/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for ValidationRulesExcelController.apxc
Dependencies : ValidationRulesExcelController.apxc
*/
@isTest
public with sharing class ValidationRulesExcelControllerTest{
    private static List<SA_Audit__OWD_Sharing_Report__c> validationRulesList = new List<SA_Audit__OWD_Sharing_Report__c>();
    static final Integer size = 1;
    @testSetup
    static void setUpData(){
        SA_Audit__OWD_Sharing_Report__c validationRulesOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        validationRulesOneRecord = createValidationRulesRecord();
        validationRulesList.add(validationRulesOneRecord);
        insert validationRulesList;
        Attachment  attach = createAttachmentRecord();
        attach.parentId = validationRulesList[0].Id;
        attach.Body = Blob.valueOf('[{"validationRuleName":"CET_Count_Validator","nameSpacePrefix":"APXTConga4","label":"Conga Solution Email Template","errorMessage":"Only one Conga Email Template is allowed per Conga Solution To make changes either modify the existing record or delete it and add a new one","errorDisplayField":"Conga Email Template","description":"Only one CET is allowed per solution","criteria":"APXTConga4__Conga_Solution__r.APXTConga4__CongaEmailTemplateCount__c != 0","active":false}]');
        insert attach;
    }
    static SA_Audit__OWD_Sharing_Report__c createValidationRulesRecord(){
        SA_Audit__OWD_Sharing_Report__c validationRulesOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        validationRulesOneRecord.Name = 'Test';
        validationRulesOneRecord.SA_Audit__Validation_Rules_JSON__c = '[{"validationRuleName":"CET_Count_Validator","nameSpacePrefix":"APXTConga4","label":"Conga Solution Email Template","errorMessage":"Only one Conga Email Template is allowed per Conga Solution To make changes either modify the existing record or delete it and add a new one","errorDisplayField":"Conga Email Template","description":"Only one CET is allowed per solution","criteria":"APXTConga4__Conga_Solution__r.APXTConga4__CongaEmailTemplateCount__c != 0","active":false}]';
        validationRulesOneRecord.SA_Audit__Type__c = 'ValidationRules';
        return validationRulesOneRecord;
    }
    static Attachment createAttachmentRecord(){
        Blob excelData;
        Attachment attach = new Attachment();
        attach.Name = 'ValidationRulesReport';
        attach.ContentType = 'text/plain';
        return attach;
    }
    static List<SA_Audit__OWD_Sharing_Report__c> getValidationRulesRecords(){
        return [SELECT Id, Name, SA_Audit__OWD_Data_Field__c, SA_Audit__Managed_Package_License_Datails__c, SA_Audit__Sharing_Rules_Details__c, SA_Audit__Type__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ValidationRules'];
    }
    @isTest
    static void fetchValidationRulesRecordsTest(){
        Test.startTest();
        ValidationRulesExcelController classObj = new ValidationRulesExcelController();
        validationRulesList = getValidationRulesRecords();
        System.assertEquals(size, validationRulesList.size());
        Test.stopTest();
    }
}