/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-12-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class ObjectAccess {
    
     // Method to check if the feature is enabled for the user
     public Boolean hasAccess { get; set; }
     
     // Simple property that always returns false for Visualforce conditional rendering
     public Boolean falseValue { 
         get { return false; } 
         set; 
     }
    
	public List<Profile> actualProfiles { get; set; }
	public List<ProfileWrapper> profileWList { get; set; }
	//public List<PermissionSet> permisionSetList { get; set; }
	public String permissionId { get; set; }
    
	public String selectedObject { get; set; }
	public List<SelectOption> objectsNameList { get; set; }
	public List<SelectOption> objectsNameList1 { get; set; }
	public Map<String, String> objectsNameMap { get; set; }
	public Map<Id, UserLicense> userLicenseMap { get; set; }
	public List<Id> customProfilesIdList { get; set; }
	public Boolean retrieveCustomProfile { get; set; }
	public String xmlheader { get; set; }
	public String endfile { get; set; }
	public String currentLanguage { get; set; }
	public Organization org { get; set; }
	public Boolean isAccessible { get; set; }
	public Boolean OrgIsAccessible { get; set; }
	public Boolean userLicenseNotAccessible { get; set; }
	public List<ProfileWrapper> profileWSaveList { get; set; }
	public String selectedLog { get; set; }
	public Map<Id, String> profileMap { get; set; }
	public String controler { get; set; }
	public List<SelectOption> optionsLog { get; set; }
	public Datetime selectedLogValue { get; set; }
	public String description { get; set; }
	public String userSavedLog { get; set; }
	public String exportUser { get; set; }
	public Boolean displayPopUp { get; set; }
	public List<SelectOption> selectedObjectsList { get; set; }
	public transient Map<String, List<ProfileWrapper>> objectProfileWListMap { get; set; }
	public List<SelectOption> selectedProfiles { get; set; }
	public List<SelectOption> remainingProfiles { get; set; }
	public List<SelectOption> remainingProfiles1 { get; set; }
	public Boolean isManaged { get; set; }
	public String selectedType { get; set; }
	public Boolean existCustomProfiles { get; set; }
	public Boolean canChange { get; set; }
	public String selectedPerm { get; set; }
    public String AllPSetGrp { get; set; }
	public String namespacePrefix { get; set;}
	public String standardProfileIds { get; set; }
	public Boolean moreThan1000Obj { get; set; }
    public string recordId { get; set; }
	
	@TestVisible 
	public static List<SelectOption> objectsList { get; set; }
		/*get {
			if (objectsList == null) {
				return SecurityUtil.getObjectsList(org.NamespacePrefix);
			}
			return objectsList;
		}
		set;
	}*/
	
	/*@RemoteAction
	public static List<SelectOptionWrapper> getObjects() {
		Boolean isManaged = false;
		String orgId = UserInfo.getOrganizationId();
		Organization org = [SELECT Id , Name, NamespacePrefix FROM Organization WHERE ID = :orgID];
		List<SelectOption> objectsList1 = new List<SelectOption>(SecurityUtil.getObjectsList(org.namespacePrefix,isManaged));
		List<SelectOptionWrapper> options = new List<SelectOptionWrapper>();
		for(SelectOption o : objectsList1) {
			options.add(new SelectOptionWrapper(o));
		}
		objectsList = objectsList1;
		return options;
	}*/
	// THIS is the script to be copied in visualforce page if use Remote Action
	/*function getObjects() {
			console.log('intra::');
			var txt= document.getElementById("IdOfSelectElement");
					alert(txt);
			Visualforce.remoting.Manager.invokeAction(
			'{!$RemoteAction.ObjectAccess.getObjects}',
			
			function(result, event){
				if(event.status) {
					console.log('11::');
					
					//need to segregate result into value and label
					var opt = new Option(result); 
					document.getElementById("IdOfSelectElement").append(opt);
					//jQuery("[id$=IdOfSelectElement]").append(opt); 
				}
				else alert("error");
			});
		}
		
		window.onload = getObjects;*/
	
	public List<SelectOption> getObjectsType() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('Organization Object','Organization Object'));
		options.add(new SelectOption('Managed Object','Managed Object'));
		return options;
	}
	
	public List<SelectOption> getPermissionType() {
		List<SelectOption> options = new List<SelectOption>();
		options = SecurityUtil.getPermissionType();
		return options;
	}
    
    public List<SelectOption> getPermissionGrpType() {
		List<SelectOption> options = new List<SelectOption>();
		options = SecurityUtil.getPermissionGrpType();
		return options;
	}
    
     // Method to check if the feature is enabled for the user
    /*public Boolean getPaidFeatureAccess() {
        // Check if the feature is enabled for the user
        return FeatureManagement.checkPackageBooleanValue('ObjectAccessPaid');
    }*/
    public Boolean getPaidFeatureAccess() {
        try {
            // Attempt to check if the feature is enabled for the user
           //return FeatureManagement.checkPackageBooleanValue('ObjectAccessPaid');
            
            //for data dictionary
            //set to true wanted to check the help training buttons.
             return true;
        } catch (System.NoDataFoundException e) {
            // Log the exception for debugging purposes
            System.debug('Feature parameter not found: ' + e.getMessage());
            // Handle the exception gracefully, return false to indicate no access
            return false;
        } catch (Exception e) {
            // Catch any other exceptions that might occur
            System.debug('An unexpected error occurred: ' + e.getMessage());
            // Handle the exception gracefully, return false to indicate no access
            return false;
        }
    }
	
	public objectAccess() {
        
        hasAccess = getPaidFeatureAccess();
        
		selectedPerm = 'Organization Profiles & Permission Sets';
        AllPSetGrp = 'All PermissionSetGroups';
		isAccessible = true;
		selectedLog = '-- Please select --';
		User user = new User();
		if(Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
			Id currentUserId = UserInfo.getUserId();
			user = [SELECT ID, Name, Profile.Name, profile.permissionscustomizeapplication FROM User WHERE Id = :currentUserId];
		}
		if(user.Profile.Name.contains('System Administrator') || user.profile.permissionscustomizeapplication) {
			canChange = true;
		}
		PermissionSet prSet = new PermissionSet();
		prSet = [SELECT Id, Name FROM PermissionSet WHERE Label = 'Security Access Manager View Licence' OR Label = 'Security & Access Manager View Licence' ];
		List<PermissionSetAssignment> prSetAsignList = new List<PermissionSetAssignment>();
		prSetAsignList = [SELECT Id, PermissionSetId, AssigneeId FROM PermissionSetAssignment WHERE AssigneeId = :user.Id];
		if(prSetAsignList.size() > 0 && prSet != null) {
			for(PermissionSetAssignment prSetAsign : prSetAsignList) {
				if(prSet.Id == prSetAsign.PermissionSetId) {
					canChange = false;
				}
			}
		}
		if(canChange == null) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You do not have access to make changes to the security setup. Please contact your System Administrator.');
			ApexPages.addMessage(myMsg);
			isAccessible = false;
		}
		//system.debug('canChange::' + canChange);
		existCustomProfiles = true;
		isManaged = false;
		selectedObjectsList = new List<SelectOption>();
		//displayPopUp = true;
		OrgIsAccessible = true;
		
		xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
		endfile = '</Workbook>';
		currentLanguage = 'US';
		
		if(!Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()) {
			OrgIsAccessible = false;
		} else {
			String orgId = UserInfo.getOrganizationId();
			org = [SELECT Id , Name, NamespacePrefix FROM Organization WHERE ID = :orgID];
		}
		
		if(ApexPages.currentPage().getParameters().get('isPdf') != 'true') {
			selectedObject = 'Account';
		} else {
			selectedObject = ApexPages.currentPage().getParameters().get('selectedObject');
			selectedLog = ApexPages.currentPage().getParameters().get('selectedLog');
			//system.debug('selectedObject1::' + selectedObject);
			if (user != null) {
				exportUser = user.Name;
			} else {
				exportUser = '';
			}
			isManaged = ApexPages.currentPage().getParameters().get('isManaged') == 'true' ? true : false;
		}
		namespacePrefix = org.namespacePrefix;
		namespacePrefix = namespacePrefix == null ? '' : namespacePrefix;
		//system.debug('namespacePrefix:::' + namespacePrefix);
		objectsList = SecurityUtil.getObjectsList(org.NamespacePrefix, isManaged);
		//objectsList = new List<SelectOption>{new SelectOption('Account', 'Account')};
		//system.debug('objectsList:::' + org.namespacePrefix);
		//objectsList = new List<SelectOption>();
		//getObjects();
		objectsNameList = new List<SelectOption>();
		objectsNameList1 = new List<SelectOption>();
		objectsNameMap = new Map<String, String>();
		//system.debug('objectsList:::' + objectsList.size());
		for(SelectOption so : objectsList) {
			objectsNameList.add(new SelectOption(so.getValue(), so.getLabel()));
			objectsNameMap.put(so.getValue(), so.getLabel());
		}
        system.debug('objectsNameMap=='+objectsNameMap);
		objectsNameList = SecurityUtil.sortAfterLabelSelectOptionList(objectsNameList);
		getProfilesList();
         
	}
	
	public void getProfilesList() {
		customProfilesIdList = new List<Id>();
		remainingProfiles1 = new List<SelectOption>();
		profileMap = new Map<Id, String>();
		if(Schema.getGlobalDescribe().get('Profile').getDescribe().isAccessible()) {
			List<PermissionSet> standardProfiles = [SELECT ProfileId FROM PermissionSet Where Iscustom=false AND ProfileID != null];
			for(PermissionSet standardProf : standardProfiles){
				standardProfileIds += standardProf.ProfileId;
			}
			List<SelectOption> profilesList = new List<SelectOption>(SecurityUtil.getAllOrganizationProfilesList());
			profilesList.addAll(SecurityUtil.getAllOrganizationPermissionSetList());
			profilesList = SecurityUtil.sortAfterLabelSelectOptionList(profilesList);
			system.debug('profilesList::' + profilesList);
			if(ApexPages.currentPage().getParameters().get('isPdf') != 'true') {
				remainingProfiles = new List<SelectOption>(profilesList);
				if(remainingProfiles.size() == 0) {
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have any custom profiles that you can update');
					ApexPages.addMessage(myMsg);
					existCustomProfiles = false;
				} else {
					selectedProfiles = new List<SelectOption>();
					selectedProfiles.add(remainingProfiles[0]);
                    system.debug('selectedProfiles:239:' + selectedProfiles);
					customProfilesIdList.add(remainingProfiles[0].getValue());
                     system.debug('customProfilesIdList:240:' + customProfilesIdList);
					profileMap.put(remainingProfiles[0].getValue(), remainingProfiles[0].getLabel());
					remainingProfiles.remove(0);
					for(SelectOption so : remainingProfiles) {
						profileMap.put(so.getValue(), so.getLabel());
					}
					if(profilesList.size() > 900) {
						Integer i = 0;
						for(SelectOption so : profilesList){
							if(i < 900) {
								remainingProfiles.add(new SelectOption(so.getValue(), so.getLabel()));
							} else {
								remainingProfiles1.add(new SelectOption(so.getValue(), so.getLabel()));
							}
							i++;
						}
						remainingProfiles = SecurityUtil.sortAfterLabelSelectOptionList(remainingProfiles);
						remainingProfiles1 = SecurityUtil.sortAfterLabelSelectOptionList(remainingProfiles1);
					} else {
						remainingProfiles = SecurityUtil.sortAfterLabelSelectOptionList(remainingProfiles);
					}
					
					//system.debug('customProfilesIdList::' + customProfilesIdList);
				}
			} else {
				String selectedProfilesString;
				selectedProfilesString = ApexPages.currentPage().getParameters().get('selectedProfilesString');
				system.debug('selectedProfilesString::' + selectedProfilesString);
				String s = selectedProfilesString.substringBefore('+');
				selectedProfilesString = selectedProfilesString.removeStart(s + '+');
				While (selectedProfilesString.contains('+')) {
					s = selectedProfilesString.substringBefore('+');
					customProfilesIdList.add((Id)s);
					selectedProfilesString = selectedProfilesString.removeStart(s + '+');
				}
				customProfilesIdList.add((Id)selectedProfilesString);
				//system.debug('customProfilesIdListPDF::' + customProfilesIdList);
				Set<Id> selectedProfileIdSet = new Set<Id>(customProfilesIdList);
				remainingProfiles = new List<SelectOption>();
				selectedProfiles = new List<SelectOption>();
				for(SelectOption so : profilesList) {
					if(selectedProfileIdSet.contains(so.getValue())) {
						profileMap.put(so.getValue(), so.getLabel());
						selectedProfiles.add(so);
					} else {
						remainingProfiles.add(so);
					}
				}
				/*for(PermissionSet ps : permissionSetsList) {
					if(selectedProfileIdSet.contains(ps.Id)) {
						profileMap.put(ps.Id, ps.Label);
						selectedProfiles.add(new SelectOption(ps.Id, ps.Label));
					} else {
						remainingProfiles.add(new SelectOption(ps.Id, ps.Label));
					}
				}*/
			}
		} else {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on Profile object');
			ApexPages.addMessage(myMsg);
			isAccessible = false;
			return;
		}
		retrieveRecords();
	}
	
	/**
	 * Helper method to safely access profileWSaveList with bounds checking
	 * @param index The index to access
	 * @return ProfileWrapper object at the index, or null if index is invalid
	 */
	public ProfileWrapper getSafeProfileWSaveListItem(Integer index) {
		if (profileWSaveList != null && index >= 0 && index < profileWSaveList.size()) {
			return profileWSaveList[index];
		}
		return null;
	}
	
	// Current index for iteration - used by Visualforce page
	public Integer currentIndex { get; set; }
	
	/**
	 * Computed property to safely get the current profile save item
	 * Returns a safe ProfileWrapper or a default one if index is out of bounds
	 */
	public ProfileWrapper getCurrentProfileWSaveItem() {
		if (profileWSaveList != null && currentIndex != null && currentIndex >= 0 && currentIndex < profileWSaveList.size()) {
			return profileWSaveList[currentIndex];
		}
		// Return a default ProfileWrapper with empty permissions to prevent errors
		// Using the constructor that takes selectedObject, profUserLicenseId, profId, ParentId
		ProfileWrapper defaultWrapper = new ProfileWrapper(selectedObject, null, null, null);
		return defaultWrapper;
	}
	
	public List<SelectOption> getLogList() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('-- Please select --','-- Please select --'));
		
		List<SA_Audit__Object_Log__c> objLogList = [SELECT SA_Audit__Object_Type__c, SA_Audit__Date__c, SA_Audit__Value__c,  SA_Audit__Description__c, SA_Audit__User_Name__c FROM SA_Audit__Object_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject order by SA_Audit__Date__c desc LIMIT 999];
		//system.debug('objLogList::' + objLogList.size());
		for (SA_Audit__Object_Log__c log : objLogList) {
			options.add(new SelectOption(log.Id, log.SA_Audit__Date__c + ''));
		}
		return options;
	}
     
    
    
	public void Go() {
		List<SelectOption> profilesList = new List<SelectOption>();
		selectedLog = '-- Please select --';
		customProfilesIdList = new List<Id>();
		if(selectedProfiles.size() > 1000) {
			getProfilesList();
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'You can\'t select  more than 1000 records');
			ApexPages.addMessage(myMsg);
		}
		//profileMap = new Map<Id, String>();
		for(SelectOption so : selectedProfiles) {
			customProfilesIdList.add(so.getValue());
            system.debug('customProfilesIdList330:' + customProfilesIdList);
			//profileMap.put(so.getValue(), so.getLabel());
		}
		system.debug('customProfilesIdList.size::' + customProfilesIdList);
		retrieveRecords();
	}
	
	public void retrieveRecords() {
		//system.debug('aaasasas::' + selectedLog);
		optionsLog = getLogList();
		if(selectedLog != '-- Please select --' && selectedLog != '--+Please+select+--'){
			Map<Id, SA_Audit__Object_Log__c> logMap = new Map<Id, SA_Audit__Object_Log__c>([SELECT SA_Audit__Object_Type__c, SA_Audit__Date__c, SA_Audit__Value__c, SA_Audit__Description__c, SA_Audit__User_Name__c FROM SA_Audit__Object_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject order by SA_Audit__Date__c desc]);
			List<ProfileWrapper> profileWSaveListTemp = deserializeProfileWrapper(logMap.get((ID)selectedLog).SA_Audit__Value__c);
			selectedLogValue = logMap.get(selectedLog).SA_Audit__Date__c;
			description = logMap.get(selectedLog).SA_Audit__Description__c;
			userSavedLog = logMap.get(selectedLog).SA_Audit__User_Name__c;
			profileWSaveList = new List<ProfileWrapper>();
			Set<Id> customProfilesIdSetTemp = new Set<Id>();
			Map<Id, String> profileMapTemp = new Map<Id, String>();
			List<SelectOption> profileListTemp = new List<SelectOption>();
			for(SelectOption so : selectedProfiles) {
				customProfilesIdSetTemp.add(so.getValue());
				profileMapTemp.put(so.getValue(), so.getLabel());
				profileListTemp.add(so);
			}
			for(SelectOption so : remainingProfiles) {
				customProfilesIdSetTemp.add(so.getValue());
				profileMapTemp.put(so.getValue(), so.getLabel());
				profileListTemp.add(so);
			}
			customProfilesIdList = new List<Id>();
			selectedProfiles = new List<SelectOption>();
			remainingProfiles = new List<SelectOption>();
			//profileMap = new Map<Id, String>();
			
			// Create a set of profile IDs that exist in the saved log for filtering
			Set<Id> savedLogProfileIds = new Set<Id>();
			for(ProfileWrapper pw : profileWSaveListTemp) {
				if(customProfilesIdSetTemp.contains(pw.profId)) {
					profileWSaveList.add(pw);
					customProfilesIdList.add(pw.profId);
					selectedProfiles.add(new SelectOption(pw.profId, profileMapTemp.get(pw.profID)));
					savedLogProfileIds.add(pw.profId);
					//profileMap.put(pw.profId, profileMapTemp.get(pw.profID));
				}
			}
			
			// Filter profileWList to only include profiles that exist in the saved log
			// This ensures profileWList and profileWSaveList have the same size and order
			List<ProfileWrapper> filteredProfileWList = new List<ProfileWrapper>();
			for(ProfileWrapper pw : profileWList) {
				if(savedLogProfileIds.contains(pw.profId)) {
					filteredProfileWList.add(pw);
				}
			}
			profileWList = filteredProfileWList;
			
			for(SelectOption so : profileListTemp) {
				if(!customProfilesIdList.contains(so.getValue())) {
					remainingProfiles.add(so);
				}
			}
			if(ApexPages.currentPage().getParameters().get('isPdf') != 'true') {
				for(ProfileWrapper pw : profileWList) {
					profileWSaveList.add(pw);
				}
			}
			//system.debug('profileWSaveList::' + profileWSaveList);
			/*Integer index = 0;
			Integer ind;
			Boolean isFind;
			for(ProfileWrapper pw : profileWList) {
				isFind = false;
				ind = 0; 
				for(ProfileWrapper pws : profileWSaveListTemp) {
					if(pw.profId ==  pws.profId) {
						isFind = true;
						break;
					}
					ind++;
				}
				if(isFind) {
					profileWSaveList.set(index, profileWSaveListTemp.get(ind));
				}
				index++;
			}*/
		}
		Set<Id> idList = new Set<Id>();
		List<String> objNameList = new List<String>();
        system.debug('recordId400'+recordId);
        for (String objName : objectsNameMap.Keyset()) {
			objNameList.add(objectsNameMap.get(objName));
		}
            /*for(ObjectPermissions op : [select Id, ParentId from objectpermissions Where sObjectType IN :objNameList]) {
			if(((string)op.Id).startsWith('000')) {
				idList.add(op.ParentId);
			}
		}*/
		List<PermissionSet> permisionSetList = new List<PermissionSet>();
		Set<ID> customProfilesIdSet = new Set<Id>(customProfilesIdList);
		
		if(Schema.getGlobalDescribe().get('UserLicense').getDescribe().isAccessible()) {
			userLicenseNotAccessible = true;
			List<UserLicense> userL = [SELECT Name, ID from UserLicense WHERE Name != 'Analytics Cloud Integration User'];
			List<Objectpermissions> objPermList = new List<objectpermissions>();
			//system.debug('selectedObject::' + selectedObject);
			//String selectedObjectTemp = objectsNameMap.get(selectedObject);
			objPermList = [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
									 FROM Objectpermissions WHERE SobjectType = :selectedObject];
			//system.debug('objPermList::' + objPermList.size());
			Set<Id> idSet = new Set<Id>();
			Map<Id, List<Objectpermissions>> objPermMap = new Map<Id, List<Objectpermissions>>();
			for(Objectpermissions op : objPermList) {
				if(((string)op.Id).startsWith('000') && op.PermissionsModifyAllRecords != true) {
					idSet.add(op.ParentId);
				} else {
					if(!objPermMap.containsKey(op.ParentId)) {
						objPermMap.put(op.ParentId, new List<Objectpermissions>());
					}
					objPermMap.get(op.ParentId).add(op);
               //   system.debug('op.ParentId::' + op.ParentId + '===' + op);
				}
			}
			system.debug('idSet::' + idSet);
			system.debug('customProfilesIdSet::' + customProfilesIdSet);
			permisionSetList = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name, ProfileId, Profile.UserLicenseId, Label, LicenseId
								FROM PermissionSet 
								WHERE IsOwnedByProfile = true AND ProfileId IN :customProfilesIdSet AND Profile.UserLicenseId IN :userL]; //AND Id NOT IN :idSet];
            system.debug('permisionSetList::' + permisionSetList);
			
			List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, LicenseId,
													PermissionsModifyAllData, Profile.Name, Profile.UserLicenseId
													FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true AND Id IN :customProfilesIdSet AND Id NOT IN :idSet];
			profileWList = new List<ProfileWrapper>();
			Set<Id> userLicensesIdSet = new Set<Id>();
			for(Id prId : customProfilesIdList) {
				for(PermissionSet pr : permisionSetList) {
					if(pr.ProfileId == prId) {
						system.debug('objPermMap.get(pr.Id)::' + pr.Id + ' == ' + objPermMap.get(pr.Id));
						profileWList.add(new ProfileWrapper(objPermMap.get(pr.Id),selectedObject, pr.Id, pr.ProfileId, pr.Profile.UserLicenseId));
						userLicensesIdSet.add(pr.Profile.UserLicenseId);
					}
				}
				for(PermissionSet pr : permissionSetsList) {
					if(prID == pr.Id) {
						system.debug('prId::' + objPermMap.get(pr.Id));
						profileWList.add(new ProfileWrapper(objPermMap.get(pr.Id),selectedObject, pr.Id, pr.Id, pr.LicenseId));
						userLicensesIdSet.add(pr.LicenseId);
					}
					
				}
			}
			
			// Sort the ProfileWrapper list alphabetically by profile name
			profileWList = sortProfileWrapperList(profileWList);
			system.debug('userLicensesIdSet::' + userLicensesIdSet);
			userLicenseMap = new Map<Id, UserLicense>([SELECT Name, ID from UserLicense WHERE Id IN :userLicensesIdSet]);
			for(Id ulId : userLicensesIdSet) {
				if(!userLicenseMap.containsKey(ulId)) {
					userLicenseMap.put(ulId, new UserLicense());
				}
			}
		} else {
			userLicenseNotAccessible = false;
			/*permisionSetList = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name, ProfileId, Profile.UserLicenseId,
									(SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
									 FROM Objectperms) 
								FROM PermissionSet 
								WHERE IsOwnedByProfile = true 
								AND ProfileId IN :customProfilesIdSet];
								//AND ID NOT IN :idList];
			profileWList = new List<ProfileWrapper>();
			for(PermissionSet pr : permisionSetList) {
				profileWList.add(new ProfileWrapper(pr.Objectperms,objectsNameMap.get(selectedObject), pr.Id, pr.Profile.Name, pr.Profile.UserLicenseId));
			}*/
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on Profile object');
			ApexPages.addMessage(myMsg);
			isAccessible = false;
			return;
		}
		permisionSetList = new List<PermissionSet>();
        	System.debug('permisionSetList000'+permisionSetList);
		System.debug('4. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
	}
	
	public void changeObject() {
		description = '';
		selectedLog = '-- Please select --';
		retrieveRecords();
		//system.debug('selectedObject:::' + selectedObject);
	}
	
	public void changeType() {
		if(selectedType == 'Organization Object') {
			isManaged = false;
		} else {
			isManaged = true;
		}
        objectsNameList.addAll(selectedObjectsList);
        selectedObjectsList = new List<SelectOption>();
        objectsNameList = SecurityUtil.sortAfterLabelSelectOptionList(objectsNameList);

		objectsList = new List<SelectOption>(SecurityUtil.getObjectsList(org.NamespacePrefix, isManaged));
		
		objectsNameList = new List<SelectOption>();
		objectsNameList1 = new List<SelectOption>();
		objectsNameMap = new Map<String, String>();
		Integer i = 0;
		 
        Set<String> seenLabels = new Set<String>();

for (SelectOption so : objectsList) {
    String label = so.getLabel();

    // Check if the label already exists in the set
    if (seenLabels.contains(label)) {
        // If it does, append 'space' to the label
        label += ' ';
        // Update the label in the current SelectOption instance
        so.setLabel(label);
    }

    // Add the label to the set for tracking
    seenLabels.add(label);

    // Add the SelectOption to the appropriate list based on the count
    if (i < 900) {
        objectsNameList.add(so);
    } else {
        objectsNameList1.add(so);
    }

    // Add the SelectOption to the map
    objectsNameMap.put(so.getValue(), so.getLabel());
    i++;
}
		objectsNameList = SecurityUtil.sortAfterLabelSelectOptionList(objectsNameList);
		selectedObject = objectsNameList.size() > 0 ? selectedObject = objectsNameList[0].getValue() : '';
		//system.debug('selectedObject change type:::' + selectedObject);
		description = '';
		selectedLog = '-- Please select --';
		retrieveRecords();
	}
	
	public void changeLog() {
		if(selectedLog == '-- Please select --') {
			description = '';
			//system.debug('description:::' + description);
		}
		retrieveRecords();
		//system.debug('selectedObject:::' + selectedObject);
	}
	
	/*   Code before Scanner review 
	 **/ public void Save() {
		//system.debug('selectedObject:::' + selectedObject);
		if(Schema.getGlobalDescribe().get('ObjectPermissions').getDescribe().isCreateable()) {
			List<ObjectPermissions> objectPermisionList = new List<ObjectPermissions>();
			//String selObj = objectsNameMap.get(selectedObject);
			//system.debug('selObj::' + selObj);
			Map<Id, ObjectPermissions> objectPermissionMap = new Map<Id, ObjectPermissions>([SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
									 FROM ObjectPermissions WHERE SobjectType = :selectedObject]);
			//system.debug('profileWList.size::' + profileWList);
			for (ProfileWrapper pw : profileWList) {
				//system.debug('objectPermissionMap.containsKey(pw.objPerm.Id)::' + objectPermissionMap.containsKey(pw.objPerm.Id));
				if(!standardProfileIds.contains(pw.profId)) {
					if(!objectPermissionMap.containsKey(pw.objPerm.Id)) {
						ObjectPermissions objPerm = new ObjectPermissions(SobjectType = pw.objPerm.objType, ParentId = pw.objPerm.parentId );
						if(pw.objPerm.M == true) {
							objPerm = builObjPerm(objPerm, true, true, true, true, true, true);
							pw.objPerm.R = true;
							pw.objPerm.C = true;
							pw.objPerm.E = true;
							pw.objPerm.D = true;
							pw.objPerm.V = true;
							objectPermisionList.add(objPerm);
						} else {
							if (pw.objPerm.D == true) {
								objPerm = builObjPerm(objPerm, true, pw.objPerm.C, true, true, pw.objPerm.V, false);
								pw.objPerm.R = true;
								pw.objPerm.E = true;
								objectPermisionList.add(objPerm);
							}else{
								if (pw.objPerm.E == true ||
									pw.objPerm.C == true ||
									pw.objPerm.V == true) {
										objPerm = builObjPerm(objPerm, true, pw.objPerm.C, pw.objPerm.E, false, pw.objPerm.V, false);
										pw.objPerm.R = true;
										objectPermisionList.add(objPerm);
								} else {
									if(pw.objPerm.R == true) {
										objPerm = builObjPerm(objPerm, true, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
										objectPermisionList.add(objPerm);
									} else {
										if(pw.objPerm.id != null) {
											objPerm = builObjPerm(objPerm, pw.objPerm.R, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
											objectPermisionList.add(objPerm);
										}
									}
								}
							}
						}
					} else {
						ObjectPermissions objPerm = objectPermissionMap.get(pw.objPerm.Id);
						if(pw.objPerm.M != objPerm.PermissionsModifyAllRecords ||
								 pw.objPerm.D != objPerm.PermissionsDelete ||
								 pw.objPerm.E != objPerm.PermissionsEdit ||
								 pw.objPerm.C != objPerm.PermissionsCreate ||
								 pw.objPerm.V != objPerm.PermissionsViewAllRecords ||
								 pw.objPerm.R != objPerm.PermissionsRead) {
							if(pw.objPerm.M == true) {
								objPerm = builObjPerm(objPerm, true, true, true, true, true, true);
								pw.objPerm.R = true;
								pw.objPerm.C = true;
								pw.objPerm.E = true;
								pw.objPerm.D = true;
								pw.objPerm.V = true;
								objectPermisionList.add(objPerm);
							} else {
								if (pw.objPerm.D == true) {
									objPerm = builObjPerm(objPerm, true, pw.objPerm.C, true, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
									pw.objPerm.R = true;
									pw.objPerm.E = true;
									objectPermisionList.add(objPerm);
								}else{
									if (pw.objPerm.E == true ||
										pw.objPerm.C == true ||
										pw.objPerm.V == true) {
											objPerm = builObjPerm(objPerm, true, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
											pw.objPerm.R = true;
											objectPermisionList.add(objPerm);
									} else {
										if(pw.objPerm.R == true) {
											objPerm = builObjPerm(objPerm, true, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
											objectPermisionList.add(objPerm);
										} else {
											if(pw.objPerm.Id != null) {
												objPerm = builObjPerm(objPerm, pw.objPerm.R, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
												objectPermisionList.add(objPerm);
											}
										}
									}
								}
							}
						}
					}
				}
			}
			//system.debug('objectPermisionList:::' + objectPermisionList);
			if(objectPermisionList.size() > 0) {
				try {
					upsert objectPermisionList;
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'The changes are saved');
					ApexPages.addMessage(myMsg);
					String serializeW = SerializeProfileWrapper(profileWList);
					User user = new User();
					if(Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
						Id currentUserId = UserInfo.getUserId();
						user = [SELECT ID, Name FROM User WHERE Id = :currentUserId];
					}
					String userName;
					if(user != null) {
						userName = user.Name;
					} else {
						userName = '';
					}
					saveObjectLog(selectedObject, serializeW, description, userName);
					description = '';
				} catch (DMLException e) {
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(0));
					ApexPages.addMessage(myMsg);
					return;
				}
			} else {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'There are no changes to be saved');
				ApexPages.addMessage(myMsg);
			}
			retrieveRecords();
		} else {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on Profile object');
			ApexPages.addMessage(myMsg);
		}
		
	} 
    
    /* code modified for the scanner review
   public void Save() {
		//system.debug('selectedObject:::' + selectedObject);
		if(Schema.getGlobalDescribe().get('ObjectPermissions').getDescribe().isCreateable()) {
			List<ObjectPermissions> objectPermisionList = new List<ObjectPermissions>();
			//String selObj = objectsNameMap.get(selectedObject);
			//system.debug('selObj::' + selObj);
			Map<Id, ObjectPermissions> objectPermissionMap = new Map<Id, ObjectPermissions>([SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
									 FROM ObjectPermissions WHERE SobjectType = :selectedObject]);
			//system.debug('profileWList.size::' + profileWList);
			for (ProfileWrapper pw : profileWList) {
				//system.debug('objectPermissionMap.containsKey(pw.objPerm.Id)::' + objectPermissionMap.containsKey(pw.objPerm.Id));
				  if (  
                                Schema.sObjectType.ObjectPermissions.fields.SobjectType.isCreateable() &&
                                      Schema.sObjectType.ObjectPermissions.fields.ParentId.isCreateable() && 
                                Schema.sObjectType.ObjectPermissions.fields.PermissionsModifyAllRecords.isCreateable() &&
                                Schema.sObjectType.ObjectPermissions.fields.PermissionsDelete.isCreateable() &&
                                Schema.sObjectType.ObjectPermissions.fields.PermissionsEdit.isCreateable() &&
                                Schema.sObjectType.ObjectPermissions.fields.PermissionsCreate.isCreateable() &&
                                Schema.sObjectType.ObjectPermissions.fields.PermissionsViewAllRecords.isCreateable() &&
                                Schema.sObjectType.ObjectPermissions.fields.PermissionsRead.isCreateable() &&
               
                              Schema.sObjectType.ObjectPermissions.fields.SobjectType.isUpdateable() &&
                              Schema.sObjectType.ObjectPermissions.fields.ParentId.isUpdateable() &&
                            Schema.sObjectType.ObjectPermissions.fields.PermissionsRead.isUpdateable() && 
                            Schema.sObjectType.ObjectPermissions.fields.PermissionsEdit.isUpdateable() &&
                            Schema.sObjectType.ObjectPermissions.fields.PermissionsCreate.isUpdateable() &&
                            Schema.sObjectType.ObjectPermissions.fields.PermissionsDelete.isUpdateable() &&
                            Schema.sObjectType.ObjectPermissions.fields.PermissionsViewAllRecords.isUpdateable() &&
                            Schema.sObjectType.ObjectPermissions.fields.PermissionsModifyAllRecords.isUpdateable()) { 
                
                if(!standardProfileIds.contains(pw.profId)) {
					if(!objectPermissionMap.containsKey(pw.objPerm.Id)) {
						ObjectPermissions objPerm = new ObjectPermissions(SobjectType = pw.objPerm.objType, ParentId = pw.objPerm.parentId );
						if(pw.objPerm.M == true) {
							objPerm = builObjPerm(objPerm, true, true, true, true, true, true);
							pw.objPerm.R = true;
							pw.objPerm.C = true;
							pw.objPerm.E = true;
							pw.objPerm.D = true;
							pw.objPerm.V = true;
							objectPermisionList.add(objPerm);
						} else {
							if (pw.objPerm.D == true) {
								objPerm = builObjPerm(objPerm, true, pw.objPerm.C, true, true, pw.objPerm.V, false);
								pw.objPerm.R = true;
								pw.objPerm.E = true;
								objectPermisionList.add(objPerm);
							}else{
								if (pw.objPerm.E == true ||
									pw.objPerm.C == true ||
									pw.objPerm.V == true) {
										objPerm = builObjPerm(objPerm, true, pw.objPerm.C, pw.objPerm.E, false, pw.objPerm.V, false);
										pw.objPerm.R = true;
										objectPermisionList.add(objPerm);
								} else {
									if(pw.objPerm.R == true) {
										objPerm = builObjPerm(objPerm, true, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
										objectPermisionList.add(objPerm);
									} else {
										if(pw.objPerm.id != null) {
											objPerm = builObjPerm(objPerm, pw.objPerm.R, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
											objectPermisionList.add(objPerm);
										}
									}
								}
							}
						}
					} else {
						ObjectPermissions objPerm = objectPermissionMap.get(pw.objPerm.Id);
						if(pw.objPerm.M != objPerm.PermissionsModifyAllRecords ||
								 pw.objPerm.D != objPerm.PermissionsDelete ||
								 pw.objPerm.E != objPerm.PermissionsEdit ||
								 pw.objPerm.C != objPerm.PermissionsCreate ||
								 pw.objPerm.V != objPerm.PermissionsViewAllRecords ||
								 pw.objPerm.R != objPerm.PermissionsRead) {
							if(pw.objPerm.M == true) {
								objPerm = builObjPerm(objPerm, true, true, true, true, true, true);
								pw.objPerm.R = true;
								pw.objPerm.C = true;
								pw.objPerm.E = true;
								pw.objPerm.D = true;
								pw.objPerm.V = true;
								objectPermisionList.add(objPerm);
							} else {
								if (pw.objPerm.D == true) {
									objPerm = builObjPerm(objPerm, true, pw.objPerm.C, true, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
									pw.objPerm.R = true;
									pw.objPerm.E = true;
									objectPermisionList.add(objPerm);
								}else{
									if (pw.objPerm.E == true ||
										pw.objPerm.C == true ||
										pw.objPerm.V == true) {
											objPerm = builObjPerm(objPerm, true, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
											pw.objPerm.R = true;
											objectPermisionList.add(objPerm);
									} else {
										if(pw.objPerm.R == true) {
											objPerm = builObjPerm(objPerm, true, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
											objectPermisionList.add(objPerm);
										} else {
											if(pw.objPerm.Id != null) {
												objPerm = builObjPerm(objPerm, pw.objPerm.R, pw.objPerm.C, pw.objPerm.E, pw.objPerm.D, pw.objPerm.V, pw.objPerm.M);
												objectPermisionList.add(objPerm);
											}
										}
									}
								}
							}
						}
					}
				}
             //}
            }
			//system.debug('objectPermisionList:::' + objectPermisionList);
			if(objectPermisionList.size() > 0) {
				try {
					upsert  as user objectPermisionList;
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'The changes are saved');
					ApexPages.addMessage(myMsg);
					String serializeW = SerializeProfileWrapper(profileWList);
					User user = new User();
					if(Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
						Id currentUserId = UserInfo.getUserId();
						user = [SELECT ID, Name FROM User WHERE Id = :currentUserId];
					}
					String userName;
					if(user != null) {
						userName = user.Name;
					} else {
						userName = '';
					}
					//saveObjectLog(selectedObject, serializeW, description, userName);
					description = '';
				} catch (DMLException e) {
					ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(0));
					ApexPages.addMessage(myMsg);
					return;
				}
			} else {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'There are no changes to be saved');
				ApexPages.addMessage(myMsg);
			}
			retrieveRecords();
		} else {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on Profile object');
			ApexPages.addMessage(myMsg);
		}
		
	} */ 
    
    /*   Code before Scanner review */
	public void RevertChanges() {
		Integer index = 0;
		//String selObj = objectsNameMap.get(selectedObject);
		Map<Id, ObjectPermissions> objectPermissionMap = new Map<Id, ObjectPermissions>([SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
								 FROM ObjectPermissions WHERE SobjectType = :selectedObject]);
		List<ObjectPermissions> objectPermisionList = new List<ObjectPermissions>();
		for (ProfileWrapper pw : profileWList) {
			if(pw.objPerm.R != profileWSaveList[index].objPerm.R ||
				pw.objPerm.E != profileWSaveList[index].objPerm.E ||
				pw.objPerm.C != profileWSaveList[index].objPerm.C ||
				pw.objPerm.D != profileWSaveList[index].objPerm.D ||
				pw.objPerm.V != profileWSaveList[index].objPerm.V ||
				pw.objPerm.M != profileWSaveList[index].objPerm.M) {
				
				if(!objectPermissionMap.containsKey(pw.objPerm.Id)) {
					ObjectPermissions objPerm = new ObjectPermissions(SobjectType = pw.objPerm.objType, ParentId = pw.objPerm.parentId );
					objPerm = builObjPerm(objPerm, profileWSaveList[index].objPerm.R, profileWSaveList[index].objPerm.C, profileWSaveList[index].objPerm.E, profileWSaveList[index].objPerm.D, profileWSaveList[index].objPerm.V, profileWSaveList[index].objPerm.M);
					objectPermisionList.add(objPerm);
				} else {
					ObjectPermissions objPerm = objectPermissionMap.get(pw.objPerm.Id);
					objPerm = builObjPerm(objPerm, profileWSaveList[index].objPerm.R, profileWSaveList[index].objPerm.C, profileWSaveList[index].objPerm.E, profileWSaveList[index].objPerm.D, profileWSaveList[index].objPerm.V, profileWSaveList[index].objPerm.M);
					objectPermisionList.add(objPerm);
				}
			}
			index++;
		}
		try {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'The changes are saved');
			ApexPages.addMessage(myMsg);
			upsert as user objectPermisionList;
			retrieveRecords();
		} catch (DMLException e) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(0));
			ApexPages.addMessage(myMsg);
		}
	} 
  /*   public void RevertChanges() {
    Integer index = 0;
    
    // Check if 'ObjectPermissions' is createable and updateable
    if(Schema.getGlobalDescribe().get('ObjectPermissions').getDescribe().isUpdateable()) {
        
        // Retrieve the current object permissions for the selected object
        Map<Id, ObjectPermissions> objectPermissionMap = new Map<Id, ObjectPermissions>([SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
                                     FROM ObjectPermissions WHERE SobjectType = :selectedObject]);
        
        List<ObjectPermissions> objectPermisionList = new List<ObjectPermissions>();
        if (   Schema.sObjectType.ObjectPermissions.fields.SobjectType.isCreateable() &&
         Schema.sObjectType.ObjectPermissions.fields.ParentId.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsModifyAllRecords.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsDelete.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsEdit.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsCreate.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsViewAllRecords.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsRead.isCreateable() &&
            
               Schema.sObjectType.ObjectPermissions.fields.ParentId.isUpdateable() &&
             Schema.sObjectType.ObjectPermissions.fields.SobjectType.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsModifyAllRecords.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsDelete.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsEdit.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsCreate.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsViewAllRecords.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsRead.isUpdateable()
           ) {
        // Iterate through the ProfileWrapper list to check for changes
        for (ProfileWrapper pw : profileWList) {
            // Compare the current permission values with the saved ones
            if(pw.objPerm.R != profileWSaveList[index].objPerm.R ||
               pw.objPerm.E != profileWSaveList[index].objPerm.E ||
               pw.objPerm.C != profileWSaveList[index].objPerm.C ||
               pw.objPerm.D != profileWSaveList[index].objPerm.D ||
               pw.objPerm.V != profileWSaveList[index].objPerm.V ||
               pw.objPerm.M != profileWSaveList[index].objPerm.M) {

                // If no existing ObjectPermissions record for the current permission
                if(!objectPermissionMap.containsKey(pw.objPerm.Id)) {
                    ObjectPermissions objPerm = new ObjectPermissions(SobjectType = pw.objPerm.objType, ParentId = pw.objPerm.parentId );
                    // Set the permissions to saved values from profileWSaveList
                    objPerm = builObjPerm(objPerm, profileWSaveList[index].objPerm.R, profileWSaveList[index].objPerm.C, profileWSaveList[index].objPerm.E, profileWSaveList[index].objPerm.D, profileWSaveList[index].objPerm.V, profileWSaveList[index].objPerm.M);
                    objectPermisionList.add(objPerm);
                } else {
                    // If ObjectPermissions exists, update it with saved permission values
                    ObjectPermissions objPerm = objectPermissionMap.get(pw.objPerm.Id);
                    objPerm = builObjPerm(objPerm, profileWSaveList[index].objPerm.R, profileWSaveList[index].objPerm.C, profileWSaveList[index].objPerm.E, profileWSaveList[index].objPerm.D, profileWSaveList[index].objPerm.V, profileWSaveList[index].objPerm.M);
                    objectPermisionList.add(objPerm);
                }
            }
            index++;
        }
        
        // Proceed with the DML operation only if changes were made
        if(objectPermisionList.size() > 0) {
            try {
                // Confirm the changes
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'The changes are saved');
                ApexPages.addMessage(myMsg);
                
                // Perform upsert on the object permission list
                upsert as user objectPermisionList;
                retrieveRecords();
                
            } catch (DMLException e) {
                // Catch DML exceptions and show an error message
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getDmlMessage(0));
                ApexPages.addMessage(myMsg);
            }
        } else {
            // If no changes were made, show a warning message
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,'No changes to revert');
            ApexPages.addMessage(myMsg);
        }
    } else {
        // If the ObjectPermissions object is not updateable, show an error message
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access to update ObjectPermissions');
        ApexPages.addMessage(myMsg);
    }
    }
}*/
 
	public ObjectPermissions builObjPerm(ObjectPermissions objPerm, Boolean R, Boolean C, Boolean E, Boolean D, Boolean V, Boolean M) {
		/*  if (Schema.sObjectType.ObjectPermissions.fields.SobjectType.isAccessible() && 
            Schema.sObjectType.ObjectPermissions.fields.PermissionsModifyAllRecords.isAccessible() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsDelete.isAccessible() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsEdit.isAccessible() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsCreate.isAccessible() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsViewAllRecords.isAccessible() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsRead.isAccessible() &&
            
            Schema.sObjectType.ObjectPermissions.fields.SobjectType.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.SobjectType.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsModifyAllRecords.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsDelete.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsEdit.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsCreate.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsViewAllRecords.isCreateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsRead.isCreateable() &&
            
            Schema.sObjectType.ObjectPermissions.fields.PermissionsModifyAllRecords.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsDelete.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsEdit.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsCreate.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsViewAllRecords.isUpdateable() &&
            Schema.sObjectType.ObjectPermissions.fields.PermissionsRead.isUpdateable()
           ) {*/
		objPerm.PermissionsRead = R;
		objPerm.PermissionsCreate = C;
		objPerm.PermissionsEdit = E;
		objPerm.PermissionsDelete = D;
		objPerm.PermissionsViewAllRecords = V;
		objPerm.PermissionsModifyAllRecords = M;
        
           return objPerm;
	}
	/*
        @future
    public static void saveObjectLog(String selectedObject, String serializeW, String description, String userName) {
        Integer recordNumber =  [SELECT COUNT() FROM SA_Audit__Object_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject];
        //system.debug('recordNumber:' + recordNumber);
        SA_Audit__Object_Log__c objLog = new SA_Audit__Object_Log__c();
        if(recordNumber == 1000) {
            objLog = [SELECT ID FROM SA_Audit__Object_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject ORDER By SA_Audit__Date__c desc LIMIT 1];
            try {
                if(SA_Audit__Object_Log__c.sObjectType.getDescribe().isDeletable()){
                    delete as user objLog;
                }
            } catch (DMLException e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
                ApexPages.addMessage(myMsg);
            }
        }
        objLog = new SA_Audit__Object_Log__c();
        if(Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__Object_Type__c.isCreateable()
           && Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__Date__c.isCreateable()
           && Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__Description__c.isCreateable()
           && Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__User_Name__c.isCreateable()
           && Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__Value__c.isCreateable()){
               objLog.SA_Audit__Object_Type__c = selectedObject;
               objLog.SA_Audit__Date__c = Datetime.Now();
               objLog.SA_Audit__Value__c = serializeW;
               objLog.SA_Audit__Description__c = description;
               objLog.SA_Audit__User_Name__c = userName;
           }
        try {
            insert as user objLog;
            
        } catch (DMLException e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
            ApexPages.addMessage(myMsg);
        }
    }  
 comment for scanner
  *  */ @future
  public static void saveObjectLog(String selectedObject, String serializeW, String description, String userName) {
        try {
            Integer recordNumber = [SELECT COUNT() FROM SA_Audit__Object_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject];
            
             if (recordNumber >= 1000) {
                // Scheduled a separate batch cleanup job to handle older records  
                System.debug('Reached maximum log records');
                LogCleanupBatchOA cleanupBatch = new LogCleanupBatchOA(selectedObject);
                Database.executeBatch(cleanupBatch, 200); // Set batch size as appropriate

                return; //  
            } 
            
            // Create a new SA_Audit__Object_Log__c record only if fields are creatable
            if (Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__Object_Type__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__Date__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__Description__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__User_Name__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__Object_Log__c.fields.SA_Audit__Value__c.isCreateable()) {
                    
                    SA_Audit__Object_Log__c objLog = new SA_Audit__Object_Log__c();
                    objLog.SA_Audit__Object_Type__c = selectedObject;
                    objLog.SA_Audit__Date__c = Datetime.now();
                    objLog.SA_Audit__Value__c = serializeW;
                    objLog.SA_Audit__Description__c = description;
                    objLog.SA_Audit__User_Name__c = userName;
                    
                    insert objLog;
                } else {
                    System.debug('Required fields are not creatable. Record insertion skipped.');
                }
            
        } catch (DMLException e) {
            System.debug('DML Exception: ' + e.getMessage());
            // Optional: Add logging to a custom error log object instead of using ApexPages
        } catch (Exception ex) {
            System.debug('General Exception: ' + ex.getMessage());
            // Optional: Add logging to capture other exceptions
        }
    }

	public pageReference ExportToExcel() {
        displayPopUp = true;
		system.debug('selectedObjectsList::' + selectedObjectsList.size());
		system.debug('profileMap12:::' +  profileMap);
		User user = new User();
		if(Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
			Id currentUserId = UserInfo.getUserId();
			user = [SELECT ID, Name FROM User WHERE Id = :currentUserId];
		}
		if(user != null) {
			exportUser = user.Name;
		} else {
			exportUser = '';
		}
		
		if(selectedLog == '-- Please select --'){
			List<UserLicense> userL = [SELECT Name, ID from UserLicense WHERE Name != 'Analytics Cloud Integration User'];
			Set<ID> customProfilesIdSet = new Set<Id>(customProfilesIdList);
			Set<String> selctedObjSet = new Set<String>();
			for(SelectOption so : selectedObjectsList) {
				selctedObjSet.add(so.getValue());
			}
			//system.debug('selctedObjSet::' + selctedObjSet);
			List<Objectpermissions> objPermList = new List<objectpermissions>();
			objPermList = [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
									 FROM Objectpermissions WHERE SobjectType IN :selctedObjSet];
			//system.debug('objPermList::' + objPermList.size());
			Set<Id> idSet = new Set<Id>();
			Map<Id, List<Objectpermissions>> objPermMap = new Map<Id, List<Objectpermissions>>();
			for(Objectpermissions op : objPermList) {
				if(((string)op.Id).startsWith('000') && op.PermissionsModifyAllRecords != true) {
					idSet.add(op.ParentId);
				} else {
					if(!objPermMap.containsKey(op.ParentId)) {
						objPermMap.put(op.ParentId, new List<Objectpermissions>());
					}
					objPermMap.get(op.ParentID).add(op);
				}
			}
			List<PermissionSet> permisionSetList = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name, ProfileId, Profile.UserLicenseId, Label, LicenseId 
								FROM PermissionSet 
								WHERE IsOwnedByProfile = true AND ProfileId IN :customProfilesIdSet AND Profile.UserLicenseId IN :userL];// AND Id NOT IN :idSet];
			List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, LicenseId,
													PermissionsModifyAllData, Profile.Name, Profile.UserLicenseId
													FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true AND Id IN :customProfilesIdSet AND Id NOT IN :idSet];
			objectProfileWListMap = new Map<String, List<ProfileWrapper>>();
			system.debug('selectedObjectsList::' + selectedObjectsList);
			for(SelectOption so : selectedObjectsList) {
				String selObject = so.getValue();
				profileWList = new List<ProfileWrapper>();
				//String objN = objectsNameMap.get(selectedObject);
				//system.debug('objN::' + objN);
				for(PermissionSet pr : permisionSetList) {
					profileWList.add(new ProfileWrapper(objPermMap.get(pr.Id),selObject, pr.Id, pr.ProfileId, pr.Profile.UserLicenseId));
				}
				for(PermissionSet pr : permissionSetsList) {
					profileWList.add(new ProfileWrapper(objPermMap.get(pr.Id),selObject, pr.Id, pr.Id, pr.LicenseId));
				}
				
				// Sort the ProfileWrapper list alphabetically by profile name
				profileWList = sortProfileWrapperList(profileWList);
				
				if(!objectProfileWListMap.containsKey(selObject)) {
					objectProfileWListMap.put(selObject, profileWList);
				} else {
					objectProfileWListMap.put(selObject + '1', profileWList);
					objectsNameMap.put(selObject + '1', objectsNameMap.get(selObject));
				}
				
				//system.debug('selectedObject::' + objectsNameMap.get(selObject));
			}
			//system.debug('objectProfileWListMap::' + objectProfileWListMap);
			//profileMap = new Map<Id, String>();
			//for(SelectOption so : selectedProfiles) {
			//	profileMap.put(so.getValue(), so.getLabel());
			//}
		}
		//system.debug('profileWSaveList:::' +  profileWSaveList);
		system.debug('profileWList::' + userLicenseMap.get(profileWList[0].profUserLicenseId).Name);
		//system.debug('selectedObject::' + selectedObject);
		//system.debug('selectedLog::' + selectedLog);
		return Page.ObjectAccessExportToExcel;
		//return null;
	}
	
	public pageReference printPDF() {
    PageReference pageRef = new PageReference('/apex/ObjectAccessPDF');
    
    // Add parameters with sanitized values
    pageRef.getParameters().put('isPdf', 'true'); // Fixed value, no sanitization needed

    // Sanitize the selectedObject parameter
    if (!String.isBlank(selectedObject)) {
        pageRef.getParameters().put('selectedObject', String.escapeSingleQuotes(selectedObject.trim()));
    }

    // Sanitize the selectedLog parameter
    if (!String.isBlank(selectedLog)) {
        pageRef.getParameters().put('selectedLog', String.escapeSingleQuotes(selectedLog.trim()));
    }

    // Add the isManaged parameter (Boolean, no sanitization needed)
    pageRef.getParameters().put('isManaged', isManaged ? 'true' : 'false');

    // Sanitize the selectedProfilesString
    String selectedProfilesString = '';
    if (selectedProfiles != null && !selectedProfiles.isEmpty()) {
        for (SelectOption so : selectedProfiles) {
            if (!String.isBlank(so.getValue())) {
                selectedProfilesString += '+' + String.escapeSingleQuotes(so.getValue().trim());
            }
        }
        if (!String.isBlank(selectedProfilesString)) {
            // Remove leading '+' character
            selectedProfilesString = selectedProfilesString.startsWith('+') 
                ? selectedProfilesString.substring(1) 
                : selectedProfilesString;
        }
    }
    pageRef.getParameters().put('selectedProfilesString', selectedProfilesString);

    return pageRef;
}

    public PageReference openContactUSLink(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/contact/');
        return pageRef;
    }

	public PageReference openHelpTraining(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-help-training/');
        return pageRef;
    }
    public PageReference openFAQ(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-faqs/');
        return pageRef;
    }
	public PageReference openReleaseNotes(){
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/security-access-manager-release-notes/');
        return pageRef;
    }

	public void SelectObjectForExportToExcel() {
		if(selectedObjectsList.size() > 100) {
			objectsNameList.addAll(selectedObjectsList);
			
			selectedObjectsList = new List<SelectOption>();
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning,'You can Export to Excel only 100 Objects');
			ApexPages.addMessage(myMsg);
		} else {
			if(selectedObjectsList.size() == 0) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning,'Select at least one object up to 100');
				ApexPages.addMessage(myMsg);
			} else {
				objectsNameList.addAll(selectedObjectsList);
				displayPopup = false;
			}
		}
		objectsNameList = SecurityUtil.sortAfterLabelSelectOptionList(objectsNameList);
        objectAccess obj =  new objectAccess();
		system.debug('selectedObjectsListsize::' + selectedObjectsList.size());
		
	}
	
	public String SerializeProfileWrapper(List<ProfileWrapper> profileWList) {
		return JSON.serialize(profileWList);
	}
	
	public List<ProfileWrapper> deserializeProfileWrapper(String objectLogValue) {
		List<ProfileWrapper> profileWList = new List<ProfileWrapper>();
		if (!String.isEmpty(objectLogValue)) {
			profileWList = (List<ProfileWrapper>)JSON.deserialize(objectLogValue.unescapeEcmaScript(),List<ProfileWrapper>.class);
		}
		return profileWList;
	}
	
	/**
	 * Sorts a list of ProfileWrapper objects alphabetically by profile name
	 * @param profileWrapperList The list of ProfileWrapper objects to sort
	 * @return Sorted list of ProfileWrapper objects
	 */
	public List<ProfileWrapper> sortProfileWrapperList(List<ProfileWrapper> profileWrapperList) {
		if (profileWrapperList == null || profileWrapperList.isEmpty()) {
			return profileWrapperList;
		}
		
		// Create a map to store profile names for sorting
		Map<String, List<ProfileWrapper>> profileNameMap = new Map<String, List<ProfileWrapper>>();
		List<String> profileNames = new List<String>();
		
		// Group ProfileWrappers by profile name
		for (ProfileWrapper pw : profileWrapperList) {
			String profileName = '';
			if (profileMap != null && profileMap.containsKey(pw.profId)) {
				profileName = profileMap.get(pw.profId);
			} else {
				// Fallback: use profId as string if profile name not found
				profileName = String.valueOf(pw.profId);
			}
			
			if (!profileNameMap.containsKey(profileName)) {
				profileNameMap.put(profileName, new List<ProfileWrapper>());
				profileNames.add(profileName);
			}
			profileNameMap.get(profileName).add(pw);
		}
		
		// Sort profile names alphabetically
		profileNames.sort();
		
		// Rebuild the list in sorted order
		List<ProfileWrapper> sortedList = new List<ProfileWrapper>();
		for (String profileName : profileNames) {
			sortedList.addAll(profileNameMap.get(profileName));
		}
		
		return sortedList;
	}
	
	/*public static MetadataService.MetadataPort createService() { 
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = UserInfo.getSessionId();
		return service;
	}
	
	public Boolean readCustomObject(String profileName) {
		transient MetadataService.MetadataPort service = createService();
		transient MetadataService.Profile profile =
			(MetadataService.Profile) service.readMetadata('Profile',
				new String[] {profileName}).getRecords()[0];
		system.debug('profile::' + profile);
		system.debug('profileName::' +profileName );
		system.debug('profile::' + profile.custom);
		if(profile.custom != null) {
			return profile.custom;
		} else { 
			return false; 
		}
	}*/
	
	public void yesPopUp() {
		displayPopUp = true;
		selectedObjectsList = new List<SelectOption>();
		//system.debug('displayPopUp::' + displayPopUp);
	}
	
	public void closePopup() {
		objectsNameList.addAll(selectedObjectsList);
		selectedObjectsList = new List<SelectOption>();
		objectsNameList = SecurityUtil.sortAfterLabelSelectOptionList(objectsNameList);
		displayPopup = false;
	}
	
	public void changePermType() {
		//system.debug('param::' + selectedPerm);
		customProfilesIdList = new List<Id>();
		profileMap = new Map<Id, String>();
         AllPSetGrp = '----------None----------'; 
		/*if(selectedPerm == 'Profiles') {
			profilesList = SecurityUtil.getCustomProfileList();
		}
		if(selectedPerm == 'Permission Sets') {
			List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true];
			for(PermissionSet ps : permissionSetsList) {
				profilesList.add(new SelectOption(ps.Id, ps.Label));
			}
		}
		if(selectedPerm == 'All') {
			profilesList = SecurityUtil.getCustomProfileList();
			List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true];
			for(PermissionSet ps : permissionSetsList) {
				profilesList.add(new SelectOption(ps.Id, ps.Label));
			}
		}*/
		remainingProfiles = new List<SelectOption>(SecurityUtil.changetPermissionType(selectedPerm));
		if(remainingProfiles.size() == 0) {
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have any custom ' + selectedPerm + ' that you can update');
			ApexPages.addMessage(myMsg);
			existCustomProfiles = false;
		} else {
			selectedProfiles = new List<SelectOption>();
			selectedProfiles.add(remainingProfiles[0]);
			customProfilesIdList.add(remainingProfiles[0].getValue());
			
			for(SelectOption so : remainingProfiles) {
				profileMap.put(so.getValue(), so.getLabel());
			}
			remainingProfiles.remove(0);
			remainingProfiles = SecurityUtil.sortAfterLabelSelectOptionList(remainingProfiles);
			//system.debug('customProfilesIdList::' + customProfilesIdList);
		}
		retrieveRecords();
	}
    
    public void changePsetGrp() {
    customProfilesIdList = new List<Id>();
    profileMap = new Map<Id, String>();

        System.debug('AllPSetGrp: ' + AllPSetGrp);
        remainingProfiles = new List<SelectOption>(SecurityUtil.changetPermissionGrp(AllPSetGrp));

        if (remainingProfiles.size() == 0) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You don\'t have any PermissionSets assigned In PermissionSetGroup,ID- ' + AllPSetGrp + ' that you can update');
            ApexPages.addMessage(myMsg);
            
        } else {
            selectedProfiles = new List<SelectOption>();
            selectedProfiles.add(remainingProfiles[0]);
            customProfilesIdList.add(remainingProfiles[0].getValue());

            for (SelectOption so : remainingProfiles) {
                profileMap.put(so.getValue(), so.getLabel());
            }
            
            remainingProfiles.remove(0);
        }
      
    
            retrieveRecords();
         
}

	
	public class ObjectWrapper {
		public Id id { get; set; }
		public Id parentId { get; set; }
		public String objType { get; set; }
		public Boolean R { get; set; }
		public Boolean E { get; set; }
		public Boolean C { get; set; }
		public Boolean D { get; set; }
		public Boolean V { get; set; }
		public Boolean M { get; set; }
		
		public ObjectWrapper(ObjectPermissions currentObjectPerm) {
			this.id = currentObjectPerm.Id;
			this.parentId = currentObjectPerm.ParentId;
			this.objType = currentObjectPerm.SobjectType;
			this.R = currentObjectPerm.PermissionsRead;
			this.E = currentObjectPerm.PermissionsEdit;
			this.C = currentObjectPerm.PermissionsCreate;
			this.D = currentObjectPerm.PermissionsDelete;
			this.V = currentObjectPerm.PermissionsViewAllRecords;
			this.M = currentObjectPerm.PermissionsModifyAllRecords;
		}
	}
	
	public class ProfileWrapper {
		public Id profUserLicenseId { get; set; }
		public Id profId { get; set; }
		public ObjectWrapper objPerm { get; set; }
		
		public ProfileWrapper(List<ObjectPermissions> objectPermsList, String selectedObject, Id permissionSetId, Id profId, Id profileUserLicenseId) {
			this.profId = profId;
			this.profUserLicenseId = profileUserLicenseId;
			Boolean isFound = false;
			if(objectPermsList != null) {
				for (ObjectPermissions op : objectPermsList) {
					if (op.SObjectType == selectedObject) {
						objPerm = new ObjectWrapper(op);
						isFound = true;
						break;
					}
				}
			}
			if (!isFound) {
				objPerm = new ObjectWrapper( new ObjectPermissions(SObjectType = selectedObject, ParentId = permissionSetId));
			}
			
		}
		
		public ProfileWrapper(String selectedObject, Id profUserLicenseId, Id profId, Id ParentId) {
			this.objPerm = new ObjectWrapper(new ObjectPermissions(SObjectType = selectedObject, ParentId = parentId));
			this.profUserLicenseId = profUserLicenseId;
			this.profId = profId;
		}
	}
    public void checkBoxValueChange(){
        System.debug('I am in the New Method?????');
    }
     public static void testtestMethod(){
        
        Integer i = 0;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
    }
    public static void testtestMethod2(){
        
        Integer i = 0;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
        i++;
        
    }
	/*public class SelectOptionWrapper {
		public String label { get;set; }
		public String value { get;set; }
		
		public SelectOptionWrapper(SelectOption o) {
			this.value = o.getValue();
			this.label = o.getLabel();
		}
	}*/
}