public with sharing class SecurityUtilForProfilePsetDecs {
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
		//if any object is missing on the object access and object and fields then you can add it here
	public static List<SelectOption> getObjectsList(String namespacePrefix, Boolean isManaged){
		
		Set<String> objTypes = new Set<String>();

		List<Schema.PicklistEntry> ple = ObjectPermissions.SObjectType.getDescribe().getPicklistValues();
		
		for(Schema.PicklistEntry f : ple) {
			objTypes.add(f.getValue());
		}
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
													AND Profile.Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User','AAA','James_Permission_Sets_Group','Management Permissions')
													ORDER BY Profile.Name];
         //Below code will exclude the PermisionsetGroups which are included in above code @TJ
         List<PermissionSetGroup> permissionSetsGroupsList = [SELECT Id, DeveloperName, MasterLabel, NamespacePrefix FROM PermissionSetGroup limit 9999];
        for(Integer i=permissionSetsList.size()-1; i>=0; i--){
            PermissionSet permissionSetRecord = permissionSetsList[i];
            for(PermissionSetGroup permissionSetGroupRecord : permissionSetsGroupsList){
                if(permissionSetRecord.Label == permissionSetGroupRecord.MasterLabel){
                    permissionSetsList.remove(i);
                    break;
                }
            }
        }
        ///------------------------------------------------------------------------
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsList) {
			options.add(new SelectOption(ps.ProfileId, ps.profile.Name));
		}
		options.sort();
		return options;
	}
	
	
	public static List<SelectOption> getAllPermissionSetList() {
         List<PermissionSetGroup> permissionSetsGroupsList = [SELECT Id, DeveloperName, MasterLabel, NamespacePrefix FROM PermissionSetGroup limit 9999];
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true  ORDER BY Name];
         for(Integer i=permissionSetsList.size()-1; i>=0; i--){
            PermissionSet permissionSetRecord = permissionSetsList[i];
            for(PermissionSetGroup permissionSetGroupRecord : permissionSetsGroupsList){
                if(permissionSetRecord.Label == permissionSetGroupRecord.MasterLabel){
                    permissionSetsList.remove(i);
                    break;
                }
            }
        }
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsList) {
			options.add(new SelectOption(ps.ID, ps.Label));
		}
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getPermissionType() {
		List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('-------- None -------','-------- None -------'));
		options.add(new SelectOption('All Profiles','All Profiles'));
		options.add(new SelectOption('All Permission Sets','All Permission Sets'));
		return options;
	}

	public static List<String> getPermissionTypeForLightning() {
		List<String> options = new List<String>();
		options.add('All Profiles');
		options.add('All Permission Sets');
		return options;
	}
	
	public static List<SelectOption> changetPermissionType(String selectedPerm) {
		List<SelectOption> profilesList = new List<SelectOption>();
		
		if(selectedPerm == 'All Profiles') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>(getAllProfilesList());
		}
		
		
		if(selectedPerm == 'All Permission Sets') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>();
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		
		return profilesList;
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
		Schema.SObjectType SObjectTypeObj;
		try {
			SObjectTypeObj = GlobalDescribeMap.get(objName);
		} catch (Exception e) {
			system.debug('Exception getting SObjectType: ' + e.getMessage());
			return null;
		}
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
        system.debug('finalMap=='+finalMap+'size'+finalMap.size());
		return finalMap;
	}
 
	
	 public static List<SelectOption> sortAfterLabelSelectOptionList(List<SelectOption> source) {
		List<String> sortList = new  List<String>();
		List<SelectOption> options = new List<SelectOption>();
		Map<String, String> valueLabelMap = new Map<String, String>();
		for(SelectOption so: source) {
            system.debug('so='+so);
			sortList.add(so.getLabel());
			valueLabelMap.put(so.getLabel(), so.getValue());
            }
          /*  for ( Schema.SObjectType obj : Schema.getGlobalDescribe().values() )
            {
                Schema.DescribeSObjectResult objDescription = obj.getDescribe();
                if(objDescription.getLabel() == sortList ){
                  sortList.add(objDescription.getName());
                }
            }*/
		system.debug('sort---=='+sortList);
		sortList.sort();
		for(String item : sortList) {
			options.add(new  SelectOption(valueLabelMap.get(item), item));
		}
		return options;
	}  



}