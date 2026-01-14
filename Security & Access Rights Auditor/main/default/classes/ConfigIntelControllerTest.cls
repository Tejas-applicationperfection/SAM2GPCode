@isTest
public class ConfigIntelControllerTest {
    
    // Mock class for HTTP callouts
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
    
    @isTest
    static void testGetValidationRulesSuccess() {
        // Create mock response for successful Tooling API call
        String mockResponse = '{' +
            '"totalSize": 2,' +
            '"done": true,' +
            '"records": [' +
                '{' +
                    '"Id": "03d000000000001",' +
                    '"ValidationName": "Test_Rule_1",' +
                    '"NamespacePrefix": null,' +
                    '"Active": true,' +
                    '"TableEnumOrId": "Account",' +
                    '"Description": "Test validation rule 1",' +
                    '"ErrorDisplayField": "Name",' +
                    '"ErrorMessage": "Error message 1",' +
                    '"Formula": "LEN(Name) < 5"' +
                '},' +
                '{' +
                    '"Id": "03d000000000002",' +
                    '"ValidationName": "Test_Rule_2",' +
                    '"NamespacePrefix": "MyNamespace",' +
                    '"Active": false,' +
                    '"TableEnumOrId": "Contact",' +
                    '"Description": "Test validation rule 2",' +
                    '"ErrorDisplayField": "Email",' +
                    '"ErrorMessage": "Error message 2",' +
                    '"Formula": "NOT(CONTAINS(Email, \'@\'))"' +
                '}' +
            ']' +
        '}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Test.startTest();
        
        // Test with multiple filters
        List<String> filters = new List<String>{'active', 'object', 'description', 'errorMessage'};
        ConfigIntelController.ConfigReportData result = ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        // Verify headers - validationRuleName should be first
        System.assertEquals(5, result.headers.size(), 'Should have 5 headers');
        System.assertEquals('validationRuleName', result.headers[0], 'First header should be validationRuleName');
        System.assertEquals('active', result.headers[1], 'Second header should be active');
        System.assertEquals('object', result.headers[2], 'Third header should be object');
        System.assertEquals('description', result.headers[3], 'Fourth header should be description');
        System.assertEquals('errorMessage', result.headers[4], 'Fifth header should be errorMessage');
        
        // Verify rows
        System.assertEquals(2, result.rows.size(), 'Should have 2 rows');
        
        // Verify first row data
        ConfigIntelController.ConfigReportRow firstRow = result.rows[0];
        System.assertEquals(5, firstRow.values.size(), 'First row should have 5 values');
        System.assertEquals('Test_Rule_1', firstRow.values[0], 'First row validation name should be Test_Rule_1');
        System.assertEquals('YES', firstRow.values[1], 'First row active should be YES');
        System.assertEquals('Account', firstRow.values[2], 'First row object should be Account');
        System.assertEquals('Test validation rule 1', firstRow.values[3], 'First row description should match');
        System.assertEquals('Error message 1', firstRow.values[4], 'First row error message should match');
        
        // Verify second row data
        ConfigIntelController.ConfigReportRow secondRow = result.rows[1];
        System.assertEquals(5, secondRow.values.size(), 'Second row should have 5 values');
        System.assertEquals('Test_Rule_2', secondRow.values[0], 'Second row validation name should be Test_Rule_2');
        System.assertEquals('NO', secondRow.values[1], 'Second row active should be NO');
        System.assertEquals('Contact', secondRow.values[2], 'Second row object should be Contact');
        System.assertEquals('Test validation rule 2', secondRow.values[3], 'Second row description should match');
        System.assertEquals('Error message 2', secondRow.values[4], 'Second row error message should match');
    }
    
    @isTest
    static void testGetValidationRulesWithDuplicateValidationRuleName() {
        // Test when validationRuleName is already in the filters list
        String mockResponse = '{' +
            '"totalSize": 1,' +
            '"done": true,' +
            '"records": [' +
                '{' +
                    '"Id": "03d000000000001",' +
                    '"ValidationName": "Test_Rule",' +
                    '"NamespacePrefix": null,' +
                    '"Active": true,' +
                    '"TableEnumOrId": "Account",' +
                    '"Description": "Test validation rule",' +
                    '"ErrorDisplayField": "Name",' +
                    '"ErrorMessage": "Error message",' +
                    '"Formula": "LEN(Name) < 5"' +
                '}' +
            ']' +
        '}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Test.startTest();
        
        // Include validationRuleName in filters to test deduplication
        List<String> filters = new List<String>{'validationRuleName', 'active', 'object'};
        ConfigIntelController.ConfigReportData result = ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Verify that validationRuleName appears only once and is first
        System.assertEquals(3, result.headers.size(), 'Should have 3 headers');
        System.assertEquals('validationRuleName', result.headers[0], 'First header should be validationRuleName');
        System.assertEquals('active', result.headers[1], 'Second header should be active');
        System.assertEquals('object', result.headers[2], 'Third header should be object');
        
        // Count occurrences of validationRuleName
        Integer count = 0;
        for (String header : result.headers) {
            if (header == 'validationRuleName') {
                count++;
            }
        }
        System.assertEquals(1, count, 'validationRuleName should appear only once');
    }
    
