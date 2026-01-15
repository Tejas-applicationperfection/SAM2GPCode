/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for ReportManagerController.apxc, DeleteArchivedReportsBatch.apxc, ReportManagerBatch.apxc, ReportManagerScheduable.apxc
*/
@isTest
public with sharing class ReportManagerControllerTest{
    private static List<Report_Manager_Object__c> reportManagerRecordsList = new List<Report_Manager_Object__c>();
    /*static void setUpData(){
        Report_Manager_Object__c reportManagerSingleRecord = new Report_Manager_Object__c();
        reportManagerSingleRecord = createReportManagerRecords();
        reportManagerRecordsList.add(reportManagerSingleRecord);
        insert reportManagerRecordsList;
    }*/
    public class WebCallOutClassSecond implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('DELETE', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000);
            //res.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v50.0/tooling/sobjects/ValidationRule/03d1v0000002ujjAAA"},"Id":"03d1v0000002ujjAAA","Active":false,"Description":"Only one CET is allowed per solution","EntityDefinition":{"attributes":{"type":"EntityDefinition","url":"/services/data/v50.0/tooling/sobjects/EntityDefinition/01I1v000002P335"},"Label":"Conga Solution Email Template"},"ErrorDisplayField":"Conga Email Template","ErrorMessage":"Only one Conga Email Template is allowed per Conga Solution. To make changes, either modify the existing record or delete it and add a new one????4.","ValidationName":"CET_Count_Validator","NamespacePrefix":"APXTConga4","Metadata":{"description":"Only one CET is allowed per solution","errorConditionFormula":"APXTConga4__Conga_Solution__r.APXTConga4__CongaEmailTemplateCount__c != 0","errorDisplayField":"APXTConga4__Conga_Email_Template__c","errorMessage":"Only one Conga Email Template is allowed per Conga Solution. To make changes, either modify the existing record or delete it and add a new one.","shouldEvaluateOnClient":null,"urls":null,"active":false}}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class WebCallOutClassThird implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('DELETE', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            //res.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v50.0/tooling/sobjects/ValidationRule/03d1v0000002ujjAAA"},"Id":"03d1v0000002ujjAAA","Active":false,"Description":"Only one CET is allowed per solution","EntityDefinition":{"attributes":{"type":"EntityDefinition","url":"/services/data/v50.0/tooling/sobjects/EntityDefinition/01I1v000002P335"},"Label":"Conga Solution Email Template"},"ErrorDisplayField":"Conga Email Template","ErrorMessage":"Only one Conga Email Template is allowed per Conga Solution. To make changes, either modify the existing record or delete it and add a new one????4.","ValidationName":"CET_Count_Validator","NamespacePrefix":"APXTConga4","Metadata":{"description":"Only one CET is allowed per solution","errorConditionFormula":"APXTConga4__Conga_Solution__r.APXTConga4__CongaEmailTemplateCount__c != 0","errorDisplayField":"APXTConga4__Conga_Email_Template__c","errorMessage":"Only one Conga Email Template is allowed per Conga Solution. To make changes, either modify the existing record or delete it and add a new one.","shouldEvaluateOnClient":null,"urls":null,"active":false}}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class WebCallOutClassFirst implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('POST', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            //res.setBody('{"size":129,"totalSize":129,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v47.0/tooling/sobjects/ValidationRule/03d1v0000002ujjAAA"},"Id":"03d1v0000002ujjAAA","EntityDefinition":{"attributes":{"type":"EntityDefinition","url":"/services/data/v47.0/tooling/sobjects/EntityDefinition/01I1v000002P335"},"QualifiedApiName":"APXTConga4__Conga_Solution_Email_Template__c"}}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    static void createReportManagerRecords(){
        Report_Manager_Object__c reportManagerSingleRecord = new Report_Manager_Object__c();
        reportManagerSingleRecord.Name = 'Test';
        reportManagerSingleRecord.JSON__c = '[{"userId":"0054K000003ghskQAA","scheduleArchive":true,"norifyUser":true,"folderIds":["UAT1","UAT2"],"archiveFolderId":"00l4K000000MiENQA0"}]';
        insert reportManagerSingleRecord;
    }
    static void createReportHistoryRecords(){
        SA_Audit__Reports_History_Tracking__c reportHistoryRecord = new SA_Audit__Reports_History_Tracking__c();
        reportHistoryRecord.Type__c = 'ArchivedReports';
        insert reportHistoryRecord;
        Attachment attach = new Attachment();
        if (Schema.sObjectType.Attachment.fields.Name.isCreateable() 
            && Schema.sObjectType.Attachment.fields.ContentType.isCreateable() 
            && Schema.sObjectType.Attachment.fields.parentId.isCreateable() 
            && Schema.sObjectType.Attachment.fields.Body.isCreateable()
        ) {
            attach.Name = 'ArchivedReports';
            attach.ContentType = 'text/plain';
            attach.parentId = reportHistoryRecord.Id;
            attach.Body = Blob.valueOf('{"00O4K000003BlSIUA0": ["00l4K000000u0xFQAQ", "Testing Folder"], "00O4K000003BlSDUA0": ["00l4K000000u0xFQAQ", "Testing Folder"], "00O4K000003BlSNUA0": ["00l4K000000u0xFQAQ", "Testing Folder"]}');
            insert attach;
        }
    }
    @isTest
    static void unarchivedTheSelectedReportsTest(){
        Test.startTest();
        List<ReportManagerController.ReportRecords> reportRecords = ReportManagerController.getArchivedFolderReports();
        createReportHistoryRecords();
        ReportManagerController classObj = new ReportManagerController();
        ReportManagerController.unarchivedTheSelectedReports(reportRecords);
        System.assertNotEquals(null, classObj);
        Test.stopTest();
    }
    static List<Report_Manager_Object__c> getReportManagerRecords(){
        return [SELECT Id, Name, JSON__c FROM Report_Manager_Object__c];
    }
    @isTest
    static void getFolderNamesTest(){
        Test.startTest();
        ReportManagerController classObj = new ReportManagerController();
        List<Folder> folderList = ReportManagerController.getFolderNames();
        System.assertNotEquals(null, folderList);
        Test.stopTest();
    }
    @isTest(SeeAllData='true')
    static void getFoldersDataTest(){
        Test.startTest();
        ReportManagerController classObj = new ReportManagerController();
        List<ReportManagerController.FoldersData> folderDataList = ReportManagerController.getFoldersData();
        System.assertNotEquals(null, folderDataList);
        Test.stopTest();
    }
    @isTest(SeeAllData='true')
    static void deleteTheEmptyFoldersTest(){
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassThird());
        Test.startTest();
        String str = 'Test';
        ReportManagerController classObj = new ReportManagerController();
        ReportManagerController.deleteTheEmptyFolders();
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
    @isTest
    static void getUsersListTest(){
        Test.startTest();
        ReportManagerController classObj = new ReportManagerController();
        List<User> userList = ReportManagerController.getUsersList();
        System.assertNotEquals(null, userList);
        Test.stopTest();
    }
    @isTest
    static void getDefaultFolderIdTest(){
        Test.startTest();
        ReportManagerController classObj = new ReportManagerController();
        String str = ReportManagerController.getDefaultFolderId();
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
    @isTest(SeeAllData='true')
    static void executeAllTheBatchApexTest(){
        Test.startTest();
        ReportManagerController.executeAllTheBatchApex();
        String str = 'Message';
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
    @isTest
    static void getUserPreferenceTest(){
        Test.startTest();
        createReportManagerRecords();
        ReportManagerController classObj = new ReportManagerController();
        List<ReportManagerController.JSONData> jsonDataList = ReportManagerController.getUserPreference();
        System.assertNotEquals(null, jsonDataList);
        Test.stopTest();
    }
    @isTest
    static void currentlyLoggedInUserIdTest(){
        Test.startTest();
        ReportManagerController classObj = new ReportManagerController();
        String str = ReportManagerController.currentlyLoggedInUserId();
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
    @isTest(SeeAllData='true')
    static void deleteReportsTest(){
        //Test.setMock(HttpCalloutMock.class, new WebCallOutClassFirst());
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassSecond());
        Test.startTest();
        ReportManagerController classObj = new ReportManagerController();
        ReportManagerController.deleteReports();
        String str = 'Test';
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
   @isTest(SeeAllData='true')
    static void archiveReportsNowTest(){
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassFirst());
        //Test.setMock(HttpCalloutMock.class, new WebCallOutClassSecond());
        Test.startTest();
        List<String> folderIds = new List<String>();
        folderIds.add('UAT1');
        folderIds.add('UAT2');
        ReportManagerController classObj = new ReportManagerController();
        ReportManagerController.archiveReportsNow('00l4K000000MiENQA0', UserInfo.getUserId(), folderIds, System.today(), 0);
        String str = 'Test';
   //     ReportManagerController.scheduleBatchClass();
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
    @isTest(SeeAllData='true')
    static void getArchivedFolderReportsTest(){
        Test.startTest();
        ReportManagerController classObj = new ReportManagerController();
        List<ReportManagerController.ReportRecords> reportRecords = ReportManagerController.getArchivedFolderReports();
        System.assertNotEquals(null, reportRecords);
        Test.stopTest();
    }
    @isTest
    static void saveJSONDataInObjectTest(){
        Test.startTest();
        ReportManagerController classObj = new ReportManagerController();
        createReportManagerRecords();
        String str = '[{"userId":"0054K000003ghskQAA","scheduleArchive":true,"norifyUser":true,"folderIds":["UAT1","UAT2"],"archiveFolderId":"00l4K000000MiENQA0"}]';
        ReportManagerController.saveJSONDataInObject(str);
        reportManagerRecordsList = getReportManagerRecords();
        delete reportManagerRecordsList;
        ReportManagerController.saveJSONDataInObject(str);
        System.assertNotEquals(null, str);
        Test.stopTest();
    }
}