/*
Author      : Himanshu Kr. Varshney
Description : This Class is Controller for the reportManager.cmp LC
Dependencies: It is being used in reportManager.cmp LC, ReportsExcelController.apxc
*/
public with sharing class ReportManagerController{
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data related to Reports based on Selected Date 
*/
    
    
    
    
     @AuraEnabled(cacheable=true)
    public static Boolean PaidFeatureAccess() {
        // Check if the feature is enabled for the user
        return FeatureManagement.checkPackageBooleanValue('PaidFeatureAccess');
    }
    @AuraEnabled
    public static List<List<ReportRecords>> getReportRecordsBasedOnDate(Date selectedDate){
        List<List<ReportRecords>> reportRecords = new List<List<ReportRecords>>();
        List<ReportRecords> reportRecordsList = new List<ReportRecords>();
        Integer i = 1;
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        List<Report> reportList = [SELECT Id, Name, FolderName, LastRunDate, CreatedDate, LastModifiedDate, LastModifiedBy.Name FROM Report WHERE (FolderName != 'SA_Audit_Report_Manager_Archived_Folder' AND LastRunDate <: selectedDate) OR (FolderName != 'SA_Audit_Report_Manager_Archived_Folder' AND LastRunDate =: null) ORDER BY Name ASC];
        for(Report reportOnRecord: reportList){
            ReportRecords reportOneRecord = new ReportRecords();
            reportOneRecord.Id = reportOnRecord.Id; 
            reportOneRecord.reportName = reportOnRecord.Name.replaceAll('[^a-zA-Z0-9\\s+]', '');
            reportOneRecord.folderName = reportOnRecord.FolderName.replaceAll('[^a-zA-Z0-9\\s+]', ''); 
            reportOneRecord.lastRunDate = reportOnRecord.LastRunDate?.format('MM/dd/yyyy hh:mm a');
            reportOneRecord.folderURL = sfdcURL + '/' + reportOnRecord.Id;
            reportOneRecord.createdDate = reportOnRecord.CreatedDate?.format('MM/dd/yyyy hh:mm a');
            reportOneRecord.lastModifiedDate = reportOnRecord.LastModifiedDate?.format('MM/dd/yyyy hh:mm a');
            reportOneRecord.lastModifiedByName = reportOnRecord.LastModifiedBy.Name;
            /*Reports.ReportDescribeResult reportDescription = Reports.ReportManager.describeReport(reportOnRecord.Id);
            Reports.ReportMetadata reportMetadata = reportDescription.getReportMetadata();
            Reports.ReportType reportType = reportMetadata.getReportType();
            reportOneRecord.reportType = reportType.getLabel();*/
            if(i < 1000){
                i++;
                reportRecordsList.add(reportOneRecord);   
            }
            else{
                reportRecords.add(reportRecordsList);
                i = 1;
                reportRecordsList = new List<ReportRecords>();
                reportRecordsList.add(reportOneRecord);
            }
        }
        if(reportRecordsList.size() > 0){
            reportRecords.add(reportRecordsList);
        }
        return reportRecords;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data related to Reports based on Specified months 
*/
    @AuraEnabled
    public static List<List<ReportRecords>> getReportRecordsBasedOnMonths(Integer months){
        List<List<ReportRecords>> reportRecords = new List<List<ReportRecords>>();
        List<ReportRecords> reportRecordsList = new List<ReportRecords>();
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        Date today = System.today();
        Date customDate = today.addMonths(-months);
        Integer i = 1;
        List<Report> reportList = [SELECT Id, Name, FolderName, LastRunDate, CreatedDate, LastModifiedDate, LastModifiedBy.Name FROM Report WHERE (LastRunDate <: customDate AND FolderName != 'SA_Audit_Report_Manager_Archived_Folder') OR (LastRunDate =: null AND FolderName != 'SA_Audit_Report_Manager_Archived_Folder') ORDER BY Name ASC];
        for(Report reportOnRecord: reportList){
            ReportRecords reportOneRecord = new ReportRecords();
            reportOneRecord.Id = reportOnRecord.Id;
            reportOneRecord.reportName = reportOnRecord.Name.replaceAll('[^a-zA-Z0-9\\s+]', '');
            reportOneRecord.folderName = reportOnRecord.FolderName.replaceAll('[^a-zA-Z0-9\\s+]', '');
            reportOneRecord.lastRunDate = reportOnRecord.LastRunDate?.format('MM/dd/yyyy hh:mm a');
            reportOneRecord.folderURL = sfdcURL + '/' + reportOnRecord.Id;
            reportOneRecord.createdDate = reportOnRecord.CreatedDate?.format('MM/dd/yyyy hh:mm a');
            reportOneRecord.lastModifiedDate = reportOnRecord.LastModifiedDate?.format('MM/dd/yyyy hh:mm a');
            reportOneRecord.lastModifiedByName = reportOnRecord.LastModifiedBy.Name;
            /*Reports.ReportDescribeResult reportDescription = Reports.ReportManager.describeReport(reportOnRecord.Id);
            Reports.ReportMetadata reportMetadata = reportDescription.getReportMetadata();
            Reports.ReportType reportType = reportMetadata.getReportType();
            reportOneRecord.reportType = reportType.getLabel();*/
            if(i < 1000){
                i++;
                reportRecordsList.add(reportOneRecord);   
            }
            else{
                reportRecords.add(reportRecordsList);
                i = 1;
                reportRecordsList = new List<ReportRecords>();
                reportRecordsList.add(reportOneRecord);
            }
        }
        if(reportRecordsList.size() > 0){
            reportRecords.add(reportRecordsList);
        }
        return reportRecords;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data related to all Folders which are in the Org 
*/
    @AuraEnabled
    public static List<Folder> getFolderNames(){
        List<Folder> folderList = [SELECT Id, Name, DeveloperName, Type, CreatedDate, LastModifiedDate, LastModifiedBy.Name FROM Folder WHERE Name != '' AND DeveloperName != '' AND DeveloperName != 'SA_Audit_Report_Manager_Archived_Folder' AND Type = 'Report' ORDER BY Name ASC];
        //Id privateFolderId = [SELECT Id, Name, FolderName FROM Report  WHERE FolderName = 'Private Reports' LIMIT 1].Id;
        //Id publicFolderId = [SELECT Id, Name, FolderName FROM Report  WHERE FolderName = 'Public Reports' LIMIT 1].Id;
        return folderList;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will delete the All Empty Folders 
*/
    @AuraEnabled
    public static void deleteTheEmptyFolders(){
        DeleteEmptyFoldersBatch obj = new DeleteEmptyFoldersBatch();
        Database.executeBatch(obj, 10);
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will delete the Folder Based on Id 

    public static void deleteEmptyFolder(String folderId){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String url = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v50.0/folders/' + folderId;
        req.setEndpoint(url);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('DELETE');
        HttpResponse res = h.send(req);
    }*/
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will Schedule the Batch Apex 

    @AuraEnabled
    public static void scheduleBatchClass(){
        String hour = String.valueOf(Datetime.now().hour());
        String minute = String.valueOf(Datetime.now().minute() + 1); 
        String second = String.valueOf(Datetime.now().second());
        String nextFireTime = second + ' ' + minute + ' ' + hour + ' * * ?';
        ReportManagerScheduable scheduleClass = new ReportManagerScheduable(); 
        System.schedule(String.valueOf(Datetime.now()), nextFireTime, scheduleClass);
    }*/
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data related to all Users which are in the Org and are in Active State
*/
    @AuraEnabled
    public static List<User> getUsersList(){
        List<User> userList = [SELECT Id, Name, isActive FROM User WHERE isActive = true ORDER BY Name ASC];
        return userList;
    }
    public class CustomException extends Exception{ 
    }
    @AuraEnabled
    public static String checkBatchApexProgress(String jobId){
        AsyncApexJob job = [SELECT JobItemsProcessed, TotalJobItems, Status FROM AsyncApexJob WHERE Id =: jobId];
        String message;
        if(job.Status == 'Queued' || job.Status == 'Holding' || job.Status == 'Preparing'){
            message = 'We are in the ' + job.Status.toLowerCase() + ' status...' + 'We are processing this report to see the latest status press the button again.';
            throw new CustomException(message);
        } 
        else if(job.Status != 'Completed' && job.Status != 'Aborted'){
            message = 'We are in ' + job.Status.toLowerCase() + ' status: ' + Math.floor(100.0 * job.JobItemsProcessed/job.TotalJobItems) + '%...' + 'We are processing this report to see the latest status press the button again.';
            throw new CustomException(message);
        } 
        else if(job.Status == 'Completed'){
            message = 'Completed';
        }
        return message;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will Execute all of the Batch Apex
*/
    @AuraEnabled
    public static List<String> executeAllTheBatchApex(){
        List<String> ids = new List<String>();
        FoldersDataBatch classObj1 = new FoldersDataBatch();
        String firstBatchApexId = Database.executeBatch(classObj1, 100);
        ids.add(firstBatchApexId);
        return ids;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data related to all Folders
*/
    @AuraEnabled
    public static List<FoldersData> getFoldersData(){
        List<FoldersData> customFoldersData = new List<FoldersData>();
        List<Reports_History_Tracking__c> reportsHistoryList = [SELECT Id FROM Reports_History_Tracking__c WHERE Type__c = 'ReportsCount'];
        if(reportsHistoryList.size() > 0){
            Attachment attach = [SELECT Id, ParentId, Body FROM Attachment WHERE ParentId =: reportsHistoryList[0].Id];
            if (attach != null) {
                customFoldersData = (List<FoldersData>)System.JSON.deserialize(attach.Body.toString(), List<FoldersData>.class);
            }
        }
        return customFoldersData;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below Wrapper class will store the JSON Data for all the Folders
*/
    public class FoldersData{
        @AuraEnabled 
        public String folderName { get; set; }
        @AuraEnabled 
        public String folderUniqueName { get; set; }
        @AuraEnabled 
        public String url { get; set; }
        @AuraEnabled 
        public DateTime createdDate { get; set; }
        @AuraEnabled 
        public Integer reportsCount { get; set; }
        @AuraEnabled 
        public String lastModifiedDate { get; set; }
        @AuraEnabled 
        public String lastModifiedByName { get; set; }
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data for default Folder Name with Developer Name 'SA_Audit_Report_Manager_Archived_Folder'
*/
    @AuraEnabled
    public static String getDefaultFolderId(){ 
        Id defualtFolderId = [SELECT Id, Name, DeveloperName FROM Folder WHERE DeveloperName = 'SA_Audit_Report_Manager_Archived_Folder' Limit 1].Id;
        return defualtFolderId;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data of Report Manager object for Current LoggedIn User
*/
    @AuraEnabled
    public static List<JSONData> getUserPreference(){ 
        List<JSONData> jsonDataList = new List<JSONData>();
        String jsonData = [SELECT Id, JSON__c FROM Report_Manager_Object__c WHERE CreatedById =: UserInfo.getUserId() LIMIT 1]?.JSON__c;
        if(String.isNotEmpty(jsonData)){
            jsonDataList = (List<JSONData>)System.JSON.deserialize(jsonData, List<JSONData>.class);
        }
        return jsonDataList;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data of All the Reports which has either Cross or Field Filter
*/
    @AuraEnabled
    public static List<FilteredReportsData> viewTheFilteredReports(){ 
        List<FilteredReportsData> filteredReportList = new List<FilteredReportsData>();
        List<Report> reportList = [SELECT Id, DeveloperName, FolderName, Name, CreatedDate, LastModifiedDate, LastModifiedBy.Name FROM Report WHERE FolderName != null];
        for(Report reportOneRecord: reportList){
            try{
                String crossFilter = '';
                String fieldFilter = '';
                String filterType = '';
                FilteredReportsData filteredReportOneRecord = new FilteredReportsData();
                //String reportId = (String)reportList.get(0).get('Id');
                Reports.ReportDescribeResult describe = Reports.ReportManager.describeReport(reportOneRecord.Id);
                Reports.ReportMetadata reportMd = describe.getReportMetadata();
                /*Reports.ReportType reportType = reportMd.getReportType();
				  filteredReportOneRecord.reportType = reportType.getLabel(); */
                List<Reports.ReportFilter> fieldFilterList = reportMd.getReportFilters();
                for(Reports.ReportFilter filterOneRecord: fieldFilterList){
                    fieldFilter += filterOneRecord.getColumn() + ' ' + filterOneRecord.getOperator() + ' ' + filterOneRecord.getValue() + ' ' + ', '; 
                }
                List<Reports.CrossFilter> crossFilterList = reportMd.getCrossFilters();
                for(Reports.CrossFilter filterOneRecord: crossFilterList){
                    crossFilter += filterOneRecord.getPrimaryEntityField() + ' ' + (filterOneRecord.getincludesObject() ? 'with' : 'without') + ' ' + filterOneRecord.getRelatedEntity() + ' ' + ', '; 
                }
                filteredReportOneRecord.createdDate = reportOneRecord.CreatedDate?.format('MM/dd/yyyy hh:mm a');
                filteredReportOneRecord.lastModifiedDate = reportOneRecord.LastModifiedDate?.format('MM/dd/yyyy hh:mm a');
                filteredReportOneRecord.lastModifiedByName = reportOneRecord.LastModifiedBy.Name;
                if(crossFilter != '' && fieldFilter != ''){
                    filteredReportOneRecord.filterType = 'Both';
                    filteredReportOneRecord.filterBy = crossFilter + ' ' + fieldFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name.replaceAll('[^a-zA-Z0-9\\s+]', '');
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName.replaceAll('[^a-zA-Z0-9\\s+]', '');
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }
                else if(fieldFilter != ''){
                    filteredReportOneRecord.filterType = 'Field Filter';
                    filteredReportOneRecord.filterBy = fieldFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name.replaceAll('[^a-zA-Z0-9\\s+]', '');
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName.replaceAll('[^a-zA-Z0-9\\s+]', '');
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }
                else if(crossFilter != ''){
                    filteredReportOneRecord.filterType = 'Cross Filter';
                    filteredReportOneRecord.filterBy = crossFilter;
                    filteredReportOneRecord.reportName = reportOneRecord.Name.replaceAll('[^a-zA-Z0-9\\s+]', '');
                    filteredReportOneRecord.folderName = reportOneRecord.FolderName.replaceAll('[^a-zA-Z0-9\\s+]', '');
                    filteredReportOneRecord.reportUniqueName = reportOneRecord.DeveloperName;
                    filteredReportList.add(filteredReportOneRecord);
                }
            }
            catch(Exception ex){
                System.debug('Error????' + reportOneRecord.Id);
            }
        }
        return filteredReportList;
    }

/*
Author            : Naveen Varshney
Purpose of method : Below method will fetch the Data of All the Reports which have been Subscribed by Users
*/
    @AuraEnabled
    public static List<CustomSubscribedReport> viewTheSubscribedReports(){ 
        
        system.debug('called');
    /*    Http h = new Http();
        List<CustomSubscribedReport> customResult = new List<CustomSubscribedReport>();
        HttpRequest req = new HttpRequest();
        List<String> reportIds = new List<String>();
        String url = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v50.0/analytics/notifications?source=lightningReportSubscribe';
        req.setEndpoint(url);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('GET');
        req.setTimeout(120000);
        HttpResponse res = h.send(req);
        List<SubscribedReportParser> subscribedReportsList = new List<SubscribedReportParser>();
        subscribedReportsList = (List<SubscribedReportParser>)System.JSON.deserialize(res.getBody().replaceAll('\"time\":', '\"time_x\":'), List<SubscribedReportParser>.class);
        for(SubscribedReportParser subscribedReportsData: subscribedReportsList){
            reportIds.add(subscribedReportsData.recordId);
        }
        System.debug('reportIds????' + reportIds);
        MAP<Id, Report> mapToReport = new Map<Id, Report>([SELECT Id, Name FROM Report WHERE Id IN: reportIds]); 
        for(SubscribedReportParser subscribedReportsData: subscribedReportsList){
            String userNames = ''; 
            CustomSubscribedReport customWrapperData = new CustomSubscribedReport();
            customWrapperData.active = subscribedReportsData.active;
            customWrapperData.reportName = mapToReport.get(subscribedReportsData.recordId).Name.replaceAll('[^a-zA-Z0-9\\s+]', '');
            customWrapperData.frequency = subscribedReportsData.schedule.frequency;
            customWrapperData.reportOwner = subscribedReportsData.owner.name;
            for(ThresholdsClass thresholdsRecords: subscribedReportsData.thresholds){
                for(ActionsClass actionClassData: thresholdsRecords.actions){
                    for(RecipientsClass recipientsClassData: actionClassData.configuration.recipients){
                        userNames +=  recipientsClassData.displayName + ', ';
                    }
                }
            }
            customWrapperData.receipents = userNames;
            customResult.add(customWrapperData);
        }*/
        return null;
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below Wrapper class will store the JSON Data for Filtered Reports
*/
    public class FilteredReportsData{
        @AuraEnabled 
        public String reportName { get; set; }
        @AuraEnabled 
        public String folderName { get; set; }
        @AuraEnabled 
        public String reportUniqueName { get; set; }
        @AuraEnabled 
        public String filterBy { get; set; }
        @AuraEnabled 
        public String filterType { get; set; }
        @AuraEnabled 
        public String reportType { get; set; }
        @AuraEnabled 
        public String createdDate { get; set; }
        @AuraEnabled 
        public String lastModifiedDate { get; set; }
        @AuraEnabled 
        public String lastModifiedByName { get; set; }
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will give the User Id of Currently LoggedIn User
*/
    @AuraEnabled
    public static String currentlyLoggedInUserId(){ 
        return UserInfo.getUserId();
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will give Save the JSON data in JSON field of Custom Object Named Report Manager Object
*/
    @AuraEnabled
    public static void saveJSONDataInObject(String jsonData){ 
        List<JSONData> jsonDataList = (List<JSONData>)System.JSON.deserialize(jsonData, List<JSONData>.class);
        List<SA_Audit__Report_Manager_Object__c> reportManagerObjectData = [SELECT Id, SA_Audit__JSON__c FROM SA_Audit__Report_Manager_Object__c WHERE CreatedById =: UserInfo.getUserId() LIMIT 1];
        for(SA_Audit__Report_Manager_Object__c reportManagerObjectOneRecord: reportManagerObjectData){
            if(Schema.sObjectType.SA_Audit__Report_Manager_Object__c.fields.SA_Audit__JSON__c.isUpdateable()){
                SA_Audit__Report_Manager_Object__c reportManagerObjectRecord = new SA_Audit__Report_Manager_Object__c();
                reportManagerObjectRecord.Id = reportManagerObjectOneRecord.Id;
                reportManagerObjectRecord.SA_Audit__JSON__c = JSON.serialize(jsonDataList);
                reportManagerObjectData.add(reportManagerObjectRecord);
            }
        }
        if(reportManagerObjectData.size() == 0){
            if(Schema.sObjectType.SA_Audit__Report_Manager_Object__c.fields.SA_Audit__JSON__c.isCreateable() 
               && Schema.sObjectType.SA_Audit__Report_Manager_Object__c.fields.Name.isCreateable()){
                   SA_Audit__Report_Manager_Object__c reportManagerObjectOneRecord = new SA_Audit__Report_Manager_Object__c();
                   reportManagerObjectOneRecord.Name = 'Test';
                   reportManagerObjectOneRecord.SA_Audit__JSON__c = JSON.serialize(jsonDataList);
                   reportManagerObjectData.add(reportManagerObjectOneRecord);
               }
        }
        if(reportManagerObjectData.size() > 0){
          //  upsert reportManagerObjectData;
            
        }
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will Execute the Batch Apex to delete all the reports from the Archived Folder
*/
    @AuraEnabled
    public static void deleteReports(){
        Database.executeBatch(new DeleteArchivedReportsBatch(), 20);
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will give us the Scheduled Reports Data
*/
    @AuraEnabled
    public static List<ScheduledReportsData> getScheduledReports(){
        List<ScheduledReportsData> scheduledReportsDataList = new List<ScheduledReportsData>();
        MAP<Id, List<String>> reportsDataMap = new MAP<Id, List<String>>();
        List<Id> listOfReportIds = new List<Id>();
        List<CronTrigger> cronTriggerList = [SELECT PreviousFireTime, Id, CronJobDetail.Name, NextFireTime, State, StartTime, EndTime, OwnerId, CreatedBy.Name, CreatedDate, TimesTriggered, CronExpression FROM CronTrigger WHERE CronJobDetail.JobType = '8'];
        for(CronTrigger cronTriggerOneRecord: cronTriggerList){
            listOfReportIds.add(cronTriggerOneRecord.CronJobDetail.Name);
        }
        List<Report> reportList = [SELECT Id, Name, DeveloperName, FolderName, CreatedDate, LastModifiedDate, LastModifiedBy.Name FROM Report WHERE Id IN: listOfReportIds];
        for(Report reportOneRecord: reportList){
            List<String> stringList = new List<String>();
            stringList.add(reportOneRecord.Name);
            stringList.add(reportOneRecord.DeveloperName); 
            stringList.add(reportOneRecord.FolderName);
            stringList.add(reportOneRecord.CreatedDate?.format('MM/dd/yyyy hh:mm a'));
            stringList.add(reportOneRecord.LastModifiedDate?.format('MM/dd/yyyy hh:mm a'));
            stringList.add(reportOneRecord.LastModifiedBy.Name);
            /*Reports.ReportDescribeResult reportDescription = Reports.ReportManager.describeReport(reportOneRecord.Id);
			  Reports.ReportMetadata reportMetadata = reportDescription.getReportMetadata();
              Reports.ReportType reportType = reportMetadata.getReportType();
              stringList.add(reportType.getLabel());*/
            reportsDataMap.put(reportOneRecord.Id, stringList);            
        }
        for(CronTrigger cronTriggerOneRecord: cronTriggerList){
            ScheduledReportsData scheduledReportsOneRecord = new ScheduledReportsData();
            if(reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name) != null){
                scheduledReportsOneRecord.reportName = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[0].replaceAll('[^a-zA-Z0-9\\s+]', '');
                scheduledReportsOneRecord.folderName = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[2].replaceAll('[^a-zA-Z0-9\\s+]', '');
                scheduledReportsOneRecord.reportUniqueName = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[1];
                scheduledReportsOneRecord.createdDate = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[3];
                scheduledReportsOneRecord.lastModifiedDate = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[4];
                scheduledReportsOneRecord.lastModifiedByName = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[5];
                scheduledReportsOneRecord.runningUserName = cronTriggerOneRecord.CreatedBy.Name;
                scheduledReportsOneRecord.startTime = cronTriggerOneRecord.StartTime;
                scheduledReportsOneRecord.endTime = cronTriggerOneRecord.EndTime;
                scheduledReportsOneRecord.previousRunTime = cronTriggerOneRecord.PreviousFireTime;
                scheduledReportsOneRecord.nextRunTime = cronTriggerOneRecord.NextFireTime;
                //scheduledReportsOneRecord.reportType = reportsDataMap.get(cronTriggerOneRecord.CronJobDetail.Name)[3];
                scheduledReportsDataList.add(scheduledReportsOneRecord);
            }
        }
        return scheduledReportsDataList;  
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below Wrapper class will store the JSON Data for Scheduled Reports
*/
    public class ScheduledReportsData{
        @AuraEnabled 
        public String reportName { get; set; }
        @AuraEnabled 
        public String reportType { get; set; }
        @AuraEnabled 
        public String folderName { get; set; }
        @AuraEnabled 
        public String reportUniqueName { get; set; }
        @AuraEnabled 
        public String runningUserName { get; set; }
        @AuraEnabled 
        public DateTime startTime { get; set; }
		@AuraEnabled 
        public DateTime endTime { get; set; } 
        @AuraEnabled 
        public DateTime previousRunTime { get; set; } 
        @AuraEnabled 
        public DateTime nextRunTime { get; set; } 
        @AuraEnabled 
        public String freequency { get; set; }
        @AuraEnabled 
        public String createdDate { get; set; }
        @AuraEnabled 
        public String lastModifiedDate { get; set; }
        @AuraEnabled 
        public String lastModifiedByName { get; set; }
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will Execute the Batch Apex to move all the Reports to Archive Folder
*/    
    @AuraEnabled
    public static void archiveReportsNow(String archiveFolderId, String userId, List<String> folderIds, Date selectedDate, Integer selectedMonth){
        if(selectedDate == null){
            Date today = System.today();
            selectedDate = today.addMonths(-selectedMonth);
        }
        List<String> developerNameOfFolders = new List<String>();
        List<ReportManagerScheduable.WrapperData> wrapperDataList = new List<ReportManagerScheduable.WrapperData>();
        //List<Report_Manager_Object__c> records = [SELECT Id, Name, JSON__c FROM Report_Manager_Object__c WHERE CreatedById =: UserInfo.getUserId()];
        Set<String> setData = new Set<String>();
        //for(Report_Manager_Object__c reportManagerOneRecord: records){
            //List<ReportManagerController.JSONData> jsonDataList = (List<ReportManagerController.JSONData>)System.JSON.deserialize(reportManagerOneRecord.JSON__c, List<ReportManagerController.JSONData>.class);
        ReportManagerScheduable.WrapperData wrapperDataOneRecord = new ReportManagerScheduable.WrapperData();
        wrapperDataOneRecord.archiveFolderId = archiveFolderId;
        wrapperDataOneRecord.userId = userId;
        wrapperDataOneRecord.norifyUser = true;
        setData.addAll(folderIds);
        wrapperDataList.add(wrapperDataOneRecord);
        //}
        developerNameOfFolders.addAll(setData);
        Database.executeBatch(new ReportManagerBatch(wrapperDataList, developerNameOfFolders, selectedDate), 20);
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data related to Archived Reports 
*/
    @AuraEnabled
    public static List<ReportRecords> getArchivedFolderReports(){
        List<ReportRecords> reportRecords = new List<ReportRecords>();
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        List<Reports_History_Tracking__c> reportsHistoryList = [SELECT Id FROM Reports_History_Tracking__c WHERE OwnerId =: UserInfo.getUserId() AND Type__c = 'ArchivedReports'];
        Map<String, Object> mapData = new Map<String, Object>();
        if(reportsHistoryList.size() > 0){
            Attachment attach = [SELECT Id, ParentId, Body FROM Attachment WHERE ParentId =: reportsHistoryList[0].Id];
            mapData = (Map<String, Object>)JSON.deserializeUntyped(attach.Body.toString());
        }
        List<Report> reportList = [SELECT Id, Name, FolderName, LastRunDate, CreatedDate, LastModifiedDate, LastModifiedBy.Name FROM Report WHERE FolderName = 'SA_Audit_Report_Manager_Archived_Folder' AND Format != 'Multiblock' ORDER BY Name ASC];
        for(Report reportOnRecord: reportList){
            try{
                ReportRecords reportOneRecord = new ReportRecords();
                reportOneRecord.Id = reportOnRecord.Id;
                reportOneRecord.reportName = reportOnRecord.Name.replaceAll('[^a-zA-Z0-9\\s+]', '');
                reportOneRecord.folderName = reportOnRecord.FolderName.replaceAll('[^a-zA-Z0-9\\s+]', '');
                reportOneRecord.lastRunDate = reportOnRecord.LastRunDate?.format('MM/dd/yyyy hh:mm a');
                reportOneRecord.folderURL = sfdcURL + '/' + reportOnRecord.Id;
                /*Reports.ReportDescribeResult reportDescription = Reports.ReportManager.describeReport(reportOnRecord.Id);
                Reports.ReportMetadata reportMetadata = reportDescription.getReportMetadata();
                Reports.ReportType reportType = reportMetadata.getReportType();
                reportOneRecord.reportType = reportType.getLabel();*/
                reportOneRecord.createdDate = reportOnRecord.CreatedDate?.format('MM/dd/yyyy hh:mm a');
                reportOneRecord.lastModifiedDate = reportOnRecord.LastModifiedDate?.format('MM/dd/yyyy hh:mm a');
                reportOneRecord.lastModifiedByName = reportOnRecord.LastModifiedBy.Name;
                reportOneRecord.checked = false;
                if(!mapData.isEmpty()){
                    List<Object> items = (List<Object>)mapData.get(reportOnRecord.Id);
                    if(items != null){
                        reportOneRecord.previousFolderName = (String)items[1];
                        reportOneRecord.previousFolderId = (String)items[0];
                    }
                }
                reportRecords.add(reportOneRecord);
            }
            catch(Exception ex){
                
            }
        } 
        return reportRecords;
    }
/*
Author            : Naveen Varshney
Purpose of method : Below method will Unarchived the Selected reports to their Original Folder 
*/
    @AuraEnabled
    public static void unarchivedTheSelectedReports(List<ReportRecords> reportRecordsList){
        List<Reports_History_Tracking__c> reportsHistoryList = [SELECT Id FROM Reports_History_Tracking__c WHERE OwnerId =: UserInfo.getUserId() AND Type__c = 'ArchivedReports' ];
        Map<String, Object> mapData = new Map<String, Object>();
        if(reportsHistoryList.size() > 0){
            Attachment attach = [SELECT Id, ParentId, Body FROM Attachment WHERE ParentId =: reportsHistoryList[0].Id];
            mapData = (Map<String, Object>)JSON.deserializeUntyped(attach.Body.toString());
            for(ReportRecords reportRecord: reportRecordsList){
                if(reportRecord.checked){
                    mapData.remove(reportRecord.Id);
                }
            }
            attach.Body = Blob.valueOf(JSON.serialize(mapData));
            if (Schema.sObjectType.Attachment.fields.Body.isUpdateable()) {
                update attach;
            }
        }
        Database.executeBatch(new UnarchivedSelectedReports(reportRecordsList), 20);
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below method will fetch Data related to Archived Reports based on Specified months 

    @AuraEnabled
    public static List<ReportRecords> viewArchivedDataBasedOnMonths(Integer months){
        List<ReportRecords> reportRecords = new List<ReportRecords>();
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        Date today = System.today();
        Date customDate = today.addMonths(-months);
        List<Report> reportList = [SELECT Id, Name, FolderName, LastRunDate FROM Report WHERE (FolderName = 'Report Manager Archive Folder' AND LastRunDate <: customDate) OR (FolderName = 'Report Manager Archive Folder' AND LastRunDate =: null) ORDER BY Name ASC];
        for(Report reportOnRecord: reportList){
            ReportRecords reportOneRecord = new ReportRecords();
            reportOneRecord.Id = reportOnRecord.Id;
            reportOneRecord.reportName = reportOnRecord.Name;
            reportOneRecord.folderName = reportOnRecord.FolderName;
            reportOneRecord.lastRunDate = reportOnRecord.LastRunDate?.format('MM/dd/yyyy hh:mm a');
            reportOneRecord.folderURL = sfdcURL + '/' + reportOnRecord.Id;
            reportRecords.add(reportOneRecord);
        }
        return reportRecords;
    }
*/
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below Wrapper class will store the data for all Reports 
*/
    public class ReportRecords{
        @AuraEnabled 
        public String id { get; set; }
        @AuraEnabled 
        public String reportName { get; set; }
        @AuraEnabled 
        public String folderName { get; set; }
        @AuraEnabled 
        public String lastRunDate { get; set; }
        @AuraEnabled 
        public String folderURL { get; set; }
        @AuraEnabled 
        public String createdDate { get; set; }
        @AuraEnabled 
        public String lastModifiedDate { get; set; }
        @AuraEnabled 
        public String lastModifiedByName { get; set; }
        @AuraEnabled 
        public String reportType { get; set; }
        @AuraEnabled 
        public String previousFolderName { get; set; }
        @AuraEnabled 
        public String previousFolderId { get; set; }
        @AuraEnabled 
        public Boolean checked { get; set; }
    }
/*
Author            : Himanshu Kr. Varshney
Purpose of method : Below Wrapper class will store the JSON Data 
*/
    public class JSONData{
        @AuraEnabled 
        public Boolean scheduleArchive { get; set; }
        @AuraEnabled 
        public List<String> folderIds { get; set; }
        @AuraEnabled 
        public Boolean norifyUser { get; set; }
        @AuraEnabled 
        public String archiveFolderId { get; set; }
        @AuraEnabled 
        public String userId { get; set; }
    }

/*
Author            : Naveen Varshney
Purpose of method : Below Wrapper class will store the JSON Data for Subscribed Reports
*/  
    public class CustomSubscribedReport{
        @AuraEnabled
        public String reportName{ get; set; }
        @AuraEnabled
        public String reportOwner{ get; set; }
        @AuraEnabled
        public String frequency{ get; set; }
        @AuraEnabled
		public String receipents{ get; set; }
        @AuraEnabled
		public Boolean active{ get; set; }
    }    
    public class SubscribedReportParser{
        @AuraEnabled
        public String recordId { get; set; }
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public OwnerClass owner { get; set; }
        @AuraEnabled
        public String lastModifiedDate { get; set; }
        @AuraEnabled
        public RunAsClass runAs { get; set; }
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public ScheduleClass schedule { get; set; }
        @AuraEnabled
        public Boolean deactivateOnTrigger { get; set; }
        @AuraEnabled
        public String source { get; set; }
        @AuraEnabled
        public String createdDate { get; set; }
        @AuraEnabled
        public List<ThresholdsClass> thresholds { get; set; }
        @AuraEnabled
        public Boolean active { get; set; }
    }
    public class RunAsClass{
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String name { get; set; }
    }
    public class ThresholdsClass{
        @AuraEnabled
        public String conditions { get; set; }
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public List<ActionsClass> actions { get; set; }
    }
    public class ScheduleClass{
        @AuraEnabled
        public DetailsClass details { get; set; }
        @AuraEnabled
        public String frequency { get; set; }
    }
    public class RecipientsClass{
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String displayName { get; set; }
        @AuraEnabled
        public String type { get; set; }
    }
    public class OwnerClass{
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String id { get; set; }
    }
    public class DetailsClass{
        @AuraEnabled
        public List<String> daysOfWeek { get; set; }
    }
    public class ConfigurationClass{
        @AuraEnabled
        public List<RecipientsClass> recipients { get; set; }
    }
    public class ActionsClass{
        @AuraEnabled
        public configurationClass configuration { get; set; }
        @AuraEnabled
        public String type { get; set; }
    }
}