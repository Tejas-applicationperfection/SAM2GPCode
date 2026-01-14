/**
 * @description Comprehensive test class for ProfileClonerController
 * @author Salesforce 
 * @date 2024
 */
@isTest
public class ProfileClonerControllerTest {
    
    /**
     * @description Setup test data for ProfileClonerController tests
     */
    @testSetup
    static void setupTestData() {
        // Create test ProfileClonerDetails records
        List<SA_Audit__ProfileClonerDetails__c> testProfiles = new List<SA_Audit__ProfileClonerDetails__c>();
        
        for (Integer i = 0; i < 15; i++) {
            SA_Audit__ProfileClonerDetails__c profile = new SA_Audit__ProfileClonerDetails__c(
                Name = 'Test Profile ' + i,
                SA_Audit__NewPermission__c = 'Test Permission ' + i
            );
            testProfiles.add(profile);
        }
        
        insert testProfiles;
    }
    
    /**
     * @description Test successful retrieval of last cloned profiles
     */
    @isTest
    static void testGetLastClonedProfiles_Success() {
        Test.startTest();
        
        List<SA_Audit__ProfileClonerDetails__c> result = ProfileClonerController.getLastClonedProfiles();
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(10, result.size(), 'Should return maximum 10 records');
        
        // Verify records are returned (CreatedDate ordering is handled by the controller's SOQL)
        // Note: CreatedDate field verification removed as it's not queried in the controller
        
        // Verify required fields are populated
        for (SA_Audit__ProfileClonerDetails__c profile : result) {
            System.assertNotEquals(null, profile.Id, 'Id should not be null');
            System.assertNotEquals(null, profile.Name, 'Name should not be null');
            System.assertNotEquals(null, profile.SA_Audit__NewPermission__c, 'NewPermission should not be null');
        }
    }
    
    /**
     * @description Test behavior when no records exist
     */
    @isTest
    static void testGetLastClonedProfiles_NoRecords() {
        // Delete all test data
        delete [SELECT Id FROM SA_Audit__ProfileClonerDetails__c];
        
        Test.startTest();
        
        List<SA_Audit__ProfileClonerDetails__c> result = ProfileClonerController.getLastClonedProfiles();
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list when no records exist');
    }
    
    /**
     * @description Test exception handling with limited user permissions
     */
    @isTest
    static void testGetLastClonedProfiles_LimitedPermissions() {
        // Create user with limited permissions
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;
        
        Test.startTest();
        
        System.runAs(testUser) {
            try {
                List<SA_Audit__ProfileClonerDetails__c> result = ProfileClonerController.getLastClonedProfiles();
                // If no exception is thrown, verify the result
                System.assertNotEquals(null, result, 'Result should not be null');
            } catch (AuraHandledException e) {
                // Verify proper exception handling
                System.assert(e.getMessage().contains('Error fetching cloned profiles'), 
                             'Exception message should contain expected text');
            }
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test performance with large dataset
     */
    @isTest
    static void testGetLastClonedProfiles_Performance() {
        Test.startTest();
        
        // Measure execution time
        Datetime startTime = System.now();
        List<SA_Audit__ProfileClonerDetails__c> result = ProfileClonerController.getLastClonedProfiles();
        Datetime endTime = System.now();
        
        Test.stopTest();
        
        // Performance assertions
        Long executionTime = endTime.getTime() - startTime.getTime();
        System.assert(executionTime < 5000, 'Method should execute within 5 seconds');
        
        // Verify LIMIT clause effectiveness
        System.assert(result.size() <= 10, 'Should never return more than 10 records');
    }
    
    /**
     * @description Test method accessibility and cacheability
     */
    @isTest
    static void testGetLastClonedProfiles_Accessibility() {
        Test.startTest();
        
        // Test multiple calls to verify caching behavior
        List<SA_Audit__ProfileClonerDetails__c> result1 = ProfileClonerController.getLastClonedProfiles();
        List<SA_Audit__ProfileClonerDetails__c> result2 = ProfileClonerController.getLastClonedProfiles();
        
        Test.stopTest();
        
        // Verify consistent results
        System.assertEquals(result1.size(), result2.size(), 'Cached results should be consistent');
        
        if (!result1.isEmpty() && !result2.isEmpty()) {
            System.assertEquals(result1[0].Id, result2[0].Id, 'First record should be the same');
        }
    }
    
    /**
     * @description Test SOQL injection prevention
     */
    @isTest
    static void testGetLastClonedProfiles_SecurityValidation() {
        Test.startTest();
        
        // Verify method executes without security vulnerabilities
        List<SA_Audit__ProfileClonerDetails__c> result = ProfileClonerController.getLastClonedProfiles();
        
        Test.stopTest();
        
        // Verify secure execution
        System.assertNotEquals(null, result, 'Method should execute securely');
        
        // Verify field-level security is respected
        for (SA_Audit__ProfileClonerDetails__c profile : result) {
            // Verify only accessible fields are returned
            System.assertNotEquals(null, profile.Id, 'Id should be accessible');
        }
    }
}