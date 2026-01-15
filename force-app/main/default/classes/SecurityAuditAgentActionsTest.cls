/**
 * Test class for SecurityAuditAgentActions
 */
@IsTest
private class SecurityAuditAgentActionsTest {
    
    @TestSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'sagent',
            Email = 'securityagent@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'SecurityAgent',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'securityagent' + DateTime.now().getTime() + '@test.com',
            IsActive = true
        );
        insert testUser;
    }
    
    @IsTest
    static void testGetUsersWithPermission_Found() {
        Test.startTest();
        
        SecurityAuditAgentActions.PermissionRequest req = new SecurityAuditAgentActions.PermissionRequest();
        req.permissionName = 'ModifyAllData';
        
        List<SecurityAuditAgentActions.PermissionResult> results = 
            SecurityAuditAgentActions.getUsersWithPermission(new List<SecurityAuditAgentActions.PermissionRequest>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0].message, 'Message should not be null');
    }
    
    @IsTest
    static void testGetUsersWithPermission_NullRequest() {
        Test.startTest();
        
        List<SecurityAuditAgentActions.PermissionResult> results = 
            SecurityAuditAgentActions.getUsersWithPermission(null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Should return empty list for null input');
    }
    
    @IsTest
    static void testGetUsersWithPermission_EmptyRequest() {
        Test.startTest();
        
        List<SecurityAuditAgentActions.PermissionResult> results = 
            SecurityAuditAgentActions.getUsersWithPermission(new List<SecurityAuditAgentActions.PermissionRequest>());
        
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }
    
    @IsTest
    static void testGetUsersWithPermission_DifferentPermissions() {
        Test.startTest();
        
        List<String> permissions = new List<String>{ 'ManageUsers', 'ApiEnabled', 'CustomizeApplication' };
        
        for (String perm : permissions) {
            SecurityAuditAgentActions.PermissionRequest req = new SecurityAuditAgentActions.PermissionRequest();
            req.permissionName = perm;
            
            List<SecurityAuditAgentActions.PermissionResult> results = 
                SecurityAuditAgentActions.getUsersWithPermission(new List<SecurityAuditAgentActions.PermissionRequest>{ req });
            
            System.assertNotEquals(null, results, 'Results should not be null for: ' + perm);
            System.assertEquals(1, results.size(), 'Should return one result for: ' + perm);
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testGetUsersWithPermission_NotFound() {
        Test.startTest();
        
        SecurityAuditAgentActions.PermissionRequest req = new SecurityAuditAgentActions.PermissionRequest();
        req.permissionName = 'NonExistentPermissionXYZ123';
        
        List<SecurityAuditAgentActions.PermissionResult> results = 
            SecurityAuditAgentActions.getUsersWithPermission(new List<SecurityAuditAgentActions.PermissionRequest>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0].message, 'Message should not be null');
    }
    
    @IsTest
    static void testWrapperClasses() {
        Test.startTest();
        
        SecurityAuditAgentActions.PermissionRequest req = new SecurityAuditAgentActions.PermissionRequest();
        req.permissionName = 'TestPermission';
        
        SecurityAuditAgentActions.PermissionResult res = new SecurityAuditAgentActions.PermissionResult();
        res.message = 'Test message';
        res.foundUsers = 'User1, User2';
        res.userCount = 2;
        res.permissionName = 'TestPermission';
        
        Test.stopTest();
        
        System.assertEquals('TestPermission', req.permissionName, 'Permission name should match');
        System.assertEquals('Test message', res.message, 'Message should match');
        System.assertEquals(2, res.userCount, 'User count should match');
    }
}