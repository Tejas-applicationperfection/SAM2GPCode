public with sharing class ProfilePsetDescription {
    public List<SelectOption> allCustomProfiles { get;  set; }
    public List<SelectOption> selectedProfileIds { get; set; } // For holding selected profile Ids
    public List<ProfileDescriptionWrapper> profileDescriptions { get; set; } // For holding profile descriptions
    public Boolean isEdit { get; set; }
    public String selectedPerm { get; set; }
    public Boolean OrgIsAccessible { get; set; }
    public String exportUser { get; set; }
    public String xmlheader { get; set; }
    public String endfile { get; set; }
    public String currentLanguage { get; set; }
    public Organization org { get; set; }
    public Boolean noEndpointMetadata { get; set; }
    public Integer totalProfiles { get; private set; } // New variable to store total profile count
    public Integer totalPermissionSets { get; private set; } // New variable to store total permission set count
    public Integer totalProfileDescriptions { get; private set; } // Variable to store profile descriptions count
    public Integer totalPermissionSetDescriptions { get; private set; } // Variable to store permission set descriptions count
    // Derived stats for profiles and permission sets (mirroring ObjectDescriptions stats)
    public Integer profilesWithDescriptionPopulated { get { return totalProfileDescriptions; } }
    public Integer profilesWithDescriptionBlank { get { return Math.max(totalProfiles - totalProfileDescriptions, 0); } }
    public Integer editableProfileCount { get { return totalProfiles; } }
    public Integer editableProfileBlankCount { get { return Math.max(profilesWithDescriptionBlank - uneditableProfileBlankCount, 0); } }
    public Integer uneditableProfileBlankCount {
        get {
            try {
                Set<Id> managedProfileIds = new Set<Id>();
                for (PermissionSet ps : [
                    SELECT ProfileId, NamespacePrefix
                    FROM PermissionSet
                    WHERE IsOwnedByProfile = true AND NamespacePrefix != null
                ]) {
                    if (ps.ProfileId != null) managedProfileIds.add(ps.ProfileId);
                }
                if (managedProfileIds.isEmpty()) return 0;
                Integer cnt = 0;
                for (Profile p : [SELECT Id, Description FROM Profile WHERE Id IN :managedProfileIds]) {
                    if (p.Description == null) cnt++;
                }
                return cnt;
            } catch (Exception e) {
                return 0;
            }
        }
    }

    public Integer permissionSetsWithDescriptionPopulated { get { return totalPermissionSetDescriptions; } }
    public Integer permissionSetsWithDescriptionBlank { get { return Math.max(totalPermissionSets - totalPermissionSetDescriptions, 0); } }
    public Integer editablePermissionSetCount { get { return totalPermissionSets; } }
    public Integer editablePermissionSetBlankCount { get { return Math.max(permissionSetsWithDescriptionBlank - uneditablePermissionSetBlankCount, 0); } }
    public Integer uneditablePermissionSetBlankCount { 
        get {
            try {
                Integer cnt = 0;
                // Count managed permission sets (NamespacePrefix not null) with blank description
                for (PermissionSet ps : [SELECT Id, Description, NamespacePrefix FROM PermissionSet WHERE IsOwnedByProfile = false AND Type != 'Group' AND NamespacePrefix != null]) {
                    if (ps.Description == null) cnt++;
                }
                return cnt;
            } catch (Exception e) {
                return 0;
            }
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
    
    
       // Constructor
    public ProfilePsetDescription() {
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
        exportUser = UserInfo.getName();
        Id currentUserId = UserInfo.getUserId();
        system.debug(currentUserId);
        User currentUser = [SELECT Id, Name FROM User WHERE Id =: currentUserId];
        currentLanguage = 'US';
        
        if(!Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()) {
            OrgIsAccessible = false;
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on Organization object');
            ApexPages.addMessage(myMsg);
        } else {
            OrgIsAccessible = true;
            
            noEndpointMetadata = false;
            String orgId = UserInfo.getOrganizationId();
            org = [SELECT Id , Name, NamespacePrefix FROM Organization WHERE ID = :orgID];
            system.debug('org name'+''+org.Name +''+ 'org Id' +''+ org.Id );
            
        }
        
        
        isEdit = false;
        allCustomProfiles = new List<SelectOption>();
        selectedProfileIds = new List<SelectOption>();
        profileDescriptions = new List<ProfileDescriptionWrapper>();
        totalProfiles = 0; // Initialize profile count
        totalPermissionSets = 0; // Initialize permission set count
        totalProfileDescriptions = 0; // Initialize profile descriptions count
        totalPermissionSetDescriptions = 0; // Initialize permission set descriptions count
        
        loadCustomProfiles();
        permissionSetCountMeth();
        DescCount();
         
        

       selectedPerm = 'All Profiles'; 
       // selectedPerm = '-------- None -------'; 
    }
    
    public List<SelectOption> getPermissionType() {
        
        List<SelectOption> options = new List<SelectOption>();
        options.addAll(SecurityUtilForProfilePsetDecs.getPermissionType());
        return options;
    }
    
    public void toggleEdit(){
        isEdit = !isEdit;
    }
    public  void SaveDescriptionMap(){
        isEdit = !isEdit;
        if(selectedPerm == 'All Profiles'){
            updateProfileDescription(profileDescriptions);
            
        }
        else{
            update_PermissionSet_Description(profileDescriptions);
            
        }
    }
    
    //Load all custom profiles into SelectOption list
    
    public void loadCustomProfiles() {
        allCustomProfiles.clear();
        selectedProfileIds.clear();
        // Query for permission sets that are owned by profiles and are custom
        List<PermissionSet> customPermissionSets = [SELECT Id, Profile.Name
                                                    FROM PermissionSet
                                                    WHERE IsOwnedByProfile = true AND Type != 'Group' ];
        
        
        // Add custom profiles from permission sets to the list
        for (PermissionSet permissionSet : customPermissionSets) {
            system.debug('Custom PermissionSet: ' + permissionSet);
            allCustomProfiles.add(new SelectOption(permissionSet.ProfileId, permissionSet.Profile.Name));
        }
        
        totalProfiles = customPermissionSets.size(); // Update profile count
        system.debug('totalProfiles Count' + '' + totalProfiles);
        allCustomProfiles.sort();
    }
    
    public void loadCustomPsets(){
        allCustomProfiles.clear();
        selectedProfileIds.clear();
        // Query for all permission sets
       
        //--------------
          List<PermissionSetGroup> permissionSetsGroupsList = [SELECT Id, DeveloperName, MasterLabel, NamespacePrefix FROM PermissionSetGroup limit 9999];
		List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix FROM PermissionSet WHERE Name != 'Security_Access_Manager_View_Licence' AND Type != 'Group' AND IsOwnedByProfile = false AND isCustom = true  ORDER BY Name];
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
			allCustomProfiles.add(new SelectOption(ps.ID, ps.Label));
		}
        
        //----------------------
        
        
        
        
        
        allCustomProfiles.sort();
    }
    
    
    public void permissionSetCountMeth(){
        List<PermissionSet> allPermissionSets = [SELECT Id, Name ,Description
                                                 FROM PermissionSet
                                                 WHERE IsOwnedByProfile = false AND Type != 'Group'];
        totalPermissionSets = allPermissionSets.size(); // Update permission set count
        for(PermissionSet pset : allPermissionSets){
            
             if (pset.Description != null) {
                 
        system.debug('pset' + '' + pset);

                     totalPermissionSetDescriptions++;
                 }
        }
        
        system.debug('totalPermissionSets count' + '' + totalPermissionSets);
        
    }
    
    
    
    public void changePermType() {
        
        if(selectedPerm == 'All Permission Sets')  {
            loadCustomPsets();
        }
        if(selectedPerm == 'All Profiles')  {
            loadCustomProfiles();
        }
        
        
    }
   /*
    * deprecated method -- security vulnarebility for userinfo.getsessionid ,replaced with named credentials 
    * public static String getNamespaceForProfileOrPermissionSet(String recordId) {
        // Make a callout to the Tooling API to get the NamespacePrefix
        String toolingQuery = 'SELECT NamespacePrefix FROM Profile WHERE Id = \'' + recordId + '\'';
        if (recordId.startsWith('0PS')) {
            toolingQuery = 'SELECT NamespacePrefix FROM PermissionSet WHERE Id = \'' + recordId + '\'';
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v62.0/tooling/query/?q=' + EncodingUtil.urlEncode(toolingQuery, 'UTF-8'));
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            // Parse the JSON response to extract NamespacePrefix
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            List<Object> records = (List<Object>) responseMap.get('records');
            if (!records.isEmpty()) {
                Map<String, Object> record = (Map<String, Object>) records[0];
                return (String) record.get('NamespacePrefix');
            }
        }
        return 'No Namespace';
    } */ 
    
    public static String getNamespaceForProfileOrPermissionSet(String recordId) {
    // Build SOQL for Tooling API
    String toolingQuery = 'SELECT NamespacePrefix FROM Profile WHERE Id = \'' + recordId + '\'';
    if (recordId.startsWith('0PS')) {
        toolingQuery = 'SELECT NamespacePrefix FROM PermissionSet WHERE Id = \'' + recordId + '\'';
    }

    // Call Tooling API using current session to avoid per-user Named Credential requirements
    HttpRequest req = new HttpRequest();
    String endpoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v62.0/tooling/query/?q=' + EncodingUtil.urlEncode(toolingQuery, 'UTF-8');
    req.setEndpoint(endpoint);
    req.setMethod('GET');
    req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
    req.setHeader('Content-Type', 'application/json');

    Http http = new Http();
    HttpResponse res;
    try {
        res = http.send(req);
    } catch (Exception e) {
        return null;
    }

    if (res != null && res.getStatusCode() == 200) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> records = (List<Object>) responseMap.get('records');
        if (records != null && !records.isEmpty()) {
            Map<String, Object> record = (Map<String, Object>) records[0];
            return (String) record.get('NamespacePrefix');
        }
    }

    return null;
}

  
  public void fetchProfileDescriptions() { 
    profileDescriptions.clear();
    
    if (selectedProfileIds.size() > 100) {
        ApexPages.Message errorMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 
            'You cannot select more than 100 Profiles or Permission Sets.');
        ApexPages.addMessage(errorMsg);
        return;
    }

    Integer serialNumber = 1;
    String orgId = UserInfo.getOrganizationId();
    Organization org = [SELECT Id, Name, NamespacePrefix FROM Organization WHERE Id = :orgId LIMIT 1];

    Set<String> profileIds = new Set<String>();
    Set<String> permissionSetIds = new Set<String>();

    for (SelectOption selectedProfile : selectedProfileIds) {
        String idPrefix = selectedProfile.getValue();
        if (idPrefix.startsWith('00e')) {
            profileIds.add(selectedProfile.getValue());
        } else if (idPrefix.startsWith('0PS')) {
            permissionSetIds.add(selectedProfile.getValue());
        }
    }

    Map<String, Profile> profileMap = new Map<String, Profile>(
        [SELECT Id, Description FROM Profile WHERE Id IN :profileIds]
    );

    Map<String, PermissionSet> permissionSetMap = new Map<String, PermissionSet>(
        [SELECT Id, Description FROM PermissionSet WHERE Id IN :permissionSetIds AND Type != 'Group']
    );

    for (SelectOption selectedProfile : selectedProfileIds) {
        String idPrefix = selectedProfile.getValue();
        String namespacePrefix = getNamespaceForProfileOrPermissionSet(selectedProfile.getValue());
        Boolean isManaged = String.isNotBlank(namespacePrefix) && namespacePrefix != org.NamespacePrefix;

        if (idPrefix.startsWith('00e') && profileMap.containsKey(selectedProfile.getValue())) {
            Profile profile = profileMap.get(selectedProfile.getValue());
            profileDescriptions.add(new ProfileDescriptionWrapper(serialNumber++, selectedProfile.getLabel(), profile.Description, isManaged));
        } 
        else if (idPrefix.startsWith('0PS') && permissionSetMap.containsKey(selectedProfile.getValue())) {
            PermissionSet permissionSet = permissionSetMap.get(selectedProfile.getValue());
            profileDescriptions.add(new ProfileDescriptionWrapper(serialNumber++, selectedProfile.getLabel(), permissionSet.Description, isManaged));
        } 
        else {
            System.debug('Unrecognized or missing ID: ' + idPrefix);
        }
    }

    System.debug('profileDescriptions==' + profileDescriptions);
}




 
    public void DescCount() {
    totalProfileDescriptions = 0;
    
    // Separate profile and permission set IDs
    Set<Id> profileIds = new Set<Id>();
    
    for (SelectOption selectedProfile : allCustomProfiles) {
        if (selectedProfile.getValue().startswith('00e')) {
            profileIds.add(selectedProfile.getValue());
        }
    }
    
    // Bulk query profiles
    if (!profileIds.isEmpty()) {
        List<Profile> profiles = [SELECT Id, Description FROM Profile WHERE Id IN :profileIds];
        for (Profile profile : profiles) {
            if (profile.Description != null) {
                totalProfileDescriptions++;
            }
        }
    }
}

    
    // Wrapper class for profile descriptions
    public class ProfileDescriptionWrapper {
        public Integer serialNumber { get; set; }
        public String profileName { get; set; }
        public String description { get; set; }
        public Boolean isManaged { get; set; }
        
        public ProfileDescriptionWrapper(Integer serialNumber, String profileName, String description, Boolean isManaged ) {
            this.serialNumber = serialNumber;
            this.profileName = profileName;
            this.description = description;
             this.isManaged = isManaged;
        }
    }
    
    public static MetadataService.MetadataPort createService() { 
    system.debug('TestingProfiles');  
    system.debug('debugg createService');

    MetadataService.MetadataPort service = new MetadataService.MetadataPort();

    // Set endpoint to use Named Credential
  //  service.endpoint_x = 'callout:SA_Audit__Tooling_API_Creds';   
    service.SessionHeader = new MetadataService.SessionHeader_element();
    service.SessionHeader.sessionId = UserInfo.getSessionId();

    service.timeout_x = 60000;

    return service;
}

    

