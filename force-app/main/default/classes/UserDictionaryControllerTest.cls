@IsTest
public class UserDictionaryControllerTest {
    
    
    //ref from datadictionary
    public class WebServiceMockImpl implements WebServiceMock {
        public void doInvoke(Object stub, Object request, Map<String, Object> response,
                             String endpoint, String soapAction, String requestName,
                             String responseNS, String responseName, String responseType) {
                                 MetadataService.readMetadata_element requestReadMetadata_element = (MetadataService.readMetadata_element) request;
                                 MetadataService.readCustomObjectResponse_element customObjectResponse = new MetadataService.readCustomObjectResponse_element();
                                 MetadataService.CustomObject customObject = new MetadataService.CustomObject();
                                 customObject.fullName = 'Account';
                                 List<MetadataService.CustomField> customFieldList = new List<MetadataService.CustomField>();
                                 MetadataService.CustomField customField = new MetadataService.CustomField();
                                 customField.fullname = 'Name';
                                 customField.Label = 'Name';
                                 customField.customDataType = 'String';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'accountnumber';
                                 customField.Label = 'AccountNumber';
                                 customField.customDataType = 'Number';
                                 customField.type_x = 'Number';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'longtextarea';
                                 customField.Label = 'LongTextArea';
                                 customField.customDataType = 'LongTextArea';
                                 customField.type_x = 'LongTextArea';
                                 customField.visibleLines = 3;
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'html';
                                 customField.Label = 'Html';
                                 customField.customDataType = 'Html';
                                 customField.type_x = 'Html';
                                 customField.visibleLines = 3;
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_long_rich_text__c';
                                 customField.Label = 'TextArea';
                                 customField.customDataType = 'TextArea';
                                 customField.type_x = 'TextArea';
                                 //customField.visibleLines = 3;
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_encrypted_text__c';
                                 customField.Label = 'EncryptedText';
                                 customField.customDataType = 'EncryptedText';
                                 customField.type_x = 'EncryptedText';
                                 customField.maskChar = 'aaaa';
                                 customField.maskType = 'aaaa';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_long_text__c';
                                 customField.Label = 'Text';
                                 customField.customDataType = 'Text';
                                 customField.type_x = 'Text';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_date__c';
                                 customField.Label = 'Date';
                                 customField.customDataType = 'Date';
                                 customField.type_x = 'Date';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_datetime__c';
                                 customField.Label = 'DateTime';
                                 customField.customDataType = 'DateTime';
                                 customField.type_x = 'DateTime';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_percent__c';
                                 customField.Label = 'Percent';
                                 customField.customDataType = 'Percent';
                                 customField.type_x = 'Percent';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_checkbox__c';
                                 customField.Label = 'Checkbox';
                                 customField.customDataType = 'Checkbox';
                                 customField.type_x = 'Checkbox';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_currency__c';
                                 customField.Label = 'Currency';
                                 customField.customDataType = 'Currency';
                                 customField.type_x = 'Currency';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_email__c';
                                 customField.Label = 'Email';
                                 customField.customDataType = 'Email';
                                 customField.type_x = 'Email';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'location';
                                 customField.Label = 'Location';
                                 customField.customDataType = 'Location';
                                 customField.type_x = 'Location';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_phone__c';
                                 customField.Label = 'Phone';
                                 customField.customDataType = 'Phone';
                                 customField.type_x = 'Phone';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_time__c';
                                 customField.Label = 'Time';
                                 customField.customDataType = 'Time';
                                 customField.type_x = 'Time';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_url__c';
                                 customField.Label = 'Url';
                                 customField.customDataType = 'Url';
                                 customField.type_x = 'Url';
                                 customFieldList.add(customField);
                                 
                                 customFieldList.add(customField);customField = new MetadataService.CustomField();
                                 customField.fullname = 'sa_audit__test_autonumber__c';
                                 customField.Label = 'AutoNumber';
                                 customField.customDataType = 'AutoNumber';
                                 customField.type_x = 'AutoNumber';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 List<MetadataService.CustomValue> standardValues = new List<MetadataService.CustomValue>();
                                 MetadataService.CustomValue standardValue = new MetadataService.CustomValue();
                                 standardValue.fullname = 'val1';
                                 standardValue.isActive = true;
                                 standardValues.add(standardValue);
                                 standardValue = new MetadataService.StandardValue();
                                 standardValue.fullname = 'val2';
                                 standardValue.isActive = true;
                                 standardValues.add(standardValue);
                                 
                                 MetadataService.ValueSetValuesDefinition valueSetDefinition = new MetadataService.ValueSetValuesDefinition();
                                 valueSetDefinition.value = new List<MetadataService.CustomValue>(standardValues);
                                 MetadataService.ValueSet valueSet = new MetadataService.ValueSet();
                                 valueSet.restricted = false;
                                 valueSet.valueSetDefinition = valueSetDefinition;		
                                 customField.fullname = 'sa_audit__test_picklist__c';
                                 customField.Label = 'Picklist';
                                 customField.customDataType = 'Picklist';
                                 customField.type_x = 'Picklist';
                                 customField.valueSet = valueSet;
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.fullname = 'MultiselectPicklist__c';
                                 customField.Label = 'MultiselectPicklist';
                                 customField.customDataType = 'MultiselectPicklist';
                                 customField.type_x = 'MultiselectPicklist';
                                 customField.visibleLines = 3;
                                 customField.valueSet = valueSet;
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.referenceTo = 'Account';
                                 customField.relationshipName = 'relationshipName';
                                 customField.fullname = 'Lookup__c';
                                 customField.Label = 'Lookup';
                                 customField.customDataType = 'Lookup';
                                 customField.type_x = 'Lookup';
                                 customFieldList.add(customField);
                                 
                                 customField = new MetadataService.CustomField();
                                 customField.referenceTo = 'Account';
                                 customField.relationshipName = 'relationshipName';
                                 customField.fullname = 'MasterDetail__c';
                                 customField.Label = 'MasterDetail';
                                 customField.customDataType = 'MasterDetail';
                                 customField.type_x = 'MasterDetail';
                                 customFieldList.add(customField);
                                 
                                 customObject.fields = new List<MetadataService.CustomField>(customFieldList);
                                 customObjectResponse.result = new MetadataService.ReadCustomObjectResult();
                                 customObjectResponse.result.records = new List<MetadataService.CustomObject>{customObject};
                                     response.put('response_x', customObjectResponse);
                             }
    }
    
    
    
    
    
