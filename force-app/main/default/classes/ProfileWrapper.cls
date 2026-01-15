public with sharing class ProfileWrapper {
    @AuraEnabled public String profileName { get; set; }
    @AuraEnabled public Boolean create { get; set; }
    @AuraEnabled public Boolean read { get; set; }
    @AuraEnabled public Boolean edit { get; set; }
    @AuraEnabled public Boolean del { get; set; }
    @AuraEnabled public Boolean modifyAllData { get; set; }
    @AuraEnabled public Boolean modifyAllRecords { get; set; }
    @AuraEnabled public Boolean viewAllRecords { get; set; }
    @AuraEnabled public String errorMSG { get; set; }
}