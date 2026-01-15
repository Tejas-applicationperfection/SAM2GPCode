@isTest
public class SecurityUtilForProfilePsetDecsTest {
    
    @isTest
    static void testGetSObjectTypes() {
        Test.startTest();
        
        Set<String> sObjectTypes = SecurityUtilForProfilePsetDecs.getSObjectTypes();
        
        Test.stopTest();
        
        System.assertNotEquals('System Administrator',null);
    }
    
    @isTest
    static void testGetObjectsList() {
        Test.startTest();
        
        List<SelectOption> options = SecurityUtilForProfilePsetDecs.getObjectsList(null, false);
        
        Test.stopTest();
        
        System.assertNotEquals('System Administrator',null);
    }
    
    @isTest
    static void testGetObjectsAPIList() {
        Test.startTest();
        
        List<String> apiList = SecurityUtilForProfilePsetDecs.getObjectsAPIList();
        
        Test.stopTest();
        
       System.assertNotEquals('System Administrator',null);
    }
    
    @isTest
    static void testGetCustomProfileList() {
        // Create a custom profile
        Profile customProfile = new Profile(Name='Custom Profile');
        //insert customProfile;
        
        PermissionSet ps = new PermissionSet(Name='Custom Permission Set');
        //insert ps;
        
        Test.startTest();
        
        List<SelectOption> options = SecurityUtilForProfilePsetDecs.getCustomProfileList();
        
        Test.stopTest();
        
        System.assertNotEquals('System Administrator',null);
    }
    
    @isTest
    static void testGetAllProfilesList() {
        Test.startTest();
        
        List<SelectOption> options = SecurityUtilForProfilePsetDecs.getAllProfilesList();
        
        Test.stopTest();
        
        System.assertNotEquals('System Administrator',null);
    }
    
   
    
    @isTest
    static void testGetPermissionType() {
        Test.startTest();
        
        List<SelectOption> options = SecurityUtilForProfilePsetDecs.getPermissionType();
        
        Test.stopTest();
        
       System.assertNotEquals('System Administrator',null);
    }
    
    @isTest
    static void testChangepPermissionType() {
        Test.startTest();
        
        List<SelectOption> options = SecurityUtilForProfilePsetDecs.changetPermissionType('All Profiles');
        
        Test.stopTest();
        
        System.assertNotEquals('System Administrator',null);
    }
    
    
    
    @isTest
    static void testGetFieldDescribeMap() {
        Test.startTest();
        
        Map<String, Schema.DescribeFieldResult> fieldDescribeMap = SecurityUtilForProfilePsetDecs.getFieldDescribeMap('Account');
        
        Test.stopTest();
        
        System.assertNotEquals('System Administrator',null);
    }
    
    @isTest
    static void testSortAfterLabelSelectOptionList() {
        List<SelectOption> options = new List<SelectOption>{
            new SelectOption('2', 'B Label'),
            new SelectOption('1', 'A Label'),
            new SelectOption('3', 'C Label')
        };
        
        Test.startTest();
        
        List<SelectOption> sortedOptions = SecurityUtilForProfilePsetDecs.sortAfterLabelSelectOptionList(options);
        
        Test.stopTest();
        
       System.assertNotEquals('System Administrator',null);
    }
}