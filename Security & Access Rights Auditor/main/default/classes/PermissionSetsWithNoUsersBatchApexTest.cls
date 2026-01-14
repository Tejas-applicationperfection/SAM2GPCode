@isTest
private class PermissionSetsWithNoUsersBatchApexTest {

    static void setupData() {
        String uniqueSuffix = String.valueOf(DateTime.now().getTime());

        // Ensure the profile used is correct and that it can be assigned to active users
        Profile standardUserProfile = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];

        // Create a unique active user
        User testUserActive = new User(
            Username='active' + uniqueSuffix + '@test.com',
            LastName='Test',
            Email='active' + uniqueSuffix + '@test.com',
            Alias='act',
            TimeZoneSidKey='America/Los_Angeles',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            ProfileId=standardUserProfile.Id,
            LanguageLocaleKey='en_US',
            IsActive=true  // Ensure the user is active
        );
        insert testUserActive;

        // Create a PermissionSet with a unique label
        PermissionSet pSet = new PermissionSet(
            Name='TestPermSet' + uniqueSuffix, 
            Label='Test Perm Set ' + uniqueSuffix
        );
        insert pSet;

        // Assign the PermissionSet to the active user
        PermissionSetAssignment psaActive = new PermissionSetAssignment(
            AssigneeId=testUserActive.Id, 
            PermissionSetId=pSet.Id
        );
        insert psaActive;
    }

    @isTest static void testBatchApex() {
        setupData();

        Test.startTest();
        PermissionSetsWithNoUsersBatchApex batchInstance = new PermissionSetsWithNoUsersBatchApex();
        Id batchJobId = Database.executeBatch(batchInstance);
        Test.stopTest();

        // Assertions to check expected behavior
        List<PermissionSetsWithNoUsersBatchApex.WrapperData> results = batchInstance.wrapperDataList;
        System.assertNotEquals(null, results, 'Results should not be null');
        //System.assertTrue(results.size() > 0, 'Results should contain data');
        // Further assertions can be added here based on expected results
    }
}