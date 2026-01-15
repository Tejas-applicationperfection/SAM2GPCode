public with sharing class LogCleanupBatchOA implements Database.Batchable<SObject> {

    public String selectedObject;

    // Constructor accepting the selectedObject as parameter
    public LogCleanupBatchOA(String selectedObject) {
        this.selectedObject = selectedObject;
    }

    // Start method to define the scope of the batch
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query all logs for the selected object sorted by the date in descending order
        return Database.getQueryLocator([
            SELECT Id, SA_Audit__Date__c
            FROM SA_Audit__Object_Log__c
            WHERE SA_Audit__Object_Type__c = :selectedObject
            ORDER BY SA_Audit__Date__c DESC
        ]);
    }

    // Execute method that is called for each batch of records
    public void execute(Database.BatchableContext BC, List<SA_Audit__Object_Log__c> records) {
        List<SA_Audit__Object_Log__c> logsToDelete = new List<SA_Audit__Object_Log__c>();

        Integer recordCount = [SELECT COUNT() FROM SA_Audit__Object_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject];
	 if(Schema.sObjectType.SA_Audit__Object_Log__c.isAccessible() &&  Schema.sObjectType.SA_Audit__Object_Log__c.isDeletable() ){
                        if(SA_Audit__Object_Log__c.sObjectType.getDescribe().isDeletable()){
        if (recordCount > 1000) {
            Integer logsToDeleteCount = recordCount - 1000;
            // Only delete records if the count exceeds the threshold
            for (Integer i = logsToDeleteCount; i < records.size(); i++) {
                logsToDelete.add(records[i]);
            }
            if (!logsToDelete.isEmpty()) {
                try {
                    delete logsToDelete;
                } catch (DMLException e) {
                    System.debug('Error occurred while deleting records: ' + e.getMessage());
                    // Optional: Log the error to a custom error log object for auditing
                }
            }
        }
                        }}
    }

    // Finish method to perform any final actions after the batch has completed
    public void finish(Database.BatchableContext BC) {
        System.debug('Batch deletion process has completed for Object: ' + selectedObject);
        // Optional: You can send an email notification or log the batch completion in a custom log object
    }
}