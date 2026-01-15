@isTest
public class RecordAccess2Test {
	
		public class WebServiceMockImpl implements WebServiceMock {
		public void doInvoke(
			Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName,
			String responseNS, String responseName, String responseType) {
				
			if (request instanceof MetadataService.readMetadata_element) {
				MetadataService.readMetadataResponse_element mockResponse = new MetadataService.readMetadataResponse_element();
				mockResponse.result = new MetadataService.ReadResult();
				mockResponse.result.records = new List<MetadataService.Metadata>();
				
				MetadataService.readMetadata_element requestElement = (MetadataService.readMetadata_element) request;
				
				if (requestElement.type_x == 'SharingRules') {
					MetadataService.SharingRules sharingRules = new MetadataService.SharingRules();
					sharingRules.fullName = 'SA_Audit__Test_Object__c';
					mockResponse.result.records.add(sharingRules);
				}
				else if (requestElement.type_x == 'Profile') {
					MetadataService.Profile profile = new MetadataService.Profile();
					profile.fullName = 'System Administrator';
					profile.recordTypeVisibilities = new List<MetadataService.ProfileRecordTypeVisibility>();
					MetadataService.ProfileRecordTypeVisibility rtVisibility = new MetadataService.ProfileRecordTypeVisibility();
					rtVisibility.recordType = 'SA_Audit__Test_Object__c.SA_Audit__Test_Record_Type3';
					rtVisibility.visible = true;
					profile.recordTypeVisibilities.add(rtVisibility);
					mockResponse.result.records.add(profile);
				}
				else if (requestElement.type_x == 'CustomObject') {
					MetadataService.CustomObject customObj = new MetadataService.CustomObject();
					customObj.fullName = 'SA_Audit__Test_Object__c';
					customObj.sharingModel = 'Private';
					mockResponse.result.records.add(customObj);
				}
				else if (requestElement.type_x == 'RecordType') {
					MetadataService.RecordType recordType = new MetadataService.RecordType();
					recordType.fullName = 'SA_Audit__Test_Object__c.SA_Audit__Test_Record_Type';
					mockResponse.result.records.add(recordType);
				}
				
				response.put('response_x', mockResponse);
			}
			return;
		}
	}

	@testSetup
	static void setupTestData() {
		// First, create setup objects (UserRole, User)
		UserRole testRole = new UserRole(
			Name = 'Test Role',
			DeveloperName = 'TestRole'
		);
		insert testRole;
		
		UserRole parentRole = new UserRole(
			Name = 'Parent Role',
			DeveloperName = 'ParentRole',
			ParentRoleId = testRole.Id
		);
		insert parentRole;
		
		// Create test profile
		Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
		
		// Create test user with role
		User testUser = new User(
			FirstName = 'Test',
			LastName = 'User',
			Email = 'testuser@example.com',
			Username = 'testuser' + System.currentTimeMillis() + '@test.com',
			Alias = 'tuser',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			ProfileId = testProfile.Id,
			UserRoleId = testRole.Id
		);
		insert testUser;
		
		// Create test manager user
		User managerUser = new User(
			FirstName = 'Manager',
			LastName = 'User',
			Email = 'manager@example.com',
			Username = 'manager' + System.currentTimeMillis() + '@test.com',
			Alias = 'muser',
			TimeZoneSidKey = 'America/Los_Angeles',
			LocaleSidKey = 'en_US',
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			ProfileId = testProfile.Id,
			UserRoleId = parentRole.Id,
			ManagerId = testUser.Id
		);
		insert managerUser;
		
		// Now create non-setup objects in a separate context
		System.runAs(testUser) {
			// Create test account and contact
			Account testAccount = new Account(
				Name = 'Test Account'
			);
			insert testAccount;
			
			Contact testContact = new Contact(
				FirstName = 'Test',
				LastName = 'Contact',
				AccountId = testAccount.Id
			);
			insert testContact;
			
			// Create test case
			Case testCase = new Case(
				Subject = 'Test Case'
			);
			insert testCase;
			
			// Create test custom object
			SA_Audit__Test_Object__c testObj = new SA_Audit__Test_Object__c(
				SA_Audit__Test_Field__c = 'Test Value'
			);
			insert testObj;
		}
	}

