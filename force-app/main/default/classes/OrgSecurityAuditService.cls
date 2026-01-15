/**
 * @description OrgSecurityAuditService
 * Orchestrates collection, analysis, scoring, and CSV export for organization security posture.
 * Produces exportable ContentVersion CSVs and summarizes results for invocable/agents.
 *
 * Design notes:
 * - with sharing and user-mode queries where appropriate
 * - bulkified queries; no SOQL/DML in loops
 * - enums over string constants
 * - invocable wrapper provided by OrgSecurityAuditInvoker
 */
public with sharing class OrgSecurityAuditService {

    // =============================
    // Enums & DTOs
    // =============================

    public enum RiskLevel { CRITICAL, HIGH, MEDIUM, LOW }

    public class ExportDescriptor {
        public String fileName;
        public Id contentVersionId;
        public String downloadUrl; // to be constructed by caller if needed
    }

    public class HighRiskUserRow {
        public Id userId;
        public String userName;
        public String profileName;
        public Set<String> sources = new Set<String>();
        public RiskLevel level;
        public String reasons;
    }

    public class SystemPermissionRow {
        public String permissionName;
        public Integer profileCount;
        public Integer permSetCount;
        public Integer userCount;
        public RiskLevel level;
    }

    public class ObjectPermRow {
        public String principalType; // Profile | PermissionSet
        public String principalName;
        public String sObjectName;
        public Boolean readAccess;
        public Boolean createAccess;
        public Boolean editAccess;
        public Boolean deleteAccess;
    }

    public class FLSGapRow {
        public String principalType; // Profile | PermissionSet
        public String principalName;
        public String sObjectName;
        public String fieldApi;
        public Boolean readable;
        public Boolean editable;
        public RiskLevel level;
        public String reason;
    }

    public class PSetAssignmentRow {
        public String userName;
        public String permissionSetLabel;
        public Boolean modifyAllData;
        public Boolean viewAllData;
        public String objectPerms; // compact summary e.g. Account[R,E]
    }

    // Aggregate output for invocable/controller
    public class AuditArtifacts {
        public Integer totalUsers = 0;
        public Integer criticalCount = 0;
        public Integer highCount = 0;
        public Integer mediumCount = 0;
        public Integer overallRiskScore = 0;

        public Map<String, List<Object>> rowsByFile = new Map<String, List<Object>>();
        public Map<String, ExportDescriptor> exportsByFile = new Map<String, ExportDescriptor>();

        // Narrative fields (can be filled by OrgSecurityAuditor or caller)
        public String executiveSummary;
        public String riskAssessment;
        public String criticalFindings;
        public String profileAnalysis;
        public String systemPermissionAnalysis;
        public String highRiskUsers;
        public String recommendations;
        public String complianceStatus;
    }

    // =============================
    // Public API
    // =============================

    public static AuditArtifacts runAudit(Boolean includeInactive, String riskLevelFilter) {
        // Collect security data
        Map<String, Object> data = collectSecurityData(includeInactive);

        // Analyze & score
        Map<String, Integer> metrics = analyzeMetrics(data);
        AuditArtifacts art = new AuditArtifacts();
        art.totalUsers = ((List<User>) data.get('users')).size();
        art.criticalCount = metrics.get('critical');
        art.highCount = metrics.get('high');
        art.mediumCount = metrics.get('medium');
        art.overallRiskScore = calculateOverallRisk(metrics, art.totalUsers);

        // Generate CSVs one at a time to reduce heap usage
        art.exportsByFile = new Map<String, ExportDescriptor>();
        
        // Summary
        List<Object> summaryRows = buildSummaryRows(art, metrics);
        art.exportsByFile.put('Summary.csv', generateSingleCsvAndUpload('Summary.csv', summaryRows));
        summaryRows.clear(); // Free memory
        
        // High Risk Users
        List<Object> highRiskRows = buildHighRiskUserRows(data);
        if (riskLevelFilter != null && riskLevelFilter != 'All') {
            highRiskRows = filterHighRiskRows(highRiskRows, riskLevelFilter);
        }
        art.exportsByFile.put('HighRiskUsers.csv', generateSingleCsvAndUpload('HighRiskUsers.csv', highRiskRows));
        highRiskRows.clear(); // Free memory
        
        // System Permissions
        List<Object> sysPermRows = buildSystemPermissionRows(data);
        if (riskLevelFilter != null && riskLevelFilter != 'All') {
            sysPermRows = filterSystemPermRows(sysPermRows, riskLevelFilter);
        }
        art.exportsByFile.put('SystemPermissions.csv', generateSingleCsvAndUpload('SystemPermissions.csv', sysPermRows));
        sysPermRows.clear(); // Free memory
        
        // Profiles Object Perms - Build and upload immediately
        List<Object> objPermRows = buildObjectPermissionRows(data);
        art.exportsByFile.put('ProfilesObjectPerms.csv', generateSingleCsvAndUpload('ProfilesObjectPerms.csv', objPermRows));
        objPermRows.clear(); // Free memory
        
        // Field Level Security Gaps
        List<Object> flsRows = buildFlsGapRows(data);
        art.exportsByFile.put('FieldLevelSecurityGaps.csv', generateSingleCsvAndUpload('FieldLevelSecurityGaps.csv', flsRows));
        flsRows.clear(); // Free memory
        
        // Permission Set Assignments
        List<Object> psaRows = buildPsaRows(data);
        art.exportsByFile.put('PermissionSetAssignments.csv', generateSingleCsvAndUpload('PermissionSetAssignments.csv', psaRows));
        psaRows.clear(); // Free memory
        
        // Clear large data structures
        data.clear();

        return art;
    }

    // =============================
    // Data Collection
    // =============================

    private static Map<String, Object> collectSecurityData(Boolean includeInactive) {
        Map<String, Object> data = new Map<String, Object>();

        // Users in scope
        String userSoql = 'SELECT Id, Name, Username, ProfileId, Profile.Name, IsActive, UserRoleId, UserRole.Name, ' +
                          'LastLoginDate, CreatedDate, UserType ' +
                          'FROM User ' +
                          (includeInactive == true ? '' : 'WHERE IsActive = true');
        List<User> users = Database.query(userSoql);
        data.put('users', users);

        // Profiles in use (optimize by user profiles)
        Set<Id> profileIds = new Set<Id>();
        for (User u : users) {
            if (u.ProfileId != null) profileIds.add(u.ProfileId);
        }
        List<Profile> profiles = new List<Profile>();
        if (!profileIds.isEmpty()) {
            profiles = [
                SELECT Id, Name,
                       PermissionsModifyAllData, PermissionsViewAllData,
                       PermissionsManageUsers, PermissionsCustomizeApplication,
                       PermissionsApiEnabled, PermissionsAuthorApex,
                       PermissionsTransferAnyEntity
                FROM Profile
                WHERE Id IN :profileIds
            ];
        }
        data.put('profiles', profiles);

        // Permission Sets granting critical perms
        List<PermissionSet> permSets = [
            SELECT Id, Name, Label, IsOwnedByProfile,
                   PermissionsModifyAllData, PermissionsViewAllData, PermissionsApiEnabled, PermissionsAuthorApex
            FROM PermissionSet
            WHERE IsOwnedByProfile = false
        ];
        data.put('permissionSets', permSets);

        // Permission Set Assignments for users in scope
        Set<Id> userIds = new Set<Id>();
        for (User u2 : users) userIds.add(u2.Id);
        List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>();
        if (!userIds.isEmpty()) {
            psa = [
                SELECT AssigneeId, Assignee.Name, Assignee.IsActive,
                       PermissionSetId, PermissionSet.Name, PermissionSet.Label,
                       PermissionSet.IsOwnedByProfile,
                       PermissionSet.PermissionsModifyAllData,
                       PermissionSet.PermissionsViewAllData,
                       PermissionSet.PermissionsApiEnabled,
                       PermissionSet.PermissionsAuthorApex
                FROM PermissionSetAssignment
                WHERE AssigneeId IN :userIds
            ];
        }
        data.put('psa', psa);

        // Object Permissions for profiles in scope (limit to reduce heap)
        List<ObjectPermissions> objPerms = new List<ObjectPermissions>();
        if (!profileIds.isEmpty()) {
            objPerms.addAll([
                SELECT ParentId, Parent.Profile.Name, SObjectType,
                       PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
                FROM ObjectPermissions
                WHERE Parent.ProfileId IN :profileIds
                LIMIT 5000
            ]);
        }

        // Object Permissions on permission sets assigned to users (limit to reduce heap)
        Set<Id> permSetIds = new Set<Id>();
        for (PermissionSetAssignment a : psa) permSetIds.add(a.PermissionSetId);
        if (!permSetIds.isEmpty()) {
            objPerms.addAll([
                SELECT ParentId, Parent.Name, SObjectType,
                       PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
                FROM ObjectPermissions
                WHERE ParentId IN :permSetIds
                LIMIT 5000
            ]);
        }
        data.put('objectPerms', objPerms);

        // Field Permissions (gaps discovery sample) - ONLY query gaps to reduce heap
        // Only get fields that are editable but not readable (misconfiguration)
        List<FieldPermissions> fldPerms = new List<FieldPermissions>();
        if (!profileIds.isEmpty()) {
            fldPerms.addAll([
                SELECT ParentId, SobjectType, Field, PermissionsEdit, PermissionsRead
                FROM FieldPermissions
                WHERE Parent.ProfileId IN :profileIds
                AND PermissionsEdit = true
                AND PermissionsRead = false
                LIMIT 1000
            ]);
        }
        if (!permSetIds.isEmpty()) {
            fldPerms.addAll([
                SELECT ParentId, SobjectType, Field, PermissionsEdit, PermissionsRead
                FROM FieldPermissions
                WHERE ParentId IN :permSetIds
                AND PermissionsEdit = true
                AND PermissionsRead = false
                LIMIT 1000
            ]);
        }
        data.put('fieldPerms', fldPerms);

        return data;
    }

    // =============================
    // Analysis & Scoring
    // =============================

    private static Map<String, Integer> analyzeMetrics(Map<String, Object> data) {
        Map<String, Integer> m = new Map<String, Integer>{
            'critical' => 0,
            'high' => 0,
            'medium' => 0,
            'modifyAllData' => 0,
            'viewAllData' => 0,
            'manageUsers' => 0,
            'customizeApp' => 0,
            'apiEnabled' => 0,
            'authorApex' => 0,
            'inactiveWithAccess' => 0,
            'noLoginInDays' => 0
        };

        List<Profile> profiles = (List<Profile>) data.get('profiles');
        List<PermissionSetAssignment> psa = (List<PermissionSetAssignment>) data.get('psa');
        List<User> users = (List<User>) data.get('users');

        for (Profile p : profiles) {
            if (p.PermissionsModifyAllData) { m.put('modifyAllData', m.get('modifyAllData') + 1); m.put('critical', m.get('critical') + 1); }
            if (p.PermissionsViewAllData)   { m.put('viewAllData', m.get('viewAllData') + 1);     m.put('high', m.get('high') + 1); }
            if (p.PermissionsManageUsers)   { m.put('manageUsers', m.get('manageUsers') + 1);     m.put('critical', m.get('critical') + 1); }
            if (p.PermissionsCustomizeApplication) { m.put('customizeApp', m.get('customizeApp') + 1); m.put('medium', m.get('medium') + 1); }
            if (p.PermissionsApiEnabled)    { m.put('apiEnabled', m.get('apiEnabled') + 1);       m.put('high', m.get('high') + 1); }
            if (p.PermissionsAuthorApex)    { m.put('authorApex', m.get('authorApex') + 1);       m.put('high', m.get('high') + 1); }
        }

        for (PermissionSetAssignment a : psa) {
            if (a.PermissionSet.PermissionsModifyAllData) { m.put('critical', m.get('critical') + 1); }
            if (a.PermissionSet.PermissionsViewAllData)   { m.put('high', m.get('high') + 1); }
        }

        Date ninetyDaysAgo = Date.today().addDays(-90);
        for (User u : users) {
            if (!u.IsActive && (u.Profile.Name != null) && (u.Profile.Name.contains('Admin') || u.Profile.Name.contains('System'))) {
                m.put('inactiveWithAccess', m.get('inactiveWithAccess') + 1);
            }
            if (u.LastLoginDate != null && u.LastLoginDate < ninetyDaysAgo && u.IsActive) {
                m.put('noLoginInDays', m.get('noLoginInDays') + 1);
            }
        }

        return m;
    }

    private static Integer calculateOverallRisk(Map<String, Integer> m, Integer totalUsers) {
        Integer score = 0;
        score += m.get('critical') * 15;
        score += m.get('high') * 10;
        score += m.get('medium') * 5;
        Integer maxScore = Math.max(1, totalUsers) * 15;
        score = (score * 100) / maxScore;
        return Math.min(100, Math.max(0, score));
    }

    // =============================
    // Row Builders
    // =============================

    private static List<Object> buildSummaryRows(AuditArtifacts art, Map<String, Integer> m) {
        List<Object> rows = new List<Object>();
        // Emit a single key-value style summary as CSV rows
        Map<String, String> summary = new Map<String, String>{
            'TotalUsers' => String.valueOf(art.totalUsers),
            'CriticalCount' => String.valueOf(art.criticalCount),
            'HighCount' => String.valueOf(art.highCount),
            'MediumCount' => String.valueOf(art.mediumCount),
            'OverallRiskScore' => String.valueOf(art.overallRiskScore),
            'ModifyAllData' => String.valueOf(m.get('modifyAllData')),
            'ViewAllData' => String.valueOf(m.get('viewAllData')),
            'ManageUsers' => String.valueOf(m.get('manageUsers')),
            'CustomizeApp' => String.valueOf(m.get('customizeApp')),
            'ApiEnabled' => String.valueOf(m.get('apiEnabled')),
            'AuthorApex' => String.valueOf(m.get('authorApex')),
            'InactiveAdmins' => String.valueOf(m.get('inactiveWithAccess')),
            'StaleActiveUsers90d' => String.valueOf(m.get('noLoginInDays'))
        };
        rows.add(summary);
        return rows;
    }

    private static List<Object> buildHighRiskUserRows(Map<String, Object> data) {
        List<Object> rows = new List<Object>();
        List<User> users = (List<User>) data.get('users');
        List<PermissionSetAssignment> psa = (List<PermissionSetAssignment>) data.get('psa');

        // Build maps for quick lookup
        Map<Id, List<PermissionSetAssignment>> userToPsa = new Map<Id, List<PermissionSetAssignment>>();
        for (PermissionSetAssignment a : psa) {
            if (!userToPsa.containsKey(a.AssigneeId)) userToPsa.put(a.AssigneeId, new List<PermissionSetAssignment>());
            userToPsa.get(a.AssigneeId).add(a);
        }

        for (User u : users) {
            Boolean hasModAll = false;
            Boolean hasViewAll = false;
            List<String> reasons = new List<String>();
            Set<String> sources = new Set<String>();

            // Profile-based
            if (u.ProfileId != null) {
                Profile pDummy = null; // we don't have the profile record here by Id map; reasons summarized via name
            }
            // Evaluate via PSA
            if (userToPsa.containsKey(u.Id)) {
                for (PermissionSetAssignment a : userToPsa.get(u.Id)) {
                    if (a.PermissionSet.PermissionsModifyAllData) { hasModAll = true; sources.add('PS:' + a.PermissionSet.Label); }
                    if (a.PermissionSet.PermissionsViewAllData)   { hasViewAll = true; sources.add('PS:' + a.PermissionSet.Label); }
                }
            }
            if (u.Profile != null && u.Profile.Name != null) {
                // names only; details aggregated by metrics elsewhere
                sources.add('Profile:' + u.Profile.Name);
            }

            if (hasModAll) reasons.add('Modify All Data');
            if (hasViewAll) reasons.add('View All Data');

            if (!reasons.isEmpty()) {
                HighRiskUserRow r = new HighRiskUserRow();
                r.userId = u.Id;
                r.userName = u.Name;
                r.profileName = (u.Profile != null ? u.Profile.Name : null);
                r.sources = sources;
                r.reasons = String.join(reasons, '; ');
                r.level = hasModAll ? RiskLevel.CRITICAL : RiskLevel.HIGH;
                rows.add(r);
            }
        }

        return rows;
    }

    private static List<Object> buildSystemPermissionRows(Map<String, Object> data) {
        List<Object> rows = new List<Object>();
        // Summarize by key high-risk permissions
        List<String> perms = new List<String>{
            'Modify All Data','View All Data','Manage Users','API Enabled','Author Apex'
        };
        // Precompute aggregates
        List<Profile> profiles = (List<Profile>) data.get('profiles');
        List<PermissionSet> psets = (List<PermissionSet>) data.get('permissionSets');
        List<PermissionSetAssignment> psa = (List<PermissionSetAssignment>) data.get('psa');

        for (String pName : perms) {
            SystemPermissionRow row = new SystemPermissionRow();
            row.permissionName = pName;
            row.profileCount = countProfilesWithPermission(profiles, pName);
            row.permSetCount = countPermSetsWithPermission(psets, pName);
            row.userCount = countUsersWithPermission(psa, pName);
            if (pName == 'Modify All Data' || pName == 'Manage Users') {
                row.level = RiskLevel.CRITICAL;
            } else if (pName == 'View All Data' || pName == 'Author Apex' || pName == 'API Enabled') {
                row.level = RiskLevel.HIGH;
            } else {
                row.level = RiskLevel.MEDIUM;
            }
            rows.add(row);
        }
        return rows;
    }

    private static Integer countProfilesWithPermission(List<Profile> profiles, String name) {
        Integer c = 0;
        for (Profile p : profiles) {
            if (name == 'Modify All Data' && p.PermissionsModifyAllData) c++;
            else if (name == 'View All Data' && p.PermissionsViewAllData) c++;
            else if (name == 'Manage Users' && p.PermissionsManageUsers) c++;
            else if (name == 'API Enabled' && p.PermissionsApiEnabled) c++;
            else if (name == 'Author Apex' && p.PermissionsAuthorApex) c++;
        }
        return c;
    }
    private static Integer countPermSetsWithPermission(List<PermissionSet> psets, String name) {
        Integer c = 0;
        for (PermissionSet ps : psets) {
            if (ps.IsOwnedByProfile) continue;
            if (name == 'Modify All Data' && ps.PermissionsModifyAllData) c++;
            else if (name == 'View All Data' && ps.PermissionsViewAllData) c++;
            else if (name == 'API Enabled' && ps.PermissionsApiEnabled) c++;
            else if (name == 'Author Apex' && ps.PermissionsAuthorApex) c++;
        }
        return c;
    }
    private static Integer countUsersWithPermission(List<PermissionSetAssignment> psa, String name) {
        Set<Id> users = new Set<Id>();
        for (PermissionSetAssignment a : psa) {
            if (name == 'Modify All Data' && a.PermissionSet.PermissionsModifyAllData) users.add(a.AssigneeId);
            else if (name == 'View All Data' && a.PermissionSet.PermissionsViewAllData) users.add(a.AssigneeId);
            else if (name == 'API Enabled' && a.PermissionSet.PermissionsApiEnabled) users.add(a.AssigneeId);
            else if (name == 'Author Apex' && a.PermissionSet.PermissionsAuthorApex) users.add(a.AssigneeId);
        }
        return users.size();
    }

    private static List<Object> buildObjectPermissionRows(Map<String, Object> data) {
        List<Object> rows = new List<Object>();
        List<ObjectPermissions> objPerms = (List<ObjectPermissions>) data.get('objectPerms');
        
        // Build lookup maps for names
        Map<Id, String> profileNames = new Map<Id, String>();
        List<Profile> profiles = (List<Profile>) data.get('profiles');
        for (Profile p : profiles) {
            profileNames.put(p.Id, p.Name);
        }
        
        Map<Id, String> permSetNames = new Map<Id, String>();
        List<PermissionSet> permSets = (List<PermissionSet>) data.get('permissionSets');
        for (PermissionSet ps : permSets) {
            permSetNames.put(ps.Id, ps.Name);
        }
        
        for (ObjectPermissions op : objPerms) {
            ObjectPermRow r = new ObjectPermRow();
            
            // Determine principal type and name safely
            String principalName = null;
            String principalType = 'Unknown';
            
            // Try to get profile name first
            try {
                if (op.Parent != null && op.Parent.Profile != null && op.Parent.Profile.Name != null) {
                    principalName = op.Parent.Profile.Name;
                    principalType = 'Profile';
                }
            } catch (Exception e) {
                // Profile field not available, try permission set
            }
            
            // If no profile, try permission set name
            if (principalName == null) {
                try {
                    if (op.Parent != null && op.Parent.Name != null) {
                        principalName = op.Parent.Name;
                        principalType = 'PermissionSet';
                    }
                } catch (Exception e) {
                    // Permission set name not available, use ParentId lookup
                    if (op.ParentId != null) {
                        if (profileNames.containsKey(op.ParentId)) {
                            principalName = profileNames.get(op.ParentId);
                            principalType = 'Profile';
                        } else if (permSetNames.containsKey(op.ParentId)) {
                            principalName = permSetNames.get(op.ParentId);
                            principalType = 'PermissionSet';
                        }
                    }
                }
            }
            
            r.principalType = principalType;
            r.principalName = principalName;
            r.sObjectName = op.SObjectType;
            r.readAccess = op.PermissionsRead;
            r.createAccess = op.PermissionsCreate;
            r.editAccess = op.PermissionsEdit;
            r.deleteAccess = op.PermissionsDelete;
            rows.add(r);
        }
        return rows;
    }

    private static List<Object> buildFlsGapRows(Map<String, Object> data) {
        List<Object> rows = new List<Object>();
        List<FieldPermissions> fperms = (List<FieldPermissions>) data.get('fieldPerms');
        // Simple rule: editable but not readable is a misconfig; editable without object edit might be flagged elsewhere
        for (FieldPermissions fp : fperms) {
            if (fp.PermissionsEdit && !fp.PermissionsRead) {
                FLSGapRow r = new FLSGapRow();
                r.principalType = 'Mixed';
                r.principalName = null;
                r.sObjectName = fp.SobjectType;
                r.fieldApi = fp.Field;
                r.readable = fp.PermissionsRead;
                r.editable = fp.PermissionsEdit;
                r.level = RiskLevel.MEDIUM;
                r.reason = 'Field editable but not readable';
                rows.add(r);
            }
        }
        return rows;
    }

    private static List<Object> buildPsaRows(Map<String, Object> data) {
        List<Object> rows = new List<Object>();
        List<PermissionSetAssignment> psa = (List<PermissionSetAssignment>) data.get('psa');

        // Preload object perms by ParentId into compact summaries
        List<ObjectPermissions> objPerms = (List<ObjectPermissions>) data.get('objectPerms');
        Map<Id, List<ObjectPermissions>> byParent = new Map<Id, List<ObjectPermissions>>();
        for (ObjectPermissions op : objPerms) {
            if (op.ParentId == null) continue;
            if (!byParent.containsKey(op.ParentId)) byParent.put(op.ParentId, new List<ObjectPermissions>());
            byParent.get(op.ParentId).add(op);
        }

        for (PermissionSetAssignment a : psa) {
            if (a.PermissionSet.IsOwnedByProfile) continue;
            PSetAssignmentRow r = new PSetAssignmentRow();
            r.userName = a.Assignee != null ? a.Assignee.Name : null;
            r.permissionSetLabel = a.PermissionSet != null ? a.PermissionSet.Label : null;
            r.modifyAllData = a.PermissionSet.PermissionsModifyAllData;
            r.viewAllData = a.PermissionSet.PermissionsViewAllData;

            List<String> parts = new List<String>();
            if (byParent.containsKey(a.PermissionSetId)) {
                for (ObjectPermissions op : byParent.get(a.PermissionSetId)) {
                    List<String> flags = new List<String>();
                    if (op.PermissionsRead) flags.add('R');
                    if (op.PermissionsCreate) flags.add('C');
                    if (op.PermissionsEdit) flags.add('E');
                    if (op.PermissionsDelete) flags.add('D');
                    if (!flags.isEmpty()) {
                        parts.add(op.SObjectType + '[' + String.join(flags, '') + ']');
                    }
                }
            }
            r.objectPerms = parts.isEmpty() ? null : String.join(parts, '; ');
            rows.add(r);
        }
        return rows;
    }

    private static void filterRowsByRisk(Map<String, List<Object>> rowsByFile, String riskFilter) {
        // Apply to HighRiskUsers.csv and SystemPermissions.csv where RiskLevel exists
        if (rowsByFile.containsKey('HighRiskUsers.csv')) {
            List<Object> src = rowsByFile.get('HighRiskUsers.csv');
            List<Object> dst = new List<Object>();
            for (Object o : src) {
                HighRiskUserRow r = (HighRiskUserRow) o;
                if (String.valueOf(r.level) == riskFilter.toUpperCase()) dst.add(r);
            }
            rowsByFile.put('HighRiskUsers.csv', dst);
        }
        if (rowsByFile.containsKey('SystemPermissions.csv')) {
            List<Object> src2 = rowsByFile.get('SystemPermissions.csv');
            List<Object> dst2 = new List<Object>();
            for (Object o2 : src2) {
                SystemPermissionRow r2 = (SystemPermissionRow) o2;
                if (String.valueOf(r2.level) == riskFilter.toUpperCase()) dst2.add(r2);
            }
            rowsByFile.put('SystemPermissions.csv', dst2);
        }
    }
    
    // Helper methods for individual row filtering
    private static List<Object> filterHighRiskRows(List<Object> rows, String riskFilter) {
        List<Object> filtered = new List<Object>();
        for (Object o : rows) {
            HighRiskUserRow r = (HighRiskUserRow) o;
            if (String.valueOf(r.level) == riskFilter.toUpperCase()) filtered.add(r);
        }
        return filtered;
    }
    
    private static List<Object> filterSystemPermRows(List<Object> rows, String riskFilter) {
        List<Object> filtered = new List<Object>();
        for (Object o : rows) {
            SystemPermissionRow r = (SystemPermissionRow) o;
            if (String.valueOf(r.level) == riskFilter.toUpperCase()) filtered.add(r);
        }
        return filtered;
    }
    
    // Single CSV generation and upload (memory efficient)
    private static ExportDescriptor generateSingleCsvAndUpload(String fileName, List<Object> rows) {
        String csv = buildCsv(rows);
        Id verId = insertContentVersion(fileName, csv);
        ExportDescriptor d = new ExportDescriptor();
        d.fileName = fileName;
        d.contentVersionId = verId;
        return d;
    }

    // =============================
    // CSV Generation & Upload
    // =============================

    private static Map<String, ExportDescriptor> generateCsvAndUpload(Map<String, List<Object>> rowsByFile) {
        Map<String, ExportDescriptor> out = new Map<String, ExportDescriptor>();
        for (String fileName : rowsByFile.keySet()) {
            List<Object> rows = rowsByFile.get(fileName);
            String csv = buildCsv(rows);
            Id verId = insertContentVersion(fileName, csv);
            ExportDescriptor d = new ExportDescriptor();
            d.fileName = fileName;
            d.contentVersionId = verId;
            out.put(fileName, d);
        }
        return out;
    }

    private static String buildCsv(List<Object> rows) {
        if (rows == null || rows.isEmpty()) {
            return '\uFEFF'; // UTF-8 BOM for Excel with no data
        }

        // Derive headers from first row using JSON keys where possible
        Set<String> headers = new Set<String>();
        // Build a list of maps
        List<Map<String, String>> flatRows = new List<Map<String, String>>();

        for (Object r : rows) {
            Map<String, String> m = new Map<String, String>();
            if (r instanceof HighRiskUserRow) {
                HighRiskUserRow x = (HighRiskUserRow) r;
                m.put('UserId', String.valueOf(x.userId));
                m.put('UserName', x.userName);
                m.put('ProfileName', x.profileName);
                m.put('Sources', x.sources == null ? null : String.join(new List<String>(x.sources), '; '));
                m.put('RiskLevel', String.valueOf(x.level));
                m.put('Reasons', x.reasons);
            } else if (r instanceof SystemPermissionRow) {
                SystemPermissionRow x = (SystemPermissionRow) r;
                m.put('PermissionName', x.permissionName);
                m.put('ProfileCount', String.valueOf(x.profileCount));
                m.put('PermSetCount', String.valueOf(x.permSetCount));
                m.put('UserCount', String.valueOf(x.userCount));
                m.put('RiskLevel', String.valueOf(x.level));
            } else if (r instanceof ObjectPermRow) {
                ObjectPermRow x = (ObjectPermRow) r;
                m.put('PrincipalType', x.principalType);
                m.put('PrincipalName', x.principalName);
                m.put('SObject', x.sObjectName);
                m.put('Read', String.valueOf(x.readAccess));
                m.put('Create', String.valueOf(x.createAccess));
                m.put('Edit', String.valueOf(x.editAccess));
                m.put('Delete', String.valueOf(x.deleteAccess));
            } else if (r instanceof FLSGapRow) {
                FLSGapRow x = (FLSGapRow) r;
                m.put('PrincipalType', x.principalType);
                m.put('PrincipalName', x.principalName);
                m.put('SObject', x.sObjectName);
                m.put('Field', x.fieldApi);
                m.put('Readable', String.valueOf(x.readable));
                m.put('Editable', String.valueOf(x.editable));
                m.put('RiskLevel', String.valueOf(x.level));
                m.put('Reason', x.reason);
            } else if (r instanceof PSetAssignmentRow) {
                PSetAssignmentRow x = (PSetAssignmentRow) r;
                m.put('UserName', x.userName);
                m.put('PermissionSet', x.permissionSetLabel);
                m.put('ModifyAllData', String.valueOf(x.modifyAllData));
                m.put('ViewAllData', String.valueOf(x.viewAllData));
                m.put('ObjectPerms', x.objectPerms);
            } else if (r instanceof Map<String, String>) {
                m.putAll((Map<String, String>) r);
            }
            // collect headers from this row
            headers.addAll(m.keySet());
            flatRows.add(m);
        }

        // Order headers deterministically
        List<String> headerList = new List<String>(headers);
        headerList.sort();

        // Build CSV
        List<String> lines = new List<String>();
        lines.add('\uFEFF' + joinCsv(headerList)); // add BOM on first line
        for (Map<String, String> row : flatRows) {
            List<String> cols = new List<String>();
            for (String h : headerList) {
                cols.add(csvEscape(row.containsKey(h) ? row.get(h) : null));
            }
            lines.add(joinCsv(cols));
        }
        return String.join(lines, '\n');
    }

    private static String joinCsv(List<String> cols) {
        return String.join(cols, ',');
    }

    private static String csvEscape(String v) {
        if (v == null) return '';
        // Escape quotes and wrap if contains comma, quote, or newline
        String w = v.replace('"', '""');
        if (w.contains(',') || w.contains('"') || w.contains('\n') || w.contains('\r')) {
            return '"' + w + '"';
        }
        return w;
    }

    private static Id insertContentVersion(String fileName, String body) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName.endsWith('.csv') ? fileName.substring(0, fileName.length()-4) : fileName;
        cv.PathOnClient = '/' + fileName;
        cv.VersionData = Blob.valueOf(body);
        Database.SaveResult sr = Database.insert(cv, AccessLevel.USER_MODE);
        if (!sr.isSuccess()) {
            // throw an exception with first error
            Database.Error e = sr.getErrors().isEmpty() ? null : sr.getErrors()[0];
            throw (e != null ? new AuraHandledException('Failed to insert ContentVersion: ' + e.getMessage()) :
                               new AuraHandledException('Failed to insert ContentVersion.'));
        }
        // Query back Id (Version Id)
        ContentVersion saved = [SELECT Id FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        return saved.Id;
    }
}