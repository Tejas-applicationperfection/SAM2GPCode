@isTest
public class ExternalRolesBatchTest {
    @isTest
    static void testBatchExecution() {
        // Insert test User data
        List<User> testUsers = new List<User>();
        for (Integer i = 0; i < 10; i++) {
            testUsers.add(new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@example.com',
                Alias = 'TUser' + i,
                Username = 'testuser' + i + '@example.com'
            ));
        }
        //insert testUsers;

        // Insert test UserRole data
        List<UserRole> testUserRoles = new List<UserRole>();
        for (Integer i = 0; i < 10; i++) {
            testUserRoles.add(new UserRole(
                Name = 'TestRole' + i,
                DeveloperName = 'TestRole' + i,
                PortalType = 'None'
            ));
        }
       // insert testUserRoles;

        // Insert test UserRoleMember data
        List<UserRole> insertedUserRoles = [SELECT Id FROM UserRole];
        List<User> insertedUsers = [SELECT Id FROM User];
        List<UserRole> testUserRoleMembers = new List<UserRole>();
         
        // Start the batch
        Test.startTest();
        ExternalRolesDataforReportBatch batch = new ExternalRolesDataforReportBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that audit records were created
        Integer createdRecordsCount = [SELECT COUNT() FROM SA_Audit__AuditHistory__c];
        System.assertNotEquals(0, createdRecordsCount, 'Audit records should have been created');

        // Verify that the batch has executed successfully
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'ExternalRolesDataforReportBatch'];
        System.assertEquals('Completed', jobs[0].Status, 'Batch job should have completed successfully');
    }
}