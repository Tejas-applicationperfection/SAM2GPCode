/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for ValidationRulesBatch.apxc
Dependencies : ValidationRulesBatch.apxc
*/
@isTest
public with sharing class ValidationRulesBatchTest{
    private static List<SA_Audit__OWD_Sharing_Report__c> validationRulesList = new List<SA_Audit__OWD_Sharing_Report__c>();
    static final Integer size = 1;
    @testSetup
    static void setUpData(){
        SA_Audit__OWD_Sharing_Report__c validationRulesOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        validationRulesOneRecord = createValidationRulesRecord();
        validationRulesList.add(validationRulesOneRecord);
        insert validationRulesList;
    }
    static SA_Audit__OWD_Sharing_Report__c createValidationRulesRecord(){
        SA_Audit__OWD_Sharing_Report__c validationRulesOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        validationRulesOneRecord.Name = 'Test';
        validationRulesOneRecord.SA_Audit__Validation_Rules_JSON__c = '[{"validationRuleName":"CET_Count_Validator","nameSpacePrefix":"APXTConga4","label":"Conga Solution Email Template","errorMessage":"Only one Conga Email Template is allowed per Conga Solution To make changes either modify the existing record or delete it and add a new one","errorDisplayField":"Conga Email Template","description":"Only one CET is allowed per solution","criteria":"APXTConga4__Conga_Solution__r.APXTConga4__CongaEmailTemplateCount__c != 0","active":false}]';
        validationRulesOneRecord.SA_Audit__Type__c = 'ValidationRules';
        return validationRulesOneRecord;
    }
    public class WebCallOutClassFirst implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('GET', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"size":129,"totalSize":129,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v47.0/tooling/sobjects/ValidationRule/03d1v0000002ujjAAA"},"Id":"03d1v0000002ujjAAA","EntityDefinition":{"attributes":{"type":"EntityDefinition","url":"/services/data/v47.0/tooling/sobjects/EntityDefinition/01I1v000002P335"},"QualifiedApiName":"APXTConga4__Conga_Solution_Email_Template__c"}}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class WebCallOutClassSecond implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('GET', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v50.0/tooling/sobjects/ValidationRule/03d1v0000002ujjAAA"},"Id":"03d1v0000002ujjAAA","Active":false,"Description":"Only one CET is allowed per solution","EntityDefinition":{"attributes":{"type":"EntityDefinition","url":"/services/data/v50.0/tooling/sobjects/EntityDefinition/01I1v000002P335"},"Label":"Conga Solution Email Template"},"ErrorDisplayField":"Conga Email Template","ErrorMessage":"Only one Conga Email Template is allowed per Conga Solution. To make changes, either modify the existing record or delete it and add a new one????4.","ValidationName":"CET_Count_Validator","NamespacePrefix":"APXTConga4","Metadata":{"description":"Only one CET is allowed per solution","errorConditionFormula":"APXTConga4__Conga_Solution__r.APXTConga4__CongaEmailTemplateCount__c != 0","errorDisplayField":"APXTConga4__Conga_Email_Template__c","errorMessage":"Only one Conga Email Template is allowed per Conga Solution. To make changes, either modify the existing record or delete it and add a new one.","shouldEvaluateOnClient":null,"urls":null,"active":false}}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void test(){
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassFirst());
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassSecond());
        Test.startTest();
        ValidationRulesBatch classObj = new ValidationRulesBatch();
        Database.executeBatch(classObj);
        Test.stopTest();
    }
}