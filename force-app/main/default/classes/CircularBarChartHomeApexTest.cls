@IsTest
public class CircularBarChartHomeApexTest {
    
    @TestSetup
    public static void setupTestData() {
        // Creating UserRoles
        List<UserRole> roles = new List<UserRole>();
        roles.add(new UserRole(Name = 'Test_Role_1', DeveloperName = 'TestRole1'));
        roles.add(new UserRole(Name = 'Test_Role_2', DeveloperName = 'TestRole2'));
        insert roles;
        
        // Creating Groups
        List<Group> groups = new List<Group>();
        groups.add(new Group(Name = 'Test_Group_1', Type = 'Regular', DeveloperName = 'TestGroup1'));
        groups.add(new Group(Name = 'Test_Group_2', Type = 'Regular', DeveloperName = 'TestGroup2'));
        insert groups;
        
        // Creating GroupMembers
        List<GroupMember> groupMembers = new List<GroupMember>();
        for (Group grp : groups) {
            groupMembers.add(new GroupMember(GroupId = grp.Id, UserOrGroupId = UserInfo.getUserId()));
        }
        insert groupMembers;

       

        // Creating PermissionSetAssignment records
        List<PermissionSet> permSets = [SELECT Id FROM PermissionSet WHERE IsOwnedByProfile = false LIMIT 1];
        if (!permSets.isEmpty()) {
            // Check if assignment already exists to avoid duplicates
            List<PermissionSetAssignment> existingAssignments = [
                SELECT Id FROM PermissionSetAssignment 
                WHERE AssigneeId = :UserInfo.getUserId() 
                AND PermissionSetId = :permSets[0].Id
            ];
            
            if (existingAssignments.isEmpty()) {
                PermissionSetAssignment permSetAssign = new PermissionSetAssignment(
                    AssigneeId = UserInfo.getUserId(),
                    PermissionSetId = permSets[0].Id
                );
                insert permSetAssign;
            }
        }
    }
    
    @IsTest
    public static void testGetPermissionReviewData() {
        // Call the method
        Test.startTest();
        List<CircularBarChartHomeApex.PermissionReviewItem> result = CircularBarChartHomeApex.getPermissionReviewData();
        Test.stopTest();
        
        // Asserts
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Result should contain at least one PermissionReviewItem');
        
        CircularBarChartHomeApex.PermissionReviewItem reviewItem = result[0];
        
        // Validate counts are non-null and logically consistent
        System.assertNotEquals(null, reviewItem.Profilecount, 'Profile count should not be null');
        System.assertNotEquals(null, reviewItem.Permissioncount, 'Permission count should not be null');
        System.assertNotEquals(null, reviewItem.Rolescount, 'Roles count should not be null');
        System.assertNotEquals(null, reviewItem.PublicGroupcount, 'Public Group count should not be null');
        System.assertNotEquals(null, reviewItem.InternalRolescount, 'Internal Roles count should not be null');
    }

    @IsTest
    public static void testGetExistingDatesFromServer() {
        // Setup test data for SA_Audit__AuditDateInfo__c
        SA_Audit__AuditDateInfo__c dateInfo = new SA_Audit__AuditDateInfo__c(
            SA_Audit__DateSelectionName__c = 'Test_Date_Record',
            SA_Audit__Date_Selection_value__c = Date.today()
        );
        insert dateInfo;
        
        Test.startTest();
        Date result = CircularBarChartHomeApex.getExistingDatesFromServer('Test_Date_Record');
        Test.stopTest();
        
        // Assert
        System.assertEquals(Date.today(), result, 'The returned date should match the test date');
    }
}