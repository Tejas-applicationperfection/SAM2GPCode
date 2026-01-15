@isTest
public class AuditObjectiveExportToExcelTest2 {
 

    @isTest
    static void testConvertPermissionReviewDataToMap() {
        // Test data setup
        List<AuditObjectiveController.PermissionReviewItem> testPermissionReviewData = new List<AuditObjectiveController.PermissionReviewItem>();
        
        // Add test data for PermissionReviewItem
        AuditObjectiveController.PermissionReviewItem testItem = new AuditObjectiveController.PermissionReviewItem();
        testItem.index = 1;
        testItem.type = 'TestType';
        testItem.Profilecount = 10;
        testItem.Permissioncount = 20;
        // Add other properties...

        testPermissionReviewData.add(testItem);

        // Mock the call to getPermissionReviewData() in the controller
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        AuditObjectiveController.getPermissionReviewData();

        // Create an instance of the controller
        AuditObjectiveExportToExcelContoller2 controllerInstance = new AuditObjectiveExportToExcelContoller2();
        
        // Call the method to be tested
        List<Map<String, Object>> result = controllerInstance.convertPermissionReviewDataToMap(testPermissionReviewData);

        // Assertions
        System.assertEquals(1, result.size());
        System.assertEquals(1, result[0].get('Index'));
        System.assertEquals('TestType', result[0].get('Type'));
        System.assertEquals(10, result[0].get('ProfileCount'));
        System.assertEquals(20, result[0].get('PermissionCount'));
        // Add assertions for other properties...

        Test.stopTest();
    }

    // MockHttpResponseGenerator class to mock the HTTP callout response
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}