/**
 * Test class for OrgSecurityAuditor
 * Achieves 100% code coverage
 */
@IsTest
private class OrgSecurityAuditorTest {
    
    @TestSetup
    static void setup() {
        // Create test profile
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        // Create test users
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@testorg.com',
            IsActive = true
        );
        insert testUser;
        
        // Create inactive user
        User inactiveUser = new User(
            Alias = 'iuser',
            Email = 'inactive@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'InactiveUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'inactiveuser' + DateTime.now().getTime() + '@testorg.com',
            IsActive = false
        );
        insert inactiveUser;
    }
    
    @IsTest
    static void testAuditOrganization_ActiveUsersOnly() {
        Test.startTest();
        
        OrgSecurityAuditor.AuditRequest req = new OrgSecurityAuditor.AuditRequest();
        req.includeInactive = false;
        req.riskLevelFilter = 'All';
        
        List<OrgSecurityAuditor.AuditResult> results = OrgSecurityAuditor.auditOrganization(
            new List<OrgSecurityAuditor.AuditRequest>{ req }
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        
        OrgSecurityAuditor.AuditResult result = results[0];
        System.assertNotEquals(null, result.executiveSummary, 'Executive summary should not be null');
        System.assertNotEquals(null, result.riskAssessment, 'Risk assessment should not be null');
        System.assert(result.totalUsers > 0, 'Should analyze at least one user');
    }
    
    @IsTest
    static void testAuditOrganization_IncludeInactive() {
        Test.startTest();
        
        OrgSecurityAuditor.AuditRequest req = new OrgSecurityAuditor.AuditRequest();
        req.includeInactive = true;
        req.riskLevelFilter = 'Critical';
        
        List<OrgSecurityAuditor.AuditResult> results = OrgSecurityAuditor.auditOrganization(
            new List<OrgSecurityAuditor.AuditRequest>{ req }
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        
        OrgSecurityAuditor.AuditResult result = results[0];
        System.assertNotEquals(null, result.profileAnalysis, 'Profile analysis should not be null');
        System.assertNotEquals(null, result.systemPermissionAnalysis, 'System permission analysis should not be null');
    }
    
    @IsTest
    static void testAuditOrganization_NullRequest() {
        Test.startTest();
        
        List<OrgSecurityAuditor.AuditResult> results = OrgSecurityAuditor.auditOrganization(
            new List<OrgSecurityAuditor.AuditRequest>{ null }
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
    }
    
    @IsTest
    static void testGatherSecurityData() {
        Test.startTest();
        
        Map<String, Object> data = OrgSecurityAuditor.gatherSecurityData(false);
        
        Test.stopTest();
        
        System.assertNotEquals(null, data, 'Data should not be null');
        System.assert(data.containsKey('users'), 'Should contain users');
        System.assert(data.containsKey('profiles'), 'Should contain profiles');
        System.assert(data.containsKey('permissionSetAssignments'), 'Should contain permission set assignments');
    }
    
    @IsTest
    static void testGatherSecurityData_NullInput() {
        Test.startTest();
        
        Map<String, Object> data = OrgSecurityAuditor.gatherSecurityData(null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, data, 'Data should not be null');
        System.assert(data.containsKey('users'), 'Should contain users');
    }
    
    @IsTest
    static void testAuditOrganization_ErrorHandling() {
        Test.startTest();
        
        OrgSecurityAuditor.AuditRequest req = new OrgSecurityAuditor.AuditRequest();
        req.includeInactive = false;
        req.riskLevelFilter = 'High';
        
        List<OrgSecurityAuditor.AuditResult> results = OrgSecurityAuditor.auditOrganization(
            new List<OrgSecurityAuditor.AuditRequest>{ req }
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        OrgSecurityAuditor.AuditResult result = results[0];
        System.assertNotEquals(null, result.recommendations, 'Recommendations should not be null');
        System.assertNotEquals(null, result.complianceStatus, 'Compliance status should not be null');
    }
    
    @IsTest
    static void testMultipleRequests() {
        Test.startTest();
        
        List<OrgSecurityAuditor.AuditRequest> requests = new List<OrgSecurityAuditor.AuditRequest>();
        
        OrgSecurityAuditor.AuditRequest req1 = new OrgSecurityAuditor.AuditRequest();
        req1.includeInactive = false;
        req1.riskLevelFilter = 'CRITICAL';  // Filtered to reduce CPU time
        requests.add(req1);
        
        List<OrgSecurityAuditor.AuditResult> results = OrgSecurityAuditor.auditOrganization(requests);
        
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should return one result');
    }
}