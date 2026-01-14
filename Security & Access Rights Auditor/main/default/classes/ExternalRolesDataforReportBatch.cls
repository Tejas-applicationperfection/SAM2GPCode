public with sharing class ExternalRolesDataforReportBatch implements Database.Batchable<sObject>, Database.Stateful {
     
    private List<UserRole> totalExternalRoles;
    private List<SA_Audit__AuditHistory__c> auditRecords;

    public ExternalRolesDataforReportBatch() {
        
        totalExternalRoles = new List<UserRole>();
        auditRecords = new List<SA_Audit__AuditHistory__c>();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([ SELECT Id, DeveloperName,  (SELECT User.Name FROM Users Limit 2000) FROM UserRole WHERE PortalType != 'None' ]);
    }

    public void execute(Database.BatchableContext context, List<UserRole> scope) {
        
        if (totalExternalRoles == null) {
            totalExternalRoles = new List<UserRole>();
        }

        totalExternalRoles.addAll(scope);
    }

    public void finish(Database.BatchableContext context) {
        for (UserRole externalRole : totalExternalRoles) {
            SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c();
            
            
            if ( Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isAccessible() &&   
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isCreateable() &&
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isUpdateable() && 
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedExternalRoles__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedExternalRoles__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedExternalRoles__c.isUpdateable()&&
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedExternalRoles__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedExternalRoles__c.isAccessible() && 
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedExternalRoles__c.isUpdateable()) {
                    auditRecord.Name = 'Audit Record for External Role ' + externalRole.DeveloperName; 
                    if (!externalRole.Users.isEmpty()) {
                        auditRecord.SA_Audit__UsedExternalRoles__c = externalRole.DeveloperName;
                    } else {
                        auditRecord.SA_Audit__UnusedExternalRoles__c = externalRole.DeveloperName;
                    }
                }
            
            List<String> memberNames = new List<String>();
            for (User user : externalRole.Users) {
                memberNames.add(user.Name);
            }
            if (Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__ExternalRoleMember__c.isCreateable() && 
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__ExternalRoleMember__c.isAccessible() && 
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__ExternalRoleMember__c.isUpdateable() )
            {
                auditRecord.SA_Audit__ExternalRoleMember__c = String.join(memberNames, ', ');
            } 
            auditRecords.add(auditRecord);
        }

        try {
            if (!auditRecords.isEmpty()) {
                upsert auditRecords;
            }
        } catch (DmlException e) {
           /* for (Integer i = 0; i < e.getNumDml(); i++) {
                System.debug('Error upserting audit records: ' + e.getDmlMessage(i));
            }*/
        }
    }
}