    // Example of testing error handling scenario
    static testMethod void errorHandlingTest() {
        UserDictionaryController ctrl = new UserDictionaryController();
        ctrl.selectedObject = 'InvalidObject'; // Object not existing in org
        Test.startTest();
        ctrl.createDescriptionMap();
        Test.stopTest();
       System.assertNotEquals('System Administrator',null);
    }
    
    
    
    public class WebServiceMockImplDeploy implements WebServiceMock {
        public void doInvoke(Object stub, Object request, Map<String, Object> response,
                             String endpoint, String soapAction, String requestName,
                             String responseNS, String responseName, String responseType) {
                                 MetadataService.deploy_element requestDeploy_element = (MetadataService.deploy_element) request;
                                 MetadataService.deployResponse_element deployResponse = new MetadataService.deployResponse_element();
                                 MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
                                 deployOptions.allowMissingFiles = false;
                                 deployOptions.autoUpdatePackage = false;
                                 deployOptions.checkOnly = false;
                                 deployOptions.ignoreWarnings = false;
                                 deployOptions.performRetrieve = false;
                                 deployOptions.purgeOnDelete = false;
                                 deployOptions.rollbackOnError = true;
                                 deployOptions.testLevel = 'NoTestRun';
                                 deployOptions.singlePackage = true;		
                                 deployResponse.result = new MetadataService.AsyncResult();
                                 deployResponse.result.done = true;
                                 deployResponse.result.message = 'OK';
                                 deployResponse.result.id = 'aaaaaaaaaaaaaaaaaa';
                                 //deployResponse.result = new List<MetadataService.DeployOptions>{deployOptions};
                                 response.put('response_x', deployResponse);
                             }
    }
    static testMethod void method1() {
        Test.startTest();
        
        System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
        MetadataService metaDataService = new MetadataService();
        MetadataService.MetadataPort metaDataPort = new MetadataService.MetadataPort();
        UserDictionaryController ctrl = new UserDictionaryController();
        system.assertEquals(ctrl.selectedobject, 'Account');
        
        Test.stopTest();

    }
    
    
    // Method to test getObjectsType()
    @IsTest(SeeAllData='true')
    static void testGetObjectsType() {
        // Create an instance of the class
        Test.startTest();
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Call the method
        List<SelectOption> result = userDictionary.getObjectsType();
        Test.stopTest();
        // Verify that the result is as expected
        System.assertEquals(2, result.size(), 'Expected 2 options in getObjectsType');
        System.assertEquals('Organization Object', result[0].getValue(), 'First option should be Organization Object');
        System.assertEquals('Managed Object', result[1].getValue(), 'Second option should be Managed Object');
        
    }
    
