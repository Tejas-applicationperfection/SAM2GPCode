/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for ListViewBatchApex.apxc
Dependencies : ListViewBatchApex.apxc
*/
@isTest
public with sharing class ListViewBatchApexTest{
    private static List<SA_Audit__OWD_Sharing_Report__c> listViewList = new List<SA_Audit__OWD_Sharing_Report__c>();
    static final Integer size = 1;
    @testSetup
    static void setUpData(){
        SA_Audit__OWD_Sharing_Report__c listViewOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        listViewOneRecord = createListViewRecord();
        listViewList.add(listViewOneRecord);
        insert listViewList;
    }
    static SA_Audit__OWD_Sharing_Report__c createListViewRecord(){
        SA_Audit__OWD_Sharing_Report__c listViewOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        listViewOneRecord.Name = 'Test';
        listViewOneRecord.SA_Audit__Validation_Rules_JSON__c = '[{"validationRuleName":"CET_Count_Validator","nameSpacePrefix":"APXTConga4","label":"Conga Solution Email Template","errorMessage":"Only one Conga Email Template is allowed per Conga Solution To make changes either modify the existing record or delete it and add a new one","errorDisplayField":"Conga Email Template","description":"Only one CET is allowed per solution","criteria":"APXTConga4__Conga_Solution__r.APXTConga4__CongaEmailTemplateCount__c != 0","active":false}]';
        listViewOneRecord.SA_Audit__Type__c = 'ListView';
        listViewOneRecord.SA_Audit__List_View_JSON__c = '[{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__S_Audit__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""},{"viewUniqueName":"All","viewName":"All","sobjectType":"SA_Audit__Test_Object__c","selectedFields":"Name, ","filterByOwner":"All OWD Sharing Reports","additionalFilters":""}]';
        return listViewOneRecord;
    }
    public class WebCallOutClassFirst implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('GET', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"columns" : [ {"ascendingLabel" : "Z-A", "descendingLabel" : "A-Z", "fieldNameOrPath" : "Name", "hidden" : false, "label" : "Account Name", "searchable" : true, "selectListItem" : "Name", "sortDirection" : "ascending", "sortIndex" : 0, "sortable" : true, "type" : "string"}, {"ascendingLabel" : "Z-A", "descendingLabel" : "A-Z", "fieldNameOrPath" : "Site", "hidden" : false, "label" : "Account Site", "searchable" : true, "selectListItem" : "Site", "sortDirection" : null, "sortIndex" : null, "sortable" : true, "type" : "string"}], "id" : "00B0Y000002zSdT", "orderBy" : [ {"fieldNameOrPath" : "Name", "nullsPosition" : "first", "sortDirection" : "ascending"}],"query" : "SELECT Name, Site, BillingState, Phone, toLabel(Type), Owner.Alias, Id, RecordTypeId, CreatedDate, LastModifiedDate, SystemModstamp, Owner.Id, OwnerId FROM Account WHERE CreatedDate = THIS_WEEK ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST", "relatedEntityId" : null, "scope" : "everything", "scopeEntityId" : null, "sobjectType" : "Account", "whereCondition" : { "field" : "CreatedDate", "operator" : "equals", "values" : [ "THIS_WEEK" ]}}');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void test(){
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassFirst());
        Test.startTest();
        Database.executeBatch(new ListViewBatchApex(), 100);
        Test.stopTest();
    }
}