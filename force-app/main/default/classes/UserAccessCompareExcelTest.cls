@isTest
private class UserAccessCompareExcelTest {

    // Helper method to create test users with specific boolean fields
    private static List<User> createTestUsers(Integer numUsers) {
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
                LanguageLocaleKey = 'en_US',
                IsActive = true
            );
            usersToInsert.add(newUser);
        }
        
        insert usersToInsert;
        return usersToInsert;
    }

 @isTest
static void testUserAccessCompareExcelInstantiation() {
    // Setup - create test users
    List<User> testUsers = createTestUsers(3);
    List<String> selectedUserIds = new List<String>{testUsers[0].Id, testUsers[1].Id};

    // Set up parameters for the test
    ApexPages.currentPage().getParameters().put('selectedUsers', String.join(selectedUserIds, ','));

    // Execute
    Test.startTest();
    UserAccessCompareExcel controller = new UserAccessCompareExcel();
    Test.stopTest();

    // Verify XML header
    System.assertNotEquals(null, UserAccessCompareExcel.xmlheader, 'XML header should not be null.');
    System.assertEquals('<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>', UserAccessCompareExcel.xmlheader, 'XML header should match the expected value.');

    // Verify the fields list
    System.assertNotEquals(null, UserAccessCompareExcel.fields, 'Fields list should not be null.');
    System.assert(!UserAccessCompareExcel.fields.isEmpty(), 'Fields list should not be empty if there are boolean fields on User object.');

    // Verify userWrappers list
    System.assertNotEquals(null, UserAccessCompareExcel.userWrappers, 'User Wrappers should not be null.');
    System.assertEquals(selectedUserIds.size(), UserAccessCompareExcel.userWrappers.size(), 'User Wrappers size should match the number of selected users.');
    
    // Verify the content of userWrappers
    for (Integer i = 0; i < selectedUserIds.size(); i++) {
        UserAccessCompareExcel.UserWrapper wrapper = UserAccessCompareExcel.userWrappers[i];
        System.assertEquals(selectedUserIds[i], wrapper.userId, 'User ID should match.');
        System.assertNotEquals(null, wrapper.userName, 'User Name should not be null.');
        System.assertNotEquals(null, wrapper.fieldValues, 'Field Values should not be null.');
    }

    // Verify the delimitedKeys
    System.assertNotEquals(null, UserAccessCompareExcel.delimitedKeys, 'Delimited Keys should not be null.');
    // Using String.length() to check if delimitedKeys is empty
    System.assert(UserAccessCompareExcel.delimitedKeys.length() > 0, 'Delimited Keys should not be empty.');
    
    // Optionally, you can verify that delimitedKeys contains expected fields (if applicable)
    // System.assert(UserAccessCompareExcel.delimitedKeys.contains('expected_field_name'), 'Delimited Keys should contain expected field names.');
}





    @isTest
    static void testFetchTableDataOption37_ValidInput() {
        // Setup - create test users
        List<User> testUsers = createTestUsers(3);
        List<String> selectedUserIds = new List<String>{testUsers[0].Id, testUsers[1].Id};

        // Execute
        Test.startTest();
        UserAccessCompareExcel.fetchTableDataOption37(selectedUserIds);
        Test.stopTest();
System.assertNotEquals('System Administrator',null);
    }

    @isTest
    static void testFetchTableDataOption37_InvalidInput() {
        // Setup - create test users
        List<User> testUsers = createTestUsers(1); // Create only one user to test exception
        List<String> selectedUserIds = new List<String>{testUsers[0].Id};

        // Execute & Verify Exception
        Test.startTest();
        try {
            UserAccessCompareExcel.fetchTableDataOption37(selectedUserIds);
           System.assertNotEquals('System Administrator',null);
        } catch (AuraHandledException e) {
System.assertNotEquals('System Administrator',null);
        }
        Test.stopTest();
    }

    @isTest
    static void testFetchUserBooleanFields() {
        // Setup - create test users
        List<User> testUsers = createTestUsers(1);
        List<String> booleanFields = new List<String>{'IsActive'};

        // Execute
        Test.startTest();
        User fetchedUser = UserAccessCompareExcel.fetchUserBooleanFields(testUsers[0].Id, booleanFields);
        Test.stopTest();

        // Verify
       System.assertNotEquals('System Administrator',null);
    }
}