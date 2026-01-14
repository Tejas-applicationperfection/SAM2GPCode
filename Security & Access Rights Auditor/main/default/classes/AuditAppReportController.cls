public with sharing class AuditAppReportController  {
    
    
    public void runStaticMethods() {
        ClearDataforReport();
       // unusedProfileDataforReport();
        //unusedPermissionsetsDataforReport();
       // PermissionSetGroupsDataforReport();
       // rolesDataforReport();
        //publicGroupsDataforReport();
        //internalrolesDataforReport();
    }
   @AuraEnabled
    public static void ClearDataforReport() { 
        Database.executeBatch(new ClearDataforReportBatch(),100);
    } 
     
   /* @AuraEnabled
    public static void unusedProfileDataforReport() {
        Database.executeBatch(new UnusedProfileDataBatch(),50);
        
    }*/

    
/*     @AuraEnabled
    public static void unusedPermissionsetsDataforReport() {
           Database.executeBatch(new unusedPermissionsetsDataforReportBatch(),100);
       
        // Query used Permission Sets and their Assignee names
        List<PermissionSet> usedPermissionSets = [SELECT Id, Name, 
                                                  (SELECT Assignee.Name FROM Assignments)
                                                  FROM PermissionSet WHERE NOT Name LIKE 'X00%'];
        
        // Create a set to store Permission Set Ids with assignments
        Set<Id> usedPermissionSetIds = new Set<Id>();
        for (PermissionSet ps : usedPermissionSets) {
            usedPermissionSetIds.add(ps.Id);
        } 
        
        // Query existing Audithistory__c records by Name
        Set<String> existingAuditRecordNames = new Set<String>();
        List<SA_Audit__Audithistory__c> existingAuditRecords = [SELECT Name FROM SA_Audit__Audithistory__c  WHERE Name != NULL];
        for (SA_Audit__Audithistory__c record : existingAuditRecords) {
            existingAuditRecordNames.add(record.Name);
        }
        
        List<SA_Audit__Audithistory__c> auditRecords = new List<SA_Audit__Audithistory__c>();
        
        for (PermissionSet ps : usedPermissionSets) {
            if (!existingAuditRecordNames.contains(ps.Name)) {
                SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();
                
                // Check FLS for the Name field
                if (Schema.sObjectType.AuditHistory__c.fields.Name.isCreateable() &&   Schema.sObjectType.AuditHistory__c.fields.Name.isAccessible()) {
                       auditRecord.Name =  ps.Name;
                    }
                
                // Check FLS for the UsedPermissionsetsName__c field
                if (Schema.sObjectType.AuditHistory__c.fields.UsedPermissionsetsName__c.isCreateable() &&   Schema.sObjectType.AuditHistory__c.fields.UsedPermissionsetsName__c.isAccessible()) {
                       auditRecord.SA_Audit__UsedPermissionsetsName__c = ps.Name;
                    }
                
                if (ps.Assignments != null && !ps.Assignments.isEmpty()) {
                    String assigneeNames = '';
                    for (PermissionSetAssignment assignment : ps.Assignments) {
                        assigneeNames += assignment.Assignee.Name + ', ';
                    }
                    assigneeNames = assigneeNames.removeEnd(', '); // Remove trailing comma and space
                    
                    // Check FLS for the PermissionMember__c field
                    if (Schema.sObjectType.AuditHistory__c.fields.PermissionMember__c.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.PermissionMember__c.isAccessible()) {
                           auditRecord.SA_Audit__PermissionMember__c = assigneeNames;
                        }
                }
                
                auditRecords.add(auditRecord);
            }
        }
        
        // Insert the Audithistory__c records
        if (!auditRecords.isEmpty()) {
            insert auditRecords;
        }
    }
    
    @AuraEnabled
    public static void PermissionSetGroupsDataforReport() {
        // Retrieve all PermissionSetAssignments, including members and groups
        List<PermissionSetAssignment> allPermissionSetAssignments = [
            SELECT Assignee.Name, PermissionSetGroup.DeveloperName
            FROM PermissionSetAssignment
            WHERE PermissionSetGroup.DeveloperName != null
            ORDER BY PermissionSetGroup.DeveloperName ASC
        ];
        
        // Create a set to store the DeveloperNames of used PermissionSetGroups
        Set<String> usedPermissionSetGroups = new Set<String>();
        
        // Create a map to group PermissionSetAssignments by PermissionSetGroup DeveloperName
        Map<String, List<String>> permissionSetGroupsMap = new Map<String, List<String>>();
        
        for (PermissionSetAssignment psAssignment : allPermissionSetAssignments) {
            String groupName = psAssignment.PermissionSetGroup.DeveloperName;
            usedPermissionSetGroups.add(groupName); // Add to the set of used groups
            
            if (!permissionSetGroupsMap.containsKey(groupName)) {
                permissionSetGroupsMap.put(groupName, new List<String>());
            }
            permissionSetGroupsMap.get(groupName).add(psAssignment.Assignee.Name);
        }
        
        // Query all PermissionSetGroups
        List<PermissionSetGroup> allPermissionSetGroups = [
            SELECT DeveloperName
            FROM PermissionSetGroup  WHERE DeveloperName != NULL
        ];
        
        // Create a set of DeveloperNames for all PermissionSetGroups
        Set<String> allPermissionSetGroupNames = new Set<String>();
        for (PermissionSetGroup groupf : allPermissionSetGroups) {
            allPermissionSetGroupNames.add(groupf.DeveloperName);
        }
        
        List<SA_Audit__AuditHistory__c> auditRecords = new List<SA_Audit__AuditHistory__c>();
        
        for (String groupName : allPermissionSetGroupNames) {
            SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();
            
            if( Schema.sObjectType.AuditHistory__c.fields.Name.isCreateable() &&
               Schema.sObjectType.AuditHistory__c.fields.Name.isAccessible() &&
               Schema.sObjectType.AuditHistory__c.fields.Name.isUpdateable()){
                   auditRecord.Name = 'Audit Record for permissionSetsGroup ' + groupName;
               }
            
            
            if (Schema.sObjectType.AuditHistory__c.fields.UsedPermissionSetsGroup__c.isCreateable() && Schema.sObjectType.AuditHistory__c.fields.UsedPermissionSetsGroup__c.isAccessible() &&    Schema.sObjectType.AuditHistory__c.fields.UsedPermissionSetsGroup__c.isUpdateable() &&   Schema.sObjectType.AuditHistory__c.fields.permissionSetsGroupMember__c.isCreateable() && Schema.sObjectType.AuditHistory__c.fields.permissionSetsGroupMember__c.isAccessible() &&   Schema.sObjectType.AuditHistory__c.fields.permissionSetsGroupMember__c.isUpdateable()&&  Schema.sObjectType.AuditHistory__c.fields.UnusedPermissionSetsGroup__c.isCreateable() && Schema.sObjectType.AuditHistory__c.fields.UnusedPermissionSetsGroup__c.isAccessible() &&  Schema.sObjectType.AuditHistory__c.fields.UnusedPermissionSetsGroup__c.isUpdateable()) {
                    if (usedPermissionSetGroups.contains(groupName)) {
                        // This group is used
                        auditRecord.SA_Audit__UsedPermissionSetsGroup__c = groupName;
                        List<String> assigneeNames = permissionSetGroupsMap.get(groupName);
                        if (!assigneeNames.isEmpty()) {
                            auditRecord.SA_Audit__permissionSetsGroupMember__c = String.join(assigneeNames, ', ');
                        }
                    } else {
                        // This group is unused
                        auditRecord.SA_Audit__UnusedPermissionSetsGroup__c = groupName;
                    }
                }
            auditRecords.add(auditRecord);
        } 
        upsert auditRecords;
    }*/
   /* @AuraEnabled
    public static void rolesDataforReport() {
        // Fetch roles along with their members (users)
        List<UserRole> rolesWithMembers = [
            SELECT Name, DeveloperName, 
            (SELECT Name FROM Users)
            FROM UserRole Where Name != null
        ];
        
        List<SA_Audit__AuditHistory__c> RoleAuditRecords = new List<SA_Audit__AuditHistory__c>();
        
        // Process roles with members
        for (UserRole role : rolesWithMembers) {
            SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();
            
            if ( Schema.sObjectType.AuditHistory__c.fields.Name.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.Name.isAccessible() &&  Schema.sObjectType.AuditHistory__c.fields.Name.isUpdateable()) {
                    auditRecord.Name = 'Audit Record for Role ' + role.DeveloperName; }
            
            
            // Check FLS for the UsedRoles__c field
            if (Schema.sObjectType.AuditHistory__c.fields.UsedRoles__c.isCreateable() && Schema.sObjectType.AuditHistory__c.fields.UsedRoles__c.isAccessible() &&  Schema.sObjectType.AuditHistory__c.fields.UsedRoles__c.isUpdateable()) { 
                    auditRecord.SA_Audit__UsedRoles__c = role.DeveloperName;
                }
            
            // Check FLS for the RolesMember__c field
            if (Schema.sObjectType.AuditHistory__c.fields.RolesMember__c.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.RolesMember__c.isAccessible()&& Schema.sObjectType.AuditHistory__c.fields.RolesMember__c.isUpdateable()) {
                   
                    String memberNames = '';
                    for (User user : role.Users) {
                        memberNames += user.Name + ', ';
                    }
                    memberNames = memberNames.removeEnd(', '); // Remove trailing comma and space 
                    auditRecord.SA_Audit__RolesMember__c = memberNames;
                }
            
            RoleAuditRecords.add(auditRecord);
        }
        
        // Insert all audit records into AuditHistory__c
        upsert RoleAuditRecords;
    }
    
    
    @AuraEnabled
    public static void publicGroupsDataforReport() {
        List<Group> publicGroups = [SELECT DeveloperName, (SELECT UserOrGroupId FROM GroupMembers)
                                    FROM Group
                                    WHERE Type = 'Regular' AND DeveloperName != 'AllInternalUsers'];
        
        List<SA_Audit__AuditHistory__c> auditRecords = new List<SA_Audit__AuditHistory__c>();
        
        Set<String> userOrGroupIds = new Set<String>();
        Map<String, String> userOrGroupNames = new Map<String, String>();
        
        for (Group publicGroup : publicGroups) {
            for (GroupMember groupMember : publicGroup.GroupMembers) {
                userOrGroupIds.add(groupMember.UserOrGroupId);
            }
        }
        
        // Query to fetch user names
        for (User user : [SELECT Id, Name FROM User WHERE Id IN :userOrGroupIds]) {
            userOrGroupNames.put(user.Id, user.Name);
        }
        
        // Query to fetch group names
        for (Group groupf : [SELECT Id, Name FROM Group WHERE Id IN :userOrGroupIds]) {
            userOrGroupNames.put(groupf.Id, groupf.Name);
        }
        
        // Query to fetch role names
        for (UserRole role : [SELECT Id, Name FROM UserRole WHERE Id IN :userOrGroupIds]) {
            userOrGroupNames.put(role.Id, role.Name);
        }
        
        for (Group publicGroup : publicGroups) {
            SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c(); 
            if (Schema.sObjectType.AuditHistory__c.fields.UsedPublicGroups__c.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.UsedPublicGroups__c.isAccessible() &&  Schema.sObjectType.AuditHistory__c.fields.UsedPublicGroups__c.isUpdateable() &&  Schema.sObjectType.AuditHistory__c.fields.UnusedPublicGroups__c.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.UnusedPublicGroups__c.isAccessible() &&   Schema.sObjectType.AuditHistory__c.fields.UnusedPublicGroups__c.isUpdateable() &&  Schema.sObjectType.AuditHistory__c.fields.Name.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.Name.isAccessible() &&  Schema.sObjectType.AuditHistory__c.fields.Name.isUpdateable() ) {
                     auditRecord.Name = 'Audit Record for Group ' + publicGroup.DeveloperName; 
                    if (publicGroup.GroupMembers.isEmpty()) {
                        auditRecord.SA_Audit__UnusedPublicGroups__c = publicGroup.DeveloperName;
                    } else {
                        auditRecord.SA_Audit__UsedPublicGroups__c = publicGroup.DeveloperName; 
                        List<String> memberNames = new List<String>(); 
                        for (GroupMember publicGroupMember : publicGroup.GroupMembers) {
                            String userOrGroupId = publicGroupMember.UserOrGroupId;
                            String memberName = userOrGroupNames.get(userOrGroupId);
                            if (memberName != null) {
                                memberNames.add(memberName);
                            }
                        } 
                        // Check FLS for the PublicGroupMember__c field
                        if (Schema.sObjectType.AuditHistory__c.fields.PublicGroupMember__c.isCreateable() &&
                            Schema.sObjectType.AuditHistory__c.fields.PublicGroupMember__c.isAccessible() 
                            &&
                            Schema.sObjectType.AuditHistory__c.fields.PublicGroupMember__c.isUpdateable()) { 
                                auditRecord.SA_Audit__PublicGroupMember__c = String.join(memberNames, ', ');
                            }
                    } 
                    auditRecords.add(auditRecord);
                }
        } 
        upsert auditRecords;
    }
     
    //===================================================================================================================
    // Fetch internal roles (PortalType = 'None') and their members (users)
    @AuraEnabled
    public static void internalrolesDataforReport() {
        List<UserRole> totalInternalRoles = [SELECT Id, DeveloperName,
                                             (SELECT User.Name FROM Users)
                                             FROM UserRole
                                             WHERE PortalType = 'None'];
        
        // Fetch external roles (PortalType != 'None') and their members (users)
        List<UserRole> totalExternalRoles = [SELECT Id, DeveloperName,
                                             (SELECT User.Name FROM Users)
                                             FROM UserRole
                                             WHERE PortalType != 'None'];
        
        List<SA_Audit__AuditHistory__c> internalauditRecords = new List<SA_Audit__AuditHistory__c>();
        
        // Process internal roles
        for (UserRole internalRole : totalInternalRoles) {
            SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();
            if (Schema.sObjectType.AuditHistory__c.fields.Name.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.Name.isAccessible() && Schema.sObjectType.AuditHistory__c.fields.Name.isUpdateable() &&   Schema.sObjectType.AuditHistory__c.fields.UsedInternalRoles__c.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.UsedInternalRoles__c.isAccessible()&&   Schema.sObjectType.AuditHistory__c.fields.UsedInternalRoles__c.isUpdateable()&&  Schema.sObjectType.AuditHistory__c.fields.UnusedInternalRoles__c.isCreateable() &&   Schema.sObjectType.AuditHistory__c.fields.UnusedInternalRoles__c.isAccessible()&& Schema.sObjectType.AuditHistory__c.fields.UnusedInternalRoles__c.isUpdateable()
               ) {   auditRecord.Name = 'Audit Record for Internal Role ' + internalRole.DeveloperName; 
                   if (!internalRole.Users.isEmpty()) {
                       auditRecord.SA_Audit__UsedInternalRoles__c = internalRole.DeveloperName;
                   } else {
                       auditRecord.SA_Audit__UnusedInternalRoles__c = internalRole.DeveloperName;
                   }
               } 
            // Create a custom field (e.g., InternalRoleMembers__c) in AuditHistory__c to store member information
            List<String> memberNames = new List<String>();
            for (User user : internalRole.Users) {
                if (Schema.sObjectType.user.fields.Name.isCreateable() && Schema.sObjectType.user.fields.Name.isAccessible() && Schema.sObjectType.user.fields.Name.isUpdateable() ) {
                        memberNames.add(user.Name);
                        
                    }}
            if (Schema.sObjectType.AuditHistory__c.fields.InternalRoleMember__c.isCreateable() && Schema.sObjectType.AuditHistory__c.fields.InternalRoleMember__c.isAccessible()&&  Schema.sObjectType.AuditHistory__c.fields.InternalRoleMember__c.isUpdateable()){
                    
                    auditRecord.SA_Audit__InternalRoleMember__c = String.join(memberNames, ', ');  
                } 
            internalauditRecords.add(auditRecord);
        }
        
        // Process external roles
        for (UserRole externalRole : totalExternalRoles) {
            SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();
            auditRecord.Name = 'Audit Record for External Role ' + externalRole.DeveloperName;
            
            if ( Schema.sObjectType.AuditHistory__c.fields.UsedExternalRoles__c.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.UsedExternalRoles__c.isAccessible() &&  Schema.sObjectType.AuditHistory__c.fields.UsedExternalRoles__c.isUpdateable()&&  Schema.sObjectType.AuditHistory__c.fields.UnusedExternalRoles__c.isCreateable() &&  Schema.sObjectType.AuditHistory__c.fields.UnusedExternalRoles__c.isAccessible() &&  Schema.sObjectType.AuditHistory__c.fields.UnusedExternalRoles__c.isUpdateable()) {
                    
                    if (!externalRole.Users.isEmpty()) {
                        auditRecord.SA_Audit__UsedExternalRoles__c = externalRole.DeveloperName;
                    } else {
                        auditRecord.SA_Audit__UnusedExternalRoles__c = externalRole.DeveloperName;
                    }
                }
            // Create a custom field (e.g., ExternalRoleMembers__c) in AuditHistory__c to store member information
            List<String> memberNames = new List<String>();
            for (User user : externalRole.Users) {
                memberNames.add(user.Name);
            }
            if (Schema.sObjectType.AuditHistory__c.fields.ExternalRoleMember__c.isCreateable() && Schema.sObjectType.AuditHistory__c.fields.ExternalRoleMember__c.isAccessible() &&  Schema.sObjectType.AuditHistory__c.fields.ExternalRoleMember__c.isUpdateable() )
            {
                auditRecord.SA_Audit__ExternalRoleMember__c = String.join(memberNames, ', ');
            } 
            internalauditRecords.add(auditRecord);
        }
        
        // Insert audit records into AuditHistory__c
        upsert internalauditRecords;
    }*/
}