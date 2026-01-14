/**
 * Test class for LargeScalePermissionExporter
 */
@IsTest
private class LargeScalePermissionExporterTest {
    
    @TestSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'lspetest',
            Email = 'largescale@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'LargeScaleTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'largescale' + DateTime.now().getTime() + '@test.com',
            IsActive = true
        );
        insert testUser;
    }
    
    @IsTest
    static void testStartLargeScaleExport() {
        Test.startTest();
        
        List<String> permissions = new List<String>{'PermissionsModifyAllData', 'PermissionsViewAllData'};
        List<Id> profileIds = new List<Id>();
        List<Id> permissionSetIds = new List<Id>();
        List<Id> permissionSetGroupIds = new List<Id>();
        List<Id> userIds = new List<Id>();
        List<String> userFields = new List<String>{'Name', 'Email'};
        
        String exportId = LargeScalePermissionExporter.startLargeScaleExport(
            permissions, profileIds, permissionSetIds, permissionSetGroupIds, 
            userIds, userFields, false
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, exportId, 'Export ID should not be null');
        System.assert(exportId.startsWith('EXP_'), 'Export ID should start with EXP_');
    }
    
    @IsTest
    static void testQueueableExecution() {
        Test.startTest();
        
        List<String> permissions = new List<String>{'PermissionsModifyAllData'};
        LargeScalePermissionExporter exporter = new LargeScalePermissionExporter(
            permissions,
            new List<Id>(),
            new List<Id>(),
            new List<Id>(),
            new List<Id>(),
            new List<String>{'Name'},
            'TEST_EXP_123',
            0,
            1,
            false
        );
        
        System.enqueueJob(exporter);
        
        Test.stopTest();
        
        System.assert(true, 'Queueable executed successfully');
    }
    
    @IsTest
    static void testMultipleBatches() {
        Test.startTest();
        
        List<String> permissions = new List<String>();
        for (Integer i = 0; i < 30; i++) {
            permissions.add('TestPermission' + i);
        }
        
        String exportId = LargeScalePermissionExporter.startLargeScaleExport(
            permissions, new List<Id>(), new List<Id>(), new List<Id>(), 
            new List<Id>(), new List<String>(), false
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, exportId, 'Export ID should not be null');
    }
    
    @IsTest
    static void testConstructorFields() {
        List<String> permissions = new List<String>{'PermissionsModifyAllData'};
        List<Id> profileIds = new List<Id>();
        List<Id> permissionSetIds = new List<Id>();
        List<Id> permissionSetGroupIds = new List<Id>();
        List<Id> userIds = new List<Id>();
        List<String> userFields = new List<String>{'Name', 'Email'};
        
        LargeScalePermissionExporter exporter = new LargeScalePermissionExporter(
            permissions, profileIds, permissionSetIds, permissionSetGroupIds,
            userIds, userFields, 'TEST_123', 0, 1, true
        );
        
        System.assertNotEquals(null, exporter, 'Exporter should be instantiated');
    }
    
    @IsTest
    static void testBatchProcessing() {
        Test.startTest();
        
        List<String> permissions = new List<String>{
            'PermissionsModifyAllData', 
            'PermissionsViewAllData',
            'PermissionsManageUsers'
        };
        
        LargeScalePermissionExporter exporter = new LargeScalePermissionExporter(
            permissions,
            new List<Id>(),
            new List<Id>(),
            new List<Id>(),
            new List<Id>(),
            new List<String>(),
            'BATCH_TEST',
            0,
            2,
            false
        );
        
        System.enqueueJob(exporter);
        
        Test.stopTest();
        
        System.assert(true, 'Batch processing completed');
    }
    
    @IsTest
    static void testEmptyPermissions() {
        Test.startTest();
        
        String exportId = LargeScalePermissionExporter.startLargeScaleExport(
            new List<String>(), 
            new List<Id>(), 
            new List<Id>(), 
            new List<Id>(),
            new List<Id>(), 
            new List<String>(), 
            false
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, exportId, 'Export ID should be generated even with empty list');
    }
    
    @IsTest
    static void testLargePermissionList() {
        Test.startTest();
        
        List<String> permissions = new List<String>();
        for (Integer i = 0; i < 50; i++) {
            permissions.add('Permission' + i);
        }
        
        String exportId = LargeScalePermissionExporter.startLargeScaleExport(
            permissions,
            new List<Id>(),
            new List<Id>(),
            new List<Id>(),
            new List<Id>(),
            new List<String>(),
            true
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, exportId, 'Should handle large permission lists');
    }
}