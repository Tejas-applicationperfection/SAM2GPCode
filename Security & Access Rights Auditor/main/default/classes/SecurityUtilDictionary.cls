public with sharing class SecurityUtilDictionary {


	public static Set<String> acceptedSObjectTypes {
		get {
			if (acceptedSObjectTypes == null) {
				return getSObjectTypes();
			}
			return acceptedSObjectTypes;
		}
	}
	
	public static Set<String> getSObjectTypes() {
		Set<String> objTypes = new Set<String>();
			
		Schema.DescribeFieldResult fieldResult = ObjectPermissions.SObjectType.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		
		for( Schema.PicklistEntry f : ple) {
			objTypes.add(f.getValue());
		}	   
		return objTypes;
	}
		
	public static List<SelectOption> getObjectsList(String namespacePrefix, Boolean isManaged){
		
		Set<String> objTypes = new Set<String>();

		List<Schema.PicklistEntry> ple = ObjectPermissions.SObjectType.getDescribe().getPicklistValues();
		
		for(Schema.PicklistEntry f : ple) {
			objTypes.add(f.getValue());
		}
        //if any object is missing on the object access and object and fields then you can add it here
		objTypes.add('Task');
		objTypes.add('Event');
		objTypes.add('OpportunityLineItem');
		objTypes.add('QuoteLineItem');
		objTypes.add('WorkOrderLineItem');
        objTypes.add('OrderItem');
        objTypes.add('WorkOrder');
		List<EntityDefinition> objList = [SELECT QualifiedApiName, DeveloperName, MasterLabel, Label, PluralLabel, NamespacePrefix, IsCustomizable, IsCustomSetting, IsQueryable
												FROM EntityDefinition 
												where IsQueryable = true AND IsCustomSetting = false AND (NOT QualifiedApiName like '%__mdt') 
												AND (NOT Label like '%: %') AND IsCustomizable = true
												order by NamespacePrefix, QualifiedApiName nulls last limit 2000];
		
		
		/*if (objList.size() == 2000) {
			Set<String> objApiNames = new Set<String>();
			for (EntityDefinition e : objList) {
				objApiNames.add(e.QualifiedApiName);
			}
			//perform de query again in case there are more than 2000 records
			List<EntityDefinition> objListInitial = new List<EntityDefinition>();
			objListInitial = [SELECT QualifiedApiName, DeveloperName, MasterLabel, Label, PluralLabel, NamespacePrefix, DeploymentStatus, IsCustomizable, IsCustomSetting, IsQueryable, IsApexTriggerable  FROM EntityDefinition where IsQueryable = true AND IsCustomSetting = false AND (NOT QualifiedApiName like '%__mdt') AND (NOT QualifiedApiName IN :objApiNames) AND (NOT Label like '%: %') order by QualifiedApiName limit 2000];
			objList.addAll(objListInitial);
		}*/
		System.debug('objList:' + objList.size());
		
		List<SelectOption> options = new List<SelectOption>();
		Integer i = 0;
		for (EntityDefinition e : objList) {
			//if (i >= 900) break;
			if(objTypes.contains(e.QualifiedApiName)) {
				if ((!isManaged && String.isEmpty(e.NamespacePrefix)) ||
					(isManaged && e.NamespacePrefix != null)) 
				{
					options.add(new SelectOption(e.QualifiedApiName, e.Label));
					i++;
				}
			}
		}
		
		
		/*Map<String,String> objMap = new Map<String,String>();
		List<SelectOption> options = new List<SelectOption>();
		String namespacePrefix = namespacePrefix == null ?  '': namespacePrefix;
		Integer i = 0;
		for (EntityDefinition e : objList) {
			if(objTypes.contains(e.QualifiedApiName)) {
				//if (i >= 900) break;
				String objName = e.QualifiedApiName;
				objName = objName.removeEndIgnoreCase('__c');
				objName = objName.removeStartIgnoreCase(NamespacePrefix + '__');
				if(!isManaged && (e.NamespacePrefix == null || e.NamespacePrefix == '') && !objName.containsIgnoreCase('__tag')) {
					options.add(new SelectOption(e.QualifiedApiName, e.Label));
					i++;
				}
				if(isManaged && e.NamespacePrefix != null && e.NamespacePrefix != '' && !objName.containsIgnoreCase('__tag')) {
					options.add(new SelectOption(e.QualifiedApiName, e.Label));
					i++;
				}
			}
		}*/
		
		System.debug('options.size:::' + options.size());
		System.debug('4. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
		
		return options;
	}
	
	public static List<String> getObjectsAPIList()
	{
		List<Schema.SObjectType> gd = Schema.getGlobalDescribe().Values();
		List<String> options = new List<String>();
		
		for(Schema.SObjectType f : gd)
		{
			options.add(f.getDescribe().getName());
		}
		options.sort();
		return options;
	}
	
	
	public static List<SelectOption> getCustomProfileList() {
		if(!Schema.getGlobalDescribe().get('Profile').getDescribe().isAccessible()) {
			return null;
		}
		if(!Schema.getGlobalDescribe().get('Account').getDescribe().isAccessible()) {
			return null;
		}
		/*String orgId = UserInfo.getOrganizationId();
		Organization org = [SELECT Id , CreatedDate FROM Organization WHERE ID = :orgID]; 
		Map<Id, Profile> customProfiles = new Map<ID, Profile>([SELECT Id, Name, CreatedDate, UserType FROM Profile WHERE CreatedDate > :org.CreatedDate 
																AND Name NOT IN ('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User', 'Gold Partner User')
																AND UserLicense.Name != 'Analytics Cloud Integration User']);
		Set<Id> customProfileIds = customProfiles != null ? customProfiles.KeySet() : new Set<Id>();
		List<PermissionSet> permissionSetList = [SELECT id, Profile.Id, Profile.Name FROM PermissionSet WHERE IsOwnedByProfile = true AND Profile.Id IN :customProfileIds];
		//Set<String> customProfilesNameSet = new Set<String>();
		List<ObjectPermissions> objPermissionList = new List<ObjectPermissions>();
		for(PermissionSet ps : permissionSetList) {
			objPermissionList.add(new ObjectPermissions(
				ParentId = ps.Id, 
				SobjectType = 'Account',
				PermissionsModifyAllRecords = true
			));
		}
		Savepoint sp = Database.setSavepoint();
		List<Database.SaveResult> srList = Database.insert(objPermissionList, false);
		Database.rollback(sp);
		String defaultMessage = 'You can\'t create, edit, or delete records for this permission set parent because it\'s associated with a standard profile.';
		Integer i=0;
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetList){
			//System.debug(ps.profile.Name + ' srList.get(' + i + ')::' + srList.get(i));
			for (Database.Error e: srList.get(i).getErrors()) {
				if (!e.Message.contains(defaultMessage)) {
					//customProfilesNameSet.add(ps.ProfileId);
					options.add(new SelectOption(ps.profileId, customProfiles.get(ps.profileId).Name));
				}
			}
			i++;
		}*/
		
		List<PermissionSet> permissionSetList = [SELECT Profile.Name,CreatedById,CreatedDate,ProfileId FROM PermissionSet Where Iscustom=true AND ProfileID != null];
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetList){
			options.add(new SelectOption(ps.profileId, ps.Profile.Name));
		}
		options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllProfilesList() {
		//List<Profile> customProfiles = [SELECT Id, Name, CreatedDate FROM Profile WHERE  Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User')];
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix, Profile.Name 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = true 
													AND Profile.Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User')
													ORDER BY Profile.Name];
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsList) {
			options.add(new SelectOption(ps.ProfileId, ps.profile.Name));
		}
		options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllOrganizationProfilesList() {
		//List<Profile> customProfiles = [SELECT Id, Name, CreatedDate FROM Profile WHERE  Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User')];
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix, Profile.Name 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = true AND NamespacePrefix = null 
													AND Profile.Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User')
													ORDER BY Profile.Name];
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsList) {
			options.add(new SelectOption(ps.ProfileId, ps.profile.Name));
		}
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllManagedProfilesList() {
		//List<Profile> customProfiles = [SELECT Id, Name, CreatedDate FROM Profile WHERE  Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User')];
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix, Profile.Name 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = true AND NamespacePrefix != null 
													AND Profile.Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User')
													ORDER BY Profile.Name];
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsList) {
			options.add(new SelectOption(ps.ProfileId, ps.profile.Name));
		}
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllManagedPermissionSetList() {
		List<PermissionSet> permissionSetsLists = [SELECT Id, ProfileId, Name, Label, NamespacePrefix 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = false AND NamespacePrefix != null AND isCustom = true
													ORDER BY Name];
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsLists) {
			options.add(new SelectOption(ps.ID, ps.Name));
		}
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllOrganizationPermissionSetList() {
		List<PermissionSet> permissionSetsLists = [SELECT Id, ProfileId, Name, Label, NamespacePrefix 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = false AND NamespacePrefix = null AND isCustom = true
													ORDER BY Name];
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsLists) {
			options.add(new SelectOption(ps.ID, ps.NamE));
		}
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllPermissionSetList() {
		List<PermissionSet> permissionSetsLists = [SELECT Id, ProfileId, Name, Label, NamespacePrefix 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = false AND isCustom = true
													ORDER BY Name];
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsLists) {
			options.add(new SelectOption(ps.ID, ps.Name));
		}
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getPermissionType() {
		List<SelectOption> options = new List<SelectOption>();
		//options.add(new SelectOption('Organization Profiles & Permission Sets','Organization Profiles & Permission Sets'));
		//options.add(new SelectOption('Managed Package Profiles & Permission Sets','Managed Package Profiles & Permission Sets'));
		//options.add(new SelectOption('All Profiles & Permission Sets','All Profiles & Permission Sets'));
		options.add(new SelectOption('Organization Profiles','Organization Profiles'));
		//options.add(new SelectOption('Organization Permission Sets','Organization Permission Sets'));
		options.add(new SelectOption('Managed Package Profiles','Managed Package Profiles'));
		//options.add(new SelectOption('Managed Package Permission Sets','Managed Package Permission Sets'));
		options.add(new SelectOption('All Profiles','All Profiles'));
		//options.add(new SelectOption('All Permission Sets','All Permission Sets'));
		return options;
	}

	public static List<String> getPermissionTypeForLightning() {
		List<String> options = new List<String>();
		//options.add('Organization Profiles & Permission Sets');
		options.add('Managed Package Profiles & Permission Sets');
		//options.add('All Profiles & Permission Sets');
		options.add('Organization Profiles');
		//options.add('Organization Permission Sets');
		options.add('Managed Package Profiles');
		//options.add('Managed Package Permission Sets');
		options.add('All Profiles');
		//options.add('All Permission Sets');
		return options;
	}
	
	public static List<SelectOption> changetPermissionType(String selectedPerm) {
		List<SelectOption> profilesList = new List<SelectOption>();
		if(selectedPerm == 'Organization Profiles & Permission Sets') {
			profilesList = new List<SelectOption>(getAllOrganizationProfilesList());
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllOrganizationPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		if(selectedPerm == 'Managed Package Profiles & Permission Sets') {
			profilesList = new List<SelectOption>(getAllManagedProfilesList());
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllManagedPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		if(selectedPerm == 'All Profiles') {
			profilesList = new List<SelectOption>(getAllProfilesList());
		}
		if(selectedPerm == 'Organization Profiles') {
			profilesList = new List<SelectOption>(getAllOrganizationProfilesList());
		}
		if(selectedPerm == 'Managed Package Profiles') {
			profilesList = new List<SelectOption>(getAllManagedProfilesList());
		}
		/*if(selectedPerm == 'All Permission Sets') {
			profilesList = new List<SelectOption>();
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}*/
		/*if(selectedPerm == 'Organization Permission Sets') {
			profilesList = new List<SelectOption>();
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllOrganizationPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}*/
		/*if(selectedPerm == 'Managed Package Permission Sets') {
			profilesList = new List<SelectOption>();
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllManagedPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}*/
		if(selectedPerm == 'All Profiles & Permission Sets') {
			profilesList = new List<SelectOption>(getAllProfilesList());
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		if(profilesList.size() > 0) {
			profilesList = sortAfterLabelSelectOptionList(profilesList);
		}
		return profilesList;
	}
    
    
    //Method to show permission sets in multi-select picklist in left option 
public static List<SelectOption> getAllPermissionSetsList(String selectedPermSet) {
    List<SelectOption> permsetList = new List<SelectOption>();

    List<SelectOption> allPermissionSets = new List<SelectOption>();
    allPermissionSets.addAll(getAllPermissionSetList());
    allPermissionSets.addAll(getAllOrganizationPermissionSetList());
    allPermissionSets.addAll(getAllManagedPermissionSetList());

    
        permsetList.addAll(allPermissionSets);
    

        permsetList.addAll(getAllOrganizationPermissionSetList());


        permsetList.addAll(getAllManagedPermissionSetList());



        permsetList = sortAfterLabelSelectOptionList(permsetList);
 
    
    return permsetList;
}


	
	public static List<SelectOption> getUserList() {
		if(!Schema.getGlobalDescribe().get('Profile').getDescribe().isAccessible()) {
			return null;
		}
		List<User> activeUser = [SELECT Id, Name, profileId, Profile.Name FROM User WHERE isActive = true];
		List<SelectOption> options = new List<SelectOption>();
		for(User user : activeUser) {
			if(!user.Name.contains('Automated')) {
				options.add(new SelectOption(user.Id, user.Name));
			}
		}
		options.sort();
		return options;
	}
	
	public static Map<String, Schema.DescribeFieldResult> getFieldDescribeMap(String objName) {
		system.debug('objName:::' + objName);
		if (String.isEmpty(objName)) {
			return null;
		}
		Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objName);
		Schema.DescribeSObjectResult dsor = SObjectTypeObj.getDescribe();
		
		// the map to be returned with the final data
		Map<String, Schema.DescribeFieldResult> finalMap = new Map<String, Schema.DescribeFieldResult>();
		// map of all fields in the object
		Map<String, Schema.SObjectField> objectFields = dsor.fields.getMap();
	
		// iterate over the requested fields and get the describe info for each one. 
		// add it to a map with field name as key
		for(String field : objectFields.keySet()){
			// add the results to the map to be returned
			finalMap.put(field, objectFields.get(field).getDescribe());
		}
		return finalMap;
	}
	
	/*public static void UpdateX() {
		FieldPermissions fp = [SELECT SobjectType, Field, PermissionsRead, PermissionsEdit, parentId FROM FieldPermissions where id = '01k0Y00002TdtclQAB'];
		fp.PermissionsEdit = false;
		update fp;
		//Database.SaveResult results = database.update(fp1,false);
		//system.debug('results:::' + results);
	}*/
	
	public static List<SelectOption> sortAfterLabelSelectOptionList(List<SelectOption> source) {
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
}