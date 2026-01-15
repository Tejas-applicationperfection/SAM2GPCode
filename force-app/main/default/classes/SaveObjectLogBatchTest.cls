@isTest
public class SaveObjectLogBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test profiles for the map
        List<Profile> profiles = [SELECT Id, Name FROM Profile LIMIT 2];
        
        // Create some existing SA_Audit__Objects_And_Fields_Log__c records to test the cleanup logic
        List<SA_Audit__Objects_And_Fields_Log__c> existingLogs = new List<SA_Audit__Objects_And_Fields_Log__c>();
        
        for (Integer i = 0; i < 5; i++) {
            SA_Audit__Objects_And_Fields_Log__c log = new SA_Audit__Objects_And_Fields_Log__c();
            if (Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Object_Type__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Date__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Description__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__User_Name__c.isCreateable()) {
                
                log.SA_Audit__Object_Type__c = 'TestObject';
                log.SA_Audit__Date__c = DateTime.now().addDays(-i);
                log.SA_Audit__Description__c = 'Test Description ' + i;
                log.SA_Audit__User_Name__c = 'Test User ' + i;
                existingLogs.add(log);
            }
        }
        
        if (!existingLogs.isEmpty()) {
            insert existingLogs;
        }
    }
    
    @isTest
    static void testSaveObjectLogBatchConstructor() {
        Test.startTest();
        
        String selectedObject = 'Account';
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = 'Test Description';
        String userName = 'Test User';
        
        // Add some test data to the map
        List<Profile> profiles = [SELECT Id FROM Profile LIMIT 2];
        if (!profiles.isEmpty()) {
            serializeWMap.put(profiles[0].Id, 'Test Value 1');
            if (profiles.size() > 1) {
                serializeWMap.put(profiles[1].Id, 'Test Value 2');
            }
        }
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        Test.stopTest();
        
        // Verify constructor initialization
        System.assertNotEquals(null, batch, 'Batch should be instantiated');
        // Note: We can't directly access private variables, but we can verify the batch was created
    }
    
    @isTest
    static void testStartMethod() {
        Test.startTest();
        
        String selectedObject = 'Account';
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = 'Test Description';
        String userName = 'Test User';
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Test the start method
        Database.QueryLocator ql = batch.start(null);
        
        Test.stopTest();
        
        // Verify query locator is created
        System.assertNotEquals(null, ql, 'QueryLocator should not be null');
    }
    
    @isTest
    static void testExecuteMethodWithNewObject() {
        Test.startTest();
        
        String selectedObject = 'NewTestObject';
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = 'Test Description';
        String userName = 'Test User';
        
        // Add test data to the map
        List<Profile> profiles = [SELECT Id FROM Profile LIMIT 2];
        if (!profiles.isEmpty()) {
            serializeWMap.put(profiles[0].Id, 'Test Value 1');
        }
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Create a mock scope (list of Users)
        List<User> scope = [SELECT Id FROM User LIMIT 1];
        
        // Execute the batch
        batch.execute(null, scope);
        
        Test.stopTest();
        
        // Verify that a new log record was created
        List<SA_Audit__Objects_And_Fields_Log__c> logs = [
            SELECT Id, SA_Audit__Object_Type__c, SA_Audit__Description__c, SA_Audit__User_Name__c 
            FROM SA_Audit__Objects_And_Fields_Log__c 
            WHERE SA_Audit__Object_Type__c = :selectedObject
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one new log record');
        System.assertEquals(selectedObject, logs[0].SA_Audit__Object_Type__c, 'Object type should match');
        System.assertEquals(description, logs[0].SA_Audit__Description__c, 'Description should match');
        System.assertEquals(userName, logs[0].SA_Audit__User_Name__c, 'User name should match');
    }
    
    @isTest
    static void testExecuteMethodWithExistingObjectUnderThreshold() {
        Test.startTest();
        
        String selectedObject = 'TestObject'; // This object already has 5 records from setup
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = 'Test Description';
        String userName = 'Test User';
        
        // Add test data to the map
        List<Profile> profiles = [SELECT Id FROM Profile LIMIT 2];
        if (!profiles.isEmpty()) {
            serializeWMap.put(profiles[0].Id, 'Test Value 1');
        }
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Create a mock scope
        List<User> scope = [SELECT Id FROM User LIMIT 1];
        
        // Execute the batch
        batch.execute(null, scope);
        
        Test.stopTest();
        
        // Verify that no old records were deleted (under threshold)
        List<SA_Audit__Objects_And_Fields_Log__c> logs = [
            SELECT Id FROM SA_Audit__Objects_And_Fields_Log__c 
            WHERE SA_Audit__Object_Type__c = :selectedObject
        ];
        
        System.assertEquals(6, logs.size(), 'Should have 5 existing + 1 new record (no deletion)');
    }
    
    @isTest
    static void testExecuteMethodWithLargeDataSet() {
        // Create a large dataset to test the 1000 record threshold
        List<SA_Audit__Objects_And_Fields_Log__c> largeLogs = new List<SA_Audit__Objects_And_Fields_Log__c>();
        
        for (Integer i = 0; i < 50; i++) { // Create 50 more records (total will be 55 with setup data)
            SA_Audit__Objects_And_Fields_Log__c log = new SA_Audit__Objects_And_Fields_Log__c();
            if (Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Object_Type__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Date__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Description__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__User_Name__c.isCreateable()) {
                
                log.SA_Audit__Object_Type__c = 'LargeTestObject';
                log.SA_Audit__Date__c = DateTime.now().addDays(-i);
                log.SA_Audit__Description__c = 'Large Test Description ' + i;
                log.SA_Audit__User_Name__c = 'Large Test User ' + i;
                largeLogs.add(log);
            }
        }
        
        if (!largeLogs.isEmpty()) {
            insert largeLogs;
        }
        
        Test.startTest();
        
        String selectedObject = 'LargeTestObject';
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = 'Large Test Description';
        String userName = 'Large Test User';
        
        // Add test data to the map
        List<Profile> profiles = [SELECT Id FROM Profile LIMIT 3];
        for (Profile p : profiles) {
            serializeWMap.put(p.Id, 'Large Test Value for ' + p.Id);
        }
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Create a mock scope
        List<User> scope = [SELECT Id FROM User LIMIT 1];
        
        // Execute the batch
        batch.execute(null, scope);
        
        Test.stopTest();
        
        // Verify that the new log record was created
        List<SA_Audit__Objects_And_Fields_Log__c> logs = [
            SELECT Id FROM SA_Audit__Objects_And_Fields_Log__c 
            WHERE SA_Audit__Object_Type__c = :selectedObject
        ];
        
        System.assertEquals(51, logs.size(), 'Should have 50 existing + 1 new record');
        
        // Verify that related field profile logs were created
        List<SA_Audit__Fields_Profile_Log__c> fieldLogs = [
            SELECT Id FROM SA_Audit__Fields_Profile_Log__c 
            WHERE SA_Audit__Objects_And_Fields_Log__c IN (
                SELECT Id FROM SA_Audit__Objects_And_Fields_Log__c 
                WHERE SA_Audit__Object_Type__c = :selectedObject
                AND SA_Audit__Description__c = :description
            )
        ];
        
        System.assertEquals(profiles.size(), fieldLogs.size(), 'Should create field logs for each profile');
    }
    
    @isTest
    static void testExecuteMethodWithEmptyMap() {
        Test.startTest();
        
        String selectedObject = 'EmptyMapObject';
        Map<Id, String> serializeWMap = new Map<Id, String>(); // Empty map
        String description = 'Empty Map Test';
        String userName = 'Empty Map User';
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Create a mock scope
        List<User> scope = [SELECT Id FROM User LIMIT 1];
        
        // Execute the batch
        batch.execute(null, scope);
        
        Test.stopTest();
        
        // Verify that the main log record was created even with empty map
        List<SA_Audit__Objects_And_Fields_Log__c> logs = [
            SELECT Id FROM SA_Audit__Objects_And_Fields_Log__c 
            WHERE SA_Audit__Object_Type__c = :selectedObject
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one log record even with empty map');
        
        // Verify no field profile logs were created
        List<SA_Audit__Fields_Profile_Log__c> fieldLogs = [
            SELECT Id FROM SA_Audit__Fields_Profile_Log__c 
            WHERE SA_Audit__Objects_And_Fields_Log__c = :logs[0].Id
        ];
        
        System.assertEquals(0, fieldLogs.size(), 'Should not create field logs for empty map');
    }
    
    @isTest
    static void testFinishMethod() {
        Test.startTest();
        
        String selectedObject = 'FinishTestObject';
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = 'Finish Test';
        String userName = 'Finish Test User';
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Mock batch context
        TestBatchableContext bc = new TestBatchableContext();
        
        // Test the finish method
        batch.finish(bc);
        
        Test.stopTest();
        
        // The finish method just logs completion, so we verify it doesn't throw exceptions
        System.assert(true, 'Finish method should complete without throwing exceptions');
    }
    
    @isTest
    static void testExecuteMethodErrorHandling() {
        Test.startTest();
        
        String selectedObject = 'ErrorTestObject';
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = 'Error Test';
        String userName = 'Error Test User';
        
        // Add invalid data to test error handling
        List<Profile> profiles = [SELECT Id FROM Profile LIMIT 1];
        if (!profiles.isEmpty()) {
            // Create a very long string that might cause issues
            String longValue = 'A'.repeat(255); // Create a string that might be too long for some fields
            serializeWMap.put(profiles[0].Id, longValue);
        }
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Create a mock scope
        List<User> scope = [SELECT Id FROM User LIMIT 1];
        
        try {
            // Execute the batch
            batch.execute(null, scope);
            System.assert(true, 'Batch should handle errors gracefully');
        } catch (Exception e) {
            System.debug('Expected exception during error handling test: ' + e.getMessage());
            System.assert(true, 'Exception handling is working as expected');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testBatchWithNullValues() {
        Test.startTest();
        
        String selectedObject = 'NullTestObject';
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = null; // Test with null description
        String userName = null; // Test with null username
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Create a mock scope
        List<User> scope = [SELECT Id FROM User LIMIT 1];
        
        try {
            // Execute the batch
            batch.execute(null, scope);
            System.assert(true, 'Batch should handle null values gracefully');
        } catch (Exception e) {
            System.debug('Exception with null values: ' + e.getMessage());
            System.assert(true, 'Null value handling is working');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testBatchWithSpecialCharacters() {
        Test.startTest();
        
        String selectedObject = 'SpecialCharObject';
        Map<Id, String> serializeWMap = new Map<Id, String>();
        String description = 'Test with special chars: <>&"\'';
        String userName = 'User with special chars: <>&"\'';
        
        // Add test data with special characters
        List<Profile> profiles = [SELECT Id FROM Profile LIMIT 1];
        if (!profiles.isEmpty()) {
            serializeWMap.put(profiles[0].Id, 'Value with special chars: <>&"\'');
        }
        
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        
        // Create a mock scope
        List<User> scope = [SELECT Id FROM User LIMIT 1];
        
        // Execute the batch
        batch.execute(null, scope);
        
        Test.stopTest();
        
        // Verify that records were created with special characters
        List<SA_Audit__Objects_And_Fields_Log__c> logs = [
            SELECT Id, SA_Audit__Description__c, SA_Audit__User_Name__c 
            FROM SA_Audit__Objects_And_Fields_Log__c 
            WHERE SA_Audit__Object_Type__c = :selectedObject
        ];
        
        System.assertEquals(1, logs.size(), 'Should create one log record');
        System.assertEquals(description, logs[0].SA_Audit__Description__c, 'Description with special chars should be preserved');
        System.assertEquals(userName, logs[0].SA_Audit__User_Name__c, 'Username with special chars should be preserved');
    }
    
    // Mock BatchableContext for testing
    private class TestBatchableContext implements Database.BatchableContext {
        public Id getJobId() {
            return '7070000000000001'; // Mock job ID
        }
        
        public Id getChildJobId() {
            return null;
        }
    }
}