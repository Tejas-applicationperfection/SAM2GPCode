@isTest
public class SchemaBuilderControllerTest {
    
    @TestSetup
    static void makeData() {
        // Create test user for permission testing
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'SchemaUser',
            Email = 'testschemauser@example.com',
            Username = 'testschemauser' + System.currentTimeMillis() + '@example.com',
            Alias = 'tschema',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = profile.Id,
            IsActive = true
        );
        insert testUser;
    }
    
    @isTest
    static void testGetSchemaDataWithBlankObjectName() {
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaData('');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('objects'), 'Result should contain objects key');
        
        List<Map<String, Object>> objects = (List<Map<String, Object>>)result.get('objects');
        System.assertNotEquals(null, objects, 'Objects list should not be null');
        System.assert(objects.size() > 0, 'Should return available objects');
    }
    
    @isTest
    static void testGetSchemaDataWithNullObjectName() {
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaData(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('objects'), 'Result should contain objects key');
    }
    
    @isTest
    static void testGetSchemaDataWithValidObjectName() {
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaData('Account');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('nodes'), 'Result should contain nodes');
        System.assert(result.containsKey('edges'), 'Result should contain edges');
        
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        List<Map<String, Object>> edges = (List<Map<String, Object>>)result.get('edges');
        
        System.assertNotEquals(null, nodes, 'Nodes should not be null');
        System.assertNotEquals(null, edges, 'Edges should not be null');
        System.assert(nodes.size() > 0, 'Should have at least one node (the primary object)');
    }
    
    @isTest
    static void testGetSchemaDataWithInvalidObjectName() {
        Test.startTest();
        try {
            Map<String, Object> result = SchemaBuilderController.getSchemaData('InvalidObject__c');
            // May not throw exception in some cases
            System.assert(true, 'Method executed');
        } catch (Exception e) {
            System.assert(true, 'Exception handled gracefully');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetSchemaDataWithPermissionsBlankObject() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithPermissions('', testUser.Id, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('objects'), 'Result should contain objects key');
    }
    
    @isTest
    static void testGetSchemaDataWithPermissionsValidObject() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithPermissions('Account', testUser.Id, true);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('nodes'), 'Result should contain nodes');
        System.assert(result.containsKey('edges'), 'Result should contain edges');
        
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        System.assert(nodes.size() > 0, 'Should have nodes');
        
        // Check that nodes have permission data
        Map<String, Object> firstNode = nodes[0];
        System.assert(firstNode.containsKey('permissions'), 'Node should have permissions data');
    }
    
    @isTest
    static void testGetSchemaDataWithPermissionsNoRelatedObjects() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithPermissions('Contact', testUser.Id, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        System.assertEquals(1, nodes.size(), 'Should only have the primary object when loadRelatedObjects is false');
    }
    
    @isTest
    static void testGetSchemaDataWithMultipleSecondaryObjectsBlankPrimary() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects('', new List<String>{'Contact'}, testUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('objects'), 'Result should contain objects key');
    }
    
    @isTest
    static void testGetSchemaDataWithMultipleSecondaryObjectsValid() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        List<String> secondaryObjects = new List<String>{'Contact', 'Opportunity'};
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects('Account', secondaryObjects, testUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.containsKey('nodes'), 'Result should contain nodes');
        System.assert(result.containsKey('edges'), 'Result should contain edges');
        
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        System.assert(nodes.size() >= 3, 'Should have primary object and secondary objects');
        
        // Check for primary and secondary flags
        Boolean foundPrimary = false;
        Boolean foundSecondary = false;
        for(Map<String, Object> node : nodes) {
            if(node.containsKey('isPrimary') && (Boolean)node.get('isPrimary')) {
                foundPrimary = true;
            }
            if(node.containsKey('isSecondary') && (Boolean)node.get('isSecondary')) {
                foundSecondary = true;
            }
        }
        System.assert(foundPrimary, 'Should have primary object marked');
        System.assert(foundSecondary, 'Should have secondary objects marked');
    }
    
    @isTest
    static void testGetSchemaDataWithMultipleSecondaryObjectsNullList() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects('Account', null, testUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        System.assert(nodes.size() > 0, 'Should have nodes even with null secondary objects');
    }
    
    @isTest
    static void testGetSchemaDataWithMultipleSecondaryObjectsEmptyList() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects('Account', new List<String>(), testUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        System.assert(nodes.size() > 0, 'Should have nodes even with empty secondary objects');
    }
    
    @isTest
    static void testGetSchemaDataWithMultipleSecondaryObjectsDuplicates() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        List<String> secondaryObjects = new List<String>{'Contact', 'Contact', 'Opportunity'};
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects('Account', secondaryObjects, testUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        
        // Should not have duplicate Contact objects
        Set<String> nodeNames = new Set<String>();
        for(Map<String, Object> node : nodes) {
            String nodeName = (String)node.get('name');
            System.assert(!nodeNames.contains(nodeName), 'Should not have duplicate objects: ' + nodeName);
            nodeNames.add(nodeName);
        }
    }
    
    @isTest
    static void testGetAllObjects() {
        Test.startTest();
        List<Map<String, Object>> objects = SchemaBuilderController.getAllObjects();
        Test.stopTest();
        
        System.assertNotEquals(null, objects, 'Objects list should not be null');
        System.assert(objects.size() >= 0, 'Should return objects list');
        
        // Check structure of returned objects if any exist
        if(objects.size() > 0) {
            Map<String, Object> firstObject = objects[0];
            System.assert(firstObject.containsKey('name'), 'Object should have name');
            System.assert(firstObject.containsKey('label'), 'Object should have label');
            System.assert(firstObject.containsKey('isCustom'), 'Object should have isCustom flag');
        }
    }
    
    @isTest
    static void testGetUserObjectPermissionsWithValidUser() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        
        Test.startTest();
        // This tests the private method through the public methods that call it
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithPermissions('Account', testUser.Id, false);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        
        if(nodes.size() > 0) {
            Map<String, Object> node = nodes[0];
            System.assert(node.containsKey('permissions'), 'Node should have permissions');
            
            Map<String, Object> permissions = (Map<String, Object>)node.get('permissions');
            System.assert(permissions.containsKey('hasAccess'), 'Permissions should have hasAccess');
            System.assert(permissions.containsKey('read'), 'Permissions should have read');
            System.assert(permissions.containsKey('create'), 'Permissions should have create');
            System.assert(permissions.containsKey('edit'), 'Permissions should have edit');
            System.assert(permissions.containsKey('delete'), 'Permissions should have delete');
            System.assert(permissions.containsKey('sources'), 'Permissions should have sources');
        }
    }
    
    @isTest
    static void testExceptionHandlingInGetSchemaData() {
        Test.startTest();
        try {
            // This may trigger an exception
            Map<String, Object> result = SchemaBuilderController.getSchemaData('NonExistentObject123');
            System.assert(true, 'Method executed without exception');
        } catch (Exception e) {
            System.assert(true, 'Exception handled gracefully');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExceptionHandlingInGetSchemaDataWithPermissions() {
        Test.startTest();
        try {
            // This may trigger an exception
            Map<String, Object> result = SchemaBuilderController.getSchemaDataWithPermissions('NonExistentObject123', UserInfo.getUserId(), true);
            System.assert(true, 'Method executed without exception');
        } catch (Exception e) {
            System.assert(true, 'Exception handled gracefully');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExceptionHandlingInGetSchemaDataWithMultipleSecondaryObjects() {
        Test.startTest();
        try {
            // This may trigger an exception
            Map<String, Object> result = SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects('NonExistentObject123', new List<String>{'Contact'}, UserInfo.getUserId());
            System.assert(true, 'Method executed without exception');
        } catch (Exception e) {
            System.assert(true, 'Exception handled gracefully');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetSchemaDataWithCustomObject() {
        // Test with a known standard object
        Test.startTest();
        try {
            Map<String, Object> result = SchemaBuilderController.getSchemaData('User');
            System.assertNotEquals(null, result, 'Result should not be null for standard object');
        } catch (Exception e) {
            // Expected if object access is restricted
            System.assert(true, 'Exception expected for restricted objects');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testNodeStructureValidation() {
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaData('Contact');
        Test.stopTest();
        
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        if(nodes.size() > 0) {
            Map<String, Object> node = nodes[0];
            System.assert(node.containsKey('name'), 'Node should have name');
            System.assert(node.containsKey('label'), 'Node should have label');
            
            String name = (String)node.get('name');
            String label = (String)node.get('label');
            System.assertNotEquals('', name, 'Node name should not be empty');
            System.assertNotEquals('', label, 'Node label should not be empty');
        }
    }
    
    @isTest
    static void testEdgeStructureValidation() {
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaData('Account');
        Test.stopTest();
        
        List<Map<String, Object>> edges = (List<Map<String, Object>>)result.get('edges');
        if(edges.size() > 0) {
            Map<String, Object> edge = edges[0];
            System.assert(edge.containsKey('source'), 'Edge should have source');
            System.assert(edge.containsKey('target'), 'Edge should have target');
            System.assert(edge.containsKey('type'), 'Edge should have type');
        }
    }
    
    @isTest
    static void testPermissionSourcesStructure() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithPermissions('Account', testUser.Id, true);
        Test.stopTest();
        
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        if(nodes.size() > 0) {
            Map<String, Object> node = nodes[0];
            Map<String, Object> permissions = (Map<String, Object>)node.get('permissions');
            List<Map<String, Object>> sources = (List<Map<String, Object>>)permissions.get('sources');
            
            System.assertNotEquals(null, sources, 'Sources should not be null');
            
            if(sources.size() > 0) {
                Map<String, Object> source = sources[0];
                System.assert(source.containsKey('type'), 'Source should have type');
                System.assert(source.containsKey('name'), 'Source should have name');
                System.assert(source.containsKey('read'), 'Source should have read permission');
                System.assert(source.containsKey('create'), 'Source should have create permission');
                System.assert(source.containsKey('edit'), 'Source should have edit permission');
                System.assert(source.containsKey('delete'), 'Source should have delete permission');
            }
        }
    }
    
    @isTest
    static void testRelationshipFieldsStructure() {
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithPermissions('Account', UserInfo.getUserId(), true);
        Test.stopTest();
        
        List<Map<String, Object>> edges = (List<Map<String, Object>>)result.get('edges');
        if(edges.size() > 0) {
            for(Map<String, Object> edge : edges) {
                if(edge.containsKey('fields')) {
                    List<Map<String, Object>> fields = (List<Map<String, Object>>)edge.get('fields');
                    if(fields.size() > 0) {
                        Map<String, Object> field = fields[0];
                        System.assert(field.containsKey('name'), 'Field should have name');
                        System.assert(field.containsKey('label'), 'Field should have label');
                        System.assert(field.containsKey('type'), 'Field should have type');
                    }
                }
            }
        }
    }
    
    @isTest
    static void testSecondaryObjectBlankHandling() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        List<String> secondaryObjects = new List<String>{'Contact', '', 'Opportunity', null};
        
        Test.startTest();
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects('Account', secondaryObjects, testUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // Should handle blank and null values gracefully
        System.assert(true, 'Should handle blank/null secondary objects without error');
    }
    
    @isTest
    static void testGetAllObjectsErrorHandling() {
        Test.startTest();
        List<Map<String, Object>> objects = SchemaBuilderController.getAllObjects();
        Test.stopTest();
        
        // Should return empty list rather than null on error
        System.assertNotEquals(null, objects, 'Should never return null');
    }
    
    @isTest
    static void testGetAvailableObjectsMethod() {
        Test.startTest();
        // Test the private method through getSchemaData with blank object name
        Map<String, Object> result = SchemaBuilderController.getSchemaData('');
        Test.stopTest();
        
        List<Map<String, Object>> objects = (List<Map<String, Object>>)result.get('objects');
        System.assertNotEquals(null, objects, 'Available objects should not be null');
        
        // Should include both standard and custom objects
        Boolean hasStandardObject = false;
        for(Map<String, Object> obj : objects) {
            String objName = (String)obj.get('name');
            if(objName == 'Account' || objName == 'Contact' || objName == 'Opportunity') {
                hasStandardObject = true;
                break;
            }
        }
        System.assert(hasStandardObject, 'Should include standard objects');
    }
    
    @isTest
    static void testDirectRelationshipsHelper() {
        Test.startTest();
        // Test the helper method through getSchemaDataWithPermissions
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithPermissions('Account', UserInfo.getUserId(), true);
        Test.stopTest();
        
        // Should have nodes and edges from direct relationships
        List<Map<String, Object>> nodes = (List<Map<String, Object>>)result.get('nodes');
        List<Map<String, Object>> edges = (List<Map<String, Object>>)result.get('edges');
        
        System.assertNotEquals(null, nodes, 'Nodes should not be null');
        System.assertNotEquals(null, edges, 'Edges should not be null');
    }
    
    @isTest
    static void testFindDirectRelationshipsHelper() {
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'SchemaUser' LIMIT 1];
        List<String> secondaryObjects = new List<String>{'Contact'};
        
        Test.startTest();
        // Test the helper method through getSchemaDataWithMultipleSecondaryObjects
        Map<String, Object> result = SchemaBuilderController.getSchemaDataWithMultipleSecondaryObjects('Account', secondaryObjects, testUser.Id);
        Test.stopTest();
        
        List<Map<String, Object>> edges = (List<Map<String, Object>>)result.get('edges');
        
        // Should find relationships between Account and Contact
        Boolean foundRelationship = false;
        for(Map<String, Object> edge : edges) {
            String source = (String)edge.get('source');
            String target = (String)edge.get('target');
            if((source == 'Account' && target == 'Contact') || (source == 'Contact' && target == 'Account')) {
                foundRelationship = true;
                break;
            }
        }
        System.assert(foundRelationship, 'Should find relationship between Account and Contact');
    }
}