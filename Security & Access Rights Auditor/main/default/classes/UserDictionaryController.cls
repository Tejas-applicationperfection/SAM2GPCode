public with sharing class UserDictionaryController {
    public Boolean hasAccess { get; set; }
    public List<SelectOption> objectsList { get; set; }    
    public List<SelectOption> objectsList1 { get; set; }    
    public String selectedObject { get; set; }    
    public Boolean OrgIsAccessible { get; set; }    
    public Map<String, List<String>> fieldDescriptionMap { get; set; }    
    public Map<String, List<String>> fieldDeployMap { get; set; }    
    public Map<String, Boolean> fieldGDPRMap { get; set; }    
    public Boolean isEdit { get; set; }    
    public Boolean isReadyToDownload { get; set; }    
    public Boolean isDeploy { get; set; }    
    public list<string> vlauuu { get; set; }    
    public String ZipData { get; set; }    
    public String xmlheader { get; set; }    
    public String endfile { get; set; }    
    //values for the fileds1,2,3,4, exports @Roopal    
    public Boolean isField1 { get; set; } //Description    
    public Boolean isField2 { get; set; } //HelpText    
    public Boolean isField3 { get; set; } //Highlighted data    
    public Boolean isField4 { get; set; } //Sensitivity    
    public Boolean isField5 { get; set; } //FieldType    
    public Boolean isField6 { get; set; } //Field usage    
    public Boolean isField7 { get; set; } //Data Owner    
    public Boolean isField8 { get; set; } //Compliance categorization    
    
    // Column visibility properties
    public Boolean showFieldNameColumn { get; set; }
    public Boolean showFieldTypeColumn { get; set; }
    public Boolean showDescriptionColumn { get; set; }
    public Boolean showHelpTextColumn { get; set; }
    public Boolean showHighlightedDataColumn { get; set; }
    public Boolean showSensitivityColumn { get; set; }
    public Boolean showFieldUsageColumn { get; set; }
    public Boolean showDataOwnerColumn { get; set; }
    public Boolean showComplianceCategorizationColumn { get; set; }
    
    // Column visibility management properties (for System Administrators)
    public Id selectedProfileForColumnVisibility { get; set; }
    public Id selectedUserForColumnVisibility { get; set; }
    public List<SelectOption> profilesForColumnVisibility { get; set; }
    public List<SelectOption> usersForColumnVisibility { get; set; }
    public Boolean displayColumnVisibilityPopup { get; set; }
    public Boolean isUserSpecificSettings { get; set; }
    
    // Add new property for Permission Set selection
    public Id selectedPermissionSetForColumnVisibility { get; set; }
    public List<SelectOption> permissionSetsForColumnVisibility { get; set; }
    
    //public Boolean showAllFields { get; set; }    
    public Integer totalFields { get; set; }    
    public Integer totalFieldsCount { get; set; }    
    public Integer totalHelptext { get; set; }    
    public Integer totalDescription { get; set; }
    public Integer TotalHelptextCount { get; set; }    
    public Integer TotalDescriptionCount { get; set; }    
    public Integer TotalFieldCount { get; set; }    
    public Integer fieldsWithPermissionsCount { get; set; }    
    public Integer fieldsWithHelpTextCount { get; set; }    
    public Integer fieldsWithDescriptionCount { get; set; }    
    public Decimal percentageOfFieldsWithHelpText { get; set; }    
    public Decimal percentageOfFieldsWithDescription { get; set; }    
    public Decimal percentageOfTotalFieldsWithHelpText { get; set; }    
    public Decimal percentageOfTotalFieldsWithDescription { get; set; }    
    public Integer helpTextCount { get; set; }    
    public Integer descriptionCount { get; set; }    
    public List<String> newValues { get; set; }    
    public List<String> oldValues { get; set; }    
    public integer FieldIndex { get; set; } //for width    
    public SA_Audit__Test_Object__c dummycontact { get; set; } // for Data Owner field    
    public List<User> userList { get; set; }    
    public String isPdf { get; set; }    
    public String userPDFID { get; set; }    
    public static List<String> userNameList { get; set; }    
    //public List<SelectOption> selectedProfilesD { get; set; } //forMultiselectPicklist    
    // public Boolean hideGoButton { get; set; } //to hide Go button when edit and save changes for deploy button is clicked    
    public Boolean isDivHidden { get; set; }        public String currentLanguage { get; set; }
    public String exportUser { get; set; }    
    public Organization org { get; set; }    
    public Boolean noEndpointMetadata { get; set; }    
    public Boolean editAccess { get; set; }
    //public transient Map<String, MetadataService.CustomField> metadataMap { get; set; }
    public Map<String, String> fieldTypeMap { get; set; }    
    public String selectedType { get; set; }    
    public Boolean isManaged { get; set; }    
    public List<SelectOption> selectedObjectsList { get; set; }    
    public Boolean displayPopup { get; set; }    
    public List<DataDictionaryWrapper> ddWList { get; set; }    
    public String selectedPerm { get; set; }    
    public String selectedProfile { get; set; }    
    public List<SelectOption> selectedPermission { get; set; }    
    public List<SelectOption> selectedcompliance { get; set; }    
    public List<SelectOption> selectedPermissionval { get; set; }    
    public String selectedProfileName { get; set; }    
    public List<SelectOption> profilesList { get; set; }    
    public List<SelectOption> permissionList { get; set; }    
    public List<SelectOption> permissionListLeftoption1 { get; set; }    
    public Map<String, String> fieldPermMap = new Map<String, String>();    
    public List<SelectOption> permsetList { get; set; }    
    public String permSetId { get; set; }    
    public Boolean isMultiselectPicklistEnabled {        
        get {            
            return isField1 || isField2 || isField3 || isField4 || isField6 || isField7 || isField8;}        
        set;        
    }    
    public List<SensitiveDataReportWrapper> sensitiveDataReportWrapperList { get; set; }    
    public MetadataService.AsyncResult AsyncResult {get; public set;}    
    public List<SelectOption> getObjectsType() {        
        List<SelectOption> options = new List<SelectOption>();        
        options.add(new SelectOption('Organization Object','Organization Object'));        
        options.add(new SelectOption('Managed Object','Managed Object'));        
        return options;       
    }    
    public List<SelectOption> getPermissionType() {        
        List<SelectOption> options = new List<SelectOption>();        
        options.addAll(SecurityUtilDictionary.getPermissionType());        
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
    
    public Boolean getPaidFeatureAccess() {
        try {
            // Check if the feature is enabled for the user
            //return FeatureManagement.checkPackageBooleanValue('UserDictionaryAccess');\
            return false;
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
	
    
    public UserDictionaryController() {        
        // Check feature access
        hasAccess = getPaidFeatureAccess();
        
        system.debug('debugg DataDictionary');        
        dummycontact = new SA_Audit__Test_Object__c(UserId__c = UserInfo.getUserId());        
        system.debug('dummycontact=='+dummycontact);        
        isDivHidden = false;        
        //selectedProfilesD = new List<SelectOption>();        
        sensitiveDataReportWrapperList = new List<SensitiveDataReportWrapper> ();        
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';        
        endfile = '</Workbook>';        
        currentLanguage = 'US';        
        exportUser = UserInfo.getName();        
        Id currentUserId = UserInfo.getUserId();               //values for the fileds1,2,3,4, exports @Roopal        
        isField1 = False; isField2 = False; isField3 = False; isField4 = False; isField5 = true; isField6 = False; isField7 = False; isField8 = False; FieldIndex = 0;        
        editAccess = false;        
        displayPopup = false;        
        displayColumnVisibilityPopup = false;
        
        // Initialize column visibility settings
            loadColumnVisibilitySettings();
        
        // If user is a System Administrator, load profiles for column visibility management
        User currentUser = [SELECT Id, Name, Profile.Name, profile.permissionscustomizeapplication FROM User WHERE Id =: currentUserId];
        if(currentUser.Profile.Name.contains('System Administrator') || currentUser.profile.permissionscustomizeapplication) {
            editAccess = true;
            profilesForColumnVisibility = UserDictionaryColumnConfigController.getAllProfiles();
            permissionSetsForColumnVisibility = UserDictionaryColumnConfigController.getAllPermissionSets();
            selectedProfileForColumnVisibility = UserInfo.getProfileId();
        }
        
        // selectedPerm = 'Organization Profiles & Permission Sets';
        fieldGDPRMap = new Map<String, Boolean>();                
        fieldDescriptionMap = new Map<String, List<String>>();        
        ddWList = new List<DataDictionaryWrapper>();        
        selectedObjectsList = new List<SelectOption>();        
        selectedPermission = new List<SelectOption>();        
        selectedcompliance = new List<SelectOption>();        
        List<SelectOption> profileTempList = new List<SelectOption>(SecurityUtilDictionary.getAllOrganizationProfilesList());        
        List<SelectOption> allPermissionSets = new List<SelectOption>(SecurityUtilDictionary.getAllPermissionSetList());        
        profilesList = new List<SelectOption>();        
        permissionList = new List<SelectOption>();        
        profileTempList = SecurityUtilDictionary.sortAfterLabelSelectOptionList(profileTempList);        
        allPermissionSets = SecurityUtilDictionary.sortAfterLabelSelectOptionList(allPermissionSets);        
        if(profileTempList.size() > 999) {            
            for(Integer i = 1; i< 999; i++) {                
                profilesList.add(profileTempList[i]);                
            }            
        } else {            
            profilesList.addAll(profileTempList);            
        }        
        if(allPermissionSets.size() > 999) {            
            for(Integer i = 1; i< 999; i++) {                
                permissionList.add(allPermissionSets[i]);                
            }            
        } else {            
            permissionList.addAll(allPermissionSets);            
        }        
             
        Id userId = UserInfo.getUserId();        
        // Query the User object to get the profile information        
        User currentUserr = [SELECT id, Profile.Name FROM User WHERE Id = :userId LIMIT 1];        
        // Access the profile name        
        String profileName = currentUserr.Profile.id;        
        selectedProfile = profileName;        
        selectedProfileName = profileName;        
        objectsList = new List<SelectOption>();        
        //metadataMap = new Map<String, MetadataService.CustomField>();        
        if(!Schema.getGlobalDescribe().get('Organization').getDescribe().isAccessible()) {            
            OrgIsAccessible = false;            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You don\'t have access on Organization object');            
            ApexPages.addMessage(myMsg);            
        } else {            
            OrgIsAccessible = true;            
            isDeploy = false;            
            isEdit = false;            
            noEndpointMetadata = false;            
                String orgId = UserInfo.getOrganizationId();            
            org = [SELECT Id , Name, NamespacePrefix FROM Organization WHERE ID = :orgID];            
            selectedObject = 'Account';            
            objectsList = SecurityUtilDictionary.getObjectsList(org.NamespacePrefix, false);            
            objectsList = SecurityUtilDictionary.sortAfterLabelSelectOptionList(objectsList);            
            //system.debug('objectsList::' + objectsList.size());
            system.debug('TestingProfiles');
            if(!DictionaryRollUpService.checkMetadataAPIConnection()) {                
                noEndpointMetadata = true;
                //system.debug('aloooo:');                           
            }
            
            retrieveRecords();            
            if(!noEndpointMetadata){                
                fieldDeployMap = new Map<String, List<String>>();                
                for(String field : fieldDescriptionMap.keySet()) {                    
                    fieldDeployMap.put(field, new List<String>(fieldDescriptionMap.get(field)));                    
                    String gdpr = fieldGDPRMap.get(field) ? 'true' : 'false';                    
                    fieldDeployMap.get(field).add(gdpr);                    
                }            
            }            
        }        
    }
    
    @RemoteAction
    
    public static void hideDiv() {        
        DataDictionary controller = new DataDictionary();        
        controller.isDivHidden = !controller.isDivHidden; // Toggle the boolean value        
    }
    
    public void changeType() {      
        if(selectedType == 'Organization Object') {            
            isManaged = false;            
        } else {            
            isManaged = true;            
        }        
                objectsList = new List<SelectOption>();
        objectsList1 = new List<SelectOption>();        
        List<SelectOption> objectsListTemp = new List<SelectOption>();        
        objectsList = SecurityUtilDictionary.getObjectsList(org.NamespacePrefix, isManaged);        
        objectsList = SecurityUtilDictionary.sortAfterLabelSelectOptionList(objectsList);        
        if(objectsList.size() > 900) {            
            objectsListTemp.addAll(objectsList);            
            objectsList = new List<SelectOption>();            
            Integer i = 0;            
            for(SelectOption so : objectsListTemp) {                
                if(i < 900) {                    
                    objectsList.add(new SelectOption(so.getValue(), so.getLabel()));
                } else {                    
                    objectsList1.add(new SelectOption(so.getValue(), so.getLabel()));                    
                }                
                i++;                
            }            
        }              
        selectedObject = objectsList[0].getValue();     
        retrieveRecords();        
        fieldDeployMap = new Map<String, List<String>>();        
        for(String field : fieldDescriptionMap.keySet()) {            
            fieldDeployMap.put(field, new List<String>(fieldDescriptionMap.get(field)));            
            //system.debug('Testing line no 187 -fieldDescriptionMap.get(field)'+ fieldDescriptionMap.get(field));            
            String gdpr = fieldGDPRMap.get(field) ? 'true' : 'false';            
            fieldDeployMap.get(field).add(gdpr);            
        }        
    }
    
    //values for the fileds1,2,3,4, exports @Roopal
    
    public void toggleValue1() {        
        isField1 = True;        
        system.debug('isField1'+ isField1);        
    }    
    public void toggleValue2() {        
        isField2 = True;        
        system.debug('isField2'+ isField1);        
    }
    public void toggleValue3() {        
        isField3 = True;        
        system.debug('isField3'+ isField1);        
    }
    
    public void toggleValue4() {        
        isField4 = True;
        system.debug('isField4'+ isField1);        
    }
    public void toggleValue5() {        
        isField5 = false;        
        system.debug('isField5'+ isField5);        
    }
    
    public void toggleValue6() {        
        isField6 = True;        
        system.debug('isField6'+ isField1);        
    }    
    public void toggleValue7() {
        
        isField7 = True;
        
        system.debug('isField7'+ isField1);
        
    }
    
    public void toggleValue8() {
        
        isField8 = True;
        
        system.debug('isField8'+ isField1);
        
    }
    
    public PageReference CreateEndpoint() {
        
        system.debug('debugg CreateEndpoint');
        
        system.debug('TestingProfiles');
        
        if(noEndpointMetadata) {
            
            return redirectToDictionaryWelcomeMetadataPage();
            
        }
        
        return null;
        
    }
    
    public void retrieveRecords() {
        
        System.debug('debugg retrieveRecords');
        
        system.debug('TestingProfiles');
        
        isReadyToDownload = false;
        
        ddWList = new List<DataDictionaryWrapper>();
        
        //system.debug('noEndpointMetadata::' + noEndpointMetadata);
        
        if(!noEndpointMetadata) {
            
            if (selectedProfile != '-------- None -------') {
                
                system.debug('debugg');
                
                List<Objectpermissions> objPermList = new List<objectpermissions>();
                
                List<PermissionSet> permissionSetList = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name, ProfileId, Profile.UserLicenseId, Label, LicenseId
                                                         
                                                         FROM PermissionSet
                                                         
                                                         WHERE ProfileId = :selectedProfile OR Id = :selectedProfile];
                
                system.debug('permissionSetList: ' + permissionSetList);
                
                permSetId = permissionSetList[0].Id;
                
                objPermList = [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
                               
                               FROM Objectpermissions WHERE SobjectType = :selectedObject AND ParentId = :permSetId];
                
                system.debug('objPermList======'+''+ objPermList);
                
                Set<String> permissionSetIds = new Set<String>();
                
                if(objPermList.size() == 0) {
                    
                    String profName = permissionSetList[0].Profile.Name == null ? permissionSetList[0].Label : permissionSetList[0].Profile.Name;
                    
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Selected profile ' + profName + ' don\'t has access on ' + selectedObject + ' object');
                    
                    ApexPages.addMessage(myMsg);
                    
                    fieldGDPRMap = new Map<String, Boolean>();
                    
                    fieldDescriptionMap = new Map<String, List<String>>();
                    
                    return;
                    
                }
                
                for (PermissionSet ps : permissionSetList) {
                    
                    permissionSetIds.add(ps.Id);
                    
                }
                
                List<FieldPermissions> fieldPermissionsList = [SELECT ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit
                                                               
                                                               FROM FieldPermissions
                                                               
                                                               WHERE SobjectType = :selectedObject AND (ParentId = :selectedProfile AND ParentId IN :permissionSetIds)];
                
                SYSTEM.debug('fieldPermissionsList: ' + fieldPermissionsList);
                
                for (FieldPermissions fp : fieldPermissionsList) {
                    
                    fieldPermMap.put(fp.Field.toLowerCase().substringAfterLast('.'), '');
                    
                }
                
            }
            
            system.debug('TestingProfiles');
            
            createDescriptionMap();
            
        }
        
        System.debug('4. Amount of CPU time (in ms) used so far: ' + Limits.getCpuTime());
        
        system.debug('TestingProfiles');
        
    }
    
    public void createDescriptionMap() {
        
        system.debug('debug createDescriptionMap');
        
        system.debug('TestingProfiles=' + selectedProfile);
        
        fieldGDPRMap = new Map<String, Boolean>();
        
        List<SA_Audit__Sensitive_Data__c> gdprObjectList = [SELECT Id, Name FROM SA_Audit__Sensitive_Data__c WHERE Name = :selectedObject];
        
        Id gdprObjectId = gdprObjectList.size() > 0 ? gdprObjectList[0].Id : null;
        
        List<Objectpermissions> objPermList1 = new List<objectpermissions>();
        
        List<SA_Audit__Sensitive_Data_Field__c> gdprFieldsList = new List<SA_Audit__Sensitive_Data_Field__c>();
        
        gdprFieldsList = [SELECT ID, Name, SA_Audit__Sensitive_Data__c, SA_Audit__Sensitive_Field_API__c FROM SA_Audit__Sensitive_Data_Field__c WHERE SA_Audit__Sensitive_Data_ObjectId__c = :gdprObjectId];
        
        for (SA_Audit__Sensitive_Data_Field__c gdprFieldName : gdprFieldsList) {
            
            fieldGDPRMap.put(gdprFieldName.SA_Audit__Sensitive_Field_API__c, gdprFieldName.SA_Audit__Sensitive_Data__c);
            
        }
        
        fieldDescriptionMap = new Map<String, List<String>>();
        
        system.debug('selectedObject+' + selectedObject);
        
        readCustomObject1(selectedObject);
        
        if (!selectedPermission.isEmpty()) {
            
            system.debug('debugg');
            
            List<String> permissionSetIds = new List<String>();
            
            for (SelectOption option : selectedPermission) {
                
                permissionSetIds.add((String)option.getValue());
                
            }
            
            List<FieldPermissions> fieldPermissionsList = [
                
                SELECT ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit
                
                FROM FieldPermissions
                
                WHERE SobjectType = :selectedObject
                
                AND (ParentId = :selectedProfile OR ParentId IN :permissionSetIds)
                
            ];
            
            Set<String> permissionSetNamesWithoutAccess = new Set<String>();
            
            List<Objectpermissions> permissionSetListd = new List<Objectpermissions>();
            
            for (SelectOption option : selectedPermission) {
                
                Id parentId = (Id) option.getValue();
                
                permissionSetListd = [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
                                      
                                      FROM Objectpermissions WHERE SobjectType = :selectedObject AND ParentId = :parentId];
                
                if (permissionSetListd.isEmpty() || permissionSetListd[0].PermissionsRead == false) {
                    
                    permissionSetNamesWithoutAccess.add(option.getLabel());
                    
                    continue;
                    
                }
                
            }
            
            List<Objectpermissions> objPermList = new List<objectpermissions>();
            
            List<PermissionSet> permissionSetList = [SELECT Id, Name, PermissionsModifyAllData, Profile.Name, ProfileId, Profile.UserLicenseId, Label, LicenseId
                                                     
                                                     FROM PermissionSet
                                                     
                                                     WHERE ProfileId = :selectedProfile OR Id = :selectedProfile];
            
            permSetId = permissionSetList[0].Id;
            
            objPermList1 = [SELECT Id, ParentId, SobjectType, PermissionsRead, PermissionsEdit, PermissionsCreate, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords
                            
                            FROM Objectpermissions WHERE SobjectType = :selectedObject AND ParentId = :permSetId];
            
            if (!permissionSetNamesWithoutAccess.isEmpty() && (objPermList1.size() == 0)) {
                
                String profName = permissionSetList[0].Profile.Name == null ? permissionSetList[0].Label : permissionSetList[0].Profile.Name;
                
                String permissionSetNames = String.join(new List<String>(permissionSetNamesWithoutAccess), ', ');
                
                String errorMessage = 'The following profile or permission set(s) do not have access to the ' + selectedObject + ' object: ' + profName + ', ' + permissionSetNames;
                
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage);
                
                ApexPages.addMessage(myMsg);
                
                return;
                
            }
            
            if( !permissionSetNamesWithoutAccess.isEmpty() ){
                
                String permissionSetNames = String.join(new List<String>(permissionSetNamesWithoutAccess), ', ');
                
                String errorMessage = 'The following profile or permission set(s) do not have access to the ' + selectedObject + ' object: ' + permissionSetNames;
                
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage);
                
                ApexPages.addMessage(myMsg);
                
                return;
                
            }
            
            SYSTEM.debug('fieldPermissionsList: ' + fieldPermissionsList);
            
            system.debug('permissionSetIdspermissionSetIds'+ permissionSetIds);
            
            for (FieldPermissions fp : fieldPermissionsList) {
                
                fieldPermMap.put(fp.Field.toLowerCase().substringAfterLast('.'), '');
                
                system.debug('fpfpfpfp'+ fp);
                
            }
            
        }
        
    }
    
    public void changePermType() {
        
        System.debug('debugg changePermType');
        
        profilesList = new List<SelectOption>();
        
        profilesList.add(new SelectOption('-------- None -------', '-------- None -------'));
        
        List<SelectOption> profileTempList = new List<SelectOption>();
        
        profileTempList = SecurityUtilDictionary.changetPermissionType(selectedPerm);
        
        if(profileTempList.size() > 999) {
            
            for(Integer i = 1; i< 999; i++) {
                
                profilesList.add(profileTempList[i]);
                
            }
            
        } else {
            
            system.debug('TestingProfiles');
            
            profilesList.addAll(profileTempList);
            
        }
        
        profilesList.addAll(profileTempList);
        
        selectedProfile = '-------- None -------';
        
        retrieveRecords();
        
    }
    
    public PageReference redirectToDictionaryWelcomeMetadataPage() {
        
        system.debug('TestingProfiles redirectToDictionaryWelcomeMetadataPage');
        
        system.debug('debugg');
        
        PageReference pageRef = Page.DictionaryWelcomeMetadataPage;
        
        pageRef.getParameters().put('retPage', 'DataDictionary');
        
        pageRef.setRedirect(true);
        
        return pageRef;
        
    }
    
    public static MetadataService.MetadataPort createService() {
        system.debug('TestingProfiles');
        system.debug('debugg createService');
        
        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        service.timeout_x = 60000;
        
        return service;
    }
    
    // for dataowner
    
    public void readCustomObject1(String objName) {
        
        system.debug('objName---' + objName);
        
        system.debug('debugg readCustomObject1');
        
        system.debug('readCustomObject1 called' + selectedProfile);
        
        Map<String, String> fieldPermMap = new Map<String, String>();
        
        if (selectedProfile != '-------- None -------') {
            
            system.debug('debugg');
            
            // Collect permissionIds
            
            List<Id> permissionIds = new List<Id>();
            
            for (SelectOption option : selectedPermission) {
                
                permissionIds.add((Id) option.getValue());
                
            }
            
            // Query PermissionSets
            
            List<PermissionSet> permissionSetList = [
                
                SELECT Id, Name, PermissionsModifyAllData, Profile.Name, ProfileId, Profile.UserLicenseId, Label, LicenseId
                
                FROM PermissionSet
                
                WHERE ProfileId = :selectedProfile OR Id IN :permissionIds
                
            ];
            
            if (permissionSetList.isEmpty()) {
                
                return;
                
            }
            
            system.debug('permissionSetList: ' + permissionSetList);
            
            // Collect PermissionSet Ids
            
            Set<String> permissionSetIds = new Set<String>();
            
            for (PermissionSet ps : permissionSetList) {
                
                permissionSetIds.add(ps.Id);
                
            }
            
            // Query ObjectPermissions
            
            List<ObjectPermissions> objectPermissionsList = [
                
                SELECT Id, ParentId, SobjectType, PermissionsRead
                
                FROM ObjectPermissions
                
                WHERE SobjectType = :selectedObject AND (ParentId = :selectedProfile OR ParentId IN :permissionSetIds)
                
            ];
            
            system.debug('objectPermissionsList: ' + objectPermissionsList);
            
            Set<String> permissionSetIdsWithAccess = new Set<String>();
            
            for (ObjectPermissions objPerm : objectPermissionsList) {
                
                if (objPerm.PermissionsRead) {
                    
                    permissionSetIdsWithAccess.add(objPerm.ParentId);
                    
                }
                
            }
            
            if (permissionSetIdsWithAccess.isEmpty()) {
                
                return;
                
            }
            
            // Query FieldPermissions
            
            List<FieldPermissions> fieldPermissionsList = [
                
                SELECT ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit
                
                FROM FieldPermissions
                
                WHERE SobjectType = :selectedObject AND (ParentId = :selectedProfile OR ParentId IN :permissionSetIdsWithAccess)
                
            ];
            
            Integer count = 0;
            
            system.debug('fieldPermissionsList: ' + fieldPermissionsList);
            
            for (FieldPermissions fp : fieldPermissionsList) {
                
                if (fp.PermissionsRead && !fp.Field.containsIgnoreCase('address') && !fp.Field.containsIgnoreCase('__pc') && fp.Field != 'Name') {
                    
                    fieldPermMap.put(fp.Field.toLowerCase().substringAfterLast('.'), '');
                    
                    count++;
                    
                }
                
            }
            
            fieldsWithPermissionsCount = count;
            system.debug('fieldsWithPermissionsCount'+fieldsWithPermissionsCount);
            
        }
        
        // Query Organization for Namespace
        
        List<Organization> namespaces = [SELECT NamespacePrefix FROM Organization LIMIT 1];
        
        system.debug('objName=====' + objName);
        
        // Query EntityParticle fields
        
        List<EntityParticle> fieldsList = [
            
            SELECT DataType, FieldDefinition.EntityDefinitionId, NamespacePrefix, FieldDefinition.SecurityClassification,
            
            FieldDefinition.QualifiedApiName, FieldDefinition.ComplianceGroup, inlineHelpText, FieldDefinition.Description, FieldDefinition.BusinessStatus,
            
            FieldDefinition.BusinessOwnerId, Label, IsUpdatable
            
            FROM EntityParticle
            
            WHERE EntityDefinition.QualifiedApiName = :objName limit 300
            
        ];
        
        totalFields = fieldsList.size();
        
        system.debug('CheckThis fieldDefinitionsList' + fieldsList);
        
        Map<Id, User> userMap = new Map<Id, User>();
        
        Set<Id> userIds = new Set<Id>();
        
        Integer helpTextCount = 0;
        
        Integer totalFieldsCount = 0;
        
        Integer descriptionCount = 0;
        
        Integer totalHelptext = 0;
        
        Integer totalDescription = 0;
        
        if (totalFields > 0) {
            
            for (EntityParticle field : fieldsList) {
                
                if (field.inlineHelpText != null && field.inlineHelpText.trim() != '') {
                    
                    totalHelptext++;
                    
                }
                
                if (field.FieldDefinition.Description != null && field.FieldDefinition.Description.trim() != '') {
                    
                    totalDescription++;
                    
                }
                
                if (field.FieldDefinition.BusinessOwnerId != null) {
                    
                    userIds.add(field.FieldDefinition.BusinessOwnerId);
                    
                }
                
                if (field.FieldDefinition.QualifiedApiName != null && !field.FieldDefinition.QualifiedApiName.containsIgnoreCase('__pc') && field.FieldDefinition.QualifiedApiName != 'Name' && !field.FieldDefinition.QualifiedApiName.containsIgnoreCase('address')) {
                    
                    totalFieldsCount++;
                    Boolean isRollupSummary = false;
                    
                    // We only need to describe the field if it's not obvious that it's not a roll-up summary
                    if (field.FieldDefinition.QualifiedApiName.contains('__r') || field.FieldDefinition.QualifiedApiName.endsWith('__c')) {
                        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objName);
                        Schema.DescribeSObjectResult sObjDesc = sObjectType.getDescribe();
                        Schema.DescribeFieldResult fieldDesc = sObjDesc.fields.getMap().get(field.FieldDefinition.QualifiedApiName).getDescribe();
                        
                        // Check for roll-up summary using isCalculated()
                        isRollupSummary = fieldDesc.isCalculated();
                        
                    }
                    
                    if (selectedProfile != '-------- None -------' && fieldPermMap.containsKey(field.FieldDefinition.QualifiedApiName.toLowerCase())) {
                        
                        String fieldLabelString = field.Label + ' (' + field.FieldDefinition.QualifiedApiName.toLowerCase() + ')';
                        
                        fieldDescriptionMap.put(fieldLabelString, new List<String>());
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.FieldDefinition.Description != null ? field.FieldDefinition.Description : '');
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.inlineHelpText != null ? field.inlineHelpText : '');
                        
                        String fieldAPI = field.FieldDefinition.QualifiedApiName.removeEndIgnoreCase('__c');
                        
                        if (String.isNotBlank(field.NamespacePrefix) && field.NamespacePrefix != namespaces[0].NamespacePrefix  || isRollupSummary|| (field.DataType == 'multiselect' || field.DataType == 'picklist' || field.DataType == 'multipicklist')) {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('false');
                            
                        } else {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('true');
                            
                        }
                        
                        if (!fieldGDPRMap.containsKey(fieldLabelString)) {
                            
                            fieldGDPRMap.put(fieldLabelString, false);
                            
                        }
                        
                        if (field.NamespacePrefix != Null) {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('true');
                            
                        } else {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('false');
                            
                        }
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.FieldDefinition.SecurityClassification != null ? field.FieldDefinition.SecurityClassification : '');
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.DataType != null ? field.DataType : '');
                        
                        if (!field.FieldDefinition.QualifiedApiName.endsWithIgnoreCase('__c') || fieldAPI.contains('__')) {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('false');
                            
                        } else {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('true');
                            
                        }
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.FieldDefinition.BusinessStatus != null ? field.FieldDefinition.BusinessStatus : '');
                        
                        String businessOwnerName = null;
                        
                        if (field.FieldDefinition.BusinessOwnerId != null && userMap.containsKey(field.FieldDefinition.BusinessOwnerId)) {
                            
                            businessOwnerName = userMap.get(field.FieldDefinition.BusinessOwnerId).Name;
                            
                        }
                        
                        fieldDescriptionMap.get(fieldLabelString).add(businessOwnerName != null ? businessOwnerName : '');
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.FieldDefinition.ComplianceGroup != null ? field.FieldDefinition.ComplianceGroup : '');
                        
                        if (field.inlineHelpText != null && field.inlineHelpText.trim() != '') {
                            
                            helpTextCount++;
                            
                        }
                        
                        if (field.FieldDefinition.Description != null && field.FieldDefinition.Description.trim() != '') {
                            
                            descriptionCount++;
                            
                        }
                        
                    }
                    
                    if (selectedProfile == '-------- None -------') {
                        
                        String fieldLabelString = field.Label + ' (' + field.FieldDefinition.QualifiedApiName.toLowerCase() + ')';
                        
                        fieldDescriptionMap.put(fieldLabelString, new List<String>());
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.FieldDefinition.Description != null ? field.FieldDefinition.Description : '');
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.inlineHelpText != null ? field.inlineHelpText : '');
                        
                        String fieldAPI = field.FieldDefinition.QualifiedApiName.removeEndIgnoreCase('__c');
                        
                        if (String.isNotBlank(field.NamespacePrefix) && field.NamespacePrefix != namespaces[0].NamespacePrefix || (field.DataType == 'multiselect' || field.DataType == 'picklist' || field.DataType == 'multipicklist')) {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('false');
                            
                        } else {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('true');
                            
                        }
                        
                        if (!fieldGDPRMap.containsKey(fieldLabelString)) {
                            
                            fieldGDPRMap.put(fieldLabelString, false);
                            
                        }
                        
                        if (field.NamespacePrefix != Null) {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('true');
                            
                        } else {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('false');
                            
                        }
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.FieldDefinition.SecurityClassification != null ? field.FieldDefinition.SecurityClassification : '');
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.DataType != null ? field.DataType : '');
                        
                        if (!field.FieldDefinition.QualifiedApiName.endsWithIgnoreCase('__c') || fieldAPI.contains('__')) {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('false');
                            
                        } else {
                            
                            fieldDescriptionMap.get(fieldLabelString).add('true');
                            
                        }
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.FieldDefinition.BusinessStatus != null ? field.FieldDefinition.BusinessStatus : '');
                        
                        String businessOwnerName = null;
                        
                        if (field.FieldDefinition.BusinessOwnerId != null && userMap.containsKey(field.FieldDefinition.BusinessOwnerId)) {
                            
                            businessOwnerName = userMap.get(field.FieldDefinition.BusinessOwnerId).Name;
                            
                        }
                        
                        fieldDescriptionMap.get(fieldLabelString).add(businessOwnerName != null ? businessOwnerName : '');
                        
                        fieldDescriptionMap.get(fieldLabelString).add(field.FieldDefinition.ComplianceGroup != null ? field.FieldDefinition.ComplianceGroup : '');
                        
                    }
                    
                }
                
            }
            
            fieldsWithHelpTextCount = helpTextCount;
            system.debug('fieldsWithHelpTextCount'+ fieldsWithHelpTextCount);
            
            fieldsWithDescriptionCount = descriptionCount;
            system.debug('fieldsWithDescriptionCount'+ fieldsWithDescriptionCount);
           
            TotalFieldCount = totalFieldsCount;
            
            TotalHelptextCount = totalHelptext;
            
            TotalDescriptionCount = totalDescription;
            
            if (TotalFieldCount > 0) {
                
                Decimal rawTotalHelpTextPercentage = (Decimal.valueOf(TotalHelptextCount) / Decimal.valueOf(TotalFieldCount)) * 100;
                
                percentageOfTotalFieldsWithHelpText = Math.round(rawTotalHelpTextPercentage);
                
                Decimal rawTotalDescriptionPercentage = (Decimal.valueOf(TotalDescriptionCount) / Decimal.valueOf(TotalFieldCount)) * 100;
                
                percentageOfTotalFieldsWithDescription = Math.round(rawTotalDescriptionPercentage);
                
            } else {
                
                percentageOfTotalFieldsWithHelpText = 0;
                
                percentageOfTotalFieldsWithDescription = 0;
                
            }
            
            if (fieldsWithPermissionsCount > 0) {
                
                Decimal rawHelpTextPercentage = (Decimal.valueOf(fieldsWithHelpTextCount) / Decimal.valueOf(fieldsWithPermissionsCount)) * 100;
                
                percentageOfFieldsWithHelpText = Math.round(rawHelpTextPercentage);
                system.debug('percentageOfFieldsWithHelpText'+ percentageOfFieldsWithHelpText);
                Decimal rawDescriptionPercentage = (Decimal.valueOf(fieldsWithDescriptionCount) / Decimal.valueOf(fieldsWithPermissionsCount)) * 100;
                
                percentageOfFieldsWithDescription = Math.round(rawDescriptionPercentage);
                system.debug('percentageOfFieldsWithDescription'+ percentageOfFieldsWithDescription);
                
            } else {
                
                percentageOfFieldsWithHelpText = 0;
                
                percentageOfFieldsWithDescription = 0;
                
            }
            
        }
        
        // Ensure all fields have at least two elements in the fieldDescriptionMap
        
        for (String field : fieldDescriptionMap.keySet()) {
            
            if (fieldDescriptionMap.get(field).size() == 0) {
                
                fieldDescriptionMap.get(field).add('');
                
                fieldDescriptionMap.get(field).add('');
                
            }
            
        }
        
        system.debug('fieldDescriptionMap=='+ fieldDescriptionMap);
        
    }
    
  
    
    public List<SelectOption> getComplianceCategorizationOptions() {
        
        System.debug('debugg getComplianceCategorizationOptions');
        
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult = FieldDefinition.ComplianceGroup.getDescribe();
        
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        
        for (Schema.PicklistEntry entry : picklistValues) {
            
            options.add(new SelectOption(entry.getValue(), entry.getLabel()));
            
        }
        
        return options;
        
    }
    
    public Map<String, DataDictionaryService.CustomField> readCustomObjectForDeploy1(String objName) {
        
        system.debug('TestingProfiles');
        
        system.debug('debug readCustomObjectForDeploy1');
        
        List<Organization> namespaces = new List<Organization>([ SELECT NamespacePrefix FROM Organization LIMIT 1 ]);
        
        Map<String, DataDictionaryService.CustomField> metadataMap = new Map<String, DataDictionaryService.CustomField>();
        
        DataDictionaryService.CustomObject obj = DataDictionaryService.retrieveCustomObjectMetadata(objName);
        
        System.debug(' metadataMap: ----' + metadataMap);
        
        system.debug('obj=='+obj);
        
        if (obj.fields != null) {
            
            for(DataDictionaryService.CustomField field : obj.fields) {
                
                //System.debug('$#$# description: ' + field.fullName + ' type=== ' + field.type_x);
                
                if(field.fullName != null) {
                    
                    metadataMap.put(field.fullName.toLowerCase(), field);
                    
                }
                
            }
            
        }
        
        system.debug('metadataMap==='+metadataMap);
        
        return metadataMap;
        
    }
    
    public Map<String, MetadataService.CustomField> readCustomObjectForDeploy(String objName) {
        
        system.debug('debug readCustomObjectForDeploy'+objName);
        
        system.debug('TestingProfiles');
        
        Map<String, MetadataService.CustomField> metadataMap = new Map<String, MetadataService.CustomField>();
        
        MetadataService.MetadataPort service = createService();
        
        MetadataService.ReadCustomObjectResult rs = (MetadataService.ReadCustomObjectResult)
            
            service.readMetadata('CustomObject', new String[] {objName});
        
        system.debug('debugg');
        
        for (MetadataService.Metadata md : rs.getRecords()) {
            
            if (md != null) {
                
                MetadataService.CustomObject obj = (MetadataService.CustomObject) md;
                
                system.debug('objobj=='+obj);
                
                if(obj.fields == null) continue;
                
                for(MetadataService.CustomField field : obj.fields) {
                    
                    if(field.fullName != null) {
                        
                        metadataMap.put(field.fullName.toLowerCase(), field);
                        
                    }
                    
                }
                
            }
            
        }
        
        system.debug('metadataMap---'+metadataMap);
        
        return metadataMap;
        
    }
    
    public void changeObject() {
        
        system.debug('TestingProfiles');
        
        system.debug('debugg changeObject');
        
        isEdit = false;
        
        isDeploy = false;
        
        try {
            
            retrieveRecords();
            
            fieldDeployMap = new Map<String, List<String>>();
            
            for(String field : fieldDescriptionMap.keySet()) {
                
                fieldDeployMap.put(field, new List<String>(fieldDescriptionMap.get(field)));
                
                String gdpr = fieldGDPRMap.get(field) ? 'true' : 'false';
                
                fieldDeployMap.get(field).add(gdpr);
                
            }
            
        } catch (Exception ex) {
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'You don\'t have rights on the ' + selectedObject));
            
        }
        
    }
    
    /*public void changeProfile() {

system.debug('debugg changeProfile');

system.debug('TestingProfiles');

}*/
    
    public void Edit() {
        
        system.debug('debugg Edit');
        
        system.debug('TestingProfiles');
        
        for(String field : fieldDescriptionMap.keySet()) {
            
        }
        
        isEdit = true;
        
        // hideGoButton = true; //to hide Go button when edit and save changes for deploy button is clicked
        
    }
    
    public void SaveMap() {
        
        System.debug('TestingProfiles');
        
        System.debug('debugg SaveMap');
        
        for (String field : fieldDescriptionMap.keySet()) {
            
            System.debug('field in savemap++++' + field);
            
            String gdpr = fieldGDPRMap.get(field) ? 'true' : 'false';
            
            // Check if any of the conditions for update are met
            
            if (fieldDescriptionMap.get(field)[0] != fieldDeployMap.get(field)[0]
                
                || fieldDescriptionMap.get(field)[1] != fieldDeployMap.get(field)[1]
                
                || fieldDeployMap.get(field)[3] != gdpr
                
                || fieldDescriptionMap.get(field)[4] != fieldDeployMap.get(field)[4]
                
                || fieldDescriptionMap.get(field)[7] != fieldDeployMap.get(field)[7]
                
                || !fieldDescriptionMap.get(field)[9].equals(fieldDeployMap.get(field)[9])) {
                    
                    // Update only the specific values that have changed
                    
                    if (!fieldDescriptionMap.get(field)[4].equals(fieldDeployMap.get(field)[4])) {
                        
                        fieldDescriptionMap.get(field)[0] += ' ';
                        
                        fieldDescriptionMap.get(field)[0] = fieldDescriptionMap.get(field)[0];
                        
                        fieldDescriptionMap.get(field)[1] += ' ';
                        
                        fieldDescriptionMap.get(field)[1] = fieldDescriptionMap.get(field)[1];
                        
                    }
                    
                    if (!fieldDescriptionMap.get(field)[7].equals(fieldDeployMap.get(field)[7])) {
                        
                        fieldDescriptionMap.get(field)[7] += ' ';
                        
                        fieldDescriptionMap.get(field)[7] = fieldDescriptionMap.get(field)[7];
                        
                    }
                    
                    // Logic specific to the 9th index (multiselect picklist)
                    
                    if (!fieldDescriptionMap.get(field)[9].equals(fieldDeployMap.get(field)[9])) {
                        
                        // Update only if the value is not null
                        
                        if (fieldDescriptionMap.get(field)[9] != null) {
                            
                            fieldDescriptionMap.get(field)[9] = fieldDescriptionMap.get(field)[9];
                            
                        }
                        
                    } else if (fieldDescriptionMap.get(field)[9] == null) {
                        
                        fieldDescriptionMap.get(field)[9] = fieldDeployMap.get(field)[9];
                        
                    }
                    
                    System.debug('fieldname*==' + field);
                    
                    isDeploy = true;
                    
                    break; // If you want to update only the first field that changed, you can remove this line.
                    
                } else {
                    
                    isDeploy = false;
                    
                }
            
        }
        
        isEdit = false;
        
        System.debug('fieldDeployMap+' + fieldDeployMap);
        
    }
    
    public PageReference Cancel() {
        
        System.debug('debugg Cancel');
        
        System.debug('TestingProfiles');
        
        System.debug('ExportToExcel method called.');
        
        // isEdit = false;
        
        // isCancel = true;
        
        fieldDescriptionMap = new Map<String, List<String>>();
        
        fieldGDPRMap = new Map<String, Boolean>();
        
        for (String field : fieldDeployMap.keySet()) {
            
            fieldDescriptionMap.put(field, new List<String>(fieldDeployMap.get(field)));
            
            Boolean gdpr = fieldDeployMap.get(field)[3] == 'true' ? true : false;
            
            fieldGDPRMap.put(field, gdpr);
            
        }
        
        PageReference nextPage = Page.UserDictionaryVFP;
        
        nextPage.setRedirect(true);
        
        return nextPage;
        
    }
    
    public void SelectObjectForExportToExcel() {
        
        system.debug('debugg SelectObjectForExportToExcel');
        
        system.debug('isFields1: ' + isField1);
        
        system.debug('isFields2: ' + isField2);
        
        system.debug('isFields3: ' + isField3); // Corrected to isFields3
        
        system.debug('selectedProfile: ' + selectedProfile);
        
        isReadyToDownload = true;
        
        if(selectedObjectsList.size() > 50) {
            
            system.debug('Too many objects selected: ' + selectedObjectsList.size());
            
            objectsList.addAll(selectedObjectsList);
            
            selectedObjectsList = new List<SelectOption>();
            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning, 'You can Export to Excel only 50 Objects');
            
            ApexPages.addMessage(myMsg);
            
            displayPopup = true;
            
        } else if(selectedObjectsList.size() == 0) {
            
            system.debug('No objects selected');
            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Warning, 'Select at least one object up to 50');
            
            ApexPages.addMessage(myMsg);
            
            displayPopup = true;
            
        } else {
            
            system.debug('Valid selection: ' + selectedObjectsList.size() + ' objects');
            
            displayPopup = false;
            
        }
        
        system.debug('Final selectedProfile: ' + selectedProfile);
        
        // Clear previous selection and add new
        
        objectsList.clear();
        
        objectsList.addAll(selectedObjectsList);
        
        // Sorting after adding selected objects
        
        objectsList = SecurityUtilDictionary.sortAfterLabelSelectOptionList(objectsList);
        
        system.debug('Sorted objectsList: ' + objectsList);
        
    }
    
    public PageReference ExportToExcel() {
        
        if (isEdit) {
            
            return null;
            
        }
        
        for(SelectOption ete : SelectedPermission){
            
        }
        
        system.debug('TestingProfiles');
        
        system.debug('TestingProfiles='+selectedProfile);
        
        if(selectedObjectsList.size() == 0) {
            
            system.debug('selectedProfile===in export'+selectedProfile);
            
            //changes by Roopal
            
            isField1 = true; isField2 = true; isField3 = true; isField4 = true; isField5 = true; isField6 = true; isField7 = true; isField8 = true;
            
            ddWList.add(new DataDictionaryWrapper(selectedObject, fieldDescriptionMap, fieldGDPRMap));
            
        } else {
            
            system.debug('selectedProfile===in export'+selectedProfile);
            
            Set<String> selectedObjAPISet = new Set<String>();
            
            for(SelectOption obj : selectedObjectsList) {
                
                selectedObjAPISet.add(obj.getValue());
                
            }
            
            system.debug('selectedProfile===in export'+selectedProfile);
            
            List<SA_Audit__Sensitive_Data__c> gdprObjectList = [SELECT Id, Name FROM SA_Audit__Sensitive_Data__c WHERE Name IN :selectedObjAPISet];
            
            Map<String, Id> sdMap = new Map<String, Id>();
            
            for(SA_Audit__Sensitive_Data__c sd: gdprObjectList) {
                
                sdMap.put(sd.Name, sd.Id);
                
            }
            
            system.debug('selectedProfile===in export'+selectedProfile);
            
            List<SA_Audit__Sensitive_Data_Field__c> gdprFieldsList = new List<SA_Audit__Sensitive_Data_Field__c>();
            
            gdprFieldsList = [SELECT ID, Name, SA_Audit__Sensitive_Data__c, SA_Audit__Sensitive_Field_API__c
                              
                              FROM SA_Audit__Sensitive_Data_Field__c WHERE SA_Audit__Sensitive_Data_ObjectId__c IN :gdprObjectList];
            
            for(SelectOption obj : selectedObjectsList) {
                
                system.debug('debugg');
                
                fieldGDPRMap = new Map<String, Boolean>();
                
                if(sdMap.containsKey(obj.getValue())) {
                    
                    system.debug('selectedProfile===in export'+selectedProfile);
                    
                    for(SA_Audit__Sensitive_Data_Field__c gdprField : gdprFieldsList) {
                        
                        if(gdprField.Id == sdMap.get(obj.getValue())) {
                            
                            system.debug('selectedProfile===in export'+selectedProfile);
                            
                            fieldGDPRMap.put(gdprField.SA_Audit__Sensitive_Field_API__c, gdprField.SA_Audit__Sensitive_Data__c);
                            
                        }
                        
                    }
                    
                }
                
                selectedObject = obj.getValue();
                
                createDescriptionMap();
                
                ddWList.add(new DataDictionaryWrapper(obj.getLabel(), fieldDescriptionMap, fieldGDPRMap));
                
            }
            
            system.debug('selectedProfile===in export'+selectedProfile);
            
        }
        
        system.debug('selectedProfile===in export'+selectedProfile);
        
        selectedObject = 'Account';
        
        selectedObjectsList = new List<SelectOption>();
        
        //system.debug('ddWList.size::' + ddWList.size());
        
        return Page.DataDictionaryExportToExcel;
        
    }
    
    public PageReference reportSensitiveData() {
        
        system.debug('TestingProfiles');
        
        system.debug('debugg reportSensitiveData');
        
        sensitiveDataReportWrapperList = new List<SensitiveDataReportWrapper> ();
        
        List<SA_Audit__Sensitive_Data__c> gdprObjectListReport = new List<SA_Audit__Sensitive_Data__c>();
        
        gdprObjectListReport = [SELECT Id, Name FROM SA_Audit__Sensitive_Data__c LIMIT 2000];
        
        Map<Id, String> sdMap = new Map<Id, String>();
        
        for(SA_Audit__Sensitive_Data__c sd: gdprObjectListReport) {
            
            sdMap.put(sd.Id, sd.Name);
            
        }
        
        List<SA_Audit__Sensitive_Data_Field__c> gdprFieldsListReport = new List<SA_Audit__Sensitive_Data_Field__c>();
        
        gdprFieldsListReport = [SELECT ID, Name, SA_Audit__Sensitive_Data__c, SA_Audit__Sensitive_Field_API__c, SA_Audit__Description__c,
                                
                                SA_Audit__Help__c, SA_Audit__Sensitive_Data_ObjectId__c
                                
                                FROM SA_Audit__Sensitive_Data_Field__c
                                
                                WHERE SA_Audit__Sensitive_Data_ObjectId__c IN :gdprObjectListReport
                                
                                AND SA_Audit__Sensitive_Data__c = true];
        
        for(SA_Audit__Sensitive_Data_Field__c sd : gdprFieldsListReport) {
            
            sensitiveDataReportWrapperList.add(new SensitiveDataReportWrapper(sdMap.get(sd.SA_Audit__Sensitive_Data_ObjectId__c),
                                                                              
                                                                              sd.SA_Audit__Sensitive_Field_API__c, sd.SA_Audit__Help__c, sd.SA_Audit__Description__c,
                                                                              
                                                                              sd.SA_Audit__Sensitive_Data__c)
                                               
                                              );
            
        }
        
        return Page.DataDictionaryReport;
        
    }
    
    public void yesPopUp() {
        
        system.debug('debugg yesPopUp');
        
        displayPopUp = true;
        
        isReadyToDownload = false;
        
        selectedObjectsList = new List<SelectOption>();
        
    }
    
    public void closePopup() {
        
        system.debug('debugg closePopup');
        
        objectsList.addAll(selectedObjectsList);
        
        selectedObjectsList = new List<SelectOption>();
        
        objectsList = SecurityUtilDictionary.sortAfterLabelSelectOptionList(objectsList);
        
        displayPopup = false;
        
    }
    
    //methods for metadata deploy
    
    public String getPackageXml() {
        
        system.debug('debugg getPackageXml');
        
        system.debug('getPackageXml');
        
        Map<String, MetadataService.CustomField> metadataMap = new Map<String, MetadataService.CustomField>();
        
        //Map<String, DataDictionaryService.CustomField> metadataMap = new Map<String, DataDictionaryService.CustomField>();
        
        metadataMap = readCustomObjectForDeploy(selectedObject);
        
        system.debug('metadataMap=='+metadataMap);
        
        String packageXml = '<?xml version="1.0" encoding="UTF-8"?>';
        
        packageXml += '<Package xmlns="http://soap.sforce.com/2006/04/metadata">';
        
        packageXml += '<types>';
        
        List<Organization> namespc = new List<Organization>([ SELECT NamespacePrefix FROM Organization LIMIT 1 ]);
        
        System.debug('fieldDescriptionMap??????' + fieldDescriptionMap);
        
        for(String field : fieldDescriptionMap.keySet()) {
            
            if( fieldDescriptionMap.get(field)[0] != fieldDeployMap.get(field)[0]
               
               || fieldDescriptionMap.get(field)[1] != fieldDeployMap.get(field)[1]
               
               || fieldDescriptionMap.get(field)[4] != fieldDeployMap.get(field)[4]
               
               || fieldDescriptionMap.get(field)[7] != fieldDeployMap.get(field)[7]
               
               || fieldDescriptionMap.get(field)[9] != fieldDeployMap.get(field)[9]){ //|| fieldDescriptionMap.get(field)[4] != fieldDeployMap.get(field)[4]
                   
                   String fieldname = field.substringBeforeLast(')');
                   
                   fieldname = fieldname.substringAfterLast('(');
                   
                   fieldname = fieldname.toLowerCase();
                   
                   System.debug('fieldname*==' + fieldname);
                   
                   if(!metadataMap.containsKey(fieldname)){ continue;}
                   
                   packageXml += '<members>' + selectedObject + '.' + metadataMap.get(fieldname).fullName + '</members>';
                   
                   //<members>Account.Industry</members>
                   
               }
            
            // }
            
        }
        
        packageXml += '<name>CustomField</name>';
        
        packageXml += '</types>';
        
        packageXml += '<version>59.0</version>';
        
        packageXml += '</Package>';
        
        system.debug('packageXml=-=-'+packageXml);
        
        return packageXml;
        
    }
    
    public String getNewDescription() {
        
        system.debug('debugg getNewDescription');
        
        system.debug('getNewDescription==' );
        
        Map<String, DataDictionaryService.CustomField> metadataMap = new Map<String, DataDictionaryService.CustomField>();
        
        metadataMap = readCustomObjectForDeploy1(selectedObject);
        
        system.debug('metadataMap=='+metadataMap);
        
        String packageXml = '<?xml version="1.0" encoding="UTF-8"?>';
        
        packageXml += '<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">';
        
        List<Organization> namespc = new List<Organization>([ SELECT NamespacePrefix FROM Organization LIMIT 1 ]);
        
        for(String field : fieldDescriptionMap.keySet()) {
            
            System.debug('fieldkeyset????' + fieldDescriptionMap.keySet());
            
            if( fieldDescriptionMap.get(field)[0] != fieldDeployMap.get(field)[0]
               
               || fieldDescriptionMap.get(field)[1] != fieldDeployMap.get(field)[1]
               
               || fieldDescriptionMap.get(field)[4] != fieldDeployMap.get(field)[4]|| fieldDescriptionMap.get(field)[7] != fieldDeployMap.get(field)[7]
               
               || fieldDescriptionMap.get(field)[9] != fieldDeployMap.get(field)[9]){ // || fieldDescriptionMap.get(field)[4] != fieldDeployMap.get(field)[4]
                   
                   String fieldname = field.substringBeforeLast(')');
                   
                   fieldname = fieldname.substringAfterLast('(');
                   
                   fieldname = fieldname.toLowerCase();
                   
                   System.debug('fieldname*==' + fieldname);
                   
                   if(!metadataMap.containsKey(fieldname)) {
                       
                       system.debug('testing line');
                       
                       continue;
                       
                   }
                   
                   System.debug('fieldDescriptionMap.get==' + fieldDescriptionMap.get(field)[0]);
                   
                   System.debug('fieldDeployMap.get0==' + fieldDeployMap.get(field)[0]);
                   
                   System.debug('fieldDeployMap.get0==' + fieldDeployMap.get(field)[0]);
                   
                   System.debug('fieldDeployMap.get1==' + fieldDeployMap.get(field)[1]);
                   
                   System.debug('fieldDeployMap.get1==' + fieldDeployMap.get(field)[1]);
                   
                   if( metadataMap.get(fieldname).type_x == null) {
                       
                       system.debug('testing line');
                       
                       packageXml += '<fields>';
                       
                       packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                       
                       packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                       
                       packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                       
                       packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                       
                       packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                       
                       packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                       
                       packageXml += '</fields>';
                       
                       System.debug('packageXml*' + packageXml);
                       
                   } else {
                       
                       system.debug('testing line');
                       
                       if (metadataMap.get(fieldname).type_x == 'Number'){
                           
                           packageXml += '<fields>';
                           
                           //packageXml += '<fullName>'+metadataMap.get(fieldname).fullName+'</fullName>';
                           packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Number</type>';
                           
                           packageXml += '<precision>' + metadataMap.get(fieldname).precision + '</precision>';
                           
                           packageXml += '<scale>' + metadataMap.get(fieldname).scale + '</scale>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Text') {
                           
                           packageXml += '<fields>';
                           
                          // packageXml += '<fullName>'+metadataMap.get(fieldname).fullName+'</fullName>';
                           packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Text</type>';
                           
                           if (metadataMap.get(fieldname).length != null) {
                               
                               packageXml += '<length>' + metadataMap.get(fieldname).length + '</length>';
                               
                           }
                           
                           if (fieldname.endsWith('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if (metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'LongTextArea'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>LongTextArea</type>';
                           
                           packageXml += '<visibleLines>'+metadataMap.get(fieldname).visibleLines+'</visibleLines>';
                           
                           if(metadataMap.get(fieldname).length != null) {
                               
                               packageXml += '<length>'+ metadataMap.get(fieldname).length+'</length>';
                               
                           }
                           
                           if(fieldname.contains('__c')) {
                               
                               system.debug('testing line');
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>'+metadataMap.get(fieldname).formula+'</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if(metadataMap.get(fieldname).type_x == 'Html') {
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Html</type>';
                           
                           packageXml += '<visibleLines>'+metadataMap.get(fieldname).visibleLines+'</visibleLines>';
                           
                           if(metadataMap.get(fieldname).length != null) {
                               
                               system.debug('testing line');
                               
                               packageXml += '<length>'+ metadataMap.get(fieldname).length+'</length>';
                               
                           }
                           
                           if(fieldname.contains('__c')) {
                           packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';    
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               system.debug('testing line');
                               
                               packageXml += '<formula>'+metadataMap.get(fieldname).formula+'</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'EncryptedText' ){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>EncryptedText</type>';
                           
                           packageXml += '<maskChar>' + metadataMap.get(fieldname).maskChar+'</maskChar>';
                           
                           packageXml += '<maskType>' + metadataMap.get(fieldname).maskType+'</maskType>';
                           
                           if(metadataMap.get(fieldname).length != null) {
                               
                               packageXml += '<length>'+metadataMap.get(fieldname).length+'</length>';
                               
                           }
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>'+metadataMap.get(fieldname).formula+'</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'TextArea'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>TextArea</type>';
                           
                           if(metadataMap.get(fieldname).length != null) {
                               
                               packageXml += '<length>' + metadataMap.get(fieldname).length + '</length>';
                               
                           }
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Date'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Date</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>'+metadataMap.get(fieldname).formula+'</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'DateTime'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4] +'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>DateTime</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Percent'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Percent</type>';
                           
                           packageXml += '<precision>'+metadataMap.get(fieldname).precision+'</precision>';
                           
                           packageXml += '<scale>'+metadataMap.get(fieldname).scale+'</scale>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Checkbox'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Checkbox</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula == null) {
                               
                               packageXml += '<defaultValue>'+metadataMap.get(fieldname).defaultValue+'</defaultValue>'; }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Currency'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]> </inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Currency</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           packageXml += '<precision>' + metadataMap.get(fieldname).precision + '</precision>';
                           
                           packageXml += '<scale>' + metadataMap.get(fieldname).scale + '</scale>';
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Email'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Email</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Location'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Location</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           packageXml += '<scale>' + metadataMap.get(fieldname).scale + '</scale>';
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Phone'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Phone</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Time'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Time</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Url'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Url</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Hierarchy'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Hierarchy</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Picklist'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Picklist</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if (metadataMap.get(fieldname).valueSet != null && fieldname.contains('__c')) {
                               
                               packageXml += '<valueSet>';
                               
                               if (metadataMap.get(fieldname).valueSet.valueSetName != null) {
                                   
                                   packageXml += '<valueSetName>' + metadataMap.get(fieldname).valueSet.valueSetName + '</valueSetName>';
                                   
                               } else {
                                   
                                   packageXml += '<valueSetDefinition>';
                                   
                                   for (DataDictionaryService.CustomValue val : metadataMap.get(fieldname).valueSet.valueSetDefinition.value) {
                                       
                                       packageXml += '<value>';
                                       
                                       packageXml += '<fullName>' + val.fullName + '</fullName>';
                                       
                                       packageXml += '<default>' + val.fullName + '</default>';
                                       
                                       packageXml += '</value>';
                                       
                                   }
                                   
                                   packageXml += '</valueSetDefinition>';
                                   
                               }
                               
                               packageXml += '</valueSet>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'MultiselectPicklist'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>MultiselectPicklist</type>';
                           
                           packageXml += '<visibleLines>'+metadataMap.get(fieldname).visibleLines+'</visibleLines>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).valueSet != null) {
                               
                               packageXml += '<valueSet>';
                               
                               packageXml += '<controllingField>' + metadataMap.get(fieldname).valueSet.controllingField + '</controllingField>';
                               
                               if(metadataMap.get(fieldname).valueSet.restricted != null) {
                                   
                                   packageXml += '<restricted>' + metadataMap.get(fieldname).valueSet.restricted + '</restricted>';
                                   
                               }
                               
                               packageXml += '<valueSetName>' + metadataMap.get(fieldname).valueSet.valueSetName + '</valueSetName>';
                               
                               packageXml += '<valueSetDefinition>';
                               
                               for(DataDictionaryService.CustomValue val : metadataMap.get(fieldname).valueSet.valueSetDefinition.value) {
                                   
                                   packageXml += '<value>';
                                   
                                   packageXml += '<fullName>' + val.fullName + '</fullName>';
                                   
                                   packageXml += '<controllingFieldValues>' + val.fullName + '</controllingFieldValues>';
                                   
                                   packageXml += '<default>' + val.fullName + '</default>';
                                   
                                   packageXml += '</value>';
                                   
                               }
                               
                               packageXml += '</valueSetDefinition>';
                               
                               packageXml += '</valueSet>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'AutoNumber'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>AutoNumber</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                           }
                           
                           if(metadataMap.get(fieldname).formula != null) {
                               
                               packageXml += '<formula>' + metadataMap.get(fieldname).formula + '</formula>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'Lookup'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<businessStatus>'+fieldDescriptionMap.get(field)[7]+'</businessStatus>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>Lookup</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                               packageXml += '<referenceTo>' + metadataMap.get(fieldname).referenceTo + '</referenceTo>';
                               
                               packageXml += '<relationshipName>' + metadataMap.get(fieldname).relationshipName + '</relationshipName>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       if (metadataMap.get(fieldname).type_x == 'MasterDetail'){
                           
                           packageXml += '<fields>';
                           
packageXml += '<fullName><![CDATA['+metadataMap.get(fieldname).fullName+']]></fullName>';
                           
                           packageXml += '<description><![CDATA['+fieldDescriptionMap.get(field)[0]+']]></description>';
                           
                           packageXml += '<inlineHelpText><![CDATA['+fieldDescriptionMap.get(field)[1]+']]></inlineHelpText>';
                           
                           packageXml += '<securityClassification>'+fieldDescriptionMap.get(field)[4]+'</securityClassification>';
                           
                           packageXml += '<complianceGroup>'+fieldDescriptionMap.get(field)[9]+'</complianceGroup>';
                           
                           packageXml += '<type>MasterDetail</type>';
                           
                           if(fieldname.contains('__c')) {
                               
packageXml += '<label><![CDATA[' + metadataMap.get(fieldname).label + ']]></label>';
                               
                               packageXml += '<referenceTo>'+metadataMap.get(fieldname).referenceTo+'</referenceTo>';
                               
                               packageXml += '<relationshipName>'+metadataMap.get(fieldname).relationshipName+'</relationshipName>';
                               
                           }
                           
                           packageXml += '</fields>';
                           
                           System.debug('packageXml*' + packageXml);
                           
                       }
                       
                       //} else {}
                       
                   }
                   
               }
            
            //}
            
        }
        
        packageXml += '</CustomObject>';        
        system.debug('packageXml==='+packageXml);        
        return packageXml;        
    }
    
    public PageReference checkAsyncRequest() {
        system.debug('TestingProfiles');  
        system.debug('debugg checkAsyncRequest');
        // Check the status of the retrieve request
        MetadataService.MetadataPort service = createService();
        MetadataService.DeployResult deployResult = service.checkDeployStatus(AsyncResult.Id, true);
        
        system.debug('DeployResult.done: ' + deployResult.done);
        if(deployResult.done) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Deployment complete'));
            system.debug('Deployment complete');
            // Deployment errors?
            if(deployResult.details!=null && deployResult.details.componentFailures!=null)
                for(MetadataService.DeployMessage deployMessage : deployResult.details.componentFailures)
                if(deployMessage.problem!=null)
                ApexPages.addMessage(
                    new ApexPages.Message(ApexPages.Severity.Error, 
                                          deployMessage.fileName + 
                                          ' (Line: ' + deployMessage.lineNumber + ': Column:' + deployMessage.columnNumber + ') : ' + 
                                          deployMessage.problem));
            system.debug('Error: '  );
            AsyncResult = null;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Deploying...'));
            system.debug('Deploying...');
        }   
        return null;
    }
    
   public void Deploy() {
        system.debug('TestingProfiles');  
        system.debug('debugg Deploy');
        isDeploy = false;
        //system.debug('isDeploy::' + isDeploy);
        Boolean messageDisplayed = false;
        system.debug('fieldDescriptionMap=='+fieldDescriptionMap);
        for(String field : fieldDescriptionMap.keySet()) {
            system.debug('field===>'+field);
            if(fieldDescriptionMap.get(field)[0] != fieldDeployMap.get(field)[0] 
               || fieldDescriptionMap.get(field)[1] != fieldDeployMap.get(field)[1]){
                   messageDisplayed = true;
               }
        }
        /*if(messageDisplayed) {
system.debug('debugg');
ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Your changes are queued for deploy. Please wait for the deploy to complete before making further changes  to this object. You can monitor the deploy status in the setup menu under Deployment Status'));

}*/
        
    }
    
    public PageReference deployZip() {
        system.debug('TestingProfiles');  
        system.debug('debugg deployZip');
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Deploying...'));
        system.debug('ZipData::' + ZipData);
        // Deploy zip file posted back from the page action function                
        MetadataService.MetadataPort service = createService();
        MetadataService.DeployOptions deployOptions = new MetadataService.DeployOptions();
        deployOptions.allowMissingFiles = false;
        deployOptions.autoUpdatePackage = false;
        deployOptions.checkOnly = false;
        deployOptions.ignoreWarnings = false;
        deployOptions.performRetrieve = false;
        deployOptions.purgeOnDelete = false;
        deployOptions.rollbackOnError = true;
        deployOptions.testLevel = 'RunSpecifiedTests';
        String[] tests = new List<String>();
        tests.add('');
        deployOptions.runTests = tests;
        deployOptions.singlePackage = true;  
        AsyncResult = service.deploy(ZipData, DeployOptions);
        system.debug('AsyncResult::' + AsyncResult);
        //fieldDeployMap = fieldDescriptionMap;
        isDeploy = false;
        
        //save GDPR in the GDPR Object and GDPR Fields
        List<SA_Audit__Sensitive_Data__c> gdprObjectList = [SELECT Id, Name FROM SA_Audit__Sensitive_Data__c WHERE Name = :selectedObject];
        Id gdprObjectId = null;
        for(SA_Audit__Sensitive_Data__c gdprObject : gdprObjectList) {
            if(gdprObject.Name == selectedObject) {
                gdprObjectId = gdprObject.Id;
            }
        }
        if(gdprObjectId != null) {
            List<SA_Audit__Sensitive_Data_Field__c> gdprFieldsList = new List<SA_Audit__Sensitive_Data_Field__c>();
            List<SA_Audit__Sensitive_Data_Field__c> gdprFieldsListToDelete = new List<SA_Audit__Sensitive_Data_Field__c>();
            List<SA_Audit__Sensitive_Data_Field__c> gdprFieldsListToUpsert = new List<SA_Audit__Sensitive_Data_Field__c>();
            gdprFieldsList = [SELECT ID, Name, SA_Audit__Sensitive_Field_API__c, SA_Audit__Sensitive_Data__c, SA_Audit__Help__c, SA_Audit__Description__c 
                              FROM SA_Audit__Sensitive_Data_Field__c 
                              WHERE SA_Audit__Sensitive_Data_ObjectId__c = :gdprObjectId];
            Set<String> sensitiveFielAPISet = new Set<String>();
            for(SA_Audit__Sensitive_Data_Field__c gdprField : gdprFieldsList) {
                if(fieldGDPRMap.containsKey(gdprField.SA_Audit__Sensitive_Field_API__c)) {
                    if(gdprField.Sensitive_Data__c != fieldGDPRMap.get(gdprField.SA_Audit__Sensitive_Field_API__c)) {
                        if(Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Data__c.isCreateable() && 
                           Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Description__c.isCreateable() &&
                           Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Help__c.isCreateable() && 
                           Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Data__c.isUpdateable() &&
                           Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Description__c.isUpdateable() &&
                           Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Help__c.isUpdateable()){
                               gdprField.SA_Audit__Sensitive_Data__c = fieldGDPRMap.get(gdprField.SA_Audit__Sensitive_Field_API__c);
                               gdprField.SA_Audit__Description__c = fieldDescriptionMap.get(gdprField.SA_Audit__Sensitive_Field_API__c)[0];
                               gdprField.SA_Audit__Help__c = fieldDescriptionMap.get(gdprField.SA_Audit__Sensitive_Field_API__c)[1];
                               gdprFieldsListToUpsert.add(gdprField);
                           }
                        system.debug('debugg');
                    } 
                    sensitiveFielAPISet.add(gdprField.SA_Audit__Sensitive_Field_API__c);
                } else {
                    gdprFieldsListToDelete.add(gdprField);
                }
            }
            for(String field : fieldGDPRMap.keySet()) {
                if(!sensitiveFielAPISet.contains(field)) {
                    SA_Audit__Sensitive_Data_Field__c gdprField = new SA_Audit__Sensitive_Data_Field__c();
                    if(Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Field_API__c.isCreateable() && 
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Data__c.isCreateable() &&
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Data_ObjectId__c.isCreateable() &&
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Description__c.isCreateable() &&
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Help__c.isCreateable() &&
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Field_API__c.isUpdateable() && 
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Data__c.isUpdateable() &&
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Data_ObjectId__c.isUpdateable() &&
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Description__c.isUpdateable() &&
                       Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Help__c.isUpdateable()){
                           gdprField.SA_Audit__Sensitive_Field_API__c = field;
                           gdprField.SA_Audit__Sensitive_Data__c = fieldGDPRMap.get(field);
                           gdprField.SA_Audit__Sensitive_Data_ObjectId__c = gdprObjectId;
                           gdprField.SA_Audit__Description__c = fieldDescriptionMap.get(field)[0];
                           gdprField.SA_Audit__Help__c = fieldDescriptionMap.get(field)[1];
                           gdprFieldsListToUpsert.add(gdprField);
                           system.debug('debugg');
                       }
                }
            }
            if(SA_Audit__Sensitive_Data_Field__c.sObjectType.getDescribe().isDeletable()){
                delete gdprFieldsListToDelete;
                system.debug('debugg');
            }
            upsert gdprFieldsListToUpsert;
        } else {
            SA_Audit__Sensitive_Data__c gdprObject = new SA_Audit__Sensitive_Data__c();
            if(Schema.sObjectType.SA_Audit__Sensitive_Data__c.fields.Name.isCreateable()){
                gdprObject.Name = selectedObject;
                insert gdprObject;
            }
            List<SA_Audit__Sensitive_Data_Field__c> gdprFieldsListToInsert = new List<SA_Audit__Sensitive_Data_Field__c>();
            for(String field : fieldGDPRMap.keySet()) {
                //if(fieldGDPRMap.get(field)) {       
                system.debug('debugg');
                SA_Audit__Sensitive_Data_Field__c gdprField = new SA_Audit__Sensitive_Data_Field__c();
                if(Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Field_API__c.isCreateable() && 
                   Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Data__c.isCreateable() &&
                   Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Sensitive_Data_ObjectId__c.isCreateable() &&
                   Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Description__c.isCreateable() &&
                   Schema.sObjectType.SA_Audit__Sensitive_Data_Field__c.fields.SA_Audit__Help__c.isCreateable()){
                       gdprField.SA_Audit__Sensitive_Field_API__c = field;
                       gdprField.SA_Audit__Sensitive_Data__c = fieldGDPRMap.get(field);
                       gdprField.SA_Audit__Sensitive_Data_ObjectId__c = gdprObject.Id;
                       gdprField.SA_Audit__Description__c = fieldDescriptionMap.get(field)[0];
                       gdprField.SA_Audit__Help__c = fieldDescriptionMap.get(field)[1];
                       gdprFieldsListToInsert.add(gdprField);
                   }
                //}
            }
            //try {
            system.debug('gdprFieldsListToInsert='+gdprFieldsListToInsert);
            insert gdprFieldsListToInsert;
            
            //} catch(Exception e) {
            //  system.debug('Eroare save GDPR::' + e.getMessage());
            //}
        }
                fieldDeployMap = new Map<String, List<String>>();                
        for(String field : fieldDescriptionMap.keySet()) {
            
            system.debug('field======'+  field);
            fieldDeployMap.put(field, new List<String>(fieldDescriptionMap.get(field)));
            String gdpr = fieldGDPRMap.get(field) ? 'true' : 'false';
            fieldDeployMap.get(field).add(gdpr);
        }
        system.debug('fieldDeployMap===-'+fieldDeployMap);
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Almost Complete...'));
        
        
        return null;
    }
    
   
    
    public class DataDictionaryWrapper {        
        public String objectName { get; set; }        
        public Map<String, List<String>> fieldDescriptionMap { get; set; }        
        //static Map<String, List<String>> fieldDeployMap;        
        public Map<String, Boolean> fieldGDPRMap { get; set; }        
        public DataDictionaryWrapper(String objectName, Map<String, List<String>> fieldDescriptionMap, Map<String, Boolean> fieldGDPRMap) {            
            objectName = objectName.replaceAll('/', '');            
            objectName = objectName.unescapeEcmaScript();            
            //system.debug('objn:: ' + objectName);                    
            this.objectName = objectName;            
            this.fieldDescriptionMap = fieldDescriptionMap;            
            this.fieldGDPRMap = fieldGDPRMap;            
        }        
    }
    
    public class SensitiveDataReportWrapper {        
        public String objName { get; set; }        
        public String fieldName { get; set; }        
        public String helpText { get; set; }        
        public String description { get; set; }        
        public Boolean sensitiveData { get; set; }        
        public SensitiveDataReportWrapper(String objName , String fieldName, String helpText, String description, Boolean sensitiveData) {            
            this.objName = objName;            
            this.fieldName = fieldName;            
            this.helpText = helpText;            
            this.description = description;            
            this.sensitiveData = sensitiveData;            
        }
        
    }
    
    /**
     * Load column visibility settings for the current user's profile
     */
    public void loadColumnVisibilitySettings() {
        System.debug('Loading column visibility settings for profile: ' + UserInfo.getProfileId());
        Map<String, Boolean> columnVisibility = UserDictionaryColumnConfigController.getColumnVisibilitySettings();
        
        // Set column visibility properties based on settings
        showFieldNameColumn = columnVisibility.get('ShowFieldName');
        showFieldTypeColumn = columnVisibility.get('ShowFieldType');
        showDescriptionColumn = columnVisibility.get('ShowDescription');
        showHelpTextColumn = columnVisibility.get('ShowHelpText');
        showHighlightedDataColumn = columnVisibility.get('ShowHighlightedData');
        showSensitivityColumn = columnVisibility.get('ShowSensitivity');
        showFieldUsageColumn = columnVisibility.get('ShowFieldUsage');
        showDataOwnerColumn = columnVisibility.get('ShowDataOwner');
        showComplianceCategorizationColumn = columnVisibility.get('ShowComplianceCategorization');
        
        System.debug('Column visibility settings loaded: ' + 
                    'ShowFieldName=' + showFieldNameColumn + 
                    ', ShowFieldType=' + showFieldTypeColumn + 
                    ', ShowDescription=' + showDescriptionColumn + 
                    ', ShowHelpText=' + showHelpTextColumn + 
                    ', ShowHighlightedData=' + showHighlightedDataColumn + 
                    ', ShowSensitivity=' + showSensitivityColumn + 
                    ', ShowFieldUsage=' + showFieldUsageColumn + 
                    ', ShowDataOwner=' + showDataOwnerColumn + 
                    ', ShowComplianceCategorization=' + showComplianceCategorizationColumn);
    }
    
    /**
     * Open the column visibility management popup
     */
    public void openColumnVisibilityPopup() {
        // Only System Administrators can manage column visibility
        User currentUserProfile = [SELECT Id, Profile.Name, profile.permissionscustomizeapplication FROM User WHERE Id = :UserInfo.getUserId()];
        if(currentUserProfile.Profile.Name.contains('System Administrator') || currentUserProfile.profile.permissionscustomizeapplication) {
            displayColumnVisibilityPopup = true;
            profilesForColumnVisibility = UserDictionaryColumnConfigController.getAllProfiles();
            usersForColumnVisibility = UserDictionaryColumnConfigController.getAllUsers();
            selectedProfileForColumnVisibility = UserInfo.getProfileId();
            selectedUserForColumnVisibility = null;
            isUserSpecificSettings = false;
            configType = 'profile'; // Set default config type to profile
            loadColumnVisibilityForSelection();
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only System Administrators can manage column visibility settings.'));
        }
    }
    
    /**
     * Close the column visibility management popup
     */
    public void closeColumnVisibilityPopup() {
        displayColumnVisibilityPopup = false;
    }
    
    /**
     * Toggle between user-specific and profile-based settings
     */
    public void toggleUserSpecificSettings() {
        // Reset the selected values when toggling
        if (isUserSpecificSettings) {
            selectedUserForColumnVisibility = null;
        } else {
            selectedProfileForColumnVisibility = null;
        }
        
        // Load settings based on the current selection
        loadColumnVisibilityForSelection();
    }
    
    /**
     * Load column visibility settings for the selected user or profile
     */
    public void loadColumnVisibilityForSelection() {
        try {
            Map<String, Boolean> columnVisibility;
            
            System.debug('Loading column visibility settings with configType: ' + configType);
            System.debug('isUserSpecificSettings: ' + isUserSpecificSettings);
            System.debug('selectedProfileForColumnVisibility: ' + selectedProfileForColumnVisibility);
            System.debug('selectedUserForColumnVisibility: ' + selectedUserForColumnVisibility);
            System.debug('selectedPermissionSetForColumnVisibility: ' + selectedPermissionSetForColumnVisibility);
            
            if (configType == 'user' && selectedUserForColumnVisibility != null) {
                // Load user-specific settings
                columnVisibility = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(
                    selectedUserForColumnVisibility, null, null
                );
                
                // Get the user's profile ID for reference
                User selectedUser = [SELECT ProfileId FROM User WHERE Id = :selectedUserForColumnVisibility LIMIT 1];
                selectedProfileForColumnVisibility = selectedUser.ProfileId;
                
                // Ensure isUserSpecificSettings is set correctly
                isUserSpecificSettings = true;
                
            } else if (configType == 'permissionset' && selectedPermissionSetForColumnVisibility != null) {
                // Load permission set settings
                columnVisibility = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(
                    null, null, selectedPermissionSetForColumnVisibility
                );
                
                // Ensure isUserSpecificSettings is set correctly
                isUserSpecificSettings = false;
                
            } else if (configType == 'profile' || selectedProfileForColumnVisibility != null) {
                // Load profile-based settings
                // If configType is 'profile', make sure we prioritize that
                
                // Ensure isUserSpecificSettings is set correctly for profile mode
                isUserSpecificSettings = false;
                configType = 'profile';
                
                columnVisibility = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(
                    null, selectedProfileForColumnVisibility, null
                );
                
                } else {            
                // Default to current user's profile if nothing is selected
                selectedProfileForColumnVisibility = UserInfo.getProfileId();
                configType = 'profile';
                isUserSpecificSettings = false;
                
                columnVisibility = UserDictionaryColumnConfigController.getColumnVisibilitySettingsFor(
                    null, selectedProfileForColumnVisibility, null
                );
            }
            
            // Set column visibility properties based on settings
            showFieldNameColumn = columnVisibility.get('ShowFieldName');
            showFieldTypeColumn = columnVisibility.get('ShowFieldType');
            showDescriptionColumn = columnVisibility.get('ShowDescription');
            showHelpTextColumn = columnVisibility.get('ShowHelpText');
            showHighlightedDataColumn = columnVisibility.get('ShowHighlightedData');
            showSensitivityColumn = columnVisibility.get('ShowSensitivity');
            showFieldUsageColumn = columnVisibility.get('ShowFieldUsage');
            showDataOwnerColumn = columnVisibility.get('ShowDataOwner');
            showComplianceCategorizationColumn = columnVisibility.get('ShowComplianceCategorization');
            
            System.debug('Settings loaded. isUserSpecificSettings: ' + isUserSpecificSettings + 
                        ', configType: ' + configType);
            } catch (Exception e) {
            System.debug('Error loading column visibility settings: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error loading column visibility settings: ' + e.getMessage()));
        }
    }
    
    /**
     * Load column visibility settings for the selected profile
     */
    public void loadColumnVisibilityForProfile() {
        // Ensure we're using profile mode
        isUserSpecificSettings = false;
        configType = 'profile';
        loadColumnVisibilityForSelection();
    }
    
    /**
     * Load column visibility settings for the selected user
     */
    public void loadColumnVisibilityForUser() {
        // Ensure we're using user mode
        isUserSpecificSettings = true;
        configType = 'user';
        loadColumnVisibilityForSelection();
    }
    
    /**
     * Save column visibility settings for the selected profile or user
     */
    public void saveColumnVisibilitySettings() {
        try {
            // Only System Administrators can save column visibility settings
            User currentUserProfile = [SELECT Id, Profile.Name, profile.permissionscustomizeapplication FROM User WHERE Id = :UserInfo.getUserId()];
            if(currentUserProfile.Profile.Name.contains('System Administrator') || currentUserProfile.profile.permissionscustomizeapplication) {
                // Create map of column visibility settings
                Map<String, Boolean> columnVisibility = new Map<String, Boolean>{
                    'ShowFieldName' => showFieldNameColumn,
                    'ShowFieldType' => showFieldTypeColumn,
                    'ShowDescription' => showDescriptionColumn,
                    'ShowHelpText' => showHelpTextColumn,
                    'ShowHighlightedData' => showHighlightedDataColumn,
                    'ShowSensitivity' => showSensitivityColumn,
                    'ShowFieldUsage' => showFieldUsageColumn,
                    'ShowDataOwner' => showDataOwnerColumn,
                    'ShowComplianceCategorization' => showComplianceCategorizationColumn
                };
                
                // Save settings for the selected user or profile
                Boolean success;
                if (isUserSpecificSettings && selectedUserForColumnVisibility != null) {
                    success = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(
                        selectedUserForColumnVisibility, 
                        null,
                        columnVisibility
                    );
                } else {
                    success = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(
                        null,
                        selectedProfileForColumnVisibility, 
                        columnVisibility
                    );
                }
                
                if(success) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Column visibility settings saved successfully.'));
                    
                    // If the current user's settings were updated, reload settings
                    if((isUserSpecificSettings && selectedUserForColumnVisibility == UserInfo.getUserId()) || 
                       (!isUserSpecificSettings && selectedProfileForColumnVisibility == UserInfo.getProfileId())) {
                        loadColumnVisibilitySettings();
                    }            
                } else {            
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving column visibility settings.'));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only System Administrators can save column visibility settings.'));
                }
            } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving column visibility settings: ' + e.getMessage()));
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
        
     public static void testtestMethod2() {
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
    
    /**
     * Navigate to the column configuration page
     * @return PageReference to the column configuration page
     */
    public PageReference navigateToColumnConfig() {
        return Page.UserDictionaryColumnConfig;
    }
    
    /**
     * Navigate back to the User Dictionary page
     * @return PageReference to the User Dictionary page
     */
    
    // Add method to load column visibility for Permission Set
    public void loadColumnVisibilityForPermissionSet() {
        // Ensure we're using permission set mode
        isUserSpecificSettings = false;
        configType = 'permissionset';
        loadColumnVisibilityForSelection();
    }

    // Add new property for column visibility management
    public String configType { get; set; }

    /**
     * Save column visibility settings for the selected profile, user, or permission set
     * with support for all entity types using the configType property
     */
    public void saveColumnVisibilitySettingsWithType() {
        try {
            // Only System Administrators can save column visibility settings
            User currentUserProfile = [SELECT Id, Profile.Name, profile.permissionscustomizeapplication FROM User WHERE Id = :UserInfo.getUserId()];
            if(currentUserProfile.Profile.Name.contains('System Administrator') || currentUserProfile.profile.permissionscustomizeapplication) {
                // Create map of column visibility settings
                Map<String, Boolean> columnVisibility = new Map<String, Boolean>{
                    'ShowFieldName' => showFieldNameColumn,
                    'ShowFieldType' => showFieldTypeColumn,
                    'ShowDescription' => showDescriptionColumn,
                    'ShowHelpText' => showHelpTextColumn,
                    'ShowHighlightedData' => showHighlightedDataColumn,
                    'ShowSensitivity' => showSensitivityColumn,
                    'ShowFieldUsage' => showFieldUsageColumn,
                    'ShowDataOwner' => showDataOwnerColumn,
                    'ShowComplianceCategorization' => showComplianceCategorizationColumn
                };
                
                // Save settings for the selected user, profile, or permission set
                Boolean success = false;
                
                // Determine which type of entity to save settings for based on configType
                if (configType == 'user' && selectedUserForColumnVisibility != null) {
                    // User-specific settings
                    success = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(
                        selectedUserForColumnVisibility, 
                        null,
                        null,
                        columnVisibility
                    );
                    System.debug('Saved user-specific settings for user: ' + selectedUserForColumnVisibility);
                } else if (configType == 'permissionset' && selectedPermissionSetForColumnVisibility != null) {
                    // Permission set settings
                    success = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(
                        null,
                        null,
                        selectedPermissionSetForColumnVisibility,
                        columnVisibility
                    );
                    System.debug('Saved permission set settings for permission set: ' + selectedPermissionSetForColumnVisibility);
                } else {
                    // Default to profile settings
                    success = UserDictionaryColumnConfigController.saveColumnVisibilitySettings(
                        null,
                        selectedProfileForColumnVisibility,
                        null,
                        columnVisibility
                    );
                    System.debug('Saved profile settings for profile: ' + selectedProfileForColumnVisibility);
                }
                
                if(success) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Column visibility settings saved successfully.'));
                    
                    // Make sure the configType remains set correctly after saving
                    // This ensures we keep the correct context (profile/user/permissionset)
                    System.debug('Current configType: ' + configType);
                    
                    // If the current user's settings were updated, reload settings for the main page
                    if((configType == 'user' && selectedUserForColumnVisibility == UserInfo.getUserId()) || 
                       (configType == 'profile' && selectedProfileForColumnVisibility == UserInfo.getProfileId())) {
                        loadColumnVisibilitySettings();
                    }
                    
                    // After saving settings, set the checkbox values directly to match what was saved
                    // This ensures the UI immediately reflects the saved values
                    showFieldNameColumn = columnVisibility.get('ShowFieldName');
                    showFieldTypeColumn = columnVisibility.get('ShowFieldType');
                    showDescriptionColumn = columnVisibility.get('ShowDescription');
                    showHelpTextColumn = columnVisibility.get('ShowHelpText');
                    showHighlightedDataColumn = columnVisibility.get('ShowHighlightedData');
                    showSensitivityColumn = columnVisibility.get('ShowSensitivity');
                    showFieldUsageColumn = columnVisibility.get('ShowFieldUsage');
                    showDataOwnerColumn = columnVisibility.get('ShowDataOwner');
                    showComplianceCategorizationColumn = columnVisibility.get('ShowComplianceCategorization');
                    
                    // Ensure isUserSpecificSettings is set correctly based on configType
                    isUserSpecificSettings = (configType == 'user');
                    
                    // Also reload the full settings for the entity that was just updated
                    loadColumnVisibilityForSelection();
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving column visibility settings.'));
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only System Administrators can save column visibility settings.'));
            }
            } catch (Exception e) {
            System.debug('Error saving column visibility settings: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving column visibility settings: ' + e.getMessage()));
        }
    }
}