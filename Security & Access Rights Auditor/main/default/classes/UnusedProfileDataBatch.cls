public with sharing class UnusedProfileDataBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) {
         System.debug('Batch started'); 
        if (Test.isRunningTest()){
             return Database.getQueryLocator([SELECT Id, ProfileId FROM User WHERE Id != null LIMIT 200]);
        }else{
             return Database.getQueryLocator([SELECT Id, ProfileId FROM User WHERE Id != null LIMIT 5000]);
        }
    }

    
   /*public void execute(Database.BatchableContext context, List<User> scope) {
    System.debug('Batch execution started');
    Set<Id> assignedProfileIds = new Set<Id>();
    Set<Id> usedProfileIds = new Set<Id>();
    Map<String, SA_Audit__Audithistory__c> auditRecordsMap = new Map<String, SA_Audit__Audithistory__c>();

    // Query User profiles
    for (User user : scope) {
        assignedProfileIds.add(user.ProfileId);
    }

    // Query PermissionSetAssignment records
    for (PermissionSetAssignment assignment : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE Id != null Limit 5000]) {
        usedProfileIds.add(assignment.PermissionSetId);
    }

    // Query unassigned Profiles
    for (List<Profile> unassignedProfiles : [SELECT Id, Name, LastModifiedDate FROM Profile WHERE Id NOT IN :assignedProfileIds Limit 5000]) {
        for (Profile unassignedProfile : unassignedProfiles) {
            if (!usedProfileIds.contains(unassignedProfile.Id)) {
                // Check if the audit record already exists in the map
                if (!auditRecordsMap.containsKey(unassignedProfile.Name)) {
                    // Create SA_Audit__Audithistory__c record and add it to the map
                    SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c(
                        Name = unassignedProfile.Name,
                        SA_Audit__Profile_Name__c = unassignedProfile.Name,
                        Last_login_date__c = String.valueOf(unassignedProfile.LastModifiedDate)
                    );
                    auditRecordsMap.put(unassignedProfile.Name, auditRecord);
                }
            }
        }
    }

    // Insert records
    if (!auditRecordsMap.isEmpty()) {
        System.debug('Inserting audit records');
        try {
            insert auditRecordsMap.values();
        } catch (Exception ex) {
            System.debug('Exception occurred while inserting audit records: ' + ex.getMessage());
        }
    } else {
        System.debug('No audit records to insert');
    }
}*/
    public void execute(Database.BatchableContext context, List<User> scope) {
    System.debug('Batch execution started');
    Set<Id> assignedProfileIds = new Set<Id>();
    Set<Id> usedProfileIds = new Set<Id>();

    // Collect existing audit records in a Map for quick access
    Map<String, SA_Audit__Audithistory__c> existingRecordsMap = new Map<String, SA_Audit__Audithistory__c>();
    for (SA_Audit__Audithistory__c record : [SELECT Id, Name, SA_Audit__Profile_Name__c FROM SA_Audit__Audithistory__c Limit 30000]) {
        existingRecordsMap.put(record.SA_Audit__Profile_Name__c, record);
    }

    List<SA_Audit__Audithistory__c> recordsToUpdate = new List<SA_Audit__Audithistory__c>();
    List<SA_Audit__Audithistory__c> recordsToInsert = new List<SA_Audit__Audithistory__c>();

    // Query User profiles
    for (User user : scope) {
        assignedProfileIds.add(user.ProfileId);
    }

    // Query PermissionSetAssignment records
    for (PermissionSetAssignment assignment : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE Id != null Limit 5000]) {
        usedProfileIds.add(assignment.PermissionSetId);
    }

    // Query unassigned Profiles
    for (Profile unassignedProfile : [SELECT Id, Name, LastModifiedDate FROM Profile WHERE Id NOT IN :assignedProfileIds Limit 5000]) {
        if (!usedProfileIds.contains(unassignedProfile.Id)) {
            // Determine if an update is needed or a new record should be created
            SA_Audit__Audithistory__c existingRecord = existingRecordsMap.get(unassignedProfile.Name);
            if (existingRecord != null) {
                 if ( Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isAccessible() &&   
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isCreateable() &&
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isUpdateable() && 
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Last_login_date__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Last_login_date__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Last_login_date__c.isUpdateable()) {
                existingRecord.SA_Audit__Last_login_date__c = String.valueOf(unassignedProfile.LastModifiedDate);
                recordsToUpdate.add(existingRecord);
                }
            }
            else {
                if ( Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isAccessible() &&   
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isCreateable() &&
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isUpdateable() && 
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Profile_Name__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Profile_Name__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Profile_Name__c.isUpdateable()&&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Last_login_date__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Last_login_date__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__Last_login_date__c.isUpdateable()
                   ) {
                SA_Audit__Audithistory__c newRecord = new SA_Audit__Audithistory__c(
                    Name = unassignedProfile.Name,
                    SA_Audit__Profile_Name__c = unassignedProfile.Name,
                    SA_Audit__Last_login_date__c = String.valueOf(unassignedProfile.LastModifiedDate)
                );
                     recordsToInsert.add(newRecord);
                }
               
            }
        }
    }

    // Insert or update records as necessary
    if (!recordsToInsert.isEmpty()) {
        insert recordsToInsert;
        System.debug('Inserted new audit records');
    }
    if (!recordsToUpdate.isEmpty()) {
        update recordsToUpdate;
        System.debug('Updated existing audit records');
    }
}



    public void finish(Database.BatchableContext context) {
        System.debug('Batch execution finished');
        if (!Test.isRunningTest()) {
        Database.executeBatch(new unusedPermissionsetsDataforReportBatch(), 50);
    }
        
    }
}