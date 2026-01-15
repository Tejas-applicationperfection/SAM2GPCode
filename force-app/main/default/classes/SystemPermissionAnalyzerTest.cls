/**
 * Test class for SystemPermissionAnalyzer
 */
@IsTest
private class SystemPermissionAnalyzerTest {
    
    @IsTest
    static void testAnalyzeSystemPermission_ModifyAllData() {
        Test.startTest();
        
        SystemPermissionAnalyzer.SystemPermissionRequest req = new SystemPermissionAnalyzer.SystemPermissionRequest();
        req.permissionName = 'Modify All Data';
        req.includeInactive = false;
        
        List<SystemPermissionAnalyzer.SystemPermissionResult> results = 
            SystemPermissionAnalyzer.analyzeSystemPermission(new List<SystemPermissionAnalyzer.SystemPermissionRequest>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0].conversationalSummary, 'Summary should not be null');
    }
    
    @IsTest
    static void testAnalyzeSystemPermission_ViewAllData() {
        Test.startTest();
        
        SystemPermissionAnalyzer.SystemPermissionRequest req = new SystemPermissionAnalyzer.SystemPermissionRequest();
        req.permissionName = 'View All Data';
        req.includeInactive = true;
        
        List<SystemPermissionAnalyzer.SystemPermissionResult> results = 
            SystemPermissionAnalyzer.analyzeSystemPermission(new List<SystemPermissionAnalyzer.SystemPermissionRequest>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertNotEquals(null, results[0].riskAssessment, 'Risk assessment should not be null');
    }
    
    @IsTest
    static void testAnalyzeSystemPermission_InvalidPermission() {
        Test.startTest();
        
        SystemPermissionAnalyzer.SystemPermissionRequest req = new SystemPermissionAnalyzer.SystemPermissionRequest();
        req.permissionName = 'InvalidPermission';
        
        List<SystemPermissionAnalyzer.SystemPermissionResult> results = 
            SystemPermissionAnalyzer.analyzeSystemPermission(new List<SystemPermissionAnalyzer.SystemPermissionRequest>{ req });
        
        Test.stopTest();
        
        System.assertEquals(0, results[0].totalUsers, 'Should return zero users');
    }
    
    @IsTest
    static void testAnalyzeSystemPermission_NullInput() {
        Test.startTest();
        
        SystemPermissionAnalyzer.SystemPermissionRequest req = new SystemPermissionAnalyzer.SystemPermissionRequest();
        req.permissionName = null;
        
        List<SystemPermissionAnalyzer.SystemPermissionResult> results = 
            SystemPermissionAnalyzer.analyzeSystemPermission(new List<SystemPermissionAnalyzer.SystemPermissionRequest>{ req });
        
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
    }
    
    @IsTest
    static void testQueryProfilesByPermission() {
        Test.startTest();
        
        List<Profile> profiles = SystemPermissionAnalyzer.queryProfilesByPermission('PermissionsModifyAllData');
        
        Test.stopTest();
        
        System.assertNotEquals(null, profiles, 'Profiles should not be null');
    }
    
    @IsTest
    static void testQueryPermissionSetsByPermission() {
        Test.startTest();
        
        List<PermissionSet> permSets = SystemPermissionAnalyzer.queryPermissionSetsByPermission('PermissionsViewAllData');
        
        Test.stopTest();
        
        System.assertNotEquals(null, permSets, 'Permission sets should not be null');
    }
    
    @IsTest
    static void testAllSupportedPermissions() {
        Test.startTest();
        
        List<String> permissions = new List<String>{
            'Manage Users', 'Customize Application', 'API Enabled', 'Author Apex'
        };
        
        for (String perm : permissions) {
            SystemPermissionAnalyzer.SystemPermissionRequest req = new SystemPermissionAnalyzer.SystemPermissionRequest();
            req.permissionName = perm;
            List<SystemPermissionAnalyzer.SystemPermissionResult> results = 
                SystemPermissionAnalyzer.analyzeSystemPermission(new List<SystemPermissionAnalyzer.SystemPermissionRequest>{ req });
            System.assertNotEquals(null, results, 'Results should not be null for: ' + perm);
        }
        
        Test.stopTest();
    }
}