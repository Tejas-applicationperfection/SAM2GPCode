/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for ListViewExcelController.apxc
Dependencies : ListViewExcelController.apxc
*/
@isTest
public with sharing class ListViewExcelControllerTest{
    private static List<SA_Audit__OWD_Sharing_Report__c> listViewList = new List<SA_Audit__OWD_Sharing_Report__c>();
    static final Integer size = 1;
    @testSetup
    static void setUpData(){
        SA_Audit__OWD_Sharing_Report__c listViewOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        listViewOneRecord = createListViewRecord();
        listViewList.add(listViewOneRecord);
        insert listViewList;
        Attachment  attach = createAttachmentRecord();
        attach.parentId = listViewList[0].Id;
        attach.Body = Blob.valueOf('[{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__S_Audit__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""},{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__Test_Object__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""}]');
        insert attach;
    }
    static SA_Audit__OWD_Sharing_Report__c createListViewRecord(){
        SA_Audit__OWD_Sharing_Report__c listViewOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        listViewOneRecord.Name = 'Test';
        listViewOneRecord.SA_Audit__List_View_JSON__c = '[{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__S_Audit__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""},{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__Test_Object__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""}]';
        listViewOneRecord.SA_Audit__Type__c = 'ListView';
        return listViewOneRecord;
    }
    static List<SA_Audit__OWD_Sharing_Report__c> getListViewRecords(){
        return [SELECT Id, Name, SA_Audit__OWD_Data_Field__c, SA_Audit__Managed_Package_License_Datails__c, SA_Audit__Sharing_Rules_Details__c, SA_Audit__Type__c, SA_Audit__List_View_JSON__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ListView'];
    }
    static Attachment createAttachmentRecord(){
        Blob excelData;
        Attachment attach = new Attachment();
        attach.Name = 'ListViewReports';
        attach.ContentType = 'text/plain';
        return attach;
    }
    @isTest
    static void fetchListViewRecordsTest(){
        Test.startTest();
        ListViewExcelController classObj = new ListViewExcelController();
        listViewList = getListViewRecords();
        System.assertEquals(size, listViewList.size());
        Test.stopTest();
    }
}