/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for ReportsExcelController.apxc
*/
@isTest
public with sharing class ReportsExcelControllerTest{
    @isTest(SeeAllData='true')
    static void testMethodForApexClass(){
        Test.startTest();
        PageReference page = Page.ReportsExcel;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('flag', 'true');
        ApexPages.currentPage().getParameters().put('selectedDate', '2021-02-09');
        ReportsExcelController classObj = new ReportsExcelController();
        System.assertNotEquals(null, classObj.reportsList);
        ApexPages.currentPage().getParameters().put('flag', 'false');
        ApexPages.currentPage().getParameters().put('selectedOption', '6');
        ReportsExcelController classObj1 = new ReportsExcelController();
        System.assertNotEquals(null, classObj1.reportsList);
        Test.stopTest();
    }
}