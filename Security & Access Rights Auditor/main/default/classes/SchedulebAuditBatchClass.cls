global with sharing class SchedulebAuditBatchClass implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext context) {
        
        return Database.getQueryLocator('SELECT Id FROM SA_Audit__Audit_Step__c');
    }
    
    global void execute(Database.BatchableContext context, List<SObject> scope) {
        String jobName = 'AuditSchedule';
        String cronExp = ''; 
        
        List<SA_Audit__AuditHistory__c> auditFlag = new List<SA_Audit__AuditHistory__c>();
       
        // Check if the job is already scheduled
        try{
       if (!isJobScheduled()) { 
            // If not scheduled, schedule it to run after 5 minutes
            Datetime dte = Datetime.now().addMinutes(1);  
            String schCronExp = dte.format('s m H d M \'?\' yyyy');
           
            cronExp = '0 15 * ? * *';
           
            System.schedule('AuditSchedule',cronExp, new AuditSchedule());         
       }
         //System.schedule(jobName, cronExp, new AuditSchedule()); 
        }catch(exception e){
            system.debug('ee=='+ e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext context) {
        // Finish method (optional)
    }
    public  Boolean isJobScheduled() {
        String jobName = 'AuditSchedule';
        for (CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = :jobName]) {
            // If there is any existing CronTrigger record for the job, return true
            if (ct != null) {
                return true;
            }
        }
        // If no CronTrigger record found, return false
        return false;
    }
}