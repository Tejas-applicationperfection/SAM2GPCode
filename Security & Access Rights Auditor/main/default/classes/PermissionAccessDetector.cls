public with sharing class PermissionAccessDetector {

    // =============================
    // INVOCABLE INPUT
    // =============================
    public class AccessRequest {
        @InvocableVariable(required=true)
        public String principalType; // User | Profile | PermissionSet

        @InvocableVariable(required=true)
        public String principalName;

        @InvocableVariable(required=true)
        public String resourceType; // Object

        @InvocableVariable(required=true)
        public String resourceName; // Account, Case, etc.
    }

    // =============================
    // INVOCABLE OUTPUT (Enhanced for AI Agent)
    // =============================
    public class AccessResult {
        @InvocableVariable(label='Access Source')
        public String accessSource;

        @InvocableVariable(label='Detailed Explanation')
        public String explanation;
        
        @InvocableVariable(label='Severity Level')
        public String severity;
        
        @InvocableVariable(label='Risk Assessment')
        public String riskAssessment;
        
        @InvocableVariable(label='Next Steps')
        public String nextSteps;
        
        @InvocableVariable(label='Conversational Summary')
        public String conversationalSummary;
    }

    // =============================
    // ENTRY POINT (AI Agent Action)
    // =============================
    @InvocableMethod(
        label='Analyze Permission Access' 
        description='Analyzes where a user, profile, or permission set gets access to a specific Salesforce object. Returns detailed breakdown including severity assessment and remediation guidance.'
        category='Security Audit'
    )
    public static List<AccessResult> detectAccess(List<AccessRequest> requests) {

        List<AccessResult> results = new List<AccessResult>();

        for (AccessRequest req : requests) {
            AccessResult res = new AccessResult();
            
            try {
                // Input validation
                if (req == null || String.isBlank(req.principalType) || String.isBlank(req.principalName) || String.isBlank(req.resourceName)) {
                    res.accessSource = 'Invalid Input';
                    res.explanation = 'Missing required parameters: principalType, principalName, or resourceName';
                    results.add(res);
                    continue;
                }

                if (req.resourceType != 'Object') {
                    res.accessSource = 'Unsupported';
                    res.explanation = 'Only Object access detection is supported.';
                    results.add(res);
                    continue;
                }

                if (req.principalType == 'Profile') {
                    analyzeProfile(req, res);
                } else if (req.principalType == 'PermissionSet') {
                    analyzePermissionSet(req, res);
                } else if (req.principalType == 'User') {
                    analyzeUser(req, res);
                } else {
                    res.accessSource = 'Invalid Input';
                    res.explanation = 'Unsupported principal type.';
                }
            } catch (Exception e) {
                res.accessSource = 'Error';
                res.explanation = 'Error analyzing access: ' + e.getMessage();
                res.severity = 'Error';
            }

            results.add(res);
        }

        return results;
    }

    // =============================
    // PROFILE ANALYSIS
    // =============================
    @TestVisible
    private static void analyzeProfile(AccessRequest req, AccessResult res) {

        Profile p = [
            SELECT Id, Name,
                   PermissionsViewAllData,
                   PermissionsModifyAllData
            FROM Profile
            WHERE Name = :req.principalName
            LIMIT 1
        ];

        List<String> accessDetails = new List<String>();

        // 1️⃣ System Permissions
        if (p.PermissionsModifyAllData) {
            accessDetails.add('• System Permission: Modify All Data (grants full CRUD access to all objects)');
        } else if (p.PermissionsViewAllData) {
            accessDetails.add('• System Permission: View All Data (grants read-only access to all objects)');
        }

        // 2️⃣ Profile ObjectPermissions
        List<ObjectPermissions> ops = [
            SELECT PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
            FROM ObjectPermissions
            WHERE Parent.ProfileId = :p.Id
            AND SObjectType = :req.resourceName
        ];

        if (!ops.isEmpty()) {
            ObjectPermissions op = ops[0];
            List<String> perms = new List<String>();
            if (op.PermissionsRead) perms.add('Read');
            if (op.PermissionsCreate) perms.add('Create');
            if (op.PermissionsEdit) perms.add('Edit');
            if (op.PermissionsDelete) perms.add('Delete');
            
            if (!perms.isEmpty()) {
                accessDetails.add('• Object Permissions: ' + String.join(perms, ', ') + ' access to ' + req.resourceName);
            }
        }

        if (accessDetails.isEmpty()) {
            res.accessSource = 'No Profile-Level Access Found';
            res.severity = 'Info';
            res.riskAssessment = 'No access granted by this profile';
            res.explanation =
                'Profile "' + p.Name + '" does not have any permissions configured for ' + req.resourceName + '. Access may still be granted via permission sets, sharing, or roles.';
            res.conversationalSummary = 'The profile "' + p.Name + '" doesn\'t grant any access to ' + req.resourceName + '. Users with this profile would need additional permission sets or sharing rules to access this object.';
            res.nextSteps = '1. Check if permission sets grant access to ' + req.resourceName + '\n2. Review sharing settings and organization-wide defaults';
        } else {
            res.accessSource = 'Profile';
            res.explanation = 'Profile "' + p.Name + '" grants access to ' + req.resourceName + ':\n\n' + String.join(accessDetails, '\n');
            
            // Determine severity
            if (p.PermissionsModifyAllData) {
                res.severity = 'High';
                res.riskAssessment = 'High Risk - Profile has Modify All Data, a system-level permission that grants full access to all data';
                res.conversationalSummary = 'The profile "' + p.Name + '" has Modify All Data permission, which is one of the most powerful permissions in Salesforce. It grants full CRUD access to all objects including ' + req.resourceName + '.';
                res.nextSteps = '1. Verify if all users with this profile require Modify All Data\n2. Consider using object-specific permissions instead\n3. Enable enhanced audit trail for users with this profile';
            } else if (p.PermissionsViewAllData) {
                res.severity = 'Medium';
                res.riskAssessment = 'Medium Risk - Profile has View All Data permission';
                res.conversationalSummary = 'The profile "' + p.Name + '" has View All Data permission, allowing read access to all ' + req.resourceName + ' records regardless of sharing rules.';
                res.nextSteps = '1. Verify if all users need to see all records\n2. Consider using sharing rules for more granular control';
            } else {
                res.severity = 'Low';
                res.riskAssessment = 'Standard object-level permissions';
                res.conversationalSummary = 'The profile "' + p.Name + '" grants standard object permissions to ' + req.resourceName + '. This is a typical setup.';
                res.nextSteps = '1. Verify the permission levels match business requirements\n2. Ensure field-level security is configured if needed';
            }
        }
    }

    // =============================
    // PERMISSION SET ANALYSIS
    // =============================
    @TestVisible
    private static void analyzePermissionSet(AccessRequest req, AccessResult res) {

        PermissionSet ps = [
            SELECT Id, Name, IsOwnedByProfile, Label,
                   PermissionsModifyAllData, PermissionsViewAllData
            FROM PermissionSet
            WHERE Name = :req.principalName
            LIMIT 1
        ];

        List<String> accessDetails = new List<String>();

        // 1️⃣ System Permissions
        if (ps.PermissionsModifyAllData) {
            accessDetails.add('• System Permission: Modify All Data (grants full CRUD access to all objects)');
        } else if (ps.PermissionsViewAllData) {
            accessDetails.add('• System Permission: View All Data (grants read-only access to all objects)');
        }

        // 2️⃣ Object Permissions
        List<ObjectPermissions> ops = [
            SELECT PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
            FROM ObjectPermissions
            WHERE ParentId = :ps.Id
            AND SObjectType = :req.resourceName
        ];

        if (!ops.isEmpty()) {
            ObjectPermissions op = ops[0];
            List<String> perms = new List<String>();
            if (op.PermissionsRead) perms.add('Read');
            if (op.PermissionsCreate) perms.add('Create');
            if (op.PermissionsEdit) perms.add('Edit');
            if (op.PermissionsDelete) perms.add('Delete');
            
            if (!perms.isEmpty()) {
                accessDetails.add('• Object Permissions: ' + String.join(perms, ', ') + ' access to ' + req.resourceName);
            }
        }

        if (accessDetails.isEmpty()) {
            res.accessSource = 'No Permission Set Access Found';
            res.severity = 'Info';
            res.riskAssessment = 'No access granted by this permission set';
            res.explanation =
                'Permission Set "' + ps.Label + '" does not grant any permissions for ' + req.resourceName + '.';
            res.conversationalSummary = 'The permission set "' + ps.Label + '" doesn\'t include any permissions for ' + req.resourceName + '. Users assigned this permission set won\'t get any additional access to this object.';
            res.nextSteps = '1. Verify if this is intentional\n2. Consider adding object permissions if access is needed';
        } else {
            res.accessSource = 'Permission Set';
            res.explanation = 'Permission Set "' + ps.Label + '" grants access to ' + req.resourceName + ':\n\n' + String.join(accessDetails, '\n');
            
            // Determine severity  
            if (ps.PermissionsModifyAllData) {
                res.severity = 'Critical';
                res.riskAssessment = 'Critical Risk - Permission set grants Modify All Data. This should be tightly controlled and only assigned to system administrators.';
                res.conversationalSummary = 'The permission set "' + ps.Label + '" includes Modify All Data permission. This is extremely powerful and should only be assigned to trusted administrators.';
                res.nextSteps = '1. ⚠️ Audit all users assigned this permission set\n2. Verify business justification for each assignment\n3. Enable audit trail and monitor all activities\n4. Consider replacing with object-specific permissions';
            } else if (ps.PermissionsViewAllData) {
                res.severity = 'High';
                res.riskAssessment = 'High Risk - Permission set grants View All Data. Carefully control assignments.';
                res.conversationalSummary = 'The permission set "' + ps.Label + '" includes View All Data permission, allowing users to read all records in ' + req.resourceName + ' and other objects.';
                res.nextSteps = '1. Review all assignments of this permission set\n2. Verify users require access to all records\n3. Consider using sharing rules for more targeted access';
            } else {
                res.severity = 'Low';
                res.riskAssessment = 'Standard permissions - Follow principle of least privilege';
                res.conversationalSummary = 'The permission set "' + ps.Label + '" provides object-level permissions for ' + req.resourceName + '. This is a standard configuration.';
                res.nextSteps = '1. Ensure permissions align with user roles\n2. Review field-level security if needed\n3. Document the purpose of this permission set';
            }
        }
    }

    // =============================
    // USER ANALYSIS (COMPREHENSIVE)
    // =============================
    @TestVisible
    private static void analyzeUser(AccessRequest req, AccessResult res) {
    
        User u = [
            SELECT Id, ProfileId, Profile.Name
            FROM User
            WHERE Name = :req.principalName
            LIMIT 1
        ];
    
        List<String> accessSources = new List<String>();
        List<String> details = new List<String>();
            
        // 1️⃣ Check Profile System Permissions (View All Data / Modify All Data)
        Profile p = [
            SELECT Id, Name,
                   PermissionsViewAllData,
                   PermissionsModifyAllData
            FROM Profile
            WHERE Id = :u.ProfileId
            LIMIT 1
        ];
            
        if (p.PermissionsModifyAllData) {
            accessSources.add('Profile System Permission');
            details.add('• Profile "' + p.Name + '" has Modify All Data permission (grants full access to all objects)');
        } else if (p.PermissionsViewAllData) {
            accessSources.add('Profile System Permission');
            details.add('• Profile "' + p.Name + '" has View All Data permission (grants read access to all objects)');
        }
    
        // 2️⃣ Check Profile Object Permissions
        List<ObjectPermissions> profileObjPerms = [
            SELECT PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
            FROM ObjectPermissions
            WHERE Parent.ProfileId = :p.Id
            AND SObjectType = :req.resourceName
        ];
    
        if (!profileObjPerms.isEmpty()) {
            ObjectPermissions op = profileObjPerms[0];
            List<String> perms = new List<String>();
            if (op.PermissionsRead) perms.add('Read');
            if (op.PermissionsCreate) perms.add('Create');
            if (op.PermissionsEdit) perms.add('Edit');
            if (op.PermissionsDelete) perms.add('Delete');
                
            if (!perms.isEmpty()) {
                accessSources.add('Profile Object Permissions');
                details.add('• Profile "' + p.Name + '" grants: ' + String.join(perms, ', '));
            }
        }
    
        // 3️⃣ Check Permission Sets
        List<PermissionSetAssignment> psa = [
            SELECT PermissionSet.Name, PermissionSetId, PermissionSet.PermissionsModifyAllData, PermissionSet.PermissionsViewAllData
            FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id
            AND PermissionSet.IsOwnedByProfile = false
        ];
    
        if (!psa.isEmpty()) {
            Set<Id> permSetIds = new Set<Id>();
            Map<Id, String> permSetNames = new Map<Id, String>();
                
            for (PermissionSetAssignment assignment : psa) {
                permSetIds.add(assignment.PermissionSetId);
                permSetNames.put(assignment.PermissionSetId, assignment.PermissionSet.Name);
                    
                // Check system-level permissions in permission sets
                if (assignment.PermissionSet.PermissionsModifyAllData) {
                    accessSources.add('Permission Set System Permission');
                    details.add('• Permission Set "' + assignment.PermissionSet.Name + '" has Modify All Data (grants full access to all objects)');
                } else if (assignment.PermissionSet.PermissionsViewAllData) {
                    accessSources.add('Permission Set System Permission');
                    details.add('• Permission Set "' + assignment.PermissionSet.Name + '" has View All Data (grants read access to all objects)');
                }
            }
                
            // Check object-specific permissions in permission sets
            List<ObjectPermissions> permSetObjPerms = [
                SELECT ParentId, Parent.Name,
                       PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
                FROM ObjectPermissions
                WHERE ParentId IN :permSetIds
                AND SObjectType = :req.resourceName
                AND (PermissionsRead = true OR PermissionsCreate = true 
                     OR PermissionsEdit = true OR PermissionsDelete = true)
            ];
                
            for (ObjectPermissions op : permSetObjPerms) {
                List<String> perms = new List<String>();
                if (op.PermissionsRead) perms.add('Read');
                if (op.PermissionsCreate) perms.add('Create');
                if (op.PermissionsEdit) perms.add('Edit');
                if (op.PermissionsDelete) perms.add('Delete');
                    
                if (!perms.isEmpty()) {
                    accessSources.add('Permission Set Object Permissions');
                    details.add('• Permission Set "' + op.Parent.Name + '" grants: ' + String.join(perms, ', '));
                }
            }
        }
    
        // 4️⃣ Check Permission Set Groups (with detailed breakdown)
        List<PermissionSetAssignment> psga = [
            SELECT PermissionSetGroupId, PermissionSetGroup.DeveloperName, PermissionSetGroup.MasterLabel
            FROM PermissionSetAssignment
            WHERE AssigneeId = :u.Id
            AND PermissionSetGroupId != null
        ];
            
        if (!psga.isEmpty()) {
            Set<Id> groupIds = new Set<Id>();
            Map<Id, String> groupLabels = new Map<Id, String>();
            
            for (PermissionSetAssignment psg : psga) {
                groupIds.add(psg.PermissionSetGroupId);
                groupLabels.put(psg.PermissionSetGroupId, psg.PermissionSetGroup.MasterLabel);
            }
            
            // Get all permission sets within these groups
            List<PermissionSetGroupComponent> groupComponents = [
                SELECT PermissionSetGroupId, PermissionSetId, PermissionSet.Name, PermissionSet.Label,
                       PermissionSet.PermissionsModifyAllData, PermissionSet.PermissionsViewAllData
                FROM PermissionSetGroupComponent
                WHERE PermissionSetGroupId IN :groupIds
            ];
            
            // Group permission sets by their group
            Map<Id, List<PermissionSetGroupComponent>> groupToPsets = new Map<Id, List<PermissionSetGroupComponent>>();
            Set<Id> allGroupPermSetIds = new Set<Id>();
            
            for (PermissionSetGroupComponent comp : groupComponents) {
                if (!groupToPsets.containsKey(comp.PermissionSetGroupId)) {
                    groupToPsets.put(comp.PermissionSetGroupId, new List<PermissionSetGroupComponent>());
                }
                groupToPsets.get(comp.PermissionSetGroupId).add(comp);
                allGroupPermSetIds.add(comp.PermissionSetId);
            }
            
            // Check which permission sets in the groups grant access to the object
            List<ObjectPermissions> groupPermSetObjPerms = [
                SELECT ParentId, Parent.Name, Parent.Label,
                       PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete
                FROM ObjectPermissions
                WHERE ParentId IN :allGroupPermSetIds
                AND SObjectType = :req.resourceName
                AND (PermissionsRead = true OR PermissionsCreate = true 
                     OR PermissionsEdit = true OR PermissionsDelete = true)
            ];
            
            Map<Id, List<String>> permSetToPerms = new Map<Id, List<String>>();
            for (ObjectPermissions op : groupPermSetObjPerms) {
                List<String> perms = new List<String>();
                if (op.PermissionsRead) perms.add('Read');
                if (op.PermissionsCreate) perms.add('Create');
                if (op.PermissionsEdit) perms.add('Edit');
                if (op.PermissionsDelete) perms.add('Delete');
                permSetToPerms.put(op.ParentId, perms);
            }
            
            // Build detailed output for each group
            for (Id groupId : groupIds) {
                String groupLabel = groupLabels.get(groupId);
                List<PermissionSetGroupComponent> groupPsets = groupToPsets.get(groupId);
                
                if (groupPsets == null || groupPsets.isEmpty()) {
                    continue;
                }
                
                List<String> grantingPsets = new List<String>();
                List<String> nonGrantingPsets = new List<String>();
                List<String> systemPermPsets = new List<String>();
                
                for (PermissionSetGroupComponent comp : groupPsets) {
                    // Check for system-level permissions
                    if (comp.PermissionSet.PermissionsModifyAllData) {
                        systemPermPsets.add(comp.PermissionSet.Label + ' (Modify All Data)');
                        accessSources.add('Permission Set Group');
                    } else if (comp.PermissionSet.PermissionsViewAllData) {
                        systemPermPsets.add(comp.PermissionSet.Label + ' (View All Data)');
                        accessSources.add('Permission Set Group');
                    }
                    
                    // Check for object-specific permissions
                    if (permSetToPerms.containsKey(comp.PermissionSetId)) {
                        List<String> perms = permSetToPerms.get(comp.PermissionSetId);
                        grantingPsets.add(comp.PermissionSet.Label + ' (' + String.join(perms, ', ') + ')');
                        accessSources.add('Permission Set Group');
                    } else if (!comp.PermissionSet.PermissionsModifyAllData && !comp.PermissionSet.PermissionsViewAllData) {
                        nonGrantingPsets.add(comp.PermissionSet.Label);
                    }
                }
                
                // Add group details
                details.add('\n▼ Permission Set Group: "' + groupLabel + '"');
                
                if (!systemPermPsets.isEmpty()) {
                    details.add('  ✔ Granting access via System Permissions:');
                    for (String pset : systemPermPsets) {
                        details.add('    • ' + pset);
                    }
                }
                
                if (!grantingPsets.isEmpty()) {
                    details.add('  ✔ Granting access via Object Permissions:');
                    for (String pset : grantingPsets) {
                        details.add('    • ' + pset);
                    }
                }
                
                if (!nonGrantingPsets.isEmpty()) {
                    details.add('  • Other permission sets in group (no access to ' + req.resourceName + '):');
                    for (String pset : nonGrantingPsets) {
                        details.add('    ○ ' + pset);
                    }
                }
            }
        }
    
        // 5️⃣ Build AI-Enhanced Response
        if (accessSources.isEmpty()) {
            res.accessSource = 'No Direct Access Found';
            res.severity = 'Info';
            res.riskAssessment = 'Low Risk - No profile or permission set access detected';
            
            res.explanation = 'User "' + req.principalName + '" does not have direct access to ' + req.resourceName + ' through Profile or Permission Sets. Access may come from:\n' +
                '• Organization-Wide Defaults (OWD)\n' +
                '• Sharing Rules\n' +
                '• Manual Sharing\n' +
                '• Role Hierarchy\n' +
                'Check Setup > Sharing Settings for more details.';
            
            res.conversationalSummary = 'I checked ' + req.principalName + '\'s access to ' + req.resourceName + ', and they don\'t have any direct permissions from their profile or permission sets. ' +
                'However, they might still have access through organization-wide defaults, sharing rules, or the role hierarchy.';
            
            res.nextSteps = '1. Check Organization-Wide Defaults in Setup > Sharing Settings\n' +
                '2. Review sharing rules for ' + req.resourceName + '\n' +
                '3. Verify the user\'s role hierarchy position\n' +
                '4. Check for any manual sharing or team access';
        } else {
            res.accessSource = String.join(new List<String>(new Set<String>(accessSources)), ' + ');
            res.explanation = 'User "' + req.principalName + '" has access to ' + req.resourceName + ' from the following sources:\n\n' + String.join(details, '\n');
            
            // Determine severity based on access type
            Boolean hasModifyAll = res.explanation.contains('Modify All Data');
            Boolean hasViewAll = res.explanation.contains('View All Data');
            Boolean hasMultipleSources = accessSources.size() > 2;
            
            if (hasModifyAll) {
                res.severity = 'High';
                res.riskAssessment = 'High Risk - User has Modify All Data permission, granting full CRUD access to all objects including ' + req.resourceName + '. This is a highly privileged permission.';
            } else if (hasViewAll) {
                res.severity = 'Medium';
                res.riskAssessment = 'Medium Risk - User has View All Data permission, granting read access to all records in ' + req.resourceName + ' regardless of sharing settings.';
            } else if (hasMultipleSources) {
                res.severity = 'Medium';
                res.riskAssessment = 'Medium Risk - Access comes from multiple sources (' + accessSources.size() + '), which may indicate over-provisioning of permissions.';
            } else {
                res.severity = 'Low';
                res.riskAssessment = 'Low Risk - Access is granted through standard object-level permissions.';
            }
            
            // Build conversational summary
            Integer sourceCount = new Set<String>(accessSources).size();
            res.conversationalSummary = 'I found that ' + req.principalName + ' has access to ' + req.resourceName + ' through ' + sourceCount + ' permission source(s). ';
            
            if (hasModifyAll) {
                res.conversationalSummary += 'This includes Modify All Data permission, which is a very powerful permission that grants full access to all data. ';
            } else if (hasViewAll) {
                res.conversationalSummary += 'This includes View All Data permission, allowing them to see all records. ';
            }
            
            res.conversationalSummary += 'I\'ve provided a detailed breakdown of each permission source below.';
            
            // Build next steps based on severity
            if (hasModifyAll || hasViewAll) {
                res.nextSteps = '1. ⚠️ REVIEW: Verify if this user requires system-level permissions\n' +
                    '2. AUDIT: Document the business justification for this level of access\n' +
                    '3. CONSIDER: Can access be granted through object-specific permissions instead?\n' +
                    '4. MONITOR: Enable field audit trail and login forensics for this user\n' +
                    '5. SCHEDULE: Plan quarterly access reviews for highly privileged users';
            } else if (hasMultipleSources) {
                res.nextSteps = '1. CONSOLIDATE: Consider combining permissions into a single permission set\n' +
                    '2. REVIEW: Check if any permission sources are redundant\n' +
                    '3. DOCUMENT: Ensure business justification exists for each source\n' +
                    '4. OPTIMIZE: Remove unnecessary permission layers';
            } else {
                res.nextSteps = '1. VERIFY: Confirm the access level matches business requirements\n' +
                    '2. DOCUMENT: Ensure access is properly justified and approved\n' +
                    '3. MONITOR: Periodically review access during quarterly audits';
            }
        }
    }
}