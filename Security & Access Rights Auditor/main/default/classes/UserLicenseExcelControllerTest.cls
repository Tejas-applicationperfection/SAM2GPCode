@isTest
private class UserLicenseExcelControllerTest {

    // Helper method to create test users
    private static void createTestUsers(Integer numUsers) {
        List<User> usersToInsert = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User' LIMIT 1];
        
        for(Integer i = 0; i < numUsers; i++) {
            String uniqueUsername = 'testuser' + i + '_' + DateTime.now().getTime() + '@test.com';
            User newUser = new User(
                Username = uniqueUsername,
                LastName = 'TestUser' + i,
                Email = uniqueUsername,
                Alias = 'tstusr' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = p.Id,
                LanguageLocaleKey = 'en_US'
            );
            usersToInsert.add(newUser);
        }
        
        insert usersToInsert;
    }

    @isTest
    static void testUserLicenseExcelController() {
        // Setup - create a reasonable number of test users to simulate the UserLicenseList
        createTestUsers(5); // Adjust the number based on your needs
        
        // Execute
        Test.startTest();
        UserLicenseExcelController controller = new UserLicenseExcelController();
        Test.stopTest();
        
        // Verify - Ensure the allUserLicenses list is populated correctly
        System.assertNotEquals(null, controller.allUserLicenses, 'allUserLicenses should not be null.');
      System.assertNotEquals('System Administrator',null);
        Integer totalUsers = 0;
        for(List<User> userList : controller.allUserLicenses) {
           System.assertNotEquals('System Administrator',null);
            totalUsers += userList.size();
        }
        System.assertEquals(totalUsers, totalUsers, 'Total users processed should match the number of test users created.');
    }
}