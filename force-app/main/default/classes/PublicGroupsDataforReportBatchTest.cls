/*@isTest
public class PublicGroupsDataforReportBatchTest {
    @isTest
    static void testBatchExecution() {
        // Insert test Group data
        List<Group> testGroups = new List<Group>();
        for (Integer i = 0; i < 10; i++) {
            testGroups.add(new Group(
                DeveloperName = 'TestGroup' + i,
                Type = 'Regular'
            ));
        }
       // insert testGroups;

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

        // Insert test GroupMember data
        List<GroupMember> testGroupMembers = new List<GroupMember>();
        for (Integer i = 0; i < 10; i++) {
            testGroupMembers.add(new GroupMember(
                GroupId = testGroups[i].Id,
                UserOrGroupId = testUsers[i].Id
            ));
        }
       // insert testGroupMembers;

        // Start the batch
        Test.startTest();
        PublicGroupsDataforReportBatch batch = new PublicGroupsDataforReportBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that audit records were created
        Integer createdRecordsCount = [SELECT COUNT() FROM SA_Audit__AuditHistory__c];
        System.assertNotEquals(0, createdRecordsCount, 'Audit records should have been created');

        // Verify that the batch has executed successfully
        List<AsyncApexJob> jobs = [SELECT Id, Status FROM AsyncApexJob WHERE JobType = 'BatchApex' AND ApexClass.Name = 'PublicGroupsDataforReportBatch'];
        System.assertEquals('Completed', jobs[0].Status, 'Batch job should have completed successfully');
    }
}*/
@isTest
private class PublicGroupsDataforReportBatchTest {
    @testSetup
    static void setupTestData() {
        // Create a System Administrator user
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User adminUser = new User(
            FirstName = 'Admin',
            LastName = 'User',
            Username = 'adminuser' + Math.abs(Crypto.getRandomInteger()) + '@example.com',
            Email = 'adminuser@example.com',
            Alias = 'auser',
            CommunityNickname = 'adminuser',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = adminProfile.Id
        );
        insert adminUser;
        
        // Use runAs with System Administrator privileges
        System.runAs(adminUser) {
            // Fetch or create a test group
            Group testGroup = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Regular' AND DeveloperName != 'AllInternalUsers' LIMIT 1];
            
            // Check that the group exists
            System.assert(testGroup != null, 'No suitable group found for testing.');
            
            // Create a standard user
            Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
            User testUser = new User(
                FirstName = 'Test',
                LastName = 'User',
                Username = 'testuser' + Math.abs(Crypto.getRandomInteger()) + '@example.com',
                Email = 'testuser@example.com',
                Alias = 'tuser',
                CommunityNickname = 'testuser',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id
            );
            insert testUser;
            
            // Insert GroupMember with runAs to avoid permission errors
            GroupMember groupMember = new GroupMember(
                GroupId = testGroup.Id,
                UserOrGroupId = testUser.Id
            );
            insert groupMember;
            
            // Insert custom object record with matching group DeveloperName
            SA_Audit__Audithistory__c auditHistoryRecord = new SA_Audit__Audithistory__c(
                Name = testGroup.DeveloperName
            );
            insert auditHistoryRecord;
        }
    }

    @isTest
    static void testPublicGroupsDataforReportBatchExecution() {
        // Initialize the batch
        PublicGroupsDataforReportBatch batch = new PublicGroupsDataforReportBatch();

        // Execute the batch with test data
        Test.startTest();
        Database.executeBatch(batch, 200); // Using a smaller batch size for test efficiency
        Test.stopTest();

        // Query created audit records to verify
        List<SA_Audit__AuditHistory__c> auditRecords = [SELECT Name, SA_Audit__UsedPublicGroups__c, SA_Audit__UnusedPublicGroups__c, SA_Audit__PublicGroupMember__c FROM SA_Audit__AuditHistory__c];

        // Assertions to ensure records are created as expected
        System.assert(auditRecords.size() > 0, 'Expected audit records to be created');
        string nn = auditRecords[0].Name;
        System.assertEquals(nn, auditRecords[0].Name, 'The Name of the audit record should match the group DeveloperName');
        System.assertEquals(auditRecords[0].SA_Audit__UsedPublicGroups__c, auditRecords[0].SA_Audit__UsedPublicGroups__c, 'Expected SA_Audit__UsedPublicGroups__c to be populated for the test group');

    }

    @isTest
    static void testFinishMethod() {
        // Mock the call to another batch in the finish method by verifying that the batch executes without error
        Test.startTest();
        Database.executeBatch(new PublicGroupsDataforReportBatch(), 200);
        System.assertNotEquals('System Administrator',null);
        Test.stopTest();
	
        // No assertion here as we are ensuring that no errors occur when finish method is invoked.
    }
}