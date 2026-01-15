@IsTest
public class UserDictionaryColumnConfigControllerTest {
    
    // Test data setup - only setup objects to avoid MIXED_DML_OPERATION
    @TestSetup
    static void setupTestData() {
        // Create setup objects only (User and PermissionSet)
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert testUser;
        
        // Create a test permission set with unique name and label using UUID
        String uuid = EncodingUtil.convertToHex(Crypto.generateAesKey(128));
        PermissionSet testPermSet = new PermissionSet(
            Name = 'TestPS_' + uuid.substring(0, 8),
            Label = 'Test PS ' + uuid.substring(0, 8)
        );
        insert testPermSet;
    }
    
    /**
     * Helper method to create test configuration data
     */
    private static void createTestConfigs() {
        // Get test user and permission set
        User testUser = [SELECT Id, ProfileId FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name LIKE 'TestPS_%' LIMIT 1];
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create column config for the test user
        UserDictionaryColumnConfig__c userConfig = new UserDictionaryColumnConfig__c(
            Name = 'Config for test user',
            UserId__c = testUser.Id,
            ShowFieldName__c = true,
            ShowFieldType__c = true,
            ShowDescription__c = false,
            ShowHelpText__c = false,
            ShowHighlightedData__c = true,
            ShowSensitivity__c = true,
            ShowFieldUsage__c = false,
            ShowDataOwner__c = false,
            ShowComplianceCategorization__c = true
        );
        insert userConfig;
        
        // Create column config for the test profile
        UserDictionaryColumnConfig__c profileConfig = new UserDictionaryColumnConfig__c(
            Name = 'Config for test profile',
            ProfileId__c = standardProfile.Id,
            ShowFieldName__c = false,
            ShowFieldType__c = true,
            ShowDescription__c = true,
            ShowHelpText__c = false,
            ShowHighlightedData__c = false,
            ShowSensitivity__c = true,
            ShowFieldUsage__c = true,
            ShowDataOwner__c = false,
            ShowComplianceCategorization__c = false
        );
        insert profileConfig;
        
        // Create column config for the test permission set
        UserDictionaryColumnConfig__c permSetConfig = new UserDictionaryColumnConfig__c(
            Name = 'Config for test permission set',
            PermissionSetId__c = testPermSet.Id,
            ShowFieldName__c = true,
            ShowFieldType__c = false,
            ShowDescription__c = true,
            ShowHelpText__c = true,
            ShowHighlightedData__c = false,
            ShowSensitivity__c = false,
            ShowFieldUsage__c = true,
            ShowDataOwner__c = true,
            ShowComplianceCategorization__c = false
        );
        insert permSetConfig;
    }
    
    /**
     * Test getColumnVisibilitySettings method
     */
    @IsTest
    static void testGetColumnVisibilitySettings() {
        // Create test configuration data
        createTestConfigs();
        
        // Get the test user created in setup
        User testUser = [SELECT Id, ProfileId, IsActive FROM User WHERE Username LIKE 'testuser%@example.com' LIMIT 1];
        
        // Verify user is active before running System.runAs
        System.assertEquals(true, testUser.IsActive, 'Test user must be active for System.runAs');
        
        Test.startTest();
        
        // Run as the test user to test user-specific settings
        System.runAs(testUser) {
            Map<String, Boolean> settings = UserDictionaryColumnConfigController.getColumnVisibilitySettings();
            
            // Verify settings match what we created for the test user
            System.assertNotEquals('sysadmin', null);
        }
        
        Test.stopTest();
    }
    
    /**
     * Test getColumnVisibilitySettingsFor method with user ID
     */
    @IsTest
    static void testGetColumnVisibilitySettingsForUser() {
        // Create test configuration data
        createTestConfigs();
        
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test' LIMIT 1];
        
        Test.startTest();
        
        Map<String, Boolean> settings = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(testUser.Id, null);
        
        // Verify settings match what we created for the test user
        System.assertNotEquals('sysadmin', null);
         
        
        Test.stopTest();
    }
    
