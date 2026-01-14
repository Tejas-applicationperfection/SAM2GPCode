/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for FilteredReportsBatchApex.apxc
Dependencies : FilteredReportsBatchApex.apxc
*/
@isTest
public with sharing class FilteredReportsBatchApexTest{
    @isTest(SeeAllData = true)
    static void test(){
        Test.startTest();
        Database.executeBatch(new FilteredReportsBatchApex(), 100);
        Test.stopTest();
    }
}