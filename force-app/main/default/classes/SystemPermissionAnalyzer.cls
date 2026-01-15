/**
 * System Permission Analyzer for AI Agent
 * Analyzes which users have specific system permissions like Modify All Data
 */
public with sharing class SystemPermissionAnalyzer {
    
    /**
     * Request for System Permission Analysis
     */
    public class SystemPermissionRequest {
        @InvocableVariable(label='System Permission Name' description='E.g., Modify All Data, View All Data' required=true)
        public String permissionName;
        
        @InvocableVariable(label='Include Inactive Users' description='Set to true to include inactive users' required=false)
        public Boolean includeInactive;
    }
    
    /**
     * Result for System Permission Analysis
     */
    public class SystemPermissionResult {
        @InvocableVariable(label='Permission Name')
        public String permissionName;
        
        @InvocableVariable(label='Total Users')
        public Integer totalUsers;
        
        @InvocableVariable(label='User List')
        public String userList;
        
        @InvocableVariable(label='Detailed Breakdown')
        public String detailedBreakdown;
        
        @InvocableVariable(label='Risk Assessment')
        public String riskAssessment;
        
        @InvocableVariable(label='Conversational Summary')
        public String conversationalSummary;
    }
    
    /**
     * Analyze who has specific system permissions
     */
    @InvocableMethod(
        label='Analyze System Permission Access'
        description='Shows all users who have a specific system permission like Modify All Data or View All Data'
        category='Security Audit'
    )
    public static List<SystemPermissionResult> analyzeSystemPermission(List<SystemPermissionRequest> requests) {
        List<SystemPermissionResult> results = new List<SystemPermissionResult>();
        
        for (SystemPermissionRequest req : requests) {
            try {
                SystemPermissionResult result = new SystemPermissionResult();
                result.permissionName = req.permissionName;
                
                // Input validation
                if (req == null || String.isBlank(req.permissionName)) {
                    result.totalUsers = 0;
                    result.conversationalSummary = 'Error: Permission name is required';
                    results.add(result);
                    continue;
                }
                
                Boolean includeInactive = req.includeInactive != null ? req.includeInactive : false;
                
                // Map permission name to field API name
                String permissionField = getPermissionFieldName(req.permissionName);
            
            if (permissionField == null) {
                result.totalUsers = 0;
                result.userList = '';
                result.detailedBreakdown = 'Unknown permission: ' + req.permissionName;
                result.conversationalSummary = 'I could not find a system permission called "' + req.permissionName + '". Please check the permission name.';
                results.add(result);
                continue;
            }
            
            // Find users with this permission
            Map<String, Set<String>> userToSources = new Map<String, Set<String>>();
            Set<Id> usersWithPermission = new Set<Id>();
            
            // 1. Check via Profile - Use safe binding
            List<Profile> profiles = queryProfilesByPermission(permissionField);
            
            if (!profiles.isEmpty()) {
                Set<Id> profileIds = new Set<Id>();
                Map<Id, String> profileNames = new Map<Id, String>();
                
                for (Profile p : profiles) {
                    profileIds.add(p.Id);
                    profileNames.put(p.Id, p.Name);
                }
                
                String userQuery = 'SELECT Id, Name, Username, ProfileId, IsActive FROM User WHERE ProfileId IN :profileIds';
                if (!includeInactive) {
                    userQuery += ' AND IsActive = true';
                }
                
                for (User u : Database.query(userQuery)) {
                    usersWithPermission.add(u.Id);
                    if (!userToSources.containsKey(u.Name)) {
                        userToSources.put(u.Name, new Set<String>());
                    }
                    userToSources.get(u.Name).add('Profile: ' + profileNames.get(u.ProfileId));
                }
            }
            
            // 2. Check via Permission Sets - Use safe binding
            List<PermissionSet> permSets = queryPermissionSetsByPermission(permissionField);
            
            if (!permSets.isEmpty()) {
                Set<Id> permSetIds = new Set<Id>();
                Map<Id, String> permSetLabels = new Map<Id, String>();
                
                for (PermissionSet ps : permSets) {
                    permSetIds.add(ps.Id);
                    permSetLabels.put(ps.Id, ps.Label + ' (' + ps.Name + ')');
                }
                
                List<PermissionSetAssignment> assignments = [
                    SELECT AssigneeId, PermissionSetId, Assignee.Name, Assignee.Username, Assignee.IsActive
                    FROM PermissionSetAssignment
                    WHERE PermissionSetId IN :permSetIds
                ];
                
                for (PermissionSetAssignment psa : assignments) {
                    if (includeInactive || psa.Assignee.IsActive) {
                        usersWithPermission.add(psa.AssigneeId);
                        if (!userToSources.containsKey(psa.Assignee.Name)) {
                            userToSources.put(psa.Assignee.Name, new Set<String>());
                        }
                        userToSources.get(psa.Assignee.Name).add('Permission Set: ' + permSetLabels.get(psa.PermissionSetId));
                    }
                }
            }
            
            // Build result
            result.totalUsers = usersWithPermission.size();
            
            // Build user list with sources
            List<String> userDetails = new List<String>();
            List<String> sortedUsers = new List<String>(userToSources.keySet());
            sortedUsers.sort();
            
            for (String userName : sortedUsers) {
                Set<String> sources = userToSources.get(userName);
                List<String> sourceList = new List<String>(sources);
                sourceList.sort();
                
                userDetails.add('\n👤 ' + userName);
                for (String source : sourceList) {
                    userDetails.add('   • ' + source);
                }
            }
            
            result.userList = String.join(userDetails, '\n');
            
            // Build detailed breakdown
            result.detailedBreakdown = buildSystemPermissionBreakdown(
                req.permissionName,
                profiles,
                permSets,
                userToSources.size()
            );
            
            // Risk assessment
            if (req.permissionName.contains('Modify All') || req.permissionName.contains('Delete')) {
                result.riskAssessment = '🔴 CRITICAL RISK: This permission grants extensive data modification capabilities. ' +
                    'Users with this permission can modify or delete ANY record in the system. ' +
                    'Strict controls and regular audits are mandatory.';
            } else if (req.permissionName.contains('View All')) {
                result.riskAssessment = '🟡 HIGH RISK: This permission grants read access to all records. ' +
                    'Users can view sensitive data across all objects. Regular access reviews recommended.';
            } else {
                result.riskAssessment = '🟢 MODERATE RISK: This permission has limited scope. ' +
                    'Standard security practices should be followed.';
            }
            
            // Conversational summary
            result.conversationalSummary = buildSystemPermissionSummary(
                req.permissionName,
                result.totalUsers,
                profiles.size(),
                permSets.size()
            );
            
            results.add(result);
            } catch (Exception e) {
                SystemPermissionResult errorResult = new SystemPermissionResult();
                errorResult.permissionName = req != null ? req.permissionName : 'Unknown';
                errorResult.totalUsers = 0;
                errorResult.conversationalSummary = 'Error analyzing permission: ' + e.getMessage();
                results.add(errorResult);
            }
        }
        
        return results;
    }
    
    /**
     * Safe query for profiles with permission - prevents dynamic SOQL
     */
    @TestVisible
    private static List<Profile> queryProfilesByPermission(String permissionField) {
        List<Profile> profiles = new List<Profile>();
        
        // Use safe field mapping instead of dynamic SOQL
        if (permissionField == 'PermissionsModifyAllData') {
            profiles = [SELECT Id, Name, PermissionsModifyAllData FROM Profile WHERE PermissionsModifyAllData = true];
        } else if (permissionField == 'PermissionsViewAllData') {
            profiles = [SELECT Id, Name, PermissionsViewAllData FROM Profile WHERE PermissionsViewAllData = true];
        } else if (permissionField == 'PermissionsManageUsers') {
            profiles = [SELECT Id, Name, PermissionsManageUsers FROM Profile WHERE PermissionsManageUsers = true];
        } else if (permissionField == 'PermissionsCustomizeApplication') {
            profiles = [SELECT Id, Name, PermissionsCustomizeApplication FROM Profile WHERE PermissionsCustomizeApplication = true];
        } else if (permissionField == 'PermissionsApiEnabled') {
            profiles = [SELECT Id, Name, PermissionsApiEnabled FROM Profile WHERE PermissionsApiEnabled = true];
        } else if (permissionField == 'PermissionsAuthorApex') {
            profiles = [SELECT Id, Name, PermissionsAuthorApex FROM Profile WHERE PermissionsAuthorApex = true];
        }
        
        return profiles;
    }
    
    /**
     * Safe query for permission sets with permission - prevents dynamic SOQL
     */
    @TestVisible
    private static List<PermissionSet> queryPermissionSetsByPermission(String permissionField) {
        List<PermissionSet> permSets = new List<PermissionSet>();
        
        if (permissionField == 'PermissionsModifyAllData') {
            permSets = [SELECT Id, Name, Label, PermissionsModifyAllData FROM PermissionSet WHERE PermissionsModifyAllData = true AND IsOwnedByProfile = false];
        } else if (permissionField == 'PermissionsViewAllData') {
            permSets = [SELECT Id, Name, Label, PermissionsViewAllData FROM PermissionSet WHERE PermissionsViewAllData = true AND IsOwnedByProfile = false];
        } else if (permissionField == 'PermissionsManageUsers') {
            permSets = [SELECT Id, Name, Label, PermissionsManageUsers FROM PermissionSet WHERE PermissionsManageUsers = true AND IsOwnedByProfile = false];
        } else if (permissionField == 'PermissionsCustomizeApplication') {
            permSets = [SELECT Id, Name, Label, PermissionsCustomizeApplication FROM PermissionSet WHERE PermissionsCustomizeApplication = true AND IsOwnedByProfile = false];
        } else if (permissionField == 'PermissionsApiEnabled') {
            permSets = [SELECT Id, Name, Label, PermissionsApiEnabled FROM PermissionSet WHERE PermissionsApiEnabled = true AND IsOwnedByProfile = false];
        } else if (permissionField == 'PermissionsAuthorApex') {
            permSets = [SELECT Id, Name, Label, PermissionsAuthorApex FROM PermissionSet WHERE PermissionsAuthorApex = true AND IsOwnedByProfile = false];
        }
        
        return permSets;
    }
    
    /**
     * Map common permission names to field API names
     */
    private static String getPermissionFieldName(String permissionName) {
        String normalized = permissionName.toLowerCase().trim()
            .replace('_', ' ')  // Handle underscores
            .replaceAll('\\s+', ' '); // Normalize multiple spaces
        
        // Common system permissions - check for variations
        // Modify All Data / ModifyAllData / Modify_All_Data
        if (normalized.contains('modifyalldata') || normalized.contains('modify all')) {
            return 'PermissionsModifyAllData';
        } 
        // View All Data / ViewAllData / View_All_Data  
        else if (normalized.contains('viewalldata') || normalized.contains('view all')) {
            return 'PermissionsViewAllData';
        } 
        // Manage Users / ManageUsers
        else if (normalized.contains('manageusers') || normalized.contains('manage users')) {
            return 'PermissionsManageUsers';
        } 
        // Customize Application / CustomizeApplication
        else if (normalized.contains('customizeapplication') || normalized.contains('customize application')) {
            return 'PermissionsCustomizeApplication';
        } 
        // Edit Reports / EditReports
        else if (normalized.contains('editreports') || normalized.contains('edit reports')) {
            return 'PermissionsEditReports';
        } 
        // Manage Dashboards / ManageDashboards
        else if (normalized.contains('managedashboards') || normalized.contains('manage dashboards')) {
            return 'PermissionsManageDashboards';
        } 
        // API Enabled / ApiEnabled
        else if (normalized.contains('apienabled') || normalized.contains('api enabled')) {
            return 'PermissionsApiEnabled';
        } 
        // Manage Profiles / ManageProfiles
        else if (normalized.contains('manageprofiles') || normalized.contains('manage profiles')) {
            return 'PermissionsManageProfilesPermissionsets';
        }
        // Author Apex
        else if (normalized.contains('authorapex') || normalized.contains('author apex')) {
            return 'PermissionsAuthorApex';
        }
        // View Setup / ViewSetup
        else if (normalized.contains('viewsetup') || normalized.contains('view setup')) {
            return 'PermissionsViewSetup';
        }
        // Transfer Record
        else if (normalized.contains('transferrecord') || normalized.contains('transfer record')) {
            return 'PermissionsTransferAnyEntity';
        }
        
        return null;
    }
    
    /**
     * Build detailed breakdown for system permission
     */
    private static String buildSystemPermissionBreakdown(
        String permissionName,
        List<Profile> profiles,
        List<PermissionSet> permSets,
        Integer totalUsers
    ) {
        List<String> details = new List<String>();
        
        details.add('🔍 SYSTEM PERMISSION ANALYSIS: ' + permissionName);
        details.add('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        details.add('');
        details.add('📊 SUMMARY:');
        details.add('• Total Users: ' + totalUsers);
        details.add('• Via Profiles: ' + profiles.size());
        details.add('• Via Permission Sets: ' + permSets.size());
        details.add('');
        
        if (!profiles.isEmpty()) {
            details.add('👥 PROFILES WITH THIS PERMISSION:');
            for (Profile p : profiles) {
                details.add('   • ' + p.Name);
            }
            details.add('');
        }
        
        if (!permSets.isEmpty()) {
            details.add('🎫 PERMISSION SETS WITH THIS PERMISSION:');
            for (PermissionSet ps : permSets) {
                details.add('   • ' + ps.Label + ' (' + ps.Name + ')');
            }
            details.add('');
        }
        
        return String.join(details, '\n');
    }
    
    /**
     * Build conversational summary
     */
    private static String buildSystemPermissionSummary(
        String permissionName,
        Integer totalUsers,
        Integer profileCount,
        Integer permSetCount
    ) {
        String summary = 'I found ' + totalUsers + ' user';
        if (totalUsers != 1) summary += 's';
        summary += ' with the "' + permissionName + '" permission. ';
        
        if (profileCount > 0 && permSetCount > 0) {
            summary += 'This permission is granted through ' + profileCount + ' profile(s) and ' + 
                      permSetCount + ' permission set(s). ';
        } else if (profileCount > 0) {
            summary += 'This permission is granted through ' + profileCount + ' profile(s). ';
        } else if (permSetCount > 0) {
            summary += 'This permission is granted through ' + permSetCount + ' permission set(s). ';
        }
        
        if (totalUsers > 10) {
            summary += '⚠️ This is a relatively large number of users with elevated privileges. ' +
                      'I recommend reviewing each user\'s access to ensure it\'s necessary.';
        } else if (totalUsers > 0) {
            summary += 'I\'ve listed all users and their permission sources in the detailed breakdown above.';
        } else {
            summary += 'No users currently have this permission in your org.';
        }
        
        return summary;
    }
}