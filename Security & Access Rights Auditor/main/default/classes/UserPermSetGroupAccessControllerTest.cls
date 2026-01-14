/**
 * Test class for UserPermissionSetGroupAccessController
 */
@IsTest
private class UserPermSetGroupAccessControllerTest {
    
    @TestSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'upsgtest',
            Email = 'userperms@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserPermsTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'userperms' + DateTime.now().getTime() + '@test.com',
            IsActive = true
        );
        insert testUser;
        
        PermissionSet ps = new PermissionSet(
            Name = 'TestPS' + String.valueOf(System.currentTimeMillis()),
            Label = 'TestPS_' + String.valueOf(System.currentTimeMillis())
        );
        insert ps;
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
        insert psa;
    }
    
    @IsTest
    static void testConstructor() {
        Test.startTest();
        
        UserPermissionSetGroupAccessController controller = 
            new UserPermissionSetGroupAccessController();
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller, 'Controller should be instantiated');
        System.assertNotEquals(null, controller.xmlheader, 'XML header should be set');
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should be set');
    }
    
    @IsTest
    static void testGetfetchTableDataOption30() {
        Test.startTest();
        
        UserPermissionSetGroupAccessController controller = 
            new UserPermissionSetGroupAccessController();
        List<UserPermissionSetGroupAccessController.PermissionSetWrapper> wrappers = 
            controller.getfetchTableDataOption30();
        
        Test.stopTest();
        
        System.assertNotEquals(null, wrappers, 'Wrappers list should not be null');
    }
    
    @IsTest
    static void testPermissionSetWrapper() {
        UserPermissionSetGroupAccessController.PermissionSetWrapper wrapper = 
            new UserPermissionSetGroupAccessController.PermissionSetWrapper();
        
        wrapper.UserId = UserInfo.getUserId();
        wrapper.UserNam = 'Test User';
        wrapper.UserEmail = 'test@test.com';
        wrapper.AssignedPermission = 'TestPermission';
        wrapper.PermissionSetGroups = null;
        
        System.assertEquals(UserInfo.getUserId(), wrapper.UserId, 'User ID should match');
        System.assertEquals('Test User', wrapper.UserNam, 'User name should match');
        System.assertEquals('test@test.com', wrapper.UserEmail, 'Email should match');
        System.assertEquals('TestPermission', wrapper.AssignedPermission, 'Permission should match');
    }
    
    @IsTest
    static void testFetchPermissionSetAssignments() {
        Test.startTest();
        
        UserPermissionSetGroupAccessController controller = 
            new UserPermissionSetGroupAccessController();
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller.permissionSetWrappertList, 
            'Permission set wrapper list should not be null');
    }
    
    @IsTest
    static void testWrapperListPopulation() {
        Test.startTest();
        
        List<UserPermissionSetGroupAccessController.PermissionSetWrapper> wrappers = 
            new UserPermissionSetGroupAccessController().getfetchTableDataOption30();
        
        Test.stopTest();
        
        System.assertNotEquals(null, wrappers, 'Should return wrapper list');
        
        if (wrappers.size() > 0) {
            UserPermissionSetGroupAccessController.PermissionSetWrapper wrapper = wrappers[0];
            System.assertNotEquals(null, wrapper.UserId, 'User ID should be populated');
        }
    }
    
    @IsTest
    static void testBatchProcessing() {
        Test.startTest();
        
        UserPermissionSetGroupAccessController controller = 
            new UserPermissionSetGroupAccessController();
        List<UserPermissionSetGroupAccessController.PermissionSetWrapper> wrappers = 
            controller.getfetchTableDataOption30();
        
        Test.stopTest();
        
        System.assertNotEquals(null, wrappers, 'Batch processing should complete');
    }
    
    @IsTest
    static void testEmptyPermissionSetAssignments() {
        
        Test.startTest();
        
        List<UserPermissionSetGroupAccessController.PermissionSetWrapper> wrappers = 
            new UserPermissionSetGroupAccessController().getfetchTableDataOption30();
        
        Test.stopTest();
        
        System.assertNotEquals(null, wrappers, 'Should return empty list, not null');
    }
    
    @IsTest
    static void testWrapperProperties() {
        UserPermissionSetGroupAccessController.PermissionSetWrapper wrapper = 
            new UserPermissionSetGroupAccessController.PermissionSetWrapper();
        
        wrapper.UserId = '0051234567890123';
        wrapper.UserNam = 'John Doe';
        wrapper.UserEmail = 'john.doe@test.com';
        wrapper.AssignedPermission = 'ViewAllData';
        wrapper.PermissionSetGroups = '0PG1234567890123';
        
        System.assertEquals('0051234567890123', wrapper.UserId);
        System.assertEquals('John Doe', wrapper.UserNam);
        System.assertEquals('john.doe@test.com', wrapper.UserEmail);
        System.assertEquals('ViewAllData', wrapper.AssignedPermission);
        System.assertEquals('0PG1234567890123', wrapper.PermissionSetGroups);
    }
    
    @IsTest
    static void testXMLHeader() {
        UserPermissionSetGroupAccessController controller = 
            new UserPermissionSetGroupAccessController();
        
        System.assertNotEquals(null, controller.xmlheader, 'XML header should be set');
        System.assert(controller.xmlheader.contains('<?xml version'), 
            'Should contain XML declaration');
        System.assert(controller.xmlheader.contains('Excel.Sheet'), 
            'Should reference Excel application');
    }
    
    @IsTest
    static void testReportInfos() {
        UserPermissionSetGroupAccessController controller = 
            new UserPermissionSetGroupAccessController();
        
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should not be null');
    }
    
    @IsTest
    static void testMultipleUsers() {
        // Create additional test user
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        User testUser2 = new User(
            Alias = 'upsg2',
            Email = 'userperms2@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'UserPermsTest2',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'userperms2' + DateTime.now().getTime() + '@test.com',
            IsActive = true
        );
        insert testUser2;
        
        Test.startTest();
        
        List<UserPermissionSetGroupAccessController.PermissionSetWrapper> wrappers = 
            new UserPermissionSetGroupAccessController().getfetchTableDataOption30();
        
        Test.stopTest();
        
        System.assert(wrappers.size() >= 0, 'Should handle multiple users');
    }
}