@isTest
global class PageLayoutAssignmentExcelTest {
// Mock HTTP callout class
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock HTTP response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"records":[]}'); // You can modify this to simulate different responses
            res.setStatusCode(200);
            return res;
        }
    }
      @isTest
    static void testReadProfileLayoutAssignmentsForObject() {
        // Create test data
        List<String> objectNames = new List<String>{'Account', 'Contact'}; // Add any object names you want to test

        // Set up mock HTTP callouts
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Call the method to be tested
        List<PageLayoutAssignmentExcel.layoutWrapper> result = PageLayoutAssignmentExcel.readProfileLayoutAssignmentsForObject(objectNames);

        // Verify the result
        System.assertNotEquals(null, result);
        // Add more assertions based on your requirements
    }


    // Mock the HTTP response for the Tooling API query
    global class MockHttpCallout implements HttpCalloutMock {
        global HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Mock response for Tooling API with layout and profile data
            String responseBody = '{"records":[{"ProfileId":"00e000000000000AAA","Layout":{"Name":"Test Layout"},"RecordTypeId":"012000000000000AAA"}]}';
            res.setBody(responseBody);

            return res;
        }
    }
}