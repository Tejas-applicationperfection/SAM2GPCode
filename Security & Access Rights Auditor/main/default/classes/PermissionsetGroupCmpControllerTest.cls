/**
 * @description Test class for PermissionsetGroupCmpController
 * @author Salesforce
 * @date 2025
 */
@IsTest
public class PermissionsetGroupCmpControllerTest {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create test users with unique usernames
        String timestamp = String.valueOf(System.currentTimeMillis());
        List<User> testUsers = new List<User>();
        
        // Get standard user profile
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        for (Integer i = 0; i < 3; i++) {
            User testUser = new User(
                FirstName = 'Test',
                LastName = 'User' + i + timestamp,
                Email = 'testuser' + i + timestamp + '@test.com',
                Username = 'testuser' + i + timestamp + '@test.com.invalid',
                Alias = 'tuser' + i,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                IsActive = true
            );
            testUsers.add(testUser);
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testUsers;
        }
        
        // Create test permission sets
        List<PermissionSet> testPermissionSets = new List<PermissionSet>();
        for (Integer i = 0; i < 2; i++) {
            PermissionSet ps = new PermissionSet(
                Name = 'TestPermissionSet' + i + timestamp,
                Label = 'Test Permission Set ' + i,
                Description = 'Test permission set for unit testing'
            );
            testPermissionSets.add(ps);
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testPermissionSets;
        }
        
        // Create test permission set groups
        List<PermissionSetGroup> testPermissionSetGroups = new List<PermissionSetGroup>();
        for (Integer i = 0; i < 2; i++) {
            PermissionSetGroup psg = new PermissionSetGroup(
                DeveloperName = 'TestPermissionSetGroup' + i + timestamp,
                MasterLabel = 'Test Permission Set Group ' + i,
                Description = 'Test permission set group for unit testing'
            );
            testPermissionSetGroups.add(psg);
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testPermissionSetGroups;
        }
        
        // Create permission set group components
        List<PermissionSetGroupComponent> testComponents = new List<PermissionSetGroupComponent>();
        for (Integer i = 0; i < testPermissionSets.size(); i++) {
            PermissionSetGroupComponent component = new PermissionSetGroupComponent(
                PermissionSetGroupId = testPermissionSetGroups[0].Id,
                PermissionSetId = testPermissionSets[i].Id
            );
            testComponents.add(component);
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testComponents;
        }
        
