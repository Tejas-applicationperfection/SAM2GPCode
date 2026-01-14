/*
Author       : Himanshu Kr. Varshney
Description  : Batch Apex for Intel tab, Option 22 which will generate the Data for all the List View for Objects
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class ListViewBatchApex implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful{
    @AuraEnabled
    public List<String> objectIdsList;
    @AuraEnabled
    public MAP<String, String> mapData;  
    @AuraEnabled
    public MAP<String, String> listViewMap;
    @AuraEnabled
    public MAP<String, String> listViewUniqueNameMap;
    @AuraEnabled
    public List<FinalClass> finalDataList { get; set; }
    public ListViewBatchApex(){
        this.finalDataList = new List<FinalClass>();
        this.objectIdsList = new List<String>();
        this.mapData = new MAP<String, String>();
        this.listViewMap = new MAP<String, String>();
        this.listViewUniqueNameMap = new MAP<String, String>();
    }
    public Iterable<String> start(Database.BatchableContext BC){
        List<ListView> listViewRecords = new List<ListView>();
        if(Test.isRunningTest()){
           listViewRecords = [SELECT Id, Name, DeveloperName, NamespacePrefix, SobjectType FROM ListView WHERE SobjectType =: 'Account' ORDER BY SobjectType ASC];
        }
        else{
            listViewRecords = [SELECT Id, Name, DeveloperName, NamespacePrefix, SobjectType FROM ListView WHERE Id != null ORDER BY SobjectType ASC];
        }
        for(ListView listviewRecord: listViewRecords){
            objectIdsList.add(listviewRecord.Id);
            mapData.put(listviewRecord.Id, listviewRecord.SobjectType);
            listViewMap.put(listviewRecord.Id, listviewRecord.Name);
            listViewUniqueNameMap.put(listviewRecord.Id, listviewRecord.DeveloperName);
        }
        return objectIdsList;
    }
    public void execute(Database.BatchableContext BC, List<String> scope){
        for(String s : scope){
            String objectName = '';
            String selectedFields = '';
            String scopeValue = '';
            String whereConditions = '';
            String listViewName = '';
            String listViewUniqueName = '';
            String toolingAPIURL = '/services/data/v32.0/sobjects/' + mapData.get(s) + '/listviews/' + s + '/describe'; 
            objectName = mapData.get(s);
            HttpResponse response = getListViewDetails(toolingAPIURL);
            if(response.getStatusCode() == 200){
                JSONData finalResponse = (JSONData)JSON.deserialize(response.getBody(), JSONData.class);
                system.debug('=========finalResponse========='+finalResponse);
                for(Columns firstColumnData: finalResponse.columns){
                    if(!firstColumnData.hidden){
                        selectedFields += firstColumnData.fieldNameOrPath + ', ';
                    }
                }
                objectName = finalResponse.sobjectType;
                scopeValue = finalResponse.scope;
                if(scopeValue == null){
                    scopeValue = 'All OWD Sharing Reports';
                }
                else{
                    scopeValue = 'My OWD Sharing Reports';
                }
                if(finalResponse.whereCondition.conditions != null){
                    for(Conditions oneConditionsRec : finalResponse.whereCondition.conditions){
                        if(oneConditionsRec.field != null && oneConditionsRec.operator != null && oneConditionsRec.values.size() > 0){
                            whereConditions += oneConditionsRec.field + ' ' + oneConditionsRec.operator + ' ' + oneConditionsRec.values[0] + ' ,';
                        }
                    }
                }
                listViewName = listViewMap.get(s);
                listViewUniqueName = listViewUniqueNameMap.get(s);
                finalDataList.add(new FinalClass(listViewName, objectName, listViewUniqueName, scopeValue, whereConditions, selectedFields));
            	system.debug('testing finalDataList=='+finalDataList);
            }
        }
    }
    public void finish(Database.BatchableContext BC){
        SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        List<SA_Audit__OWD_Sharing_Report__c> owdSharingReportList = [SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ListView' LIMIT 100];
        if(owdSharingReporTList.size() > 0 && SA_Audit__OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
            delete owdSharingReportList;
        }
        if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable() && Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isUpdateable()){
            owdObjRecord.SA_Audit__Type__c = 'ListView';
            upsert owdObjRecord;
        }
         if(Schema.sObjectType.Attachment.fields.Body.isCreateable() && Schema.sObjectType.Attachment.fields.parentId.isCreateable()){

        Attachment att = getListViewFile();
        att.parentId = owdObjRecord.Id;
        att.Body = Blob.valueOf(JSON.serialize(finalDataList));
             insert att;}
    }
    public static Attachment getListViewFile(){
        Blob excelData;
         Attachment attach = new Attachment();
         if( Schema.sObjectType.Attachment.fields.ContentType.isCreateable() && Schema.sObjectType.Attachment.fields.Name.isCreateable()){

         attach.Name = 'ListViewReports';
        attach.ContentType = 'text/plain';
             }
        return attach;
    }
    public static HttpResponse getListViewDetails(String toolingAPIURL){
        HttpRequest req = new HttpRequest();
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        req.setEndpoint(sfdcURL + toolingAPIURL);
        req.setMethod('GET');
        req.setTimeout(120000);
        String sessionId = UserInfo.getSessionId();
        // String sessionId = 'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res;
    }
    public class FinalClass{
        @AuraEnabled
        public String viewName { get; set; }
        @AuraEnabled
        public String sobjectType { get; set; }
        @AuraEnabled
        public String viewUniqueName { get; set; }
        @AuraEnabled
        public String filterByOwner { get; set; }
        @AuraEnabled
        public String additionalFilters { get; set; }
        @AuraEnabled
        public String selectedFields { get; set; }
        public FinalClass(String data1, String data2, String data3, String data4, String data5, String data6){
            system.debug('testing data'+data1+'+++'+data2+'+++'+data3+'+++'+data4+'+++'+data5+'+++'+data6);
            this.viewName = data1;
            this.sobjectType = data2;
            this.viewUniqueName = data3;
            this.filterByOwner = data4;
            this.additionalFilters = data5;
            this.selectedFields = data6;
            system.debug('testing data'+data1+'+++'+data2+'+++'+data3+'+++'+data4+'+++'+data5+'+++'+data6);
        }
    } 
    public class JSONData{
        @AuraEnabled
        public List<Columns> columns { get; set; }
        @AuraEnabled
        public String scope { get; set; }
        @AuraEnabled
        public String sobjectType { get; set; }
        @AuraEnabled
        public WhereConditions whereCondition { get; set; }
    }
    public class Columns{
        @AuraEnabled
        public String fieldNameOrPath { get; set; }
        @AuraEnabled
        public Boolean hidden { get; set; }
    }
    public class WhereConditions{
        @AuraEnabled
        public List<Conditions> conditions { get; set; }
    }
    public class Conditions{
        @AuraEnabled
        public String field { get; set; }
        @AuraEnabled
        public String operator { get; set; }
        @AuraEnabled
        public List<String> values { get; set; }
    }
}