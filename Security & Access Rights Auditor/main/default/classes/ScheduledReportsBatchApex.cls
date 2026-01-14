/*
Author       : Himanshu Kr. Varshney
Description  : Batch Apex for Intel tab feature named Scheduled Reports, Option 23
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class ScheduledReportsBatchApex implements Database.Batchable<CronTrigger>, Database.Stateful{
    public List<IntelController.ScheduledReportsData> scheduledReportsList;
    public ScheduledReportsBatchApex(){
        this.scheduledReportsList = new List<IntelController.ScheduledReportsData>();
    }
    public Iterable<CronTrigger> start(Database.BatchableContext BC){
        List<CronTrigger> cronTriggerList = [SELECT PreviousFireTime, Id, CronJobDetail.Name, NextFireTime, State, StartTime, EndTime, OwnerId, CreatedBy.Name, CreatedDate, TimesTriggered, CronExpression FROM CronTrigger WHERE CronJobDetail.JobType = '8'];
        system.debug('cronTriggerList'+cronTriggerList);
        return cronTriggerList;
    }
    public void execute(Database.BatchableContext BC, List<CronTrigger> cronTriggerList){
        try{
            MAP<Id, List<String>> reportsDataMap = new MAP<Id, List<String>>();
        List<Id> listOfReportIds = new List<Id>();
        for(CronTrigger cronTriggerOneRecord: cronTriggerList){
            listOfReportIds.add(cronTriggerOneRecord.CronJobDetail.Name);
        }
        List<Report> reportList = [SELECT Id, Name, DeveloperName, FolderName FROM Report WHERE Id IN: listOfReportIds];
        for(Report reportOneRecord: reportList){
            List<String> stringList = new List<String>();
            stringList.add(reportOneRecord.Name);
            stringList.add(reportOneRecord.DeveloperName);
            stringList.add(reportOneRecord.FolderName);
            reportsDataMap.put(reportOneRecord.Id, stringList);
        }
        for(CronTrigger cronTriggerOneRecord: cronTriggerList){
            IntelController.ScheduledReportsData scheduledReportsOneRecord = new IntelController.ScheduledReportsData();
            if(reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name) != null){
                scheduledReportsOneRecord.reportName = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[0];
                scheduledReportsOneRecord.folderName = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[2];
                scheduledReportsOneRecord.reportUniqueName = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[1];
                scheduledReportsOneRecord.runningUserName = cronTriggerOneRecord.CreatedBy.Name;
                scheduledReportsOneRecord.startTime = cronTriggerOneRecord.StartTime;
                scheduledReportsOneRecord.endTime = cronTriggerOneRecord.EndTime;
                scheduledReportsOneRecord.previousRunTime = cronTriggerOneRecord.PreviousFireTime;
                scheduledReportsOneRecord.nextRunTime = cronTriggerOneRecord.NextFireTime;
                scheduledReportsList.add(scheduledReportsOneRecord);
            }
        }
     }catch(exception e){
            system.debug('error=='+ e.getLineNumber() + e.getStackTraceString()+ e);
        }
    }
    public void finish(Database.BatchableContext BC){
        SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        List<SA_Audit__OWD_Sharing_Report__c> owdSharingReportList = [SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ScheduledReports' LIMIT 100];
        if(owdSharingReporTList.size() > 0 && SA_Audit__OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
            delete owdSharingReportList;
        }
        if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable()){
            owdObjRecord.SA_Audit__Type__c = 'ScheduledReports';
            insert owdObjRecord;
        }
        Blob excelData;
      if(Schema.sObjectType.Attachment.fields.Body.isCreateable() && Schema.sObjectType.Attachment.fields.parentId.isCreateable() && Schema.sObjectType.Attachment.fields.ContentType.isCreateable() && Schema.sObjectType.Attachment.fields.Name.isCreateable()){
        Attachment attach = new Attachment();
        attach.Name = 'ScheduledReports';
        attach.ContentType = 'text/plain';
        attach.parentId = owdObjRecord.Id;
        attach.Body = Blob.valueOf(JSON.serialize(scheduledReportsList));
            insert attach;}
        system.debug('Blob.valueOf(JSON.serialize(scheduledReportsList));'+(JSON.serialize(scheduledReportsList)));
        /*SA_Audit__BatchApexStatus__c customSettingRecord = SA_Audit__BatchApexStatus__c.getValues('Permission Set');
        customSettingRecord.SA_Audit__Batch_Apex_Id__c = permissionSetBatchApexId;
        customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true;
        update customSettingRecord;*/
    }
}