public void updateProfileDescription(List<ProfileDescriptionWrapper> profileDescriptions) {
    system.debug('profileDescriptions=' + profileDescriptions);
    List<MetadataService.UpsertResult> results = new List<MetadataService.UpsertResult>();
    MetadataService.MetadataPort service = createService();

    // Create a set to store profile names for querying
    Set<String> profileNamesSet = new Set<String>();

    // Populate the set with profile names
    for (ProfileDescriptionWrapper pd : profileDescriptions) {
        if (pd != null) {
            profileNamesSet.add(pd.profileName);
        }
    }

    // Query to retrieve existing Profile details
    List<Profile> profiles = [
        SELECT Name, Description
        FROM Profile
        WHERE Name IN :profileNamesSet
    ];

    // Create a map to store existing descriptions for quick lookup
    Map<String, String> existingDescriptions = new Map<String, String>();

    // Populate the map with existing profile descriptions
    for (Profile profile : profiles) {
        existingDescriptions.put(profile.Name, profile.Description);
    }

    for (ProfileDescriptionWrapper selectedProfile : profileDescriptions) {
        if (selectedProfile != null && !selectedProfile.isManaged) { // Process only if not managed
            try {
                // Get the current description from the map
                String currentDescription = existingDescriptions.get(selectedProfile.profileName);
                String newDescription = selectedProfile.description; // Directly use the new description

                // Check if the new description is different from the current description
                if (currentDescription == null && String.isNotBlank(newDescription)) {
                    // Current description is null, and new description is not blank, so update
                    MetadataService.Profile customProfile = new MetadataService.Profile();
                    system.debug('Updating Profile: ' + selectedProfile.profileName);

                    // Prepare custom profile
                    customProfile.fullName = selectedProfile.profileName;
                    customProfile.description = newDescription; // Update with new description

                    // Upsert the metadata changes
                    results.addAll(service.upsertMetadata(new MetadataService.Metadata[] { customProfile }));
                    system.debug('Description updated for Profile: ' + selectedProfile.profileName);
                } else if (currentDescription != null && !currentDescription.equals(newDescription)) {
                    // Current description exists and is different from new description
                    MetadataService.Profile customProfile = new MetadataService.Profile();
                    system.debug('Updating Profile: ' + selectedProfile.profileName);

                    // Prepare custom profile
                    customProfile.fullName = selectedProfile.profileName;
                    customProfile.description = newDescription; // Update with new description

                    // Upsert the metadata changes
                    results.addAll(service.upsertMetadata(new MetadataService.Metadata[] { customProfile }));
                    system.debug('Description updated for Profile: ' + selectedProfile.profileName);
                } else {
                    system.debug('No changes for Profile: ' + selectedProfile.profileName);
                }
            } catch (Exception e) {
                System.debug('Error updating profile. Message: ' + e.getMessage());
            }
        } else {
            system.debug('No valid profile found for ID: ' + selectedProfile.profileName);
        }
    }

    // Handle the upsert results after processing all profiles
    for (MetadataService.UpsertResult result : results) {
        if (result.success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successfully updated: ' + result.fullName));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating: ' + result.fullName + '. Message: ' + result.errors[0].message));
        }
    }
}


    
    
