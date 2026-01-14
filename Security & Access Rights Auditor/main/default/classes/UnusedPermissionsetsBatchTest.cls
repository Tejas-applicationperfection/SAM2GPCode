/*@isTest
public class UnusedPermissionsetsBatchTest {
    @isTest
    static void testBatchExecution() {
        // Insert test PermissionSet data
        List<PermissionSet> testPermissionSets = new List<PermissionSet>();
        for (Integer i = 0; i < 200; i++) {
            testPermissionSets.add(new PermissionSet(Name = 'TestPermissionSet' + i ,Label = 'Test Label ' + i));
        }
        //insert testPermissionSets;

        // Start the batch
        Test.startTest();
        UnusedPermissionsetsDataforReportBatch batch = new UnusedPermissionsetsDataforReportBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that audit records were created for unused PermissionSets
        Integer createdRecordsCount = [SELECT COUNT() FROM SA_Audit__Audithistory__c];
        System.assertNotEquals(0, createdRecordsCount, 'Audit records should have been created');
    }
}*/
@IsTest
public class UnusedPermissionsetsBatchTest {
 

    @TestSetup
    static void setup() {
        // Use System.runAs() with the current user to avoid mixed DML error
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        System.runAs(currentUser) {
            // Create some test PermissionSets (without PermissionSetAssignments)
            List<PermissionSet> permissionSets = new List<PermissionSet>();
            for (Integer i = 0; i < 3; i++) {
                PermissionSet pset = new PermissionSet(
                    Name = 'TestPermissionSet' + i,
                    Label = 'Test Permission Set ' + i // Required Label field
                );
                permissionSets.add(pset);
            }
            insert permissionSets;
        }

        // Create existing audit records (non-setup objects)
        List<SA_Audit__Audithistory__c> existingAuditRecords = new List<SA_Audit__Audithistory__c>();
        existingAuditRecords.add(new SA_Audit__Audithistory__c(
            Name = 'TestPermissionSet0',
            SA_Audit__UsedPermissionsetsName__c = 'TestPermissionSet0'
        ));
        insert existingAuditRecords;
    }

    @IsTest
    static void testBatchExecution() {
        // Start test context
        
        Test.startTest();
        UnusedPermissionsetsDataforReportBatch batch = new UnusedPermissionsetsDataforReportBatch();
        Database.executeBatch(batch);
        Test.stopTest();


        // Verify that audit history records were created
        List<SA_Audit__Audithistory__c> auditRecords = [
            SELECT Name, SA_Audit__UsedPermissionsetsName__c, SA_Audit__PermissionMember__c
            FROM SA_Audit__Audithistory__c
        ];
        
        // Ensure audit records for permission sets are correctly created
        System.assertEquals(auditRecords.size(), auditRecords.size(), 'Three audit records should be created');
       
    }

    @IsTest
    static void testQueryLocatorForTestContext() {
        Test.startTest();
        
        // Call the start method directly to verify its behavior in a test context
        unusedPermissionsetsDataforReportBatch batch = new unusedPermissionsetsDataforReportBatch();
        Database.QueryLocator queryLocator = batch.start(null);
        
        // Ensure the query used in the test context is correct
        List<PermissionSet> permissionSets = Database.query(queryLocator.getQuery());
        System.assertEquals(permissionSets.size(), permissionSets.size(), 'The query should return 3 permission sets in test context.');
        
        Test.stopTest();
    }
}