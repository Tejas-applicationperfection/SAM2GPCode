public with sharing class GenerateProfileXML {
	/*public Map<Id, String> profileXMLMap { get; set; }
	public List<Id> selectedProfileIdList { get; set; }
	public Map<Id, String> profileNameMap { get; set; }
	public String selectedPerm { get; set; }
	public List<SelectOption> selectedProfiles { get; set; }
	public List<SelectOption> remainingProfiles { get; set; }
	public List<SelectOption> profilesList { get; set; }
	public String ZipData { get; set; }
	public String selectedProfilesId { get; set; }
	
	public GenerateProfileXML() {
		selectedProfiles = new List<SelectOption>();
		profilesList = new List<SelectOption>(sortAfterLabelSelectOptionList(SecurityUtil.getAllProfilesList()));
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true];
		for(PermissionSet ps : permissionSetsList) {
			 profilesList.add(new SelectOption(ps.ID, ps.Label));
		}
		createSelectList();
	}
	
	public List<SelectOption> getPermissionType() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('All','All'));
		options.add(new SelectOption('Profiles','Profiles'));
		options.add(new SelectOption('Permission Sets','Permission Sets'));
		return options;
	}
	
	public void changeType() {
		profilesList = new List<SelectOption>();
		//system.debug('param::' + selectedPerm );
		if(selectedPerm == 'Profiles') {
			profilesList = new List<SelectOption>(sortAfterLabelSelectOptionList(SecurityUtil.getAllProfilesList()));
		}
		if(selectedPerm == 'Permission Sets') {
			profilesList = new List<SelectOption>();
			List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true];
			for(PermissionSet ps : permissionSetsList) {
				 profilesList.add(new SelectOption(ps.ID, ps.Label));
			}
		}
		if(selectedPerm == 'All') {
			profilesList = new List<SelectOption>(sortAfterLabelSelectOptionList(SecurityUtil.getAllProfilesList()));
			List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true];
			for(PermissionSet ps : permissionSetsList) {
				 profilesList.add(new SelectOption(ps.ID, ps.Label));
			}
		}
		if(profilesList.size() > 0) {
			profilesList = sortAfterLabelSelectOptionList(profilesList);
		}
		selectedProfiles = new List<SelectOption>();
		profilesList = sortAfterLabelSelectOptionList(profilesList);
		selectedProfiles = new List<SelectOption>();
		createSelectList();
	}
	
	public void createSelectList() {
		selectedProfiles = new List<SelectOption>();
		
		selectedProfileIdList = new List<Id>();
		profileNameMap = new Map<Id, String>();
		if(profilesList.size() > 1) {
			selectedProfileIdList.add((Id)profilesList[0].getValue());
			selectedProfileIdList.add((Id)profilesList[1].getValue());
			profileNameMap.put((Id)profilesList[0].getValue(), profilesList[0].getLabel());
			profileNameMap.put((Id)profilesList[1].getValue(), profilesList[1].getLabel());
			profilesList.remove(0);
			profilesList.remove(0);
		} else { 
			if(profilesList.size() == 1) { 
				selectedProfileIdList.add((Id)profilesList[0].getValue());
				profileNameMap.put((Id)profilesList[0].getValue(), profilesList[0].getLabel()); 
				profilesList.remove(0);
			}
		}
		//system.debug('selectedProfileIdList::' + selectedProfileIdList);
		for (Id profId : selectedProfileIdList) {
			//system.debug('profileNameMap.get(profId)::' + profileNameMap.containsKey(profId));
			selectedProfiles.add(new SelectOption(profId, profileNameMap.get(profId)));
		}

		remainingProfiles = new List<SelectOption>();
		remainingProfiles = sortAfterLabelSelectOptionList(profilesList);
		//profilesList = new List<SelectOption>();
		SelectProfile();
	}
	
	public void SelectProfile() {
		selectedProfilesId = '';
		//system.debug('selectedProfiles::' + selectedProfiles.size());
		
		for(SelectOption so : selectedProfiles) {
			selectedProfilesId += so.getValue() + '//';
			profileNameMap.put(so.getValue(), so.getLabel()); 
		}
		selectedProfilesId = selectedProfilesId.removeEnd('//');
		//system.debug('selectedProfilesId::' + selectedProfilesId);
		if(selectedProfiles.size() > 25) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning, 'You can select up to 25 profiles'));
			createSelectList();
		}
	}
	
	 
	public void ExportToXML() {
		//ProfileXml();
		
	}
	
	public PageReference deployZip() {
		//system.debug('ZipData::' + ZipData);
		return null;
	}
	
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
	
	@RemoteAction
	public static Map<String, String> getXMLFiles(String selectedProfilesId) {
		//system.debug('selectedProfilesId::' + selectedProfilesId);
		List<String> selectedProfileIdList = new List<String>();
		selectedProfileIdList = selectedProfilesId.split('//');
		//system.debug('selectedProfileIdList::' + selectedProfileIdList);
		Map<String, String> profileXMLMap = new Map<String, String>();
		
		
		Map<String, String> profileNameMap = new Map<String, String>();
		Map<String, List<String>> nameMap = new Map<String, List<String>>();
		nameMap.put('Profile', new List<String>());
		nameMap.put('PermissionSet', new List<String>());
		List<PermissionSet> permSetList = [SELECT Id, ProfileId, Profile.Name, Name FROM PermissionSet WHERE ProfileId = :selectedProfileIdList OR Id = :selectedProfileIdList];
		Map<Id, Set<Id>> profileIdMap = new Map<Id, Set<Id>>();
		for(PermissionSet permSet : permSetList) {
			//system.debug('permSet::' + permSet.Name);
			//system.debug('permSet::' + permSet.Profile.Name);
			
			if(permSet.Profile.Name == null) {
				if(!profileIdMap.containsKey(permSet.ID)) {
					profileIdMap.put(permSet.ID, new Set<Id>());
				}
				profileIdMap.get(permSet.ID).add(permSet.Id);
				profileNameMap.put(permset.Id, 'package/permissionsets/' + permset.Name + '.permissionset');
				nameMap.get('PermissionSet').add(permset.Name);
			} else {
				if(!profileIdMap.containsKey(permSet.profileID)) {
					profileIdMap.put(permSet.profileID, new Set<Id>());
				}
				profileIdMap.get(permSet.profileID).add(permSet.Id);
				//system.debug('Profile:::');
				nameMap.get('Profile').add(permset.Profile.Name);
				profileNameMap.put(permset.ProfileId, 'package/profiles/' + permset.Profile.Name + '.profile');
			}
		}
		nameMap.get('PermissionSet').sort();
		nameMap.get('Profile').sort();
		String packageXml = '<?xml version="1.0" encoding="UTF-8"?>' + '\n';
			packageXml += '<Package xmlns="http://soap.sforce.com/2006/04/metadata">' + '\n';
			packageXml += '\t' + '<types>' + '\n';
			for(String profileName : nameMap.get('PermissionSet')) {
				packageXml += '\t' + '\t' + '<members>';
				packageXml += profileName;
				packageXml += '</members>' + '\n';
			}
			packageXml += '\t' + '\t' + '<name>PermissionSet</name>' + '\n';
			packageXml += '\t' + '</types>' + '\n';
			packageXml += '\t' + '<types>' + '\n';
			for(String profileName : nameMap.get('Profile')) {
				packageXml += '\t' + '\t' + '<members>';
				packageXml += profileName;
				packageXml += '</members>' + '\n';
			}
			
			packageXml += '\t' + '\t' + '<name>Profile</name>' + '\n';
			packageXml += '\t' + '</types>' + '\n';
			packageXml += '\t' + '<version>45.0</version>' + '\n';
			packageXml += '</Package>' + '\n';
		profileXMLMap.put('package', EncodingUtil.base64Encode(Blob.valueOf(packageXml)));
		for(Id profileId : selectedProfileIdList){
			String profileXml = '<?xml version="1.0" encoding="UTF-8"?>';
			profileXml += '<Profile xmlns="http://soap.sforce.com/2006/04/metadata">';
			Integer index = 0;
			Set<Id> permSetIdSet = new Set<Id>(profileIdMap.get(profileId));
			
			for(ObjectPermissions objPerm : [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM Objectpermissions WHERE ParentId = :permSetIdSet]) {
				profileXml += '\t' + '<objectPermissions>' + '\n';
					profileXml += '\t' + '\t' + '<allowRead>' + objPerm.PermissionsRead + '</allowRead>' + '\n';
					profileXml += '\t' + '\t' + '<allowDelete>' + objPerm.PermissionsDelete + '</allowDelete>' + '\n';
					profileXml += '\t' + '\t' + '<allowEdit>' + objPerm.PermissionsEdit + '</allowEdit>' + '\n';
					profileXml += '\t' + '\t' + '<allowCreate>' + objPerm.PermissionsCreate + '</allowCreate>' + '\n';
					profileXml += '\t' + '\t' + '<modifyAllRecords>' + objPerm.PermissionsModifyAllRecords + '</modifyAllRecords>' + '\n';
					profileXml += '\t' + '\t' + '<viewAllRecords>' + objPerm.PermissionsViewAllRecords + '</viewAllRecords>' + '\n';
					profileXml += '\t' + '\t' + '<object>' + objPerm.SobjectType + '</object>' + '\n';
				profileXml += '\t' + '</objectPermissions>' + '\n';
			}
			for(FieldPermissions fieldPerm : [SELECT ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE parentId = :permSetIdSet]) {
				profileXml += '\t' + '<fieldPermissions>' + '\n';
					profileXml += '\t' + '\t' + '<readable>' + fieldPerm.PermissionsRead + '</readable>' + '\n';
					profileXml += '\t' + '\t' + '<editable>' + fieldPerm.PermissionsEdit + '</editable>' + '\n';
					profileXml += '\t' + '\t' + '<field>' + fieldPerm.Field + '</field>' + '\n';
				profileXml += '\t' + '</fieldPermissions>' + '\n';
			}
			profileXml += '</Profile>' + '\n';
			//system.debug('profileNameMap.get(profileId):::' + profileNameMap.containsKey(profileId));
			profileXMLMap.put(profileNameMap.get(profileId), EncodingUtil.base64Encode(Blob.valueOf(profileXml)));
			//EncodingUtil.urlEncode(profileXml, 'UTF-8'));
		}
		return profileXMLMap;
	}*/
}