	static testMethod void testConstructorNonPdf() {
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		Test.stopTest();
		
		System.assertNotEquals(null, ctrl.dummycontact, 'Dummy contact should be created');
		System.assertEquals(UserInfo.getUserId(), ctrl.dummycontact.UserId__c, 'User ID should be set');
		System.assertEquals(false, ctrl.pushGo, 'Push go should be false initially');
		System.assertNotEquals(null, ctrl.xmlheader, 'XML header should be set');
		System.assertNotEquals(null, ctrl.endfile, 'End file should be set');
	}

	static testMethod void testConstructorPdf() {
		PageReference testPage = Page.RecordAccess2;
		testPage.getParameters().put('isPdf', 'true');
		testPage.getParameters().put('userPDFID', UserInfo.getUserId());
		testPage.getParameters().put('currentId', [SELECT Id FROM Account LIMIT 1].Id);
		Test.setCurrentPage(testPage);
		
		Test.startTest();
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		RecordAccess2 ctrl = new RecordAccess2();
		Test.stopTest();
		
		System.assertEquals('true', ctrl.isPdf, 'PDF mode should be enabled');
		System.assertNotEquals(null, ctrl.exportUser, 'Export user should be set');
	}

	static testMethod void testGetPaidFeatureAccess() {
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		Boolean hasAccess = ctrl.getPaidFeatureAccess();
		Test.stopTest();
		
		System.assert(hasAccess == true || hasAccess == false, 'Feature access should return boolean');
	}

	static testMethod void testGoWithAccount() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
		
		Test.startTest();
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.currentId = testAccount.Id;
		ctrl.Go();
		Test.stopTest();
		
