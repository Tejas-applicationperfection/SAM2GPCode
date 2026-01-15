/*
Author       : Himanshu Kr. Varshney
Description  : Apex Test Class for ManagedPackageLicenseFutureController.apxc
Dependencies : ManagedPackageLicenseFutureController.apxc
*/
@isTest
public class ManagedPackageFutureControllerTest{
    private static List<SA_Audit__OWD_Sharing_Report__c> managedPackageLicensesList = new List<SA_Audit__OWD_Sharing_Report__c>();
    private static List<User> userList = new List<User>();
    static final Integer size = 1;
    @testSetup
    static void setUpData(){
        SA_Audit__OWD_Sharing_Report__c managedPackageLicenseOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        managedPackageLicenseOneRecord = createManagedPackageLicenseRecord();
        managedPackageLicensesList.add(managedPackageLicenseOneRecord);
        insert managedPackageLicensesList;
        insertUser();
    }
    @future
    static void insertUser(){
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User userRecord = new User();
        userRecord.firstName = 'Test First Name';
        userRecord.lastName = 'Test Last Name';
        userRecord.profileId = profileRecord.Id;
        userRecord.username = 'testshskep45425567@abc.com';
        userRecord.email = 'test@abc.com';
        userRecord.Alias = 'fakeuser'; 
        userRecord.EmailEncodingKey = 'UTF-8'; 
        userRecord.LanguageLocaleKey = 'en_US'; 
        userRecord.LocaleSidKey = 'en_US'; 
        userRecord.TimeZoneSidKey = 'America/New_York'; 
        userList.add(userRecord);
        insert userList;
        PackageLicense pl = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = 'sf_com_apps'];
        User u = [SELECT Id FROM User WHERE firstName = 'Test First Name'];
        insert new UserPackageLicense(UserId = u.Id, PackageLicenseId = pl.Id);
    }
    static SA_Audit__OWD_Sharing_Report__c createManagedPackageLicenseRecord(){
        SA_Audit__OWD_Sharing_Report__c managedPackageLicenseOneRecord = new SA_Audit__OWD_Sharing_Report__c();
        managedPackageLicenseOneRecord.Name = 'Test';
        managedPackageLicenseOneRecord.SA_Audit__Managed_Package_License_Datails__c = '[{"userName":"james@applicationperfection.co.uk.development","role":"CEO","profile":"System Administrator","packageName":"Conga Composer","name":"James Burgess","activeBoolean":true}]';
        managedPackageLicenseOneRecord.SA_Audit__Type__c = 'ManagedPackaged';
        return managedPackageLicenseOneRecord;
    }
    public class WebCallOutClassFirst implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            System.assertEquals('GET', req.getMethod());
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"size":5,"totalSize":5,"done":true,"queryLocator":null,"entityTypeName":"InstalledSubscriberPackage","records":[{"attributes":{"type":"InstalledSubscriberPackage","url":"/services/data/v47.0/tooling/sobjects/InstalledSubscriberPackage/0A31v000000MmCBCA0"},"Id":"0A31v000000MmCBCA0","SubscriberPackage":{"attributes":{"type":"SubscriberPackage","url":"/services/data/v47.0/tooling/sobjects/SubscriberPackage/03330000000wDAbAAM"},"NamespacePrefix":"sf_com_apps","Name":"Salesforce Connected Apps"}}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void test(){
        Test.setMock(HttpCalloutMock.class, new WebCallOutClassFirst());
        Test.startTest();
        //ManagedPackageLicenseFutureController classObj = new ManagedPackageLicenseFutureController();
        ManagedPackageLicenseFutureController.getManagedPackageDetails();
        Test.stopTest();
    }
}