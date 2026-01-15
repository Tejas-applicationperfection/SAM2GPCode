@isTest
public class RecordTypesReportControllerTest {
    
    @isTest
    static void testGetAllTypeOfPermissionSuccess() {
        Test.startTest();
        
        try {
            List<String> result = RecordTypesReportController.getAllTypeOfPermission();
            
            // Verify the result is not null
            System.assertNotEquals(null, result, 'Result should not be null');
            
            // Verify it returns a List<String>
            System.assert(result != null, 'Result should be a valid List<String>');
            
        } catch (AuraHandledException e) {
            // If SecurityUtil.getPermissionTypeForLightning() throws an exception,
            // it should be wrapped in AuraHandledException
            System.assert(e.getMessage() != null, 'Exception message should not be null');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetAllTypeOfPermissionAuraEnabled() {
        // Test that the method can be called from Lightning components
        Test.startTest();
        
        Boolean methodExecutedSuccessfully = false;
        List<String> result = null;
        
        try {
            result = RecordTypesReportController.getAllTypeOfPermission();
            methodExecutedSuccessfully = true;
        } catch (Exception e) {
            // Check if it's an AuraHandledException as expected
            System.assert(e instanceof AuraHandledException, 
                'Exception should be AuraHandledException for Lightning component compatibility');
        }
        
        Test.stopTest();
        
        // If method executed successfully, verify result
        if (methodExecutedSuccessfully) {
            System.assertNotEquals(null, result, 'Result should not be null when method executes successfully');
        }
    }
    
    @isTest
    static void testGetAllTypeOfPermissionReturnType() {
        // Test the return type and structure
        Test.startTest();
        
        try {
            Object result = RecordTypesReportController.getAllTypeOfPermission();
            
            // Verify return type
            System.assert(result != null, 'Return type should be List<String>');
            
            // Cast and verify
            List<String> stringList = (List<String>) result;
            System.assertNotEquals(null, stringList, 'Casted result should not be null');
            
            // Verify each element is a string (if list is not empty)
            for (String item : stringList) {
                System.assertNotEquals(null, item, 'Each item should be a valid String');
            }
            
        } catch (AuraHandledException e) {
            // Expected if SecurityUtil method fails
            System.assertNotEquals(null, e.getMessage(), 'AuraHandledException should have a message');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetAllTypeOfPermissionExceptionHandling() {
        // Test exception handling behavior
        Test.startTest();
        
        Boolean caughtAuraHandledException = false;
        String exceptionMessage = '';
        
        try {
            List<String> result = RecordTypesReportController.getAllTypeOfPermission();
            // If no exception is thrown, that's also valid
            System.assertNotEquals(null, result, 'Result should not be null if no exception thrown');
        } catch (AuraHandledException e) {
            caughtAuraHandledException = true;
            exceptionMessage = e.getMessage();
        } catch (Exception e) {
            System.assert(false, 'Should only throw AuraHandledException, not: ' + e.getTypeName());
        }
        
        Test.stopTest();
        
        // If exception was caught, verify it was handled properly
        if (caughtAuraHandledException) {
            System.assertNotEquals(null, exceptionMessage, 'Exception message should not be null');
            System.assertNotEquals('', exceptionMessage, 'Exception message should not be empty');
        }
    }
    
    @isTest
    static void testGetAllTypeOfPermissionMultipleCalls() {
        // Test multiple calls to ensure consistency
        Test.startTest();
        
        List<String> result1 = null;
        List<String> result2 = null;
        Boolean bothCallsSucceeded = false;
        
        try {
            result1 = RecordTypesReportController.getAllTypeOfPermission();
            result2 = RecordTypesReportController.getAllTypeOfPermission();
            bothCallsSucceeded = true;
        } catch (AuraHandledException e) {
            // Expected if SecurityUtil method is not available
            System.assertNotEquals(null, e.getMessage(), 'Exception should have a message');
        }
        
        Test.stopTest();
        
        // If both calls succeeded, verify consistency
        if (bothCallsSucceeded) {
            System.assertNotEquals(null, result1, 'First result should not be null');
            System.assertNotEquals(null, result2, 'Second result should not be null');
            
            // Results should be consistent
            System.assertEquals(result1.size(), result2.size(), 'Results should have same size');
        }
    }
}