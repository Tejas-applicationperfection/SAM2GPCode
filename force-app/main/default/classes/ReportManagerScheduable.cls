/*
Author       : Himanshu Kr. Varshney
Description  : This is Scheduable Apex to call the Batch Apex Class at a specified Time
Dependencies : Called from ReportManagerController.apxc class 
*/
public with sharing class ReportManagerScheduable implements Schedulable{
    @AuraEnabled
    public List<String> developerNameOfFolders { get; set; }
    @AuraEnabled
    public List<WrapperData> wrapperDataList { get; set; }
    public ReportManagerScheduable(){
        this.developerNameOfFolders = new List<String>();
        this.wrapperDataList = new List<WrapperData>();
    }
    public void execute(SchedulableContext sc){
        List<Report_Manager_Object__c> records = [SELECT Id, Name, JSON__c FROM Report_Manager_Object__c WHERE CreatedById =: UserInfo.getUserId()];
        Set<String> setData = new Set<String>();
        for(Report_Manager_Object__c reportManagerOneRecord: records){
            List<ReportManagerController.JSONData> jsonDataList = (List<ReportManagerController.JSONData>)System.JSON.deserialize(reportManagerOneRecord.JSON__c, List<ReportManagerController.JSONData>.class);
            WrapperData wrapperDataOneRecord = new WrapperData();
            wrapperDataOneRecord.archiveFolderId = jsonDataList[0].archiveFolderId;
            wrapperDataOneRecord.userId = jsonDataList[0].userId;
            wrapperDataOneRecord.norifyUser = jsonDataList[0].norifyUser;
            setData.addAll(jsonDataList[0].folderIds);
            wrapperDataList.add(wrapperDataOneRecord);
        }
        developerNameOfFolders.addAll(setData);
        Database.executeBatch(new ReportManagerBatch(wrapperDataList, developerNameOfFolders), 50);
    }
    public class WrapperData{
        @AuraEnabled
        public String archiveFolderId { get; set; }
        @AuraEnabled
        public Boolean norifyUser { get; set; }
        @AuraEnabled
        public String userId { get; set; }
    }
}