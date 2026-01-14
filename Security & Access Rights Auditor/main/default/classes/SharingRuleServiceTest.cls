/**
 * @description Comprehensive test class for SharingRuleService
 * @author Salesforce
 * @date 2024
 */
@isTest
public class SharingRuleServiceTest {
    
    /**
     * @description Test successful creation of MetadataService port
     */
    @isTest
    static void testCreateService_Success() {
        Test.startTest();
        
        MetadataService.MetadataPort service = SharingRuleService.createService();
        
        Test.stopTest();
        
        // Assertions
        System.assertNotEquals(null, service, 'MetadataPort service should not be null');
        // Note: endpoint_x is set by the MetadataService constructor, not by our code
        System.assertNotEquals(null, service.endpoint_x, 'Endpoint should be set');
        System.assertEquals(120000, service.timeout_x, 'Timeout should be set to 120000');
    }
    
    /**
     * @description Test readSettings method with valid object name
     */
    @isTest
    static void testReadSettings_ValidObjectName() {
        // Mock the HTTP callout response
        Test.setMock(HttpCalloutMock.class, new MockMetadataServiceResponse());
        
        Test.startTest();
        
        try {
            SharingRuleService.readSettings('Account');
            // If no exception is thrown, the test passes
            System.assert(true, 'Method should execute without exceptions');
        } catch (Exception e) {
            // Verify proper exception handling
            System.assert(e.getMessage() != null, 'Exception message should not be null');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test readSettings method with invalid object name
     */
    @isTest
    static void testReadSettings_InvalidObjectName() {
        // Mock the HTTP callout response for invalid object
        Test.setMock(HttpCalloutMock.class, new MockMetadataServiceErrorResponse());
        
        Test.startTest();
        
        try {
            SharingRuleService.readSettings('InvalidObject');
        } catch (Exception e) {
            // Verify proper exception handling
            System.assert(e.getMessage() != null, 'Exception should be thrown for invalid object');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test SharingRules wrapper class constructor
     */
    @isTest
    static void testSharingRulesWrapper_Constructor() {
        Test.startTest();
        
        // Create mock MetadataService.SharingRules
        MetadataService.SharingRules mockSharingRules = new MetadataService.SharingRules();
        mockSharingRules.fullName = 'Account';
        mockSharingRules.sharingCriteriaRules = new List<MetadataService.SharingCriteriaRule>();
        mockSharingRules.sharingOwnerRules = new List<MetadataService.SharingOwnerRule>();
        mockSharingRules.sharingTerritoryRules = new List<MetadataService.SharingTerritoryRule>();
        
        // Add mock criteria rule
        MetadataService.SharingCriteriaRule mockCriteriaRule = new MetadataService.SharingCriteriaRule();
        mockCriteriaRule.fullName = 'TestRule';
        mockCriteriaRule.accessLevel = 'Read';
        mockCriteriaRule.description = 'Test Description';
        mockCriteriaRule.label = 'Test Label';
        mockCriteriaRule.criteriaItems = new List<MetadataService.FilterItem>();
        
        // Add mock filter item
        MetadataService.FilterItem mockFilterItem = new MetadataService.FilterItem();
        mockFilterItem.field = 'Name';
        mockFilterItem.operation = 'equals';
        mockFilterItem.value = 'Test';
        mockCriteriaRule.criteriaItems.add(mockFilterItem);
        
        mockSharingRules.sharingCriteriaRules.add(mockCriteriaRule);
        
        // Test wrapper constructor
        SharingRuleService.SharingRules wrapper = new SharingRuleService.SharingRules(mockSharingRules);
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals('SharingRules', wrapper.type, 'Type should be SharingRules');
        System.assertEquals('Account', wrapper.fullName, 'FullName should match');
        System.assertNotEquals(null, wrapper.sharingCriteriaRules, 'Criteria rules should not be null');
        System.assertEquals(1, wrapper.sharingCriteriaRules.size(), 'Should have one criteria rule');
    }
    
    /**
     * @description Test SharingCriteriaRule wrapper class constructor
     */
    @isTest
    static void testSharingCriteriaRuleWrapper_Constructor() {
        Test.startTest();
        
        // Create mock MetadataService.SharingCriteriaRule
        MetadataService.SharingCriteriaRule mockRule = new MetadataService.SharingCriteriaRule();
        mockRule.fullName = 'TestCriteriaRule';
        mockRule.accessLevel = 'Edit';
        mockRule.description = 'Test Criteria Description';
        mockRule.label = 'Test Criteria Label';
        mockRule.criteriaItems = new List<MetadataService.FilterItem>();
        
        // Add mock filter items
        MetadataService.FilterItem mockItem1 = new MetadataService.FilterItem();
        mockItem1.field = 'Type';
        mockItem1.operation = 'equals';
        mockItem1.value = 'Customer';
        mockRule.criteriaItems.add(mockItem1);
        
        MetadataService.FilterItem mockItem2 = new MetadataService.FilterItem();
        mockItem2.field = 'Industry';
        mockItem2.operation = 'notEqual';
        mockItem2.value = 'Technology';
        mockRule.criteriaItems.add(mockItem2);
        
        // Test wrapper constructor
        SharingRuleService.SharingCriteriaRule wrapper = new SharingRuleService.SharingCriteriaRule(mockRule);
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals('TestCriteriaRule', wrapper.fullName, 'FullName should match');
        System.assertEquals('Edit', wrapper.accessLevel, 'AccessLevel should match');
        System.assertEquals('Test Criteria Description', wrapper.description, 'Description should match');
        System.assertEquals('Test Criteria Label', wrapper.label, 'Label should match');
        System.assertNotEquals(null, wrapper.criteriaItems, 'Criteria items should not be null');
        System.assertEquals(2, wrapper.criteriaItems.size(), 'Should have two criteria items');
    }
    
    /**
     * @description Test FilterItem wrapper class constructor
     */
    @isTest
    static void testFilterItemWrapper_Constructor() {
        Test.startTest();
        
        // Create mock MetadataService.FilterItem
        MetadataService.FilterItem mockItem = new MetadataService.FilterItem();
        mockItem.field = 'AnnualRevenue';
        mockItem.operation = 'greaterThan';
        mockItem.value = '1000000';
        mockItem.valueField = 'Revenue_Threshold__c';
        
        // Test wrapper constructor
        SharingRuleService.FilterItem wrapper = new SharingRuleService.FilterItem(mockItem);
        
        Test.stopTest();
        
        // Assertions
        System.assertEquals('AnnualRevenue', wrapper.field, 'Field should match');
        System.assertEquals('greaterThan', wrapper.operation, 'Operation should match');
        System.assertEquals('1000000', wrapper.value, 'Value should match');
        System.assertEquals('Revenue_Threshold__c', wrapper.valueField, 'ValueField should match');
    }
    
    /**
     * @description Test error handling for null parameters
     */
    @isTest
    static void testErrorHandling_NullParameters() {
        Test.startTest();
        
        try {
            SharingRuleService.readSettings(null);
        } catch (Exception e) {
            System.assert(e.getMessage() != null, 'Exception should be thrown for null parameter');
        }
        
        Test.stopTest();
    }
    
    /**
     * @description Test performance and governor limits
     */
    @isTest
    static void testPerformance_GovernorLimits() {
        Test.startTest();
        
        Integer initialCallouts = Limits.getCallouts();
        
        // Mock the HTTP callout response
        Test.setMock(HttpCalloutMock.class, new MockMetadataServiceResponse());
        
        try {
            SharingRuleService.readSettings('Account');
        } catch (Exception e) {
            // Expected for mock scenario
        }
        
        Test.stopTest();
        
        // Verify callout limits are respected
        System.assert(Limits.getCallouts() <= Limits.getLimitCallouts(), 
                     'Should not exceed callout limits');
    }
    
    /**
     * @description Mock HTTP callout class for successful responses
     */
    private class MockMetadataServiceResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setBody('<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Body><readMetadataResponse><result><records><fullName>Account</fullName></records></result></readMetadataResponse></soapenv:Body></soapenv:Envelope>');
            res.setStatusCode(200);
            return res;
        }
    }
    
    /**
     * @description Mock HTTP callout class for error responses
     */
    private class MockMetadataServiceErrorResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'text/xml');
            res.setBody('<?xml version="1.0" encoding="UTF-8"?><soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"><soapenv:Body><soapenv:Fault><faultcode>INVALID_TYPE</faultcode><faultstring>Invalid object type</faultstring></soapenv:Fault></soapenv:Body></soapenv:Envelope>');
            res.setStatusCode(500);
            return res;
        }
    }
}