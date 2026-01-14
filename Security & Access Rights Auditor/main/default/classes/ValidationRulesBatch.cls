/*
Author       : Himanshu Kr. Varshney
Description  : Batch Apex for Intel tab, Option 20
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class ValidationRulesBatch implements Database.Batchable<String>, Database.AllowsCallouts, Database.Stateful{
    @AuraEnabled
    public List<String> objectNameList;
    @AuraEnabled
    public List<FinalClass> finalDataList { get; set; }
    public ValidationRulesBatch(){
        this.finalDataList = new List<FinalClass>();
    }
    public Iterable<String> start(Database.BatchableContext BC){
        objectNameList = new List<String>();
        Set<String> objectNames = new Set<String>();
        String toolingAPIURL = '/services/data/v50.0/tooling/query/?q=SELECT+Id,EntityDefinition.QualifiedApiName+FROM+ValidationRule';
        String response = getObjectDetails(toolingAPIURL);
        ObjectDetails objectDetailsList = (ObjectDetails)JSON.deserialize(response, ObjectDetails.class);
        for(Attribute oneRecord: objectDetailsList.records){
            objectNameList.add(oneRecord.id);
        }
        //objectNameList = new List<String>(objectNames);
        return objectNameList;
    }
    public void execute(Database.BatchableContext BC, List<String> scope){
        for(String s : scope){
            String toolingAPIURL = '/services/data/v50.0/tooling/query?q=Select+Id,Active,Description,EntityDefinition.Label,ErrorDisplayField,ErrorMessage,ValidationName,NamespacePrefix,Metadata+From+ValidationRule+WHERE+Id=\'' + s + '\'';
            String response = getObjectDetails(toolingAPIURL);
            System.debug('response>>>>' + response);
            ValidationRulesDetails objectDetailsList = (ValidationRulesDetails)JSON.deserialize(response, ValidationRulesDetails.class);
            System.debug('ValidationRulesDetails>>>>' + objectDetailsList);
            for(Attribute3 onRecord: objectDetailsList.records){
                finalDataList.add(new FinalClass(onRecord));
                //finalDataList.add(finalDataOneRecord);
            }
        }
    }
    public void finish(Database.BatchableContext BC){
        SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        List<SA_Audit__OWD_Sharing_Report__c> owdSharingReportList = [SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ValidationRules' LIMIT 100];
        if(owdSharingReporTList.size() > 0 && SA_Audit__OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
            delete owdSharingReportList;
        }
        if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable()){
            owdObjRecord.SA_Audit__Type__c = 'ValidationRules';
            insert owdObjRecord;
        }
        Blob excelData;
       if(Schema.sObjectType.Attachment.fields.Body.isCreateable() && Schema.sObjectType.Attachment.fields.parentId.isCreateable() && Schema.sObjectType.Attachment.fields.ContentType.isCreateable() && Schema.sObjectType.Attachment.fields.Name.isCreateable()){

        Attachment attach = new Attachment();
        attach.Name = 'ValidationRulesReport';
        attach.ContentType = 'text/plain';
        attach.parentId = owdObjRecord.Id;
        attach.Body = Blob.valueOf(JSON.serialize(finalDataList));
        system.debug('body json--'+attach.Body);
            insert attach;}
    }
    public static String getObjectDetails(String toolingAPIURL){
        HttpRequest req = new HttpRequest();
        String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        req.setEndpoint(sfdcURL + toolingAPIURL);
        req.setMethod('GET');
        String sessionId = UserInfo.getSessionId();
       // String sessionId = 'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
    public class ObjectDetails{
        @AuraEnabled
        public List<Attribute> records { get; set; }
    }
    public class Attribute{
        @AuraEnabled
        public Attribute2 EntityDefinition { get; set; }
        @AuraEnabled
        public String id { get; set; }
    }
    public class Attribute2{
        @AuraEnabled
        public String qualifiedApiName { get; set; }
    }
    public class ValidationRulesDetails{
        @AuraEnabled
        public List<Attribute3> records { get; set; }
    }
    public class Attribute3{
        @AuraEnabled
        public String nameSpacePrefix { get; set; }
        @AuraEnabled
        public Boolean active { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String errorDisplayField { get; set; }
        @AuraEnabled
        public String errorMessage { get; set; }
        @AuraEnabled
        public String validationName { get; set; }
        @AuraEnabled
        public Attribute4 EntityDefinition { get; set; }
        @AuraEnabled
        public Attribute5 Metadata { get; set; }
    }
    public class Attribute4{
        @AuraEnabled
        public String label { get; set; }
    }
    public class Attribute5{
        @AuraEnabled
        public String errorConditionFormula { get; set; }
    }
    public class FinalClass{
        @AuraEnabled
        public String validationRuleName { get; set; }
        @AuraEnabled
        public String nameSpacePrefix { get; set; }
        @AuraEnabled
        public Boolean active { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String errorDisplayField { get; set; }
        @AuraEnabled
        public String errorMessage { get; set; }
        @AuraEnabled
        public String label { get; set; }
        @AuraEnabled
        public String criteria { get; set; }
        public FinalClass(Attribute3 onRecord){
            this.active = onRecord.active;
            this.validationRuleName = onRecord.validationName;
            this.nameSpacePrefix = onRecord.nameSpacePrefix;
            this.description = String.isNotEmpty(onRecord.description) ? onRecord.description.replaceAll('[^a-zA-Z0-9\\s+]', '') : '';//
            this.errorDisplayField = onRecord.errorDisplayField;
            this.errorMessage = onRecord.errorMessage.replaceAll('[^a-zA-Z0-9\\s+]', '');
            this.label = onRecord.EntityDefinition.label;
            this.criteria = onRecord.Metadata.errorConditionFormula;
        }
    }
}