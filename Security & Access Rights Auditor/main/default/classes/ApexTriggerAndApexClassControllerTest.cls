/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for ApexTriggerAndApexClassController.apxc
Dependencies : ApexTriggerAndApexClassController.apxc
*/
@isTest
public with sharing class ApexTriggerAndApexClassControllerTest{
    @isTest
    static void getApexTriggersAndApexClassDetailsTest(){
        Test.startTest();
        ApexTriggerAndApexClassController classObj = new ApexTriggerAndApexClassController();
        ApexTriggerAndApexClassController.WrapperData wrapperDataList = ApexTriggerAndApexClassController.getApexTriggersAndApexClassDetails();
        System.assertNotEquals(null, wrapperDataList);
        Test.stopTest();
    }
    @isTest(SeeAllData='true')
    static void fetchTableDataOption23Test(){
        Test.startTest();
        List<IntelController.ScheduledReportsData> scheduledReportsList = IntelController.fetchTableDataOption23();
        System.assertNotEquals(null, scheduledReportsList);
        Test.stopTest();
    }
    @isTest(SeeAllData='true')
    static void fetchTableDataOption24Test(){
        Test.startTest();
        List<IntelController.FilteredReportsData> filteredReportsList = IntelController.fetchTableDataOption24();
        System.assertNotEquals(null, filteredReportsList);
        Test.stopTest();
    }
    @isTest(SeeAllData='true')
    static void fetchTableDataOption25Test(){
        Test.startTest();
        List<IntelController.FoldersData> folderList = IntelController.fetchTableDataOption25();
        System.assertNotEquals(null, folderList);
        Test.stopTest();
    }
}