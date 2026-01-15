/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 10-16-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class SecurityUtil {
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
	
	public static List<SelectOption> getAllOrganizationProfilesList() {
		//List<Profile> customProfiles = [SELECT Id, Name, CreatedDate FROM Profile WHERE  Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User')];
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix, Profile.Name 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = true AND NamespacePrefix = null 
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
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllManagedProfilesList() {
		//List<Profile> customProfiles = [SELECT Id, Name, CreatedDate FROM Profile WHERE  Name NOT IN('Chatter Free User', 'Chatter Moderator User', 'Chatter External User', 'Guest License User')];
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix, Profile.Name 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = true AND NamespacePrefix != null 
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
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllManagedPermissionSetList() {
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix 
													FROM PermissionSet 
													WHERE IsOwnedByProfile = false AND NamespacePrefix != null AND isCustom = true  
													ORDER BY Name];
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
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsList) {
			options.add(new SelectOption(ps.ID, ps.Label));
		}
		//options.sort();
		return options;
	}
	
	public static List<SelectOption> getAllOrganizationPermissionSetList() {
        List<PermissionSetGroup> permissionSetsGroupsList = [SELECT Id, DeveloperName, MasterLabel, NamespacePrefix FROM PermissionSetGroup limit 9999];
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix FROM PermissionSet 
													WHERE IsOwnedByProfile = false AND NamespacePrefix = null AND isCustom = true
													ORDER BY Name];
        system.debug('permissionSetsList=='+permissionSetsList);
        
        for(Integer i=permissionSetsList.size()-1; i>=0; i--){
            PermissionSet permissionSetRecord = permissionSetsList[i];
            for(PermissionSetGroup permissionSetGroupRecord : permissionSetsGroupsList){
                if(permissionSetRecord.Label == permissionSetGroupRecord.MasterLabel){
                    permissionSetsList.remove(i);
                    break;
                }
            }
        }
        system.debug('permissionSetsList=='+permissionSetsList);
		List<SelectOption> options = new List<SelectOption>();
		for(PermissionSet ps : permissionSetsList) {
			options.add(new SelectOption(ps.ID, ps.Label));
		}
		//options.sort();
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
    
    // Fetch  PermissionSetGroups
    public static List<SelectOption> getAllPermissionSetGroupList() {
        // Fetch all PermissionSetGroups
        List<PermissionSetGroup> permissionSetGroupsList = [
            SELECT Id, DeveloperName, MasterLabel, NamespacePrefix
            FROM PermissionSetGroup
            ORDER BY MasterLabel
            LIMIT 9999
        ];
        
        // Fetch all PermissionSetGroupComponents (associated PermissionSets)
        List<PermissionSetGroupComponent> permissionSetGroupComponents = [
            SELECT PermissionSetGroupId, PermissionSetId
            FROM PermissionSetGroupComponent  LIMIT 30000
        ];
        
        // Prepare the list of options to be returned
        List<SelectOption> options = new List<SelectOption>();
        
        // Create a map to store PermissionSetGroupId to PermissionSetGroupComponent relationship
        Map<Id, List<PermissionSetGroupComponent>> psgToComponentsMap = new Map<Id, List<PermissionSetGroupComponent>>();
        
        for (PermissionSetGroupComponent psgc : permissionSetGroupComponents) {
            if (!psgToComponentsMap.containsKey(psgc.PermissionSetGroupId)) {
                psgToComponentsMap.put(psgc.PermissionSetGroupId, new List<PermissionSetGroupComponent>());
            }
            psgToComponentsMap.get(psgc.PermissionSetGroupId).add(psgc);
        }
        
        // Iterate through each PermissionSetGroup
        for (PermissionSetGroup psg : permissionSetGroupsList) {
            // Add the PermissionSetGroup as a parent option
            options.add(new SelectOption(psg.Id, psg.MasterLabel + ' (Group)'));
            
            // Fetch associated PermissionSets
            if (psgToComponentsMap.containsKey(psg.Id)) {
                List<Id> permissionSetIds = new List<Id>();
                for (PermissionSetGroupComponent psgc : psgToComponentsMap.get(psg.Id)) {
                    permissionSetIds.add(psgc.PermissionSetId);
                }
                
                // Query PermissionSets associated with the group
                List<PermissionSet> permissionSets = [SELECT Id, Label FROM PermissionSet WHERE Id IN :permissionSetIds];
                for (PermissionSet ps : permissionSets) {
                    options.add(new SelectOption(ps.Id, '-- ' + ps.Label));
                }
            }
        }
        system.debug('options--'+options);
        return options;
    }

    
    
    /*public static List<SelectOption> changetPermissionGrp(String AllPSetGrp) {
        List<SelectOption> profilesList = new List<SelectOption>();
        
        system.debug('entry in security util');
        profilesList = new List<SelectOption>();
        List<SelectOption> permissionSetsList = new List<SelectOption>(populateProfilesListWithPermissionSets(AllPSetGrp));
        profilesList.addAll(permissionSetsList);
        system.debug('profilesList-'+profilesList);
        return profilesList;
        
    }*/
   /* public static List<SelectOption> changetPermissionGrp(String AllPSetGrp) {
    List<SelectOption> profilesList = new List<SelectOption>();
    
    // Add check for null or empty
    if (String.isBlank(AllPSetGrp)) {
        system.debug('No PermissionSetGroup selected.');
        return profilesList;
    }

    system.debug('entry in security util');
    List<SelectOption> permissionSetsList = new List<SelectOption>(populateProfilesListWithPermissionSets(AllPSetGrp));
    profilesList.addAll(permissionSetsList);
    system.debug('profilesList-' + profilesList);
    return profilesList;
}

    
   public static List<SelectOption> populateProfilesListWithPermissionSets(String permissionSetGroupName) {
        system.debug('permissionSetGroupName='+permissionSetGroupName);
    List<SelectOption> options = new List<SelectOption>();
    
    if (String.isNotBlank(permissionSetGroupName)) {
        // Query to find the PermissionSetGroup by name
        List<PermissionSetGroup> psgList = [SELECT Id, DeveloperName, MasterLabel 
                                            FROM PermissionSetGroup 
                                            WHERE Id = :permissionSetGroupName 
                                            LIMIT 1];

        // Check if any PermissionSetGroup was found
        if (psgList.isEmpty()) {
            system.debug('nooptions=' );
            return options; // Return empty options list if no PermissionSetGroup is found
            
        }

        PermissionSetGroup psg = psgList[0];
       system.debug('psg.Id='+psg.Id);
        // Query to get the associated PermissionSets for the found PermissionSetGroup
        List<PermissionSetGroupComponent> psgComponents = [
            SELECT PermissionSet.Label, PermissionSet.Name, PermissionSetId 
            FROM PermissionSetGroupComponent 
            WHERE PermissionSetGroupId = :psg.Id
        ];
        
        // Convert the PermissionSets into SelectOption items
        for (PermissionSetGroupComponent psgComponent : psgComponents) {
            String permissionSetLabel = psgComponent.PermissionSet.Label != null ? psgComponent.PermissionSet.Label : psgComponent.PermissionSet.Name;
            options.add(new SelectOption(psgComponent.PermissionSetId, permissionSetLabel));
        }
    }
 system.debug('options-populate='+options);
    return options;
}*/
  public static List<SelectOption> changetPermissionGrp(String AllPSetGrp) {
    List<SelectOption> profilesList = new List<SelectOption>();

    // Add check for null or empty
    if (String.isBlank(AllPSetGrp)) {
        system.debug('No PermissionSetGroup selected.');
        return profilesList;
    }

    system.debug('entry in security util');
    List<SelectOption> permissionSetsList = new List<SelectOption>(populateProfilesListWithPermissionSets(AllPSetGrp));
    
    // Check for null before adding
    if (permissionSetsList != null) {
        profilesList.addAll(permissionSetsList);
    } else {
        system.debug('permissionSetsList is null');
    }

    system.debug('profilesList-' + profilesList);
    return profilesList;
}

public static List<SelectOption> populateProfilesListWithPermissionSets(String permissionSetGroupName) {
    system.debug('permissionSetGroupName=' + permissionSetGroupName);
    List<SelectOption> options = new List<SelectOption>();
    
    if (String.isNotBlank(permissionSetGroupName)) {
        // Query to find the PermissionSetGroup by Id
        List<PermissionSetGroup> psgList = [SELECT Id, DeveloperName, MasterLabel 
                                            FROM PermissionSetGroup 
                                            WHERE Id = :permissionSetGroupName 
                                            LIMIT 1];

        // Check if any PermissionSetGroup was found
        if (psgList.isEmpty()) {
            system.debug('No PermissionSetGroup found for Id: ' + permissionSetGroupName);
            return options; // Return empty options list if no PermissionSetGroup is found
        }

        PermissionSetGroup psg = psgList[0];
        system.debug('psg.Id=' + psg.Id);
        
        // Query to get the associated PermissionSets for the found PermissionSetGroup
        List<PermissionSetGroupComponent> psgComponents = [
            SELECT PermissionSet.Label, PermissionSet.Name, PermissionSetId 
            FROM PermissionSetGroupComponent 
            WHERE PermissionSetGroupId = :psg.Id
        ];

        // Query to get the muted Permission Sets
        List<PermissionSet> mutedPermissionSets = [
            SELECT Id, Label, Name 
            FROM PermissionSet 
            WHERE PermissionSetGroupId = :psg.Id AND IsOwnedByProfile = false AND IsCustom = true
        ];

        system.debug('psgComponents=' + psgComponents);
        system.debug('mutedPermissionSets=' + mutedPermissionSets);

        // Convert the regular PermissionSets into SelectOption items
        for (PermissionSetGroupComponent psgComponent : psgComponents) {
            if (psgComponent.PermissionSet != null) {
                String permissionSetLabel = psgComponent.PermissionSet.Label != null ? psgComponent.PermissionSet.Label : psgComponent.PermissionSet.Name;
                options.add(new SelectOption(psgComponent.PermissionSetId, permissionSetLabel));
            } else {
                system.debug('PermissionSet is null for component: ' + psgComponent);
            }
        }

        // Convert the muted PermissionSets into SelectOption items with "(Muted)" label
        for (PermissionSet mutedPset : mutedPermissionSets) {
            if (mutedPset != null) {
                String mutedLabel = mutedPset.Label != null ? mutedPset.Label : mutedPset.Name;
                options.add(new SelectOption(mutedPset.Id, mutedLabel + ' (Muted)'));
            } else {
                system.debug('Muted PermissionSet is null.');
            }
        }
    } else {
        system.debug('permissionSetGroupName is blank or null.');
    }
    
    system.debug('options-populate=' + options);
    return options;
}


    
	
	public static List<SelectOption> getPermissionType() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('Organization Profiles & Permission Sets','Organization Profiles & Permission Sets'));
		options.add(new SelectOption('Managed Package Profiles & Permission Sets','Managed Package Profiles & Permission Sets'));
		options.add(new SelectOption('All Profiles & Permission Sets','All Profiles & Permission Sets'));
		options.add(new SelectOption('Organization Profiles','Organization Profiles'));
		options.add(new SelectOption('Organization Permission Sets','Organization Permission Sets'));
		options.add(new SelectOption('Managed Package Profiles','Managed Package Profiles'));
		options.add(new SelectOption('Managed Package Permission Sets','Managed Package Permission Sets'));
		options.add(new SelectOption('All Profiles','All Profiles'));
		options.add(new SelectOption('All Permission Sets','All Permission Sets'));

		return options;
	}
    
    public static List<SelectOption> getPermissionGrpType() {
        List<SelectOption> options = new List<SelectOption>();
        
        // Add a default option
        options.add(new SelectOption('----------None----------', '----------None----------'));
        
        // Query to fetch all PermissionSetGroup names
        List<PermissionSetGroup> permissionSetGroupsList = [
            SELECT Id, MasterLabel 
            FROM PermissionSetGroup 
            ORDER BY MasterLabel  LIMIT 30000
        ];
        
        // Iterate over the results and add them as select options
        for (PermissionSetGroup psg : permissionSetGroupsList) {
            options.add(new SelectOption(psg.Id, psg.MasterLabel));
        }
        
        return options;
    }


	public static List<String> getPermissionTypeForLightning() {
		List<String> options = new List<String>();
		options.add('Organization Profiles & Permission Sets');
		options.add('Managed Package Profiles & Permission Sets');
		options.add('All Profiles & Permission Sets');
		options.add('Organization Profiles');
		options.add('Organization Permission Sets');
		options.add('Managed Package Profiles');
		options.add('Managed Package Permission Sets');
		options.add('All Profiles');
		options.add('All Permission Sets');

		return options;
	}
    
    
   
    
	
	public static List<SelectOption> changetPermissionType(String selectedPerm) {
		List<SelectOption> profilesList = new List<SelectOption>();
		if(selectedPerm == 'Organization Profiles & Permission Sets') {
            system.debug('entry in security util');
			profilesList = new List<SelectOption>(getAllOrganizationProfilesList());
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllOrganizationPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		if(selectedPerm == 'Managed Package Profiles & Permission Sets') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>(getAllManagedProfilesList());
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllManagedPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		if(selectedPerm == 'All Profiles') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>(getAllProfilesList());
		}
		if(selectedPerm == 'Organization Profiles') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>(getAllOrganizationProfilesList());
		}
		if(selectedPerm == 'Managed Package Profiles') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>(getAllManagedProfilesList());
		}
		if(selectedPerm == 'All Permission Sets') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>();
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		if(selectedPerm == 'Organization Permission Sets') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>();
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllOrganizationPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		if(selectedPerm == 'Managed Package Permission Sets') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>();
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllManagedPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
		if(selectedPerm == 'All Profiles & Permission Sets') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>(getAllProfilesList());
			List<SelectOption> permissionSetsList = new List<SelectOption>(getAllPermissionSetList());
			profilesList.addAll(permissionSetsList);
		}
        if(selectedPerm == 'All PermissionSetGroups') {
             system.debug('entry in security util');
			profilesList = new List<SelectOption>();
			List<SelectOption>  PermissionSetGroupList = new List<SelectOption>(getAllPermissionSetGroupList());
			profilesList.addAll(PermissionSetGroupList);
		}
		if(profilesList.size() > 0) {
			profilesList = sortAfterLabelSelectOptionList(profilesList);
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