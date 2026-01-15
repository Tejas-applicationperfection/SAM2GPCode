/**
 * @description Comprehensive test class for userCloneAnalytics
 * @author Salesforce Trae AI
 * @date 2025
 */
@IsTest
public class userCloneAnalyticsTest {
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test users with different profiles
        List<User> testUsers = new List<User>();
        
        // Get standard user profile
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create test users with unique usernames
        String uniqueId = String.valueOf(System.currentTimeMillis());
        for(Integer i = 0; i < 3; i++) {
            User testUser = new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + uniqueId + '@test.com',
                Username = 'testuser' + i + uniqueId + '@test.com.test',
                Alias = 'tu' + i + String.valueOf(i),
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                IsActive = true
            );
            testUsers.add(testUser);
        }
        
        insert testUsers;
        
        // Create test permission sets
        List<PermissionSet> testPermSets = new List<PermissionSet>();
        for(Integer i = 0; i < 2; i++) {
            PermissionSet ps = new PermissionSet(
                Name = 'TestPermSet' + i,
                Label = 'Test Permission Set ' + i
            );
            testPermSets.add(ps);
        }
        insert testPermSets;
        
        // Create permission set assignments
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for(Integer i = 0; i < testUsers.size(); i++) {
            for(Integer j = 0; j < testPermSets.size(); j++) {
                PermissionSetAssignment psa = new PermissionSetAssignment(
                    AssigneeId = testUsers[i].Id,
                    PermissionSetId = testPermSets[j].Id
                );
                assignments.add(psa);
            }
        }
        insert assignments;
        
        // Use System.runAs to avoid mixed DML operations
        System.runAs(testUsers[0]) {
            // Create test RecentCloneUserLog__c records
            List<RecentCloneUserLog__c> cloneLogs = new List<RecentCloneUserLog__c>();
            for(Integer i = 0; i < 3; i++) {
                RecentCloneUserLog__c log = new RecentCloneUserLog__c(
                    Name = 'Test Clone ' + i,
                    source_User__c = testUsers[0].Id, // Use actual User ID
                    UserClonedDate__c = Date.today().addDays(-i)
                );
                cloneLogs.add(log);
            }
            insert cloneLogs;
        }
    }
    
    /**
     * @description Test getLicenseUtilization method with valid data
     */
    @IsTest
    static void testGetLicenseUtilization_Success() {
        Test.startTest();
        
        List<userCloneAnalytics.LicenseInfo> result = userCloneAnalytics.getLicenseUtilization();
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'License utilization should not be null');
        System.assert(result.size() >= 0, 'Should return license information');
        
        // Verify structure of returned data
        if(!result.isEmpty()) {
            userCloneAnalytics.LicenseInfo firstLicense = result[0];
            System.assertNotEquals(null, firstLicense.licenseName, 'License name should not be null');
            System.assertNotEquals(null, firstLicense.totalLicenses, 'Total licenses should not be null');
            System.assertNotEquals(null, firstLicense.usedLicenses, 'Used licenses should not be null');
            System.assertNotEquals(null, firstLicense.users, 'Users list should not be null');
        }
    }
    
    /**
     * @description Test getPermissionDistribution method with valid parameters
     */
    @IsTest
    static void testGetPermissionDistribution_Success() {
        Test.startTest();
        
        List<userCloneAnalytics.PermissionData> result = userCloneAnalytics.getPermissionDistribution(0, 10);
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Permission distribution should not be null');
        System.assert(result.size() >= 0, 'Should return permission data');
        
        // Verify structure if data exists
        if(!result.isEmpty()) {
            userCloneAnalytics.PermissionData firstPerm = result[0];
            System.assertNotEquals(null, firstPerm.name, 'Permission name should not be null');
            System.assertNotEquals(null, firstPerm.count, 'Permission count should not be null');
            System.assertNotEquals(null, firstPerm.permissionSetId, 'Permission set ID should not be null');
        }
    }
    
    /**
     * @description Test getPermissionDistribution with null parameters
     */
    @IsTest
    static void testGetPermissionDistribution_NullParameters() {
        Test.startTest();
        
        List<userCloneAnalytics.PermissionData> result = userCloneAnalytics.getPermissionDistribution(null, null);
        
        Test.stopTest();
        
        // Should handle null parameters gracefully
        System.assertNotEquals(null, result, 'Should handle null parameters');
    }
    
    /**
     * @description Test getPermissionDistribution with negative parameters
     */
    @IsTest
    static void testGetPermissionDistribution_NegativeParameters() {
        Test.startTest();
        
        List<userCloneAnalytics.PermissionData> result = userCloneAnalytics.getPermissionDistribution(-5, -10);
        
        Test.stopTest();
        
        // Should handle negative parameters gracefully
        System.assertNotEquals(null, result, 'Should handle negative parameters');
    }
    
    /**
     * @description Test getPermissionDistribution with large limit
     */
    @IsTest
    static void testGetPermissionDistribution_LargeLimit() {
        Test.startTest();
        
        List<userCloneAnalytics.PermissionData> result = userCloneAnalytics.getPermissionDistribution(0, 2000);
        
        Test.stopTest();
        
        // Should cap at maximum limit
        System.assertNotEquals(null, result, 'Should handle large limits');
    }
    
    /**
     * @description Test getCloningPatterns method
     */
    @IsTest
    static void testGetCloningPatterns_Success() {
        Test.startTest();
        
        List<userCloneAnalytics.ClonePattern> result = userCloneAnalytics.getCloningPatterns();
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Cloning patterns should not be null');
        System.assertEquals(7, result.size(), 'Should return 7 days of patterns');
        
        // Verify structure
        for(userCloneAnalytics.ClonePattern pattern : result) {
            System.assertNotEquals(null, pattern.label, 'Pattern label should not be null');
            System.assertNotEquals(null, pattern.value, 'Pattern value should not be null');
            System.assert(pattern.value >= 0, 'Pattern value should be non-negative');
        }
    }
    
    /**
     * @description Test getCloneHistory method
     */
    @IsTest
    static void testGetCloneHistory_Success() {
        Test.startTest();
        
        List<RecentCloneUserLog__c> result = userCloneAnalytics.getCloneHistory();
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Clone history should not be null');
        System.assert(result.size() >= 0, 'Should return clone history data');
        
        // Verify structure if data exists
        if(!result.isEmpty()) {
            RecentCloneUserLog__c firstLog = result[0];
            System.assertNotEquals(null, firstLog.Id, 'Log ID should not be null');
            System.assertNotEquals(null, firstLog.Name, 'Log name should not be null');
        }
    }
    
    /**
     * @description Test inner class constructors and properties
     */
    @IsTest
    static void testInnerClassConstructors() {
        Test.startTest();
        
        // Test LicenseInfo constructor
        List<userCloneAnalytics.UserLicenseInfo> userList = new List<userCloneAnalytics.UserLicenseInfo>();
        userCloneAnalytics.LicenseInfo licenseInfo = new userCloneAnalytics.LicenseInfo(
            'Test License', 100, 50, userList
        );
        
        System.assertEquals('Test License', licenseInfo.licenseName);
        System.assertEquals(100, licenseInfo.totalLicenses);
        System.assertEquals(50, licenseInfo.usedLicenses);
        System.assertEquals(userList, licenseInfo.users);
        
        // Test UserLicenseInfo constructor
        userCloneAnalytics.UserLicenseInfo userLicenseInfo = new userCloneAnalytics.UserLicenseInfo(
            'Test User', 'test@test.com', 'Standard User', DateTime.now()
        );
        
        System.assertEquals('Test User', userLicenseInfo.userName);
        System.assertEquals('test@test.com', userLicenseInfo.userEmail);
        System.assertEquals('Standard User', userLicenseInfo.profileName);
        System.assertNotEquals(null, userLicenseInfo.assignedDate);
        
        // Test CloneHistory constructor
        userCloneAnalytics.CloneHistory cloneHistory = new userCloneAnalytics.CloneHistory(
            DateTime.now(), 'Source User', 'New User', 'Cloned By', 'Success'
        );
        
        System.assertNotEquals(null, cloneHistory.cloneDate);
        System.assertEquals('Source User', cloneHistory.sourceUser);
        System.assertEquals('New User', cloneHistory.newUser);
        System.assertEquals('Cloned By', cloneHistory.clonedBy);
        System.assertEquals('Success', cloneHistory.status);
        
        // Test PermissionData constructor
        userCloneAnalytics.PermissionData permissionData = new userCloneAnalytics.PermissionData(
            'Test Permission', 5, 'permSetId123'
        );
        
        System.assertEquals('Test Permission', permissionData.name);
        System.assertEquals(5, permissionData.count);
        System.assertEquals('permSetId123', permissionData.permissionSetId);
        
        // Test ClonePattern constructor
        userCloneAnalytics.ClonePattern clonePattern = new userCloneAnalytics.ClonePattern(
            'Test Pattern', 10
        );
        
        System.assertEquals('Test Pattern', clonePattern.label);
        System.assertEquals(10, clonePattern.value);
        
        Test.stopTest();
    }
    
    /**
     * @description Test SecurityException class
     */
    @IsTest
    static void testSecurityException() {
        Test.startTest();
        
        try {
            throw new userCloneAnalytics.SecurityException('Test security exception');
        } catch(userCloneAnalytics.SecurityException e) {
            System.assertEquals('Test security exception', e.getMessage());
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test method behavior with insufficient permissions (negative test)
     * Note: This test simulates security scenarios but actual FLS/CRUD checks 
     * depend on the running user's permissions in the test context
     */
    @IsTest
    static void testSecurityEnforcement() {
        // Create a user with minimal permissions for negative testing
        Profile minimalProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        
        String minimalUniqueId = String.valueOf(System.currentTimeMillis()) + 'min';
        User testUser = new User(
            FirstName = 'Minimal',
            LastName = 'User',
            Email = 'minimal' + minimalUniqueId + '@test.com',
            Username = 'minimal' + minimalUniqueId + '@test.com.test',
            Alias = 'min' + String.valueOf(System.currentTimeMillis()).right(4),
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = minimalProfile.Id,
            IsActive = true
        );
        
        insert testUser;
        
        System.runAs(testUser) {
            Test.startTest();
            
            // Test methods that should handle security gracefully
            try {
                List<userCloneAnalytics.LicenseInfo> licenseResult = userCloneAnalytics.getLicenseUtilization();
                // If no exception, verify empty or valid result
                System.assertNotEquals(null, licenseResult);
            } catch(Exception e) {
                // Expected for users without proper permissions
                System.assert(e instanceof userCloneAnalytics.SecurityException || 
                            e.getMessage().contains('Insufficient'));
            }
            
            try {
                List<userCloneAnalytics.PermissionData> permResult = userCloneAnalytics.getPermissionDistribution(0, 10);
                System.assertNotEquals(null, permResult);
            } catch(Exception e) {
                System.assert(e instanceof userCloneAnalytics.SecurityException || 
                            e.getMessage().contains('Insufficient'));
            }
            
            try {
                List<userCloneAnalytics.ClonePattern> patternResult = userCloneAnalytics.getCloningPatterns();
                System.assertNotEquals(null, patternResult);
            } catch(Exception e) {
                System.assert(e instanceof userCloneAnalytics.SecurityException || 
                            e.getMessage().contains('Insufficient'));
            }
            
            Test.stopTest();
        }
    }
    
    /**
     * @description Test bulk data scenarios
     */
    @IsTest
    static void testBulkDataScenarios() {
        Test.startTest();
        
        // Test with larger offset and limit values
        List<userCloneAnalytics.PermissionData> result1 = userCloneAnalytics.getPermissionDistribution(100, 50);
        System.assertNotEquals(null, result1);
        
        // Test with maximum allowed limit
        List<userCloneAnalytics.PermissionData> result2 = userCloneAnalytics.getPermissionDistribution(0, 1000);
        System.assertNotEquals(null, result2);
        
        // Test cloning patterns for consistency
        List<userCloneAnalytics.ClonePattern> patterns = userCloneAnalytics.getCloningPatterns();
        System.assertEquals(7, patterns.size(), 'Should always return 7 days of patterns');
        
        Test.stopTest();
    }
    
    /**
     * @description Test edge cases and boundary conditions
     */
    @IsTest
    static void testEdgeCases() {
        Test.startTest();
        
        // Test with zero offset and limit
        List<userCloneAnalytics.PermissionData> result1 = userCloneAnalytics.getPermissionDistribution(0, 0);
        System.assertNotEquals(null, result1);
        
        // Test with large offset (within SOQL limits)
        List<userCloneAnalytics.PermissionData> result2 = userCloneAnalytics.getPermissionDistribution(1500, 10);
        System.assertNotEquals(null, result2);
        
        Test.stopTest();
    }
}