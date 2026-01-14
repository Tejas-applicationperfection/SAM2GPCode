/*
Author       : Naveen Varshney
Description  : This is Batch Apex to move all reports from Unarchived Folders to Original Folders
Dependencies : Called from ReportManagerScheduable.apxc class 
*/
public with sharing class UnarchivedSelectedReports implements Database.Batchable<ReportManagerController.ReportRecords>, Database.AllowsCallouts, Database.Stateful{
    @AuraEnabled
    public List<ReportManagerController.ReportRecords> reportRecordsList { get; set; }
    @AuraEnabled
    public MAP<String, String> folderNames { get; set; }
    public UnarchivedSelectedReports(List<ReportManagerController.ReportRecords> reportList){
        this.reportRecordsList = reportList;
        this.folderNames = new MAP<String, String>();
    }
    public Iterable<ReportManagerController.ReportRecords> start(Database.BatchableContext bc){
        return reportRecordsList;
    }
    public void execute(Database.BatchableContext bc, List<ReportManagerController.ReportRecords> records){
        for(ReportManagerController.ReportRecords reportRecord: records){
            if(reportRecord.checked && String.isNotBlank(reportRecord.previousFolderId)){
                folderNames.put(reportRecord.Id, reportRecord.reportName);                	
                updateReportFolderId(reportRecord.Id, reportRecord.previousFolderId);
              
            }
        }
    }
    public void finish(Database.BatchableContext bc){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();
        toAddresses.add(UserInfo.getUserEmail());
        email.setToAddresses(toAddresses);
        email.setSubject('Your Report Manager App');
        String body = '';
        body += 'Dear <b>' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + '</b>,';
        body += '<br/>';
        body += '<br/>';
        body += 'Today Report Manager Unarchived the following reports';
        body += '<br/>';
        body += '<br/>';
        body += '<ul>';
        String instanceURL = URL.getSalesforceBaseUrl().toExternalForm();
        for(String str: folderNames.keySet()){
            body += '<li>' + folderNames.get(str) + ' - ' + '<a href=' + '\'' + instanceURL + '/' + str + '\'' + '>' + instanceURL + '/' + str + '</a>' + '</li>';
            body += '<br/>';
        }
        body += '</ul>';
        body += '<br/>';
        body += '<br/>';
        body += '<b>Best regards</b>,';
        body += '<br/>';
        body += '<b>Application Perfection Report Manager team</b>';
        email.setHTMLBody(body);
        if(toAddresses.size() > 0){
            try{
                Messaging.SendEmailResult [] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            }
            catch(Exception ex){
                System.debug('Exception: ' + ex.getMessage() + ' Line Number: ' + ex.getLineNumber() + ' Stack Trace : ' + ex.getStackTraceString());
            }
        }
    }
    public static void updateReportFolderId(String reportId, String folderId){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String url = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v34.0/analytics/reports/' + reportId + '?_HttpMethod=PATCH';
        req.setEndpoint(url);
        folderId = '"' + folderId + '"';
        String body = '{ "reportMetadata" : { "folderId" : ' + folderId + ' }}'; 
        req.setBody(body);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        req.setTimeout(120000);
        HttpResponse response;
        try {
            response = h.send(req);
        } catch(System.CalloutException ex) {
            System.debug('Exception: ' + ex.getMessage() + ' Line Number: ' + ex.getLineNumber() + ' Stack Trace : ' + ex.getStackTraceString());
        }
        
    }
}