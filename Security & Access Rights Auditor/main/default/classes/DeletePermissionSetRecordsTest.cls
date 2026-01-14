@isTest
public class DeletePermissionSetRecordsTest {
    
    @isTest
    static void testDeleteRecords() {
        // Step 1: Create test data for the custom setting
        SA_Audit__BatchApexStatus__c customSettingRecord = new SA_Audit__BatchApexStatus__c();
         customSettingRecord.Name = 'PermissionSet';
        customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true;
        insert customSettingRecord;

        // Step 2: Create test data for OWDObjectRecord
        SA_Audit__BatchApexStatus__c owdObjectRecord = new SA_Audit__BatchApexStatus__c();
        owdObjectRecord.Name = 'PermissionSet';
        owdObjectRecord.SA_Audit__Is_Batch_Apex_Executed__c = true;
        insert owdObjectRecord;

        // Step 3: Create test data for Sharing Report records
        SA_Audit__OWD_Sharing_Report__c sharingReportRecord = new SA_Audit__OWD_Sharing_Report__c();
        sharingReportRecord.SA_Audit__Type__c = 'PermissionSet';
        insert sharingReportRecord;

        // Step 4: Call the method to delete records
        Test.startTest();
        DeletePermissionSetRecords.DeleteRecords();
        Test.stopTest();

        // Step 5: Verify that the custom setting record has been deleted
        SA_Audit__BatchApexStatus__c deletedCustomSettingRecord = SA_Audit__BatchApexStatus__c.getValues('PermissionSet');
        System.assertEquals(null, deletedCustomSettingRecord, 'Custom setting record should be deleted.');

        // Step 6: Verify that OWDObjectRecord has been deleted
        List<SA_Audit__BatchApexStatus__c> owdObjectRecords = [SELECT Id FROM SA_Audit__BatchApexStatus__c WHERE SA_Audit__Is_Batch_Apex_Executed__c = true];
        System.assertEquals(0, owdObjectRecords.size(), 'OWDObjectRecord should be deleted.');

        // Step 7: Verify that Sharing Report records have been deleted
        List<SA_Audit__OWD_Sharing_Report__c> sharingReports = [SELECT Id FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'PermissionSet'];
        System.assertEquals(0, sharingReports.size(), 'Sharing Report records should be deleted.');
    }
}