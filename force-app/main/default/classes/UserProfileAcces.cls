public with sharing class UserProfileAcces {
    
 
     public Boolean hasAccess { get; set; }
          
	public static List<SelectOption> profilesList { get; set; }
	public List<SelectOption> remainingProfileList { get; set; }
	public List<SelectOption> selectedProfileList { get; set; }
	public List<Id> selectedProfileIdList { get; set; }
	public List<String> fieldNameList{ get; set; }
    public List<String> fieldNameList2{ get; set; }
    public List<String> fieldNameUneditableList { get; set; }
	public Map<String, List<String>> fieldNameLabelMap { get; set; }
    public Map<String, List<String>> fieldNameUneditableMap { get; set; }
	public String selectedPerm { get; set; }
	public Map<Id, sObject> profileMap { get; set; }
    public String AllPSetGrp { get; set; }
    public Map<Id, sObject> profileMap2 { get; set; }
	public String xmlheader { get; set; }
	public String endfile { get; set; }
	public String currentLanguage { get; set; }
	public Organization org { get; set; }
	public String exportUser { get; set; }
	public String indAcrossCell { get; set; }
	public Boolean OrgIsAccessible { get; set; }
    public  Boolean isField1 { get; set; }
    public Boolean isGO { get; set; }
    public integer index { get; set; }
	public List<SelectOption> profList { get; set; }
	public List<SelectOption> selectedProfileExcel { get; set; }
	public Boolean displayPopup { get; set; }
	public Boolean showFields { get; set; }
    public List<EntityParticle> entityParticles { get; set; }
    
    //now
     public Map<Id, Map<String, Object>> profileMapForUpdate { get; set; }
    public List<Profile> profiles { get; set; }
   
      // Method to check if the feature is enabled for the user
    public Boolean getPaidFeatureAccess() {
        
         try {
            // Attempt to check if the feature is enabled for the user
             // return FeatureManagement.checkPackageBooleanValue('SystemPermissionPaidAccess');
           //for data dictionary
            return true; 
        } catch (System.NoDataFoundException e) {
            // Log the exception for debugging purposes
            System.debug('Feature parameter not found: ' + e.getMessage());
            // Handle the exception gracefully, return false to indicate no access
            return true;
        } catch (Exception e) {
            // Catch any other exceptions that might occur
            System.debug('An unexpected error occurred: ' + e.getMessage());
            // Handle the exception gracefully, return false to indicate no access
            return true;
        }
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
   //constructor
	public UserProfileAcces() {
          hasAccess = getPaidFeatureAccess();
		selectedPerm = 'Organization Profiles & Permission Sets';
		displayPopup = false;
		OrgIsAccessible = true;
        index = 0;
        isGO = false;
       isField1 = false; 
		selectedProfileExcel = new List<SelectOption>();
		if(!Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()) {
			OrgIsAccessible = false;
		} else {
			String orgId = UserInfo.getOrganizationId();
			org = [SELECT Id , Name, NamespacePrefix FROM Organization WHERE ID = :orgID];
		}
		xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
		endfile = '</Workbook>';
		currentLanguage = 'US';
		if(Schema.getGlobalDescribe().get('Profile').getDescribe().isAccessible()) {
			profilesList = new List<SelectOption>(SecurityUtil.getAllOrganizationProfilesList());
			profilesList.addAll(SecurityUtil.getAllOrganizationPermissionSetList());
			profilesList = sortAfterLabelSelectOptionList(profilesList);
			fieldNameList = new List<String>();
            fieldNameList2 = new List<String>();
            fieldNameUneditableList = new List<String>();
            fieldNameUneditableMap = new Map<string,List<string>>();
			fieldNameLabelMap = new Map<String, List<String>>();
			List<EntityParticle> profileFieldList = [SELECT DataType, IsCalculated, IsCreatable, IsUpdatable, IsPermissionable, 
														QualifiedApiName, DeveloperName, Label, NamespacePrefix
														FROM EntityParticle WHERE EntityDefinition.QualifiedApiName = 'Profile' ];
			List<EntityParticle> permSetFieldList = [SELECT DataType, IsCalculated, IsCreatable, IsUpdatable, IsPermissionable, 
														QualifiedApiName, DeveloperName, Label, NamespacePrefix
														FROM EntityParticle WHERE EntityDefinition.QualifiedApiName = 'PermissionSet' ];
			// Build sets of field names for comparison
			Set<String> profileFieldNames = new Set<String>();
			Set<String> permSetFieldNames = new Set<String>();
			
			for(EntityParticle profileField : profileFieldList) {
				profileFieldNames.add(profileField.QualifiedApiName);
			}
			
			for(EntityParticle permSetField : permSetFieldList) {
				permSetFieldNames.add(permSetField.QualifiedApiName);
			}
			
			// Exclude fields that don't exist on both objects
			Set<String> fieldExcluded = new Set<String>();
			// Add known problematic fields
			fieldExcluded.add('PermissionsAccessDisputePrompts');
			
			for(EntityParticle profileField : profileFieldList) {
				if(!permSetFieldNames.contains(profileField.QualifiedApiName)){
					 fieldExcluded.add(profileField.QualifiedApiName);
					 system.debug('excluded from Profile (not in PermissionSet): ' + profileField.QualifiedApiName);
				}
			}
			
			for(EntityParticle permSetField : permSetFieldList) {
				if(!profileFieldNames.contains(permSetField.QualifiedApiName)){
					 fieldExcluded.add(permSetField.QualifiedApiName);
					 system.debug('excluded from PermissionSet (not in Profile): ' + permSetField.QualifiedApiName);
				}
			}
			
			for(EntityParticle profileField : profileFieldList) {
				if(!fieldExcluded.contains(profileField.QualifiedApiName) ){
					fieldNameList.add(profileField.QualifiedApiName);
					fieldNameLabelMap.put(profileField.QualifiedApiName, new List<String>());
					fieldNameLabelMap.get(profileField.QualifiedApiName).add(profileField.Label);
					if(profileField.DataType.containsIgnoreCase('boolean')){
						fieldNameLabelMap.get(profileField.QualifiedApiName).add('boolean');
					}else {
						fieldNameLabelMap.get(profileField.QualifiedApiName).add('other');
					}
					system.debug('fieldNameList::' + fieldNameList);
                    system.debug('fieldNameLabelMap::' + fieldNameLabelMap);
                    
				}
                 
                
			}
           fieldNameList.sort();
            //@Roopal
         
            for(EntityParticle profileField : profileFieldList) {
                if(!fieldExcluded.contains(profileField.QualifiedApiName) &&  profileField.IsPermissionable == false && profileField.IsCreatable == false && profileField.IsUpdatable == false ){ //profileField.DataType.containsIgnoreCase('boolean') && profileField.IsCreatable == false 
                    fieldNameUneditableList.add(profileField.QualifiedApiName);
                    fieldNameUneditableMap.put(profileField.QualifiedApiName, new List<String>());
                    fieldNameUneditableMap.get(profileField.QualifiedApiName).add(profileField.Label);
                    if(profileField.DataType.containsIgnoreCase('boolean')){
						fieldNameUneditableMap.get(profileField.QualifiedApiName).add('boolean');
					}else {
						fieldNameUneditableMap.get(profileField.QualifiedApiName).add('other');
					}
                }
                	system.debug('profileField2::' + profileField);
                 
                system.debug('fieldNameUneditableMap='+fieldNameUneditableMap);
                index++;
            }
             fieldNameList.sort();
            // Create a deep copy of fieldNameList for fieldNameList2
            fieldNameList2 = new List<String>();
            fieldNameList2.addAll(fieldNameList);
         system.debug('fieldNameListsort'+fieldNameList2);

	
            fieldNameList2.sort();
          
            system.debug('fieldNameListsort'+fieldNameList);
            
            fieldNameUneditableList.sort();
            system.debug('fieldNameUneditableListsort'+fieldNameUneditableList);
			createSelectList();
			retrieveRecords(); 
            retrieveRecordsUneditable();
		}
	}
    
	public List<SelectOption> getPermissionType() {
        isField1 = false;
		List<SelectOption> options = new List<SelectOption>();
		options.addAll(SecurityUtil.getPermissionType());
		return options;
	}
    public List<SelectOption> getPermissionGrpType() {
          isField1 = false;
		List<SelectOption> options = new List<SelectOption>();
		options.addAll( SecurityUtil.getPermissionGrpType());
		return options;
	}
	
    
    
     public static MetadataService.MetadataPort createService() { 
        system.debug('TestingProfiles');  
        system.debug('debugg createService');
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
      // service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';
        service.timeout_x = 60000;
        return service;
    }
    
	 
	
   /* public static void updatePermissions() {
      
      string profileName = 'admin';
    List<MetadataService.UpsertResult> results = new List<MetadataService.UpsertResult>();
    MetadataService.MetadataPort service = createService();
    
     
        try {
            // Retrieve existing metadata
            MetadataService.Profile existingProfile = (MetadataService.Profile) service.readMetadata('Profile', new String[] { profileName }).getRecords()[0];
            system.debug('existingProfile--'+existingProfile.customPermissions);
            system.debug('custom--'+existingProfile.custom);
            system.debug('userPermissions--'+existingProfile.userPermissions);
            system.debug('fieldPermissions--'+existingProfile.fieldPermissions);
            
            if (existingProfile != null) {
                MetadataService.Profile customProfile = new MetadataService.Profile();
                 
                results.addAll(service.upsertMetadata(new MetadataService.Metadata[] { customProfile }));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error retrieving: ' + profileName));
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating: ' + profileName + '. Message: ' + e.getMessage()));
        }
    
 

    }
    
    
    
     public static void getProfileBooleanFields() {
         string profileName = 'admin';
        MetadataService.MetadataPort service = createService();
        MetadataService.Profile existingProfile = (MetadataService.Profile) service.readMetadata('Profile', new String[] { profileName }).getRecords()[0];
        
        Map<String, Boolean> bCustomPermissions = new Map<String, Boolean>();
          Map<String, Boolean> bUserPermission = new Map<String, Boolean>();
          Map<String, Boolean> bFieldLevelSecurity = new Map<String, Boolean>();
        
        // Check for boolean fields in customPermissions
        for (MetadataService.ProfileCustomPermissions perm : existingProfile.customPermissions) {
               bCustomPermissions.put('customPermissions.' + perm.name, perm.enabled);
        }
        
        // Check for boolean fields in userPermissions
        for (MetadataService.ProfileUserPermission perm : existingProfile.userPermissions) {
            if (perm.enabled) {
                bUserPermission.put('userPermissions.enabled', perm.enabled);
            }
        }
        
        // Check for boolean fields in fieldPermissions
        for (MetadataService.ProfileFieldLevelSecurity fieldPerm : existingProfile.fieldPermissions) {
            if (fieldPerm.readable) {
                bFieldLevelSecurity.put('fieldPermissions.readable', fieldPerm.readable);
            }
            if (fieldPerm.editable) {
                bFieldLevelSecurity.put('fieldPermissions.editable', fieldPerm.editable);
            }
        }
        
        system.debug('bCustomPermissions Fields: ' + bCustomPermissions);
         system.debug('bUserPermission Fields: ' + bUserPermission);
         system.debug('bFieldLevelSecurity Fields: ' + bFieldLevelSecurity);
    }
    */
	public List<SelectOption> sortAfterLabelSelectOptionList(List<SelectOption> source) {
		List<String> sortList = new  List<String>();
		List<SelectOption> options = new List<SelectOption>();
		Map<String, String> valueLabelMap = new Map<String, String>();
		for(SelectOption so: source) {
			sortList.add(so.getLabel());
			valueLabelMap.put(so.getLabel(), so.getValue());
		}
		sortList.sort();
		for(String item : sortList) {
			options.add(new  SelectOption(valueLabelMap.get(item), item));
		}
		return options;
	}
    
	public void createSelectList() {
		selectedProfileList = new List<SelectOption>();
		selectedProfileIdList = new List<Id>();
		if(profilesList.size() > 1) {
			selectedProfileIdList.add((Id)profilesList[0].getValue());
			selectedProfileIdList.add((Id)profilesList[1].getValue());
			selectedProfileList.add(new SelectOption(profilesList[0].getValue(), profilesList[0].getLabel()));
			selectedProfileList.add(new SelectOption(profilesList[1].getValue(), profilesList[1].getLabel()));
			profilesList.remove(0);
			profilesList.remove(0);
		} else { 
			if(profilesList.size() == 1) { 
				selectedProfileIdList.add((Id)profilesList[0].getValue());
				selectedProfileList.add(new SelectOption(profilesList[0].getValue(), profilesList[0].getLabel()));
				profilesList.remove(0);
			}
		}
		system.debug('profilesList::' + profilesList+'selectedProfileList'+selectedProfileList);
		remainingProfileList = new List<SelectOption>();
		remainingProfileList = sortAfterLabelSelectOptionList(profilesList);
		system.debug('remainingProfileList::' + remainingProfileList);
		profilesList = new List<SelectOption>();
	}
	
    public void UnEditToggel() {
         system.debug('isField1'+ isField1);
       // retrieveRecordsUneditable();
    }
    
    public void retrieveRecordsUneditable(){
		profileMap2 = new Map<Id, sObject>();
		String query = 'SELECT';
		for(String profileField : fieldNameUneditableList) {
			query += ' ' + profileField + ',';
			
		}
		String permissionQuery = query;
		Set<Id> profileIdSet = new Set<Id>(selectedProfileIdList);
		query = query.removeEnd(',') + ' FROM Profile Where Id IN :profileIdSet';
		system.debug('query::' + query);
		List<Profile> profileList = Database.Query(query);
		system.debug('profileList::' + profileList);
		for(Profile pr : profileList){
			if(!profileMap2.containsKey(pr.id)) {
				profileMap2.put(pr.id, (Profile)pr);
			}
		}
  
        system.debug('profileMap2=='+profileMap2);
		permissionQuery = permissionQuery.removeEnd(',') + ' FROM PermissionSet Where Id IN :profileIdSet';
		List<PermissionSet> permissionSetList = Database.Query(permissionQuery);
		for(PermissionSet ps : permissionSetList){
			if(!profileMap2.containsKey(ps.id)) {
				profileMap2.put(ps.id, (PermissionSet)ps);
			}
		}
         system.debug('profileMap2=='+profileMap2);
	}
	
    public void Go(){
        isGO = true ;
        isField1 = False;
        selectedProfileIdList = new List<Id>();
        system.debug('selectedProfileList::' + selectedProfileList);
        Boolean isMoreProfiles = false;
        for (SelectOption so : selectedProfileList) {
            if(!isMoreProfiles) {
                selectedProfileIdList.add(so.getValue());
                if(selectedProfileIdList.size() > 10) {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'Select only 10 profiles / permissionSet');
                    ApexPages.addMessage(myMsg);
                    Id profId = selectedProfileIdList.remove(10);
                    isMoreProfiles = true;
                    remainingProfileList.add(new SelectOption(profId, so.getLabel()));
                }
            }else {
                remainingProfileList.add(new SelectOption(so.getValue(), so.getLabel()));
            }
        }
        if(isMoreProfiles){
            List<SelectOption> profileTempList = new List<SelectOption>();
            profileTempList.addAll(selectedProfileList);
            selectedProfileList = new List<SelectOption>();
            Integer i = 0;
            for (SelectOption so : profileTempList) {
                selectedProfileList.add(new SelectOption(so.getValue(), so.getLabel()));
                i++;
                if(i > 9) break;
            }
        }
        remainingProfileList = sortAfterLabelSelectOptionList(remainingProfileList);
        retrieveRecords();
        retrieveRecordsUneditable(); 
    }
    
    
    public void retrieveRecords(){
        isField1 = true;
        profileMap = new Map<Id, sObject>();
        for (Integer i = (fieldNameList2.size()-1) ; i>= 0 ; i--)
        {
            if(fieldNameList2.contains('CreatedById')){
                Integer index =fieldNameList2.indexOf('CreatedById');
                fieldNameList2.remove(index);
            }
            if(fieldNameList2.contains('CreatedDate')){
                Integer index =fieldNameList2.indexOf('CreatedDate');
                fieldNameList2.remove(index);
            }
            if(fieldNameList2.contains('Id')){
                Integer index =fieldNameList2.indexOf('Id');
                fieldNameList2.remove(index);
            }
            if(fieldNameList2.contains('LastModifiedById')){
                Integer index =fieldNameList2.indexOf('LastModifiedById');
                fieldNameList2.remove(index);
            }
            if(fieldNameList2.contains('SystemModstamp')){
                Integer index =fieldNameList2.indexOf('SystemModstamp');
                fieldNameList2.remove(index);
            }
            if(fieldNameList2.contains('LastModifiedDate')){
                Integer index =fieldNameList2.indexOf('LastModifiedDate');
                fieldNameList2.remove(index);
            }
        } 
        String query = 'SELECT';
        for(String profileField : fieldNameList2) {
            query += ' ' + profileField + ',';
            
        }
        String permissionQuery = query;
        Set<Id> profileIdSet = new Set<Id>(selectedProfileIdList);
        query = query.removeEnd(',') + ' FROM Profile Where Id IN :profileIdSet';
        system.debug('query::' + query);
        List<Profile> profileList = Database.Query(query);
        system.debug('profileList::' + profileList);
        for(Profile pr : profileList){
            if(!profileMap.containsKey(pr.id)) {
                profileMap.put(pr.id, (Profile)pr);
            }
        }
        system.debug('profileMap=='+profileMap);
        permissionQuery = permissionQuery.removeEnd(',') + ' FROM PermissionSet Where Id IN :profileIdSet';
        List<PermissionSet> permissionSetList = Database.Query(permissionQuery);
        for(PermissionSet ps : permissionSetList){
            if(!profileMap.containsKey(ps.id)) {
                profileMap.put(ps.id, (PermissionSet)ps);
            }
        }
        system.debug('profileMap=='+profileMap);
    }
    
    
	public void changePermType() {
          AllPSetGrp = '----------None----------'; 
		profilesList = new List<SelectOption>();
        isField1 = false;
		 
		profilesList = new List<SelectOption>(SecurityUtil.changetPermissionType(selectedPerm));
		createSelectList();
		retrieveRecords();
          retrieveRecordsUneditable();
	}
	
    public void changePsetGrp() {
        profilesList = new List<SelectOption>();
        isField1 = false;
        
        
        profilesList = new List<SelectOption>(SecurityUtil.changetPermissionGrp(AllPSetGrp));
        createSelectList();
        retrieveRecords();
        retrieveRecordsUneditable();
    }
	 
  
	public PageReference ExportToExcel() {
        isField1 = true;
		indAcrossCell = String.valueOf(selectedProfileIdList.size());
		system.debug('indAcrossCell::' + indAcrossCell);
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
		selectedProfileIdList = new List<Id>();
		if(selectedProfileExcel.size() > 0) {
			for(SelectOption so : selectedProfileExcel) {
				selectedProfileIdList.add((Id)so.getValue());
			}
		} else {
			for(SelectOption so : selectedProfileList) {
				selectedProfileIdList.add((Id)so.getValue());
			}
		}
		retrieveRecords();
		selectedProfileList = new List<SelectOption>();
		return Page.UserProfileAccesExportToExcel;
	}
	
	public void yesPopUp() {
		displayPopUp = true;
		profList = new List<SelectOption>();
		for(SelectOption so : remainingProfileList) {
			profList.add(new SelectOption(so.getValue(), so.GetLabel()));
			if(profList.size() > 998 -  selectedProfileList.size()) break;
		}
		profList = sortAfterLabelSelectOptionList(profList);
		selectedProfileExcel = new List<SelectOption>();
		for(SelectOption so : selectedProfileList) {
			selectedProfileExcel.add(new SelectOption(so.getValue(), so.GetLabel()));
		}
		//system.debug('displayPopUp::' + displayPopUp);
	}
	
	public void closePopup() {
		//objectsNameList.addAll(selectedObjectsList);
		selectedProfileExcel = new List<SelectOption>();
		profList = new List<SelectOption>();
		displayPopup = false;
	}
	
	public void SelectProfilesForExportToExcel() {
	   
		if(selectedProfileExcel.size() > 1000) {
			profList.addAll(selectedProfileExcel);
			
			selectedProfileExcel = new List<SelectOption>();
			ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning,'You can Export to Excel only 1000 Profiles');
			ApexPages.addMessage(myMsg);
		} else {
			if(selectedProfileExcel.size() == 0) {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning,'Select at least one profile up to 1000');
				ApexPages.addMessage(myMsg);
			} else {
				profList = new List<SelectOption>();
				displayPopup = false;
			}
		}
	}
	 
}