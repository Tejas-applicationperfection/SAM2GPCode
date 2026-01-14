/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for DashboardReportExcelController.apxc
*/
@isTest
public with sharing class DashboardReportExcelControllerTest{
    @isTest(SeeAllData=true)
    static void test(){
        Test.startTest();
        DashboardReportExcelController classObj = new DashboardReportExcelController();
        System.assertNotEquals(null, classObj.xmlheader);
        Test.stopTest();
    }
    /*@isTest(SeeAllData=false)
    static void batchApexExecutionToSendAnEmailTest(){
        Test.startTest();
        List<String> listOfIds = new List<String>();
        IntelController.batchApexExecutionToSendAnEmail(listOfIds);
        //Database.executeBatch(new GenerateAllReports(listOfIDs), 200);
        String str = 'Fake';
        System.assertNotEquals(null, str);
        Test.stopTest();
    }*/
}