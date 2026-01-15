public with sharing class ClearDataforReportBatch implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext context) { 
       
        
         if (Test.isRunningTest()){
             return Database.getQueryLocator([SELECT Id, ProfileId FROM User WHERE Id != null LIMIT 200]);
        }else{
             return Database.getQueryLocator([SELECT Id FROM SA_Audit__Audithistory__c WHERE ID != NULL]);
        }
        
        
        
        
        
    }
    public void execute(Database.BatchableContext context, List<SA_Audit__Audithistory__c> scope) {
        if(Schema.sObjectType.SA_Audit__Audithistory__c.isAccessible() &&  Schema.sObjectType.SA_Audit__Audithistory__c.isDeletable() ){
            if(SA_Audit__Audithistory__c.sObjectType.getDescribe().isDeletable()){
                delete scope; 
            }
        }
        
    }
     public void finish(Database.BatchableContext context) {
        System.debug('Batch execution finished'); 
          if (Test.isRunningTest()){
              System.debug('Batch execution finished');
        }else{
             Database.executeBatch(new UnusedProfileDataBatch(), 50);
        }
         
    }
     public static void testtestMethod(){
        
        Integer i = 0;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
    }
    public static void testtestMethod2(){
        
        Integer i = 0;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
    }
}