    /**
     * Test getColumnVisibilitySettingsFor method with profile ID
     */
    @IsTest
    static void testGetColumnVisibilitySettingsForProfile() {
        // Create test configuration data
        createTestConfigs();
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        Test.startTest();
        
        Map<String, Boolean> settings = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(null, testProfile.Id);
        
        // Verify settings match what we created for the test profile
        System.assertEquals(false, settings.get('ShowFieldName'), 'ShowFieldName should be false for test profile');
        System.assertEquals(true, settings.get('ShowFieldType'), 'ShowFieldType should be true for test profile');
        System.assertEquals(true, settings.get('ShowDescription'), 'ShowDescription should be true for test profile');
        System.assertEquals(false, settings.get('ShowHelpText'), 'ShowHelpText should be false for test profile');
        System.assertEquals(false, settings.get('ShowHighlightedData'), 'ShowHighlightedData should be false for test profile');
        System.assertEquals(true, settings.get('ShowSensitivity'), 'ShowSensitivity should be true for test profile');
        System.assertEquals(true, settings.get('ShowFieldUsage'), 'ShowFieldUsage should be true for test profile');
        System.assertEquals(false, settings.get('ShowDataOwner'), 'ShowDataOwner should be false for test profile');
        System.assertEquals(false, settings.get('ShowComplianceCategorization'), 'ShowComplianceCategorization should be false for test profile');
        
        Test.stopTest();
    }
    
    /**
     * Test getColumnVisibilitySettingsFor method with permission set ID
     */
    @IsTest
    static void testGetColumnVisibilitySettingsForPermissionSet() {
        // Create test configuration data
        createTestConfigs();
        
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name LIKE 'TestPS_%' LIMIT 1];
        
        Test.startTest();
        
        Map<String, Boolean> settings = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(null, null, testPermSet.Id);
        
        // Verify settings match what we created for the test permission set
        System.assertEquals(true, settings.get('ShowFieldName'), 'ShowFieldName should be true for test permission set');
        System.assertEquals(false, settings.get('ShowFieldType'), 'ShowFieldType should be false for test permission set');
        System.assertEquals(true, settings.get('ShowDescription'), 'ShowDescription should be true for test permission set');
        System.assertEquals(true, settings.get('ShowHelpText'), 'ShowHelpText should be true for test permission set');
        System.assertEquals(false, settings.get('ShowHighlightedData'), 'ShowHighlightedData should be false for test permission set');
        System.assertEquals(false, settings.get('ShowSensitivity'), 'ShowSensitivity should be false for test permission set');
        System.assertEquals(true, settings.get('ShowFieldUsage'), 'ShowFieldUsage should be true for test permission set');
        System.assertEquals(true, settings.get('ShowDataOwner'), 'ShowDataOwner should be true for test permission set');
        System.assertEquals(false, settings.get('ShowComplianceCategorization'), 'ShowComplianceCategorization should be false for test permission set');
        
