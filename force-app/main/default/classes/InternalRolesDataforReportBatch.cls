public with sharing class InternalRolesDataforReportBatch implements Database.Batchable<sObject>, Database.Stateful {
    private List<UserRole> totalInternalRoles;
    
    private List<SA_Audit__AuditHistory__c> auditRecords;
    
    public InternalRolesDataforReportBatch() {
        totalInternalRoles = new List<UserRole>();
        
        auditRecords = new List<SA_Audit__AuditHistory__c>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext context) {
        
        
        if (Test.isRunningTest()){
            return Database.getQueryLocator([
                SELECT Id, DeveloperName,
                (SELECT User.Name FROM Users)
                FROM UserRole
                WHERE PortalType IN ('None', 'None') Limit 10
            ]);
        }else{
            return Database.getQueryLocator([
                SELECT Id, DeveloperName,
                (SELECT User.Name FROM Users)
                FROM UserRole
                WHERE PortalType IN ('None', 'None')
            ]);
        }
        
    }
    
    public void execute(Database.BatchableContext context, List<UserRole> scope) {
        if (totalInternalRoles == null) {
            totalInternalRoles = new List<UserRole>();
        }
        
        
        totalInternalRoles.addAll(scope);
    }
    
    /* public void finish(Database.BatchableContext context) {
for (UserRole internalRole : totalInternalRoles) {
SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();
auditRecord.Name = 'Audit Record for Internal Role ' + internalRole.DeveloperName;
if (!internalRole.Users.isEmpty()) {
auditRecord.SA_Audit__UsedInternalRoles__c = internalRole.DeveloperName;
List<String> memberNames = new List<String>();
for (User user : internalRole.Users) {
memberNames.add(user.Name);
}
auditRecord.SA_Audit__InternalRoleMember__c = String.join(memberNames, ', ');
} else {
auditRecord.SA_Audit__UnusedInternalRoles__c = internalRole.DeveloperName;
}
auditRecords.add(auditRecord);
}

try {
if (!auditRecords.isEmpty()) {
upsert auditRecords;
}
} catch (DmlException e) {
for (Integer i = 0; i < e.getNumDml(); i++) {
System.debug('Error upserting audit records: ' + e.getDmlMessage(i));
}
}
Database.executeBatch(new ExternalRolesDataforReportBatch(),100);
}*/
    public void finish(Database.BatchableContext context) {
        for (UserRole internalRole : totalInternalRoles) {
            SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();
            // Check if fields are createable and updateable before assigning values
            if (Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__UsedInternalRoles__c.isCreateable() && 
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__UsedInternalRoles__c.isUpdateable() && 
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isCreateable() && 
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isUpdateable()) {
                    
                    auditRecord.Name = 'Audit Record for Internal Role ' + internalRole.DeveloperName;
                    
                    
                    if (!internalRole.Users.isEmpty()) {
                        auditRecord.SA_Audit__UsedInternalRoles__c = internalRole.DeveloperName;
                        List<String> memberNames = new List<String>();
                        for (User user : internalRole.Users) {
                            memberNames.add(user.Name);
                        }
                        
                        // Check if InternalRoleMember field is createable and updateable
                        if (Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__InternalRoleMember__c.isCreateable() && 
                            Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__InternalRoleMember__c.isUpdateable()) {
                                auditRecord.SA_Audit__InternalRoleMember__c = String.join(memberNames, ', ');
                            }
                    } else {
                        // Check if UnusedInternalRoles field is createable and updateable
                        if (Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__UnusedInternalRoles__c.isCreateable() && 
                            Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__UnusedInternalRoles__c.isUpdateable()) {
                                auditRecord.SA_Audit__UnusedInternalRoles__c = internalRole.DeveloperName;
                            }
                    }
                }
            auditRecords.add(auditRecord);
        }
        
        try {
            if (!auditRecords.isEmpty()) {
                upsert auditRecords;
            }
        } catch (DmlException e) {
            for (Integer i = 0; i < e.getNumDml(); i++) {
                System.debug('Error upserting audit records: ' + e.getDmlMessage(i));
            }
        }
        
        Database.executeBatch(new ExternalRolesDataforReportBatch(), 100);
    }
    
}