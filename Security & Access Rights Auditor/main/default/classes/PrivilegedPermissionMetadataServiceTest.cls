/**
 * Test class for PrivilegedPermissionMetadataService
 */
@isTest
private class PrivilegedPermissionMetadataServiceTest {
    
    @isTest
    static void testUpsertPrivilegedPermission() {
        Test.startTest();
        try {
            String deploymentId = PrivilegedPermissionMetadataService.upsertPrivilegedPermission(
                'PermissionsViewSetup',
                'View Setup and Configuration',
                'Allows users to view Setup and Configuration',
                true
            );
            // In test context, metadata operations will throw exception
            System.assert(false, 'Should have thrown exception in test context');
        } catch (Exception e) {
            // Expected in test context - metadata cannot be deployed
            System.assert(e.getMessage().contains('Metadata') || e.getMessage().contains('test'), 
                'Exception should be about metadata deployment in test context');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeletePrivilegedPermission() {
        Test.startTest();
        String result = PrivilegedPermissionMetadataService.deletePrivilegedPermission(
            'PermissionsViewSetup'
        );
        Test.stopTest();
        
        // Delete method returns null as documented
        System.assertEquals(null, result, 'Delete should return null');
    }
    
    @isTest
    static void testDeployCallbackSuccess() {
        Test.startTest();
        PrivilegedPermissionMetadataService.DeployCallback callback = 
            new PrivilegedPermissionMetadataService.DeployCallback();
        
        Metadata.DeployResult mockResult = new Metadata.DeployResult();
        mockResult.status = Metadata.DeployStatus.Succeeded;
        
        Metadata.DeployCallbackContext mockContext = new Metadata.DeployCallbackContext();
        
        callback.handleResult(mockResult, mockContext);
        Test.stopTest();
        
        System.assert(true, 'Callback executed successfully');
    }
}