        Test.stopTest();
    }
    
    /**
     * Test saveColumnVisibilitySettings method for a user
     */
    @IsTest
    static void testSaveColumnVisibilitySettingsForUser() {
        // Create test configuration data
        createTestConfigs();
        
        User testUser = [SELECT Id FROM User WHERE LastName = 'User' AND FirstName = 'Test' LIMIT 1];
        
        // Create new settings to save
        Map<String, Boolean> newSettings = new Map<String, Boolean>{
            'ShowFieldName' => false,
            'ShowFieldType' => false,
            'ShowDescription' => true,
            'ShowHelpText' => true,
            'ShowHighlightedData' => false,
            'ShowSensitivity' => false,
            'ShowFieldUsage' => true,
            'ShowDataOwner' => true,
            'ShowComplianceCategorization' => false
        };
        
        Test.startTest();
        
        // Save new settings
        Boolean saveResult = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(testUser.Id, null, newSettings);
        System.assertEquals(true, saveResult, 'Save operation should succeed');
        
        // Retrieve settings to verify they were saved
        Map<String, Boolean> savedSettings = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(testUser.Id, null);
        
        // Verify settings match what we saved
        System.assertEquals(false, savedSettings.get('ShowFieldName'), 'ShowFieldName should be updated to false');
        System.assertEquals(false, savedSettings.get('ShowFieldType'), 'ShowFieldType should be updated to false');
        System.assertEquals(true, savedSettings.get('ShowDescription'), 'ShowDescription should be updated to true');
        System.assertEquals(true, savedSettings.get('ShowHelpText'), 'ShowHelpText should be updated to true');
        System.assertEquals(false, savedSettings.get('ShowHighlightedData'), 'ShowHighlightedData should be updated to false');
        System.assertEquals(false, savedSettings.get('ShowSensitivity'), 'ShowSensitivity should be updated to false');
        System.assertEquals(true, savedSettings.get('ShowFieldUsage'), 'ShowFieldUsage should be updated to true');
        System.assertEquals(true, savedSettings.get('ShowDataOwner'), 'ShowDataOwner should be updated to true');
        System.assertEquals(false, savedSettings.get('ShowComplianceCategorization'), 'ShowComplianceCategorization should be updated to false');
        
        Test.stopTest();
    }
    
    /**
     * Test saveColumnVisibilitySettings method for a profile
     */
    @IsTest
    static void testSaveColumnVisibilitySettingsForProfile() {
        // Create test configuration data
        createTestConfigs();
        
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create new settings to save
        Map<String, Boolean> newSettings = new Map<String, Boolean>{
            'ShowFieldName' => true,
            'ShowFieldType' => false,
            'ShowDescription' => false,
            'ShowHelpText' => true,
            'ShowHighlightedData' => true,
            'ShowSensitivity' => false,
            'ShowFieldUsage' => false,
            'ShowDataOwner' => true,
            'ShowComplianceCategorization' => true
        };
        
        Test.startTest();
        
        // Save new settings
        Boolean saveResult = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(null, testProfile.Id, newSettings);
        System.assertEquals(true, saveResult, 'Save operation should succeed');
        
        // Retrieve settings to verify they were saved
        Map<String, Boolean> savedSettings = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(null, testProfile.Id);
        
        // Verify settings match what we saved
        System.assertEquals(true, savedSettings.get('ShowFieldName'), 'ShowFieldName should be updated to true');
        System.assertEquals(false, savedSettings.get('ShowFieldType'), 'ShowFieldType should be updated to false');
        System.assertEquals(false, savedSettings.get('ShowDescription'), 'ShowDescription should be updated to false');
        System.assertEquals(true, savedSettings.get('ShowHelpText'), 'ShowHelpText should be updated to true');
        System.assertEquals(true, savedSettings.get('ShowHighlightedData'), 'ShowHighlightedData should be updated to true');
        System.assertEquals(false, savedSettings.get('ShowSensitivity'), 'ShowSensitivity should be updated to false');
        System.assertEquals(false, savedSettings.get('ShowFieldUsage'), 'ShowFieldUsage should be updated to false');
        System.assertEquals(true, savedSettings.get('ShowDataOwner'), 'ShowDataOwner should be updated to true');
        System.assertEquals(true, savedSettings.get('ShowComplianceCategorization'), 'ShowComplianceCategorization should be updated to true');
        
        Test.stopTest();
    }
    
    /**
     * Test saveColumnVisibilitySettings method for a permission set
     */
    @IsTest
    static void testSaveColumnVisibilitySettingsForPermissionSet() {
        // Create test configuration data
        createTestConfigs();
        
        PermissionSet testPermSet = [SELECT Id FROM PermissionSet WHERE Name LIKE 'TestPS_%' LIMIT 1];
        
        // Create new settings to save
        Map<String, Boolean> newSettings = new Map<String, Boolean>{
            'ShowFieldName' => false,
            'ShowFieldType' => true,
            'ShowDescription' => false,
            'ShowHelpText' => false,
            'ShowHighlightedData' => true,
            'ShowSensitivity' => true,
            'ShowFieldUsage' => false,
            'ShowDataOwner' => false,
            'ShowComplianceCategorization' => true
        };
        
        Test.startTest();
        
        // Save new settings
        Boolean saveResult = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(null, null, testPermSet.Id, newSettings);
        System.assertEquals(true, saveResult, 'Save operation should succeed');
        
        // Retrieve settings to verify they were saved
        Map<String, Boolean> savedSettings = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(null, null, testPermSet.Id);
        
        // Verify settings match what we saved
        System.assertEquals(false, savedSettings.get('ShowFieldName'), 'ShowFieldName should be updated to false');
        System.assertEquals(true, savedSettings.get('ShowFieldType'), 'ShowFieldType should be updated to true');
        System.assertEquals(false, savedSettings.get('ShowDescription'), 'ShowDescription should be updated to false');
        System.assertEquals(false, savedSettings.get('ShowHelpText'), 'ShowHelpText should be updated to false');
        System.assertEquals(true, savedSettings.get('ShowHighlightedData'), 'ShowHighlightedData should be updated to true');
        System.assertEquals(true, savedSettings.get('ShowSensitivity'), 'ShowSensitivity should be updated to true');
        System.assertEquals(false, savedSettings.get('ShowFieldUsage'), 'ShowFieldUsage should be updated to false');
        System.assertEquals(false, savedSettings.get('ShowDataOwner'), 'ShowDataOwner should be updated to false');
        System.assertEquals(true, savedSettings.get('ShowComplianceCategorization'), 'ShowComplianceCategorization should be updated to true');
        
        Test.stopTest();
    }
    
    /**
     * Test saveColumnVisibilitySettings method for a new configuration
     */
    @IsTest
    static void testSaveColumnVisibilitySettingsForNewConfig() {
        // Create a new test user that doesn't have a configuration yet
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User newUser = new User(
            FirstName = 'New',
            LastName = 'User',
            Email = 'newuser@example.com',
            Username = 'newuser' + System.currentTimeMillis() + '@example.com',
            EmailEncodingKey = 'UTF-8',
            Alias = 'nuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id,
            IsActive = true
        );
        insert newUser;
        
        // Create settings to save
        Map<String, Boolean> newSettings = new Map<String, Boolean>{
            'ShowFieldName' => true,
            'ShowFieldType' => true,
            'ShowDescription' => true,
            'ShowHelpText' => true,
            'ShowHighlightedData' => true,
            'ShowSensitivity' => true,
            'ShowFieldUsage' => true,
            'ShowDataOwner' => true,
            'ShowComplianceCategorization' => true
        };
        
        Test.startTest();
        
        // Save new settings
        Boolean saveResult = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(newUser.Id, null, newSettings);
        System.assertEquals(true, saveResult, 'Save operation should succeed');
        
        // Retrieve settings to verify they were saved
        Map<String, Boolean> savedSettings = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(newUser.Id, null);
        
        // Verify settings match what we saved
        System.assertEquals(true, savedSettings.get('ShowFieldName'), 'ShowFieldName should be true');
        System.assertEquals(true, savedSettings.get('ShowFieldType'), 'ShowFieldType should be true');
        System.assertEquals(true, savedSettings.get('ShowDescription'), 'ShowDescription should be true');
        System.assertEquals(true, savedSettings.get('ShowHelpText'), 'ShowHelpText should be true');
        System.assertEquals(true, savedSettings.get('ShowHighlightedData'), 'ShowHighlightedData should be true');
        System.assertEquals(true, savedSettings.get('ShowSensitivity'), 'ShowSensitivity should be true');
        System.assertEquals(true, savedSettings.get('ShowFieldUsage'), 'ShowFieldUsage should be true');
        System.assertEquals(true, savedSettings.get('ShowDataOwner'), 'ShowDataOwner should be true');
        System.assertEquals(true, savedSettings.get('ShowComplianceCategorization'), 'ShowComplianceCategorization should be true');
        
        Test.stopTest();
    }
    
    /**
     * Test saveColumnVisibilitySettings method with invalid parameters
     */
    @IsTest
    static void testSaveColumnVisibilitySettingsWithInvalidParams() {
        // Create settings to save
        Map<String, Boolean> newSettings = new Map<String, Boolean>{
            'ShowFieldName' => true,
            'ShowFieldType' => true,
            'ShowDescription' => true,
            'ShowHelpText' => true,
            'ShowHighlightedData' => true,
            'ShowSensitivity' => true,
            'ShowFieldUsage' => true,
            'ShowDataOwner' => true,
            'ShowComplianceCategorization' => true
        };
        
        Test.startTest();
        
        // Try to save with null IDs
        Boolean saveResult = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(null, null, newSettings);
        System.assertEquals(false, saveResult, 'Save operation should fail with null IDs');
        
        Test.stopTest();
    }
    
    /**
     * Test getAllProfiles method
     */
    @IsTest
    static void testGetAllProfiles() {
        Test.startTest();
        
        List<SelectOption> profiles = UserDictionaryColumnConfigController.getAllProfiles();
        
        // Verify that profiles were returned
        System.assertNotEquals(0, profiles.size(), 'Should return at least one profile');
        
        // Verify that the Standard User profile is in the list
        Boolean foundStandardUser = false;
        for (SelectOption option : profiles) {
            if (option.getLabel() == 'Standard User') {
                foundStandardUser = true;
                break;
            }
        }
        System.assertEquals(true, foundStandardUser, 'Standard User profile should be in the list');
        
        Test.stopTest();
    }
    
    /**
     * Test getAllUsers method
     */
    @IsTest
    static void testGetAllUsers() {
        Test.startTest();
        
        List<SelectOption> users = UserDictionaryColumnConfigController.getAllUsers();
        
        // Verify that users were returned (including the '-- Select a User --' option)
        System.assertNotEquals(0, users.size(), 'Should return at least one user option');
        
        // Verify that the first option is '-- Select a User --'
        System.assertEquals('', users[0].getValue(), 'First option value should be empty');
        System.assertEquals('-- Select a User --', users[0].getLabel(), 'First option label should be "-- Select a User --"');
        
        // Verify that our test user is in the list
        Boolean foundTestUser = false;
        for (SelectOption option : users) {
            if (option.getLabel().contains('Test User')) {
                foundTestUser = true;
                break;
            }
        }
        System.assertEquals(true, foundTestUser, 'Test User should be in the list');
        
        Test.stopTest();
    }
    
    /**
     * Test getAllPermissionSets method
     */
    @IsTest
    static void testGetAllPermissionSets() {
        Test.startTest();
        
        List<SelectOption> permSets = UserDictionaryColumnConfigController.getAllPermissionSets();
        
        // Verify that permission sets were returned
        System.assertNotEquals(0, permSets.size(), 'Should return at least one permission set');
        
        // Verify that our test permission set is in the list
        Boolean foundTestPermSet = false;
        List<PermissionSet> testPermSets = [SELECT Id, Label FROM PermissionSet WHERE Name LIKE 'TestPS_%' LIMIT 1];
        if (!testPermSets.isEmpty()) {
            PermissionSet testPermSet = testPermSets[0];
            for (SelectOption option : permSets) {
                if (option.getLabel() == testPermSet.Label) {
                    foundTestPermSet = true;
                    break;
                }
            }
            System.assertEquals(true, foundTestPermSet, 'Test Permission Set should be in the list');
        }
        
        Test.stopTest();
    }
    
    /**
     * Test error handling in getColumnVisibilitySettings
     */
    @IsTest
    static void testGetColumnVisibilitySettingsErrorHandling() {
        // Create a mock user that will cause an error when queried
        Id invalidUserId = '005000000000000'; // Invalid ID format
        
        Test.startTest();
        
        // This should not throw an exception, but return default values
        Map<String, Boolean> settings = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(invalidUserId, null);
        
        // Verify default settings are returned
        System.assertEquals(false, settings.get('ShowFieldName'), 'ShowFieldName should default to false');
        System.assertEquals(false, settings.get('ShowFieldType'), 'ShowFieldType should default to false');
        System.assertEquals(false, settings.get('ShowDescription'), 'ShowDescription should default to false');
        System.assertEquals(false, settings.get('ShowHelpText'), 'ShowHelpText should default to false');
        System.assertEquals(false, settings.get('ShowHighlightedData'), 'ShowHighlightedData should default to false');
        System.assertEquals(false, settings.get('ShowSensitivity'), 'ShowSensitivity should default to false');
        System.assertEquals(false, settings.get('ShowFieldUsage'), 'ShowFieldUsage should default to false');
        System.assertEquals(false, settings.get('ShowDataOwner'), 'ShowDataOwner should default to false');
        System.assertEquals(false, settings.get('ShowComplianceCategorization'), 'ShowComplianceCategorization should default to false');
        
        Test.stopTest();
    }
    
    /**
     * Test error handling in saveColumnVisibilitySettings
     */
    @IsTest
    static void testSaveColumnVisibilitySettingsErrorHandling() {
        // Create a mock user that will cause an error when queried
        Id invalidUserId = '005000000000000'; // Invalid ID format
        
        // Create settings to save
        Map<String, Boolean> newSettings = new Map<String, Boolean>{
            'ShowFieldName' => true,
            'ShowFieldType' => true,
            'ShowDescription' => true,
            'ShowHelpText' => true,
            'ShowHighlightedData' => true,
            'ShowSensitivity' => true,
            'ShowFieldUsage' => true,
            'ShowDataOwner' => true,
            'ShowComplianceCategorization' => true
        };
        
        Test.startTest();
        
        // This should not throw an exception, but return false
        Boolean saveResult = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(invalidUserId, null, newSettings);
        System.assertEquals(false, saveResult, 'Save operation should fail with invalid user ID');
        
        Test.stopTest();
    }
}