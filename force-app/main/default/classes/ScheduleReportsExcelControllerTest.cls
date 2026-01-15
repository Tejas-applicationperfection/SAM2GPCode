/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for ScheduleReportsExcelController.apxc
Dependencies : ScheduleReportsExcelController.apxc, IntelController.apxc, ScheduledReportsBatchApex.apxc
*/
@isTest
public with sharing class ScheduleReportsExcelControllerTest{
    private static List<SA_Audit__OWD_Sharing_Report__c> scheduledReportsList = new List<SA_Audit__OWD_Sharing_Report__c>();
    static final Integer size = 1;
    static void createIntializeData(){
        SA_Audit__OWD_Sharing_Report__c scheduledReportOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        scheduledReportOneRecord = createScheduledReportsRecord();
        scheduledReportsList.add(scheduledReportOneRecord);
        insert scheduledReportsList;
        Attachment attach = new Attachment();
        attach.Name = 'ScheduledReports';
        attach.ContentType = 'text/plain';
        attach.parentId = scheduledReportsList[0].Id;
        attach.Body = Blob.valueOf('[{"endTime":"2021-04-28T22:59:59.000Z","folderName":"Private Reports","previousRunTime":"2021-04-28T00:29:00.080Z","reportName":"Test Reports","reportUniqueName":"Test_Reports","runningUserName":"Himanshu Varshney","startTime":"2021-04-26T23:00:00.000Z"}]');
        insert attach;
        /*SA_Audit__BatchApexStatus__c customSettingRecord = new SA_Audit__BatchApexStatus__c();
        customSettingRecord.Name = 'ScheduledReports';
        insert customSettingRecord;*/
    }
    static SA_Audit__OWD_Sharing_Report__c createScheduledReportsRecord(){
        SA_Audit__OWD_Sharing_Report__c scheduledReportsOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        scheduledReportsOneRecord.Name = 'Test';
        scheduledReportsOneRecord.SA_Audit__Type__c = 'ScheduledReports';
        return scheduledReportsOneRecord;
    }
    static List<SA_Audit__OWD_Sharing_Report__c> getScheduledReportsRecords(){
        List<SA_Audit__OWD_Sharing_Report__c> permissionSetsList = [SELECT Id, Name, SA_Audit__Type__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ScheduledReports' LIMIT 1];
        return permissionSetsList;
    }
    @isTest(SeeAllData = true)
    static void getPermissionSetsDetailsTest(){
        createIntializeData();
        Test.startTest();
        scheduledReportsList = getScheduledReportsRecords();
        ScheduleReportsExcelController obj = new ScheduleReportsExcelController();
        System.assertEquals(size, scheduledReportsList.size());
        System.assertNotEquals(null, obj.reportsList);
        Test.stopTest();
    }
}