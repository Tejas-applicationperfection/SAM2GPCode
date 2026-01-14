@isTest
public class UserAccessCompareControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users with all required fields
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User user1 = new User(
            Username = 'testuser1_' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser1@example.com',
            Alias = 'tuser1',
            ProfileId = standardProfile.Id,
            IsActive = true,
            FirstName = 'Test',
            LastName = 'User1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        User user2 = new User(
            Username = 'testuser2_' + System.currentTimeMillis() + '@example.com',
            Email = 'testuser2@example.com',
            Alias = 'tuser2',
            ProfileId = standardProfile.Id,
            IsActive = false,
            FirstName = 'Test',
            LastName = 'User2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        
        insert new List<User>{user1, user2};
    }
    
    @isTest
    static void testConstructor() {
        Test.startTest();
        UserAccessCompareController controller = new UserAccessCompareController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller, 'Controller should be instantiated');
        System.assertNotEquals(null, controller.xmlheader, 'XML header should be set');
        System.assert(controller.xmlheader.contains('<?xml version="1.0"?>'), 'XML header should contain version declaration');
    }
    
    @isTest
    static void testGetUserBooleanFieldDataSuccess() {
        List<User> testUsers = [SELECT Id, Name FROM User WHERE Email LIKE 'testuser%@example.com' ORDER BY Email];
        System.assertEquals(2, testUsers.size(), 'Should have 2 test users');
        
        Test.startTest();
        List<String> selectedUsers = new List<String>{testUsers[0].Id, testUsers[1].Id};
        UserAccessCompareController.UserWrapper result = UserAccessCompareController.getUserBooleanFieldData(selectedUsers);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(testUsers[0].Id + ' vs ' + testUsers[1].Id, result.userId, 'User IDs should match expected format');
        System.assertEquals(testUsers[0].Name + ' vs ' + testUsers[1].Name, result.userName, 'User names should match expected format');
        System.assertNotEquals(null, result.fields, 'Fields list should not be null');
        System.assertNotEquals(null, result.fieldValues1, 'Field values 1 should not be null');
        System.assertNotEquals(null, result.fieldValues2, 'Field values 2 should not be null');
        System.assertEquals(result.fields.size(), result.fieldValues1.size(), 'Fields and values1 should have same size');
        System.assertEquals(result.fields.size(), result.fieldValues2.size(), 'Fields and values2 should have same size');
    }
    
    @isTest
    static void testGetUserBooleanFieldDataInsufficientUsers() {
        List<User> testUsers = [SELECT Id FROM User WHERE Email LIKE 'testuser%@example.com' LIMIT 1];
        
        Test.startTest();
        List<String> selectedUsers = new List<String>{testUsers[0].Id};
        UserAccessCompareController.UserWrapper result = UserAccessCompareController.getUserBooleanFieldData(selectedUsers);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null when insufficient users provided');
    }
    
    @isTest
    static void testGetUserBooleanFieldDataEmptyList() {
        Test.startTest();
        List<String> selectedUsers = new List<String>();
        UserAccessCompareController.UserWrapper result = UserAccessCompareController.getUserBooleanFieldData(selectedUsers);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null when empty list provided');
    }
    
    @isTest
    static void testFetchUserBooleanFields() {
        List<User> testUsers = [SELECT Id FROM User WHERE Email LIKE 'testuser%@example.com' LIMIT 1];
        
        // Get boolean fields for testing
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('User').getDescribe().fields.getMap();
        List<String> booleanFields = new List<String>();
        
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (fieldDescribe.getType() == Schema.DisplayType.Boolean) {
                booleanFields.add(fieldName);
                if (booleanFields.size() >= 3) break; // Limit for testing
            }
        }
        
        Test.startTest();
        User result = UserAccessCompareController.fetchUserBooleanFields(testUsers[0].Id, booleanFields);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(testUsers[0].Id, result.Id, 'User ID should match');
    }
    
    @isTest
    static void testFetchUserBooleanFieldsEmptyFields() {
        List<User> testUsers = [SELECT Id FROM User WHERE Email LIKE 'testuser%@example.com' LIMIT 1];
        
        Test.startTest();
        User result = UserAccessCompareController.fetchUserBooleanFields(testUsers[0].Id, new List<String>());
        Test.stopTest();
        
        System.assertEquals(null, result, 'Result should be null when no boolean fields provided');
    }
    
    @isTest
    static void testUserWrapperClass() {
        Test.startTest();
        List<String> fields = new List<String>{'IsActive', 'EmailBouncedReason'};
        List<Boolean> values1 = new List<Boolean>{true, false};
        List<Boolean> values2 = new List<Boolean>{false, true};
        
        UserAccessCompareController.UserWrapper wrapper = new UserAccessCompareController.UserWrapper(
            'user1 vs user2',
            'Test User1 vs Test User2',
            fields,
            values1,
            values2
        );
        Test.stopTest();
        
        System.assertEquals('user1 vs user2', wrapper.userId, 'User ID should match');
        System.assertEquals('Test User1 vs Test User2', wrapper.userName, 'User name should match');
        System.assertEquals(fields, wrapper.fields, 'Fields should match');
        System.assertEquals(values1, wrapper.fieldValues1, 'Field values 1 should match');
        System.assertEquals(values2, wrapper.fieldValues2, 'Field values 2 should match');
    }
}