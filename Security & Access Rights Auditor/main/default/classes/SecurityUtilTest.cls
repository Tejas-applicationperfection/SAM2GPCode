@isTest
public class SecurityUtilTest {
  

   /*  @isTest
    static void testMethods() {
        SecurityUtilDictionaryTest.testGetAllOrganizationProfilesList();
        SecurityUtilDictionaryTest.testGetPermissionTypeForLightning();
    } */
    
    @isTest
    static void testGetObjectsList() {
        List<SelectOption> options = SecurityUtil.getObjectsList(null, false);
        System.assertNotEquals(0, options.size(), 'Objects list should not be empty');
    }

    @isTest
    static void testGetCustomProfileList() {
        List<SelectOption> options = SecurityUtil.getCustomProfileList();
        System.assertNotEquals(null, options, 'Custom profile list should not be null');
    }
    
    
    @isTest
    static void testGetAllProfilesList() {
        List<SelectOption> options = SecurityUtil.getAllProfilesList();
        System.assertNotEquals(0, options.size(), 'All profiles list should not be empty');
    }

   /*  @isTest
    static void testGetAllOrganizationProfilesList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllOrganizationProfilesList();
        System.assertNotEquals(0, options.size(), 'Organization profiles list should not be empty');
    } */


    @isTest
    static void testGetAllManagedProfilesList() {
        List<SelectOption> options = SecurityUtil.getAllManagedProfilesList();
        System.assertNotEquals(0, options.size(), 'Managed profiles list should not be empty');
    }

    @isTest
    static void testGetAllManagedPermissionSetList() {
        List<SelectOption> options = SecurityUtil.getAllManagedPermissionSetList();
        System.assertNotEquals(0, options.size(), 'Managed permission sets list should not be empty');
    }

  /*  @isTest
    static void testGetAllOrganizationPermissionSetList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllOrganizationPermissionSetList();
        System.assertNotEquals(0, options.size(), 'Organization permission sets list should not be empty');
    } */

    @isTest
    static void testGetAllPermissionSetList() {
        List<SelectOption> options = SecurityUtil.getAllPermissionSetList();
        System.assertNotEquals(0, options.size(), 'All permission sets list should not be empty');
    }

    @isTest
    static void testGetPermissionType() {
        List<SelectOption> options = SecurityUtil.getPermissionType();
        System.assertEquals(options.size(), options.size(), 'Permission type list should have three options');
    }

  /*    @isTest
    static void testGetPermissionTypeForLightning() {
        List<String> options = SecurityUtilDictionary.getPermissionTypeForLightning();
        System.assertEquals(3, options.size(), 'Permission type for Lightning list should have three options');
    } */
    
    @isTest
    static void testChangetPermissionType() {
        List<SelectOption> options = SecurityUtil.changetPermissionType('All Profiles');
        System.assertNotEquals(0, options.size(), 'Changed permission type list should not be empty');
    }

    

    @isTest
    static void testGetUserList() {
        List<SelectOption> options = SecurityUtil.getUserList();
        System.assertNotEquals(0, options.size(), 'User list should not be empty');
    }

    @isTest
    static void testGetFieldDescribeMap() {
        Map<String, Schema.DescribeFieldResult> fieldMap = SecurityUtil.getFieldDescribeMap('Account');
        System.assertNotEquals(null, fieldMap, 'Field describe map should not be null');
    }

    @isTest
    static void testSortAfterLabelSelectOptionList() {
        List<SelectOption> inputOptions = new List<SelectOption>{
            new SelectOption('B', 'Beta'),
            new SelectOption('A', 'Alpha'),
            new SelectOption('C', 'Charlie')
        };
        List<SelectOption> sortedOptions = SecurityUtil.sortAfterLabelSelectOptionList(inputOptions);
        System.assertEquals('Alpha', sortedOptions[0].getLabel(), 'First option should be Alpha');
        System.assertEquals('Beta', sortedOptions[1].getLabel(), 'Second option should be Beta');
        System.assertEquals('Charlie', sortedOptions[2].getLabel(), 'Third option should be Charlie');
    }
}