@isTest
public class PermissionSetGroupDescriptionManagerTest {

    @isTest
    public static void testConstructor() {
        // Create a test user and log in as the user
        User testUser = new User(
            Username = 'testtuser79@example.com',
            Email = 'testtuser79@example.com',
            Alias = 'tuser',
            LastName = 'usert',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        System.runAs(testUser) {
            // Initialize the manager class
            PermissionSetGroupDescriptionManager manager = new PermissionSetGroupDescriptionManager();

            // Test the constructor and properties
            System.assertNotEquals(manager.allPSetGroups, null, 'allPSetGroups should not be null');
            System.assertNotEquals(manager.selectedPSetGroups, null, 'selectedPSetGroups should not be null');
            System.assertNotEquals(manager.pSetGroupDescriptions, null, 'pSetGroupDescriptions should not be null');
            System.assertEquals(manager.isEdit, false, 'isEdit should initially be false');
            System.assertNotEquals(manager.xmlheader, null, 'xmlheader should not be null');
            System.assertNotEquals(manager.exportUser, null, 'exportUser should not be null');
            System.assertEquals(manager.OrgIsAccessible, true, 'OrgIsAccessible should be true');
        }
    }

    @isTest
    public static void testFetchPSetGroupDescriptions() {
        // Create test Permission Set Groups
        PermissionSetGroup psg1 = new PermissionSetGroup(DeveloperName = 'TestGroup1', MasterLabel = 'Test Group 1', Description = 'Group 1 Description');
        PermissionSetGroup psg2 = new PermissionSetGroup(DeveloperName = 'TestGroup2', MasterLabel = 'Test Group 2', Description = 'Group 2 Description');
        insert new List<PermissionSetGroup>{ psg1, psg2 };

        // Initialize the manager class
        PermissionSetGroupDescriptionManager manager = new PermissionSetGroupDescriptionManager();

        // Add selected groups
        manager.selectedPSetGroups.add(new SelectOption(psg1.Id, psg1.DeveloperName));
        manager.selectedPSetGroups.add(new SelectOption(psg2.Id, psg2.DeveloperName));

        // Call fetchPSetGroupDescriptions method
        Test.startTest();
        manager.fetchPSetGroupDescriptions();
        Test.stopTest();

        // Test that descriptions are populated correctly
        System.assertEquals(manager.pSetGroupDescriptions.size(), 2, 'There should be 2 descriptions');
        System.assertEquals(manager.pSetGroupDescriptions[0].description, 'Group 1 Description', 'Description for group 1 should be correct');
        System.assertEquals(manager.pSetGroupDescriptions[1].description, 'Group 2 Description', 'Description for group 2 should be correct');
    }

    @isTest
    public static void testToggleEdit() {
        // Initialize the manager class
        PermissionSetGroupDescriptionManager manager = new PermissionSetGroupDescriptionManager();

        // Test that isEdit is false initially
        System.assertEquals(manager.isEdit, false, 'isEdit should initially be false');

        // Toggle edit mode
        manager.toggleEdit();
        System.assertEquals(manager.isEdit, true, 'isEdit should be true after toggle');

        // Toggle again
        manager.toggleEdit();
        System.assertEquals(manager.isEdit, false, 'isEdit should be false after another toggle');
    }

    @isTest
    public static void testSaveDescriptions() {
        // Create test Permission Set Groups
        PermissionSetGroup psg1 = new PermissionSetGroup(DeveloperName = 'TestGroup1', MasterLabel = 'Test Group 1', Description = 'Group 1 Description');
        PermissionSetGroup psg2 = new PermissionSetGroup(DeveloperName = 'TestGroup2', MasterLabel = 'Test Group 2', Description = 'Group 2 Description');
        insert new List<PermissionSetGroup>{ psg1, psg2 };

        // Initialize the manager class
        PermissionSetGroupDescriptionManager manager = new PermissionSetGroupDescriptionManager();

        // Add selected groups
        manager.selectedPSetGroups.add(new SelectOption(psg1.Id, psg1.DeveloperName));
        manager.selectedPSetGroups.add(new SelectOption(psg2.Id, psg2.DeveloperName));

        // Call fetchPSetGroupDescriptions method to populate descriptions
        manager.fetchPSetGroupDescriptions();

        // Update descriptions
        manager.pSetGroupDescriptions[0].description = 'Updated Group 1 Description';
        manager.pSetGroupDescriptions[1].description = 'Updated Group 2 Description';

        // Call saveDescriptions method
        Test.startTest();
        manager.saveDescriptions();
        Test.stopTest();

        // Verify that descriptions have been saved
        PermissionSetGroup updatedPsg1 = [SELECT Description FROM PermissionSetGroup WHERE Id = :psg1.Id];
        PermissionSetGroup updatedPsg2 = [SELECT Description FROM PermissionSetGroup WHERE Id = :psg2.Id];

        System.assertEquals(updatedPsg1.Description, 'Updated Group 1 Description', 'Group 1 description should be updated');
        System.assertEquals(updatedPsg2.Description, 'Updated Group 2 Description', 'Group 2 description should be updated');
    }

    @isTest
    public static void testOpenContactUSLink() {
        // Initialize the manager class
        PermissionSetGroupDescriptionManager manager = new PermissionSetGroupDescriptionManager();

        // Test openContactUSLink method
        PageReference pageRef = manager.openContactUSLink();
        System.assertNotEquals(pageRef, null, 'Page reference should not be null');
        System.assertEquals(pageRef.getUrl(), 'https://applicationperfection.com/contact/', 'URL should match');
    }

    @isTest
    public static void testOpenHelpTraining() {
        // Initialize the manager class
        PermissionSetGroupDescriptionManager manager = new PermissionSetGroupDescriptionManager();

        // Test openHelpTraining method
        PageReference pageRef = manager.openHelpTraining();
        System.assertNotEquals(pageRef, null, 'Page reference should not be null');
        System.assertEquals(pageRef.getUrl(), 'https://applicationperfection.com/security-access-manager-help-training/', 'URL should match');
    }

    @isTest
    public static void testOpenFAQ() {
        // Initialize the manager class
        PermissionSetGroupDescriptionManager manager = new PermissionSetGroupDescriptionManager();

        // Test openFAQ method
        PageReference pageRef = manager.openFAQ();
        System.assertNotEquals(pageRef, null, 'Page reference should not be null');
        System.assertEquals(pageRef.getUrl(), 'https://applicationperfection.com/security-access-manager-faqs/', 'URL should match');
    }

    @isTest
    public static void testOpenReleaseNotes() {
        // Initialize the manager class
        PermissionSetGroupDescriptionManager manager = new PermissionSetGroupDescriptionManager();

        // Test openReleaseNotes method
        PageReference pageRef = manager.openReleaseNotes();
        System.assertNotEquals(pageRef, null, 'Page reference should not be null');
        System.assertEquals(pageRef.getUrl(), 'https://applicationperfection.com/security-access-manager-release-notes/', 'URL should match');
    }
}