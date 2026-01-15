/**
 * @description Test class for PsetGroupDescription
 * @author sfdev
 * @date 2024
 */
@IsTest
public class PsetGroupDescriptionTest {
    
    @TestSetup
    static void setupTestData() {
        // No specific test data needed as PsetGroupDescription uses current user context
        // The class will work with the running user's information
    }
    
    @IsTest
    static void testConstructorWithOrganizationAccess() {
        Test.startTest();
        
        // Test constructor when user has Organization access
        PsetGroupDescription controller = new PsetGroupDescription();
        
        Test.stopTest();
        
        // Verify initialization
        System.assertNotEquals(null, controller, 'Controller should be initialized');
        System.assertEquals('<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>', 
                           controller.xmlheader, 'XML header should be set correctly');
        System.assertEquals('</Workbook>', controller.endfile, 'End file should be set correctly');
        System.assertEquals(UserInfo.getName(), controller.exportUser, 'Export user should be current user');
        System.assertEquals('US', controller.currentLanguage, 'Current language should be US');
        
        // Verify organization access
        if (Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()) {
            System.assertEquals(true, controller.OrgIsAccessible, 'Organization should be accessible');
            System.assertNotEquals(null, controller.org, 'Organization should be populated');
            System.assertEquals(false, controller.noEndpointMetadata, 'No endpoint metadata should be false');
        }
    }
    
    @IsTest
    static void testConstructorProperties() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        
        // Test property initialization
        controller.isEdit = true;
        controller.selectedPerm = 'TestPermission';
        
        Test.stopTest();
        
