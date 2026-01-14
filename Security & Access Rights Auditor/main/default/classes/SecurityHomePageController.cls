/**
 * @description Controller for SecurityHomePage LWC to check feature access
 * @author Application Perfection
 * @date 2025-01-12
 */
public with sharing class SecurityHomePageController {
    
    /**
     * @description Check if user has access to paid features
     * @return Boolean True if user has access to all paid features
     */
    @AuraEnabled(cacheable=true)
    public static Boolean checkFeatureAccess() {
        return FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess');
    }
    
    /**
     * @description Get license status for all features on the home page
     * @return Map<String, Boolean> Map of feature names to their license status
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Boolean> getFeatureLicenseStatus() {
        Map<String, Boolean> featureStatus = new Map<String, Boolean>();
        
        // Each feature has its own license parameter
       // featureStatus.put('objectSecurity', FeatureManagement.checkPackageBooleanValue('IntelPaidAccess'));
        featureStatus.put('objectSecurity', true);

       // featureStatus.put('fieldSecurity', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('fieldSecurity', true);

       // featureStatus.put('recordAccess', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('recordAccess', true);

       // featureStatus.put('intelTab', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('intelTab', true);

       // featureStatus.put('dataDescriptionEditor', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('dataDescriptionEditor', true);

       // featureStatus.put('System_Permissions', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('System_Permissions', true);

       // featureStatus.put('permissionAudit', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('permissionAudit', true);

       // featureStatus.put('reportManager', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('reportManager', true);

       // featureStatus.put('bulkExporter', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('bulkExporter', true);

       // featureStatus.put('lightningIntel', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('lightningIntel', true);

       // featureStatus.put('userAccessManager', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess'));
        featureStatus.put('userAccessManager', true);

       // featureStatus.put('clonerApp', FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess')); 
        featureStatus.put('clonerApp', true);
        
       // featureStatus.put('privilegedPermissions', FeatureManagement.checkPackageBooleanValue('PrivilegedPermissionsLicensed'));
        featureStatus.put('privilegedPermissions', true);
        
       // featureStatus.put('userDataDictionary', FeatureManagement.checkPackageBooleanValue('UserDictionaryLicensed'));
        featureStatus.put('userDataDictionary', true);
        
        return featureStatus;
    }
}