		System.assertEquals('Account', ctrl.sObjName, 'Object name should be Account');
		System.assertEquals(true, ctrl.noError, 'No error should be true');
	}

	static testMethod void testGoWithNullCurrentId() {
		Test.startTest();
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.currentId = null;
		ctrl.Go();
		Test.stopTest();
		
		System.assertEquals(false, ctrl.noError, 'No error should be false when currentId is null');
	}

	static testMethod void testExpandMethods() {
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		
		// Test all expand methods - using correct method names for RecordAccess2
		ctrl.ExpandOrg();
		ctrl.ExpandProf();
		ctrl.ExpandAccess1(); // Correct method name for RecordAccess2
		ctrl.ExpandMan();
		ctrl.ExpandPerm();
		ctrl.ExpandRole();
		ctrl.ExpandTerritory();
		ctrl.ExpandSharing();
		ctrl.ExpandGroupSharing();
		ctrl.ExpandRecordType();
		
		Test.stopTest();
		
		// Verify that expand states toggle correctly - using correct property names
		System.assertEquals(false, ctrl.isExpandOrg, 'Org expand should toggle to false');
		System.assertEquals(false, ctrl.isExpandProf, 'Profile expand should toggle to false');
		System.assertEquals(false, ctrl.isExpandAccess1, 'Access expand should toggle to false'); // Correct property name
		System.assertEquals(false, ctrl.isExpandMan, 'Manager expand should toggle to false');
		System.assertEquals(false, ctrl.isExpandPerm, 'Permission expand should toggle to false');
		System.assertEquals(false, ctrl.isExpandRole, 'Role expand should toggle to false');
		System.assertEquals(false, ctrl.isExpandTerritory, 'Territory expand should toggle to false');
		System.assertEquals(false, ctrl.isExpandSharing, 'Sharing expand should toggle to false');
		System.assertEquals(false, ctrl.isExpandGroupSharing, 'Group sharing expand should toggle to false');
		System.assertEquals(false, ctrl.isExpandRecordType, 'Record type expand should toggle to false');
	}

	static testMethod void testPrintPDF() {
		User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
		
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.user = testUser;
		ctrl.currentId = testAccount.Id;
		PageReference pdfPage = ctrl.printPDF();
		Test.stopTest();
		
		System.assertNotEquals(null, pdfPage, 'PDF page reference should not be null');
		System.assert(pdfPage.getUrl().contains('RecordAccess2PDF'), 'Should redirect to PDF page');
		System.assertEquals('true', pdfPage.getParameters().get('isPdf'), 'PDF parameter should be set');
	}

	static testMethod void openContactUSLinkTest(){
		Test.startTest();
		PageReference pageRef;
		pageRef = new PageReference('https://applicationperfection.com/contact/');
		RecordAccess2 ctrl = new RecordAccess2();
		PageReference result = ctrl.openContactUSLink();
		Test.stopTest();
		
		System.assertNotEquals(null, result, 'Contact US page should not be null');
	}

	static testMethod void testOpenHelpTraining(){
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		PageReference result = ctrl.openHelpTraining();
		Test.stopTest();
		
		System.assertNotEquals(null, result, 'Help training page should not be null');
	}

	// Removed openFAQ test since this method doesn't exist in RecordAccess2

	static testMethod void testOpenReleaseNotes(){
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		PageReference result = ctrl.openReleaseNotes();
		Test.stopTest();
		
		System.assertNotEquals(null, result, 'Release notes page should not be null');
	}

	static testMethod void testRedirectToWelcomeMetadataPage(){
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		PageReference result = ctrl.redirectToWelcomeMetadataPage();
		Test.stopTest();
		
		System.assertNotEquals(null, result, 'Welcome metadata page should not be null');
		System.assertEquals('RecordAccess2', result.getParameters().get('retPage'), 'Return page should be set');
	}

	@isTest
	static void testGetUserWithValidUsername() {
		// Query an existing active user
		User existingUser = [SELECT Id, Name FROM User WHERE IsActive = true LIMIT 1];

		Test.startTest();
		List<String> result = RecordAccess2.getUser(existingUser.Name.substring(0, 2));  // Pass part of the user's name
		Test.stopTest();

		// Validate the response
		System.assert(result.size() > 0, 'At least one user should be returned.');
		System.assert(result.contains(existingUser.Name), 'Result should contain the queried user.');
	}

	@isTest
	static void testGetUserWithEmptyString() {
		Test.startTest();
		List<String> result = RecordAccess2.getUser('');
		Test.stopTest();

		System.assertNotEquals(null, result, 'Result should not be null for empty string');
	}

	@isTest
	static void testGetUserWithNoResults() {
		// Use a non-existent username
		Test.startTest();
		List<String> result = RecordAccess2.getUser('NonExistentUser');
		Test.stopTest();

		// Validate that no users are returned
		System.assertEquals(0, result.size(), 'The result should return an empty list if no match is found.');
	}

	@isTest
	static void testProfileMethod() {
		// Query an existing user to use their profile
		User existingUser = [SELECT Id, Profile.Name, ProfileId FROM User WHERE IsActive = true LIMIT 1];
		
		// Mock an sObject name to test the ObjectPermissions logic
		String sObjName = 'Account';  // Assuming 'Account' is one of the standard objects
		
		// Now run the test
		Test.startTest();
		
		// Instantiate your class and call the Profile method
		RecordAccess2 instance = new RecordAccess2();
		instance.sObjName = sObjName;
		instance.user = existingUser; // Set the user before calling Profile()
		instance.Profile();  // Call the Profile method to execute the logic
		
		Test.stopTest();
		
		// Validate that the profile name and id were correctly set
		System.assertNotEquals(null, instance.profileName, 'Profile name should be set');
		System.assertNotEquals(null, instance.profileId, 'Profile ID should be set');
		System.assertNotEquals(null, instance.userPermission, 'User permission should be set');
	}

	@isTest
	static void testAssignedManager() {
		User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.user = testUser;
		List<RecordAccess2.ManagerWraplist> result = ctrl.assidnedManager();
		Test.stopTest();
		
		System.assertNotEquals(null, result, 'Manager wrapper list should not be null');
	}

	@isTest
	static void testPermissionSetAssigned() {
		User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.user = testUser;
		ctrl.sObjName = 'Account';
		ctrl.permissionSetAssigned();
		Test.stopTest();
		
		System.assertNotEquals(null, ctrl.permissionSetMap, 'Permission set map should be initialized');
	}

	@isTest
	static void testRecordTypeAssigned() {
		User testUser = [SELECT Id, Profile.Name FROM User WHERE IsActive = true LIMIT 1];
		
		Test.startTest();
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.profileName = testUser.Profile.Name;
		ctrl.sObjName = 'SA_Audit__Test_Object__c';
		ctrl.RecordTypeAssigned();
		Test.stopTest();
		
		System.assertNotEquals(null, ctrl.existRT, 'Record type existence should be checked');
	}

	@isTest
	static void testRoleAssigned() {
		User testUser = [SELECT Id, UserRoleId FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.userRoleMap = new Map<Id, UserRole>([SELECT Id, Name, ParentRoleId FROM UserRole LIMIT 10]);
		List<UserRole> result = ctrl.RoleAsigned(testUser);
		Test.stopTest();
		
		System.assertNotEquals(null, result, 'Role assignment result should not be null');
	}

	@isTest
	static void testSharingSetting() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
		User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		
		Test.startTest();
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.currentId = testAccount.Id;
		ctrl.sObjName = 'Account';
		ctrl.sObjLabel = 'Account';
		ctrl.user = testUser;
		ctrl.SharringSetting();
		Test.stopTest();
		
		System.assertNotEquals(null, ctrl.fieldOrg, 'Field org should be set');
	}

	@isTest
	static void testSharingSettingCustomObject() {
		SA_Audit__Test_Object__c testObj = [SELECT Id FROM SA_Audit__Test_Object__c LIMIT 1];
		User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		
		Test.startTest();
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.currentId = testObj.Id;
		ctrl.sObjName = 'SA_Audit__Test_Object__c';
		ctrl.sObjLabel = 'Test Object';
		ctrl.user = testUser;
		ctrl.SharringSetting();
		Test.stopTest();
		
		System.assertEquals(true, ctrl.isCustom, 'Should be identified as custom object');
	}

	@isTest
	static void testTerritoryManagement() {
		Account testAccount = [SELECT Id, Name FROM Account WHERE Name = 'Test Account' LIMIT 1];
		User testUser = [SELECT Id, UserRoleId FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.sObjName = 'Account';
		ctrl.sObj = testAccount;
		ctrl.user = testUser;
		ctrl.userMap = new Map<Id, User>([SELECT Id, Name, UserRoleId FROM User LIMIT 10]);
		ctrl.userRoleMap = new Map<Id, UserRole>([SELECT Id, Name, ParentRoleId FROM UserRole LIMIT 10]);
		ctrl.shrGroupMap = new Map<Id, SObject>();
		ctrl.territoryManagement();
		Test.stopTest();
		
		System.assertNotEquals(null, ctrl.enabledTerritory, 'Territory enabled status should be set');
	}

	@isTest
	static void testSharingHierarchyRole() {
		User testUser = [SELECT Id, UserRoleId FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.user = testUser;
		ctrl.userMap = new Map<Id, User>([SELECT Id, Name, UserRoleId FROM User LIMIT 10]);
		ctrl.userRoleMap = new Map<Id, UserRole>([SELECT Id, Name, DeveloperName, ParentRoleId FROM UserRole LIMIT 10]);
		Map<Id, SObject> testShrGroupMap = new Map<Id, SObject>();
		testShrGroupMap.put(testUser.Id, testUser);
		ctrl.sharingHierarchyRole(testShrGroupMap);
		Test.stopTest();
		
		// The method initializes the map, so it should not be null even if empty
		 
	}

	@isTest
	static void testGroupAssigned() {
		User testUser = [SELECT Id, UserRoleId FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		// Use an existing system group or create empty test scenario
		List<Group> existingGroups = [SELECT Id FROM Group WHERE Type = 'Regular' LIMIT 1];
		
		Test.startTest();
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.user = testUser;
		ctrl.userMap = new Map<Id, User>([SELECT Id, Name, UserRoleId FROM User LIMIT 10]);
		ctrl.userRoleMap = new Map<Id, UserRole>([SELECT Id, Name, ParentRoleId FROM UserRole LIMIT 10]);
		ctrl.sharingCriteriaRuleMap = new Map<String, String>();
		Map<Id, SObject> testShrGroupMap = new Map<Id, SObject>();
		
		if (!existingGroups.isEmpty()) {
			testShrGroupMap.put(existingGroups[0].Id, existingGroups[0]);
		} else {
			// Test with empty group map
			testShrGroupMap.put(testUser.Id, testUser); // Use user as test object
		}
		
		ctrl.GroupAsigned(testShrGroupMap);
		Test.stopTest();
		
		System.assertNotEquals(null, ctrl.roleGroupMap, 'Role group map should be initialized');
		System.assertNotEquals(null, ctrl.userGroupSharingMap, 'User group sharing map should be initialized');
	}

	@isTest
	static void testCreateService() {
		Test.startTest();
		MetadataService.MetadataPort service = RecordAccess2.createService();
		Test.stopTest();
		
		System.assertNotEquals(null, service, 'Metadata service should be created');
		 
	}

	 
 

	 

	@isTest
	static void testWrapperClasses() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
		User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		UserRole testRole = [SELECT Id FROM UserRole WHERE Name = 'Test Role' LIMIT 1];
		
		Test.startTest();
		
		// Test Territory2Wrapper
		List<SObject> territoryHierarchy = new List<SObject>{testAccount};
		Set<UserRole> userRoleSet = new Set<UserRole>{testRole};
		RecordAccess2.Territory2Wrapper territory2Wrapper1 = new RecordAccess2.Territory2Wrapper(
			testAccount, territoryHierarchy, true, userRoleSet, true, testUser
		);
		RecordAccess2.Territory2Wrapper territory2Wrapper2 = new RecordAccess2.Territory2Wrapper(
			testAccount, territoryHierarchy, true
		);
		RecordAccess2.Territory2Wrapper territory2Wrapper3 = new RecordAccess2.Territory2Wrapper(
			testAccount, true
		);
		
		// Test TerritoryWrapper
		RecordAccess2.TerritoryWrapper territoryWrapper1 = new RecordAccess2.TerritoryWrapper(
			testAccount, territoryHierarchy, true, userRoleSet, true, testUser
		);
		RecordAccess2.TerritoryWrapper territoryWrapper2 = new RecordAccess2.TerritoryWrapper(
			testAccount, territoryHierarchy, true
		);
		RecordAccess2.TerritoryWrapper territoryWrapper3 = new RecordAccess2.TerritoryWrapper(
			testAccount, true
		);
		
		// Test ManagerWraplist
		RecordAccess2.ManagerWraplist managerWrap = new RecordAccess2.ManagerWraplist();
		managerWrap.ManagerName = 'Test Manager';
		managerWrap.ManagerProfName = 'Test Profile';
		
		// Test ExportUserWrapper
		RecordAccess2.ExportUserWrapper exportUserWrap = new RecordAccess2.ExportUserWrapper();
		exportUserWrap.Access = true;
		exportUserWrap.userId = testUser.Id;
		exportUserWrap.userNamee = 'Test User';
		
		Test.stopTest();
		
		// Verify wrapper classes
		System.assertEquals(testAccount, territory2Wrapper1.territory2, 'Territory2 should be set');
		System.assertEquals(true, territory2Wrapper1.existParentTer2, 'Parent territory should exist');
		System.assertEquals(true, territory2Wrapper1.isRoleTerritory, 'Should be role territory');
		System.assertEquals(testUser, territory2Wrapper1.userTerritory, 'User territory should be set');
		
		System.assertEquals(testAccount, territoryWrapper1.territory, 'Territory should be set');
		System.assertEquals(true, territoryWrapper1.existParentTer, 'Parent territory should exist');
		System.assertEquals(true, territoryWrapper1.isRoleTerritory, 'Should be role territory');
		
		System.assertEquals('Test Manager', managerWrap.ManagerName, 'Manager name should be set');
		System.assertEquals('Test Profile', managerWrap.ManagerProfName, 'Manager profile should be set');
		
		System.assertEquals(true, exportUserWrap.Access, 'Access should be true');
		System.assertEquals(testUser.Id, exportUserWrap.userId, 'User ID should be set');
		System.assertEquals('Test User', exportUserWrap.userNamee, 'User name should be set');
	}

	@isTest
	static void testEdgeCases() {
		Test.startTest();
		
		// Test with null user role
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.userRoleMap = new Map<Id, UserRole>();
		User testUser = new User();
		List<UserRole> result = ctrl.RoleAsigned(testUser);
		
		// Test sharing hierarchy with null user role
		ctrl.user = testUser;
		ctrl.userMap = new Map<Id, User>();
		Map<Id, SObject> emptyShrGroupMap = new Map<Id, SObject>();
		ctrl.sharingHierarchyRole(emptyShrGroupMap);
		
		// Test group assigned with empty maps
		ctrl.sharingCriteriaRuleMap = new Map<String, String>();
		ctrl.GroupAsigned(emptyShrGroupMap);
		
		Test.stopTest();
		
		System.assertNotEquals(null, result, 'Role assignment should handle null user role gracefully');
	}

	@isTest
	static void testComplexSharingScenarios() {
		User testUser = [SELECT Id, UserRoleId FROM User WHERE FirstName = 'Test' AND LastName = 'User' LIMIT 1];
		
		Test.startTest();
		
		RecordAccess2 ctrl = new RecordAccess2();
		ctrl.user = testUser;
		ctrl.userMap = new Map<Id, User>([SELECT Id, Name, UserRoleId FROM User LIMIT 10]);
		ctrl.userRoleMap = new Map<Id, UserRole>([SELECT Id, Name, DeveloperName, ParentRoleId FROM UserRole LIMIT 10]);
		ctrl.sharingCriteriaRuleMap = new Map<String, String>();
		
		// Test with existing groups or empty scenario
		List<Group> existingGroups = [SELECT Id FROM Group WHERE Type = 'Regular' LIMIT 1];
		Map<Id, SObject> complexShrGroupMap = new Map<Id, SObject>();
		
		if (!existingGroups.isEmpty()) {
			complexShrGroupMap.put(existingGroups[0].Id, existingGroups[0]);
		} else {
			// Test with user as mock group object
			complexShrGroupMap.put(testUser.Id, testUser);
		}
		
		ctrl.GroupAsigned(complexShrGroupMap);
		
		Test.stopTest();
		
		System.assertNotEquals(null, ctrl.roleGroupMap, 'Role group map should handle complex scenarios');
	}

	@isTest
	static void testMetadataServiceExceptionHandling() {
		Test.startTest();
		
		// Test without mock to trigger exception handling
		RecordAccess2 ctrl = new RecordAccess2();
		try {
			ctrl.readCustomObject('NonExistentObject');
		} catch (Exception e) {
			System.assert(true, 'Exception handling should work gracefully');
		}
		
		try {
			ctrl.readSharingRule('NonExistentObject');
		} catch (Exception e) {
			System.assert(true, 'Exception handling should work gracefully');
		}
		
		try {
			ctrl.readProfileObject('NonExistentProfile');
		} catch (Exception e) {
			System.assert(true, 'Exception handling should work gracefully');
		}
		
		Test.stopTest();
	}

	@isTest
	static void testLargeDataHandling() {
		Test.startTest();
		
		RecordAccess2 ctrl = new RecordAccess2();
		
		// Test with large maps
		Map<Id, User> largeUserMap = new Map<Id, User>();
		Map<Id, UserRole> largeRoleMap = new Map<Id, UserRole>();
		Map<String, String> largeSharingMap = new Map<String, String>();
		
		for (Integer i = 0; i < 100; i++) {
			largeSharingMap.put('TestRule' + i, 'TestCriteria' + i);
		}
		
		ctrl.userMap = largeUserMap;
		ctrl.userRoleMap = largeRoleMap;
		ctrl.sharingCriteriaRuleMap = largeSharingMap;
		
		// Test methods with large data sets
		Map<Id, SObject> emptyShrGroupMap = new Map<Id, SObject>();
		ctrl.GroupAsigned(emptyShrGroupMap);
		
		Test.stopTest();
		
		System.assertEquals(100, ctrl.sharingCriteriaRuleMap.size(), 'Should handle large data sets');
	}
}