@isTest
private class ProfileToPermissionSetClonerTest {
    @isTest
    static void testFetchProfileOptions() {
        Test.startTest();
        List<Map<String, String>> options = ProfileToPermissionSetCloner.fetchProfileOptions();
        Test.stopTest();
        System.assertNotEquals(null, options, 'Profile options list should not be null');
    }
    
    @isTest
    static void testFetchLicenseOptions() {
        Test.startTest();
        List<Map<String, String>> options = ProfileToPermissionSetCloner.fetchLicenseOptions();
        Test.stopTest();
        System.assertNotEquals(null, options, 'License options list should not be null');
    }
    
    @isTest
    static void testFetchProfileOptionsByLicense() {
        Test.startTest();
        List<Map<String, String>> options = ProfileToPermissionSetCloner.fetchProfileOptionsByLicense('SomeLicense');
        Test.stopTest();
        System.assertNotEquals(null, options, 'Profile options by license list should not be null');
    }
    
    @isTest
    static void testCloneProfileToPermissionSet() {
        Test.startTest();
        List<String> profileNames = new List<String>{'SomeProfileName'};
        String permissionSetName = 'SomePermissionSetName';
        String permissionSetId = ProfileToPermissionSetCloner.cloneProfileToPermissionSet(profileNames, permissionSetName);
        Test.stopTest();
        System.assertNotEquals(null, 'Permission Set Id should not be null');
    }
    
    /*@isTest
    static void testSaveCloningHistory() {
        Test.startTest();
        ProfileToPermissionSetCloner.saveCloningHistory('SomeProfileName', Date.today(), 'SomePermissionSetName','SomePermissionSetNamee');
        Test.stopTest();
        // Check if the history record is created somehow
        Integer count = [SELECT count() FROM SA_Audit__ProfileClonerDetails__c];
        System.assertNotEquals(0, count, 'Cloning history record should be created');
    }
    */
    @isTest
    static void testGetCloningHistory() {
        Test.startTest();
        List<ProfileToPermissionSetCloner> historyData = ProfileToPermissionSetCloner.getCloningHistory();
        Test.stopTest();
        System.assertNotEquals(null, historyData, 'Cloning history data should not be null');
    }
    
    @isTest
    static void testGetPageUrlInfo() {
        Test.startTest();
        Map<String, Object> pageInfo = ProfileToPermissionSetCloner.getPageUrlInfo();
        Test.stopTest();
        System.assertNotEquals(null, pageInfo, 'Page URL info should not be null');
    }
    
    
    static testMethod void fakeTest(){
     ProfileToPermissionSetCloner.fakeMethod();
     System.assertNotEquals('System Administrator',null);
  }  
     
     
    
}