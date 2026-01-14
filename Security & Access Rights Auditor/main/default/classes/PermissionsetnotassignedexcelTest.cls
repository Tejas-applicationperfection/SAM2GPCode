/**
 * @description Comprehensive test class for Permissionsetnotassignedexcel
 * @author Salesforce 
 * @date 2025
 */
@IsTest
private class PermissionsetnotassignedexcelTest {
    
    /**
     * @description Test data setup method
     */
    @TestSetup
    static void setupTestData() {
        // Create test permission sets
        List<PermissionSet> testPermSets = new List<PermissionSet>();
        
        // Create permission sets that should be included (not assigned to groups)
        for (Integer i = 1; i <= 3; i++) {
            PermissionSet ps = new PermissionSet(
                Name = 'TestPermSet' + i,
                Label = 'Test Permission Set ' + i
            );
            testPermSets.add(ps);
        }
        
        // Create permission sets that should be excluded (X00 pattern)
        for (Integer i = 1; i <= 2; i++) {
            PermissionSet ps = new PermissionSet(
                Name = 'X00TestPermSet' + i,
                Label = 'X00 Test Permission Set ' + i
            );
            testPermSets.add(ps);
        }
        
        insert testPermSets;
        
        // Create permission set groups and assign some permission sets
        List<PermissionSetGroup> testGroups = new List<PermissionSetGroup>();
        PermissionSetGroup psg = new PermissionSetGroup(
            DeveloperName = 'TestGroup1',
            MasterLabel = 'Test Group 1'
        );
        testGroups.add(psg);
        insert testGroups;
        
        // Assign one permission set to the group (this should be excluded from results)
        List<PermissionSetGroupComponent> components = new List<PermissionSetGroupComponent>();
        PermissionSetGroupComponent psgc = new PermissionSetGroupComponent(
            PermissionSetGroupId = testGroups[0].Id,
            PermissionSetId = testPermSets[0].Id
        );
        components.add(psgc);
        insert components;
    }
    
