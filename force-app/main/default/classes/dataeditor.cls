public with sharing class dataeditor {
	@AuraEnabled(cacheable=true)
    public static Boolean PaidFeatureAccess() {
        // Check if the feature is enabled for the user
       // return FeatureManagement.checkPackageBooleanValue('DataDescriptionEditorPaidAccess');
       // returned true because i want to work on the DDE
        return true;
    }
    
}