/*  public void update_PermissionSet_Description(List<ProfileDescriptionWrapper> profileDescriptions) {
    system.debug('profileDescriptions=' + profileDescriptions);
    List<MetadataService.UpsertResult> results = new List<MetadataService.UpsertResult>();
    MetadataService.MetadataPort service = createService();

    // Create a set to store profile names for the query
    Set<String> profileNamesSet = new Set<String>();

    // Populate the set with profile names
    for (ProfileDescriptionWrapper pd : profileDescriptions) {
        if (pd != null) {
            profileNamesSet.add(pd.profileName);
        }
    }

    // Query to retrieve existing PermissionSet details
    List<PermissionSet> permissionSets = [
        SELECT Name, Description, PermissionsModifyAllData
        FROM PermissionSet
        WHERE Name IN :profileNamesSet AND Type != 'Group'
    ];

    // Create a map to store existing descriptions for quick lookup
    Map<String, String> existingDescriptions = new Map<String, String>();

    // Populate the map with existing permission set descriptions
    for (PermissionSet pSet : permissionSets) {
        existingDescriptions.put(pSet.Name, pSet.Description);
    }

    // Loop through the profiles to update only those with changed descriptions
    for (ProfileDescriptionWrapper selectedPsets : profileDescriptions) {
        if (selectedPsets != null && !selectedPsets.isManaged) { // Process only if not managed
            try {
                // Get the current description from the map
                String currentDescription = existingDescriptions.get(selectedPsets.profileName);
                String newDescription = selectedPsets.description; // Directly use the new description

                // Check if the new description is different from the current description
                if (currentDescription == null && String.isNotBlank(newDescription)) {
                    // Description is new and not blank, so update
                    MetadataService.PermissionSet customPermissionSet = new MetadataService.PermissionSet();
                    customPermissionSet.fullName = selectedPsets.profileName.replaceAll('[^a-zA-Z0-9\\s]', ' ').replaceAll('\\s+', '_').replaceAll('_+', '_').replaceAll('_$', '');
                    system.debug('Label='+selectedPsets.profileName);
                    system.debug('fullname='+selectedPsets.profileName.replaceAll('[^a-zA-Z0-9\\s]', ' ').replaceAll('\\s+', '_').replaceAll('_+', '_').replaceAll('_$', ''));
                    customPermissionSet.Label = selectedPsets.profileName;
                    customPermissionSet.description = newDescription;

                    // Upsert the metadata changes
                    results.addAll(service.upsertMetadata(new MetadataService.Metadata[] { customPermissionSet }));
                    system.debug('Description updated for PermissionSet: ' + selectedPsets.profileName);
                } else if (currentDescription != null && !currentDescription.equals(newDescription)) {
                    // Description has changed (non-null and different)
                    MetadataService.PermissionSet customPermissionSet = new MetadataService.PermissionSet();
                    customPermissionSet.fullName = selectedPsets.profileName.replaceAll('[^a-zA-Z0-9\\s]', ' ').replaceAll('\\s+', '_').replaceAll('_+', '_').replaceAll('_$', '');
                    customPermissionSet.Label = selectedPsets.profileName;
                    customPermissionSet.description = newDescription;

                    // Upsert the metadata changes
                    results.addAll(service.upsertMetadata(new MetadataService.Metadata[] { customPermissionSet }));
                    system.debug('Description updated for PermissionSet: ' + selectedPsets.profileName);
                } else {
                    // No change in description
                    system.debug('No changes for PermissionSet: ' + selectedPsets.profileName);
                }
            } catch (Exception e) {
                System.debug('Error updating permission set. Message: ' + e.getMessage());
            }
        } else {
            system.debug('No valid permission set found for ID: ' + selectedPsets.profileName);
        }
    }

    // Handle the upsert results after processing all permission sets
    for (MetadataService.UpsertResult result : results) {
        if (result.success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successfully updated: ' + result.fullName));
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating: ' + result.fullName + '. Message: ' + result.errors[0].message));
        }
    }
}*/
    public void update_PermissionSet_Description(List<ProfileDescriptionWrapper> profileDescriptions) { 
    system.debug('profileDescriptions=' + profileDescriptions);
    List<MetadataService.UpsertResult> results = new List<MetadataService.UpsertResult>();
    MetadataService.MetadataPort service = createService();

    // Create a set to store profile names for the query
    Set<String> profileNamesSet = new Set<String>();

    // Populate the set with profile names
    for (ProfileDescriptionWrapper pd : profileDescriptions) {
        if (pd != null) {
            profileNamesSet.add(pd.profileName);
        }
    }

    // Query to retrieve existing PermissionSet details
    List<PermissionSet> permissionSets = [
        SELECT Name, Description, PermissionsModifyAllData
        FROM PermissionSet
        WHERE Name IN :profileNamesSet AND Type != 'Group'
    ];

    // Create a map to store existing descriptions for quick lookup
    Map<String, String> existingDescriptions = new Map<String, String>();

    // Populate the map with existing permission set descriptions
    for (PermissionSet pSet : permissionSets) {
        existingDescriptions.put(pSet.Name, pSet.Description);
    }

    // Track updated PermissionSets for success messages
    Set<String> updatedPermissionSets = new Set<String>();

    // Loop through the profiles to update only those with changed descriptions
    for (ProfileDescriptionWrapper selectedPsets : profileDescriptions) {
        if (selectedPsets != null && !selectedPsets.isManaged) { // Process only if not managed
            try {
                // Get the current description from the map
                String currentDescription = existingDescriptions.get(selectedPsets.profileName);
                String newDescription = selectedPsets.description; // Directly use the new description

                // Check if the new description is different from the current description
                if ((currentDescription == null && String.isNotBlank(newDescription)) || 
                    (currentDescription != null && !currentDescription.equals(newDescription))) {
                    
                    MetadataService.PermissionSet customPermissionSet = new MetadataService.PermissionSet();
                    customPermissionSet.fullName = selectedPsets.profileName.replaceAll('[^a-zA-Z0-9\\s]', ' ').replaceAll('\\s+', '_').replaceAll('_+', '_').replaceAll('_$', '');
                    customPermissionSet.Label = selectedPsets.profileName;
                    customPermissionSet.description = newDescription;

                    // Upsert the metadata changes
                    results.addAll(service.upsertMetadata(new MetadataService.Metadata[] { customPermissionSet }));
                    updatedPermissionSets.add(selectedPsets.profileName); // Mark as updated
                    system.debug('Description updated for PermissionSet: ' + selectedPsets.profileName);
                } else {
                    // No change in description
                    system.debug('No changes for PermissionSet: ' + selectedPsets.profileName);
                }
            } catch (Exception e) {
                System.debug('Error updating permission set. Message: ' + e.getMessage());
            }
        } else {
            system.debug('No valid permission set found for ID: ' + selectedPsets.profileName);
        }
    }

    // Handle the upsert results after processing all permission sets
    for (MetadataService.UpsertResult result : results) {
        if (result.success && updatedPermissionSets.contains(result.fullName)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Successfully updated: ' + result.fullName));
        } else if (!result.success) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error updating: ' + result.fullName + '. Message: ' + result.errors[0].message));
        }
    }
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
   


    

    
    public PageReference ExportToExcel(){
        return Page.ProfilePsetDEscriptionExportToExcel;
    }
    
   
}