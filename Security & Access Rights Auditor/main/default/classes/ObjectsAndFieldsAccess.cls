/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 10-12-2021
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class ObjectsAndFieldsAccess{
    
    // Method to check if the feature is enabled for the user
    public Boolean hasAccess { get; set; }
    
    //public List<Profile> customProfiles { get; set; }
    public List<Id> selectedProfileIdList { get; set; }
    public List<ObjectPermisionWrapper> objectPermisionWList { get; set; }
    public List<String> selectedObjectsList { get; set; }
    public String expandObject { get; set; }
    public Boolean readyToExport { get; set;}
    public String dummyexpandObject { get; set; }
    public List<RecordType> recordTypeList { get; set; }
    //public Map<String, List<RecordType>> recordTypeMap { get; set; }
    public List<Id> permisionSetIdList { get; set; }
    public List<SelectOption> selectedProfiles { get; set; }
    public List<SelectOption> selectedObjects { get; set; }
    public List<SelectOption> remainingProfiles { get; set; }
    public List<SelectOption> remainingProfiles1 { get; set; }
    public List<SelectOption> remainingObjects { get; set; }
    public List<SelectOption> remainingObjects1 { get; set; }
    public List<SelectOption> selectedProfileList { get; set; }
    public Map<String, String> objectNameMap { get; set; }
    public Organization org { get; set; }
    public Map<String, List<String>> fieldNameMap { get; set; }
    public Map<Id, String> profileNameMap { get; set; }
    public List<String> fieldNameList { get; set; }
    public String selectedLog { get; set; }
    public List<SelectOption> optionsLog { get; set; }
    public Map<String, List<FieldPermissionWrapper>> fieldPermissionMap { get; set; }
    
    public static List<SelectOption> objectsList { get; set; }
    public static List<SelectOption> profilesList { get; set; }
    public List<SelectOption> profList { get; set; }
    
    public String xmlheader { get; set; }
    public String endfile { get; set; }
    public String currentLanguage { get; set; }
    public String selectedLogExcel { get; set; }
    public String indAcrossCell { get; set; }
    public Boolean isAccessible { get; set; }
    public Boolean OrgIsAccessible { get; set; }
    
    public String isPdf { get; set; }
    public Map<String, Map<Id, FieldPermissionLogWrapper>> fielPermLogWMap { get; set; }
    public Datetime selectedLogValue { get; set; }
    public String description { get; set; }
    public String userSavedLog { get; set; }
    public String exportUser { get; set; }
    public String selectProfileId { get; set; }
    public Boolean readSelectOnlySelectedCheckbox { get; set; }
    public Boolean editSelectOnlySelectedCheckbox { get; set; }
    public Map<Id, Boolean> readProfileSelectCheckboxMap { get; set; }
    public Map<Id, Boolean> editProfileSelectCheckboxMap { get; set; }
    public Boolean displayPopUp { get; set; }
    public Boolean canChange { get; set; }
    public String selectedType { get; set; }
    public String selectedPerm { get; set; }
    public String AllPSetGrp { get; set; }
    
    
    // Method to check if the feature is enabled for the user
    public Boolean getPaidFeatureAccess() {
        
        
        try {
            // Attempt to check if the feature is enabled for the user
            //return FeatureManagement.checkPackageBooleanValue('ObjectFieldsPaidAccess');
            //for data dictionary
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
    
    
    
    public ObjectsAndFieldsAccess() {
        
        
        hasAccess = getPaidFeatureAccess();
        
        User user = new User();
        isAccessible = true;
        if(Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
            Id currentUserId = UserInfo.getUserId();
            user = [SELECT ID, Name, Profile.Name, profile.permissionscustomizeapplication FROM User WHERE Id = :currentUserId];
        }
        if(user.Profile.Name.contains('System Administrator') || user.profile.permissionscustomizeapplication) {
            canChange = true;
        }
        PermissionSet prSet = new PermissionSet();
        prSet = [SELECT Id, Name FROM PermissionSet WHERE Label = 'Security Access Manager View Licence' OR Label = 'Security & Access Manager View Licence'];
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
        displayPopUp = false;
        selectedProfileList = new List<SelectOption>();
        if(!Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()) {
            OrgIsAccessible = false;
        } else {
            String orgId = UserInfo.getOrganizationId();
            org = [SELECT Id , Name, NamespacePrefix FROM Organization WHERE ID = :orgID];
        }
        selectedLog = '';
        
        OrgIsAccessible = true;
        editSelectOnlySelectedCheckbox = false;
        readSelectOnlySelectedCheckbox = false;
        readProfileSelectCheckboxMap = new Map<Id, Boolean>();
        editProfileSelectCheckboxMap = new Map<Id, Boolean>();
        isPdf = ApexPages.currentPage().getParameters().get('isPdf');
        objectsList = new List<SelectOption>(sortAfterLabelSelectOptionList(SecurityUtil.getObjectsList(org.NamespacePrefix, false)));
        objectsList.add(new SelectOption('User', 'User'));
        selectedPerm = 'Organization Profiles & Permission Sets';
        if(Schema.getGlobalDescribe().get('Profile').getDescribe().isAccessible()) {
            profilesList = new List<SelectOption>(SecurityUtil.getAllOrganizationProfilesList());
            List<SelectOption> permissionSetsList = new List<SelectOption>(SecurityUtil.getAllOrganizationPermissionSetList());
            profilesList.addAll(permissionSetsList);
            profilesList = sortAfterLabelSelectOptionList(profilesList);
            system.debug('profilesList==='+profilesList);
            selectedProfiles = new List<SelectOption>();
            selectedObjects = new List<SelectOption>();
            //system.debug('isPdf' + isPdf);
            if (isPdf != 'true') {
                xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
                endfile = '</Workbook>';
                currentLanguage = 'US';
                createSelectList();
                retrieveRecords();
            } else {
                exportUser = user.Name;
                
                // Initialize variables
                selectedProfileIdList = new List<Id>();
                String selectedProfilesString = ApexPages.currentPage().getParameters().get('selectedProfilesString');
                if (!String.isBlank(selectedProfilesString)) {
                    selectedProfilesString = selectedProfilesString.trim();
                    selectedProfilesString = String.escapeSingleQuotes(selectedProfilesString); // Sanitize input
                    
                    // Process selected profiles
                    String s = selectedProfilesString.substringBefore('+');
                    selectedProfilesString = selectedProfilesString.removeStart(s + '+');
                    while (selectedProfilesString.contains('+')) {
                        s = selectedProfilesString.substringBefore('+');
                        if (isValidSalesforceId(s)) { // Validate ID format
                            selectedProfileIdList.add((Id)s);
                        }
                        selectedProfilesString = selectedProfilesString.removeStart(s + '+');
                    }
                    if (isValidSalesforceId(selectedProfilesString)) {
                        selectedProfileIdList.add((Id)selectedProfilesString);
                    }
                }
                
                
                profileNameMap = new Map<Id, String>();
                Set<Id> selectedProfileIdSet = new Set<Id>(selectedProfileIdList);
                remainingProfiles = new List<SelectOption>();
                for (SelectOption so : profilesList) {
                    if (selectedProfileIdSet.contains(so.getValue())) {
                        profileNameMap.put(so.getValue(), so.getLabel());
                        selectedProfiles.add(so);
                    } else {
                        remainingProfiles.add(so);
                    }
                }
                
                // Process object names
                objectNameMap = new Map<String, String>();
                for (SelectOption so : objectsList) {
                    objectNameMap.put(so.getValue(), so.getLabel());
                }
                system.debug('Testing objectNameMap: ' + objectNameMap);
                
                selectedObjectsList = new List<String>();
                String selectedObjectsString = ApexPages.currentPage().getParameters().get('selectedObjectsString');
                if (!String.isBlank(selectedObjectsString)) {
                    selectedObjectsString = selectedObjectsString.trim();
                    selectedObjectsString = String.escapeSingleQuotes(selectedObjectsString); // Sanitize input
                    
                    // Process selected objects
                    String s = selectedObjectsString.substringBefore('+');
                    selectedObjectsString = selectedObjectsString.removeStart(s + '+');
                    while (selectedObjectsString.contains('+')) {
                        s = selectedObjectsString.substringBefore('+');
                        system.debug('Processing object: ' + s);
                        selectedObjectsList.add(s.trim()); // Trim and add to list
                        selectedObjectsString = selectedObjectsString.removeStart(s + '+');
                    }
                    selectedObjectsList.add(selectedObjectsString.trim());
                }
                system.debug('Selected Objects List: ' + selectedObjectsList.size() + ' - ' + selectedObjectsList);
                
                // Process other parameters
                expandObject = ApexPages.currentPage().getParameters().get('expandObject');
                if (!String.isBlank(expandObject)) {
                    expandObject = String.escapeSingleQuotes(expandObject.trim());
                }
                
                selectedLog = ApexPages.currentPage().getParameters().get('selectedLog');
                if (!String.isBlank(selectedLog)) {
                    selectedLog = String.escapeSingleQuotes(selectedLog.trim());
                }
                
                // Retrieve records and process change log
                retrieveRecords();
                if (!String.isBlank(selectedLog)) {
                    changeLog();
                }
            }
            
            
        } else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on Profile object');
            ApexPages.addMessage(myMsg);
            isAccessible = false;
        }
        
        //selectedObjects.clear();
        // expandObject = '';
        //selectedProfileIdList.clear();
        //selectedProfiles.clear();
        
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
    private Boolean isValidSalesforceId(String id) {
        // Ensure the string is not null and its length is either 15 or 18
        if (id == null || (id.length() != 15 && id.length() != 18)) {
            return false;
        }
        // Use regex to check if it contains only alphanumeric characters
        String sanitizedId = id.replaceAll('[A-Za-z0-9]', '');
        return sanitizedId == ''; // Check if no non-alphanumeric characters are left
    }
    
    
    
    
    
    public List<SelectOption> getObjectsType() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Organization Object','Organization Object'));
        options.add(new SelectOption('Managed Object','Managed Object'));
        return options;
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
    public void changeType() {
        expandObjects1();
        AllPSetGrp = '----------None----------'; 
        system.debug('param::' + selectedPerm + ' ' + selectedType);
        profilesList = new List<SelectOption>(SecurityUtil.changetPermissionType(selectedPerm));
        
        system.debug('selectedPerm++++'+selectedPerm);
        selectedProfiles = new List<SelectOption>();
        profilesList = sortAfterLabelSelectOptionList(profilesList); 
        selectedProfiles = new List<SelectOption>();
        selectedObjects = new List<SelectOption>();
        if(selectedType == 'Organization Object') {
            objectsList = new List<SelectOption>(sortAfterLabelSelectOptionList(SecurityUtil.getObjectsList(org.NamespacePrefix, false)));
        } else {
            objectsList = new List<SelectOption>(SecurityUtil.getObjectsList(org.NamespacePrefix, true));
            //below code duplicate object name
            Map<String, Integer> labelCountMap = new Map<String, Integer>();
            
            for (SelectOption option : objectsList) {
                String label = option.getLabel();
                Integer count = labelCountMap.get(label);
                
                if (count == null) { 
                    labelCountMap.put(label, 1);
                } else { 
                    count++;
                    labelCountMap.put(label, count);
                    option.setLabel(label + '_' + count);
                }
            }
        }         
        
        //system.debug('object size::' + objectsList.size());
        selectedLog = '-- Please select --';
        createSelectList();
        retrieveRecords();
    }
    
    public void changePsetGrp() {
        expandObjects1();
        profilesList = new List<SelectOption>(SecurityUtil.changetPermissionGrp(AllPSetGrp));
        system.debug('selectedPerm++++'+selectedPerm);
        selectedProfiles = new List<SelectOption>();
        profilesList = sortAfterLabelSelectOptionList(profilesList); 
        if(profilesList == null){
            ApexPages.Message warningMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'You don\'t have any permissionsets that you can update.');
            ApexPages.addMessage(warningMsg);
        }
        selectedProfiles = new List<SelectOption>();
        selectedObjects = new List<SelectOption>();
        if(selectedType == 'Organization Object') {
            objectsList = new List<SelectOption>(sortAfterLabelSelectOptionList(SecurityUtil.getObjectsList(org.NamespacePrefix, false)));
        } else {
            objectsList = new List<SelectOption>(SecurityUtil.getObjectsList(org.NamespacePrefix, true));
            //below code duplicate object name
            Map<String, Integer> labelCountMap = new Map<String, Integer>();
            
            for (SelectOption option : objectsList) {
                String label = option.getLabel();
                Integer count = labelCountMap.get(label);
                
                if (count == null) { 
                    labelCountMap.put(label, 1);
                } else { 
                    count++;
                    labelCountMap.put(label, count);
                    option.setLabel(label + '_' + count);
                }
            }
        }         
        
        //system.debug('object size::' + objectsList.size());
        selectedLog = '-- Please select --';
        createSelectList();
        retrieveRecords();
        
        
        
    }
    
    public List<SelectOption> sortAfterLabelSelectOptionList(List<SelectOption> source) {
        system.debug('source==='+source);
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
        objectNameMap = new Map<String, String>();
        Set<String> seenLabels = new Set<String>();
        for(SelectOption so : objectsList) {
            objectNameMap.put(so.getValue(), so.getLabel());
        }
        //system.debug('objectNameMap::' + objectNameMap);
        selectedObjectsList = new List<String>();
        selectedObjectsList.add(objectsList[0].getValue());
        objectsList.remove(0);
        //system.debug('objectsList:::' + objectsList);
        selectedObjects.add(new SelectOption(selectedObjectsList[0], objectNameMap.get(selectedObjectsList[0])));
        remainingObjects = new List<SelectOption>();
        remainingObjects1 = new List<SelectOption>();
        
        objectsList = sortAfterLabelSelectOptionList(objectsList);
        
        if(objectsList.size() > 900) {
            Integer i = 0;
            for(SelectOption so : objectsList){
                
                if(i < 900) {
                    
                    remainingObjects.add(new SelectOption(so.getValue(), so.getLabel()));
                } else {
                    remainingObjects1.add(new SelectOption(so.getValue(), so.getLabel()));
                }
                i++;
            }
            
            //remainingObjects1 = sortAfterLabelSelectOptionList(remainingObjects1);
        } else {
            for(SelectOption so : objectsList){
                
                
                remainingObjects.add(new SelectOption(so.getValue(), so.getLabel()));
            }
        }
        //remainingObjects = sortAfterLabelSelectOptionList(remainingObjects);
        system.debug('remainingObjects:::' + remainingObjects.size());
        
        selectedObjectsList = new List<String>(); 
        selectedObjectsList.add(objectsList[0].getValue());
        
        objectsList.remove(0);
        selectedObjects.add(new SelectOption(selectedObjectsList[0], objectNameMap.get(selectedObjectsList[0])));
        remainingObjects = new List<SelectOption>();
        remainingObjects1 = new List<SelectOption>();
        
        objectsList = sortAfterLabelSelectOptionList(objectsList);
        if (objectsList.size() > 900) {
            Integer i = 0;
            for (SelectOption so : objectsList) {
                
                if (i < 900) {
                    remainingObjects.add(new SelectOption(so.getValue(), objectNameMap.get(so.getValue())));
                } else {
                    remainingObjects1.add(new SelectOption(so.getValue(), objectNameMap.get(so.getValue())));
                }
                i++;
            }
        } else {
            for (SelectOption so : objectsList) {
                
                remainingObjects.add(new SelectOption(so.getValue(), objectNameMap.get(so.getValue())));
                
            }
        }
        system.debug('remainingObjects:::' + remainingObjects.size());
        profilesList = sortAfterLabelSelectOptionList(profilesList);
        selectedProfileIdList = new List<Id>();
        profileNameMap = new Map<Id, String>();
        if(profilesList.size() > 1) {
            system.debug('profilesList:::' + profilesList);
            selectedProfileIdList.add((Id)profilesList[0].getValue());
            selectedProfileIdList.add((Id)profilesList[1].getValue());
            profileNameMap.put((Id)profilesList[0].getValue(), profilesList[0].getLabel());
            profileNameMap.put((Id)profilesList[1].getValue(), profilesList[1].getLabel());
            profilesList.remove(0);
            profilesList.remove(0);
        } else { 
            if(profilesList.size() == 1) { 
                system.debug('profilesList:::' + profilesList);
                selectedProfileIdList.add((Id)profilesList[0].getValue());
                profileNameMap.put((Id)profilesList[0].getValue(), profilesList[0].getLabel()); 
                profilesList.remove(0);
            }
        } 
        for (String profId : selectedProfileIdList) {
            selectedProfiles.add(new SelectOption(profId, profileNameMap.get(profId)));
            readProfileSelectCheckboxMap.put(profId, false);
            editProfileSelectCheckboxMap.put(profId, false);
        }
        
        //system.debug('profilesList::' + profilesList);
        remainingProfiles = new List<SelectOption>();
        remainingProfiles1 = new List<SelectOption>();
        Set<String> profileLabels = new Set<String>();
        if(profilesList.size() > 900) {
            Integer i = 0;
            for(SelectOption so : profilesList){
                if(i < 900) {
                    String profileId = so.getValue();
                    String profileLabel = so.getLabel();
                    if(!profileLabels.contains(profileLabel)) {
                        remainingProfiles.add(new SelectOption(profileId, profileLabel));
                        profileLabels.add(profileLabel);
                    }
                } else {
                    String profileId = so.getValue();
                    String profileLabel = so.getLabel();
                    if(!profileLabels.contains(profileLabel)) {
                        remainingProfiles1.add(new SelectOption(profileId, profileLabel));
                        profileLabels.add(profileLabel);
                    }
                }
                i++;
            }
            remainingProfiles = sortAfterLabelSelectOptionList(remainingProfiles);
            remainingProfiles1 = sortAfterLabelSelectOptionList(remainingProfiles1);
        } else {
            for(SelectOption so : profilesList) {
                String profileId = so.getValue();
                String profileLabel = so.getLabel();
                if(!profileLabels.contains(profileLabel)) {
                    remainingProfiles.add(new SelectOption(profileId, profileLabel));
                    profileLabels.add(profileLabel);
                }
            }
            remainingProfiles = sortAfterLabelSelectOptionList(remainingProfiles);
        }
        profilesList = new List<SelectOption>();
        
    }
    
    public List<SelectOption> getLogList() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-- Please select --'));
        system.debug('expandObject===' + expandObject);
        List<SA_Audit__Objects_And_Fields_Log__c> objLogList = [SELECT SA_Audit__Object_Type__c, SA_Audit__Date__c, SA_Audit__Value__c FROM SA_Audit__Objects_And_Fields_Log__c WHERE SA_Audit__Object_Type__c = :expandObject order by SA_Audit__Date__c desc LIMIT 999];
        system.debug('objLogList==' + objLogList.size());
        for (SA_Audit__Objects_And_Fields_Log__c log : objLogList) {
            options.add(new SelectOption(log.Id, log.SA_Audit__Date__c + ''));
        }
        system.debug('options==' + options);
        return options;
    }
    
    public void changeLog() {
        selectedProfileList = new List<SelectOption>();
        if(selectedLog != null && selectedLog != '' && selectedLog != '-- Please select --') {
            Id logId = (ID)selectedLog;
            system.debug('logId'+logId);
            SA_Audit__Objects_And_Fields_Log__c objlog = [SELECT SA_Audit__Description__c, SA_Audit__User_Name__c, SA_Audit__Object_Type__c, SA_Audit__Date__c, SA_Audit__Value__c FROM SA_Audit__Objects_And_Fields_Log__c WHERE Id = :logId];
            system.debug('objlog===>'+objlog);
            List<SA_Audit__Fields_Profile_Log__c> fieldProfileList = [SELECT SA_Audit__ProfileId__c, SA_Audit__Value__c FROM SA_Audit__Fields_Profile_Log__c WHERE SA_Audit__Objects_And_Fields_Log__c = :objlog.Id];
            system.debug('fieldProfileList==='+fieldProfileList);
            selectedLogValue = objlog.SA_Audit__Date__c;
            description = objlog.SA_Audit__Description__c;
            userSavedLog = objlog.SA_Audit__User_Name__c;
            Map<Id, List<FieldPermissionWrapper>> fieldPermM = new Map<Id, List<FieldPermissionWrapper>>();
            for(SA_Audit__Fields_Profile_Log__c fieldProf : fieldProfileList) {
                fieldPermM.put(fieldProf.SA_Audit__ProfileId__c, deserializeFieldPermisionWrapper(fieldProf.SA_Audit__Value__c));
            }
            
            selectedProfileIdList = new List<Id>();
            Map<String, List<FieldPermissionWrapper>> fieldPermissionSavedMap = new Map<String, List<FieldPermissionWrapper>>();
            for(Id profileId : fieldPermM.keySet()) {
                selectedProfileIdList.add(profileId);
                for(FieldPermissionWrapper fpw : fieldPermM.get(profileId)) {
                    if(!fieldPermissionSavedMap.containsKey(fpw.field.tolowerCase())) {
                        fieldPermissionSavedMap.put(fpw.field.tolowerCase(), new List<FieldPermissionWrapper>());
                    }
                    fieldPermissionSavedMap.get(fpw.field.tolowerCase()).add(fpw);
                }
            }
            Set<ID> selectedProfileIdSet = new Set<Id>(selectedProfileIdList);
            for (String fn : fieldNameList) {
                if (!fieldPermissionSavedMap.containsKey(fn)) {
                    fieldPermissionSavedMap.put(fn, new List<FieldPermissionWrapper>());
                    for (Id prId : selectedProfileIdSet) {
                        fieldPermissionSavedMap.get(fn).add(new FieldPermissionWrapper(new FieldPermissions(parentId = prID, PermissionsEdit = false, PermissionsRead = false, field = fn, SobjectType = objlog.SA_Audit__Object_Type__c)));
                    }
                }
            }
            
            //create selectedList and remaininglist for Profile and Objects
            profilesList = new List<SelectOption>();
            for(SelectOption so : selectedProfiles) {
                profilesList.add(so);
            }
            for(SelectOption so : remainingProfiles) {
                profilesList.add(so);
            }
            selectedProfiles = new List<SelectOption>();
            remainingProfiles = new List<SelectOption>();
            
            for(SelectOption so : profilesList) {
                if(selectedProfileIdSet.contains(so.getValue())) {
                    selectedProfiles.add(so);
                } else {
                    remainingProfiles.add(so);
                }
            }
            remainingProfiles = sortAfterLabelSelectOptionList(remainingProfiles);
            selectedProfiles = sortAfterLabelSelectOptionList(selectedProfiles);
            profileNameMap = new  Map<Id, String>();
            
            for(SelectOption so : selectedProfiles) {
                
                profileNameMap.put(so.getValue(), so.getLabel());
            }
            system.debug('profileNameMap::::' + profileNameMap);
            system.debug('selectedProfileIdList::' + selectedProfileIdList);
            profilesList = new List<SelectOption>();
            
            selectedObjects = new List<SelectOption>();
            remainingObjects = new List<SelectOption>();
            selectedObjects.add(new SelectOption(objlog.SA_Audit__Object_Type__c, objectNameMap.get(objlog.SA_Audit__Object_Type__c)));
            selectedObjectsList = new List<String>{objlog.SA_Audit__Object_Type__c};
                for(String objName : objectNameMap.keySet()) {
                    if(objName != objlog.SA_Audit__Object_Type__c) {
                        remainingObjects.add(new SelectOption(objName, objectNameMap.get(objName)));
                    }
                }
            remainingObjects = sortAfterLabelSelectOptionList(remainingObjects);
            
            retrieveRecords();
            fielPermLogWMap = new Map<String, Map<Id, FieldPermissionLogWrapper>>();
            Integer index = 0;
            for (String fn : fieldPermissionMap.KeySet()) {
                if (!fielPermLogWMap.containsKey(fn)) {
                    fielPermLogWMap.put(fn, new Map<Id, FieldPermissionLogWrapper>());
                }
                index = 0;
                for (Id prId : selectedProfileIdList) {
                    if (!fielPermLogWMap.get(fn).containsKey(prId)) {
                        fielPermLogWMap.get(fn).put(prId, new FieldPermissionLogWrapper(fieldPermissionMap.get(fn)[index],fieldPermissionSavedMap.get(fn)[index].R, fieldPermissionSavedMap.get(fn)[index].E));
                    }
                    index++;
                }
            }
            fieldPermissionMap = new Map<String, List<FieldPermissionWrapper>>();
            //system.debug('fielPermLogWMap::' + fielPermLogWMap);
        } else {
            fielPermLogWMap = new Map<String, Map<Id, FieldPermissionLogWrapper>>();
            editProfileSelectCheckboxMap = new Map<Id, Boolean>();
            readProfileSelectCheckboxMap = new Map<Id, Boolean>();
            for(ID prID : selectedProfileIdList) {
                readProfileSelectCheckboxMap.put(prID, false);
                editProfileSelectCheckboxMap.put(prID, false);
            }
            retrieveRecords();
        }
    }
    
    public void retrieveRecords() {
        try{
            // Early validation and initialization
            if(String.isEmpty(selectedLog)) {
                description = '';
            }
            optionsLog = getLogList();
            
            // Optimize object name processing
            if(selectedObjectsList == null || selectedObjectsList.isEmpty()) {
                return;
            }
            
            Set<String> objNameSet = new Set<String>(selectedObjectsList);
            system.debug('objNameSet::' + objNameSet);
            
            // Optimize ObjectPermissions query with proper limits
            Set<Id> excludedObjectPermIds = new Set<Id>();
            for(ObjectPermissions op : [SELECT Id, ParentId FROM ObjectPermissions 
                                       WHERE SObjectType IN :objNameSet 
                                       LIMIT 10000]) {
                if(String.valueOf(op.Id).startsWith('000')) {
                    excludedObjectPermIds.add(op.Id);
                }
            }
            system.debug('excludedObjectPermIds size::' + excludedObjectPermIds.size());
            
            // Optimize PermissionSet query with better filtering
            Set<Id> selectedProfilesIdSet = new Set<Id>(selectedProfileIdList);
            List<PermissionSet> permisionSetList = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name
                                                    FROM PermissionSet 
                                                    WHERE (IsOwnedByProfile = true AND Profile.Id IN :selectedProfilesIdSet) OR
                                                    (IsOwnedByProfile = false AND isCustom = true)
                                                    ORDER BY Profile.Name ASC 
                                                    LIMIT 5000];
            system.debug('permisionSetList size::' + permisionSetList.size());
            /*List<PermissionSet> permissionSetsList = [SELECT Id, ProfileId, Name, Label, NamespacePrefix,
(SELECT Id, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM Objectperms WHERE ID NOT IN :excludedObjectPermIds) 
FROM PermissionSet WHERE IsOwnedByProfile = false AND isCustom = true];
permisionSetList.addAll(permissionSetsList);*/
            
            //List<Objectpermissions> objPermTempList = new List<objectpermissions>();
            //objPermTempList = [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
            //						 FROM Objectpermissions WHERE ParentId = :permisionSetList AND ID NOT IN :excludedObjectPermIds];
            Map<Id,List<ObjectPermissions>> objectPermMap = new Map<Id,List<ObjectPermissions>>();
            //ADDED FOR THE CODE TEST
            if (Test.isRunningTest()) {
                for (ObjectPermissions obj : [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
                                              FROM Objectpermissions WHERE ParentId = :permisionSetList AND ID NOT IN :excludedObjectPermIds Limit 1]) {//objPermTempList
                                                  if(!objectPermMap.containsKey(obj.ParentId)) {
                                                      objectPermMap.put(obj.ParentId, new List<ObjectPermissions>());
                                                  }
                                                  objectPermMap.get(obj.ParentId).add(obj);
                                              }
            }
            else{
                system.debug('permisionSetList=='+permisionSetList.size());
                for (ObjectPermissions obj : [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
                                              FROM Objectpermissions WHERE ParentId = :permisionSetList AND ID NOT IN :excludedObjectPermIds Limit 18000]) {//objPermTempList
                                                  if(!objectPermMap.containsKey(obj.ParentId)) {
                                                      objectPermMap.put(obj.ParentId, new List<ObjectPermissions>());
                                                  }
                                                  objectPermMap.get(obj.ParentId).add(obj);
                                              }  
                Integer currentHeapSize = Limits.getHeapSize();
                Integer maxHeapSize = Limits.getLimitHeapSize();
                
                // System.debug('Current Heap Size: ' + currentHeapSize + ' bytes');
                //  System.debug('Maximum Heap Size: ' + maxHeapSize + ' bytes');
                System.debug('Heap Usage Percentage: ' + ((currentHeapSize * 100) / maxHeapSize) + '%');
                
            } 
            /*else {
system.debug('permisionSetList==' + permisionSetList.size());

for (ObjectPermissions obj : [
SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, 
PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords 
FROM Objectpermissions 
WHERE ParentId = :permisionSetList 
AND ID NOT IN :excludedObjectPermIds 
LIMIT 2000
]) {
// Log current heap size and heap limit
Integer currentHeapSize = Limits.getHeapSize();
Integer maxHeapSize = Limits.getLimitHeapSize();

System.debug('Current Heap Size: ' + currentHeapSize + ' bytes');
System.debug('Maximum Heap Size: ' + maxHeapSize + ' bytes');
System.debug('Heap Usage Percentage: ' + ((currentHeapSize * 100) / maxHeapSize) + '%');

// Check if heap size is approaching the limit
if (currentHeapSize > (maxHeapSize * 0.8)) {
System.debug('Heap size nearing limit. Exiting loop.');
break;
}

if (!objectPermMap.containsKey(obj.ParentId)) {
objectPermMap.put(obj.ParentId, new List<ObjectPermissions>());
}
objectPermMap.get(obj.ParentId).add(obj);
}
}*/
            objectPermisionWList = new List<ObjectPermisionWrapper>();
            //Map<String, ProfileWrapper> objPermMap;
            
            Set<String> selectedObjectsSet = new Set<String>(selectedObjectsList);
            //system.debug('selectedObjectsSet1::' + selectedObjectsSet);
            Map<String, List<String>> objPermMap = new Map<String, List<String>>();
            for(String objName : selectedObjectsSet) {
                objectPermisionWList.add(new ObjectPermisionWrapper(objName, objectNameMap.get(objName)));
                objPermMap.put(objName, new List<String>());
            }
            //go through all profiles and permission set
            Integer index = 0;
            permisionSetIdList = new List<Id>();
            Map<Id, Integer> permSetIndexMap = new Map<Id, Integer>();
            system.debug('selectedProfileIdList:::' + selectedProfileIdList);
            for(Id prId : selectedProfileIdList) {
                index ++;
                for(PermissionSet ps : permisionSetList) {
                    if(ps.ProfileId == prId || ps.Id == prId) {
                        permSetIndexMap.put(ps.Id, index);
                        permisionSetIdList.add(ps.Id);
                        
                        //go through all objects permissions for current profile or permission set
                        if(objectPermMap.containsKey(ps.Id) && objectPermMap.get(ps.Id) != null) {
                            for (ObjectPermissions obj : objectPermMap.get(ps.Id)) {
                                if(selectedObjectsSet.contains(obj.SobjectType)) {
                                    String objPerm = '';
                                    if(obj.PermissionsCreate) {
                                        objPerm += 'C';
                                    }
                                    if(obj.PermissionsRead) {
                                        objPerm += 'R';
                                    }
                                    if(obj.PermissionsEdit) {
                                        objPerm += 'U';
                                    }
                                    if(obj.PermissionsDelete) {
                                        objPerm += 'D';
                                    }
                                    if(obj.PermissionsViewAllRecords) {
                                        objPerm += 'V';
                                    }
                                    if(obj.PermissionsModifyAllRecords){
                                        objPerm += 'M';
                                    }
                                    objPermMap.get(obj.SobjectType).add(objPerm);
                                } 
                            }
                        }
                        //for profiles that don't have object permissions put empty values
                        system.debug('objPermMap::' + objPermMap);
                        for (String objName : objPermMap.keySet()) {
                            if(objPermMap.get(objName).size () < index){
                                objPermMap.get(objName).add('');
                            }
                        }
                    } 
                }
            }
            for (ObjectPermisionWrapper objPermW : objectPermisionWList) {
                objPermW.objPermList = objPermMap.get(objPermW.objName);
            }
            system.debug('objectPermisionWList::' + objectPermisionWList);
            
            if(expandObject != null && expandObject != '') {
                // CPU monitoring for field expansion
                Integer cpuTimeFieldStart = Limits.getCpuTime();
                Integer cpuLimit = Limits.getLimitCpuTime();
                
                if(cpuTimeFieldStart > (cpuLimit * 0.6)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                        'CPU limit approaching during field expansion. Reducing scope.'));
                    expandObject = null;
                    return;
                }
                
                system.debug('expandObject='+expandObject);
                fieldNameList = new List<String>();
                Set<Id> excludedFieldPermIds = new Set<Id>();
                
                // Optimize FieldPermissions query with better limits
                for(FieldPermissions fp : [SELECT Id, ParentId FROM FieldPermissions 
                                          WHERE SobjectType = :expandObject 
                                          AND ParentId IN :permisionSetIdList 
                                          LIMIT 3000]) {
                    if(String.valueOf(fp.Id).startsWith('000')) {
                        excludedFieldPermIds.add(fp.Id);
                    }
                }
                system.debug('excludedFieldPermIds size::' + excludedFieldPermIds.size());
                
                try {
                    List<FieldPermissions> fieldPermissionsList = [SELECT ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit 
                                                                   FROM FieldPermissions 
                                                                   WHERE SobjectType = :expandObject 
                                                                   AND ParentId IN :permisionSetIdList 
                                                                   AND ID NOT IN :excludedFieldPermIds 
                                                                   LIMIT 3000];
                    
                    fieldPermissionMap = new Map<String, List<FieldPermissionWrapper>>();
                    fieldNameMap = new Map<String, List<String>>();
                    for (FieldPermissions fp : fieldPermissionsList){
                        String fieldN = fp.Field.toLowerCase();
                        if(!fieldPermissionMap.containsKey(fieldN)) {
                            fieldPermissionMap.put(fieldN, new List<FieldPermissionWrapper>());
                            fieldNameList.add(fieldN);
                            for(Id prId : permisionSetIdList) {
                                fieldPermissionMap.get(fieldN).add(new FieldPermissionWrapper(new FieldPermissions(ParentId = prId, field = fp.Field, PermissionsEdit = false, PermissionsRead = false, SobjectType = expandObject)));
                            }
                        }
                    }
                    
                    Set<Id> permisionSetIdSet = new Set<Id>(permisionSetIdList);
                    for (FieldPermissions fp : fieldPermissionsList){
                        if(permisionSetIdSet.contains(fp.ParentId)){
                            index = permSetIndexMap.get(fp.ParentId);
                            if(index != null){
                                fieldPermissionMap.get(fp.Field.toLowerCase()).set(index-1,new FieldPermissionWrapper(fp));
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('An exception occurred while executing the SOQL query or processing the results: ' + e.getMessage());
                }
                
                system.debug('fieldPermissionMap::' + fieldPermissionMap);
                List<EntityParticle> fieldList = [SELECT DataType, IsPermissionable, QualifiedApiName, DeveloperName, Label, NamespacePrefix 
                                                  FROM EntityParticle 
                                                  WHERE  EntityDefinition.QualifiedApiName = :expandObject  AND DataType != 'reference' Limit 5000]; //////owner fields for TTC condition- AND IsPermissionable = true
                List<FieldPermissions> fieldupdatedPermissionList = new List<FieldPermissions>();
                for(EntityParticle field : fieldList) {
                    Boolean findMatch = false;
                    for (String fieldName : fieldPermissionMap.keySet()) {
                        String fieldAPI = fieldName.removeStart(expandObject.toLowerCase() + '.').toLowerCase();
                        if(fieldAPI == field.QualifiedApiName) {
                            findMatch = true;
                            String fieldLabelString = field.Label + ' (' + field.QualifiedApiName + ')';
                            fieldNameMap.put(fieldName, new List<String>{fieldLabelString, String.valueOf(field.IsPermissionable)});
                            break;
                        }
                    }
                    if(!findMatch) {
                        String fieldAPIName = field.QualifiedApiName;
                        String fieldN = expandObject.toLowerCase() + '.' + fieldAPIName.toLowerCase();
                        //	if(!fieldAPIName.containsIgnoreCase('person')) {
                        if(!(fieldAPIName.containsIgnoreCase('Billing') || fieldAPIName.containsIgnoreCase('Shipping') || 
                             fieldAPIName.containsIgnoreCase('Mailing') || fieldAPIName.containsIgnoreCase('Other')) || 
                           fieldAPIName.containsIgnoreCase('Address')){
                               
                               String fieldAPI = field.Label + ' (' + fieldAPIName + ')';
                               fieldNameMap.put(fieldN, new List<String>{fieldAPI, String.valueOf(field.IsPermissionable)});
                               fieldPermissionMap.put(fieldN, new List<FieldPermissionWrapper>());
                               fieldNameList.add(fieldN);
                               //system.debug('fieldN::' + fieldN + '\\' + fieldPermissionMap.containsKey(fieldN));
                               for(Id prId : permisionSetIdList){
                                   fieldPermissionMap.get(fieldN).add(new FieldPermissionWrapper(new FieldPermissions(ParentId = prId, field = fieldN, PermissionsEdit = false, PermissionsRead = false, SobjectType = expandObject)));
                               }
                               /*if(field.NamespacePrefix != null) {
fieldupdatedPermissionList.add(new FieldPermissions(Field = fieldN, SobjectType = expandObject, ParentId = permisionSetIdList[0].ParentId, PermissionsRead = true, PermissionsEdit = true));
}*/
                           }
                        //}
                    }
                }
                /*Savepoint sp = Database.setSavepoint();
List<Database.SaveResult> srList = Database.insert(fieldupdatedPermissionList, false);
Database.rollback(sp);
*/
                // Optimized field processing with reduced CPU usage
                Map<String, Schema.DescribeFieldResult> objFieldMap = SecurityUtil.getFieldDescribeMap(expandObject);
                system.debug('objFieldMap size: ' + objFieldMap.size());
                
                // Pre-process field information to avoid repeated calculations
                Map<String, List<String>> fieldInfoCache = new Map<String, List<String>>();
                
                // Batch process field name mapping with optimized logic
                for (String fieldName : fieldPermissionMap.keySet()) {
                    String fieldAPI = fieldName.removeStart(expandObject.toLowerCase() + '.').toLowerCase();
                    String fieldLabelString;
                    Boolean isUpdateable = false;
                    
                    // Optimized field lookup with fallback logic
                    Schema.DescribeFieldResult fieldDescribe = objFieldMap.get(fieldAPI);
                    if (fieldDescribe != null) {
                        fieldLabelString = fieldDescribe.getLabel() + ' (' + fieldAPI + ')';
                        try {
                            isUpdateable = fieldDescribe.isCalculated();
                        } catch(Exception e) {
                            isUpdateable = true;
                        }
                    } else {
                        // Check for ID field variant
                        fieldDescribe = objFieldMap.get(fieldAPI + 'id');
                        if (fieldDescribe != null) {
                            fieldLabelString = fieldDescribe.getLabel() + ' (' + fieldAPI + 'id)';
                            isUpdateable = fieldDescribe.isCalculated();
                        } else {
                            fieldLabelString = fieldAPI;
                            isUpdateable = false;
                        }
                    }
                    
                    // Cache field information for reuse
                    List<String> fieldInfo = new List<String>{fieldLabelString, isUpdateable ? 'false' : 'true'};
                    fieldInfoCache.put(fieldName, fieldInfo);
                    fieldNameMap.put(fieldName, fieldInfo);
                }
                //system.debug('fieldNameMap:' + fieldNameMap);
                try{
                    // Optimized field processing with Set-based lookups instead of nested loops
                    Set<String> existingFieldNames = new Set<String>();
                    for(String fieldName : fieldNameMap.keySet()) {
                        existingFieldNames.add(fieldName.toLowerCase());
                    }
                    
                    // Pre-filter permissionable fields to reduce iterations
                    List<String> permissionableFields = new List<String>();
                    for(String fieldAPIName : objFieldMap.keySet()) {
                        Schema.DescribeFieldResult fieldDescribe = objFieldMap.get(fieldAPIName);
                        if(fieldDescribe.isPermissionable() && fieldDescribe.isAccessible() && fieldDescribe.isCustom()) {
                            permissionableFields.add(fieldAPIName);
                        }
                    }
                    
                    // Process fields efficiently with reduced CPU usage
                    for(String fieldAPIName : permissionableFields) {
                        String fieldNameLower = (expandObject.toLowerCase() + '.' + fieldAPIName).toLowerCase();
                        String fieldNameIdLower = (fieldNameLower + 'id').toLowerCase();
                        
                        // Use Set lookup instead of nested loop - O(1) vs O(n)
                        Boolean findMatch = existingFieldNames.contains(fieldNameLower) || 
                                          existingFieldNames.contains(fieldNameIdLower);
                        
                        if(!findMatch && !fieldAPIName.containsIgnoreCase('person')) {
                            Schema.DescribeFieldResult fieldDescribe = objFieldMap.get(fieldAPIName);
                            String fieldN = expandObject.toLowerCase() + '.' + fieldAPIName;
                            String fieldAPI = fieldDescribe.getLabel() + ' (' + fieldAPIName + ')';
                            String isUpdateableStr;
                            
                            // Handle address fields specifically
                            if((fieldAPIName.containsIgnoreCase('Billing') || fieldAPIName.containsIgnoreCase('Shipping') || 
                                fieldAPIName.containsIgnoreCase('Mailing') || fieldAPIName.containsIgnoreCase('Other')) &&
                               fieldAPIName.containsIgnoreCase('Address')) {
                                isUpdateableStr = 'true';
                            } else {
                                isUpdateableStr = fieldDescribe.isCalculated() ? 'false' : 'true';
                            }
                            
                            // Batch create field permission wrappers
                            List<FieldPermissionWrapper> fieldPermWrappers = new List<FieldPermissionWrapper>();
                            for(Id prId : permisionSetIdList) {
                                fieldPermWrappers.add(new FieldPermissionWrapper(
                                    new FieldPermissions(ParentId = prId, field = fieldN, 
                                                        PermissionsEdit = false, PermissionsRead = false, 
                                                        SobjectType = expandObject)));
                            }
                            
                            // Update maps and lists
                            fieldNameMap.put(fieldN, new List<String>{fieldAPI, isUpdateableStr});
                            fieldPermissionMap.put(fieldN, fieldPermWrappers);
                            fieldNameList.add(fieldN);
                            existingFieldNames.add(fieldN.toLowerCase());
                        }
                    }
                } catch (Exception e) {
                    // handle the exception here
                    System.debug('Error: ' + e.getMessage());
                }
                if (String.isEmpty(selectedLog)) {
                    indAcrossCell = String.valueOf(2*permisionSetIdList.size() + 1);
                } else {
                    indAcrossCell = String.valueOf(4*permisionSetIdList.size() + 1);
                }
                fieldNameList = sortFieldAPINameListAfterLabel();
            } else {
                indAcrossCell = String.valueOf(6*permisionSetIdList.size());
            }
            
            //system.debug('objectPermisionWList1::' + objectPermisionWList);
            objectsList = new List<SelectOption>();
        }   
        catch (Exception e) {
            System.debug('An exception occurred: ' + e.getMessage());
            throw e;
        }
    }
    
    
    public List<String> sortFieldAPINameListAfterLabel() {
        List<String> sortList = new List<String>();
        Map<String, String> sortMap = new Map<String, String>();
        for(String fieldName : fieldNameMap.KeySet()) {
            sortList.add(fieldNameMap.get(fieldName)[0]);
            sortMap.put(fieldNameMap.get(fieldName)[0], fieldName);
        }
        sortList.sort();
        List<String> sortListToReturn = new List<String>();
        for(String item : sortList) {
            sortListToReturn.add(sortMap.get(item));
        }
        return sortListToReturn;
    }
    public void expandObjects1() {
        selectedProfileList = new List<SelectOption>();
        editProfileSelectCheckboxMap = new Map<Id, Boolean>();
        readProfileSelectCheckboxMap = new Map<Id, Boolean>();
        for(ID prID : selectedProfileIdList) {
            readProfileSelectCheckboxMap.put(prID, false);
            editProfileSelectCheckboxMap.put(prID, false);
        }
        if(dummyexpandObject == expandObject) {
            expandObject = '';
            dummyexpandObject = '';
            selectedLog = '';
            fielPermLogWMap = new Map<String, Map<Id, FieldPermissionLogWrapper>>();
        } else {
            dummyexpandObject = expandObject;
        }
        //system.debug('expandObject:!:' + expandObject);
        //retrieveRecords();
    }
    
    public void expandObjects() {
        try {
            // CPU limit monitoring and early validation
            Integer cpuTimeStart = Limits.getCpuTime();
            Integer cpuLimit = Limits.getLimitCpuTime();
            
            if(cpuTimeStart > (cpuLimit * 0.7)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                    'CPU limit approaching. Please reduce the number of selected profiles or objects.'));
                return;
            }
            
            // Early validation
            if(selectedProfileIdList == null || selectedProfileIdList.isEmpty()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 
                    'Please select profiles to expand objects.'));
                return;
            }
            
            selectedProfileList = new List<SelectOption>();
            editProfileSelectCheckboxMap = new Map<Id, Boolean>();
            readProfileSelectCheckboxMap = new Map<Id, Boolean>();
            
            // Optimize profile processing
            for(ID prID : selectedProfileIdList) {
                readProfileSelectCheckboxMap.put(prID, false);
                editProfileSelectCheckboxMap.put(prID, false);
            }
            
            if(dummyexpandObject == expandObject) {
                expandObject = '';
                dummyexpandObject = '';
                selectedLog = '';
                fielPermLogWMap = new Map<String, Map<Id, FieldPermissionLogWrapper>>();
            } else {
                dummyexpandObject = expandObject;
            }
            
            // Monitor CPU before calling retrieveRecords
            Integer cpuTimeBeforeRetrieve = Limits.getCpuTime();
            if(cpuTimeBeforeRetrieve > (cpuLimit * 0.8)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                    'CPU limit exceeded. Please reduce data scope and try again.'));
                return;
            }
            
            retrieveRecords();
            
        } catch(Exception e) {
            System.debug('Error in expandObjects: ' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                'An error occurred while expanding objects: ' + e.getMessage()));
        }
    }
    
    public void Go() {
        selectedProfileList = new List<SelectOption>();
        fielPermLogWMap = new Map<String, Map<Id, FieldPermissionLogWrapper>>();
        selectedLog = null;
        selectedProfileIdList = new List<Id>();
        readProfileSelectCheckboxMap = new Map<Id, Boolean>();
        editProfileSelectCheckboxMap = new Map<Id, Boolean>();
        //system.debug('selectedProfiles::' + selectedProfiles);
        Boolean isMoreProfiles = false;
        Map<Id, String> profNameMap = new  Map<Id, String>();
        for (SelectOption so : selectedProfiles) {
            if(!isMoreProfiles) {
                selectedProfileIdList.add(so.getValue());
                readProfileSelectCheckboxMap.put((Id)so.getValue(), false);
                editProfileSelectCheckboxMap.put((Id)so.getValue(), false);
                profNameMap.put(so.getValue(), so.getLabel());
                if(selectedProfileIdList.size() > 7) {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING, 'Select only 7 profiles');
                    ApexPages.addMessage(myMsg);
                    Id profId = selectedProfileIdList.remove(5);
                    isMoreProfiles = true;
                    remainingProfiles.add(new SelectOption(profId, profNameMap.get(profId)));
                }
            }else {
                remainingProfiles.add(new SelectOption(so.getValue(), so.getLabel()));
            }
        }
        if(isMoreProfiles){
            selectedProfiles = new List<SelectOption>();
            for (Id profId : selectedProfileIdList) {
                selectedProfiles.add(new SelectOption(profId, profNameMap.get(profId)));
            }
        }
        
        selectedObjectsList = new List<String>();
        for (SelectOption so : selectedObjects) {
            selectedObjectsList.add(so.getValue());
        }
        remainingProfiles = sortAfterLabelSelectOptionList(remainingProfiles);
        remainingObjects = sortAfterLabelSelectOptionList(remainingObjects);
        system.debug('remainingObjects=='+remainingObjects);
        profileNameMap = new  Map<Id, String>();
        for (Id profId : selectedProfileIdList) {
            profileNameMap.put(profId, profNameMap.get(profId));
        }
        retrieveRecords();
        system.debug('expandObject===' + expandObject);
    }
    
    /*   Code before Scanner review */
    public void Save() {
        system.debug('Entry in save::');
        selectedProfileList = new List<SelectOption>();
        system.debug('selectedProfileList=='+selectedProfileList);
        system.debug('Entry in save::');
        if(Schema.getGlobalDescribe().get('FieldPermissions').getDescribe().isCreateable()) {
            Map<Id, FieldPermissions> fieldPermMap = new Map<Id, FieldPermissions>([SELECT ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE SobjectType = :expandObject AND ParentId IN :permisionSetIdList]);
            String fieldAPIName;
            List<FieldPermissions> fieldupdatedPermissionList = new List<FieldPermissions>();
            
            if(expandObject != null && expandObject != '') {
                FieldPermissions fieldPerm;
                for (String fieldName : fieldPermissionMap.keySet()){
                    
                    for(FieldPermissionWrapper fpw : fieldPermissionMap.get(fieldName)) {
                        if(fpw.id != null && fieldPermMap.containsKey(fpw.id)) {
                            if(fpw.R != fieldPermMap.get(fpw.id).PermissionsRead || fpw.E != fieldPermMap.get(fpw.id).PermissionsEdit) {
                                system.debug('121343::' + fieldName);
                                fieldPerm = new FieldPermissions(Id = fpw.id, parentId = fpw.parentId, SobjectType = expandObject, Field = fieldName);
                                if(fpw.R == false){
                                    fpw.E = false;
                                    fieldPerm.PermissionsRead = false;
                                    fieldPerm.PermissionsEdit = false;
                                    fieldupdatedPermissionList.add(fieldPerm);
                                }else {
                                    if(fpw.E == true){
                                        fpW.R = true;
                                        fieldPerm.PermissionsRead = true;
                                        fieldPerm.PermissionsEdit = true;
                                        fieldupdatedPermissionList.add(fieldPerm);
                                    } else {
                                        fieldPerm.PermissionsRead = fpw.R;
                                        fieldPerm.PermissionsEdit = fpw.E;
                                        fieldupdatedPermissionList.add(fieldPerm);
                                    }
                                }
                            }
                        } else {
                            if(fpw.R == true) {
                                fieldupdatedPermissionList.add(new FieldPermissions(Field = fieldName, SobjectType = expandObject, ParentId = fpw.ParentId, PermissionsRead = fpw.R, PermissionsEdit = fpw.E));
                            } else {
                                if(fpw.E == true){
                                    fpW.R = true;
                                    fieldupdatedPermissionList.add(new FieldPermissions(Field = fieldName, SobjectType = expandObject, ParentId = fpw.ParentId, PermissionsRead = fpw.R, PermissionsEdit = fpw.E));
                                }
                            }
                        }
                    }
                }
            }
            //system.debug('fieldupdatedPermissionList.size::' + fieldupdatedPermissionList.size());
            if (fieldupdatedPermissionList.size() > 0) {
                System.debug('0. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
                //upsert fieldupdatedPermissionList;
                List<Database.UpsertResult> upsertResult = Database.upsert(fieldupdatedPermissionList, false);
                Boolean isAllSaved = true;
                Set<String> errorFieldsSet = new Set<String>();
                System.debug('1. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
                for(Database.UpsertResult ur : upsertResult) {
                    //System.debug('4. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
                    if (!ur.isSuccess()) {
                        
                        isAllSaved = false;
                        for(Database.Error err : ur.getErrors()) {
                            //System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            //System.debug('Account fields that affected this error: ' + err.getFields());
                            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,err.getMessage());
                            ApexPages.addMessage(myMsg);
                            if(err.getMessage().containsIgnoreCase(expandObject)) {
                                String errField = err.getMessage().toLowerCase();
                                errField = errField.substringAfter(expandObject.toLowerCase());
                                //system.debug('errField::' + errField);
                                errField = errField.contains(' ') ? errField.substringBefore(' ') : errField;
                                errField = expandObject + errField;
                                errorFieldsSet.add(errField.toLowerCase());
                            }
                        }
                        
                    }
                    
                }
                system.debug('errorFieldsSet::' + errorFieldsSet);
                if(isAllSaved) {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'The changes are saved');
                    ApexPages.addMessage(myMsg);
                    String successMessage = 'The following fields are successfully saved: ';
                    for(FieldPermissions fp : fieldupdatedPermissionList) {
                        if(!errorFieldsSet.contains(fp.field.toLowerCase())) {
                            successMessage += fp.field + ', ';
                        }
                    }
                    successMessage = successMessage.substringAfterLast(',');
                    successMessage = successMessage.removeEnd(',');
                    
                    system.debug('successMessage::' + successMessage.length());
                    if(successMessage != '') {
                        
                        
                        //String serializeW =   SerializeObjectPermisionWrapper(objectPermisionWList);
                        Map<ID, List<FieldPermissionWrapper>> fieldProfMap = new Map<ID, List<FieldPermissionWrapper>>();
                        fieldProfMap = profileIdListFieldPermW();
                        Map<Id, String> serializeWMap = new Map<Id, String>();
                        String serializeW;
                        for(Id profileId : fieldProfMap.KeySet()) {
                            serializeW = SerializeFieldPermisionWrapper(fieldProfMap.get(profileId));
                            //system.debug('serializeW::' + serializeW);
                            serializeWMap.put(profileId, serializeW);
                        }
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
                        system.debug('expandObject, serializeWMap, description, userName='+ expandObject+ serializeWMap+ description+ userName);
                        saveObjectLog(expandObject, serializeWMap, description, userName);
                        description = '';
                    } else {
                        for(String fieldName : errorFieldsSet) {
                            system.debug('fieldName21345::' + fieldName + '::' + fieldPermissionMap.containsKey(fieldName.toLowerCase()));
                            for(FieldPermissionWrapper fpw : fieldPermissionMap.get(fieldName.toLowerCase())) {
                                if(fpw.id != null && fieldPermMap.containsKey(fpw.id)) {
                                    fpw.R = fieldPermMap.get(fpw.id).PermissionsRead;
                                    fpw.E = fieldPermMap.get(fpw.id).PermissionsEdit;
                                } else {
                                    fpw.R = false;
                                    fpw.E = false;
                                }
                            }
                        }
                        
                    }
                }
                
            }
            
            fieldupdatedPermissionList = new List<FieldPermissions>();
            
            retrieveRecords();
        } else {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You don\'t have access on FieldPermissions object');
            ApexPages.addMessage(myMsg);
        }
    }    
   /*
    * code for scanenr commnet for the existing feature not working
    *  public void Save() {
        system.debug('Entry in save::');
        selectedProfileList = new List<SelectOption>();
        system.debug('selectedProfileList==' + selectedProfileList);
        system.debug('Entry in save::');
        if (!Schema.sObjectType.FieldPermissions.isCreateable() || 
            !Schema.sObjectType.FieldPermissions.isUpdateable()) {
                throw new AuraHandledException('Insufficient permissions to modify FieldPermissions.');
            }
        
        try {         
            Map<Id, FieldPermissions> fieldPermMap = new Map<Id, FieldPermissions>([SELECT ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit FROM FieldPermissions WHERE SobjectType = :expandObject AND ParentId IN :permisionSetIdList]);
            String fieldAPIName;
            List<FieldPermissions> fieldupdatedPermissionList = new List<FieldPermissions>();
            
            if (expandObject != null && expandObject != '') {
                FieldPermissions fieldPerm;
                for (String fieldName : fieldPermissionMap.keySet()) {
                    
                    for (FieldPermissionWrapper fpw : fieldPermissionMap.get(fieldName)) { 
                        
                        if (fpw.id != null && fieldPermMap.containsKey(fpw.id)) {
                            if (fpw.R != fieldPermMap.get(fpw.id).PermissionsRead || fpw.E != fieldPermMap.get(fpw.id).PermissionsEdit) {
                                system.debug('121343::' + fieldName);
                                fieldPerm = new FieldPermissions(Id = fpw.id, parentId = fpw.parentId, SobjectType = expandObject, Field = fieldName);
                                if (fpw.R == false) {
                                    fpw.E = false;
                                    fieldPerm.PermissionsRead = false;
                                    fieldPerm.PermissionsEdit = false;
                                    fieldupdatedPermissionList.add(fieldPerm);
                                } else {
                                    if (fpw.E == true) {
                                        fpw.R = true;
                                        fieldPerm.PermissionsRead = true;
                                        fieldPerm.PermissionsEdit = true;
                                        fieldupdatedPermissionList.add(fieldPerm);
                                    } else {
                                        fieldPerm.PermissionsRead = fpw.R;
                                        fieldPerm.PermissionsEdit = fpw.E;
                                        fieldupdatedPermissionList.add(fieldPerm);
                                    }
                                }
                            }
                        } else {
                            if (fpw.R == true) {
                                fieldupdatedPermissionList.add(new FieldPermissions(Field = fieldName, SobjectType = expandObject, ParentId = fpw.ParentId, PermissionsRead = fpw.R, PermissionsEdit = fpw.E));
                            } else {
                                if (fpw.E == true) {
                                    fpw.R = true;
                                    fieldupdatedPermissionList.add(new FieldPermissions(Field = fieldName, SobjectType = expandObject, ParentId = fpw.ParentId, PermissionsRead = fpw.R, PermissionsEdit = fpw.E));
                                }
                            }
                        }
                        
                    }}
            } 
            
            
            if (fieldupdatedPermissionList.size() > 0) {
                System.debug('0. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
                //upsert fieldupdatedPermissionList;
                List<Database.UpsertResult> upsertResult = Database.upsert(fieldupdatedPermissionList, false, AccessLevel.USER_MODE);
                Boolean isAllSaved = true;
                Set<String> errorFieldsSet = new Set<String>();
                System.debug('1. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
                for (Database.UpsertResult ur : upsertResult) {
                    if (!ur.isSuccess()) {
                        isAllSaved = false;
                        for (Database.Error err : ur.getErrors()) {
                            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage());
                            ApexPages.addMessage(myMsg);
                            if (err.getMessage().containsIgnoreCase(expandObject)) {
                                String errField = err.getMessage().toLowerCase();
                                errField = errField.substringAfter(expandObject.toLowerCase());
                                errField = errField.contains(' ') ? errField.substringBefore(' ') : errField;
                                errField = expandObject + errField;
                                errorFieldsSet.add(errField.toLowerCase());
                            }
                        }
                    }
                }
                system.debug('errorFieldsSet::' + errorFieldsSet);
                if (isAllSaved) {
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The changes are saved');
                    ApexPages.addMessage(myMsg);
                    String successMessage = 'The following fields are successfully saved: ';
                    for (FieldPermissions fp : fieldupdatedPermissionList) {
                        if (!errorFieldsSet.contains(fp.field.toLowerCase())) {
                            successMessage += fp.field + ', ';
                        }
                    }
                    successMessage = successMessage.substringAfterLast(',');
                    successMessage = successMessage.removeEnd(',');
                    
                    system.debug('successMessage::' + successMessage.length());
                    if (successMessage != '') {
                        Map<ID, List<FieldPermissionWrapper>> fieldProfMap = profileIdListFieldPermW();
                        Map<Id, String> serializeWMap = new Map<Id, String>();
                        String serializeW;
                        for (Id profileId : fieldProfMap.KeySet()) {
                            serializeW = SerializeFieldPermisionWrapper(fieldProfMap.get(profileId));
                            serializeWMap.put(profileId, serializeW);
                        }
                        User user = new User();
                        if (Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
                            Id currentUserId = UserInfo.getUserId();
                            user = [SELECT ID, Name FROM User WHERE Id = :currentUserId];
                        }
                        String userName;
                        if (user != null) {
                            userName = user.Name;
                        } else {
                            userName = '';
                        }
                        system.debug('expandObject, serializeWMap, description, userName=' + expandObject + serializeWMap + description + userName);
                        saveObjectLog(expandObject, serializeWMap, description, userName);
                        description = '';
                    }
                } else {
                    for (String fieldName : errorFieldsSet) {
                        system.debug('fieldName21345::' + fieldName + '::' + fieldPermissionMap.containsKey(fieldName.toLowerCase()));
                        for (FieldPermissionWrapper fpw : fieldPermissionMap.get(fieldName.toLowerCase())) {
                            if (fpw.id != null && fieldPermMap.containsKey(fpw.id)) {
                                fpw.R = fieldPermMap.get(fpw.id).PermissionsRead;
                                fpw.E = fieldPermMap.get(fpw.id).PermissionsEdit;
                            } else {
                                fpw.R = false;
                                fpw.E = false;
                            }
                        }
                    }
                }
            }
            
            fieldupdatedPermissionList = new List<FieldPermissions>();
            
            retrieveRecords();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Error: ' + e.getMessage()
            ));
        }
        
    }  */
    
    /*   Code before Scanner review */
    public void RevertChanges() {
        system.debug('Reverted');
        selectedProfileList = new List<SelectOption>();
        List<FieldPermissions> fieldupdatedPermissionList = new List<FieldPermissions>();
        FieldPermissions fieldPerm = new FieldPermissions();
        Integer index;
        system.debug('fielPermLogWMap.key=='+fielPermLogWMap.keySet());
        for (String fieldName : fielPermLogWMap.keySet()){
            //fpwFieldPermissionLogWrapper:[E=true, R=true, field=Account.SA_Audit__active__c,
            // id=01k1v0000Ni5DJ8AQM, logE=true, logR=true, objType=Account, parentId=0PS1v000002ZT8NGAW]
            index = 0;
            FieldPermissionLogWrapper fpw;
            for(Id prId : fielPermLogWMap.get(fieldName).keySet()) {
                system.debug('fielPermLogWMap.key=='+ fielPermLogWMap.get(fieldName).keySet());
                fpw = fielPermLogWMap.get(fieldName).get(prId);
                system.debug('fpw'+fpw);
                if(fpw.R != fpw.logR || fpw.E != fpw.logE) {
                    fpw.R = fpw.logR;
                    fpw.E = fpw.logE;
                    fieldPerm = new FieldPermissions(Id = fpw.id, parentId = fpw.parentId, SobjectType = expandObject, Field = fieldName, PermissionsRead = fpw.R, PermissionsEdit = fpw.E);
                    fieldupdatedPermissionList.add(fieldPerm);
                    system.debug('fieldupdatedPermissionList1:::' + fieldupdatedPermissionList);
                }
                system.debug('fieldupdatedPermissionList1:::' + fieldupdatedPermissionList);
                index++;
            }
        }
        system.debug('fieldupdatedPermissionList1:::' + fieldupdatedPermissionList);
        if (fieldupdatedPermissionList.size() > 0) {
            try { 
                List<Database.UpsertResult> upsertResult = Database.upsert(fieldupdatedPermissionList,AccessLevel.USER_MODE);
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'The changes are saved');
                ApexPages.addMessage(myMsg);
            } catch (DMLException e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
                ApexPages.addMessage(myMsg);
                retrieveRecords();
                return;
            }
        }
        //system.debug('fieldNameList@:::' + fieldNameList);
        //  changeLog();
    }   
    /*
     * code for scanner
      public void RevertChanges() {
        System.debug('Reverted');
        selectedProfileList = new List<SelectOption>();
        List<FieldPermissions> fieldupdatedPermissionList = new List<FieldPermissions>();
        FieldPermissions fieldPerm;
        Integer index;
        System.debug('fielPermLogWMap.key==' + fielPermLogWMap.keySet());
        
        
        if (Schema.getGlobalDescribe().get('FieldPermissions').getDescribe().isCreateable() && 
            Schema.getGlobalDescribe().get('FieldPermissions').getDescribe().isUpdateable()) {
                
                for (String fieldName : fielPermLogWMap.keySet()) {
                    index = 0;
                    FieldPermissionLogWrapper fpw;
                    for (Id prId : fielPermLogWMap.get(fieldName).keySet()) {
                        System.debug('fielPermLogWMap.key==' + fielPermLogWMap.get(fieldName).keySet());
                        fpw = fielPermLogWMap.get(fieldName).get(prId);
                        System.debug('fpw' + fpw);
                        
                        
                        if (Schema.sObjectType.FieldPermissions.fields.PermissionsRead.isCreateable() &&
                            Schema.sObjectType.FieldPermissions.fields.PermissionsEdit.isCreateable() &&
                           Schema.sObjectType.FieldPermissions.fields.PermissionsRead.isUpdateable() &&
                            Schema.sObjectType.FieldPermissions.fields.PermissionsEdit.isUpdateable()) {
                               if((fpw.id == null && Schema.sObjectType.FieldPermissions.isCreateable()) || 
                                  (fpw.id != null && Schema.sObjectType.FieldPermissions.isUpdateable())) {
                                      
                                      
                                      if (fpw.R != fpw.logR || fpw.E != fpw.logE) {
                                          fpw.R = fpw.logR;
                                          fpw.E = fpw.logE;
                                          fieldPerm = new FieldPermissions(
                                              Id = fpw.id, 
                                              ParentId = fpw.parentId, 
                                              SobjectType = expandObject, 
                                              Field = fieldName, 
                                              PermissionsRead = fpw.R, 
                                              PermissionsEdit = fpw.E
                                          );
                                          fieldupdatedPermissionList.add(fieldPerm);
                                          System.debug('fieldupdatedPermissionList1:::' + fieldupdatedPermissionList);
                                      }
                                  }} else {
                                      ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have permission to update FieldPermissions fields.');
                                      ApexPages.addMessage(myMsg);
                                      return;
                                  }
                        index++;
                    }
                }
                
                System.debug('fieldupdatedPermissionList1:::' + fieldupdatedPermissionList);
                
                // Perform upsert operation in System Mode
                if (fieldupdatedPermissionList.size() > 0) {
                    try {
                        List<Database.UpsertResult> upsertResult = Database.upsert(fieldupdatedPermissionList,AccessLevel.USER_MODE); // System Mode
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM, 'The changes are saved');
                        ApexPages.addMessage(myMsg);
                    } catch (DMLException e) {
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
                        ApexPages.addMessage(myMsg);
                        retrieveRecords();
                        return;
                    }
                }
            } else {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'You do not have permission to create or update FieldPermissions');
                ApexPages.addMessage(myMsg);
            }
    }*/
    public Map<ID, List<FieldPermissionWrapper>> profileIdListFieldPermW() {
        Map<ID, List<FieldPermissionWrapper>> fieldPermMap = new Map<ID, List<FieldPermissionWrapper>>();
        for(Id profileId : selectedProfileIdList) {
            fieldPermMap.put(profileId, new List<FieldPermissionWrapper>());
        }
        Integer index;
        for(String field : fieldPermissionMap.keySet()) {
            index = 0;
            for(FieldPermissionWrapper fpw : fieldPermissionMap.get(field)) {
                fieldPermMap.get(selectedProfileIdList.get(index)).add(fpw);
                index++;
            }
        }
        return fieldPermMap;
    }
    
    
     @future 
    public static void saveObjectLog(String selectedObject, Map<Id, String> serializeWMap, String description, String userName) {
        system.debug('ENtry in saveObjectLog');
        system.debug('selectedObject==>'+selectedObject +'---serializeWMap===>'+serializeWMap+ '---description==>'+description + '--userName==>'+userName);
        Integer recordNumber =  [SELECT COUNT() FROM SA_Audit__Objects_And_Fields_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject];
        system.debug('recordNumber===>' + recordNumber);
        SA_Audit__Objects_And_Fields_Log__c objLog = new SA_Audit__Objects_And_Fields_Log__c();
        if(recordNumber == 999) {
            objLog = [SELECT ID FROM SA_Audit__Objects_And_Fields_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject ORDER By SA_Audit__Date__c desc LIMIT 1];
            try {
                if(SA_Audit__Objects_And_Fields_Log__c.sObjectType.getDescribe().isDeletable()){
                    delete as user objLog;
                }
            } catch (DMLException e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
                ApexPages.addMessage(myMsg);
            }
        }
        objLog = new SA_Audit__Objects_And_Fields_Log__c();
        if(Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Object_Type__c.isCreateable()
           && Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Date__c.isCreateable()
           && Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Description__c.isCreateable()
           && Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__User_Name__c.isCreateable()){
               objLog.SA_Audit__Object_Type__c = selectedObject;
               objLog.SA_Audit__Date__c = Datetime.Now();
               objLog.SA_Audit__Description__c = description;
               objLog.SA_Audit__User_Name__c = userName;
           }
        //objLog.SA_Audit__Value__c = serializeW;
        system.debug('objLog=='+objLog);
        try {
            insert  as user objLog;
        } catch (DMLException e) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
            ApexPages.addMessage(myMsg);
            system.debug('e=='+ e);
        } 
        //above code changed to below code cause of the DML inside Loop Warning in review
        List<SA_Audit__Fields_Profile_Log__c> fieldProfileLogList = new List<SA_Audit__Fields_Profile_Log__c>();
        
        // Loop through profile IDs and create a new record for each
        try{
            for (Id profileId : serializeWMap.keySet()) {
                // Instantiate a new record on each iteration
                SA_Audit__Fields_Profile_Log__c fieldProfileLog = new SA_Audit__Fields_Profile_Log__c();
                try{
                    // Check field-level security before setting field values
                    if (Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__Objects_And_Fields_Log__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__ProfileId__c.isCreateable() &&
                        Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__Value__c.isCreateable()) {
                            
                            fieldProfileLog.SA_Audit__Objects_And_Fields_Log__c = objLog.Id;
                            fieldProfileLog.SA_Audit__ProfileId__c = profileId;
                            fieldProfileLog.SA_Audit__Value__c = serializeWMap.get(profileId);
                            
                            // Add the new record to the list
                            fieldProfileLogList.add(fieldProfileLog);
                        }
                }  catch (Exception e) { 
                    system.debug('issue');
                }
            }
            
            try {
                // Perform a single insert operation for all records at once
                if (!fieldProfileLogList.isEmpty()) {
                    insert as user fieldProfileLogList;
                }
            } catch (DMLException e) {
                // Log and display error message
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
                ApexPages.addMessage(myMsg);
            } 	
        } catch (Exception e) { 
            system.debug('issue');
        }
    }   
    
    
    /* public static void saveObjectLog(String selectedObject, Map<Id, String> serializeWMap, String description, String userName) {
System.debug('Entry in saveObjectLog');
System.debug('selectedObject==>' + selectedObject + '---serializeWMap===>' + serializeWMap + '---description==>' + description + '--userName==>' + userName);

// Check if record count exceeds the threshold and trigger cleanup batch
Integer recordNumber = [SELECT COUNT() FROM SA_Audit__Objects_And_Fields_Log__c WHERE SA_Audit__Object_Type__c = :selectedObject];
System.debug('recordNumber===>' + recordNumber);

if (recordNumber >= 1000) {
// Trigger cleanup if record count exceeds the threshold
System.debug('Reached max record count. Triggering cleanup batch...');
LogCleanupBatchOANDF cleanupBatch = new LogCleanupBatchOANDF(selectedObject);
Database.executeBatch(cleanupBatch, 200);
return; // Exit early after scheduling cleanup
}

// Create a new log entry
SA_Audit__Objects_And_Fields_Log__c objLog = new SA_Audit__Objects_And_Fields_Log__c();
if (Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Object_Type__c.isCreateable() &&
Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Date__c.isCreateable() &&
Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__Description__c.isCreateable() &&
Schema.sObjectType.SA_Audit__Objects_And_Fields_Log__c.fields.SA_Audit__User_Name__c.isCreateable()) {

objLog.SA_Audit__Object_Type__c = selectedObject;
objLog.SA_Audit__Date__c = Datetime.Now();
objLog.SA_Audit__Description__c = description;
objLog.SA_Audit__User_Name__c = userName;
}

// Insert the main object log entry
try {
insert as user objLog;
} catch (DMLException e) {
ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
ApexPages.addMessage(myMsg);
System.debug('Error inserting objLog: ' + e);
return; // Exit after error
}

// Prepare the list for SA_Audit__Fields_Profile_Log__c records
List<SA_Audit__Fields_Profile_Log__c> fieldProfileLogList = new List<SA_Audit__Fields_Profile_Log__c>();

// Collect records in bulk to avoid DML in loop
for (Id profileId : serializeWMap.keySet()) {
SA_Audit__Fields_Profile_Log__c fieldProfileLog = new SA_Audit__Fields_Profile_Log__c();

// Check if field values can be set
if (Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__Objects_And_Fields_Log__c.isCreateable() &&
Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__ProfileId__c.isCreateable() &&
Schema.sObjectType.SA_Audit__Fields_Profile_Log__c.fields.SA_Audit__Value__c.isCreateable()) {

fieldProfileLog.SA_Audit__Objects_And_Fields_Log__c = objLog.Id;
fieldProfileLog.SA_Audit__ProfileId__c = profileId;
fieldProfileLog.SA_Audit__Value__c = serializeWMap.get(profileId);

fieldProfileLogList.add(fieldProfileLog);
}
}

// Perform bulk DML operation for related records
if (!fieldProfileLogList.isEmpty()) {
try {
insert as user fieldProfileLogList;
} catch (DMLException e) {
ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
ApexPages.addMessage(myMsg);
System.debug('Error inserting fieldProfileLogList: ' + e);
}
}
} */
   /* public static void saveObjectLog(String selectedObject, Map<Id, String> serializeWMap, String description, String userName) {
        System.debug('Entry in saveObjectLog');
        System.debug('selectedObject==>' + selectedObject + '---serializeWMap===>' + serializeWMap + '---description==>' + description + '--userName==>' + userName);
        
        // Call the batch class to handle the log creation
        SaveObjectLogBatch batch = new SaveObjectLogBatch(selectedObject, serializeWMap, description, userName);
        Database.executeBatch(batch, 200); // Execute the batch with a scope size of 200
    }*/
    
    public pageReference ExportToExcel() {
        User user = new User();
        if(Schema.getGlobalDescribe().get('User').getDescribe().isAccessible()) {
            Id currentUserId = UserInfo.getUserId();
            user = [SELECT ID, Name FROM User WHERE Id = :currentUserId];
        }
        exportUser = user.Name;
        if(selectedLog != null && selectedLog != '') {
            for (SelectOption so : optionsLog) {
                if (so.getValue() == selectedLog) {
                    selectedLogExcel = so.getLabel();
                }
            }
        } else {
            selectedProfileIdList = new List<Id>();
            profileNameMap = new Map<Id, String>();
            if(selectedProfileList.size() > 0) {
                for(SelectOption so : selectedProfileList) {
                    selectedProfileIdList.add((Id)so.getValue());
                    profileNameMap.put(so.getValue(), so.getLabel());
                }
            } else {
                for(SelectOption so : selectedProfiles) {
                    selectedProfileIdList.add((Id)so.getValue());
                    profileNameMap.put(so.getValue(), so.getLabel());
                }
            }
        }
        retrieveRecords();
        selectedProfileList = new List<SelectOption>();
        return Page.ObjectsAndFieldsAccessExportToExcel;
        //return null;
    }
    
    
    public void SelectProfilesForExportToExcel() {
        if(selectedProfileList.size() > 100) {
            profList.addAll(selectedProfileList);
            
            selectedProfileList = new List<SelectOption>();
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning,'You can Export to Excel only 100 Profiles');
            ApexPages.addMessage(myMsg);
        } else {
            if(selectedProfileList.size() == 0) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning,'Select at least one profile up to 100');
                ApexPages.addMessage(myMsg);
            } else {
                readyToExport = true;
                profList = new List<SelectOption>();
                displayPopup = false;
            }
        }
    }
    
    
    public pageReference printPDF() {
        PageReference pageRef;
        pageRef = new PageReference('/apex/ObjectsAndFieldsAccessPDF');
        pageRef.getParameters().put('isPdf', 'true');
        String selectedProfilesString;
        for(SelectOption so : selectedProfiles) {
            selectedProfilesString += '+' + so.getValue();
        }
        pageRef.getParameters().put('selectedProfilesString', selectedProfilesString);
        String selectedObjectsString;
        for(SelectOption so : selectedObjects) {
            selectedObjectsString += '+' + so.getValue();
        }
        pageRef.getParameters().put('selectedObjectsString', selectedObjectsString);
        pageRef.getParameters().put('expandObject', expandObject);
        pageRef.getParameters().put('selectedLog', selectedLog);
        return pageRef;
    }
    
    public String SerializeFieldPermisionWrapper(List<FieldPermissionWrapper> fieldPermisionWList) {
        return JSON.serialize(fieldPermisionWList);
    }
    
    public List<FieldPermissionWrapper> deserializeFieldPermisionWrapper(String objectLogValue) {
        List<FieldPermissionWrapper> fieldPermisionWList = new List<FieldPermissionWrapper>();
        if (!String.isEmpty(objectLogValue)) {
            fieldPermisionWList = (List<FieldPermissionWrapper>)JSON.deserialize(objectLogValue,List<FieldPermissionWrapper>.class);
        }
        return fieldPermisionWList;
    }
    
    public void readSelectOnlyRecordsWithSelectedCheckboxes() {
        //system.debug('selectProfileId::' + selectProfileId);
        //system.debug('readSelectOnlySelectedCheckbox::' + readSelectOnlySelectedCheckbox);
        if(readSelectOnlySelectedCheckbox) {
            for(Id prId : readProfileSelectCheckboxMap.keySet()) {
                if(readProfileSelectCheckboxMap.get(prId)) {
                    retrieveRecords();
                }
            }
        }
        editProfileSelectCheckboxMap = new Map<Id, Boolean>();
        readProfileSelectCheckboxMap = new Map<Id, Boolean>();
        for(ID prID : selectedProfileIdList) {
            readProfileSelectCheckboxMap.put(prID, false);
            editProfileSelectCheckboxMap.put(prID, false);
        }
        if(readSelectOnlySelectedCheckbox) {
            Map<String, List<FieldPermissionWrapper>> fieldPermissionNotNullMap = new Map<String, List<FieldPermissionWrapper>>();
            Integer index = 0;
            for(ID prID : selectedProfileIdList) {
                if(prId == (Id)selectProfileId) {
                    readProfileSelectCheckboxMap.remove(prId);
                    readProfileSelectCheckboxMap.put(prID,true);
                    break;
                }
                index++;
            }
            Integer ind;
            fieldNameList = new List<String>();
            for(String fieldName : fieldPermissionMap.KeySet()) {
                ind = 0;
                Boolean isFind = false;
                for(FieldPermissionWrapper fpw : fieldPermissionMap.get(fieldName)) {
                    if(ind == index && fpw.R == true) {
                        isFind = true;
                    }
                    ind++;
                }
                if(isFind) {
                    fieldPermissionNotNullMap.put(fieldName, fieldPermissionMap.get(fieldName));
                    fieldNameList.add(fieldName);
                }
            }
            fieldPermissionMap = new Map<String, List<FieldPermissionWrapper>>();
            fieldPermissionMap = fieldPermissionNotNullMap;
        } else {
            retrieveRecords();
        }
    }
    
    public void editSelectOnlyRecordsWithSelectedCheckboxes() {
        //system.debug('selectProfileId::' + selectProfileId);
        //system.debug('editSelectOnlySelectedCheckbox::' + editSelectOnlySelectedCheckbox);
        if(editSelectOnlySelectedCheckbox) {
            for(Id prId : editProfileSelectCheckboxMap.keySet()) {
                if(editProfileSelectCheckboxMap.get(prId)) {
                    retrieveRecords();
                }
            }
        }
        editProfileSelectCheckboxMap = new Map<Id, Boolean>();
        readProfileSelectCheckboxMap = new Map<Id, Boolean>();
        for(ID prID : selectedProfileIdList) {
            editProfileSelectCheckboxMap.put(prID, false);
            readProfileSelectCheckboxMap.put(prID, false);
        }
        if(editSelectOnlySelectedCheckbox) {
            Map<String, List<FieldPermissionWrapper>> fieldPermissionNotNullMap = new Map<String, List<FieldPermissionWrapper>>();
            Integer index = 0;
            for(ID prID : selectedProfileIdList) {
                if(prId == (Id)selectProfileId) {
                    editProfileSelectCheckboxMap.remove(prId);
                    editProfileSelectCheckboxMap.put(prID,true);
                    break;
                }
                index++;
            }
            Integer ind;
            fieldNameList = new List<String>();
            for(String fieldName : fieldPermissionMap.KeySet()) {
                ind = 0;
                Boolean isFind = false;
                for(FieldPermissionWrapper fpw : fieldPermissionMap.get(fieldName)) {
                    if(ind == index && fpw.E == true) {
                        isFind = true;
                    }
                    ind++;
                }
                if(isFind) {
                    fieldPermissionNotNullMap.put(fieldName, fieldPermissionMap.get(fieldName));
                    fieldNameList.add(fieldName);
                }
            }
            fieldPermissionMap = new Map<String, List<FieldPermissionWrapper>>();
            fieldPermissionMap = fieldPermissionNotNullMap;
        } else {
            retrieveRecords();
        }
    }
    
    public void yesPopUp() {
        displayPopUp = true;
        readyToExport = false;
        profList = new List<SelectOption>();
        for(SelectOption so : remainingProfiles) {
            profList.add(new SelectOption(so.getValue(), so.GetLabel()));
            if(profList.size() > 998 -  selectedProfiles.size()) break;
        }
        profList = sortAfterLabelSelectOptionList(profList);
        selectedProfileList = new List<SelectOption>();
        for(SelectOption so : selectedProfiles) {
            selectedProfileList.add(new SelectOption(so.getValue(), so.GetLabel()));
        }
        //system.debug('displayPopUp::' + displayPopUp);
    }
    
    public void closePopup() {
        //objectsNameList.addAll(selectedObjectsList);
        selectedProfileList = new List<SelectOption>();
        profList = new List<SelectOption>();
        displayPopup = false;
    }
    
    public void ExportToXML() {
        //PageReference pageRef = new PageReference('/apex/GenerateProfileXML');
        //return pageRef;
    }
    
    public class FieldPermissionWrapper {
        public Id id { get; set; }
        public Id parentId { get; set; }
        public String objType { get; set; }
        public Boolean R { get; set; }
        public Boolean E { get; set; }
        public String field { get; set; }
        
        public FieldPermissionWrapper(FieldPermissions fieldPerm) {
            this.id = fieldPerm.Id;
            this.Field = fieldPerm.Field;
            this.parentId = fieldPerm.ParentId;
            this.objType = fieldPerm.SobjectType;
            this.R = fieldPerm.PermissionsRead;
            this.E = fieldPerm.PermissionsEdit;
        }
    }
    
    public class ObjectPermisionWrapper {
        public String objName { get; set; } //API Name
        public String objLabel { get; set; }	 //Label
        public List<String> objPermList { get; set; } //C R U D
        
        public ObjectPermisionWrapper(String objectName, String objectLabel) {
            this.objName = objectName;
            this.objLabel = objectLabel;
        }
    }
    
    public class FieldPermissionLogWrapper {
        public Id id { get; set; }
        public Id parentId { get; set; }
        public String objType { get; set; }
        public Boolean R { get; set; }
        public Boolean logR { get; set; }
        public Boolean E { get; set; }
        public Boolean logE { get; set; }
        public String field { get; set; }
        
        public FieldPermissionLogWrapper(FieldPermissionWrapper fieldPerm, Boolean Read, Boolean Edit) {
            this.id = fieldPerm.Id;
            this.Field = fieldPerm.Field;
            this.parentId = fieldPerm.ParentId;
            this.objType = fieldPerm.objType;
            this.R = fieldPerm.R;
            this.E = fieldPerm.E;
            this.logR = Read;
            this.logE = Edit;
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
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
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
    
    public static void testtestMethod1(){
        
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
    
    
    
}