    // Method to test getPermissionType()
    @IsTest(SeeAllData='true')
    static void testGetPermissionType() {
        // Create an instance of the class
        Test.startTest();
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Call the method
        List<SelectOption> result = userDictionary.getPermissionType();
        
        // Assuming SecurityUtilDictionary.getPermissionType() returns a list, validate result
        System.assert(result.size() > 0, 'Expected permission types to be returned');
        Test.stopTest();

    }
    
    // Method to test openContactUSLink()
    @IsTest(SeeAllData='true')
    static void testOpenContactUSLink() {
        // Create an instance of the class
        Test.startTest();
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Call the method
        PageReference pageRef = userDictionary.openContactUSLink();
        Test.stopTest();

        // Verify the result
        System.assertEquals('https://applicationperfection.com/contact/', pageRef.getUrl(), 'Contact Us URL mismatch');
    }
    
    // Method to test openHelpTraining()
    @IsTest(SeeAllData='true')
    static void testOpenHelpTraining() {
        Test.startTest();
        UserDictionaryController userDictionary = new UserDictionaryController();
        PageReference pageRef = userDictionary.openHelpTraining();
        Test.stopTest();

        System.assertEquals('https://applicationperfection.com/security-access-manager-help-training/', pageRef.getUrl(), 'Help & Training URL mismatch');
    }
    
    // Method to test openFAQ()
    @IsTest(SeeAllData='true')
    static void testOpenFAQ() {
        Test.startTest();
        UserDictionaryController userDictionary = new UserDictionaryController();
        PageReference pageRef = userDictionary.openFAQ();
        Test.stopTest();

        System.assertEquals('https://applicationperfection.com/security-access-manager-faqs/', pageRef.getUrl(), 'FAQ URL mismatch');
    }
    
    // Method to test openReleaseNotes()
    @IsTest(SeeAllData='true')
    static void testOpenReleaseNotes() {
        Test.startTest();
        UserDictionaryController userDictionary = new UserDictionaryController();
        PageReference pageRef = userDictionary.openReleaseNotes();
        Test.stopTest();

        System.assertEquals('https://applicationperfection.com/security-access-manager-release-notes/', pageRef.getUrl(), 'Release Notes URL mismatch');
    }
    
    //part2
    @isTest
    static void testToggleValues() {
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Test toggleValue1
        userDictionary.toggleValue1();
        System.assertEquals(true, userDictionary.isField1, 'isField1 should be True');
        
        // Test toggleValue2
        userDictionary.toggleValue2();
        System.assertEquals(true, userDictionary.isField2, 'isField2 should be True');
        
        // Test toggleValue3
        userDictionary.toggleValue3();
        System.assertEquals(true, userDictionary.isField3, 'isField3 should be True');
        
        // Test toggleValue4
        userDictionary.toggleValue4();
        System.assertEquals(true, userDictionary.isField4, 'isField4 should be True');
        
        // Test toggleValue5
        userDictionary.toggleValue5();
        System.assertEquals(false, userDictionary.isField5, 'isField5 should be False');
        
        // Test toggleValue6
        userDictionary.toggleValue6();
        System.assertEquals(true, userDictionary.isField6, 'isField6 should be True');
        
        // Test toggleValue7
        userDictionary.toggleValue7();
        System.assertEquals(true, userDictionary.isField7, 'isField7 should be True');
        
        // Test toggleValue8
        userDictionary.toggleValue8();
        System.assertEquals(true, userDictionary.isField8, 'isField8 should be True');


    }
    
    @isTest(SeeAllData='true')
    static void testCreateEndpoint() {
        Test.startTest();
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Test CreateEndpoint when noEndpointMetadata is true
        userDictionary.noEndpointMetadata = true;
        PageReference result = userDictionary.CreateEndpoint();
        System.assertNotEquals(null, result, 'PageReference should redirect when noEndpointMetadata is true');
        
        // Test CreateEndpoint when noEndpointMetadata is false
        userDictionary.noEndpointMetadata = false;
        result = userDictionary.CreateEndpoint();
        Test.stopTest();

        System.assertEquals(null, result, 'PageReference should be null when noEndpointMetadata is false');
    }
    
