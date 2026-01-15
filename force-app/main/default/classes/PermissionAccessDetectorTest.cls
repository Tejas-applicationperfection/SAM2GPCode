/**
 * Test class for PermissionAccessDetector
 */
@IsTest
private class PermissionAccessDetectorTest {
    
    @TestSetup
    static void setup() {
        Profile p = [SELECT Id, Name FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testpermdet@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'PermDetector',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testpermdetector' + DateTime.now().getTime() + '@test.com',
            IsActive = true
        );
        insert testUser;
    }
    
    @IsTest
    static void testDetectAccess_Profile() {
        Profile p = [SELECT Name FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        Test.startTest();
        
        PermissionAccessDetector.AccessRequest req = new PermissionAccessDetector.AccessRequest();
        req.principalType = 'Profile';
        req.principalName = p.Name;
        req.resourceType = 'Object';
        req.resourceName = 'Account';
        
        List<PermissionAccessDetector.AccessResult> results = 
            PermissionAccessDetector.detectAccess(new List<PermissionAccessDetector.AccessRequest>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0].explanation, 'Explanation should not be null');
    }
    
    @IsTest
    static void testDetectAccess_User() {
        User testUser = [SELECT Name FROM User WHERE LastName='PermDetector' LIMIT 1];
        
        Test.startTest();
        
        PermissionAccessDetector.AccessRequest req = new PermissionAccessDetector.AccessRequest();
        req.principalType = 'User';
        req.principalName = testUser.Name;
        req.resourceType = 'Object';
        req.resourceName = 'Account';
        
        List<PermissionAccessDetector.AccessResult> results = 
            PermissionAccessDetector.detectAccess(new List<PermissionAccessDetector.AccessRequest>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertNotEquals(null, results[0].conversationalSummary, 'Summary should not be null');
    }
    
    @IsTest
    static void testDetectAccess_InvalidInput() {
        Test.startTest();
        
        PermissionAccessDetector.AccessRequest req = new PermissionAccessDetector.AccessRequest();
        req.principalType = null;
        req.principalName = null;
        req.resourceName = null;
        
        List<PermissionAccessDetector.AccessResult> results = 
            PermissionAccessDetector.detectAccess(new List<PermissionAccessDetector.AccessRequest>{ req });
        
        Test.stopTest();
        
        System.assertEquals('Invalid Input', results[0].accessSource, 'Should detect invalid input');
    }
    
    @IsTest
    static void testDetectAccess_UnsupportedResource() {
        Test.startTest();
        
        PermissionAccessDetector.AccessRequest req = new PermissionAccessDetector.AccessRequest();
        req.principalType = 'Profile';
        req.principalName = 'Test';
        req.resourceType = 'Field';
        req.resourceName = 'Account.Name';
        
        List<PermissionAccessDetector.AccessResult> results = 
            PermissionAccessDetector.detectAccess(new List<PermissionAccessDetector.AccessRequest>{ req });
        
        Test.stopTest();
        
        System.assertEquals('Unsupported', results[0].accessSource, 'Should detect unsupported resource');
    }
    
    @IsTest
    static void testAnalyzeProfile() {
        Profile p = [SELECT Name FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        Test.startTest();
        
        PermissionAccessDetector.AccessRequest req = new PermissionAccessDetector.AccessRequest();
        req.principalName = p.Name;
        req.resourceName = 'Account';
        
        PermissionAccessDetector.AccessResult res = new PermissionAccessDetector.AccessResult();
        PermissionAccessDetector.analyzeProfile(req, res);
        
        Test.stopTest();
        
        System.assertNotEquals(null, res.accessSource, 'Access source should not be null');
        System.assertNotEquals(null, res.severity, 'Severity should not be null');
    }
    
    @IsTest
    static void testAnalyzeUser() {
        User testUser = [SELECT Name FROM User WHERE LastName='PermDetector' LIMIT 1];
        
        Test.startTest();
        
        PermissionAccessDetector.AccessRequest req = new PermissionAccessDetector.AccessRequest();
        req.principalName = testUser.Name;
        req.resourceName = 'Account';
        
        PermissionAccessDetector.AccessResult res = new PermissionAccessDetector.AccessResult();
        PermissionAccessDetector.analyzeUser(req, res);
        
        Test.stopTest();
        
        System.assertNotEquals(null, res.nextSteps, 'Next steps should not be null');
    }
}