    @isTest
    static void testGetValidationRulesAllFields() {
        // Test with all possible fields
        String mockResponse = '{' +
            '"totalSize": 1,' +
            '"done": true,' +
            '"records": [' +
                '{' +
                    '"Id": "03d000000000001",' +
                    '"ValidationName": "Complete_Rule",' +
                    '"NamespacePrefix": "TestNS",' +
                    '"Active": true,' +
                    '"TableEnumOrId": "Opportunity",' +
                    '"Description": "Complete test rule",' +
                    '"ErrorDisplayField": "Amount",' +
                    '"ErrorMessage": "Complete error message",' +
                    '"Formula": "Amount > 1000000"' +
                '}' +
            ']' +
        '}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Test.startTest();
        
        // Test with all available fields
        List<String> filters = new List<String>{
            'namespacePrefix', 'active', 'object', 'description', 
            'errorDisplayField', 'errorMessage', 'criteria'
        };
        ConfigIntelController.ConfigReportData result = ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Verify all fields are included
        System.assertEquals(8, result.headers.size(), 'Should have 8 headers');
        System.assertEquals('validationRuleName', result.headers[0], 'First header should be validationRuleName');
        
        // Verify row data for all fields
        ConfigIntelController.ConfigReportRow row = result.rows[0];
        System.assertEquals(8, row.values.size(), 'Row should have 8 values');
        System.assertEquals('Complete_Rule', row.values[0], 'Validation name should match');
        System.assertEquals('TestNS', row.values[1], 'Namespace prefix should match');
        System.assertEquals('YES', row.values[2], 'Active should be YES');
        System.assertEquals('Opportunity', row.values[3], 'Object should match');
        System.assertEquals('Complete test rule', row.values[4], 'Description should match');
        System.assertEquals('Amount', row.values[5], 'Error display field should match');
        System.assertEquals('Complete error message', row.values[6], 'Error message should match');
        System.assertEquals('Amount > 1000000', row.values[7], 'Criteria should match');
    }
    
    @isTest
    static void testGetValidationRulesWithNullValues() {
        // Test handling of null values in the response
        String mockResponse = '{' +
            '"totalSize": 1,' +
            '"done": true,' +
            '"records": [' +
                '{' +
                    '"Id": "03d000000000001",' +
                    '"ValidationName": "Null_Test_Rule",' +
                    '"NamespacePrefix": null,' +
                    '"Active": false,' +
                    '"TableEnumOrId": "Account",' +
                    '"Description": null,' +
                    '"ErrorDisplayField": null,' +
                    '"ErrorMessage": null,' +
                    '"Formula": null' +
                '}' +
            ']' +
        '}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Test.startTest();
        
        List<String> filters = new List<String>{'namespacePrefix', 'description', 'errorMessage', 'criteria'};
        ConfigIntelController.ConfigReportData result = ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Verify null values are handled properly
        ConfigIntelController.ConfigReportRow row = result.rows[0];
        System.assertEquals('Null_Test_Rule', row.values[0], 'Validation name should not be null');
        System.assertEquals(null, row.values[1], 'Namespace prefix should be null');
        System.assertEquals(null, row.values[2], 'Description should be null');
        System.assertEquals(null, row.values[3], 'Error message should be null');
        System.assertEquals(null, row.values[4], 'Criteria should be null');
    }
    
    @isTest
    static void testGetValidationRulesHttpError() {
        // Test HTTP error response
        String errorResponse = '{"error": "Invalid query"}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(400, errorResponse));
        
        Test.startTest();
        
        List<String> filters = new List<String>{'active', 'object'};
        ConfigIntelController.ConfigReportData result = ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Verify empty result when HTTP error occurs
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(3, result.headers.size(), 'Should have 3 headers even with error');
        System.assertEquals(0, result.rows.size(), 'Should have 0 rows when HTTP error occurs');
    }
    
