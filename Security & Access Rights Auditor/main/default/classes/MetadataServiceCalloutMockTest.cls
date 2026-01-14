/**
 * @description Comprehensive test class for MetadataServiceCalloutMock
 * @author Salesforce  
 * @date 2025
 */
@IsTest
private class MetadataServiceCalloutMockTest {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        // No specific test data setup required for this mock class
        // as it deals with HTTP callout mocking
    }
    
    /**
     * @description Test constructor with valid ReadResult
     */
    @IsTest
    static void testConstructor_ValidReadResult() {
        // Arrange
        MetadataService.ReadResult readResult = createTestReadResult();
        
        // Act
        Test.startTest();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, mock, 'Mock should be instantiated');
        // Note: readResult is private, so we test functionality through respond method
        HttpRequest testRequest = createTestHttpRequest();
        HttpResponse response = mock.respond(testRequest);
        System.assertNotEquals(null, response, 'Mock should be functional with valid ReadResult');
    }
    
    /**
     * @description Test constructor with null ReadResult
     */
    @IsTest
    static void testConstructor_NullReadResult() {
        // Act
        Test.startTest();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(null);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, mock, 'Mock should be instantiated even with null ReadResult');
        // Note: readResult is private, so we test functionality through respond method
        HttpRequest testRequest = createTestHttpRequest();
        HttpResponse response = mock.respond(testRequest);
        System.assertNotEquals(null, response, 'Mock should be functional even with null ReadResult');
    }
    
    /**
     * @description Test respond method with valid HTTP request
     */
    @IsTest
    static void testRespond_ValidHttpRequest() {
        // Arrange
        MetadataService.ReadResult readResult = createTestReadResult();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        HttpRequest request = createTestHttpRequest();
        
        // Act
        Test.startTest();
        HttpResponse response = mock.respond(request);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertEquals('application/xml', response.getHeader('Content-Type'), 'Content-Type should be application/xml');
        System.assert(response.getBody().contains('<?xml version="1.0" encoding="UTF-8"?>'), 'Response body should contain XML declaration');
        System.assert(response.getBody().contains('<ReadResult>'), 'Response body should contain ReadResult element');
    }
    
    /**
     * @description Test respond method with null HTTP request
     */
    @IsTest
    static void testRespond_NullHttpRequest() {
        // Arrange
        MetadataService.ReadResult readResult = createTestReadResult();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        
        // Act
        Test.startTest();
        HttpResponse response = mock.respond(null);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null even with null request');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertEquals('application/xml', response.getHeader('Content-Type'), 'Content-Type should be application/xml');
    }
    
    /**
     * @description Test respond method with different HTTP methods
     */
    @IsTest
    static void testRespond_DifferentHttpMethods() {
        // Arrange
        MetadataService.ReadResult readResult = createTestReadResult();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        
        List<String> httpMethods = new List<String>{'GET', 'POST', 'PUT', 'DELETE', 'PATCH'};
        
        // Act & Assert
        Test.startTest();
        for (String method : httpMethods) {
            HttpRequest request = new HttpRequest();
            request.setMethod(method);
            request.setEndpoint('https://test.salesforce.com/services/Soap/m/64.0');
            
            HttpResponse response = mock.respond(request);
            
            System.assertNotEquals(null, response, 'Response should not be null for method: ' + method);
            System.assertEquals(200, response.getStatusCode(), 'Status code should be 200 for method: ' + method);
            System.assertEquals('application/xml', response.getHeader('Content-Type'), 'Content-Type should be application/xml for method: ' + method);
        }
        Test.stopTest();
    }
    
    /**
     * @description Test respond method with empty ReadResult
     */
    @IsTest
    static void testRespond_EmptyReadResult() {
        // Arrange
        MetadataService.ReadResult readResult = new MetadataService.ReadResult();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        HttpRequest request = createTestHttpRequest();
        
        // Act
        Test.startTest();
        HttpResponse response = mock.respond(request);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertEquals('application/xml', response.getHeader('Content-Type'), 'Content-Type should be application/xml');
        System.assert(response.getBody().contains('<ReadResult>'), 'Response body should contain ReadResult element');
    }
    
    /**
     * @description Test respond method with null ReadResult in mock
     */
    @IsTest
    static void testRespond_NullReadResultInMock() {
        // Arrange
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(null);
        HttpRequest request = createTestHttpRequest();
        
        // Act
        Test.startTest();
        HttpResponse response = mock.respond(request);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertEquals('application/xml', response.getHeader('Content-Type'), 'Content-Type should be application/xml');
        System.assert(response.getBody().contains('<ReadResult>'), 'Response body should contain ReadResult element');
    }
    
    /**
     * @description Test serializeReadResult method indirectly through respond
     */
    @IsTest
    static void testSerializeReadResult_IndirectTest() {
        // Arrange
        MetadataService.ReadResult readResult = createTestReadResultWithRecords();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        HttpRequest request = createTestHttpRequest();
        
        // Act
        Test.startTest();
        HttpResponse response = mock.respond(request);
        Test.stopTest();
        
        // Assert
        String responseBody = response.getBody();
        System.assert(responseBody.contains('<?xml version="1.0" encoding="UTF-8"?>'), 'Response should contain XML declaration');
        System.assert(responseBody.contains('<ReadResult>'), 'Response should contain ReadResult opening tag');
        System.assert(responseBody.contains('</ReadResult>'), 'Response should contain ReadResult closing tag');
    }
    
    /**
     * @description Test mock integration with Test.setMock
     */
    @IsTest
    static void testMockIntegration_WithTestSetMock() {
        // Arrange
        MetadataService.ReadResult readResult = createTestReadResult();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        
        // Act
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Simulate a callout that would use this mock
        HttpRequest request = createTestHttpRequest();
        Http http = new Http();
        HttpResponse response = http.send(request);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertEquals('application/xml', response.getHeader('Content-Type'), 'Content-Type should be application/xml');
    }
    
    /**
     * @description Test mock with multiple consecutive requests
     */
    @IsTest
    static void testMock_MultipleConsecutiveRequests() {
        // Arrange
        MetadataService.ReadResult readResult = createTestReadResult();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        Test.setMock(HttpCalloutMock.class, mock);
        
        // Act
        Test.startTest();
        Http http = new Http();
        List<HttpResponse> responses = new List<HttpResponse>();
        
        for (Integer i = 0; i < 3; i++) {
            HttpRequest request = createTestHttpRequest();
            request.setEndpoint('https://test.salesforce.com/services/Soap/m/64.0/' + i);
            responses.add(http.send(request));
        }
        Test.stopTest();
        
        // Assert
        System.assertEquals(3, responses.size(), 'Should have 3 responses');
        for (HttpResponse response : responses) {
            System.assertNotEquals(null, response, 'Each response should not be null');
            System.assertEquals(200, response.getStatusCode(), 'Each status code should be 200');
            System.assertEquals('application/xml', response.getHeader('Content-Type'), 'Each Content-Type should be application/xml');
        }
    }
    
    /**
     * @description Test mock behavior with large ReadResult
     */
    @IsTest
    static void testMock_LargeReadResult() {
        // Arrange
        MetadataService.ReadResult readResult = createLargeTestReadResult();
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        HttpRequest request = createTestHttpRequest();
        
        // Act
        Test.startTest();
        HttpResponse response = mock.respond(request);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, response, 'Response should not be null');
        System.assertEquals(200, response.getStatusCode(), 'Status code should be 200');
        System.assertEquals('application/xml', response.getHeader('Content-Type'), 'Content-Type should be application/xml');
        // Note: The current implementation returns a fixed XML string, so we test for basic XML structure
        System.assert(response.getBody().contains('<?xml'), 'Response body should contain XML declaration');
        System.assert(response.getBody().contains('ReadResult'), 'Response body should contain ReadResult element');
    }
    
    /**
     * @description Test mock accessibility (global class)
     */
    @IsTest
    static void testMock_Accessibility() {
        // Arrange & Act
        Test.startTest();
        MetadataService.ReadResult readResult = createTestReadResult();
        
        // Test that the class can be instantiated (global accessibility)
        MetadataServiceCalloutMock mock = new MetadataServiceCalloutMock(readResult);
        
        // Test that the respond method can be called (global accessibility)
        HttpRequest request = createTestHttpRequest();
        HttpResponse response = mock.respond(request);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, mock, 'Mock should be accessible and instantiable');
        System.assertNotEquals(null, response, 'Respond method should be accessible and callable');
    }
    
    // Helper Methods
    
    /**
     * @description Create a test ReadResult for testing
     * @return MetadataService.ReadResult Test ReadResult instance
     */
    private static MetadataService.ReadResult createTestReadResult() {
        MetadataService.ReadResult readResult = new MetadataService.ReadResult();
        readResult.records = new List<MetadataService.Metadata>();
        return readResult;
    }
    
    /**
     * @description Create a test ReadResult with sample records
     * @return MetadataService.ReadResult Test ReadResult with records
     */
    private static MetadataService.ReadResult createTestReadResultWithRecords() {
        MetadataService.ReadResult readResult = new MetadataService.ReadResult();
        
        // Create sample metadata records
        List<MetadataService.Metadata> records = new List<MetadataService.Metadata>();
        
        // Add a sample metadata record (using base Metadata class)
        MetadataService.Metadata sampleMetadata = new MetadataService.Metadata();
        sampleMetadata.fullName = 'TestMetadata';
        records.add(sampleMetadata);
        
        readResult.records = records;
        return readResult;
    }
    
    /**
     * @description Create a large test ReadResult for performance testing
     * @return MetadataService.ReadResult Large test ReadResult
     */
    private static MetadataService.ReadResult createLargeTestReadResult() {
        MetadataService.ReadResult readResult = new MetadataService.ReadResult();
        
        List<MetadataService.Metadata> records = new List<MetadataService.Metadata>();
        
        // Create multiple metadata records to simulate a large response
        for (Integer i = 0; i < 10; i++) {
            MetadataService.Metadata metadata = new MetadataService.Metadata();
            metadata.fullName = 'TestMetadata' + i;
            records.add(metadata);
        }
        
        readResult.records = records;
        return readResult;
    }
    
    /**
     * @description Create a test HTTP request
     * @return HttpRequest Test HTTP request instance
     */
    private static HttpRequest createTestHttpRequest() {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('https://test.salesforce.com/services/Soap/m/64.0');
        request.setHeader('Content-Type', 'text/xml; charset=UTF-8');
        request.setHeader('SOAPAction', 'read');
        request.setBody('<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"></soap:Envelope>');
        return request;
    }
}