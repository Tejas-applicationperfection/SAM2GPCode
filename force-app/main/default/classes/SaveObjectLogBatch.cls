public with sharing class SaveObjectLogBatch implements Database.Batchable<sObject>, Database.Stateful {
    private String selectedObject;
    private Map<Id, String> serializeWMap;
    private String description;
    private String userName;

    public SaveObjectLogBatch(String selectedObject, Map<Id, String> serializeWMap, String description, String userName) {
        this.selectedObject = selectedObject;
        this.serializeWMap = serializeWMap;
        this.description = description;
        this.userName = userName;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT Id FROM User LIMIT 1]);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        // Step 1: Check if the record count exceeds the threshold and delete the oldest record if necessary
        Integer recordNumber = [SELECT COUNT() FROM SA_Audit__Objects_And_Fields_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject];
        System.debug('Record count for ' + selectedObject + ': ' + recordNumber);

        if (recordNumber >= 1000) {
            SA_Audit__Objects_And_Fields_Log__c oldestLog = [SELECT Id FROM SA_Audit__Objects_And_Fields_Log__c 
                                                             WHERE SA_Audit__Object_Type__c = :selectedObject 
                                                             ORDER BY SA_Audit__Date__c ASC LIMIT 1];
            if (oldestLog != null && SA_Audit__Objects_And_Fields_Log__c.sObjectType.getDescribe().isDeletable()) {
                System.debug('Deleting oldest log record: ' + oldestLog.Id);
                delete oldestLog;
            }
        }

        // Step 2: Create and insert the new SA_Audit__Objects_And_Fields_Log__c record
        SA_Audit__Objects_And_Fields_Log__c objLog = new SA_Audit__Objects_And_Fields_Log__c();
        if (Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Object_Type__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Date__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Description__c.isCreateable() &&
            Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__User_Name__c.isCreateable()) {

            objLog.SA_Audit__Object_Type__c = selectedObject;
            objLog.SA_Audit__Date__c = Datetime.now();
            objLog.SA_Audit__Description__c = description;
            objLog.SA_Audit__User_Name__c = userName;
        }

        System.debug('Attempting to insert objLog: ' + objLog);
        try {
            insert objLog;
            System.debug('Successfully inserted objLog with Id: ' + objLog.Id);
        } catch (DMLException e) {
            System.debug('Error inserting objLog: ' + e.getMessage());
            return; // Exit if there's an error
        }

        // Step 3: Create and insert related SA_Audit__Fields_Profile_Log__c records
        List<SA_Audit__Fields_Profile_Log__c> fieldProfileLogList = new List<SA_Audit__Fields_Profile_Log__c>();
        for (Id profileId : serializeWMap.keySet()) {
            SA_Audit__Fields_Profile_Log__c fieldProfileLog = new SA_Audit__Fields_Profile_Log__c();
            if (Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__Objects_And_Fields_Log__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__ProfileId__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__Value__c.isCreateable()) {

                fieldProfileLog.SA_Audit__Objects_And_Fields_Log__c = objLog.Id;
                fieldProfileLog.SA_Audit__ProfileId__c = profileId;
                fieldProfileLog.SA_Audit__Value__c = serializeWMap.get(profileId);
                fieldProfileLogList.add(fieldProfileLog);
            }
        }

        System.debug('Attempting to insert fieldProfileLogList: ' + fieldProfileLogList);
        if (!fieldProfileLogList.isEmpty()) {
            try {
                insert fieldProfileLogList;
                System.debug('Successfully inserted fieldProfileLogList');
            } catch (DMLException e) {
                System.debug('Error inserting fieldProfileLogList: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch processing completed.');
    }
}