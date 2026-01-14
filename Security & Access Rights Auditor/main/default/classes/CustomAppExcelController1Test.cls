@isTest
public class CustomAppExcelController1Test {

    @isTest
    static void testCustomAppExcelController1() {
        // Test data setup
        // You may need to mock certain objects or data depending on your specific requirements.

        // Mock the call to Utils.getReportsInfos() in the controller
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Utils.getReportsInfos();

        // Create an instance of the controller
        CustomAppExcelController1 controllerInstance = new CustomAppExcelController1();

        // Assertions
        System.assertNotEquals(null, controllerInstance.xmlheader);
        System.assertNotEquals(null, controllerInstance.applicationAccessWrapperList);
        // Add more assertions based on your specific logic and requirements.

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