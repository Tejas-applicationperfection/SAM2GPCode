/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for MultipleExcelGenerator.apxc
Dependencies : MultipleExcelGenerator.apxc
*/
@isTest
public with sharing class MultipleExcelGeneratorTest{
    private class RestMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void getLayoutDetailsTest(){
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        PageReference page = Page.multipleExcelGenerator;
        Test.setCurrentPage(page);
        ApexPages.currentPage().getParameters().put('recordId', 'Account, Case');
        MultipleExcelGenerator classObj = new MultipleExcelGenerator();
        System.assertNotEquals(null, page);
        Test.stopTest();
    }
}