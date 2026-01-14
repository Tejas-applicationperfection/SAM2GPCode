public with sharing class rolesDataforReportBatch implements Database.Batchable<sObject>, Database.Stateful {
    private List<UserRole> rolesWithMembers;
    private List<SA_Audit__AuditHistory__c> roleAuditRecords;

    public RolesDataforReportBatch() {
        roleAuditRecords = new List<SA_Audit__AuditHistory__c>();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        
        
        if (Test.isRunningTest()){
             return Database.getQueryLocator([
            SELECT Name, DeveloperName, (SELECT Name FROM Users)
            FROM UserRole WHERE Name != null Limit 10
        ]);
        }else{
            return Database.getQueryLocator([
            SELECT Name, DeveloperName, (SELECT Name FROM Users)
            FROM UserRole WHERE Name != null Limit 1000
        ]);
        }
        
        
        
    }

    public void execute(Database.BatchableContext context, List<UserRole> scope) {
        // Initialize variables
        if (rolesWithMembers == null) {
            rolesWithMembers = new List<UserRole>();
        }

        // Process records
        rolesWithMembers.addAll(scope);

        for (UserRole role : scope) {
            SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();

            if (Schema.sObjectType.AuditHistory__c.fields.Name.isCreateable() &&
                Schema.sObjectType.AuditHistory__c.fields.Name.isAccessible() &&
                Schema.sObjectType.AuditHistory__c.fields.Name.isUpdateable()) {
                auditRecord.Name = 'Audit Record for Role ' + role.DeveloperName;
            }

            if (Schema.sObjectType.AuditHistory__c.fields.UsedRoles__c.isCreateable() &&
                Schema.sObjectType.AuditHistory__c.fields.UsedRoles__c.isAccessible() &&
                Schema.sObjectType.AuditHistory__c.fields.UsedRoles__c.isUpdateable()) {
                auditRecord.SA_Audit__UsedRoles__c = role.DeveloperName;
            }

            if (Schema.sObjectType.AuditHistory__c.fields.RolesMember__c.isCreateable() &&
                Schema.sObjectType.AuditHistory__c.fields.RolesMember__c.isAccessible() &&
                Schema.sObjectType.AuditHistory__c.fields.RolesMember__c.isUpdateable()) {
                String memberNames = '';
                for (User user : role.Users) {
                    memberNames += user.Name + ', ';
                }
                memberNames = memberNames.removeEnd(', '); // Remove trailing comma and space 
                auditRecord.SA_Audit__RolesMember__c = memberNames;
            }

            roleAuditRecords.add(auditRecord);
        }
    }

    public void finish(Database.BatchableContext context) {
        // Upsert audit records
        try {
            if (!roleAuditRecords.isEmpty()) {
                upsert roleAuditRecords;
            }
        } catch (DmlException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                System.debug('Error upserting audit records: ' + e.getDmlMessage(i));
            }
        }
         Database.executeBatch(new PublicGroupsDataforReportBatch(), 50);
    }
}