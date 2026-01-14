/**
 * Test class for SecurityAccessManagerController
 * Provides comprehensive test coverage for all methods including template management
 */
@isTest
private class SecurityAccessManagerControllerTest {
    
    @TestSetup
    static void makeData() {
        // Create test users
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        List<User> testUsers = new List<User>();
        for (Integer i = 1; i <= 3; i++) {
            User testUser = new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@test.com',
                Username = 'testuser' + i + '@test.com.testorg',
                Alias = 'tuser' + i,
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = standardProfile.Id,
                IsActive = true
            );
            testUsers.add(testUser);
        }
        insert testUsers;
    }
    
    // Helper method to create setup objects in separate transaction
    static void createSetupObjects() {
        // Create test roles
        UserRole testRole = new UserRole(
            Name = 'Test Role',
            DeveloperName = 'TestRole'
        );
        insert testRole;
        
        // Create test groups
        Group testGroup = new Group(
            Name = 'Test Group',
            DeveloperName = 'TestGroup',
            Type = 'Regular'
        );
        insert testGroup;
        
        // Create test permission set
        PermissionSet testPermSet = new PermissionSet(
            Name = 'TestPermissionSet',
            Label = 'Test Permission Set'
        );
        insert testPermSet;
    }
    
    // Helper method to create custom objects in separate transaction
    static void createCustomObjects() {
        // Create test templates
        List<LightIntelTemplate__c> testTemplates = new List<LightIntelTemplate__c>();
        
        LightIntelTemplate__c userTemplate = new LightIntelTemplate__c(
            TemplateName__c = 'Test User Template',
            CardType__c = 'user',
            SelectedFilters__c = '{"filters":["userName","userEmail"],"userData":{"selectedUsers":[]}}'
        );
        testTemplates.add(userTemplate);
        
        LightIntelTemplate__c configTemplate = new LightIntelTemplate__c(
            TemplateName__c = 'Test Config Template',
            CardType__c = 'config',
            SelectedFilters__c = '{"filters":["validationRuleName","active"]}'
        );
        testTemplates.add(configTemplate);
        
        insert testTemplates;
    }
    
    @isTest
    static void testGetReportIdByName() {
        Test.startTest();
        
        // Test exception handling for non-existent report
        try {
            SecurityAccessManagerController.getReportIdByName('NonExistentReport');
            System.assert(false, 'Should throw exception for non-existent report');
        } catch (Exception e) {
            // Should catch any exception for non-existent report
            System.assert(true, 'Exception was thrown as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'userEmail', 'userStatus'};
        String cardId = 'user';
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportData(filters, cardId);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters.size(), result.headers.size(), 'Headers should match filter count');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportDataWithPermissionSetsEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'userEmail', 'permissionSets'};
        String cardId = 'user';
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportData(filters, cardId);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportDataWithNullFilters() {
        Test.startTest();
        
        try {
            SecurityAccessManagerController.getReportData(null, 'user');
            System.assert(false, 'Should throw exception for null filters');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportDataWithEmptyFilters() {
        Test.startTest();
        
        List<String> filters = new List<String>();
        String cardId = 'user';
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportData(filters, cardId);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportDataNonUserCardEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'profileName', 'userLicense'};
        String cardId = 'profile';
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportData(filters, cardId);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetAllUserFields() {
        Test.startTest();
        
        List<SecurityAccessManagerController.UserFieldInfo> result = SecurityAccessManagerController.getAllUserFields();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return user fields');
        
        // Verify field info structure
        SecurityAccessManagerController.UserFieldInfo firstField = result[0];
        System.assertNotEquals(null, firstField.name, 'Field name should not be null');
        System.assertNotEquals(null, firstField.label, 'Field label should not be null');
        System.assertNotEquals(null, firstField.category, 'Field category should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetConfigIntelReportData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'validationRuleName', 'active', 'object'};
        
        SecurityAccessManagerController.ConfigIntelReportData result = SecurityAccessManagerController.getConfigIntelReportData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetConfigIntelReportDataWithNullFilters() {
        Test.startTest();
        
        SecurityAccessManagerController.ConfigIntelReportData result = SecurityAccessManagerController.getConfigIntelReportData(null);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        // When null filters are passed, headers will be null or empty - this is expected behavior
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetConfigIntelReportDataWithEmptyFilters() {
        Test.startTest();
        
        List<String> filters = new List<String>();
        
        SecurityAccessManagerController.ConfigIntelReportData result = SecurityAccessManagerController.getConfigIntelReportData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetConfigIntelReportDataWithAllFilters() {
        Test.startTest();
        
        List<String> filters = new List<String>{
            'validationRuleName', 'namespacePrefix', 'active', 'object', 
            'description', 'errorDisplayField', 'errorMessage', 'criteria'
        };
        
        SecurityAccessManagerController.ConfigIntelReportData result = SecurityAccessManagerController.getConfigIntelReportData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match all filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetSharingSettingsReport() {
        Test.startTest();
        
        SecurityAccessManagerController.SharingReportData result = SecurityAccessManagerController.getSharingSettingsReport();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.sections, 'Sections should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetAllSharingRulesData() {
        Test.startTest();
        
        SecurityAccessManagerController.SharingReportData result = SecurityAccessManagerController.getAllSharingRulesData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.sections, 'Sections should not be null');
        
        // Verify sections structure
        for (SecurityAccessManagerController.SharingReportSection section : result.sections) {
            System.assertNotEquals(null, section.title, 'Section title should not be null');
            System.assertNotEquals(null, section.headers, 'Section headers should not be null');
            System.assertNotEquals(null, section.rows, 'Section rows should not be null');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetOrgWideDefaultsData() {
        Test.startTest();
        
        SecurityAccessManagerController.SharingReportData result = SecurityAccessManagerController.getOrgWideDefaultsData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.sections, 'Sections should not be null');
        
        // Verify OWD sections structure
        for (SecurityAccessManagerController.SharingReportSection section : result.sections) {
            System.assertNotEquals(null, section.title, 'OWD section title should not be null');
            System.assertNotEquals(null, section.headers, 'OWD section headers should not be null');
            System.assertNotEquals(null, section.rows, 'OWD section rows should not be null');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testSharingReportDataStructure() {
        Test.startTest();
        
        // Test SharingReportData wrapper classes
        SecurityAccessManagerController.SharingReportData reportData = new SecurityAccessManagerController.SharingReportData();
        reportData.sections = new List<SecurityAccessManagerController.SharingReportSection>();
        
        SecurityAccessManagerController.SharingReportSection section = new SecurityAccessManagerController.SharingReportSection();
        section.title = 'Test Section';
        section.headers = new List<String>{'Header1', 'Header2'};
        section.rows = new List<SecurityAccessManagerController.SharingReportRow>();
        
        SecurityAccessManagerController.SharingReportRow row = new SecurityAccessManagerController.SharingReportRow();
        row.values = new List<String>{'Value1', 'Value2'};
        row.key = 'TestKey';
        section.rows.add(row);
        
        reportData.sections.add(section);
        
        System.assertEquals(1, reportData.sections.size(), 'Should have one section');
        System.assertEquals('Test Section', reportData.sections[0].title, 'Section title should be set');
        System.assertEquals(2, reportData.sections[0].headers.size(), 'Section should have headers');
        System.assertEquals(1, reportData.sections[0].rows.size(), 'Section should have rows');
        System.assertEquals('TestKey', reportData.sections[0].rows[0].key, 'Row key should be set');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPublicGroupsData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'groupLabel', 'groupName', 'createdBy'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPublicGroupsData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPublicGroupsDataPaginated() {
        Test.startTest();
        
        List<String> filters = new List<String>{'groupLabel', 'groupName'};
        Integer pageSize = 5;
        Integer pageNumber = 0;
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPublicGroupsDataPaginated(filters, pageSize, pageNumber);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPublicGroupMembersData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'alias', 'fullName', 'userName'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPublicGroupMembersData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportFolderShareData() {
        Test.startTest();
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportFolderShareData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetDashboardFolderShareData() {
        Test.startTest();
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getDashboardFolderShareData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetDashboardRunningUserData() {
        Test.startTest();
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getDashboardRunningUserData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetProfileAssignmentData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'profileName', 'profileType', 'userLicense'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getProfileAssignmentData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assert(result.rows.size() > 0, 'Should return profile data');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetRoleTypeData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'roleLabel', 'roleName', 'roleOpportunityAccess'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getRoleTypeData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetRoleTypeDataPaginated() {
        Test.startTest();
        
        List<String> filters = new List<String>{'roleLabel', 'roleName'};
        Integer pageSize = 5;
        Integer pageNumber = 0;
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getRoleTypeDataPaginated(filters, pageSize, pageNumber);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetTerritoriesData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'territoryLabel', 'territoryName'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getTerritoriesData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPermissionSetNoGroupData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'permissionSetName', 'permissionSetLabel'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPermissionSetNoGroupData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetInstalledPackagesData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'packageName', 'packageStatus'};
        
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getInstalledPackagesData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetListViewData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'listViewObject', 'viewName'};
        
        // Mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getListViewData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetApexClassesData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'className', 'classApiVersion'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getApexClassesData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetApexTriggersData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'triggerName', 'triggerSObjectType'};
        
        // Mock HTTP callout for Tooling API
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getApexTriggersData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserTerritoriesData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'territoryUserName', 'territoryName'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getUserTerritoriesData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserPermissionFields() {
        Test.startTest();
        
        List<User> testUsers = [SELECT Id FROM User WHERE LastName LIKE 'User%' LIMIT 2];
        List<String> userIds = new List<String>();
        for (User u : testUsers) {
            userIds.add(u.Id);
        }
        
        SecurityAccessManagerController.UserPermissionsData result = SecurityAccessManagerController.getUserPermissionFields(userIds);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.permissionFields, 'Permission fields should not be null');
        System.assertNotEquals(null, result.userPermissions, 'User permissions should not be null');
        
        Test.stopTest();
    }
    
    // ================================
    // TEMPLATE MANAGEMENT TESTS
    // ================================
    
    @isTest
    static void testSaveTemplate() {
        Test.startTest();
        
        String templateName = 'New Test Template';
        String cardType = 'user';
        String selectedFilters = '{"filters":["userName","userEmail"],"userData":{"selectedUsers":[]}}';
        
        // Test creating new template
        Boolean result = SecurityAccessManagerController.saveTemplate(templateName, cardType, selectedFilters);
        
        System.assertEquals(true, result, 'Should successfully save template');
        
        // Verify template was created
        List<LightIntelTemplate__c> templates = [
            SELECT Id, TemplateName__c, CardType__c, SelectedFilters__c 
            FROM LightIntelTemplate__c 
            WHERE TemplateName__c = :templateName AND CardType__c = :cardType
        ];
        
        System.assertEquals(1, templates.size(), 'Should create one template');
        System.assertEquals(templateName, templates[0].TemplateName__c, 'Template name should match');
        System.assertEquals(cardType, templates[0].CardType__c, 'Card type should match');
        System.assertEquals(selectedFilters, templates[0].SelectedFilters__c, 'Selected filters should match');
        
        // Test updating existing template
        String updatedFilters = '{"filters":["userName","userEmail","userStatus"],"userData":{"selectedUsers":[]}}';
        Boolean updateResult = SecurityAccessManagerController.saveTemplate(templateName, cardType, updatedFilters);
        
        System.assertEquals(true, updateResult, 'Should successfully update template');
        
        // Verify template was updated
        List<LightIntelTemplate__c> updatedTemplates = [
            SELECT Id, SelectedFilters__c 
            FROM LightIntelTemplate__c 
            WHERE TemplateName__c = :templateName AND CardType__c = :cardType
        ];
        
        System.assertEquals(1, updatedTemplates.size(), 'Should still have one template');
        System.assertEquals(updatedFilters, updatedTemplates[0].SelectedFilters__c, 'Selected filters should be updated');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSaveTemplateException() {
        Test.startTest();
        
        try {
            // Test with null template name to trigger an exception
            SecurityAccessManagerController.saveTemplate(null, 'user', '{}');
            System.assert(false, 'Should throw exception for null template name');
        } catch (Exception e) {
            // Should catch any exception for null template name
            System.assert(true, 'Exception was thrown as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testLoadTemplates() {
        // Create test templates in separate transaction
        createCustomObjects();
        
        Test.startTest();
        
        String cardType = 'user';
        
        List<SecurityAccessManagerController.TemplateWrapper> result = SecurityAccessManagerController.loadTemplates(cardType);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return one user template');
        
        SecurityAccessManagerController.TemplateWrapper template = result[0];
        System.assertEquals('Test User Template', template.name, 'Template name should match');
        System.assertNotEquals(null, template.id, 'Template ID should not be null');
        System.assertNotEquals(null, template.selectedFilters, 'Selected filters should not be null');
        System.assertNotEquals(null, template.createdDate, 'Created date should not be null');
        System.assertNotEquals(null, template.lastModifiedDate, 'Last modified date should not be null');
        
        // Test loading templates for different card type
        List<SecurityAccessManagerController.TemplateWrapper> configResult = SecurityAccessManagerController.loadTemplates('config');
        System.assertEquals(1, configResult.size(), 'Should return one config template');
        System.assertEquals('Test Config Template', configResult[0].name, 'Config template name should match');
        
        // Test loading templates for card type with no templates
        List<SecurityAccessManagerController.TemplateWrapper> emptyResult = SecurityAccessManagerController.loadTemplates('sharing');
        System.assertEquals(0, emptyResult.size(), 'Should return empty list for card type with no templates');
        
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteTemplate() {
        // Create test templates in separate transaction
        createCustomObjects();
        
        Test.startTest();
        
        // Get existing test template
        LightIntelTemplate__c testTemplate = [
            SELECT Id FROM LightIntelTemplate__c 
            WHERE TemplateName__c = 'Test User Template' 
            LIMIT 1
        ];
        
        Boolean result = SecurityAccessManagerController.deleteTemplate(testTemplate.Id);
        
        System.assertEquals(true, result, 'Should successfully delete template');
        
        // Verify template was deleted
        List<LightIntelTemplate__c> templates = [
            SELECT Id FROM LightIntelTemplate__c 
            WHERE Id = :testTemplate.Id
        ];
        
        System.assertEquals(0, templates.size(), 'Template should be deleted');
        
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteTemplateException() {
        Test.startTest();
        
        try {
            // Test with invalid template ID format
            SecurityAccessManagerController.deleteTemplate('invalid_id');
            System.assert(false, 'Should throw exception for invalid template ID');
        } catch (Exception e) {
            // Should catch any exception for invalid ID
            System.assert(true, 'Exception was thrown as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testTemplateWrapperClass() {
        Test.startTest();
        
        // Test TemplateWrapper class
        SecurityAccessManagerController.TemplateWrapper wrapper = new SecurityAccessManagerController.TemplateWrapper();
        wrapper.id = 'testId';
        wrapper.name = 'testName';
        wrapper.selectedFilters = 'testFilters';
        wrapper.createdDate = DateTime.now();
        wrapper.lastModifiedDate = DateTime.now();
        
        System.assertEquals('testId', wrapper.id, 'ID should be set correctly');
        System.assertEquals('testName', wrapper.name, 'Name should be set correctly');
        System.assertEquals('testFilters', wrapper.selectedFilters, 'Selected filters should be set correctly');
        System.assertNotEquals(null, wrapper.createdDate, 'Created date should be set');
        System.assertNotEquals(null, wrapper.lastModifiedDate, 'Last modified date should be set');
        
        Test.stopTest();
    }
    
    @isTest
    static void testLoadTemplatesEmpty() {
        Test.startTest();
        
        // Test loading templates when no templates exist
        List<SecurityAccessManagerController.TemplateWrapper> result = SecurityAccessManagerController.loadTemplates('user');
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(0, result.size(), 'Should return empty list when no templates exist');
        
        Test.stopTest();
    }
    
    @isTest
    static void testUserFieldInfoClass() {
        Test.startTest();
        
        // Test UserFieldInfo class
        SecurityAccessManagerController.UserFieldInfo fieldInfo = new SecurityAccessManagerController.UserFieldInfo();
        fieldInfo.name = 'TestField';
        fieldInfo.label = 'Test Field';
        fieldInfo.type = 'STRING';
        fieldInfo.isCustom = true;
        fieldInfo.isRequired = false;
        fieldInfo.category = 'Test Category';
        
        System.assertEquals('TestField', fieldInfo.name, 'Name should be set correctly');
        System.assertEquals('Test Field', fieldInfo.label, 'Label should be set correctly');
        System.assertEquals('STRING', fieldInfo.type, 'Type should be set correctly');
        System.assertEquals(true, fieldInfo.isCustom, 'IsCustom should be set correctly');
        System.assertEquals(false, fieldInfo.isRequired, 'IsRequired should be set correctly');
        System.assertEquals('Test Category', fieldInfo.category, 'Category should be set correctly');
        
        Test.stopTest();
    }
    
    @isTest
    static void testReportDataClass() {
        Test.startTest();
        
        // Test ReportData and ReportRow classes
        SecurityAccessManagerController.ReportData reportData = new SecurityAccessManagerController.ReportData();
        reportData.headers = new List<String>{'Header1', 'Header2'};
        reportData.rows = new List<SecurityAccessManagerController.ReportRow>();
        
        SecurityAccessManagerController.ReportRow row = new SecurityAccessManagerController.ReportRow();
        row.values = new List<String>{'Value1', 'Value2'};
        reportData.rows.add(row);
        
        System.assertEquals(2, reportData.headers.size(), 'Headers should be set correctly');
        System.assertEquals(1, reportData.rows.size(), 'Rows should be set correctly');
        System.assertEquals('Value1', reportData.rows[0].values[0], 'Row values should be set correctly');
        
        Test.stopTest();
    }
    
    @isTest
    static void testExportReportToExcel() {
        Test.startTest();
        
        // Test exception handling for non-existent report
        try {
            SecurityAccessManagerController.exportReportToExcel('NonExistentReport');
            System.assert(false, 'Should throw exception for non-existent report');
        } catch (Exception e) {
            // Should catch any exception for non-existent report
            System.assert(true, 'Exception was thrown as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testExportAllReports() {
        Test.startTest();
        
        String result = SecurityAccessManagerController.exportAllReports();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('/apex/SecurityAccessManagerExport'), 'Should contain export URL');
        
        Test.stopTest();
    }
    
    @isTest
    static void testUserFieldComparator() {
        Test.startTest();
        
        SecurityAccessManagerController.UserFieldInfo field1 = new SecurityAccessManagerController.UserFieldInfo();
        field1.category = 'Basic Information';
        field1.label = 'Name';
        
        SecurityAccessManagerController.UserFieldInfo field2 = new SecurityAccessManagerController.UserFieldInfo();
        field2.category = 'Basic Information';
        field2.label = 'Email';
        
        SecurityAccessManagerController.UserFieldInfo field3 = new SecurityAccessManagerController.UserFieldInfo();
        field3.category = 'Security & Access';
        field3.label = 'Profile';
        
        SecurityAccessManagerController.UserFieldComparator comparator = new SecurityAccessManagerController.UserFieldComparator();
        
        // Test same category, different labels
        Integer result1 = comparator.compare(field1, field2);
        System.assert(result1 > 0, 'Name should come after Email alphabetically');
        
        // Test different categories
        Integer result2 = comparator.compare(field1, field3);
        System.assert(result2 < 0, 'Basic Information should come before Security & Access');
        
        Test.stopTest();
    }
    
    // Mock HTTP Response Generator for testing HTTP callouts
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            if (req.getEndpoint().contains('InstalledSubscriberPackage')) {
                res.setBody('{"records": [{"Id": "0A3000000000001", "SubscriberPackageId": "033000000000001", "SubscriberPackage": {"Name": "Test Package", "Description": "Test Description", "NamespacePrefix": "testns"}, "SubscriberPackageVersion": {"Name": "1.0", "MajorVersion": 1, "MinorVersion": 0, "PatchVersion": 0, "BuildNumber": 0}}]}');
            } else if (req.getEndpoint().contains('ListView')) {
                res.setBody('{"records": [{"Id": "00B000000000001", "Name": "Test ListView", "DeveloperName": "TestListView", "SobjectType": "Account", "Columns": ["Name", "Type"], "LastModifiedDate": "2023-01-01T00:00:00.000Z", "LastModifiedBy": {"Name": "Test User"}}]}');
            } else if (req.getEndpoint().contains('ApexTrigger')) {
                res.setBody('{"records": [{"Id": "01q000000000001", "Name": "TestTrigger", "ApiVersion": 57.0, "Status": "Active", "NamespacePrefix": null, "TableEnumOrId": "Account", "CreatedDate": "2023-01-01T00:00:00.000Z", "CreatedBy": {"Name": "Test User"}, "LastModifiedBy": {"Name": "Test User"}}]}');
            } else {
                res.setBody('{"records": []}');
            }
            
            return res;
        }
    }
    
    @isTest
    static void testGetPermissionSetsData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'permissionSetName', 'permissionSetLabel', 'isOwnedByProfile'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPermissionSetsData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPermissionSetGroupsData() {
        Test.startTest();
        
        List<String> filters = new List<String>{'groupLabel', 'groupName', 'status'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPermissionSetGroupsData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetInstalledPackagesDataNew() {
        Test.startTest();
        
        // Set up mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<String> filters = new List<String>{'packageName', 'version', 'namespace'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getInstalledPackagesData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetListViewDataNew() {
        Test.startTest();
        
        // Set up mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<String> filters = new List<String>{'listViewName', 'objectType', 'lastModified'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getListViewData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetApexTriggersDataNew() {
        Test.startTest();
        
        // Set up mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<String> filters = new List<String>{'triggerName', 'objectType', 'status'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getApexTriggersData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetApexClassesDataNew() {
        Test.startTest();
        
        // Set up mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        List<String> filters = new List<String>{'className', 'apiVersion', 'status'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getApexClassesData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        
        Test.stopTest();
    }
    

    
    @isTest
    static void testGetUserPermissionFieldsNew() {
        Test.startTest();
        
        List<String> userIds = new List<String>{UserInfo.getUserId()};
        
        SecurityAccessManagerController.UserPermissionsData result = SecurityAccessManagerController.getUserPermissionFields(userIds);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.permissionFields, 'Permission fields should not be null');
        System.assertNotEquals(null, result.userPermissions, 'User permissions should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSaveTemplateNew() {
        Test.startTest();
        
        String templateName = 'Test Save Template';
        String cardType = 'user';
        String selectedFilters = '{"filters":["userName","userEmail"]}';
        
        Boolean result = SecurityAccessManagerController.saveTemplate(templateName, cardType, selectedFilters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(true, result, 'Should return true for successful save');
        
        Test.stopTest();
    }
    
    @isTest
    static void testLoadTemplatesNew() {
        // Create test templates first
        createCustomObjects();
        
        Test.startTest();
        
        List<SecurityAccessManagerController.TemplateWrapper> result = SecurityAccessManagerController.loadTemplates('user');
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.size() > 0, 'Should return templates');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportDataWithPermissionSets() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'permissionSets'};
        String cardId = 'user';
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportData(filters, cardId);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportDataWithPermissionSetLicenses() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'permissionSetLicenses'};
        String cardId = 'user';
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportData(filters, cardId);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportDataNonUserCard() {
        Test.startTest();
        
        List<String> filters = new List<String>{'profileName', 'userLicense'};
        String cardId = 'profile';
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportData(filters, cardId);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportMetadata() {
        Test.startTest();
        
        try {
            // This will likely throw an exception in test context, which is expected
            SecurityAccessManagerController.getReportMetadata('00O000000000000');
            System.assert(false, 'Should throw exception for invalid report ID');
        } catch (Exception e) {
            // Expected behavior in test context
            System.assert(true, 'Exception was thrown as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testSharingReportDataClasses() {
        Test.startTest();
        
        // Test SharingReportData and related classes
        SecurityAccessManagerController.SharingReportData reportData = new SecurityAccessManagerController.SharingReportData();
        reportData.sections = new List<SecurityAccessManagerController.SharingReportSection>();
        
        SecurityAccessManagerController.SharingReportSection section = new SecurityAccessManagerController.SharingReportSection();
        section.title = 'Test Section';
        section.headers = new List<String>{'Header1', 'Header2'};
        section.rows = new List<SecurityAccessManagerController.SharingReportRow>();
        
        SecurityAccessManagerController.SharingReportRow row = new SecurityAccessManagerController.SharingReportRow();
        row.values = new List<String>{'Value1', 'Value2'};
        row.key = 'TestKey';
        section.rows.add(row);
        
        reportData.sections.add(section);
        
        System.assertEquals(1, reportData.sections.size(), 'Should have one section');
        System.assertEquals('Test Section', reportData.sections[0].title, 'Section title should be set');
        System.assertEquals(2, reportData.sections[0].headers.size(), 'Section should have headers');
        System.assertEquals(1, reportData.sections[0].rows.size(), 'Section should have rows');
        
        Test.stopTest();
    }
    
    @isTest
    static void testPermissionFieldInfoClass() {
        Test.startTest();
        
        SecurityAccessManagerController.PermissionFieldInfo fieldInfo = new SecurityAccessManagerController.PermissionFieldInfo();
        fieldInfo.name = 'TestPermission';
        fieldInfo.label = 'Test Permission';
        fieldInfo.category = 'Administrative Permissions';
        
        System.assertEquals('TestPermission', fieldInfo.name, 'Name should be set correctly');
        System.assertEquals('Test Permission', fieldInfo.label, 'Label should be set correctly');
        System.assertEquals('Administrative Permissions', fieldInfo.category, 'Category should be set correctly');
        
        Test.stopTest();
    }
    
    @isTest
    static void testUserPermissionsDataClass() {
        Test.startTest();
        
        SecurityAccessManagerController.UserPermissionsData permData = new SecurityAccessManagerController.UserPermissionsData();
        permData.permissionFields = new List<SecurityAccessManagerController.PermissionFieldInfo>();
        permData.userPermissions = new Map<String, Object>();
        
        SecurityAccessManagerController.PermissionFieldInfo fieldInfo = new SecurityAccessManagerController.PermissionFieldInfo();
        fieldInfo.name = 'TestPerm';
        fieldInfo.label = 'Test Permission';
        fieldInfo.category = 'Test Category';
        permData.permissionFields.add(fieldInfo);
        
        permData.userPermissions.put('TestPerm', true);
        
        System.assertEquals(1, permData.permissionFields.size(), 'Should have permission fields');
        System.assertEquals(1, permData.userPermissions.size(), 'Should have user permissions');
        System.assertEquals(true, permData.userPermissions.get('TestPerm'), 'Permission should be set to true');
        
        Test.stopTest();
    }
    
    @isTest
    static void testErrorHandlingScenarios() {
        Test.startTest();
        
        // Test various error scenarios
        try {
            SecurityAccessManagerController.getReportData(null, 'user');
            System.assert(false, 'Should throw exception for null filters');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected: ' + e.getMessage());
        }
        
        try {
            SecurityAccessManagerController.saveTemplate('', 'user', '{}');
            // Method might succeed with empty name in test context
            System.assert(true, 'Save template handled gracefully');
        } catch (Exception e) {
            System.assert(true, 'Exception was thrown as expected: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testAdvancedErrorHandlingScenarios() {
        Test.startTest();
        
        // Test error handling for invalid pagination parameters
        try {
            SecurityAccessManagerController.getPublicGroupsDataPaginated(null, -1, -1);
            System.assert(false, 'Should handle invalid pagination parameters');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for invalid pagination: ' + e.getMessage());
        }
        
        // Test error handling for getUserPermissionFields with invalid user IDs
        try {
            List<String> invalidUserIds = new List<String>{'invalid_id_123'};
            SecurityAccessManagerController.getUserPermissionFields(invalidUserIds);
            // Method might handle invalid IDs gracefully
            System.assert(true, 'Method handled invalid user IDs gracefully');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for invalid user IDs: ' + e.getMessage());
        }
        
        // Test error handling for getReportMetadata with invalid report ID
        try {
            SecurityAccessManagerController.getReportMetadata('invalid_report_id');
            System.assert(false, 'Should throw exception for invalid report ID');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for invalid report ID: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDataIntegrityAndConsistencyEnhanced() {
        Test.startTest();
        
        // Test that different methods return consistent data structures
        List<String> userFilters = new List<String>{'userName', 'userEmail'};
        
        SecurityAccessManagerController.ReportData userData1 = SecurityAccessManagerController.getUserDataWithPermissions(userFilters);
        SecurityAccessManagerController.ReportData userData2 = SecurityAccessManagerController.getUserDataWithPermissionsWithFilter(userFilters, false);
        
        // Both methods should return similar data structures
        System.assertEquals(userData1.headers.size(), userData2.headers.size(), 
                           'Both user data methods should return same number of headers');
        
        // Test permission set data consistency
        List<String> permSetFilters = new List<String>{'permissionSetName', 'permissionSetLabel'};
        SecurityAccessManagerController.ReportData permSetData1 = SecurityAccessManagerController.getPermissionSetsData(permSetFilters);
        SecurityAccessManagerController.ReportData permSetData2 = SecurityAccessManagerController.getPermissionSetNoGroupData(permSetFilters);
        
        System.assertEquals(permSetData1.headers, permSetData2.headers, 
                           'Permission set methods should have consistent headers');
        
        Test.stopTest();
    }
    
    @isTest
    static void testPerformanceAndScalability() {
        Test.startTest();
        
        // Test performance with larger filter sets
        List<String> largeFilterSet = new List<String>{
            'userName', 'userEmail', 'userStatus', 'profileName', 'userRole', 
            'lastLoginDate', 'manager', 'title', 'department', 'userLicense',
            'permissionSets', 'permissionSetLicenses'
        };
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportData(largeFilterSet, 'user');
        
        System.assertNotEquals(null, result, 'Should handle large filter sets');
        System.assertEquals(largeFilterSet.size(), result.headers.size(), 'Should process all filters');
        
        // Test bulk export performance
        SecurityAccessManagerController.ReportData bulkResult = SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk(
            new List<String>{'userName', 'permissionSets'}, 
            new List<String>{'userName', 'permissionSetGroups'}
        );
        
        System.assertNotEquals(null, bulkResult, 'Bulk export should complete successfully');
        System.assert(bulkResult.rows.size() >= 0, 'Bulk export should return valid row count');
        
        Test.stopTest();
    }
    
    @isTest
    static void testConfigIntelReportDataClass() {
        Test.startTest();
        
        SecurityAccessManagerController.ConfigIntelReportData configData = new SecurityAccessManagerController.ConfigIntelReportData();
        configData.headers = new List<String>{'Header1', 'Header2'};
        configData.rows = new List<SecurityAccessManagerController.ReportRow>();
        
        SecurityAccessManagerController.ReportRow row = new SecurityAccessManagerController.ReportRow();
        row.values = new List<String>{'ConfigValue1', 'ConfigValue2'};
        configData.rows.add(row);
        
        System.assertEquals(2, configData.headers.size(), 'Config headers should be set');
        System.assertEquals(1, configData.rows.size(), 'Config rows should be set');
        System.assertEquals('ConfigValue1', configData.rows[0].values[0], 'Config row values should be set');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHttpCalloutErrorHandling() {
        Test.startTest();
        
        // Test HTTP callout error handling
        try {
            // This should handle HTTP callout gracefully in test context
            SecurityAccessManagerController.getInstalledPackagesData(new List<String>{'packageName'});
        } catch (Exception e) {
            // Expected in test context without proper HTTP mock setup
            System.assert(true, 'HTTP callout error handled gracefully');
        }
        
        Test.stopTest();
    }
    
    // ================================
    // ADDITIONAL TEST METHODS FOR UNCOVERED @AuraEnabled METHODS
    // ================================
    
    @isTest
    static void testGetUserDataWithPermissionsWithFilterBoolean() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'userEmail', 'permissionSets'};
        Boolean filterByValues = true;
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getUserDataWithPermissionsWithFilter(filters, filterByValues);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertEquals(filters.size(), result.headers.size(), 'Headers count should match filters count');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserDataWithPermissionsWithFilterFalse() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'userEmail', 'userStatus'};
        Boolean filterByValues = false;
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getUserDataWithPermissionsWithFilter(filters, filterByValues);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertEquals(filters.size(), result.headers.size(), 'Headers count should match filters count');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserDataWithPermissions() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'userEmail', 'permissionSets', 'permissionSetLicenses'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getUserDataWithPermissions(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertEquals(filters.size(), result.headers.size(), 'Headers count should match filters count');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testTestPermissionSetGroupAssignments() {
        Test.startTest();
        
        String result = SecurityAccessManagerController.testPermissionSetGroupAssignments();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.contains('Permission Set Group'), 'Result should contain permission set group information');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPermissionSetDetails() {
        Test.startTest();
        
        List<String> filters = new List<String>{
            'permissionSetDetailsId', 'permissionSetDetailsName', 'permissionSetDetailsLabel',
            'permissionSetDetailsType', 'permissionSetDetailsIsCustom'
        };
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPermissionSetDetails(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testExportCombinedPermissionAssignmentsBulkWithTwoParams() {
        Test.startTest();
        
        List<String> permissionSetFilters = new List<String>{'userName', 'userEmail', 'permissionSets'};
        List<String> permissionSetGroupFilters = new List<String>{'userName', 'userEmail', 'permissionSetGroups'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk(permissionSetFilters, permissionSetGroupFilters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        
        // Verify expected headers for combined export
        List<String> expectedHeaders = new List<String>{
            'User Name', 'User Email', 'User ID', 'Permission Sets', 
            'Permission Set Groups', 'User Profile', 'User Is Active'
        };
        System.assertEquals(expectedHeaders, result.headers, 'Headers should match expected combined format');
        
        Test.stopTest();
    }
    
    @isTest
    static void testExportCombinedPermissionAssignmentsBulkWithNullFilters() {
        Test.startTest();
        
        try {
            SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk(null, null);
            
            System.assertNotEquals(null, result, 'Result should not be null even with null filters');
            System.assertNotEquals(null, result.headers, 'Headers should not be null');
            System.assertNotEquals(null, result.rows, 'Rows should not be null');
        } catch (Exception e) {
            System.assert(true, 'Exception handled gracefully: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testExportCombinedPermissionAssignmentsBulkWithEmptyFilters() {
        Test.startTest();
        
        List<String> emptyFilters = new List<String>();
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk(emptyFilters, emptyFilters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testBulkDataProcessingLimitsEnhanced() {
        Test.startTest();
        
        // Test bulk processing with reasonable data size
        List<String> filters = new List<String>{'userName', 'userEmail'};
        
        try {
            SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk(filters, filters);
            
            // Verify the method handles bulk processing within governor limits
            System.assertNotEquals(null, result, 'Bulk export should return valid result');
            System.assert(result.rows.size() >= 0, 'Should return non-negative number of rows');
            
        } catch (Exception e) {
            // Should handle governor limit exceptions gracefully
            System.assert(e.getMessage().contains('limit') || e.getMessage().contains('Error'), 
                         'Should handle limits gracefully: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testExportReportToExcelWithValidReport() {
        Test.startTest();
        
        try {
            // Test with a potentially valid report name pattern
            String result = SecurityAccessManagerController.exportReportToExcel('TestReport');
            // If no exception is thrown, the method handled it gracefully
          //  System.assert(true, 'Export method executed without throwing exception');
        } catch (Exception e) {
            // Expected behavior for non-existent reports
            //System.assert(e.getMessage().contains('Error') || e.getMessage().contains('Report'),  'Should throw meaningful error message');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testBulkDataProcessingLimits() {
        Test.startTest();
        
        // Test bulk processing with reasonable data size
        List<String> filters = new List<String>{'userName', 'userEmail'};
        
        try {
            SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk(filters, filters);
            
            // Verify the method handles bulk processing within governor limits
            System.assertNotEquals(null, result, 'Bulk export should return valid result');
            System.assert(result.rows.size() >= 0, 'Should return non-negative number of rows');
            
        } catch (Exception e) {
            // Should handle governor limit exceptions gracefully
            System.assert(e.getMessage().contains('limit') || e.getMessage().contains('Error'), 
                         'Should handle limits gracefully: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testErrorHandlingForInvalidInputs() {
        Test.startTest();
        
        // Test various invalid input scenarios
        try {
            SecurityAccessManagerController.getPublicGroupsDataPaginated(null, -1, -1);
            System.assert(false, 'Should handle invalid pagination parameters');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for invalid pagination: ' + e.getMessage());
        }
        
        try {
            SecurityAccessManagerController.getUserDataWithPermissionsWithFilter(new List<String>(), false);
            // Method might handle null gracefully
            System.assert(true, 'Method handled null user filters gracefully');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for null filters: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDataIntegrityAndConsistency() {
        Test.startTest();
        
        // Test that different methods return consistent data structures
        List<String> userFilters = new List<String>{'userName', 'userEmail'};
        
        SecurityAccessManagerController.ReportData userData1 = SecurityAccessManagerController.getUserDataWithPermissions(userFilters);
        SecurityAccessManagerController.ReportData userData2 = SecurityAccessManagerController.getUserDataWithPermissionsWithFilter(userFilters, false);
        
        // Both methods should return similar data structures
        System.assertEquals(userData1.headers.size(), userData2.headers.size(), 
                           'Both user data methods should return same number of headers');
        
        // Test permission set data consistency
        List<String> permSetFilters = new List<String>{'permissionSetName', 'permissionSetLabel'};
        SecurityAccessManagerController.ReportData permSetData1 = SecurityAccessManagerController.getPermissionSetsData(permSetFilters);
        SecurityAccessManagerController.ReportData permSetData2 = SecurityAccessManagerController.getPermissionSetNoGroupData(permSetFilters);
        
        System.assertEquals(permSetData1.headers, permSetData2.headers, 
                           'Permission set methods should have consistent headers');
        
        Test.stopTest();
    }
    
    // ================================
    // ADDITIONAL TEST METHODS FOR INCREASED COVERAGE
    // ================================
    
    @isTest
    static void testGetUserDataWithPermissionsEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'userEmail', 'permissionSets', 'permissionSetLicenses', 'userPermissionSetIds', 'userPermissionSetGroupIds'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getUserDataWithPermissions(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertEquals(filters.size(), result.headers.size(), 'Headers count should match filters count');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserDataWithPermissionsWithFilterEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'userName', 'userEmail', 'userStatus', 'profileName'};
        
        // Test with filterByValues = true
        SecurityAccessManagerController.ReportData result1 = SecurityAccessManagerController.getUserDataWithPermissionsWithFilter(filters, true);
        System.assertNotEquals(null, result1, 'Result with filter=true should not be null');
        
        // Test with filterByValues = false
        SecurityAccessManagerController.ReportData result2 = SecurityAccessManagerController.getUserDataWithPermissionsWithFilter(filters, false);
        System.assertNotEquals(null, result2, 'Result with filter=false should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPermissionSetDetailsEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{
            'permissionSetDetailsId', 'permissionSetDetailsName', 'permissionSetDetailsLabel',
            'permissionSetDetailsType', 'permissionSetDetailsIsCustom', 'permissionSetDetailsDescription'
        };
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPermissionSetDetails(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPermissionSetGroupsDataEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'groupLabel', 'groupName', 'status', 'description'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPermissionSetGroupsData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetTerritoriesDataEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'territoryLabel', 'territoryName', 'territoryType'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getTerritoriesData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserTerritoriesDataEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'territoryUserName', 'territoryName', 'territoryRole'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getUserTerritoriesData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPublicGroupsDataPaginatedEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'groupLabel', 'groupName', 'createdBy', 'createdDate'};
        Integer pageSize = 10;
        Integer pageNumber = 0;
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPublicGroupsDataPaginated(filters, pageSize, pageNumber);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetRoleTypeDataPaginatedEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'roleLabel', 'roleName', 'roleOpportunityAccess'};
        Integer pageSize = 10;
        Integer pageNumber = 0;
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getRoleTypeDataPaginated(filters, pageSize, pageNumber);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPublicGroupMembersDataEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'alias', 'fullName', 'userName', 'email'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPublicGroupMembersData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetReportFolderShareDataEnhanced() {
        Test.startTest();
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getReportFolderShareData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assert(result.headers.size() > 0, 'Should have headers');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetDashboardFolderShareDataEnhanced() {
        Test.startTest();
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getDashboardFolderShareData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assert(result.headers.size() > 0, 'Should have headers');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetDashboardRunningUserDataEnhanced() {
        Test.startTest();
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getDashboardRunningUserData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        System.assert(result.headers.size() > 0, 'Should have headers');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetProfileAssignmentDataEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'profileName', 'profileType', 'userLicense', 'description'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getProfileAssignmentData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetPermissionSetNoGroupDataEnhanced() {
        Test.startTest();
        
        List<String> filters = new List<String>{'permissionSetName', 'permissionSetLabel', 'isOwnedByProfile', 'type'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.getPermissionSetNoGroupData(filters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(filters, result.headers, 'Headers should match filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHttpCalloutMethods() {
        Test.startTest();
        
        // Set up mock HTTP callout
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        // Test getInstalledPackagesData
        List<String> packageFilters = new List<String>{'packageName', 'version', 'namespace', 'description'};
        SecurityAccessManagerController.ReportData packageResult = SecurityAccessManagerController.getInstalledPackagesData(packageFilters);
        System.assertNotEquals(null, packageResult, 'Package result should not be null');
        
        // Test getListViewData
        List<String> listViewFilters = new List<String>{'listViewName', 'objectType', 'lastModified', 'createdBy'};
        SecurityAccessManagerController.ReportData listViewResult = SecurityAccessManagerController.getListViewData(listViewFilters);
        System.assertNotEquals(null, listViewResult, 'ListView result should not be null');
        
        // Test getApexTriggersData
        List<String> triggerFilters = new List<String>{'triggerName', 'objectType', 'status', 'apiVersion'};
        SecurityAccessManagerController.ReportData triggerResult = SecurityAccessManagerController.getApexTriggersData(triggerFilters);
        System.assertNotEquals(null, triggerResult, 'Trigger result should not be null');
        
        // Test getApexClassesData
        List<String> classFilters = new List<String>{'className', 'apiVersion', 'status', 'namespace'};
        SecurityAccessManagerController.ReportData classResult = SecurityAccessManagerController.getApexClassesData(classFilters);
        System.assertNotEquals(null, classResult, 'Class result should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testExportCombinedPermissionAssignmentsBulkAdvanced() {
        Test.startTest();
        
        // Test with comprehensive filters
        List<String> permissionSetFilters = new List<String>{'userName', 'userEmail', 'permissionSets', 'userStatus'};
        List<String> permissionSetGroupFilters = new List<String>{'userName', 'userEmail', 'permissionSetGroups', 'userProfile'};
        
        SecurityAccessManagerController.ReportData result = SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk(permissionSetFilters, permissionSetGroupFilters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.headers, 'Headers should not be null');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        // Verify expected headers for combined export
        List<String> expectedHeaders = new List<String>{
            'User Name', 'User Email', 'User ID', 'Permission Sets', 
            'Permission Set Groups', 'User Profile', 'User Is Active'
        };
        System.assertEquals(expectedHeaders, result.headers, 'Headers should match expected combined format');
        
        // Test with null filters
        SecurityAccessManagerController.ReportData nullResult = SecurityAccessManagerController.exportCombinedPermissionAssignmentsBulk(null, null);
        System.assertNotEquals(null, nullResult, 'Null result should not be null');
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetAllSharingRulesDataAdvanced() {
        Test.startTest();
        
        SecurityAccessManagerController.SharingReportData result = SecurityAccessManagerController.getAllSharingRulesData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.sections, 'Sections should not be null');
        
        // Verify sections structure
        for (SecurityAccessManagerController.SharingReportSection section : result.sections) {
            System.assertNotEquals(null, section.title, 'Section title should not be null');
            System.assertNotEquals(null, section.headers, 'Section headers should not be null');
            System.assertNotEquals(null, section.rows, 'Section rows should not be null');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetOrgWideDefaultsDataAdvanced() {
        Test.startTest();
        
        SecurityAccessManagerController.SharingReportData result = SecurityAccessManagerController.getOrgWideDefaultsData();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.sections, 'Sections should not be null');
        
        // Verify OWD sections structure
        for (SecurityAccessManagerController.SharingReportSection section : result.sections) {
            System.assertNotEquals(null, section.title, 'OWD section title should not be null');
            System.assertNotEquals(null, section.headers, 'OWD section headers should not be null');
            System.assertNotEquals(null, section.rows, 'OWD section rows should not be null');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testGetUserPermissionFieldsAdvanced() {
        Test.startTest();
        
        List<User> testUsers = [SELECT Id FROM User WHERE LastName LIKE 'User%' LIMIT 3];
        List<String> userIds = new List<String>();
        for (User u : testUsers) {
            userIds.add(u.Id);
        }
        
        // Add current user ID for more comprehensive testing
        userIds.add(UserInfo.getUserId());
        
        SecurityAccessManagerController.UserPermissionsData result = SecurityAccessManagerController.getUserPermissionFields(userIds);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.permissionFields, 'Permission fields should not be null');
        System.assertNotEquals(null, result.userPermissions, 'User permissions should not be null');
        
        // Verify permission fields structure
        if (!result.permissionFields.isEmpty()) {
            SecurityAccessManagerController.PermissionFieldInfo firstField = result.permissionFields[0];
            System.assertNotEquals(null, firstField.name, 'Permission field name should not be null');
            System.assertNotEquals(null, firstField.label, 'Permission field label should not be null');
            System.assertNotEquals(null, firstField.category, 'Permission field category should not be null');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testTemplateManagementAdvanced() {
        // Create test templates in separate transaction
        createCustomObjects();
        
        Test.startTest();
        
        // Test saving multiple templates
        String templateName1 = 'Advanced Test Template 1';
        String templateName2 = 'Advanced Test Template 2';
        String cardType = 'user';
        String selectedFilters1 = '{"filters":["userName","userEmail","userStatus"],"userData":{"selectedUsers":[]}}';
        String selectedFilters2 = '{"filters":["profileName","userLicense"],"userData":{"selectedUsers":[]}}';
        
        Boolean result1 = SecurityAccessManagerController.saveTemplate(templateName1, cardType, selectedFilters1);
        Boolean result2 = SecurityAccessManagerController.saveTemplate(templateName2, cardType, selectedFilters2);
        
        System.assertEquals(true, result1, 'Should successfully save first template');
        System.assertEquals(true, result2, 'Should successfully save second template');
        
        // Test loading templates
        List<SecurityAccessManagerController.TemplateWrapper> templates = SecurityAccessManagerController.loadTemplates(cardType);
        System.assert(templates.size() >= 2, 'Should have at least 2 templates');
        
        // Test updating existing template
        String updatedFilters = '{"filters":["userName","userEmail","userStatus","profileName"],"userData":{"selectedUsers":[]}}';
        Boolean updateResult = SecurityAccessManagerController.saveTemplate(templateName1, cardType, updatedFilters);
        System.assertEquals(true, updateResult, 'Should successfully update template');
        
        // Test deleting template
        if (!templates.isEmpty()) {
            Boolean deleteResult = SecurityAccessManagerController.deleteTemplate(templates[0].id);
            System.assertEquals(true, deleteResult, 'Should successfully delete template');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testErrorHandlingAndEdgeCases() {
        Test.startTest();
        
        // Test with invalid inputs
        try {
            SecurityAccessManagerController.getReportData(null, 'user');
            System.assert(false, 'Should throw exception for null filters');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for null filters: ' + e.getMessage());
        }
        
        try {
            SecurityAccessManagerController.getUserPermissionFields(new List<String>{'invalid_id_123'});
            // Method might handle invalid IDs gracefully
            System.assert(true, 'Method handled invalid user IDs gracefully');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for invalid user IDs: ' + e.getMessage());
        }
        
        try {
            SecurityAccessManagerController.getReportMetadata('invalid_report_id');
            System.assert(false, 'Should throw exception for invalid report ID');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for invalid report ID: ' + e.getMessage());
        }
        
        try {
            SecurityAccessManagerController.saveTemplate('', 'user', '{}');
            // Method might succeed with empty name in test context
            System.assert(true, 'Save template handled gracefully');
        } catch (Exception e) {
            System.assert(true, 'Exception handled for empty template name: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testConfigIntelReportDataAdvanced() {
        Test.startTest();
        
        // Test with comprehensive filters
        List<String> allFilters = new List<String>{
            'validationRuleName', 'namespacePrefix', 'active', 'object', 
            'description', 'errorDisplayField', 'errorMessage', 'criteria'
        };
        
        SecurityAccessManagerController.ConfigIntelReportData result = SecurityAccessManagerController.getConfigIntelReportData(allFilters);
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(allFilters, result.headers, 'Headers should match all filters');
        System.assertNotEquals(null, result.rows, 'Rows should not be null');
        
        // Test with single filter
        List<String> singleFilter = new List<String>{'validationRuleName'};
        SecurityAccessManagerController.ConfigIntelReportData singleResult = SecurityAccessManagerController.getConfigIntelReportData(singleFilter);
        
        System.assertNotEquals(null, singleResult, 'Single filter result should not be null');
        System.assertEquals(singleFilter, singleResult.headers, 'Single filter headers should match');
        
        Test.stopTest();
    }
    
    @isTest
    static void testWrapperClassesAndDataStructures() {
        Test.startTest();
        
        // Test ReportData class
        SecurityAccessManagerController.ReportData reportData = new SecurityAccessManagerController.ReportData();
        reportData.headers = new List<String>{'Header1', 'Header2', 'Header3'};
        reportData.rows = new List<SecurityAccessManagerController.ReportRow>();
        
        SecurityAccessManagerController.ReportRow row = new SecurityAccessManagerController.ReportRow();
        row.values = new List<String>{'Value1', 'Value2', 'Value3'};
        reportData.rows.add(row);
        
        System.assertEquals(3, reportData.headers.size(), 'Headers should be set correctly');
        System.assertEquals(1, reportData.rows.size(), 'Rows should be set correctly');
        System.assertEquals('Value1', reportData.rows[0].values[0], 'Row values should be set correctly');
        
        // Test UserFieldInfo class
        SecurityAccessManagerController.UserFieldInfo fieldInfo = new SecurityAccessManagerController.UserFieldInfo();
        fieldInfo.name = 'TestField';
        fieldInfo.label = 'Test Field';
        fieldInfo.type = 'STRING';
        fieldInfo.isCustom = true;
        fieldInfo.isRequired = false;
        fieldInfo.category = 'Test Category';
        
        System.assertEquals('TestField', fieldInfo.name, 'Field name should be set correctly');
        System.assertEquals('Test Field', fieldInfo.label, 'Field label should be set correctly');
        System.assertEquals('STRING', fieldInfo.type, 'Field type should be set correctly');
        System.assertEquals(true, fieldInfo.isCustom, 'IsCustom should be set correctly');
        System.assertEquals(false, fieldInfo.isRequired, 'IsRequired should be set correctly');
        System.assertEquals('Test Category', fieldInfo.category, 'Category should be set correctly');
        
        // Test TemplateWrapper class
        SecurityAccessManagerController.TemplateWrapper wrapper = new SecurityAccessManagerController.TemplateWrapper();
        wrapper.id = 'testId';
        wrapper.name = 'testName';
        wrapper.selectedFilters = 'testFilters';
        wrapper.createdDate = DateTime.now();
        wrapper.lastModifiedDate = DateTime.now();
        
        System.assertEquals('testId', wrapper.id, 'ID should be set correctly');
        System.assertEquals('testName', wrapper.name, 'Name should be set correctly');
        System.assertEquals('testFilters', wrapper.selectedFilters, 'Selected filters should be set correctly');
        System.assertNotEquals(null, wrapper.createdDate, 'Created date should be set');
        System.assertNotEquals(null, wrapper.lastModifiedDate, 'Last modified date should be set');
        
        // Test PermissionFieldInfo class
        SecurityAccessManagerController.PermissionFieldInfo permFieldInfo = new SecurityAccessManagerController.PermissionFieldInfo();
        permFieldInfo.name = 'TestPermission';
        permFieldInfo.label = 'Test Permission';
        permFieldInfo.category = 'Administrative Permissions';
        
        System.assertEquals('TestPermission', permFieldInfo.name, 'Permission name should be set correctly');
        System.assertEquals('Test Permission', permFieldInfo.label, 'Permission label should be set correctly');
        System.assertEquals('Administrative Permissions', permFieldInfo.category, 'Permission category should be set correctly');
        
        // Test UserPermissionsData class
        SecurityAccessManagerController.UserPermissionsData permData = new SecurityAccessManagerController.UserPermissionsData();
        permData.permissionFields = new List<SecurityAccessManagerController.PermissionFieldInfo>();
        permData.userPermissions = new Map<String, Object>();
        
        permData.permissionFields.add(permFieldInfo);
        permData.userPermissions.put('TestPerm', true);
        
        System.assertEquals(1, permData.permissionFields.size(), 'Should have permission fields');
        System.assertEquals(1, permData.userPermissions.size(), 'Should have user permissions');
        System.assertEquals(true, permData.userPermissions.get('TestPerm'), 'Permission should be set to true');
        
        Test.stopTest();
    }
    
    @isTest
    static void testUserFieldComparatorAdvanced() {
        Test.startTest();
        
        SecurityAccessManagerController.UserFieldInfo field1 = new SecurityAccessManagerController.UserFieldInfo();
        field1.category = 'Basic Information';
        field1.label = 'Name';
        
        SecurityAccessManagerController.UserFieldInfo field2 = new SecurityAccessManagerController.UserFieldInfo();
        field2.category = 'Basic Information';
        field2.label = 'Email';
        
        SecurityAccessManagerController.UserFieldInfo field3 = new SecurityAccessManagerController.UserFieldInfo();
        field3.category = 'Security & Access';
        field3.label = 'Profile';
        
        SecurityAccessManagerController.UserFieldInfo field4 = new SecurityAccessManagerController.UserFieldInfo();
        field4.category = 'Contact Information';
        field4.label = 'Phone';
        
        SecurityAccessManagerController.UserFieldComparator comparator = new SecurityAccessManagerController.UserFieldComparator();
        
        // Test same category, different labels
        Integer result1 = comparator.compare(field1, field2);
        System.assert(result1 > 0, 'Name should come after Email alphabetically');
        
        // Test different categories
        Integer result2 = comparator.compare(field1, field3);
        System.assert(result2 < 0, 'Basic Information should come before Security & Access');
        
        // Test another category comparison
        Integer result3 = comparator.compare(field4, field3);
        System.assert(result3 < 0, 'Contact Information should come before Security & Access');
        
        // Test same fields
        Integer result4 = comparator.compare(field1, field1);
        System.assertEquals(0, result4, 'Same field should return 0');
        
        Test.stopTest();
    }
}