/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for FilteredReportsExcelController.apxc
*/
@isTest
public with sharing class FilteredReportsExcelControllerTest{
    @isTest(SeeAllData='true')
    static void testMethodForApexClass(){
        Test.startTest();
        FilteredReportsExcelController classObj = new FilteredReportsExcelController();
        System.assertNotEquals(null, classObj.reportsList);
        Test.stopTest();
    }
}