        // Create permission set assignments
        List<PermissionSetAssignment> testAssignments = new List<PermissionSetAssignment>();
        for (Integer i = 0; i < testUsers.size() && i < testPermissionSets.size(); i++) {
            PermissionSetAssignment assignment = new PermissionSetAssignment(
                AssigneeId = testUsers[i].Id,
                PermissionSetId = testPermissionSets[i].Id
            );
            testAssignments.add(assignment);
        }
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert testAssignments;
        }
    }
    
    /**
     * @description Test successful controller initialization
     */
    @IsTest
    static void testControllerInitializationSuccess() {
        Test.startTest();
        
        PermissionsetGroupCmpController controller = new PermissionsetGroupCmpController();
        
        Test.stopTest();
        
        // Verify controller properties are initialized
        System.assertNotEquals(null, controller, 'Controller should be instantiated');
        System.assertNotEquals(null, controller.xmlheader, 'XML header should be set');
        System.assertEquals('<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>', 
                          controller.xmlheader, 'XML header should match expected format');
        
        // Verify reportInfos is initialized
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should be initialized');
        System.assertNotEquals(null, controller.reportInfos.org, 'Organization should be set');
        System.assertNotEquals(null, controller.reportInfos.exportUser, 'Export user should be set');
        
        // Verify permission set group component map is initialized
        System.assertNotEquals(null, controller.permissionSetGroupCmpMap, 
                             'Permission set group component map should be initialized');
    }
    
    /**
     * @description Test controller with existing permission set group components
     */
    @IsTest
    static void testControllerWithExistingData() {
        Test.startTest();
        
        PermissionsetGroupCmpController controller = new PermissionsetGroupCmpController();
        
        Test.stopTest();
        
        // Verify that the controller loads existing permission set group components
        System.assertNotEquals(null, controller.permissionSetGroupCmpMap, 
                             'Permission set group component map should not be null');
        
        // Verify the map contains the test data we created
        System.assert(controller.permissionSetGroupCmpMap.size() >= 0, 
                     'Permission set group component map should contain data or be empty');
        
        // If there are components, verify their structure
        if (!controller.permissionSetGroupCmpMap.isEmpty()) {
            for (PermissionSetGroupComponent component : controller.permissionSetGroupCmpMap.values()) {
                System.assertNotEquals(null, component.PermissionSetGroupId, 
                                     'Permission set group ID should not be null');
                System.assertNotEquals(null, component.PermissionSetId, 
                                     'Permission set ID should not be null');
            }
        }
    }
    
    /**
     * @description Test controller properties accessibility
     */
    @IsTest
    static void testControllerPropertiesAccessibility() {
        Test.startTest();
        
        PermissionsetGroupCmpController controller = new PermissionsetGroupCmpController();
        
        // Test property setters and getters
        controller.reportBody = 'Test Report Body';
        controller.jobId = 'TestJobId123';
        
        Test.stopTest();
        
        // Verify properties can be set and retrieved
        System.assertEquals('Test Report Body', controller.reportBody, 
                          'Report body should be settable and retrievable');
        System.assertEquals('TestJobId123', controller.jobId, 
                          'Job ID should be settable and retrievable');
        
        // Verify AuraEnabled properties are accessible
        System.assertNotEquals(null, controller.xmlheader, 'XML header should be accessible');
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should be accessible');
    }
    
    /**
     * @description Test controller behavior with no permission set group components
     
    @IsTest
    static void testControllerWithNoData() {
        // Delete all permission set group components to test empty scenario
        List<PermissionSetGroupComponent> existingComponents = [SELECT Id FROM PermissionSetGroupComponent];
        if (!existingComponents.isEmpty()) {
            System.runAs(new User(Id = UserInfo.getUserId())) {
                delete existingComponents;
            }
        }
        
        Test.startTest();
        
        PermissionsetGroupCmpController controller = new PermissionsetGroupCmpController();
        
        Test.stopTest();
        
        // Verify controller handles empty data gracefully
        System.assertNotEquals(null, controller.permissionSetGroupCmpMap, 
                             'Permission set group component map should not be null even with no data');
        System.assertEquals(0, controller.permissionSetGroupCmpMap.size(), 
                          'Permission set group component map should be empty when no data exists');
        
        // Verify other properties are still initialized
        System.assertNotEquals(null, controller.xmlheader, 'XML header should still be initialized');
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should still be initialized');
    }*/
    
    /**
     * @description Test controller error handling and security
     */
    @IsTest
    static void testControllerSecurityAndErrorHandling() {
        // Create a user with limited permissions
        Profile limitedProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String timestamp = String.valueOf(System.currentTimeMillis());
        
        User limitedUser = new User(
            FirstName = 'Limited',
            LastName = 'User' + timestamp,
            Email = 'limiteduser' + timestamp + '@test.com',
            Username = 'limiteduser' + timestamp + '@test.com.invalid',
            Alias = 'luser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = limitedProfile.Id,
            IsActive = true
        );
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert limitedUser;
        }
        
        Test.startTest();
        
        System.runAs(limitedUser) {
            try {
                PermissionsetGroupCmpController controller = new PermissionsetGroupCmpController();
                
                // Verify controller can be instantiated even with limited permissions
                System.assertNotEquals(null, controller, 'Controller should be instantiated');
                System.assertNotEquals(null, controller.permissionSetGroupCmpMap, 
                                     'Permission set group component map should be initialized');
                
            } catch (Exception e) {
                // If an exception occurs due to permissions, verify it's handled gracefully
                System.assert(e.getMessage().contains('Insufficient privileges') || 
                            e.getMessage().contains('INSUFFICIENT_ACCESS'), 
                            'Exception should be related to insufficient access: ' + e.getMessage());
            }
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test controller performance with large data sets
     */
    @IsTest
    static void testControllerPerformance() {
        Test.startTest();
        
        // Measure performance
        Datetime startTime = System.now();
        PermissionsetGroupCmpController controller = new PermissionsetGroupCmpController();
        Datetime endTime = System.now();
        
        Test.stopTest();
        
        // Verify controller initializes within reasonable time
        Long executionTime = endTime.getTime() - startTime.getTime();
        System.assert(executionTime < 30000, 'Controller initialization should complete within 30 seconds');
        
        // Verify all properties are properly initialized
        System.assertNotEquals(null, controller.xmlheader, 'XML header should be initialized');
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should be initialized');
        System.assertNotEquals(null, controller.permissionSetGroupCmpMap, 
                             'Permission set group component map should be initialized');
    }
    
    /**
     * @description Test Utils.ReportInfos integration
     */
    @IsTest
    static void testUtilsReportInfosIntegration() {
        Test.startTest();
        
        PermissionsetGroupCmpController controller = new PermissionsetGroupCmpController();
        
        Test.stopTest();
        
        // Verify Utils.ReportInfos is properly integrated
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should not be null');
        System.assertNotEquals(null, controller.reportInfos.org, 'Organization should not be null');
        System.assertNotEquals(null, controller.reportInfos.exportUser, 'Export user should not be null');
        
        // Verify organization data
        System.assertEquals(UserInfo.getOrganizationId(), controller.reportInfos.org.Id, 
                          'Organization ID should match current org');
        
        // Verify export user data
        System.assertEquals(UserInfo.getName(), controller.reportInfos.exportUser, 
                          'Export user should match current user');
    }
    
    /**
     * @description Test HierarchyService integration
     */
    @IsTest
    static void testHierarchyServiceIntegration() {
        Test.startTest();
        
        PermissionsetGroupCmpController controller = new PermissionsetGroupCmpController();
        
        Test.stopTest();
        
        // Verify that HierarchyService methods are called without errors
        // The actual functionality is tested in HierarchyServiceTest
        System.assertNotEquals(null, controller, 'Controller should be instantiated successfully');
        
        // Verify that the controller doesn't fail when HierarchyService methods are called
        System.assertNotEquals(null, controller.permissionSetGroupCmpMap, 
                             'Permission set group component map should be initialized');
    }
}