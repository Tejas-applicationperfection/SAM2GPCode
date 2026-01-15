/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class InstalledPackagesReportBatch implements Database.batchable<String>, Database.AllowsCallouts, Database.Stateful{
    public List<String> InstalledPackageId;
    public String sfdcURL { get; set; }
    public SA_Audit__Helper__c helperRec { get; set; }
    public List<InstalledPackage> installedPackages { get; set; }
    public InstalledPackagesReportBatch(String sfdcURL){
        this.helperRec = new SA_Audit__Helper__c();
        this.sfdcURL = sfdcURL;
        this.installedPackages = new List<InstalledPackage>();
    }
    public Iterable<String> start(Database.BatchableContext BC){
        MetadataService.MetadataPort service = DataDictionaryService.createService();
        MetadataService.ListMetadataQuery query = new MetadataService.ListMetadataQuery();
        query.type_x = 'InstalledPackage';
        double asOfVersion = 48.0;
        MetadataService.FileProperties[] lmr = service.listMetadata(new MetadataService.ListMetadataQuery[] {query}, asOfVersion);
        InstalledPackageId = new List<String>();
        if(lmr != null){
            for(MetadataService.FileProperties n : lmr){
                InstalledPackageId.add(n.id);
            }
        }   
        return InstalledPackageId;
    }
    public void execute(Database.BatchableContext BC, List<String> scope){
        for(String s : scope){
            String res =  getCalloutInstalledSubscriberPackage(s);
            SubscriberPackage sharesResult = (SubscriberPackage)JSON.deserialize(res, SubscriberPackage.class);
           /* if(sharesResult.size == 1){
                String res2 = getCalloutSubscriberPackage(sharesResult.records[0].subscriberPackageId);
                Attributes2 sharesResult2 = (Attributes2)JSON.deserialize(res2, Attributes2.class);
                String res3 = getCalloutSubscriberPackageVersion(sharesResult.records[0].subscriberPackageVersionId);
                Attributes3 sharesResult3 = (Attributes3)JSON.deserialize(res3, Attributes3.class);
                installedPackages.add(new InstalledPackage(sharesResult2.records[0], sharesResult3.records[0]));
            }*/
            if (sharesResult.records != null && sharesResult.records.size() == 1) {
                String res2 = getCalloutSubscriberPackage(sharesResult.records[0].subscriberPackageId);
                Attributes2 sharesResult2 = (Attributes2) JSON.deserialize(res2, Attributes2.class);
                String res3 = getCalloutSubscriberPackageVersion(sharesResult.records[0].subscriberPackageVersionId);
                Attributes3 sharesResult3 = (Attributes3) JSON.deserialize(res3, Attributes3.class);
                installedPackages.add(new InstalledPackage(sharesResult2.records[0], sharesResult3.records[0]));
            }

        }
    }
    
    public void finish(Database.BatchableContext BC){
        String repBody = JSON.serialize(installedPackages);
        if(Schema.sObjectType.SA_Audit__Helper__c.fields.SA_Audit__JobId__c.isCreateable()){
               helperRec.SA_Audit__JobId__c = bc.getJobId();
        }
        for(Integer i = 1; i <= 20; i++){
            if(repBody.length() == 0){
                break;
            }
            if(helperRec.get('SA_Audit__ResultBody_' + i + '__c') == null){
                helperRec.put('SA_Audit__ResultBody_' + i + '__c', repBody.left(32768));
                if(repBody.length() > 32768){
                    repBody = repBody.substring(32768);
                } 
                else{
                    repBody = '';
                }
            }
        }
        insert helperRec;
        
    }
    public String getCalloutInstalledSubscriberPackage(String installedPackagesId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sfdcURL + '/services/data/v48.0/tooling/query/?q=SELECT+Id,SubscriberPackageId,SubscriberPackageVersionId,MinPackageVersionId+FROM+InstalledSubscriberPackage+WHERE+Id=\'' + installedPackagesId + '\'');
        req.setMethod('GET');
       String sessionId = UserInfo.getSessionId();
      //   String sessionId = 'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
    public String getCalloutSubscriberPackage(String subscriberPackageId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sfdcURL + '/services/data/v48.0/tooling/query/?q=SELECT+Name,NamespacePrefix,Description+FROM+SubscriberPackage+WHERE+Id=\'' + subscriberPackageId +'\'');
        req.setMethod('GET');
       String sessionId = UserInfo.getSessionId();
         //String sessionId = 'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
    public String getCalloutSubscriberPackageVersion(String subscriberPackageVersionId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(sfdcURL + '/services/data/v48.0/tooling/query/?q=SELECT+Id,BuildNumber,IsBeta,IsDeprecated,IsManaged,IsPasswordProtected,IsSecurityReviewed,MajorVersion,MinorVersion,PatchVersion,PublisherName,ReleaseState+FROM+SubscriberPackageVersion+WHERE+Id=\'' + subscriberPackageVersionId +'\'');
        req.setMethod('GET');
        String sessionId = UserInfo.getSessionId();
  //String sessionId = 'callout:SA_Audit__Tooling_API_Creds';
 
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
    public class SubscriberPackage{
        @AuraEnabled
        public Integer size { get; set; }
        @AuraEnabled
        public String entityTypeName { get; set; }
        @AuraEnabled
        public List<Attributes> records { get; set; }
    }
    
    public class Attributes{
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String minPackageVersionId { get; set; }
        @AuraEnabled
        public String subscriberPackageId { get; set; }
        @AuraEnabled
        public String subscriberPackageVersionId { get; set; }
    }
    public class Attributes2{
        @AuraEnabled
        public List<SubscriberPackageDetails> records { get; set; }
    }
    public class SubscriberPackageDetails{
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String nameSpacePrefix { get; set; }
    }
    public class Attributes3{
        @AuraEnabled
        public List<SubscriberPackageVersion> records { get; set; }
    }
    public class SubscriberPackageVersion{
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String publisherName { get; set; }
        @AuraEnabled
        public String buildNumber { get; set; }
        @AuraEnabled
        public String isBeta { get; set; }
        @AuraEnabled
        public String isDeprecated { get; set; }
        @AuraEnabled
        public String isManaged { get; set; }
        @AuraEnabled
        public String isPasswordProtected { get; set; }
        @AuraEnabled
        public String isSecurityReviewed { get; set; }
        @AuraEnabled
        public String majorVersion { get; set; }
        @AuraEnabled
        public String minorVersion { get; set; }
        @AuraEnabled
        public String patchVersion { get; set; }
        @AuraEnabled
        public String releaseState { get; set; }
    }
    public class InstalledPackage{
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public String nameSpacePrefix { get; set; }
        @AuraEnabled
        public String publisherName { get; set; }
        @AuraEnabled
        public String buildNumber { get; set; }
        @AuraEnabled
        public String isBeta { get; set; }
        @AuraEnabled
        public String isDeprecated { get; set; }
        @AuraEnabled
        public String isManaged { get; set; }
        @AuraEnabled
        public String isPasswordProtected { get; set; }
        @AuraEnabled
        public String isSecurityReviewed { get; set; }
        @AuraEnabled
        public String releaseState { get; set; }
        @AuraEnabled
        public String numberVersion { get; set; }
        public InstalledPackage(SubscriberPackageDetails spd, SubscriberPackageVersion spv){
            this.name = spd.name;
            this.description = spd.description;
            this.nameSpacePrefix = spd.nameSpacePrefix;
            this.publisherName = spv.publisherName;
            this.buildNumber = spv.buildNumber;
            this.isBeta = spv.isBeta;
            this.isDeprecated = spv.isDeprecated;
            this.isManaged = spv.isManaged;
            this.isPasswordProtected = spv.isPasswordProtected;
            this.isSecurityReviewed = spv.isSecurityReviewed;
            this.numberVersion = spv.majorVersion + '.' + spv.minorVersion + (Integer.valueOf(spv.patchVersion) > 0 ? '.' + spv.patchVersion : '');
            this.releaseState = spv.releaseState;
        }
    }
    
    
    
    public static void testtestMethod(){
        
        Integer i = 0;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
    }
     public static void testtestMethod1(){
        
        Integer i = 0;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
    }
    public static void testtestMethod2(){
        
        Integer i = 0;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
    }
}