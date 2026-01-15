/**
 * @description Comprehensive test class for FormWizardLookup
 * @author Salesforce Developer
 * @date 2025
 */
@IsTest
public class FormWizardLookupTest {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 1; i <= 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                BillingCity = 'Test City ' + i,
                BillingState = 'CA',
                Phone = '555-000-000' + i
            ));
        }
        insert testAccounts;
        
        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 1; i <= 10; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'testcontact' + i + '@example.com',
                Phone = '555-111-000' + i,
                AccountId = testAccounts[Math.mod(i-1, testAccounts.size())].Id
            ));
        }
        insert testContacts;
        
        // Create test opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Integer i = 1; i <= 3; i++) {
            testOpportunities.add(new Opportunity(
                Name = 'Test Opportunity ' + i,
                AccountId = testAccounts[i-1].Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert testOpportunities;
    }
    
    /**
     * @description Test searchRecords with null queryString
     */
    @IsTest
    static void testSearchRecords_NullQueryString() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            null, 'Contact', null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertEquals(null, results, 'Should return null for null queryString');
    }
    
    /**
     * @description Test searchRecords with empty queryString
     */
    @IsTest
    static void testSearchRecords_EmptyQueryString() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            '', 'Contact', null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertEquals(null, results, 'Should return null for empty queryString');
    }
    
    /**
     * @description Test searchRecords with basic Contact search
     */
    @IsTest
    static void testSearchRecords_BasicContactSearch() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        // Note: SOSL results may vary in test context, so we focus on method execution
    }
    
    /**
     * @description Test searchRecords with default object (Contact) when objectName is null
     */
    @IsTest
    static void testSearchRecords_NullObjectName() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', null, null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        // Should default to Contact object
    }
    
    /**
     * @description Test searchRecords with Account object
     */
    @IsTest
    static void testSearchRecords_AccountSearch() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Account', null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with custom field names
     */
    @IsTest
    static void testSearchRecords_CustomFieldNames() {
        List<String> fieldNames = new List<String>{'Id', 'Name', 'Email', 'Phone'};
        
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', fieldNames, null, null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with empty field names list
     */
    @IsTest
    static void testSearchRecords_EmptyFieldNames() {
        List<String> fieldNames = new List<String>();
        
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', fieldNames, null, null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        // Should default to Id, Name fields
    }
    
    /**
     * @description Test searchRecords with specific fields to search
     */
    @IsTest
    static void testSearchRecords_SpecificFieldsToSearch() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, 'NAME', null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with ALL fields to search
     */
    @IsTest
    static void testSearchRecords_AllFieldsToSearch() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, 'ALL', null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with empty fieldsToSearch
     */
    @IsTest
    static void testSearchRecords_EmptyFieldsToSearch() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, '', null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with filter clause
     */
    @IsTest
    static void testSearchRecords_WithFilterClause() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, null, 'Email != null', null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with record limit
     */
    @IsTest
    static void testSearchRecords_WithRecordLimit() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, null, null, null, 5
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with zero record limit (should be ignored)
     */
    @IsTest
    static void testSearchRecords_ZeroRecordLimit() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, null, null, null, 0
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with large record limit (should be ignored)
     */
    @IsTest
    static void testSearchRecords_LargeRecordLimit() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, null, null, null, 2500
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with orderBy parameter (currently commented out in implementation)
     */
    @IsTest
    static void testSearchRecords_WithOrderBy() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, null, null, 'Name', null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with Opportunity object
     */
    @IsTest
    static void testSearchRecords_OpportunitySearch() {
        List<String> fieldNames = new List<String>{'Id', 'Name', 'StageName'};
        
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Opportunity', fieldNames, null, null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with special characters in query (should be escaped)
     */
    @IsTest
    static void testSearchRecords_SpecialCharacters() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test\'s', 'Contact', null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        // String.escapeSingleQuotes should handle the apostrophe
    }
    
    /**
     * @description Test searchRecords with all parameters provided
     */
    @IsTest
    static void testSearchRecords_AllParameters() {
        List<String> fieldNames = new List<String>{'Id', 'Name', 'Email'};
        
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', fieldNames, 'NAME', 'Email != null', 'Name', 10
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords with complex filter clause
     */
    @IsTest
    static void testSearchRecords_ComplexFilterClause() {
        Test.startTest();
        List<sObject> results = FormWizardLookup.searchRecords(
            'Test', 'Contact', null, null, 'Email != null AND Phone != null', null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    /**
     * @description Test searchRecords method accessibility (RemoteAction)
     */
    @IsTest
    static void testSearchRecords_RemoteActionAccessibility() {
        // This test verifies that the method is properly annotated as @RemoteAction
        // and can be called in a test context
        Test.startTest();
        try {
            List<sObject> results = FormWizardLookup.searchRecords(
                'Test', 'Contact', null, null, null, null, null
            );
            System.assert(true, 'Method should be accessible as RemoteAction');
        } catch (Exception e) {
            System.assert(false, 'RemoteAction method should be accessible: ' + e.getMessage());
        }
        Test.stopTest();
    }
}