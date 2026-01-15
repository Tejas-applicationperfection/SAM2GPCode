/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for FilteredReportsExcelController.apxc
*/
@isTest
public with sharing class FilterReportsExcelControllerTest{
    @isTest(SeeAllData='true')
    static void testMethodForApexClass(){
        Test.startTest();
        FilterReportsExcelController classObj = new FilterReportsExcelController();
        System.assertNotEquals(null, classObj.reportsList);
        Test.stopTest();
    }
}