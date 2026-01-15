/*
Author       : Himanshu Kr. Varshney
Description  : Future method for Intel tab, Option 19
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class ManagedPackageLicenseFutureController{
    @AuraEnabled
    public static String getInstalledSubscriberPackageDetails(){
        // String sfdcURL = System.URL.getOrgDomainUrl().toExternalForm();
        String urlInstance = String.valueof(System.URL.getOrgDomainUrl()).replace('Url:[delegate=','').replace(']','');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(urlInstance + '/services/data/v59.0/tooling/query/?q=SELECT+Id,SubscriberPackage.NamespacePrefix,SubscriberPackage.Name+FROM+InstalledSubscriberPackage');
        req.setMethod('GET');
        String sessionId = UserInfo.getSessionId();
           // String sessionId = 'callout:SA_Audit__Tooling_API_Creds';
        String authorizationHeader = 'OAuth ' + sessionId;
        req.setHeader('Authorization', authorizationHeader);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        system.debug('res='+res.getBody());
        return res.getBody();
    }
    /*
Author  : Himanshu Kr. Varshney
Purpose : Below Method will Give Us Data related to Managed Packaged Licenses with User Assigned
*/
    
    public static void getManagedPackageDetails(){
        Map<String, String> nameSpaceMap = new Map<String, String>();
        List<User> finalUserList = new List<User>();
        SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        String response = getInstalledSubscriberPackageDetails();
        system.debug('response='+response);
        system.debug('response='+response);
        List<ManagedPackageDetailsClass> managedPackageDetailsClassList = new List<ManagedPackageDetailsClass>();
        //List<SA_Audit__OWD_Sharing_Report__c> owdSharingReportList = [SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'ManagedPackaged' LIMIT 100];
       // if(owdSharingReporTList.size() > 0 && SA_Audit__OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
       //     delete owdSharingReportList;
//        }
        //List<InstalledSubscriberPackageClass> installedSubscriberPackageList = new List<InstalledSubscriberPackageClass>();
        InstalledSubscriberPackageClass installedSubscriberPackageList = (InstalledSubscriberPackageClass)System.JSON.deserialize(response, InstalledSubscriberPackageClass.class);
        for(Attribute attributeOneRecord : installedSubscriberPackageList.records){
            nameSpaceMap.put(attributeOneRecord.SubscriberPackage.nameSpacePrefix, attributeOneRecord.SubscriberPackage.name);
            system.debug('nameSpaceMap=='+nameSpaceMap);
        }
        for(String str: nameSpaceMap.KeySet()){
            system.debug('entry');
            system.debug('str==='+str);
            List<User> userList = [SELECT Id, Name, Username, UserRole.Name, isActive, Profile.Name, LastLoginDate FROM User WHERE Id IN (SELECT UserId FROM UserPackageLicense WHERE PackageLicense.NamespacePrefix =: str)];
            system.debug('userList=='+userList);
            for(User userDataOneRecord: userList){
                ManagedPackageDetailsClass managedPackageDetailsClassOnRecord = new ManagedPackageDetailsClass();
                managedPackageDetailsClassOnRecord.packageName = nameSpaceMap.get(str);
                managedPackageDetailsClassOnRecord.name = userDataOneRecord.Name;
                managedPackageDetailsClassOnRecord.userName = userDataOneRecord.Username;
                managedPackageDetailsClassOnRecord.role = userDataOneRecord.UserRole.Name;
                managedPackageDetailsClassOnRecord.activeBoolean = userDataOneRecord.isActive;
                managedPackageDetailsClassOnRecord.profile = userDataOneRecord.Profile.Name;
                managedPackageDetailsClassOnRecord.lastLoginDate = userDataOneRecord.LastLoginDate;
                managedPackageDetailsClassList.add(managedPackageDetailsClassOnRecord);
                system.debug('managedPackageDetailsClassList==='+managedPackageDetailsClassList);
            }
        }
        
        if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Managed_Package_License_Datails__c.isCreateable() && 
           Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable()) {
               try {
                   // Serialize the data into JSON format
                   String serializedData = JSON.serialize(managedPackageDetailsClassList);
                     System.debug('serializedData : ' + serializedData);
                   Integer maxLength1 = 131072; // Max length for the first field
                   
                   System.debug('Serialized Data Length: ' + serializedData.length());
                   if(serializedData.length() <= maxLength1){
                      owdObjRecord.SA_Audit__Managed_Package_License_Datails__c = JSON.serialize(managedPackageDetailsClassList);
                       
                       owdObjRecord.SA_Audit__Type__c = 'ManagedPackaged';
                       
                       insert owdObjRecord; 
                       System.debug('Record inserted successfully with data.');
                   }
                   else if (serializedData.length() >= maxLength1) {
                       owdObjRecord.SA_Audit__Managed_Package_License_Datails__c = serializedData.substring(0, Math.min(serializedData.length(), maxLength1));
                       
                       owdObjRecord.SA_Audit__Type__c = 'ManagedPackaged';
                       
                       insert owdObjRecord; 
                       System.debug('Record inserted successfully with data within the allowed limit.');
                   } else {
                       System.debug('Data exceeds the maximum allowed length of ' + maxLength1 + ' characters and was not inserted.');
                   }
               } catch (Exception e) {
                   System.debug('Exception: ' + e.getMessage());
               }
               }  
    }
    
          
             
    public class InstalledSubscriberPackageClass{
        /*@AuraEnabled
public String installedSubscriberPackageId {get; set;}
@AuraEnabled
public String name {get; set;}
@AuraEnabled
public String nameSpacePrefix {get; set;}*/
        @AuraEnabled
        public List<Attribute> records {get; set;}        
    }
    public class Attribute{
        @AuraEnabled
        public String Id {get; set;}
        @AuraEnabled
        public Attribute2 SubscriberPackage {get; set;}
    }
    public class Attribute2{
        @AuraEnabled
        public String name {get; set;}
        @AuraEnabled
        public String nameSpacePrefix {get; set;}
    }
    public class ManagedPackageDetailsClass{
        @AuraEnabled
        public String packageName {get; set;}
        @AuraEnabled
        public String name {get; set;} 
        @AuraEnabled
        public String userName {get; set;}
        @AuraEnabled
        public String role {get; set;}
        @AuraEnabled
        public Boolean activeBoolean {get; set;}
        @AuraEnabled
        public String profile {get; set;}
        @AuraEnabled
        public DateTime lastLoginDate {get; set;}
    }
}