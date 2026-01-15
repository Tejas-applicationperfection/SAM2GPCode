/**
 * Test class for OrgSecurityAuditInvoker
 */
@IsTest
private class OrgSecurityAuditInvokerTest {
    
    @IsTest
    static void testRun_BasicInvocation() {
        Test.startTest();
        
        OrgSecurityAuditInvoker.AuditInput input = new OrgSecurityAuditInvoker.AuditInput();
        input.includeInactive = false;
        input.riskLevelFilter = 'All';
        
        List<OrgSecurityAuditInvoker.AuditOutput> outputs = OrgSecurityAuditInvoker.run(
            new List<OrgSecurityAuditInvoker.AuditInput>{ input }
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        System.assertEquals(1, outputs.size(), 'Should return one output');
        
        OrgSecurityAuditInvoker.AuditOutput output = outputs[0];
        System.assertNotEquals(null, output.executiveSummary, 'Executive summary should not be null');
        System.assertNotEquals(null, output.recommendations, 'Recommendations should not be null');
        System.assert(output.totalUsers > 0, 'Should analyze users');
    }
    
    @IsTest
    static void testRun_NullInput() {
        Test.startTest();
        
        List<OrgSecurityAuditInvoker.AuditOutput> outputs = OrgSecurityAuditInvoker.run(
            new List<OrgSecurityAuditInvoker.AuditInput>{ null }
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
    }
    
    @IsTest
    static void testRun_WithRiskFilter() {
        Test.startTest();
        
        OrgSecurityAuditInvoker.AuditInput input = new OrgSecurityAuditInvoker.AuditInput();
        input.includeInactive = true;
        input.riskLevelFilter = 'CRITICAL';
        
        List<OrgSecurityAuditInvoker.AuditOutput> outputs = OrgSecurityAuditInvoker.run(
            new List<OrgSecurityAuditInvoker.AuditInput>{ input }
        );
        
        Test.stopTest();
        
        System.assertNotEquals(null, outputs, 'Outputs should not be null');
        OrgSecurityAuditInvoker.AuditOutput output = outputs[0];
        System.assertNotEquals(null, output.files, 'Files should not be null');
    }
    
    @IsTest
    static void testFileLinks() {
        Test.startTest();
        
        OrgSecurityAuditInvoker.FileLink link = new OrgSecurityAuditInvoker.FileLink();
        link.fileName = 'test.csv';
        link.downloadUrl = 'https://example.com/download';
        
        Test.stopTest();
        
        System.assertEquals('test.csv', link.fileName, 'File name should match');
        System.assertEquals('https://example.com/download', link.downloadUrl, 'Download URL should match');
    }
}