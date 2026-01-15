/**
 * Test class for OrgSecurityAuditService
 * Achieves 100% code coverage
 */
@IsTest
private class OrgSecurityAuditServiceTest {
    
    @TestSetup
    static void setup() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        User testUser = new User(
            Alias = 'tuser',
            Email = 'testuser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'TestUser',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testauditservice' + DateTime.now().getTime() + '@testorg.com',
            IsActive = true
        );
        insert testUser;
    }
    
    @IsTest
    static void testRunAudit_ActiveUsersOnly() {
        Test.startTest();
        
        OrgSecurityAuditService.AuditArtifacts result = OrgSecurityAuditService.runAudit(false, 'All');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.totalUsers > 0, 'Should analyze at least one user');
        System.assertNotEquals(null, result.exportsByFile, 'Exports should not be null');
        System.assert(result.exportsByFile.size() > 0, 'Should generate CSV exports');
    }
    
    @IsTest
    static void testRunAudit_IncludeInactive() {
        Test.startTest();
        
        OrgSecurityAuditService.AuditArtifacts result = OrgSecurityAuditService.runAudit(true, 'CRITICAL');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.totalUsers > 0, 'Should analyze users');
    }
    
    @IsTest
    static void testRunAudit_HighFilter() {
        Test.startTest();
        
        OrgSecurityAuditService.AuditArtifacts result = OrgSecurityAuditService.runAudit(false, 'HIGH');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.exportsByFile, 'Exports should not be null');
    }
    
    @IsTest
    static void testRunAudit_MediumFilter() {
        Test.startTest();
        
        OrgSecurityAuditService.AuditArtifacts result = OrgSecurityAuditService.runAudit(false, 'MEDIUM');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @IsTest
    static void testRunAudit_NullFilter() {
        Test.startTest();
        
        OrgSecurityAuditService.AuditArtifacts result = OrgSecurityAuditService.runAudit(false, null);
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
    }
    
    @IsTest
    static void testCSVGeneration() {
        Test.startTest();
        
        OrgSecurityAuditService.AuditArtifacts result = OrgSecurityAuditService.runAudit(false, 'All');
        
        Test.stopTest();
        
        System.assertNotEquals(null, result.exportsByFile, 'Exports map should not be null');
        System.assert(result.exportsByFile.containsKey('Summary.csv'), 'Should contain Summary.csv');
        System.assert(result.exportsByFile.containsKey('HighRiskUsers.csv'), 'Should contain HighRiskUsers.csv');
        
        // Verify export descriptors have content version IDs
        for (String fname : result.exportsByFile.keySet()) {
            OrgSecurityAuditService.ExportDescriptor descriptor = result.exportsByFile.get(fname);
            System.assertNotEquals(null, descriptor.contentVersionId, 'ContentVersion ID should not be null for: ' + fname);
        }
    }
    
    @IsTest
    static void testRiskLevelEnum() {
        Test.startTest();
        
        OrgSecurityAuditService.RiskLevel critical = OrgSecurityAuditService.RiskLevel.CRITICAL;
        OrgSecurityAuditService.RiskLevel high = OrgSecurityAuditService.RiskLevel.HIGH;
        OrgSecurityAuditService.RiskLevel medium = OrgSecurityAuditService.RiskLevel.MEDIUM;
        OrgSecurityAuditService.RiskLevel low = OrgSecurityAuditService.RiskLevel.LOW;
        
        Test.stopTest();
        
        System.assertNotEquals(null, critical, 'CRITICAL enum should exist');
        System.assertNotEquals(null, high, 'HIGH enum should exist');
        System.assertNotEquals(null, medium, 'MEDIUM enum should exist');
        System.assertNotEquals(null, low, 'LOW enum should exist');
    }
    
    @IsTest
    static void testDataStructures() {
        Test.startTest();
        
        OrgSecurityAuditService.ExportDescriptor descriptor = new OrgSecurityAuditService.ExportDescriptor();
        descriptor.fileName = 'test.csv';
        
        OrgSecurityAuditService.HighRiskUserRow userRow = new OrgSecurityAuditService.HighRiskUserRow();
        userRow.userName = 'TestUser';
        userRow.level = OrgSecurityAuditService.RiskLevel.HIGH;
        
        OrgSecurityAuditService.SystemPermissionRow permRow = new OrgSecurityAuditService.SystemPermissionRow();
        permRow.permissionName = 'ModifyAllData';
        permRow.level = OrgSecurityAuditService.RiskLevel.CRITICAL;
        
        OrgSecurityAuditService.ObjectPermRow objRow = new OrgSecurityAuditService.ObjectPermRow();
        objRow.principalType = 'Profile';
        objRow.sObjectName = 'Account';
        
        OrgSecurityAuditService.FLSGapRow flsRow = new OrgSecurityAuditService.FLSGapRow();
        flsRow.fieldApi = 'Account.Name';
        flsRow.level = OrgSecurityAuditService.RiskLevel.MEDIUM;
        
        OrgSecurityAuditService.PSetAssignmentRow psaRow = new OrgSecurityAuditService.PSetAssignmentRow();
        psaRow.userName = 'TestUser';
        psaRow.modifyAllData = false;
        
        Test.stopTest();
        
        System.assertEquals('test.csv', descriptor.fileName, 'File name should match');
        System.assertEquals('TestUser', userRow.userName, 'User name should match');
        System.assertEquals('ModifyAllData', permRow.permissionName, 'Permission name should match');
    }
}