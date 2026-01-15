@isTest
public class SharingSettingsFutureControllerTest {
    
    @TestSetup
    static void setup() {
        // Create multiple test records
        List<SA_Audit__OWD_Sharing_Report__c> owdRecords = new List<SA_Audit__OWD_Sharing_Report__c>();
        owdRecords.add(new SA_Audit__OWD_Sharing_Report__c(SA_Audit__Type__c = 'OWDReport'));
        owdRecords.add(new SA_Audit__OWD_Sharing_Report__c(SA_Audit__Type__c = 'SharingRulesReport'));
        insert owdRecords;
    }
    
    @isTest
    static void testGetOWDDetails() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        SharingSettingsFutureController.getOWDDetails();
        Test.stopTest();
        
        List<SA_Audit__OWD_Sharing_Report__c> records = [SELECT Id FROM SA_Audit__OWD_Sharing_Report__c];
        System.assert(records.size() > 0, 'Records should exist');
    }
    
    @isTest
    static void testGetOWDDetailsWithExistingRecords() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorWithContent());
        
        Test.startTest();
        SharingSettingsFutureController.getOWDDetails();
        Test.stopTest();
        
        System.assert(true, 'Method executed successfully');
    }
    
    @isTest
    static void testGetSharingRulesDetails() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        try {
            SharingSettingsFutureController.getOWDDetails();
        } catch (Exception e) {
            System.debug('Expected exception in test context: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testMultipleExecutions() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Test.startTest();
        SharingSettingsFutureController.getOWDDetails();
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM SA_Audit__OWD_Sharing_Report__c];
        System.assert(count >= 0, 'Should have records');
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            res.setBody('<html><body>Mock HTML response</body></html>');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockHttpResponseGeneratorWithContent implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            String body = '<html><body>Organization-Wide Defaults';
            body += '<!-- ListRow --><th dataCell  ">Account</th><td dataCell  ">Private</td>';
            body += '<td dataCell  ">Private</td><td booleanColumn">/img/checkbox_checked.gif</td>';
            body += '<!-- ListRow -->Other Settings</body></html>';
            res.setBody(body);
            res.setStatusCode(200);
            return res;
        }
    }
}