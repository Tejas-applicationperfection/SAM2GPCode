public with sharing class ProfileClonerController {
        @AuraEnabled(cacheable=true)
        public static List<SA_Audit__ProfileClonerDetails__c> getLastClonedProfiles() {
            try {
                return [SELECT Id, Name,SA_Audit__NewPermission__c FROM SA_Audit__ProfileClonerDetails__c ORDER BY CreatedDate DESC LIMIT 10];
            } catch (Exception ex) {
                throw new AuraHandledException('Error fetching cloned profiles: ' + ex.getMessage());
            }
        }
    }