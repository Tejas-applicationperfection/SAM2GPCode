/*
Author       : Himanshu Kr. Varshney
Description  : Batch Apex for Intel tab feature named Filtered Reports, Option 24
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class FilteredReportsBatchApex implements Database.Batchable<Report>, Database.Stateful{
    public List<IntelController.FilteredReportsData> filteredReportList;
    public FilteredReportsBatchApex(){
        this.filteredReportList = new List<IntelController.FilteredReportsData>();
    }
    public Iterable<Report> start(Database.BatchableContext BC){
        List<Report> reportsList = [SELECT Id, DeveloperName, FolderName, Name FROM Report WHERE FolderName != null];
        return reportsList;
    }
    public void execute(Database.BatchableContext BC, List<Report> reportsList){
        for(Report reportOneRecord: reportsList){
            try{
                String crossFilter = '';
                String fieldFilter = '';
                String filterType = '';
                IntelController.FilteredReportsData filteredReportOneRecord = new IntelController.FilteredReportsData();
                //String reportId = (String)reportList.get(0).get('Id');
                Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportOneRecord.Id);
                Reports.ReportMetadata reportMd = describe.getReportMetadata();
                List<Reports.ReportFilter> fieldFilterList = reportMd.getReportFilters();
                for(Reports.ReportFilter filterOneRecord: fieldFilterList){
                    fieldFilter += filterOneRecord.getColumn() + ' ' + filterOneRecord.getOperator() + ' ' + filterOneRecord.getValue() + ' ' + ', '; 
                }
                List<Reports.CrossFilter> crossFilterList = reportMd.getCrossFilters();
                for(Reports.CrossFilter filterOneRecord: crossFilterList){
                    crossFilter += filterOneRecord.getPrimaryEntityField() + ' ' + (filterOneRecord.getincludesObject() ? 'with' : 'without') + ' ' + filterOneRecord.getRelatedEntity() + ' ' + ', '; 
                }
                if(crossFilter != '' && fieldFilter != ''){
                    filteredReportOneRecord.filterType = 'Both';
                    filteredReportOneRecord.filterBy = crossFilter + ' ' + fieldFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name;
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName;
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }
                else if(fieldFilter != ''){
                    filteredReportOneRecord.filterType = 'Field Filter';
                    filteredReportOneRecord.filterBy = fieldFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name;
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName;
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }
                else if(crossFilter != ''){
                    filteredReportOneRecord.filterType = 'Cross Filter';
                    filteredReportOneRecord.filterBy = crossFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name;
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName;
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }           
            }
            catch(Exception ex){
                
            }
        }
    }
    public void finish(Database.BatchableContext BC){
        SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        List<SA_Audit__OWD_Sharing_Report__c> owdSharingReportList = [SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'FilteredReport' LIMIT 100];
        if(owdSharingReporTList.size() > 0 && SA_Audit__OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
            delete owdSharingReportList;
        }
        if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable()){
            owdObjRecord.SA_Audit__Type__c = 'FilteredReport';
            insert owdObjRecord;
        }
        Blob excelData;
        if(Schema.sObjectType.Attachment.fields.Body.isCreateable() && Schema.sObjectType.Attachment.fields.parentId.isCreateable() && Schema.sObjectType.Attachment.fields.ContentType.isCreateable() && Schema.sObjectType.Attachment.fields.Name.isCreateable()){

        Attachment attach = new Attachment();
        attach.Name = 'FilteredReports';
        attach.ContentType = 'text/plain';
        attach.parentId = owdObjRecord.Id;
        attach.Body = Blob.valueOf(JSON.serialize(filteredReportList));
        insert attach;
          }
        /*SA_Audit__BatchApexStatus__c customSettingRecord = SA_Audit__BatchApexStatus__c.getValues('Permission Set');
        customSettingRecord.SA_Audit__Batch_Apex_Id__c = permissionSetBatchApexId;
        customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true;
        update customSettingRecord;*/
    }
}














/*public with sharing class FilteredReportsBatchApex implements Database.Batchable<Report>, Database.Stateful{
    Exception[] errors = new Exception[0];
    public List<IntelController.FilteredReportsData> filteredReportList;
    public FilteredReportsBatchApex(){
        this.filteredReportList = new List<IntelController.FilteredReportsData>();
    }
    public Iterable<Report> start(Database.BatchableContext BC){
        List<Report> reportsList = [SELECT Id, DeveloperName, FolderName, Name FROM Report WHERE FolderName != null];
        return reportsList;
    }
    public void execute(Database.BatchableContext BC, List<Report> reportsList){
        for(Report reportOneRecord: reportsList){
            try{
                String crossFilter = '';
                String fieldFilter = '';
                String filterType = '';
                IntelController.FilteredReportsData filteredReportOneRecord = new IntelController.FilteredReportsData();
                //String reportId = (String)reportList.get(0).get('Id');
                Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportOneRecord.Id);
                Reports.ReportMetadata reportMd = describe.getReportMetadata();
                List<Reports.ReportFilter> fieldFilterList = reportMd.getReportFilters();
                for(Reports.ReportFilter filterOneRecord: fieldFilterList){
                    fieldFilter += filterOneRecord.getColumn() + ' ' + filterOneRecord.getOperator() + ' ' + filterOneRecord.getValue() + ' ' + ', '; 
                }
                List<Reports.CrossFilter> crossFilterList = reportMd.getCrossFilters();
                for(Reports.CrossFilter filterOneRecord: crossFilterList){
                    crossFilter += filterOneRecord.getPrimaryEntityField() + ' ' + (filterOneRecord.getincludesObject() ? 'with' : 'without') + ' ' + filterOneRecord.getRelatedEntity() + ' ' + ', '; 
                }
                if(crossFilter != '' && fieldFilter != ''){
                    filteredReportOneRecord.filterType = 'Both';
                    filteredReportOneRecord.filterBy = crossFilter + ' ' + fieldFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name;
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName;
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }
                else if(fieldFilter != ''){
                    filteredReportOneRecord.filterType = 'Field Filter';
                    filteredReportOneRecord.filterBy = fieldFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name;
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName;
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }
                else if(crossFilter != ''){
                    filteredReportOneRecord.filterType = 'Cross Filter';
                    filteredReportOneRecord.filterBy = crossFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name;
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName;
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }           
            }
            catch(Exception ex){
                system.debug('error/exception'+ ex + ex.getLineNumber() + ex.getStackTraceString() + ex.getInaccessibleFields());
                errors.add(ex);
            }
            system.debug('errrors'+errors);
        }
    }
    public void finish(Database.BatchableContext BC){
       if(!errors.isEmpty()) {
           SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        List<SA_Audit__OWD_Sharing_Report__c> owdSharingReportList = [SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'FilteredReport' LIMIT 100];
        if(owdSharingReporTList.size() > 0 && SA_Audit__OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
            delete owdSharingReportList;
        }
       if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable()){
            owdObjRecord.SA_Audit__Type__c = 'FilteredReport';
            insert owdObjRecord;
        }
        Blob excelData;
        Attachment attach= new Attachment();
        attach.Name = 'FilteredReports';
        attach.ContentType = 'text/plain';
        attach.parentId = owdObjRecord.Id;
        attach.Body = Blob.valueOf(JSON.serialize(filteredReportList));
        insert attach;
        /*SA_Audit__BatchApexStatus__c customSettingRecord = SA_Audit__BatchApexStatus__c.getValues('Permission Set');
        customSettingRecord.SA_Audit__Batch_Apex_Id__c = permissionSetBatchApexId;
        customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true;
        update customSettingRecord;
       }
        
    }*/
//}