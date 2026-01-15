/*
Author      : Himanshu Kr. Varshney
Description : This Class is Test class for ArchiveReportsExcelController.apxc
*/
@isTest
public with sharing class ArchiveReportsExcelControllerTest{
    @isTest(SeeAllData='true')
    static void testMethodForApexClass(){
        Test.startTest();
        ArchiveReportsExcelController classObj = new ArchiveReportsExcelController();
        System.assertNotEquals(null, classObj.reportsList);
        Test.stopTest();
    }
}