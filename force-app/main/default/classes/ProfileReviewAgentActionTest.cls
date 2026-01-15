/**
 * Test class for ProfileReviewAgentAction
 */
@IsTest
private class ProfileReviewAgentActionTest {
    
    @IsTest
    static void testReviewProfiles_SingleProfile() {
        Profile p = [SELECT Name FROM Profile LIMIT 1];
        
        Test.startTest();
        
        ProfileReviewAgentAction.Request req = new ProfileReviewAgentAction.Request();
        req.profileName = p.Name;
        
        List<ProfileReviewAgentAction.Response> responses = 
            ProfileReviewAgentAction.reviewProfiles(new List<ProfileReviewAgentAction.Request>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, responses, 'Responses should not be null');
        System.assertEquals(1, responses.size(), 'Should return one response');
        System.assertNotEquals(null, responses[0].findings, 'Findings should not be null');
        System.assertNotEquals(null, responses[0].riskLevel, 'Risk level should not be null');
    }
    
    @IsTest
    static void testReviewProfiles_AllProfiles() {
        Test.startTest();
        
        ProfileReviewAgentAction.Request req = new ProfileReviewAgentAction.Request();
        req.profileName = 'ALL';
        
        List<ProfileReviewAgentAction.Response> responses = 
            ProfileReviewAgentAction.reviewProfiles(new List<ProfileReviewAgentAction.Request>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, responses, 'Responses should not be null');
        System.assert(responses[0].findings.contains('ORG-WIDE'), 'Should contain org-wide audit text');
    }
    
    @IsTest
    static void testReviewProfiles_NullInput() {
        Test.startTest();
        
        List<ProfileReviewAgentAction.Response> responses = 
            ProfileReviewAgentAction.reviewProfiles(new List<ProfileReviewAgentAction.Request>{ null });
        
        Test.stopTest();
        
        System.assertEquals('Error', responses[0].riskLevel, 'Should return error for null input');
    }
    
    @IsTest
    static void testReviewProfiles_MultipleRequests() {
        Profile p = [SELECT Name FROM Profile LIMIT 1];
        
        Test.startTest();
        
        List<ProfileReviewAgentAction.Request> requests = new List<ProfileReviewAgentAction.Request>();
        
        ProfileReviewAgentAction.Request req1 = new ProfileReviewAgentAction.Request();
        req1.profileName = p.Name;
        requests.add(req1);
        
        ProfileReviewAgentAction.Request req2 = new ProfileReviewAgentAction.Request();
        req2.profileName = 'ALL';
        requests.add(req2);
        
        List<ProfileReviewAgentAction.Response> responses = 
            ProfileReviewAgentAction.reviewProfiles(requests);
        
        Test.stopTest();
        
        System.assertEquals(2, responses.size(), 'Should return two responses');
    }
}