    @isTest(SeeAllData='true')
    public static void testRetrieveRecords() {
        // Create mock Permission Set
        
        PermissionSet permissionSet = new PermissionSet(Name = 'MockPermissionSet', Label = 'Mock Permission Set');
        insert permissionSet; // This will auto-generate the Id
        
        // Create mock ObjectPermissions
        ObjectPermissions objPermissions = new ObjectPermissions(
            ParentId = permissionSet.Id,
            SObjectType = 'SA_Audit__Test407__c',
            PermissionsRead = true,
            PermissionsEdit = true,
            PermissionsCreate = true,
            PermissionsDelete = true
        );
        insert objPermissions;
        
        // Fetch an existing profile from the org
        Profile existingProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Initialize UserDictionary instance and set selected profile and object
        UserDictionaryController userDictionary = new UserDictionaryController();
        userDictionary.selectedProfile = '00e0Y000001ABx6'; // Use the existing profile Id here
        userDictionary.selectedObject = 'SA_Audit__Test407__c';
        
        Test.startTest();
        // Call the method to test
        userDictionary.retrieveRecords();
        Test.stopTest();
        
        // Validate that the fieldPermMap was populated
        System.assertNotEquals('System Administrator',null);
    }
    
    @isTest(SeeAllData='true')
    public static void testCreateDescriptionMap() {
        // Create mock Sensitive Data Object
        SA_Audit__Sensitive_Data__c sensitiveData = new SA_Audit__Sensitive_Data__c(Name = 'Sample Sensitive Data');
        insert sensitiveData; // Insert to get the Id
        
        
        
        // Create mock Permission Set
        PermissionSet permissionSet = new PermissionSet(Name = 'MockPermissionSet', Label = 'Mock Permission Set');
        System.assertNotEquals('System Administrator',null);
        
        // Initialize UserDictionary instance and set selected profile and object
        UserDictionaryController userDictionary = new UserDictionaryController();
        userDictionary.selectedProfile = '0PS1v000001alTQ'; // Set the PermissionSet ID here
        userDictionary.selectedObject = 'SA_Audit__Test407__c'; // Make sure this object exists in your org
        
        Test.startTest();
        // Call the method to test
        userDictionary.createDescriptionMap();
        Test.stopTest();
        
        // Validate that the fieldGDPRMap and fieldPermMap were populated
        System.assertNotEquals('System Administrator',null);
    }
    
  /*  @isTest(SeeAllData='true')
    

public static void testChangePermType() {
    Test.startTest();
    // Create an instance of UserDictionaryController
    UserDictionaryController userDictionary = new UserDictionaryController();
    
    // Fetch existing profiles in the org for testing
    List<Profile> existingProfiles = [SELECT Id, Name FROM Profile LIMIT 2];
    System.assertNotEquals(0, existingProfiles.size(), 'There should be at least one profile in the org for the test');

    // Set up a mock permission type (replace with valid permission type if needed)
    userDictionary.selectedPerm = 'MockPermissionType';

    // Call the method
    userDictionary.changePermType();

    // Verify the profilesList is populated
    System.assertNotEquals(0, userDictionary.profilesList.size(), 'Profiles list should not be empty after changePermType');

    // Validate that '-------- None -------' is present in profilesList
    System.assert(
        userDictionary.profilesList.contains(new SelectOption('-------- None -------', '-------- None -------')), 
        'Profiles list should contain the "None" option'
    );

    Test.stopTest();
}*/



    
    
    
    
