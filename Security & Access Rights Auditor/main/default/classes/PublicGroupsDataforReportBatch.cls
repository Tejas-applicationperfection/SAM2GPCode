public with sharing class PublicGroupsDataforReportBatch implements Database.Batchable<SObject>, Database.Stateful {
    public Database.QueryLocator start(Database.BatchableContext BC) {
        if (Test.isRunningTest()){
           return Database.getQueryLocator([
            SELECT DeveloperName, (SELECT UserOrGroupId FROM GroupMembers LIMIT 2000)
            FROM Group
            WHERE Type = 'Regular' AND DeveloperName != 'AllInternalUsers' limit 10
        ]);
        }else{
          return Database.getQueryLocator([
            SELECT Name FROM SA_Audit__Audithistory__c WHERE Name != NULL LIMIT 40000
        ]);
        }
    }

    public void execute(Database.BatchableContext BC, List<SA_Audit__Audithistory__c> scope) {
     try {   List<SA_Audit__AuditHistory__c> auditRecords = new List<SA_Audit__AuditHistory__c>();
        Set<String> existingAuditRecordNames = new Set<String>();
        for (SA_Audit__Audithistory__c record : scope) {
            existingAuditRecordNames.add(record.Name);
        }
        Set<Id> userOrGroupIds = new Set<Id>();
        Map<Id, String> userOrGroupNames = new Map<Id, String>();

        // Collect UserOrGroupIds
        for (Group publicGroup : [SELECT DeveloperName, (SELECT UserOrGroupId FROM GroupMembers LIMIT 5000)
            FROM Group
            WHERE Type = 'Regular' AND DeveloperName != 'AllInternalUsers'  Limit 1000]) {
            for (GroupMember groupMember : publicGroup.GroupMembers) {
                userOrGroupIds.add(groupMember.UserOrGroupId);
            }
        }

        
            // Fetch user names
            for (User user : [SELECT Id, Name FROM User WHERE Id IN :userOrGroupIds]) {
                userOrGroupNames.put(user.Id, user.Name);
            }

            // Fetch group names
            for (Group groupf : [SELECT Id, Name FROM Group WHERE Id IN :userOrGroupIds]) {
                userOrGroupNames.put(groupf.Id, groupf.Name);
            }

            // Fetch role names
            for (UserRole role : [SELECT Id, Name FROM UserRole WHERE Id IN :userOrGroupIds]) {
                userOrGroupNames.put(role.Id, role.Name);
            }

            // Create audit records
            for (Group  publicGroup : [SELECT DeveloperName, (SELECT UserOrGroupId FROM GroupMembers LIMIT 5000)
            FROM Group
            WHERE Type = 'Regular' AND DeveloperName != 'AllInternalUsers']) {
                SA_Audit__AuditHistory__c auditRecord = new SA_Audit__AuditHistory__c();

                if ( Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedPublicGroups__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedPublicGroups__c.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPublicGroups__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPublicGroups__c.isUpdateable() && 
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__PublicGroupMember__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__PublicGroupMember__c.isUpdateable()) {
                        if (!existingAuditRecordNames.contains(publicGroup.DeveloperName)) {
                            auditRecord.Name = publicGroup.DeveloperName;
                            
                           if (publicGroup.GroupMembers.isEmpty()) {
                               auditRecord.SA_Audit__UnusedPublicGroups__c = publicGroup.DeveloperName;
                           } else {
                               auditRecord.SA_Audit__UsedPublicGroups__c = publicGroup.DeveloperName;
                               List<String> memberNames = new List<String>();
                               
                               for (GroupMember publicGroupMember : publicGroup.GroupMembers) {
                                   String memberName = userOrGroupNames.get(publicGroupMember.UserOrGroupId);
                                   if (memberName != null) {
                                       memberNames.add(memberName);
                                   }
                               }
                               
                               
                               auditRecord.SA_Audit__PublicGroupMember__c = String.join(memberNames, ', ');
                               
                           }
                           
                           auditRecords.add(auditRecord);
                       }
                   }
            }

            if (!auditRecords.isEmpty()) {
                upsert auditRecords;
            }
        } catch (Exception e) {
            // Handle any errors that occur during the process
            System.debug('Error: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC) {
          Database.executeBatch(new InternalRolesDataforReportBatch(), 50);
    }
}