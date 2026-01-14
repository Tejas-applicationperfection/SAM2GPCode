/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for EmptyReportsExcelController.apxc
*/
@isTest
public with sharing class EmptyReportsExcelControllerTest{
    @isTest(SeeAllData='true')
    static void testMethodForApexClass(){
        Test.startTest();
        EmptyReportsExcelController classObj = new EmptyReportsExcelController();
        System.assertNotEquals(null, classObj.reportsList);
        Test.stopTest();
    }
}