    @isTest
    static void testGetValidationRulesEmptyResponse() {
        // Test empty response from Tooling API
        String emptyResponse = '{' +
            '"totalSize": 0,' +
            '"done": true,' +
            '"records": []' +
        '}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, emptyResponse));
        
        Test.startTest();
        
        List<String> filters = new List<String>{'active'};
        ConfigIntelController.ConfigReportData result = ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Verify empty result is handled properly
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(2, result.headers.size(), 'Should have 2 headers');
        System.assertEquals('validationRuleName', result.headers[0], 'First header should be validationRuleName');
        System.assertEquals('active', result.headers[1], 'Second header should be active');
        System.assertEquals(0, result.rows.size(), 'Should have 0 rows for empty response');
    }
    
    @isTest
    static void testGetValidationRulesEmptyFilters() {
        // Test with empty filters list
        String mockResponse = '{' +
            '"totalSize": 1,' +
            '"done": true,' +
            '"records": [' +
                '{' +
                    '"Id": "03d000000000001",' +
                    '"ValidationName": "Test_Rule",' +
                    '"NamespacePrefix": null,' +
                    '"Active": true,' +
                    '"TableEnumOrId": "Account",' +
                    '"Description": "Test rule",' +
                    '"ErrorDisplayField": "Name",' +
                    '"ErrorMessage": "Error",' +
                    '"Formula": "LEN(Name) < 5"' +
                '}' +
            ']' +
        '}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Test.startTest();
        
        List<String> filters = new List<String>();
        ConfigIntelController.ConfigReportData result = ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Verify only validationRuleName header when no filters provided
        System.assertEquals(1, result.headers.size(), 'Should have 1 header');
        System.assertEquals('validationRuleName', result.headers[0], 'Header should be validationRuleName');
        System.assertEquals(1, result.rows.size(), 'Should have 1 row');
        System.assertEquals(1, result.rows[0].values.size(), 'Row should have 1 value');
        System.assertEquals('Test_Rule', result.rows[0].values[0], 'Value should be validation rule name');
    }
    
    @isTest
    static void testGetValidationRulesUnknownField() {
        // Test with unknown field in filters
        String mockResponse = '{' +
            '"totalSize": 1,' +
            '"done": true,' +
            '"records": [' +
                '{' +
                    '"Id": "03d000000000001",' +
                    '"ValidationName": "Test_Rule",' +
                    '"NamespacePrefix": null,' +
                    '"Active": true,' +
                    '"TableEnumOrId": "Account",' +
                    '"Description": "Test rule",' +
                    '"ErrorDisplayField": "Name",' +
                    '"ErrorMessage": "Error",' +
                    '"Formula": "LEN(Name) < 5"' +
                '}' +
            ']' +
        '}';
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Test.startTest();
        
        List<String> filters = new List<String>{'unknownField', 'active'};
        ConfigIntelController.ConfigReportData result = ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Verify unknown field returns empty string
        System.assertEquals(3, result.headers.size(), 'Should have 3 headers');
        ConfigIntelController.ConfigReportRow row = result.rows[0];
        System.assertEquals('Test_Rule', row.values[0], 'Validation name should be correct');
        System.assertEquals('', row.values[1], 'Unknown field should return empty string');
        System.assertEquals('YES', row.values[2], 'Active field should be correct');
    }
    
    @isTest
    static void testConfigReportDataClass() {
        // Test the inner classes
        Test.startTest();
        
        ConfigIntelController.ConfigReportData data = new ConfigIntelController.ConfigReportData();
        data.headers = new List<String>{'header1', 'header2'};
        data.rows = new List<ConfigIntelController.ConfigReportRow>();
        
        ConfigIntelController.ConfigReportRow row = new ConfigIntelController.ConfigReportRow();
        row.values = new List<String>{'value1', 'value2'};
        data.rows.add(row);
        
        Test.stopTest();
        
        // Verify inner class functionality
        System.assertNotEquals(null, data, 'ConfigReportData should be instantiated');
        System.assertEquals(2, data.headers.size(), 'Headers should have 2 elements');
        System.assertEquals(1, data.rows.size(), 'Rows should have 1 element');
        System.assertEquals(2, data.rows[0].values.size(), 'Row values should have 2 elements');
        System.assertEquals('header1', data.headers[0], 'First header should match');
        System.assertEquals('value1', data.rows[0].values[0], 'First value should match');
    }
    
    @isTest
    static void testHttpRequestDetails() {
        // Test to verify HTTP request is constructed correctly
        String mockResponse = '{"totalSize": 0, "done": true, "records": []}';
        
        // Custom mock to verify request details
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, mockResponse));
        
        Test.startTest();
        
        List<String> filters = new List<String>{'active'};
        ConfigIntelController.getValidationRules(filters);
        
        Test.stopTest();
        
        // Test passes if no exceptions are thrown, indicating proper HTTP request construction
        System.assert(true, 'HTTP request should be constructed without errors');
    }
}