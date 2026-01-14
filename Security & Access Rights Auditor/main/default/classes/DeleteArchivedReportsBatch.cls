/*
Author       : Himanshu Kr. Varshney
Description  : This is Batch Apex to delete all reports from the Archived Folder
Dependencies : Called from ReportManagerController.apxc class 
*/
public with sharing class DeleteArchivedReportsBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    public DeleteArchivedReportsBatch(){
        
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query;
        String conditionValue = 'SA_Audit_Report_Manager_Archived_Folder';
        query = 'SELECT Id, Name, FolderName, DeveloperName, NamespacePrefix FROM Report WHERE FolderName = ' + '\''+ conditionValue + '\'';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Report> records){
        for(Report reportRecord: records){
            try{
                deleteReportsFromArchivedFolder(reportRecord.Id);
            }
            catch(Exception ex){
                System.debug('Exception: ' + ex.getMessage() + ' Line Number: ' + ex.getLineNumber() + ' Stack Trace : ' + ex.getStackTraceString());
            }
        }
    }
    public void finish(Database.BatchableContext bc){
        List<String> toAddresses = new List<String>();
        MAP<Id, String> mapEmailAddress = new MAP<Id, String>();
        toAddresses.add(UserInfo.getUserEmail());
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject('Report Manager Update');
        String body = '';
        body += 'Dear <b>' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + '</b>,';
        body += '<br/>';
        body += '<br/>';
        body += 'Your Archived Reports have been deleted Successfully from the Archived folder.';
        body += '<br/>';
        body += '<br/>';
        body += '<b>Best regards</b>,';
        body += '<br/>';
        body += '<b>Application Perfection Report Manager team</b>';
        email.setHTMLBody(body);
        try{
            Messaging.SendEmailResult [] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
        catch(Exception ex){
            System.debug('Exception: ' + ex.getMessage() + ' Line Number: ' + ex.getLineNumber() + ' Stack Trace : ' + ex.getStackTraceString());
        }
    }
    public static void deleteReportsFromArchivedFolder(String reportId){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String url = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v34.0/analytics/reports/' + reportId;
        req.setEndpoint(url);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setMethod('DELETE');
        HttpResponse res = h.send(req);
    }
}