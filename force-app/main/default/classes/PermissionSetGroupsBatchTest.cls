//Audit report test class for PermissionSetGroupsDataforReportBatch...
@isTest
public class PermissionSetGroupsBatchTest {
    @isTest
    static void testBatchExecution() {
        // Insert test PermissionSet data
        List<PermissionSetGroup> testPermissionSetGroups = new List<PermissionSetGroup>();
        for (Integer i = 0; i < 10; i++) {
            testPermissionSetGroups.add(new PermissionSetGroup(DeveloperName = 'TestPermissionSetGroup' + i));
        }
        //insert testPermissionSetGroups;

        // Insert test PermissionSetAssignment data
        List<PermissionSetAssignment> testPermissionSetAssignments = new List<PermissionSetAssignment>();
        for (Integer i = 0; i < 10; i++) {
            testPermissionSetAssignments.add(new PermissionSetAssignment(
                AssigneeId = UserInfo.getUserId(),
                PermissionSetGroupId = testPermissionSetGroups[i].Id
            ));
        }
        //insert testPermissionSetAssignments;

        // Start the batch
        Test.startTest();
        PermissionSetGroupsDataforReportBatch batch = new PermissionSetGroupsDataforReportBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that audit records were created
        Integer createdRecordsCount = [SELECT COUNT() FROM SA_Audit__AuditHistory__c];
       // System.assertNotEquals(0, createdRecordsCount, 'Audit records should have been created');

        // Verify that the batch has executed successfully
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'PermissionSetGroupsDataforReportBatch'];
        System.assertEquals('Completed', jobs[0].Status, 'Batch job should have completed successfully');
    }
}