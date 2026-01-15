/*
Author       : Himanshu Kr. Varshney
Description  : This is Batch Apex to delete all the Empty Folders
Dependencies : Called from ReportManagerController.apxc class 
*/
public with sharing class DeleteEmptyFoldersBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    public List<ReportManagerController.FoldersData> customFoldersData;
    public DeleteEmptyFoldersBatch(){
        this.customFoldersData = new List<ReportManagerController.FoldersData>();
    }
    public List<Reports_History_Tracking__c> start(Database.BatchableContext bc){
       List<Reports_History_Tracking__c> reportHistoryRecords = [SELECT Id FROM Reports_History_Tracking__c WHERE Type__c = 'ReportsCount' LIMIT 1];
        return reportHistoryRecords;
    }
    public void execute(Database.BatchableContext bc, List<Reports_History_Tracking__c> reportHistoryRecords){
       /* Attachment attach = [SELECT Id, Body, ParentId FROM Attachment WHERE ParentId =: reportHistoryRecords[0].Id];
        if (attach != null) {
            customFoldersData = (List<ReportManagerController.FoldersData>)System.JSON.deserialize(attach.Body.toString(), List<ReportManagerController.FoldersData>.class);
        }
        
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm() + '/';
        for(ReportManagerController.FoldersData folderOneRecord: customFoldersData){
            if(folderOneRecord.reportsCount == 0){
                deleteEmptyFolder(folderOneRecord.url.substringAfter(sfdcURL));
            }
        }*/
    }
    public void finish(Database.BatchableContext bc){
    }
   /* public static void deleteEmptyFolder(String folderId){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String url = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v50.0/folders/' + folderId;
        req.setEndpoint(url);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000);
        req.setMethod('DELETE');
        HttpResponse res = h.send(req);
    }*/
}