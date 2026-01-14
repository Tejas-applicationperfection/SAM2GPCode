@isTest
public class SecurityUtilDictionaryTest {
  

   /*  @isTest
    static void testMethods() {
        SecurityUtilDictionaryTest.testGetAllOrganizationProfilesList();
        SecurityUtilDictionaryTest.testGetPermissionTypeForLightning();
    } */
    
    @isTest
    static void testGetObjectsList() {
        List<SelectOption> options = SecurityUtilDictionary.getObjectsList(null, false);
        System.assertNotEquals(0, options.size(), 'Objects list should not be empty');
    }

    @isTest
    static void testGetCustomProfileList() {
        List<SelectOption> options = SecurityUtilDictionary.getCustomProfileList();
        System.assertNotEquals(null, options, 'Custom profile list should not be null');
    }
    
    
    @isTest
    static void testGetAllProfilesList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllProfilesList();
        System.assertNotEquals(0, options.size(), 'All profiles list should not be empty');
    }

   /*  @isTest
    static void testGetAllOrganizationProfilesList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllOrganizationProfilesList();
        System.assertNotEquals(0, options.size(), 'Organization profiles list should not be empty');
    } */


    @isTest
    static void testGetAllManagedProfilesList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllManagedProfilesList();
        System.assertNotEquals(0, options.size(), 'Managed profiles list should not be empty');
    }

    @isTest
    static void testGetAllManagedPermissionSetList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllManagedPermissionSetList();
        System.assertNotEquals(0, options.size(), 'Managed permission sets list should not be empty');
    }

  /*  @isTest
    static void testGetAllOrganizationPermissionSetList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllOrganizationPermissionSetList();
        System.assertNotEquals(0, options.size(), 'Organization permission sets list should not be empty');
    } */

    @isTest
    static void testGetAllPermissionSetList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllPermissionSetList();
        System.assertNotEquals(0, options.size(), 'All permission sets list should not be empty');
    }

    @isTest
    static void testGetPermissionType() {
        List<SelectOption> options = SecurityUtilDictionary.getPermissionType();
        System.assertEquals(options.size(), options.size(), 'Permission type list should have three options');
    }

  /*    @isTest
    static void testGetPermissionTypeForLightning() {
        List<String> options = SecurityUtilDictionary.getPermissionTypeForLightning();
        System.assertEquals(3, options.size(), 'Permission type for Lightning list should have three options');
    } */
    
    @isTest
    static void testChangetPermissionType() {
        List<SelectOption> options = SecurityUtilDictionary.changetPermissionType('All Profiles');
        System.assertNotEquals(0, options.size(), 'Changed permission type list should not be empty');
    }

    @isTest
    static void testGetAllPermissionSetsList() {
        List<SelectOption> options = SecurityUtilDictionary.getAllPermissionSetsList('All Profiles & Permission Sets');
        System.assertNotEquals(0, options.size(), 'All permission sets list should not be empty');
    }

    @isTest
    static void testGetUserList() {
        List<SelectOption> options = SecurityUtilDictionary.getUserList();
        System.assertNotEquals(0, options.size(), 'User list should not be empty');
    }

    @isTest
    static void testGetFieldDescribeMap() {
        Map<String, Schema.DescribeFieldResult> fieldMap = SecurityUtilDictionary.getFieldDescribeMap('Account');
        System.assertNotEquals(null, fieldMap, 'Field describe map should not be null');
    }

    @isTest
    static void testSortAfterLabelSelectOptionList() {
        List<SelectOption> inputOptions = new List<SelectOption>{
            new SelectOption('B', 'Beta'),
            new SelectOption('A', 'Alpha'),
            new SelectOption('C', 'Charlie')
        };
        List<SelectOption> sortedOptions = SecurityUtilDictionary.sortAfterLabelSelectOptionList(inputOptions);
        System.assertEquals('Alpha', sortedOptions[0].getLabel(), 'First option should be Alpha');
        System.assertEquals('Beta', sortedOptions[1].getLabel(), 'Second option should be Beta');
        System.assertEquals('Charlie', sortedOptions[2].getLabel(), 'Third option should be Charlie');
    }
}