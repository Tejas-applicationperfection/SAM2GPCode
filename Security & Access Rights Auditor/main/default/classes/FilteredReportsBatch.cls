/*
Author       : Himanshu Kr. Varshney
Description  : This is Batch Apex to get the Folders Data along with Number of Reports
Dependencies : Called from ReportManagerController.apxc class 
*/
public with sharing class FilteredReportsBatch implements Database.Batchable<sObject>, Database.Stateful{
    public List<ReportManagerController.FoldersData> customFoldersData;
    public FilteredReportsBatch(){
        this.customFoldersData = new List<ReportManagerController.FoldersData>();
    }
    public List<Folder> start(Database.BatchableContext bc){
        List<Folder> folderList = [SELECT Id, Name, DeveloperName, CreatedDate, LastModifiedDate, LastModifiedBy.Name FROM Folder WHERE DeveloperName != 'SA_Audit_Report_Manager_Archived_Folder' AND DeveloperName != null AND Name != null AND Type = 'Report'];
        return folderList;
    }
    public void execute(Database.BatchableContext bc, List<Folder> folderList){
        List<Report> reportList = [SELECT Id, OwnerId FROM Report WHERE FolderName != null];
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        for(Folder folderOneRecord: folderList){
            Integer reportCount = 0;
            ReportManagerController.FoldersData customFolderOneRecord = new ReportManagerController.FoldersData();
            customFolderOneRecord.folderName = folderOneRecord.Name;
            customFolderOneRecord.folderUniqueName = folderOneRecord.DeveloperName;
            customFolderOneRecord.url = sfdcURL + '/' + folderOneRecord.Id;
            customFolderOneRecord.createdDate = folderOneRecord.CreatedDate;
            customFolderOneRecord.lastModifiedDate = folderOneRecord.LastModifiedDate?.format('MM/dd/yyyy hh:mm a');
            customFolderOneRecord.lastModifiedByName = folderOneRecord.LastModifiedBy.Name;
            for(Report reportOneRecord: reportList){
                if(reportOneRecord.OwnerId == folderOneRecord.Id){
                    reportCount++;
                }
            }
            customFolderOneRecord.reportsCount = reportCount;
            customFoldersData.add(customFolderOneRecord);
        }
    }
    public void finish(Database.BatchableContext bc){
        
        List<Reports_History_Tracking__c> reportsHistoryList = [SELECT Id FROM Reports_History_Tracking__c WHERE Type__c = 'ReportsCount'];
        
        if(reportsHistoryList.size() > 0 && Reports_History_Tracking__c.sObjectType.getDescribe().isDeletable() ){
            Database.DeleteResult[] reportsHistoryList1= Database.delete(reportsHistoryList , false);
            for(Database.DeleteResult rep : reportsHistoryList1) {
                if (rep.isSuccess()) {
                    System.debug('Successfully deleted account with ID: ' + rep.getId());
                }
            }
            //  delete reportsHistoryList;
            
        }
		
             
        Reports_History_Tracking__c reportsHistoryData = new Reports_History_Tracking__c();
              if(Schema.sObjectType.Reports_History_Tracking__c.fields.Type__c.isCreateable()){
        reportsHistoryData.Type__c = 'ReportsCount'; 
            insert reportsHistoryData;
        }
        if(Schema.sObjectType.Attachment.fields.Body.isCreateable() && Schema.sObjectType.Attachment.fields.parentId.isCreateable() && Schema.sObjectType.Attachment.fields.ContentType.isCreateable() && Schema.sObjectType.Attachment.fields.Name.isCreateable()){
            Attachment attach = new Attachment();
            attach.Name = 'ArchivedReports';
            attach.ContentType = 'text/plain';
            attach.parentId = reportsHistoryData.Id;
            attach.Body = Blob.valueOf(JSON.serialize(customFoldersData));
            insert attach;}
    }
}