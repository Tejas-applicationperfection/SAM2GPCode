@isTest
public class AuditObjectiveExportToExcelTest {

 

    @isTest
    static void testConvertDataToAuditStepMap() {
        // Test data setup
        List<Map<String, Object>> testAuditReportsData = new List<Map<String, Object>>();
        // Add test data map for SA_Audit__Audit_Step__c
        Map<String, Object> testDataMap = new Map<String, Object>{
            'Name' => 'Test Audit Step',
            'SA_Audit__Template__c' => 'Test Template',
            'ReviewDatee__c' => '2022-01-05',
            'Comments__c' => 'Test Comments'
        };
        testAuditReportsData.add(testDataMap);

        // Mock the call to getAuditReports() in the controller
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        AuditObjectiveController.getAuditReports();

        // Create an instance of the controller
        AuditObjectiveExportToExcelContoller controllerInstance = new AuditObjectiveExportToExcelContoller();
        
        // Call the method to be tested
        Map<String, List<SA_Audit__Audit_Step__c>> result = controllerInstance.convertDataToAuditStepMap(testAuditReportsData);

        // Assertions
        System.assertEquals(1, result.size());
        System.assertEquals('Test Audit Step', result.get('Test Template')[0].Name);
        System.assertEquals('Test Template', result.get('Test Template')[0].Template__c);
        System.assertEquals('2022-01-05', result.get('Test Template')[0].ReviewDatee__c);
        System.assertEquals('Test Comments', result.get('Test Template')[0].Comments__c);

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