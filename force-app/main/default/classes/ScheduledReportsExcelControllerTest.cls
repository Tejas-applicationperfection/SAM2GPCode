/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for ScheduledReportsExcelController.apxc
*/
@isTest
public with sharing class ScheduledReportsExcelControllerTest{
    @isTest(SeeAllData='true')
    static void testMethodForApexClass(){
        Test.startTest();
        ScheduledReportsExcelController classObj = new ScheduledReportsExcelController();
        System.assertNotEquals(null, classObj.reportsList);
        Test.stopTest();
    }
}