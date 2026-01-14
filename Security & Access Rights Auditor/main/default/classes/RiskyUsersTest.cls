/**
 * @description Test class for the Risky Users functionality
 * @author System
 * @date 2025
 */
@IsTest
public with sharing class RiskyUsersTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test profile
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create test users
        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < 15; i++) {
            User testUser = new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@test.com',
                Username = 'testuser' + i + '@test.com.risky',
                Alias = 'tu' + i,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = testProfile.Id,
                IsActive = true
            );
            testUsers.add(testUser);
        }
        insert testUsers;
    }
    
    @IsTest
    static void testGetRiskyUsersFirstPage() {
        Test.startTest();
        
        UserPermController.RiskyUsersResponse response = UserPermController.getRiskyUsers(1, 10);
        
        Test.stopTest();
        
        // Verify response structure
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(1, response.currentPage, 'Current page should be 1');
        System.assertEquals(10, response.pageSize, 'Page size should be 10');
        System.assertNotEquals(null, response.users, 'Users list should not be null');
        
        // Verify we get users (at least the test users we created)
        System.assert(response.users.size() > 0, 'Should return some users');
        System.assert(response.totalCount > 0, 'Total count should be greater than 0');
        
        // Verify user data structure
        for (UserPermController.RiskyUserWrapper user : response.users) {
            System.assertNotEquals(null, user.userId, 'User ID should not be null');
            System.assertNotEquals(null, user.userName, 'User name should not be null');
            System.assertNotEquals(null, user.riskLevel, 'Risk level should not be null');
            System.assert(user.riskScore >= 0, 'Risk score should be non-negative');
        }
    }
    
    @IsTest
    static void testGetRiskyUsersSecondPage() {
        Test.startTest();
        
        UserPermController.RiskyUsersResponse response = UserPermController.getRiskyUsers(2, 10);
        
        Test.stopTest();
        
        // Verify response structure
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(2, response.currentPage, 'Current page should be 2');
        System.assertEquals(10, response.pageSize, 'Page size should be 10');
    }
    
    @IsTest
    static void testGetRiskyUsersInvalidParameters() {
        Test.startTest();
        
        // Test with null parameters
        UserPermController.RiskyUsersResponse response1 = UserPermController.getRiskyUsers(null, null);
        
        // Test with invalid parameters
        UserPermController.RiskyUsersResponse response2 = UserPermController.getRiskyUsers(-1, 0);
        
        // Test with oversized page (should be capped at 1000)
        UserPermController.RiskyUsersResponse response3 = UserPermController.getRiskyUsers(1, 2000);
        
        Test.stopTest();
        
        // Verify defaults are applied
        System.assertEquals(1, response1.currentPage, 'Should default to page 1');
        System.assertEquals(10, response1.pageSize, 'Should default to page size 10');
        
        System.assertEquals(1, response2.currentPage, 'Should default to page 1 for negative input');
        System.assertEquals(10, response2.pageSize, 'Should default to page size 10 for zero input');
        
        System.assertEquals(1, response3.currentPage, 'Should accept page 1');
        System.assertEquals(1000, response3.pageSize, 'Page size should be capped at 1000');
    }
    
    @IsTest
    static void testRiskScoreComparator() {
        Test.startTest();
        
        // Create test users with different risk scores
        UserPermController.RiskyUserWrapper user1 = new UserPermController.RiskyUserWrapper();
        user1.userName = 'User A';
        user1.riskScore = 85;
        
        UserPermController.RiskyUserWrapper user2 = new UserPermController.RiskyUserWrapper();
        user2.userName = 'User B';
        user2.riskScore = 45;
        
        UserPermController.RiskyUserWrapper user3 = new UserPermController.RiskyUserWrapper();
        user3.userName = 'User C';
        user3.riskScore = 85; // Same as user1
        
        List<UserPermController.RiskyUserWrapper> users = new List<UserPermController.RiskyUserWrapper>{user2, user3, user1};
        
        // Sort using the comparator
        users.sort(new UserPermController.RiskScoreComparator());
        
        Test.stopTest();
        
        // Verify sorting (highest risk first, then by name)
        System.assertEquals(85, users[0].riskScore, 'First user should have highest risk score');
        System.assertEquals(85, users[1].riskScore, 'Second user should have same high risk score');
        System.assertEquals(45, users[2].riskScore, 'Third user should have lowest risk score');
        
        // When risk scores are equal, should sort by name
        System.assertEquals('User A', users[0].userName, 'User A should come before User C alphabetically');
        System.assertEquals('User C', users[1].userName, 'User C should come after User A alphabetically');
    }
}