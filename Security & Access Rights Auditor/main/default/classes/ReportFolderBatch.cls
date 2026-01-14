/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
global with sharing class ReportFolderBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful{
    @AuraEnabled
    global String repBody { get; set; }
    @AuraEnabled
    global String repType { get; set; }
    @AuraEnabled
    global SA_Audit__Helper__c helperRec { get; set; }
    @AuraEnabled
    global String sfdcURL { get; set; }
    global ReportFolderBatch(String repType){
        this.repType = repType;
        this.helperRec = new SA_Audit__Helper__c();
    }
    global ReportFolderBatch(String repType, String sfdcURL){
        this.repType = repType;
        this.helperRec = new SA_Audit__Helper__c();
        this.sfdcURL = sfdcURL;
    }
    global Database.QueryLocator start(Database.BatchableContext bc){
        repBody = '';
        return Database.getQueryLocator('SELECT Id, Name, Type FROM Folder WHERE Type = \'' + repType + '\' ORDER BY Name');
    }
    global void execute(Database.BatchableContext bc, List<Folder> records){
        for(Folder f : records){
            String res = getReportShareDetails(f.Id);
            Shares sharesResult = (Shares)JSON.deserialize(res, Shares.class);
            if(sharesResult.shares == null || sharesResult.shares.size() == 0){
                repBody += (f.Name == null ? '' : f.Name) + '~#~' + ' ' + '~#~' + ' ' + '~#~' + ' ' + '/n';
            }
            for(ReportShares repShares : sharesResult.shares){
                repBody += (f.Name == null ? '' : f.Name) + '~#~' + repShares.accessType + '~#~' + repShares.shareType + '~#~' + repShares.sharedWithLabel + '/n';
            }
            if(repBody.length() >= 32768){
                for(Integer i = 1; i <= 500; i++){
                    if(helperRec.get('SA_Audit__ResultBody_' + i + '__c') == null){
                        String repBody2 = repBody.left(32768);
                        Integer int1 = repBody2.lastIndexOf('/n');
                        helperRec.put('SA_Audit__ResultBody_' + i + '__c', repBody2.left(int1+2));
                        repBody = repBody.substring(int1 + 2);
                        break;                        
                    }
                }                
            }
        }
    }    
    global void finish(Database.BatchableContext bc){
         if (Schema.sObjectType.SA_Audit__Helper__c.fields.SA_Audit__JobId__c.isCreateable() && Schema.sObjectType.SA_Audit__Helper__c.fields.SA_Audit__JobId__c.isUpdateable()) {
         
        helperRec.SA_Audit__JobId__c = bc.getJobId();
        for(Integer i = 1; i <= 500; i++){
               if(helperRec.get('SA_Audit__ResultBody_' + i + '__c') == null){
                helperRec.put('SA_Audit__ResultBody_' + i + '__c', repBody);
                break;                        
            }
             }
        }  
        insert helperRec;
    }
    public String getReportShareDetails(Id reportFolderId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sfdcURL + '/services/data/v45.0/folders/' + reportFolderId + '/shares');
        req.setMethod('GET');
        //String sessionId = UserInfo.getSessionId();
        String sessionId =  'callout:SA_Audit__Tooling_API_Creds'; 
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
    public class Shares{
        @AuraEnabled
        public List<ReportShares> shares { get; set; }
    }
    public class ReportShares{
        @AuraEnabled
        public String accessType { get; set; }
        @AuraEnabled
        public String imageColor { get; set; }
        @AuraEnabled
        public String imageUrl { get; set; }
        @AuraEnabled
        public String shareId { get; set; }
        @AuraEnabled
        public String shareType { get; set; }
        @AuraEnabled
        public String sharedWithId { get; set; }
        @AuraEnabled
        public String sharedWithLabel { get; set; }
        @AuraEnabled
        public String url { get; set; }
    }
}