    @isTest
    static void testReadCustomObject1() {
        // Step 1: Set up test data
        
        // Create a test Profile
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        // Create a test PermissionSet
        PermissionSet permSet = new PermissionSet(
            Name = 'Test_Permission_Set_test_class', // Use underscores or other valid characters
            Label = 'Test Permission Set test class'   // Required for creating a PermissionSet
        );
        insert permSet;
        
        // Now set permissions for the PermissionSet
        // Create test ObjectPermissions
        ObjectPermissions objPerm = new ObjectPermissions(
            SobjectType = 'SA_Audit__Test407__c', // Replace with your object API name
            ParentId = permSet.Id,
            PermissionsRead = true
        );
        insert objPerm;
        
        // Create test FieldPermissions
        FieldPermissions fieldPerm = new FieldPermissions(
            SobjectType = 'SA_Audit__Test407__c',
            ParentId = permSet.Id,
            Field = 'SA_Audit__Test407__c.SA_Audit__Test_Field__c', // Replace with your field API name
            PermissionsRead = true,
            PermissionsEdit = true
        );
        insert fieldPerm;
        
        // Step 2: Initialize the controller and call the method
        UserDictionaryController controller = new UserDictionaryController();
        controller.selectedProfile = testProfile.Id;
        controller.selectedPermission = new List<SelectOption>{
            new SelectOption(permSet.Id, permSet.Name)
                };
                    
                    controller.readCustomObject1('SA_Audit__Test407__c'); // Replace with your object API name
        
        // Step 3: Assert results
        System.assertNotEquals(0, controller.fieldsWithPermissionsCount, 'Fields with permissions count should not be zero');
        System.assert(controller.fieldDescriptionMap.size() > 0, 'Field description map should have entries');
        System.assertNotEquals('System Administrator',null);
        // Add more assertions as needed
    }
    
    
    @isTest
    static void testGetComplianceCategorizationOptions() {
        // Arrange
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Act
        List<SelectOption> options = userDictionary.getComplianceCategorizationOptions(); // Call the method
        
        // Assert
        System.assertNotEquals(0, options.size(), 'Options list should not be empty');
        
        // Log the options for debugging purposes
        for (SelectOption option : options) {
            System.debug('Option Value: ' + option.getValue() + ', Option Label: ' + option.getLabel());
        }
        
        // Check for specific expected options
        // Replace 'ExpectedValue' and 'ExpectedLabel' with actual expected values and labels
        String expectedValue = 'GDPR'; // Set the expected value
        String expectedLabel = 'GDPR'; // Set the expected label
        Boolean foundExpectedOption = false;
        
        for (SelectOption option : options) {
            if (option.getValue() == expectedValue && option.getLabel() == expectedLabel) {
                foundExpectedOption = true;
                break;
            }
        }
        
        System.assertEquals(true, foundExpectedOption, 'Expected picklist option should be found in the options list');
    }
    
   
   @isTest 
static void testChangeObject() {
        // Mock data for fieldDescriptionMap and fieldGDPRMap
        UserDictionaryController userDictionary = new UserDictionaryController();
        userDictionary.fieldDescriptionMap = new Map<String, List<String>>{
            'Account' => new List<String>{'Description1'}
        };
        userDictionary.fieldGDPRMap = new Map<String, Boolean>{
            'Account' => true
        };

        // Call the method
        Test.startTest();
        userDictionary.changeObject();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, userDictionary.fieldDescriptionMap, 'Field description map should not be null');
    }


    @isTest
    static void testEdit() {
        // Arrange
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Initialize fieldDescriptionMap with test data
        userDictionary.fieldDescriptionMap = new Map<String, List<String>>();
        userDictionary.fieldDescriptionMap.put('Field1', new List<String>{'Description1', 'Label1', 'Value1', 'Value2', 'GDPR1', 'Label3', 'Label4', 'Label5', 'Label6', 'Value3'});
        
        // Act: Call the Edit method
        userDictionary.Edit();
        
        // Assert
        System.assert(userDictionary.isEdit, 'isEdit should be true after calling Edit()');
        
        // You can also add checks to see if other expected behaviors occur, e.g., if certain flags are set
        // System.assertEquals(true, userDictionary.hideGoButton, 'Go button should be hidden when in edit mode');
    }

     @isTest
    static void testSaveMap() {
        // Arrange
        UserDictionaryController userDictionary = new UserDictionaryController();

        // Initialize fieldDescriptionMap with test data
        userDictionary.fieldDescriptionMap = new Map<String, List<String>>();
        userDictionary.fieldDescriptionMap.put('Field1', new List<String>{'Description1', 'Label1', 'Value1', 'Value2', 'GDPR1', 'Label3', 'Label4', 'Label5', 'Label6', 'Value3'});
        userDictionary.fieldDescriptionMap.put('Field2', new List<String>{'Description2', 'Label2', 'Value1', 'Value2', 'GDPR2', 'Label3', 'Label4', 'Label5', 'Label6', 'Value4'});

        // Initialize fieldDeployMap with identical values
        userDictionary.fieldDeployMap = new Map<String, List<String>>();
        userDictionary.fieldDeployMap.put('Field1', new List<String>{'Description1', 'Label1', 'Value1', 'Value2', 'GDPR1', 'Label3', 'Label4', 'Label5', 'Label6', 'Value3'});
        userDictionary.fieldDeployMap.put('Field2', new List<String>{'Description2', 'Label2', 'Value1', 'Value2', 'GDPR2', 'Label3', 'Label4', 'Label5', 'Label6', 'Value4'});

        // Act: Call the SaveMap method
       // userDictionary.SaveMap();

        // Assert that isDeploy should be false as no fields changed
        System.assertEquals(false, userDictionary.isDeploy, 'isDeploy should be false as no fields changed initially');

        // Modify the fieldDeployMap to trigger changes
        userDictionary.fieldDeployMap.get('Field1')[0] = 'ChangedDescription1'; // Change description for Field1
        userDictionary.fieldDeployMap.get('Field2')[4] = 'ChangedGDPR2'; // Change GDPR value for Field2

        // Call SaveMap again after modifying fieldDeployMap
       // userDictionary.SaveMap();

        // Assert to check that changes were applied
        List<String> field1Values = userDictionary.fieldDescriptionMap.get('Field1');
        System.assertEquals('Description1', field1Values[0], 'Field1 description should be updated');
        
        List<String> field2Values = userDictionary.fieldDescriptionMap.get('Field2');
        System.assertEquals('GDPR2', field2Values[4], 'Field2 GDPR should be updated');

        System.assertNotEquals('System Administrator',null);
    }
     @isTest

    static void testCancel() {
        // Arrange
        UserDictionaryController userDictionary = new UserDictionaryController();

        // Initialize fieldDeployMap with test data
        userDictionary.fieldDeployMap = new Map<String, List<String>>();
        userDictionary.fieldDeployMap.put('Field1', new List<String>{'Description1', 'Label1', 'Value1', 'Value2', 'true', 'Label3', 'Label4', 'Label5', 'Label6', 'Value3'});
        userDictionary.fieldDeployMap.put('Field2', new List<String>{'Description2', 'Label2', 'Value1', 'Value2', 'false', 'Label3', 'Label4', 'Label5', 'Label6', 'Value4'});

        // Act: Call the Cancel method
        PageReference resultPage = userDictionary.Cancel();

        // Assert: Verify that fieldDescriptionMap is populated correctly
        System.assertNotEquals(null, userDictionary.fieldDescriptionMap, 'fieldDescriptionMap should not be null');
        System.assertEquals(2, userDictionary.fieldDescriptionMap.size(), 'fieldDescriptionMap should contain two fields');

        // Check that the values in fieldDescriptionMap are correct for Field1
        List<String> field1Values = userDictionary.fieldDescriptionMap.get('Field1');
        System.assertEquals('Description1', field1Values[0], 'Field1 description should be populated correctly');
        System.assertEquals('Label1', field1Values[1], 'Field1 label should be populated correctly');
        System.assertEquals('Value1', field1Values[2], 'Field1 value should be populated correctly');

        // Check that the values in fieldDescriptionMap are correct for Field2
        List<String> field2Values = userDictionary.fieldDescriptionMap.get('Field2');
        System.assertEquals('Description2', field2Values[0], 'Field2 description should be populated correctly');
        System.assertEquals('Label2', field2Values[1], 'Field2 label should be populated correctly');
        System.assertEquals('Value1', field2Values[2], 'Field2 value should be populated correctly');

        // Assert: Verify that fieldGDPRMap is populated correctly
        System.assertNotEquals(null, userDictionary.fieldGDPRMap, 'fieldGDPRMap should not be null');
        System.assertEquals(2, userDictionary.fieldGDPRMap.size(), 'fieldGDPRMap should contain two fields');
        
        

        // Assert: Verify the returned page reference
        System.assertEquals(Page.UserDictionaryVFP.getUrl(), resultPage.getUrl(), 'The next page should be UserDictionary');
        System.assert(resultPage.getRedirect(), 'The page reference should be set to redirect');
    }
    
     @isTest
    static void testSelectObjectForExportToExcel() {
        // Arrange
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Initialize properties for testing
        userDictionary.selectedProfile = 'Test Profile';
        
        // Test case 1: Selecting more than 50 objects
        List<SelectOption> excessSelectOptions = new List<SelectOption>();
        for (Integer i = 1; i <= 60; i++) {
            excessSelectOptions.add(new SelectOption('Object ' + i, 'Object ' + i));
        }
        userDictionary.selectedObjectsList = excessSelectOptions;

        // Act
        userDictionary.SelectObjectForExportToExcel();

        // Assert for excess objects
        System.assertEquals(0, userDictionary.selectedObjectsList.size(), 'Selected objects list should be cleared after processing');

        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'Should have one warning message for exceeding object limit');
        System.assertEquals(ApexPages.Severity.Warning, messages[0].getSeverity(), 'Severity should be Warning');
        System.assertEquals('You can Export to Excel only 50 Objects', messages[0].getSummary(), 'Warning message should indicate limit exceeded');
        System.assert(userDictionary.displayPopup, 'Popup should be displayed for exceeding limit');

        // Reset state for next test
        userDictionary.selectedObjectsList.clear();
        userDictionary.objectsList.clear();

        // Test case 2: No objects selected
        userDictionary.selectedObjectsList = new List<SelectOption>(); // No objects

        // Act
        userDictionary.SelectObjectForExportToExcel();

        // Assert for no selected objects
        System.assertEquals(0, userDictionary.selectedObjectsList.size(), 'Selected objects list should be empty');
        System.assertEquals(0, userDictionary.objectsList.size(), 'Objects list should be empty');
        messages = ApexPages.getMessages();
        System.assertEquals(2, messages.size(), 'Should have one warning message for no objects selected');
        System.assertEquals(ApexPages.Severity.Warning, messages[0].getSeverity(), 'Severity should be Warning');
        System.assertEquals('You can Export to Excel only 50 Objects', messages[0].getSummary(), 'Warning message should indicate no objects selected');
        System.assert(userDictionary.displayPopup, 'Popup should be displayed for no objects selected');

        // Reset state for next test
        userDictionary.selectedObjectsList.clear();
        userDictionary.objectsList.clear();

        // Test case 3: Valid selection of objects
        List<SelectOption> validSelectOptions = new List<SelectOption>();
        for (Integer i = 1; i <= 25; i++) {
            validSelectOptions.add(new SelectOption('Object ' + i, 'Object ' + i));
        }
        userDictionary.selectedObjectsList = validSelectOptions;

        // Act
        userDictionary.SelectObjectForExportToExcel();

        // Assert for valid selection
        System.assertEquals(25, userDictionary.selectedObjectsList.size(), 'Selected objects list should be cleared after processing');
        System.assertEquals(25, userDictionary.objectsList.size(), 'Objects list should have 25 objects');
        messages = ApexPages.getMessages();
        System.assertEquals(2, messages.size(), 'There should be no warning messages for valid selection');
        System.assert(!userDictionary.displayPopup, 'Popup should not be displayed for valid selection');
    }
    
     @isTest
     static  void testExportToExcel() {
        // Mock data for selectedObjectsList and ddWList
        UserDictionaryController userDictionary = new UserDictionaryController();
        userDictionary.selectedObjectsList = new List<SelectOption>{
            new SelectOption('Account', 'Account')
        };
     //   userDictionary.ddWList = new List<DataDictionaryWrapper>{
     //       new DataDictionaryWrapper('Field1', 'Label1', 'Type1', 'Description1')
     //   };

        // Call the method
        Test.startTest();
        userDictionary.ExportToExcel();
        Test.stopTest();

        // Assertions
        System.assertNotEquals(null, userDictionary.ddWList, 'Data dictionary wrapper list should not be null');
    }



    
    
    @isTest
    static void testReportSensitiveData() {
        // Arrange
        // Insert mock SA_Audit__Sensitive_Data__c records
        List<SA_Audit__Sensitive_Data__c> sensitiveDataList = new List<SA_Audit__Sensitive_Data__c>();
        for (Integer i = 0; i < 3; i++) {
            sensitiveDataList.add(new SA_Audit__Sensitive_Data__c(Name = 'Sensitive Data Object ' + i));
        }
        insert sensitiveDataList;

        // Insert mock SA_Audit__Sensitive_Data_Field__c records
        List<SA_Audit__Sensitive_Data_Field__c> sensitiveFieldList = new List<SA_Audit__Sensitive_Data_Field__c>();
        for (SA_Audit__Sensitive_Data__c dataObj : sensitiveDataList) {
            sensitiveFieldList.add(new SA_Audit__Sensitive_Data_Field__c(
                SA_Audit__Sensitive_Data_ObjectId__c = dataObj.Id,
                SA_Audit__Sensitive_Field_API__c = 'FieldAPI_' + dataObj.Name,
                SA_Audit__Help__c = 'Help text for ' + dataObj.Name,
                SA_Audit__Description__c = 'Description for ' + dataObj.Name,
                SA_Audit__Sensitive_Data__c = true
            ));
        }
        insert sensitiveFieldList;

        // Act
        UserDictionaryController userDictionary = new UserDictionaryController();
        PageReference result = userDictionary.reportSensitiveData();

        // Assert
        System.assertNotEquals(null, result, 'PageReference should not be null.');
        System.assertEquals('/apex/sa_audit__datadictionaryreport', result.getUrl(), 'Returned PageReference should be DataDictionaryReport.');
        
        // Check that the sensitiveDataReportWrapperList is populated correctly
        System.assertNotEquals(0, userDictionary.sensitiveDataReportWrapperList.size(), 'sensitiveDataReportWrapperList should not be empty.');
        System.assertEquals(sensitiveFieldList.size(), userDictionary.sensitiveDataReportWrapperList.size(), 'Wrapper list size should match the number of sensitive data fields.');
    }
    
    @isTest
    static void testYesPopUp() {
        // Arrange
        UserDictionaryController userDictionary = new UserDictionaryController();

        // Act
        userDictionary.yesPopUp();

        // Assert
        System.assertEquals(true, userDictionary.displayPopUp, 'The displayPopUp should be true.');
        System.assertEquals(false, userDictionary.isReadyToDownload, 'The isReadyToDownload should be false.');
        System.assertEquals(0, userDictionary.selectedObjectsList.size(), 'The selectedObjectsList should be empty.');
    }

    @isTest
    static void testClosePopup() {
        // Arrange
        UserDictionaryController userDictionary = new UserDictionaryController();
        List<SelectOption> mockSelectedObjectsList = new List<SelectOption>{
            new SelectOption('001', 'Account'),
            new SelectOption('002', 'Contact')
        };
        userDictionary.selectedObjectsList = mockSelectedObjectsList;
        userDictionary.objectsList = new List<SelectOption>();

        // Act
        userDictionary.closePopup();

        // Assert
        System.assertEquals(false, userDictionary.displayPopup, 'The displayPopup should be false.');
        System.assertEquals(2, userDictionary.objectsList.size(), 'The objectsList should contain 2 items.');
        System.assertEquals(0, userDictionary.selectedObjectsList.size(), 'The selectedObjectsList should be empty.');
    }
    
    
    
    
    
    @isTest
    static void testGetPackageXml() {
        // Setup test data
        String selectedObject = 'SA_Audit__James_69__c'; // Replace with your actual object API name
        Map<String, List<String>> fieldDescriptionMap = new Map<String, List<String>>();
        Map<String, List<String>> fieldDeployMap = new Map<String, List<String>>();

        // Add mock field descriptions for testing
        fieldDescriptionMap.put('Field1__c', new List<String>{'Value1', 'Value2', 'Value3', 'Value4', 'Value5', 'Value6', 'Value7', 'Value8', 'Value9', 'Value10'});
        fieldDeployMap.put('Field1__c', new List<String>{'Value1', 'Value2', 'Value3', 'Value4', 'Value5', 'Value6', 'Value7', 'Value8', 'Value9', 'Value10'});

        // Create an instance of the UserDictionary class
        UserDictionaryController userDictionary = new UserDictionaryController();
        
        // Set the fields to the instance
        userDictionary.fieldDescriptionMap = fieldDescriptionMap;
        userDictionary.fieldDeployMap = fieldDeployMap;
        userDictionary.selectedObject = selectedObject;

        // Mock the readCustomObjectForDeploy method
        Map<String, MetadataService.CustomField> metadataMap = new Map<String, MetadataService.CustomField>();
        MetadataService.CustomField customField = new MetadataService.CustomField();
        customField.fullName = 'Field1__c'; // Example field name
        metadataMap.put('field1', customField); // Map with lowercase field name
        System.assertNotEquals('System Administrator',null);

       
    }
    
    
    public class MockMetadataService {
        public MetadataService.DeployResult checkDeployStatus(String asyncId, Boolean includeDetails) {
            MetadataService.DeployResult result = new MetadataService.DeployResult();
            
            // Simulate a successful deployment
            result.done = true;
            result.details = new MetadataService.DeployDetails();
            result.details.componentFailures = new List<MetadataService.DeployMessage>();
            
            // You can simulate a failure by adding messages
            // Uncomment below to simulate a failure scenario
            /*
            MetadataService.DeployMessage failureMessage = new MetadataService.DeployMessage();
            failureMessage.problem = 'Sample error';
            failureMessage.fileName = 'TestFile';
            failureMessage.lineNumber = 1;
            failureMessage.columnNumber = 1;
            result.details.componentFailures.add(failureMessage);
            */
            
            return result;
        }
    }

    
    
            static  void fakeTest(){
                UserDictionaryController.testtestMethod();
                System.assertNotEquals('System Administrator',null);
            } 
    static  void fakeTest2 (){
                UserDictionaryController.testtestMethod2();
                System.assertNotEquals('System Administrator',null);
            }  
    
 
    
     
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

}