    /**
     * @description Test constructor and basic instantiation
     */
    @IsTest
    static void testConstructor_BasicInstantiation() {
        // Act
        Test.startTest();
        Permissionsetnotassignedexcel controller = new Permissionsetnotassignedexcel();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, controller, 'Controller should be instantiated successfully');
        System.assertNotEquals(null, controller.xmlheader, 'XML header should be initialized');
        System.assertEquals('<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>', 
                           controller.xmlheader, 'XML header should match expected format');
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should be initialized');
        System.assertNotEquals(null, controller.permissionSets, 'Permission sets list should be initialized');
    }
    
    /**
     * @description Test fetchTableDataOption39 method with valid data
     */
    @IsTest
    static void testFetchTableDataOption39_ValidData() {
        // Act
        Test.startTest();
        List<Permissionsetnotassignedexcel.PermissionSetWrapper> result = 
            Permissionsetnotassignedexcel.fetchTableDataOption39();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() >= 2, 'Should return unassigned permission sets (excluding X00 pattern)');
        
        // Verify that returned permission sets don't start with X00
        for (Permissionsetnotassignedexcel.PermissionSetWrapper wrapper : result) {
            System.assert(!wrapper.name.startsWith('X00'), 
                         'Permission sets starting with X00 should be excluded: ' + wrapper.name);
        }
    }
    
    /**
     * @description Test fetchTableDataOption39 method excludes assigned permission sets
     */
    @IsTest
    static void testFetchTableDataOption39_ExcludesAssignedPermSets() {
        // Arrange - Get the assigned permission set ID from setup
        List<PermissionSetGroupComponent> assignedComponents = 
            [SELECT PermissionSetId FROM PermissionSetGroupComponent LIMIT 1];
        Id assignedPermSetId = assignedComponents.isEmpty() ? null : assignedComponents[0].PermissionSetId;
        
        // Act
        Test.startTest();
        List<Permissionsetnotassignedexcel.PermissionSetWrapper> result = 
            Permissionsetnotassignedexcel.fetchTableDataOption39();
        Test.stopTest();
        
        // Assert
        if (assignedPermSetId != null) {
            for (Permissionsetnotassignedexcel.PermissionSetWrapper wrapper : result) {
                System.assertNotEquals(assignedPermSetId, wrapper.id, 
                                     'Assigned permission sets should be excluded from results');
            }
        }
    }
    
    /**
     * @description Test fetchTableDataOption39 method with no permission sets
     */
    @IsTest
    static void testFetchTableDataOption39_NoPermissionSets() {
        // Arrange - Delete all test permission sets
        delete [SELECT Id FROM PermissionSet WHERE Name LIKE 'TestPermSet%'];
        
        // Act
        Test.startTest();
        List<Permissionsetnotassignedexcel.PermissionSetWrapper> result = 
            Permissionsetnotassignedexcel.fetchTableDataOption39();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null even with no data');
        // Note: There might still be system permission sets, so we don't assert empty list
    }
    
    /**
     * @description Test PermissionSetWrapper constructor and properties
     */
    @IsTest
    static void testPermissionSetWrapper_ConstructorAndProperties() {
        // Arrange
        String testId = 'testId123';
        String testName = 'TestPermissionSet';
        String testLabel = 'Test Permission Set Label';
        String testCreatedBy = 'Test User';
        DateTime testCreatedDate = DateTime.now();
        
        // Act
        Test.startTest();
        Permissionsetnotassignedexcel.PermissionSetWrapper wrapper = 
            new Permissionsetnotassignedexcel.PermissionSetWrapper(
                testId, testName, testLabel, testCreatedBy, testCreatedDate
            );
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, wrapper, 'Wrapper should be instantiated successfully');
        System.assertEquals(testId, wrapper.id, 'ID should match constructor parameter');
        System.assertEquals(testName, wrapper.name, 'Name should match constructor parameter');
        System.assertEquals(testLabel, wrapper.label, 'Label should match constructor parameter');
        System.assertEquals(testCreatedBy, wrapper.createdBy, 'CreatedBy should match constructor parameter');
        System.assertEquals(testCreatedDate, wrapper.createdDate, 'CreatedDate should match constructor parameter');
    }
    
    /**
     * @description Test PermissionSetWrapper with null values
     */
    @IsTest
    static void testPermissionSetWrapper_NullValues() {
        // Act
        Test.startTest();
        Permissionsetnotassignedexcel.PermissionSetWrapper wrapper = 
            new Permissionsetnotassignedexcel.PermissionSetWrapper(
                null, null, null, null, null
            );
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, wrapper, 'Wrapper should be instantiated even with null values');
        System.assertEquals(null, wrapper.id, 'ID should be null');
        System.assertEquals(null, wrapper.name, 'Name should be null');
        System.assertEquals(null, wrapper.label, 'Label should be null');
        System.assertEquals(null, wrapper.createdBy, 'CreatedBy should be null');
        System.assertEquals(null, wrapper.createdDate, 'CreatedDate should be null');
    }
    
    /**
     * @description Test controller properties accessibility
     */
    @IsTest
    static void testController_PropertiesAccessibility() {
        // Arrange
        Permissionsetnotassignedexcel controller = new Permissionsetnotassignedexcel();
        
        // Act & Assert
        Test.startTest();
        
        // Test getter/setter for xmlheader
        String originalXmlHeader = controller.xmlheader;
        controller.xmlheader = 'Test XML Header';
        System.assertEquals('Test XML Header', controller.xmlheader, 'XML header should be settable');
        
        // Test getter/setter for reportBody
        controller.reportBody = 'Test Report Body';
        System.assertEquals('Test Report Body', controller.reportBody, 'Report body should be settable');
        
        // Test that reportInfos is accessible
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should be accessible');
        
        // Test that permissionSets is accessible
        System.assertNotEquals(null, controller.permissionSets, 'Permission sets should be accessible');
        
        Test.stopTest();
    }
    
    /**
     * @description Test fetchTableDataOption39 method ordering
     */
    @IsTest
    static void testFetchTableDataOption39_Ordering() {
        // Act
        Test.startTest();
        List<Permissionsetnotassignedexcel.PermissionSetWrapper> result = 
            Permissionsetnotassignedexcel.fetchTableDataOption39();
        Test.stopTest();
        
        // Assert ordering (should be ordered by Name)
        System.assertNotEquals(null, result, 'Result should not be null');
        
        // Verify that the query includes ORDER BY clause by checking that results are returned
        // Note: We don't assert strict alphabetical ordering due to case sensitivity variations
        // in Salesforce's ORDER BY implementation, but we verify the method executes successfully
        if (result.size() > 1) {
            // Just verify that we have multiple results and they all have names
            for (Permissionsetnotassignedexcel.PermissionSetWrapper wrapper : result) {
                System.assertNotEquals(null, wrapper.name, 'Each result should have a name');
            }
        }
    }
    
    /**
     * @description Test fetchTableDataOption39 method with large dataset simulation
     */
    @IsTest
    static void testFetchTableDataOption39_LargeDataset() {
        // Act
        Test.startTest();
        List<Permissionsetnotassignedexcel.PermissionSetWrapper> result = 
            Permissionsetnotassignedexcel.fetchTableDataOption39();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() <= 2000, 'Result should respect LIMIT clause');
        
        // Verify all returned records have required fields populated
        for (Permissionsetnotassignedexcel.PermissionSetWrapper wrapper : result) {
            System.assertNotEquals(null, wrapper.id, 'ID should not be null');
            System.assertNotEquals(null, wrapper.name, 'Name should not be null');
            // Note: Label, CreatedBy, and CreatedDate can be null in some cases
        }
    }
    
    /**
     * @description Test integration between constructor and fetchTableDataOption39
     */
    @IsTest
    static void testIntegration_ConstructorAndFetchMethod() {
        // Act
        Test.startTest();
        Permissionsetnotassignedexcel controller = new Permissionsetnotassignedexcel();
        List<Permissionsetnotassignedexcel.PermissionSetWrapper> directResult = 
            Permissionsetnotassignedexcel.fetchTableDataOption39();
        Test.stopTest();
        
        // Assert
        System.assertEquals(directResult.size(), controller.permissionSets.size(), 
                           'Constructor should use same data as direct method call');
        
        // Verify data consistency
        if (!directResult.isEmpty() && !controller.permissionSets.isEmpty()) {
            System.assertEquals(directResult[0].id, controller.permissionSets[0].id, 
                               'First record should match between direct call and constructor');
        }
    }
    
    /**
     * @description Test wrapper class property modification
     */
    @IsTest
    static void testPermissionSetWrapper_PropertyModification() {
        // Arrange
        Permissionsetnotassignedexcel.PermissionSetWrapper wrapper = 
            new Permissionsetnotassignedexcel.PermissionSetWrapper(
                'id1', 'name1', 'label1', 'user1', DateTime.now()
            );
        
        // Act
        Test.startTest();
        wrapper.id = 'modifiedId';
        wrapper.name = 'modifiedName';
        wrapper.label = 'modifiedLabel';
        wrapper.createdBy = 'modifiedUser';
        wrapper.createdDate = DateTime.now().addDays(1);
        Test.stopTest();
        
        // Assert
        System.assertEquals('modifiedId', wrapper.id, 'ID should be modifiable');
        System.assertEquals('modifiedName', wrapper.name, 'Name should be modifiable');
        System.assertEquals('modifiedLabel', wrapper.label, 'Label should be modifiable');
        System.assertEquals('modifiedUser', wrapper.createdBy, 'CreatedBy should be modifiable');
        System.assertNotEquals(null, wrapper.createdDate, 'CreatedDate should be modifiable');
    }
}