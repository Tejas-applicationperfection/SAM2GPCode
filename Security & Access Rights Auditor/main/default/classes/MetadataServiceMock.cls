@isTest
public class MetadataServiceMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest request) {
        // Create a mock response for the readMetadata call
        HTTPResponse response = new HTTPResponse();
        response.setStatusCode(200);
        response.setStatus('OK');

        // Simulate a JSON response that would be returned from the MetadataService
        String jsonResponse = '[{"fields": [{"fullName": "Name", "type": "String"}, {"fullName": "CustomField__c", "type": "String"}]}]';
        response.setBody(jsonResponse);
        
        return response;
    }
}