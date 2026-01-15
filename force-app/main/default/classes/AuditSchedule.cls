global with sharing class AuditSchedule implements Schedulable{
    global void execute(SchedulableContext SC) {
        try{
            
            AuditAppReportController abc = new AuditAppReportController();
            abc.runStaticMethods();
            
        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        
    }
}