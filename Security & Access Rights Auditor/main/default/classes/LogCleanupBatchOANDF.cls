public with sharing class LogCleanupBatchOANDF implements Database.Batchable<sObject> {
    
    // Property to hold the selected object name for filtering
    public String selectedObject;
    
    // Constructor to initialize the selected object name
    public LogCleanupBatchOANDF(String selectedObject) {
        this.selectedObject = selectedObject;
    }

    // Start method to define the query for batch job
    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query to fetch old log records for the selected object type.
        // For example, you might delete records older than 30 days.
        String query = 'SELECT Id FROM SA_Audit__Objects_And_Fields_Log__c ' +
                       'WHERE SA_Audit__Object_Type__c = :selectedObject ' +
                       'AND SA_Audit__Date__c <= :System.today().addDays(-30) ' +  // Delete logs older than 30 days
                       'ORDER BY SA_Audit__Date__c ASC';
        
        return Database.getQueryLocator(query);
    }

    // Execute method to delete the records
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<SA_Audit__Objects_And_Fields_Log__c> logsToDelete = new List<SA_Audit__Objects_And_Fields_Log__c>();
        if(Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.isAccessible() &&  Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.isDeletable() ){
            if(SA_Audit__Objects_And_Fields_Log__c.sObjectType.getDescribe().isDeletable()){
                // Collect logs to delete
                for (sObject record : scope) {
                    SA_Audit__Objects_And_Fields_Log__c logRecord = (SA_Audit__Objects_And_Fields_Log__c) record;
                    logsToDelete.add(logRecord);
                }
                
                // Delete the logs
                try {
                    if (!logsToDelete.isEmpty()) {
                        delete logsToDelete;
                    }
                } catch (DMLException e) {
                    System.debug('Error while deleting logs: ' + e.getMessage());
                    // Optionally, add error handling for failed delete operation
                }
            }}
    }

    // Finish method to handle any post-processing or logging
    public void finish(Database.BatchableContext BC) {
        // Example: Send an email notification once the cleanup is complete
        System.debug('Batch job completed for object: ' + selectedObject);
        // You can add an email alert or any other post-processing logic here.
    }
}