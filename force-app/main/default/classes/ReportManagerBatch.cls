/*
Author       : Himanshu Kr. Varshney
Description  : This is Batch Apex to move all reports from one Folder to another Folder
Dependencies : Called from ReportManagerScheduable.apxc class 
*/
public with sharing class ReportManagerBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    @AuraEnabled
    public List<ReportManagerScheduable.WrapperData> wrapperDataList { get; set; }
    @AuraEnabled
    public List<String> developerNameOfFolder { get; set; }
    @AuraEnabled
    public MAP<String, String> folderNames { get; set; }
    @AuraEnabled
    public Map<Id, List<String>> mapData { get; set; }
    @AuraEnabled 
    public Date dateSinceLastRun { get; set; } 
    public ReportManagerBatch(List<ReportManagerScheduable.WrapperData> wrapperList, List<String> developerNameOfFolder, Date dateSinceLastRun){
        this.wrapperDataList = wrapperList;
        this.developerNameOfFolder = developerNameOfFolder;
        this.folderNames = new MAP<String, String>();
        this.mapData = new Map<Id, List<String>>();
        this.dateSinceLastRun = dateSinceLastRun;
    }
    public ReportManagerBatch(List<ReportManagerScheduable.WrapperData> wrapperList, List<String> developerNameOfFolder){
        this.wrapperDataList = wrapperList;
        this.developerNameOfFolder = developerNameOfFolder;
        this.folderNames = new MAP<String, String>();
        this.mapData = new Map<Id, List<String>>();
    }
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query;
        String conditionValue = '';
        conditionValue = '\'' + String.join(developerNameOfFolder, '\', \'') + '\'';
        System.debug('conditionValue?????' + conditionValue);
        
        query = 'SELECT Id, Name, FolderName, DeveloperName, NamespacePrefix, Description FROM Report WHERE FolderName IN' + ' (' + conditionValue + ')';
        if (this.dateSinceLastRun != null){
            DateTime str = this.dateSinceLastRun;
            String nullStr = null;
            //query = query + ' AND (LastRunDate <: this.dateSinceLastRun OR  LastRunDate =: null)';
            
            //query = query + ' AND (LastRunDate <: ' +  '\'' + this.dateSinceLastRun + '\'' + ' OR  LastRunDate =: ' + null + ')';
            query = query + ' AND (LastRunDate <: str OR  LastRunDate =: nullStr)';
        }
        System.debug('queryForBatch>>>' + query);
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<Report> records){
        for(Report reportRecord: records){
            try {
                String folderId = getFolderId(reportRecord.Id);
                HttpResponse response = updateReportFolderId(reportRecord.Id, wrapperDataList[0].archiveFolderId);
                if(response.getStatusCode() == 200){
                    folderNames.put(reportRecord.Id, reportRecord.Name);
                    List<String> listData = new List<String>();
                    listData.add(folderId);
                    listData.add(reportRecord.FolderName);

                    mapData.put(reportRecord.Id, listData);
                }
                
            } catch (Exception ex) {
                System.debug('Exception: ' + ex.getMessage() + ' Line Number: ' + ex.getLineNumber() + ' Stack Trace : ' + ex.getStackTraceString());
            }
        }
    }
    public void finish(Database.BatchableContext bc){
        List<String> toAddresses = new List<String>();
        MAP<Id, String> mapEmailAddress = new MAP<Id, String>();
        for(ReportManagerScheduable.WrapperData wrapperDataOneRecord: wrapperDataList){
            if(wrapperDataOneRecord.norifyUser){
                toAddresses.add(wrapperDataOneRecord.userId);
            }
        }
        List<User> userList = [SELECT Id, Email FROM User WHERE Id IN: toAddresses];
        toAddresses.clear();
        for(User userOneRecord: userList){
            toAddresses.add(userOneRecord.Email);
        }
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject('Your Report Manager App');
        String body = '';
        body += 'Dear <b>' + UserInfo.getFirstName() + ' ' + UserInfo.getLastName() + '</b>,';
        body += '<br/>';
        body += '<br/>';
        body += 'Today Report Manager archived the following reports';
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
        List<Reports_History_Tracking__c> reportsHistoryList = [SELECT Id FROM Reports_History_Tracking__c WHERE OwnerId =: UserInfo.getUserId() AND Type__c = 'ArchivedReports'];
        if(reportsHistoryList.size() > 0){
            Map<String, Object> mapExistingData = new Map<String, Object>();
            Attachment attach = [SELECT Id, ParentId, Body FROM Attachment WHERE ParentId =: reportsHistoryList[0].Id];
            mapExistingData = (Map<String, Object>)JSON.deserializeUntyped(attach.Body.toString());
            if(!mapExistingData.isEmpty()){
                for(String key: mapExistingData.keySet()){
                    List<Object> items = (List<Object>)mapExistingData.get(key);
                    List<String> strList = new List<String>();
                    strList.add((String)items[0]);
                    strList.add((String)items[1]);
                    mapData.put(key, strList);
                    if (Schema.sObjectType.Attachment.fields.Body.isUpdateable()) {
                        attach.Body = Blob.valueOf(JSON.serialize(mapData));
                    //	update attach;
                	}
                    
                }
            }
            else{
                if (Schema.sObjectType.Attachment.fields.Body.isUpdateable()) {
                    attach.Body = Blob.valueOf(JSON.serialize(mapData));
                	//update attach;
                }
            }
        }
        else{
            Reports_History_Tracking__c reportsHistoryData = new Reports_History_Tracking__c();
            if(Schema.sObjectType.Reports_History_Tracking__c.fields.Type__c.isCreateable()){
                reportsHistoryData.Type__c = 'ArchivedReports'; 
                insert reportsHistoryData;
                Attachment attach = new Attachment();
                if (Schema.sObjectType.Attachment.fields.Name.isCreateable() 
                    && Schema.sObjectType.Attachment.fields.ContentType.isCreateable() 
                    && Schema.sObjectType.Attachment.fields.parentId.isCreateable() 
                    && Schema.sObjectType.Attachment.fields.Body.isCreateable()
                    ) {// if(Schema.sObjectType.Attachment.fields.Body.isCreateable()
                        //&& Schema.sObjectType.Attachment.fields.parentId.isCreateable()
                        // && Schema.sObjectType.Attachment.fields.ContentType.isCreateable()
                        //  && Schema.sObjectType.Attachment.fields.Name.isCreateable()){
     
                    attach.Name = 'ArchivedReports';
                    attach.ContentType = 'text/plain';
                    attach.parentId = reportsHistoryData.Id;
                    attach.Body = Blob.valueOf(JSON.serialize(mapData));
                  //  insert attach;
                }
        	}
        }        
    }
    public static HttpResponse updateReportFolderId(String reportId, String folderId){
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
        HttpResponse response = h.send(req);
        return response;
    }
    public static String getFolderId(String reportId){
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        String url = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v34.0/analytics/reports/' + reportId;
        req.setEndpoint(url);
        req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('GET');
        req.setTimeout(120000);
        HttpResponse response = h.send(req);
		Map<String, Object> results = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        Map<String, Object> folderIdMap = (Map<String, Object>)results.get('reportMetadata');
        return (String)folderIdMap.get('folderId');
    }
}