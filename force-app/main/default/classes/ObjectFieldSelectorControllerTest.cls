/**
 * Test class for ObjectFieldSelectorController
 */
@IsTest
private class ObjectFieldSelectorControllerTest {
    
    @IsTest
    static void testGetObjectTypes() {
        Test.startTest();
        
        List<String> objectTypes = ObjectFieldSelectorController.getObjectTypes();
        
        Test.stopTest();
        
        System.assertNotEquals(null, objectTypes, 'Object types should not be null');
        System.assertEquals(2, objectTypes.size(), 'Should return 2 object types');
        System.assert(objectTypes.contains('Organization'), 'Should contain Organization');
        System.assert(objectTypes.contains('Managed'), 'Should contain Managed');
    }
    
    @IsTest
    static void testGetObjectsByType_Organization() {
        Test.startTest();
        
        List<ObjectFieldSelectorController.ObjectInfo> objects = 
            ObjectFieldSelectorController.getObjectsByType('Organization');
        
        Test.stopTest();
        
        System.assertNotEquals(null, objects, 'Objects list should not be null');
        System.assert(objects.size() > 0, 'Should return organization objects');
    }
    
    @IsTest
    static void testGetObjectsByType_Managed() {
        Test.startTest();
        
        List<ObjectFieldSelectorController.ObjectInfo> objects = 
            ObjectFieldSelectorController.getObjectsByType('Managed');
        
        Test.stopTest();
        
        System.assertNotEquals(null, objects, 'Objects list should not be null');
    }
    
    @IsTest
    static void testGetObjectFields_Account() {
        Test.startTest();
        
        List<ObjectFieldSelectorController.FieldInfo> fields = 
            ObjectFieldSelectorController.getObjectFields('Account');
        
        Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Fields list should not be null');
        System.assert(fields.size() > 0, 'Account should have fields');
    }
    
    @IsTest
    static void testGetObjectFields_Contact() {
        Test.startTest();
        
        List<ObjectFieldSelectorController.FieldInfo> fields = 
            ObjectFieldSelectorController.getObjectFields('Contact');
        
        Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Fields list should not be null');
    }
    
    @IsTest
    static void testGetObjectFields_InvalidObject() {
        Test.startTest();
        
        try {
            ObjectFieldSelectorController.getObjectFields('NonExistentObject__c');
            System.assert(false, 'Should throw exception for invalid object');
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Should contain error message');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testObjectInfo_Comparable() {
        ObjectFieldSelectorController.ObjectInfo obj1 = 
            new ObjectFieldSelectorController.ObjectInfo('Account', 'Account');
        ObjectFieldSelectorController.ObjectInfo obj2 = 
            new ObjectFieldSelectorController.ObjectInfo('Contact', 'Contact');
        
        Integer compareResult = obj1.compareTo(obj2);
        
        System.assert(compareResult < 0, 'Account should come before Contact');
    }
    
    @IsTest
    static void testObjectInfo_Equal() {
        ObjectFieldSelectorController.ObjectInfo obj1 = 
            new ObjectFieldSelectorController.ObjectInfo('Account', 'Account');
        ObjectFieldSelectorController.ObjectInfo obj2 = 
            new ObjectFieldSelectorController.ObjectInfo('Account', 'Account');
        
        Integer compareResult = obj1.compareTo(obj2);
        
        System.assertEquals(0, compareResult, 'Equal objects should return 0');
    }
    
    @IsTest
    static void testFieldInfo_Comparable() {
        ObjectFieldSelectorController.FieldInfo field1 = 
            new ObjectFieldSelectorController.FieldInfo();
        field1.label = 'Name';
        
        ObjectFieldSelectorController.FieldInfo field2 = 
            new ObjectFieldSelectorController.FieldInfo();
        field2.label = 'Email';
        
        Integer compareResult = field1.compareTo(field2);
        
        System.assert(compareResult > 0, 'Name should come after Email alphabetically');
    }
    
    @IsTest
    static void testFieldInfo_Properties() {
        ObjectFieldSelectorController.FieldInfo field = 
            new ObjectFieldSelectorController.FieldInfo();
        
        field.name = 'TestField__c';
        field.label = 'Test Field';
        field.type = 'text';
        field.inlineHelpText = 'Help text';
        field.description = 'Description';
        field.isRequired = true;
        field.isActive = 'Active';
        field.dataOwner = 'Test Owner';
        field.dataSensitivityLevel = 'Public';
        field.complianceCategorization = new List<String>{'GDPR', 'HIPAA'};
        
        System.assertEquals('TestField__c', field.name, 'Name should match');
        System.assertEquals(2, field.complianceCategorization.size(), 'Should have 2 compliance groups');
    }
    
    @IsTest
    static void testGetObjectFields_User() {
        Test.startTest();
        
        List<ObjectFieldSelectorController.FieldInfo> fields = 
            ObjectFieldSelectorController.getObjectFields('User');
        
        Test.stopTest();
        
        System.assertNotEquals(null, fields, 'User fields should not be null');
        System.assert(fields.size() > 0, 'User should have accessible fields');
    }
    
    @IsTest
    static void testGetObjectsByType_EmptyString() {
        Test.startTest();
        
        List<ObjectFieldSelectorController.ObjectInfo> objects = 
            ObjectFieldSelectorController.getObjectsByType('');
        
        Test.stopTest();
        
        System.assertNotEquals(null, objects, 'Should return empty list, not null');
    }
    
    @IsTest
    static void testGetObjectFields_Opportunity() {
        Test.startTest();
        
        List<ObjectFieldSelectorController.FieldInfo> fields = 
            ObjectFieldSelectorController.getObjectFields('Opportunity');
        
        Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Opportunity fields should not be null');
    }
}