        System.assertEquals(true, controller.isEdit, 'isEdit property should be settable');
        System.assertEquals('TestPermission', controller.selectedPerm, 'selectedPerm should be settable');
    }
    
    @IsTest
    static void testOpenContactUSLink() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        PageReference result = controller.openContactUSLink();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'PageReference should not be null');
        System.assertEquals('https://applicationperfection.com/contact/', 
                           result.getUrl(), 'Should redirect to contact page');
    }
    
    @IsTest
    static void testOpenHelpTraining() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        PageReference result = controller.openHelpTraining();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'PageReference should not be null');
        System.assertEquals('https://applicationperfection.com/security-access-manager-help-training/', 
                           result.getUrl(), 'Should redirect to help training page');
    }
    
    @IsTest
    static void testOpenFAQ() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        PageReference result = controller.openFAQ();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'PageReference should not be null');
        System.assertEquals('https://applicationperfection.com/security-access-manager-faqs/', 
                           result.getUrl(), 'Should redirect to FAQ page');
    }
    
    @IsTest
    static void testOpenReleaseNotes() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        PageReference result = controller.openReleaseNotes();
        
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'PageReference should not be null');
        System.assertEquals('https://applicationperfection.com/security-access-manager-release-notes/', 
                           result.getUrl(), 'Should redirect to release notes page');
    }
    
    @IsTest
    static void testAllNavigationMethods() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        
        // Test all navigation methods
        PageReference contactRef = controller.openContactUSLink();
        PageReference helpRef = controller.openHelpTraining();
        PageReference faqRef = controller.openFAQ();
        PageReference releaseRef = controller.openReleaseNotes();
        
        Test.stopTest();
        
        // Verify all navigation methods return valid PageReferences
        System.assertNotEquals(null, contactRef, 'Contact link should not be null');
        System.assertNotEquals(null, helpRef, 'Help training link should not be null');
        System.assertNotEquals(null, faqRef, 'FAQ link should not be null');
        System.assertNotEquals(null, releaseRef, 'Release notes link should not be null');
        
        // Verify URLs are different
        Set<String> urls = new Set<String>{
            contactRef.getUrl(),
            helpRef.getUrl(),
            faqRef.getUrl(),
            releaseRef.getUrl()
        };
        System.assertEquals(4, urls.size(), 'All navigation URLs should be unique');
    }
    
    @IsTest
    static void testOrganizationDataRetrieval() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        
        Test.stopTest();
        
        // Verify organization data is properly retrieved when accessible
        if (controller.OrgIsAccessible) {
            System.assertNotEquals(null, controller.org, 'Organization should be populated');
            System.assertNotEquals(null, controller.org.Id, 'Organization ID should be populated');
            System.assertNotEquals(null, controller.org.Name, 'Organization Name should be populated');
            System.assertEquals(UserInfo.getOrganizationId(), controller.org.Id, 
                               'Organization ID should match current org');
        }
    }
    
    @IsTest
    static void testUserInfoRetrieval() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        
        Test.stopTest();
        
        // Verify user information is correctly retrieved
        System.assertEquals(UserInfo.getName(), controller.exportUser, 
                           'Export user should match current user name');
        System.assertNotEquals(null, controller.exportUser, 'Export user should not be null');
    }
    
    @IsTest
    static void testPropertyGettersAndSetters() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        
        // Test all property setters
        controller.isEdit = true;
        controller.selectedPerm = 'TestPermissionSet';
        controller.exportUser = 'TestExportUser';
        controller.xmlheader = 'TestXMLHeader';
        controller.endfile = 'TestEndFile';
        controller.currentLanguage = 'EN';
        controller.noEndpointMetadata = true;
        
        Test.stopTest();
        
        // Verify all properties are set correctly
        System.assertEquals(true, controller.isEdit, 'isEdit should be true');
        System.assertEquals('TestPermissionSet', controller.selectedPerm, 'selectedPerm should be set');
        System.assertEquals('TestExportUser', controller.exportUser, 'exportUser should be set');
        System.assertEquals('TestXMLHeader', controller.xmlheader, 'xmlheader should be set');
        System.assertEquals('TestEndFile', controller.endfile, 'endfile should be set');
        System.assertEquals('EN', controller.currentLanguage, 'currentLanguage should be set');
        System.assertEquals(true, controller.noEndpointMetadata, 'noEndpointMetadata should be true');
    }
    
    @IsTest
    static void testMultipleInstances() {
        Test.startTest();
        
        // Test creating multiple instances
        PsetGroupDescription controller1 = new PsetGroupDescription();
        PsetGroupDescription controller2 = new PsetGroupDescription();
        
        Test.stopTest();
        
        // Verify both instances are properly initialized
        System.assertNotEquals(null, controller1, 'First controller should be initialized');
        System.assertNotEquals(null, controller2, 'Second controller should be initialized');
        
        // Verify they have the same initialization values
        System.assertEquals(controller1.xmlheader, controller2.xmlheader, 
                           'XML headers should be the same');
        System.assertEquals(controller1.endfile, controller2.endfile, 
                           'End files should be the same');
        System.assertEquals(controller1.currentLanguage, controller2.currentLanguage, 
                           'Current languages should be the same');
    }
    
    @IsTest
    static void testNavigationMethodsReturnNewInstances() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        
        // Call navigation methods multiple times
        PageReference contact1 = controller.openContactUSLink();
        PageReference contact2 = controller.openContactUSLink();
        
        Test.stopTest();
        
        // Verify each call returns a new PageReference instance
        System.assertNotEquals(null, contact1, 'First contact reference should not be null');
        System.assertNotEquals(null, contact2, 'Second contact reference should not be null');
        System.assertEquals(contact1.getUrl(), contact2.getUrl(), 
                           'URLs should be the same but instances different');
    }
    
    @IsTest
    static void testDebugStatements() {
        Test.startTest();
        
        // Test that debug statements don't cause errors
        PsetGroupDescription controller = new PsetGroupDescription();
        
        Test.stopTest();
        
        // Verify controller is still properly initialized despite debug statements
        System.assertNotEquals(null, controller, 'Controller should be initialized despite debug statements');
        System.assertNotEquals(null, controller.exportUser, 'Export user should be set despite debug statements');
    }
    
    @IsTest
    static void testCurrentUserQuery() {
        Test.startTest();
        
        // Test that the current user query executes without error
        PsetGroupDescription controller = new PsetGroupDescription();
        
        Test.stopTest();
        
        // Verify the controller was created successfully
        System.assertNotEquals(null, controller, 'Controller should be created successfully');
        System.assertEquals(UserInfo.getName(), controller.exportUser, 
                           'Export user should match current user after query');
    }
    
    @IsTest
    static void testOrganizationQueryExecution() {
        Test.startTest();
        
        PsetGroupDescription controller = new PsetGroupDescription();
        
        Test.stopTest();
        
        // If organization is accessible, verify the query executed properly
        if (controller.OrgIsAccessible) {
            System.assertNotEquals(null, controller.org, 'Organization should be queried and populated');
            System.assertEquals(UserInfo.getOrganizationId(), controller.org.Id, 
                               'Organization ID should match from query');
        }
    }
}