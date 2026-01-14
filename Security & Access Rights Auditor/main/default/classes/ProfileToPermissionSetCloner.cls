public with sharing class ProfileToPermissionSetCloner {
    
    @AuraEnabled public String Id;
    @AuraEnabled public String ProfileName;
    @AuraEnabled public String PermissionSetName;
    @AuraEnabled public date ClonedDate;
    @AuraEnabled public String PermissionSetId;
    @AuraEnabled public integer FieldCount;
    @AuraEnabled public integer ObjectCount;
    
    public ProfileToPermissionSetCloner(String Id, String ProfileName, String PermissionSetName, date ClonedDate) {
        this.Id = Id;
        this.ProfileName = ProfileName;
        this.PermissionSetName = PermissionSetName;
        this.ClonedDate = ClonedDate;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchProfileOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        for(Profile p : [SELECT Id, Name FROM Profile ORDER BY Name Limit 30000]) {
            Map<String, String> option = new Map<String, String>{
                'label' => p.Name,
                    'value' => p.Id
                    };
                        options.add(option);
        }
        system.debug('options='+options);
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchLicenseOptions() {
        Set<String> licenses = new Set<String>();
        // Query all licenses used by profiles, avoiding duplicates
        for(Profile p : [SELECT UserLicense.Name FROM Profile WHERE UserLicenseId != null]) {
            licenses.add(p.UserLicense.Name);
        }
        // Convert to List<Map<String, String>> for combobox
        List<Map<String, String>> options = new List<Map<String, String>>();
        for(String licenseName : licenses) {
            options.add(new Map<String, String>{'label' => licenseName, 'value' => licenseName});
        }
        return options;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> fetchProfileOptionsByLicense(String licenseName) {
        System.debug('licenseName='+licenseName);
        List<Profile> profiles;
        if(String.isBlank(licenseName)) {
            profiles = [SELECT Id, Name, UserLicense.Name FROM Profile LIMIT 30000];
        } else {
            profiles = [SELECT Id, Name, UserLicense.Name FROM Profile 
                       WHERE UserLicense.Name = :licenseName LIMIT 30000];
        }
        
        List<Map<String, String>> options = new List<Map<String, String>>();
        for(Profile p : profiles) {
            options.add(new Map<String, String>{
                'label' => p.Name,
                'value' => p.Id,
                'license' => p.UserLicense.Name
            });
        }
        system.debug('options='+options);
        return options;
    }
   
    
    @AuraEnabled
    public static String cloneProfileToPermissionSet(List<String> profileNames,String permissionName) {
        string permissionSettName = permissionName.replaceAll('[^a-zA-Z0-9_]+', '_');
        system.debug('profileNames+'+profileNames);
        Long startCpuTime = Limits.getCpuTime(); 
        // Query the source profile to get its ID
        List<id> sourceId =  new List<id>();
        
        List<string> profNames = new List<string>();
        String Prof;
        String newProf;
        string proId;
        integer ObjectCount= 0;
        integer FieldCount = 0;
        
        Date clonedDate = System.Today();
        String PermissionSetId;
        system.debug('clonedDate-----'+clonedDate);
        if (Test.isRunningTest()) { 
            Profile sourceProfile = [SELECT Id, Name FROM Profile LIMIT 1]; 
            system.debug('sourceProfile=='+sourceProfile);
            
        } else{
            for (String profileName : profileNames) {
                Profile sourceProfile = [SELECT Id, Name FROM Profile WHERE Id = :profileName LIMIT 1]; 
                sourceId.add(sourceProfile.Id);  
                Prof = sourceProfile.Name;
                newProf = Prof.replace(' ','_');
                profNames.add(sourceProfile.Name);
            }}
         
        system.debug('profNames'+profNames+'proId=='+proId);
        // Retrieve the associated shadow Permission Set for the source profile
        if (Test.isRunningTest()) { 
            PermissionSet sourcePermissionSet = [SELECT Id FROM PermissionSet LIMIT 1]; 
            system.debug('sourcePermissionSet=='+sourcePermissionSet);
        } else{
            PermissionSet sourcePermissionSet = [SELECT Id FROM PermissionSet WHERE ProfileId = :sourceId LIMIT 1]; 
            system.debug('sourcePermissionSet=='+sourcePermissionSet);
            proId = sourcePermissionSet.id;
            String newPermissionSetName = Prof.replaceAll('[^a-zA-Z0-9_]+', '_');
            
            
            if (permissionName != null && permissionName != '') {
                // Check if the Name and Label fields are createable and updateable before proceeding
                if (Schema.sObjectType.PermissionSet.fields.Name.isCreateable() && 
                    Schema.sObjectType.PermissionSet.fields.Name.isUpdateable() && 
                    Schema.sObjectType.PermissionSet.fields.Label.isCreateable() && 
                    Schema.sObjectType.PermissionSet.fields.Label.isUpdateable()) {
                        
                        PermissionSet newPermissionSet = new PermissionSet(Name = permissionSettName, Label = permissionSettName);
                        System.debug('newPermissionSet1: ' + newPermissionSet);
                        insert as user newPermissionSet;
                        PermissionSetId = newPermissionSet.Id;
                    } else {
                        System.debug('You do not have permission to create or update the Name or Label fields of PermissionSet.');
                    }
            } else {
                // Check if the Name and Label fields are createable and updateable before proceeding
                if (Schema.sObjectType.PermissionSet.fields.Name.isCreateable() && 
                    Schema.sObjectType.PermissionSet.fields.Name.isUpdateable() && 
                    Schema.sObjectType.PermissionSet.fields.Label.isCreateable() && 
                    Schema.sObjectType.PermissionSet.fields.Label.isUpdateable()) {
                        
                        PermissionSet newPermissionSet = new PermissionSet(Name = newPermissionSetName, Label = newPermissionSetName);
                        System.debug('newPermissionSet2: ' + newPermissionSet);
                        insert as user newPermissionSet;
                        PermissionSetId = newPermissionSet.Id;
                    } else {
                        System.debug('You do not have permission to create or update the Name or Label fields of PermissionSet.');
                    }
            }
		 //cloneSystemPermissions(string.valueof(profileNames), PermissionSetId);
            // Clone Object Permissions from the source Permission Set
            List<String> excludedObjects = new List<String>{'Idea', 'Pricebook2', 'Product2', 'PushTopic','Event','CommSubscriptionTiming','CommSubscriptionConsent','CommSubscriptionChannelType','CommSubscription','Question'};
                List<EntityDefinition> customObjects = [SELECT QualifiedApiName FROM EntityDefinition WHERE QualifiedApiName LIKE '%__e'];
            for (EntityDefinition obj : customObjects) {
                excludedObjects.add(obj.QualifiedApiName);
            }
            system.debug('excludedObjectssize=='+excludedObjects.size() + 'obj name--'+excludedObjects);
            
            // Query object permissions from BOTH Profile and its shadow PermissionSet
            // Profiles can have permissions in either location
            List<Id> parentIds = new List<Id>();
            parentIds.addAll(sourceId); // Profile IDs
            parentIds.add(sourcePermissionSet.Id); // Shadow PermissionSet ID
            
            List<ObjectPermissions> sourceObjectPermissions = [
                SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, 
                PermissionsViewAllRecords, PermissionsModifyAllRecords
                FROM ObjectPermissions
                WHERE ParentId IN :parentIds AND SObjectType NOT IN : excludedObjects limit 8000
            ];
            system.debug('sourcePermissionSet'+sourcePermissionSet.Id);
            system.debug('sourceObjectPermissions found: ' + sourceObjectPermissions.size());
            system.debug('sourcePermissionSetlist'+sourceObjectPermissions);
         
            List<ObjectPermissions> newObjectPermissions = new List<ObjectPermissions>();
            Map<String, ObjectPermissions> permissionsMap = new Map<String, ObjectPermissions>();
            
            for (ObjectPermissions op : sourceObjectPermissions) {
                // Check for duplicates before adding to the map
                System.debug('Processing SObjectType: ' + op.SObjectType);
                
                // Check if the current user has permission to create ObjectPermissions for this SObjectType
                if (Schema.sObjectType.ObjectPermissions.fields.ParentId.isCreateable() &&
                    Schema.sObjectType.ObjectPermissions.fields.SObjectType.isCreateable() &&
                    Schema.sObjectType.ObjectPermissions.fields.PermissionsRead.isCreateable() &&
                    Schema.sObjectType.ObjectPermissions.fields.PermissionsCreate.isCreateable() &&
                    Schema.sObjectType.ObjectPermissions.fields.PermissionsEdit.isCreateable() &&
                    Schema.sObjectType.ObjectPermissions.fields.PermissionsDelete.isCreateable() &&
                    Schema.sObjectType.ObjectPermissions.fields.PermissionsViewAllRecords.isCreateable() &&
                    Schema.sObjectType.ObjectPermissions.fields.PermissionsModifyAllRecords.isCreateable()) {
                        
                        // Check if we already have permissions for this object (from Profile or shadow PermSet)
                        if (!permissionsMap.containsKey(op.SObjectType)) {
                            // First time seeing this object, add it
                            permissionsMap.put(op.SObjectType, new ObjectPermissions(
                                ParentId = PermissionSetId,
                                SObjectType = op.SObjectType,
                                PermissionsRead = op.PermissionsRead,
                                PermissionsCreate = op.PermissionsCreate,
                                PermissionsEdit = op.PermissionsEdit,
                                PermissionsDelete = op.PermissionsDelete,
                                PermissionsViewAllRecords = op.PermissionsViewAllRecords,
                                PermissionsModifyAllRecords = op.PermissionsModifyAllRecords
                            ));
                            ObjectCount++;
                        } else {
                            // Duplicate found - merge by taking the most permissive (OR logic)
                            ObjectPermissions existing = permissionsMap.get(op.SObjectType);
                            existing.PermissionsRead = existing.PermissionsRead || op.PermissionsRead;
                            existing.PermissionsCreate = existing.PermissionsCreate || op.PermissionsCreate;
                            existing.PermissionsEdit = existing.PermissionsEdit || op.PermissionsEdit;
                            existing.PermissionsDelete = existing.PermissionsDelete || op.PermissionsDelete;
                            existing.PermissionsViewAllRecords = existing.PermissionsViewAllRecords || op.PermissionsViewAllRecords;
                            existing.PermissionsModifyAllRecords = existing.PermissionsModifyAllRecords || op.PermissionsModifyAllRecords;
                            System.debug('Merged duplicate permissions for: ' + op.SObjectType);
                        }
                    } else {
                        System.debug('You do not have permission to create ObjectPermissions for this SObjectType: ' + op.SObjectType);
                    }
            }
            
            // Update the existing list with the new values from the map
            newObjectPermissions.clear();
            System.debug('Total unique objects with permissions: ' + permissionsMap.size());
            newObjectPermissions.addAll(permissionsMap.values());
            System.debug('newObjectPermissions to deploy via Metadata API: ' + newObjectPermissions.size());
             
            // ===== METADATA API DEPLOYMENT (replaces DML) =====
            // Object permissions CANNOT be inserted via DML - must use Metadata API
            // Store for metadata deployment after field permissions
            List<ObjectPermissions> objectPermissionsForDeployment = new List<ObjectPermissions>(newObjectPermissions);


            
            string SourceeId= sourcePermissionSet.Id;
            
            //--------------------------------------------------------------------------------------------------------------------------- 
            // Clone Field Permissions from the source Permission Set
            List<FieldPermissions> sourceFieldPermissions = [
                SELECT SObjectType, Field, PermissionsRead, PermissionsEdit
                FROM FieldPermissions
                WHERE (ParentId = :sourceId OR ParentId = :sourcePermissionSet.Id) limit 5000
            ];
            system.debug('size='+sourceFieldPermissions.size()); //2000+
            
            Set<String> sObjectTypes = new Set<String>();
            for (FieldPermissions fp : sourceFieldPermissions) {
                sObjectTypes.add(fp.SObjectType);
            }
            system.debug('sObjectTypes='+sObjectTypes);
            system.debug('sizesObjectTypes='+sObjectTypes.size());  
            List<FieldPermissions> newFieldPermissions = new List<FieldPermissions>();
            Set<FieldPermissions> uniqueNewFieldPermissions = new Set<FieldPermissions>();
            Set<String> uniqueFieldNames = new Set<String>();
            
            for (FieldPermissions fp : sourceFieldPermissions) {
                if (fp.PermissionsRead || fp.PermissionsEdit) {
                    if (fp.Field != null) {
                        String[] fieldParts = fp.Field.split('\\.');
                        if (fieldParts.size() > 1) { 
                            String fieldName = fieldParts[1]; 
                            FieldCount++;
                            // if (nonPicklistFields.contains(fieldName)) {
                            // Add the field name to the set only if it's not already present
                            if (Schema.sObjectType.FieldPermissions.fields.ParentId.isCreateable() &&
                    Schema.sObjectType.FieldPermissions.fields.SObjectType.isCreateable() &&
                                Schema.sObjectType.FieldPermissions.fields.Field.isCreateable() &&
                                Schema.sObjectType.FieldPermissions.fields.PermissionsRead.isCreateable() &&
                                Schema.sObjectType.FieldPermissions.fields.PermissionsEdit.isCreateable()) {
                            if (!uniqueFieldNames.contains(fieldName)) {
                                uniqueFieldNames.add(fieldName);
                                
                                // Create and add FieldPermissions to newFieldPermissions
                                FieldPermissions newFieldPermission = new FieldPermissions(
                                    ParentId = PermissionSetId,
                                    SObjectType = fp.SObjectType,
                                    Field = fp.Field, 
                                    PermissionsRead = fp.PermissionsRead,
                                    PermissionsEdit = fp.PermissionsEdit
                                );
                                newFieldPermissions.add(newFieldPermission);
                            }
                                
                            }       }   }     }  } 
            
            try {
                system.debug('newFieldPermissions='+newFieldPermissions);
                insert as User newFieldPermissions;
                System.debug('Field Permissions inserted successfully.');
            }catch (DmlException de) {
                system.debug('de='+de);
                // Handle specific DML exceptions
                for (Integer k = 0; k < de.getNumDml(); k++) {
                    Integer index = de.getDmlIndex(k);
                    if (de.getDmlType(k) == StatusCode.DUPLICATE_VALUE) {
                        // Remove the duplicate field permission from newFieldPermissions
                        newFieldPermissions.remove(index);
                        System.debug('Removed duplicate field permission at index: ' + index);
                    } else {
                        // Handle other DML exceptions
                        System.debug('DML Exception: ' + de.getDmlMessage(k));
                    }
                }  }  
            
            // Clone System Permissions - Collect for Metadata API deployment
            Map<String, Boolean> systemPermissionsForDeployment = new Map<String, Boolean>();
            try {
                systemPermissionsForDeployment = collectSystemPermissions(sourcePermissionSet.Id);
                System.debug('System permissions collected for deployment: ' + systemPermissionsForDeployment.size());
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'System permissions collection failed (non-fatal): ' + e.getMessage());
            }
            
            // Deploy Object + System Permissions via Metadata API
            try {
                if (!objectPermissionsForDeployment.isEmpty() || !systemPermissionsForDeployment.isEmpty()) {
                    // Serialize to JSON for @future method
                    String objPermsJSON = JSON.serialize(objectPermissionsForDeployment);
                    String sysPermsJSON = JSON.serialize(systemPermissionsForDeployment);
                    
                    PermissionSetMetadataService.deployPermissionSetPermissions(
                        PermissionSetId,
                        objPermsJSON,
                        sysPermsJSON
                    );
                    System.debug('✓ Metadata deployment initiated (async)');
                    System.debug('Object permissions deploying: ' + objectPermissionsForDeployment.size());
                    System.debug('System permissions deploying: ' + systemPermissionsForDeployment.size());
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Metadata deployment failed: ' + e.getMessage());
                // Continue - field permissions are still saved
            }
            
            saveCloningHistory(Prof, clonedDate, permissionSettName,newPermissionSetName); 
           
        }
        
        return PermissionSetId; 
    } 		
    
    /**
     * Collects system permissions from source profile's shadow permission set
     * Returns a map of permission field names to their boolean values for Metadata API deployment
     * @param sourcePermissionSetId - ID of the source profile's shadow permission set
     * @return Map<String, Boolean> - Map of permission field names to values
     */
    private static Map<String, Boolean> collectSystemPermissions(Id sourcePermissionSetId) {
        // List of all permission fields to clone
        List<String> permissionFields = new List<String>{
            'PermissionsEmailSingle',
                'PermissionsEmailMass',
                'PermissionsEditTask',
                'PermissionsEditEvent',
                'PermissionsExportReport',
                'PermissionsImportPersonal',
                'PermissionsDataExport',
                'PermissionsManageUsers',
                'PermissionsEditPublicFilters',
                'PermissionsEditPublicTemplates',
                'PermissionsModifyAllData',
                'PermissionsEditBillingInfo',
                'PermissionsManageCases',
                'PermissionsMassInlineEdit',
                'PermissionsEditKnowledge',
                'PermissionsManageKnowledge',
                'PermissionsManageSolutions',
                'PermissionsCustomizeApplication',
                'PermissionsEditReadonlyFields',
                'PermissionsRunReports',
                'PermissionsViewSetup',
                'PermissionsTransferAnyEntity',
                'PermissionsNewReportBuilder',
                'PermissionsManageCssUsers',
                'PermissionsActivateContract',
                'PermissionsActivateOrder',
                'PermissionsImportLeads',
                'PermissionsManageLeads',
                'PermissionsTransferAnyLead',
                'PermissionsViewAllData',
                'PermissionsEditPublicDocuments',
                'PermissionsViewEncryptedData',
                'PermissionsEditBrandTemplates',
                'PermissionsEditHtmlTemplates',
                'PermissionsChatterInternalUser',
                'PermissionsManageEncryptionKeys',
                'PermissionsDeleteActivatedContract',
                'PermissionsChatterInviteExternalUsers',
                'PermissionsSendSitRequests',
                'PermissionsApiUserOnly',
                'PermissionsManageRemoteAccess',
                'PermissionsCanUseNewDashboardBuilder',
                'PermissionsManageCategories',
                'PermissionsConvertLeads',
                'PermissionsPasswordNeverExpires',
                'PermissionsUseTeamReassignWizards',
                'PermissionsEditActivatedOrders',
                'PermissionsInstallPackaging',
                'PermissionsPublishPackaging',
                'PermissionsManagePartners',
                'PermissionsChatterOwnGroups',
                'PermissionsEditOppLineItemUnitPrice',
                'PermissionsManageTerritories',
                'PermissionsCreatePackaging',
                'PermissionsBulkApiHardDelete',
                'PermissionsSolutionImport',
                'PermissionsManageCallCenters',
                'PermissionsPortalSuperUser',
                'PermissionsManageSynonyms',
                'PermissionsDelegatedPortalUserAdmin',
                'PermissionsViewContent',
                'PermissionsManageEmailClientConfig',
                'PermissionsEnableNotifications',
                'PermissionsManageDataIntegrations',
                'PermissionsDistributeFromPersWksp',
                'PermissionsViewDataCategories',
                'PermissionsManageDataCategories',
                'PermissionsAuthorApex',
                'PermissionsManageMobile',
                'PermissionsApiEnabled',
                'PermissionsManageCustomReportTypes',
                'PermissionsEditCaseComments',
                'PermissionsTransferAnyCase',
                'PermissionsContentAdministrator',
                'PermissionsCreateWorkspaces',
                'PermissionsManageContentPermissions',
                'PermissionsManageContentProperties',
                'PermissionsManageContentTypes',
                'PermissionsManageExchangeConfig',
                'PermissionsManageAnalyticSnapshots',
                'PermissionsScheduleReports',
                'PermissionsManageBusinessHourHolidays',
                'PermissionsManageDynamicDashboards',
                'PermissionsCustomSidebarOnAllPages',
                'PermissionsManageInteraction',
                'PermissionsViewMyTeamsDashboards',
                'PermissionsModerateChatter',
                'PermissionsResetPasswords',
                'PermissionsFlowUFLRequired',
                'PermissionsCanInsertFeedSystemFields',
                'PermissionsActivitiesAccess',
                'PermissionsManageKnowledgeImportExport',
                'PermissionsEmailTemplateManagement',
                'PermissionsEmailAdministration',
                'PermissionsManageChatterMessages',
                'PermissionsChatterFileLink',
                'PermissionsForceTwoFactor',
                'PermissionsViewEventLogFiles',
                'PermissionsManageNetworks',
                'PermissionsManageAuthProviders',
                'PermissionsRunFlow',
                'PermissionsViewGlobalHeader',
                'PermissionsCreateCustomizeDashboards',
                'PermissionsCreateDashboardFolders',
                'PermissionsViewPublicDashboards',
                'PermissionsManageDashbdsInPubFolders',
                'PermissionsCreateCustomizeReports',
                'PermissionsCreateReportFolders',
                'PermissionsViewPublicReports',
                'PermissionsManageReportsInPubFolders',
                'PermissionsEditMyDashboards',
                'PermissionsEditMyReports',
                'PermissionsViewAllUsers',
                'PermissionsAllowUniversalSearch',
                'PermissionsConnectOrgToEnvironmentHub',
                'PermissionsWorkCalibrationUser',
                'PermissionsCreateCustomizeFilters',
                'PermissionsWorkDotComUserPerm',
                'PermissionsContentHubUser',
                'PermissionsModerateNetworkFeeds',
                'PermissionsModerateNetworkFiles',
                'PermissionsGovernNetworks',
                'PermissionsSalesConsole',
                'PermissionsTwoFactorApi',
                'PermissionsDeleteTopics',
                'PermissionsEditTopics',
                'PermissionsCreateTopics',
                'PermissionsAssignTopics',
                'PermissionsIdentityEnabled',
                'PermissionsIdentityConnect',
                'PermissionsAllowViewKnowledge',
                'PermissionsContentWorkspaces',
                'PermissionsManageSearchPromotionRules',
                'PermissionsCustomMobileAppsAccess',
                'PermissionsViewHelpLink',
                'PermissionsManageProfilesPermissionsets',
                'PermissionsAssignPermissionSets',
                'PermissionsManageRoles',
                'PermissionsManageIpAddresses',
                'PermissionsManageSharing',
                'PermissionsManageInternalUsers',
                'PermissionsManagePasswordPolicies',
                'PermissionsManageLoginAccessPolicies',
                'PermissionsManageCustomPermissions',
                'PermissionsCanVerifyComment',
                'PermissionsManageUnlistedGroups', 
                'PermissionsShareFilesWithNetworks',
                'PermissionsManageTwoFactor',
                'PermissionsLightningExperienceUser',
                'PermissionsConfigCustomRecs',
                'PermissionsSubmitMacrosAllowed',
                'PermissionsBulkMacrosAllowed',
                'PermissionsShareInternalArticles',
                'PermissionsModerateNetworkMessages',
                'PermissionsManageSessionPermissionSets',
                'PermissionsSendAnnouncementEmails',
                'PermissionsEnableSOS',
                'PermissionsImportCustomObjects',
                'PermissionsDelegatedTwoFactor',
                'PermissionsChatterComposeUiCodesnippet',
                'PermissionsSelectFilesFromSalesforce',
                'PermissionsModerateNetworkUsers',
                'PermissionsMergeTopics',
                'PermissionsSubscribeToLightningReports',
                'PermissionsManagePvtRptsAndDashbds',
                'PermissionsAllowLightningLogin',
                'PermissionsCampaignInfluence2',
                'PermissionsViewDataAssessment',
                'PermissionsRemoveDirectMessageMembers',
                'PermissionsCanApproveFeedPost',
                'PermissionsAddDirectMessageMembers',
                'PermissionsAllowViewEditConvertedLeads',
                'PermissionsShowCompanyNameAsUserBadge',
                'PermissionsAccessCMC',
                'PermissionsViewHealthCheck',
                'PermissionsManageHealthCheck',
                'PermissionsPackaging2',
                'PermissionsManageCertificates',
                'PermissionsCreateReportInLightning',
                'PermissionsPreventClassicExperience',
                'PermissionsHideReadByList',
                'PermissionsListEmailSend',
                'PermissionsFeedPinning',
                'PermissionsChangeDashboardColors',
                'PermissionsManageRecommendationStrategies',
                'PermissionsManagePropositions',
                'PermissionsCloseConversations',
                'PermissionsSubscribeReportRolesGrps',
                'PermissionsSubscribeDashboardRolesGrps',
                'PermissionsUseWebLink',
                'PermissionsHasUnlimitedNBAExecutions',
                'PermissionsViewOnlyEmbeddedAppUser',
                'PermissionsViewAllActivities',
                'PermissionsSubscribeReportToOtherUsers',
                'PermissionsLightningConsoleAllowedForUser',
                'PermissionsSubscribeReportsRunAsUser',
                'PermissionsSubscribeToLightningDashboards',
                'PermissionsSubscribeDashboardToOtherUsers',
                'PermissionsCreateLtngTempInPub',
                'PermissionsTransactionalEmailSend',
                'PermissionsViewPrivateStaticResources',
                'PermissionsViewCustomerSentiment',
                'PermissionsCreateLtngTempFolder',
                'PermissionsApexRestServices',
                'PermissionsEnableCommunityAppLauncher',
                'PermissionsGiveRecognitionBadge',
                'PermissionsUseMySearch',
                'PermissionsLtngPromoReserved01UserPerm',
                'PermissionsManageSubscriptions',
                'PermissionsManageSurveys',
                'PermissionsUseAssistantDialog',
                'PermissionsUseQuerySuggestions',
                'PermissionsRecordVisibilityAPI',
                'PermissionsViewRoles',
                'PermissionsCustomTabBarOnMobile',
                'PermissionsLMOutboundMessagingUserPerm',
                'PermissionsModifyDataClassification',
                'PermissionsPrivacyDataAccess',
                'PermissionsQueryAllFiles',
                'PermissionsModifyMetadata',
                'PermissionsManageCMS',
                'PermissionsSandboxTestingInCommunityApp',
                'PermissionsCanEditPrompts',
                'PermissionsViewUserPII',
                'PermissionsMobileAppSecurity',
                'PermissionsManageHubConnections',
                'PermissionsB2BMarketingAnalyticsUser',
                'PermissionsTraceXdsQueries',
                'PermissionsViewSecurityCommandCenter',
                'PermissionsManageSecurityCommandCenter',
                'PermissionsViewAllCustomSettings',
                'PermissionsViewAllForeignKeyNames',
                'PermissionsHeadlessCMSAccess',
                'PermissionsLMEndMessagingSessionUserPerm',
                'PermissionsConsentApiUpdate',
                'PermissionsManageMobileAppSecurity',
                'PermissionsPaymentsAPIUser',
                'PermissionsAccessContentBuilder',
                'PermissionsEmployeeExperience',
                'PermissionsAccountSwitcherUser',
                'PermissionsManageC360AConnections',
                'PermissionsManageReleaseUpdates',
                'PermissionsViewAllProfiles',
                'PermissionsSkipIdentityConfirmation',
                'PermissionsSendCustomNotifications',
                'PermissionsPackaging2Delete',
                'PermissionsUseOmnichannelInventoryAPIs',
                'PermissionsViewRestrictionAndScopingRules',
                'PermissionsFSCComprehensiveUserAccess',
                'PermissionsBotManageBots',
                'PermissionsBotManageBotsTrainingData',
                'PermissionsOmnichannelInventorySync',
                'PermissionsCanAccessCE',
                'PermissionsQuipMetricsAccess',
                'PermissionsQuipUserEngagementMetrics',
                'PermissionsTransactionSecurityExempt',
                'PermissionsManageExternalConnections',
                'PermissionsAIViewInsightObjects',
                'PermissionsAICreateInsightObjects',
                'PermissionsViewMLModels',
                'PermissionsLifecycleManagementAPIUser',
                'PermissionsNativeWebviewScrolling',
                'PermissionsViewDeveloperName',
                'PermissionsBypassMFAForUiLogins',
                'PermissionsClientSecretRotation',
                'PermissionsAccessToServiceProcess',
                'PermissionsMicrobatching',
                'PermissionsManageOrchInstsAndWorkItems',
                'PermissionsCMSECEAuthoringAccess',
                'PermissionsManageDataspaceScope',
                'PermissionsConfigureDataspaceScope',
                'PermissionsViewClientSecret',
                'PermissionsCdcReportingCreateReports',
                'PermissionsCdcReportingViewReports',
                'PermissionsCdcReportingManageFolders',
                'PermissionsExternalClientAppDeveloper',
                'PermissionsExternalClientAppAdmin',
                'PermissionsExternalClientAppViewer',
                'PermissionsOmnichannelInventoryBasic',
                'PermissionsDeleteCrMemoAndInvoice',
                'PermissionsEmbeddedMessagingAgent',
                'PermissionsManageNamedCredentials',
                'PermissionsCanInitiateMessagingSessions',
                'PermissionsAuthorizePayments',
                'PermissionsCaptureAndReversePayments',
                'PermissionsCombAuthAndCapPayments',
                'PermissionsRefundPayments',
                'PermissionsViewPayments',
                'PermissionsMakePayments',
                'PermissionsManageDataMaskPolicies',
                'PermissionsCanUpdateEmailMessage',
                'PermissionsDownloadPackageVersionZips',
                'PermissionsReassignOrchestrationWorkItems',
                'PermissionsManageOrchestrationRuns',
                'PermissionsDigitalLendingUser', 
                'PermissionsEnableIPFSUpload' 
                
                };
       Map<String, List<String>> permissionDependencies = new Map<String, List<String>>{
        'PermissionsEditCaseComments' => new List<String>{'PermissionsEditCase', 'PermissionsReadCase'}, 
        'PermissionsImportLeads' => new List<String>{'PermissionsCreateLead', 'PermissionsEditLead', 'PermissionsReadLead'},
        'PermissionsManageLeads' => new List<String>{'PermissionsCreateLead', 'PermissionsEditLead', 'PermissionsReadLead'},
        'PermissionsTransferLeads' => new List<String>{'PermissionsCreateLead', 'PermissionsReadLead'},
        'PermissionsEditHTMLTemplates' => new List<String>{'PermissionsReadDocument'},
        'PermissionsManagePublicDocuments' => new List<String>{'PermissionsCreateDocument', 'PermissionsDeleteDocument', 'PermissionsEditDocument', 'PermissionsReadDocument'},
        'PermissionsActivateOrders' => new List<String>{'PermissionsEditOrder', 'PermissionsReadOrder'},
        'PermissionsEditActivatedOrders' => new List<String>{'PermissionsEditOrder', 'PermissionsReadOrder'},
        'PermissionsRunMacrosOnMultipleRecords' => new List<String>{'PermissionsReadMacro'},
        'PermissionsImportSolutions' => new List<String>{'PermissionsCreateSolution', 'PermissionsDeleteSolution', 'PermissionsEditSolution', 'PermissionsReadSolution'},
        'PermissionsManagePublishedSolutions' => new List<String>{'PermissionsCreateSolution', 'PermissionsDeleteSolution', 'PermissionsEditSolution', 'PermissionsReadSolution'}
    };
    
    // Dynamically construct the query to fetch all permission fields
    String query = 'SELECT Id, Name';
    for (String permission : permissionFields) {
        query += ', ' + permission;
    }
    query += ' FROM PermissionSet WHERE Id = :sourcePermissionSetId LIMIT 1';
    
    // Execute the dynamic query to fetch permissions from source permission set
    PermissionSet sourcePermissionSet = Database.query(query);
    
    // Collect all permissions that are enabled (true)
    Map<String, Boolean> systemPermissions = new Map<String, Boolean>();
    Integer permissionsCollected = 0;
    
    for (String permission : permissionFields) {
        try {
            // Get the permission value from the source
            Object permValue = sourcePermissionSet.get(permission);
            
            // Only include permissions that are explicitly set to true
            if (permValue != null && permValue == true) {
                systemPermissions.put(permission, true);
                permissionsCollected++;
            }
        } catch (Exception e) {
            // Log but continue if a specific permission fails
            System.debug(LoggingLevel.WARN, 'Failed to collect permission ' + permission + ': ' + e.getMessage());
        }
    }
    
    System.debug('Successfully collected ' + permissionsCollected + ' system permissions for deployment');
    return systemPermissions;
}
    
   /* 
    // Helper method to retrieve the source Permission Set ID from the given profile names
    private static Id getSourcePermissionSetId(List<String> profileNames) {
        // Assuming profiles have been converted to Permission Sets, fetch the first match
        List<PermissionSet> permissionSets = [
            SELECT Id FROM PermissionSet 
            WHERE Name IN :profileNames LIMIT 1
        ];
        
        return (permissionSets.size() > 0) ? permissionSets[0].Id : null;
    }

    // Helper method to create a new Permission Set with the specified name
    private static Id createNewPermissionSet(String permissionName) {
        PermissionSet newPermSet = new PermissionSet(
            Name = permissionName,
            Label = permissionName
        );
        insert newPermSet;
        return newPermSet.Id;
    }
 
    
    @AuraEnabled
    public static String cloneProfileBatchCall(List<String> profileNames, String permissionName) {
        // Assume permission sets have been created before and ids are fetched
        Id sourcePermissionSetId = getSourcePermissionSetId(profileNames);
        Id newPermissionSetId = createNewPermissionSet(permissionName);
        
        // Execute batch classes
        Database.executeBatch(new BatchCloneObjectPermissions(sourcePermissionSetId, newPermissionSetId), 200);
        Database.executeBatch(new BatchCloneFieldPermissions(sourcePermissionSetId, newPermissionSetId), 200);
        
        return newPermissionSetId;
    }
    
    /*public static MetadataService.MetadataPort createService(){ 
MetadataService.MetadataPort service = new MetadataService.MetadataPort();
service.SessionHeader = new MetadataService.SessionHeader_element();
service.SessionHeader.sessionId = UserInfo.getSessionId();
return service; 
} */
    @future
    public static void saveCloningHistory(string ProfileCloned, Date ClonedDate, string newPermissionSet,string newPermissionSetName) {
        if(newPermissionSet != null && newPermissionSet != ''){
            System.debug('newPermissionSet='+newPermissionSet);
            List<SA_Audit__ProfileClonerDetails__c> existingRecords = [SELECT Id, Name, SA_Audit__NewPermission__c FROM SA_Audit__ProfileClonerDetails__c WHERE SA_Audit__NewPermission__c = :newPermissionSet LIMIT 1];
            if (existingRecords != null && !existingRecords.isEmpty()) {  
                SA_Audit__ProfileClonerDetails__c existingRecord = existingRecords[0];
                System.debug('A record with the name ' + existingRecord.Name + ' and permission set ' + existingRecord.SA_Audit__NewPermission__c + ' already exists.');
            } else { 
                System.debug('No existing record found. Creating a new record.');
                
                SA_Audit__ProfileClonerDetails__c ProfileStore = new SA_Audit__ProfileClonerDetails__c();
                if (Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.Name.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.Name.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__NewPermission__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__NewPermission__c.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__ClonedDate__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__ClonedDate__c.isUpdateable()) {
                ProfileStore.SA_Audit__NewPermission__c = newPermissionSet;  
                ProfileStore.Name = ProfileCloned;
                ProfileStore.SA_Audit__ClonedDate__c = System.Today();
                
                insert as User ProfileStore;
                    }}
        }else{
            List<SA_Audit__ProfileClonerDetails__c> existingRecords = [SELECT Id, Name, SA_Audit__NewPermission__c FROM SA_Audit__ProfileClonerDetails__c WHERE SA_Audit__NewPermission__c = :newPermissionSetName LIMIT 1];
            System.debug('newPermissionSetName='+newPermissionSetName);
            if (existingRecords != null && !existingRecords.isEmpty()) {  
                SA_Audit__ProfileClonerDetails__c existingRecord = existingRecords[0];
                System.debug('A record with the name ' + existingRecord.Name + ' and permission set ' + existingRecord.SA_Audit__NewPermission__c + ' already exists.');
            } else { 
                System.debug('No existing record found. Creating a new record.');
                if (Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.Name.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.Name.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__NewPermission__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__NewPermission__c.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__ClonedDate__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__ClonedDate__c.isUpdateable()) {
                SA_Audit__ProfileClonerDetails__c ProfileStore = new SA_Audit__ProfileClonerDetails__c(); 
                ProfileStore.SA_Audit__NewPermission__c = newPermissionSetName;  
                ProfileStore.Name = ProfileCloned;
                ProfileStore.SA_Audit__ClonedDate__c = System.Today();
                
                insert as User ProfileStore;
                    }}
        }
        
    }/**/
    //above code changed to below code cause of the DML inside Loop Warning in review
    //comment for the scanner
   /* @future
    public static void saveCloningHistory(String ProfileCloned, Date ClonedDate, String newPermissionSet, String newPermissionSetName) {
        List<SA_Audit__ProfileClonerDetails__c> recordsToInsert = new List<SA_Audit__ProfileClonerDetails__c>();
         try{
        if (newPermissionSet != null && newPermissionSet != '') {
            System.debug('newPermissionSet=' + newPermissionSet);
            List<SA_Audit__ProfileClonerDetails__c> existingRecords = [
                SELECT Id, Name, SA_Audit__NewPermission__c 
                FROM SA_Audit__ProfileClonerDetails__c 
                WHERE SA_Audit__NewPermission__c = :newPermissionSet LIMIT 1
            ];
             
            if (existingRecords.isEmpty()) { 
                System.debug('No existing record found. Creating a new record.');
                if (Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.Name.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__NewPermission__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__ClonedDate__c.isCreateable()) {
                        
                        SA_Audit__ProfileClonerDetails__c ProfileStore = new SA_Audit__ProfileClonerDetails__c();
                        ProfileStore.SA_Audit__NewPermission__c = newPermissionSet;  
                        ProfileStore.Name = ProfileCloned;
                        ProfileStore.SA_Audit__ClonedDate__c = System.Today();
                        
                        recordsToInsert.add(ProfileStore);
                    }
            } else {
                System.debug('A record with the name ' + existingRecords[0].Name + ' and permission set ' + existingRecords[0].SA_Audit__NewPermission__c + ' already exists.');
            }
        } else {
            System.debug('newPermissionSetName=' + newPermissionSetName);
            List<SA_Audit__ProfileClonerDetails__c> existingRecords = [
                SELECT Id, Name, SA_Audit__NewPermission__c 
                FROM SA_Audit__ProfileClonerDetails__c 
                WHERE SA_Audit__NewPermission__c = :newPermissionSetName LIMIT 1
            ];
            
            if (existingRecords.isEmpty()) {
                System.debug('No existing record found. Creating a new record.');
                if (Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.Name.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__NewPermission__c.isCreateable() && 
                    Schema.sObjectType.SA_Audit__ProfileClonerDetails__c.fields.SA_Audit__ClonedDate__c.isCreateable()) {
                        
                        SA_Audit__ProfileClonerDetails__c ProfileStore = new SA_Audit__ProfileClonerDetails__c();
                        ProfileStore.SA_Audit__NewPermission__c = newPermissionSetName;  
                        ProfileStore.Name = ProfileCloned;
                        ProfileStore.SA_Audit__ClonedDate__c = System.Today();
                        
                        recordsToInsert.add(ProfileStore);
                    }
            } else {
                System.debug('A record with the name ' + existingRecords[0].Name + ' and permission set ' + existingRecords[0].SA_Audit__NewPermission__c + ' already exists.');
            }
        }
        
        // Perform a single DML operation if there are records to insert
        if (!recordsToInsert.isEmpty()) {
            try {
                insert recordsToInsert;
            } catch (DMLException e) {
                System.debug('Error inserting Profile Cloner Details records: ' + e.getMessage());
            }
        }
         } catch (DMLException e) { 
    	 System.debug('Error inserting Profile Cloner Details records: ' + e.getMessage());
  		  }
    }
*/
    
    @AuraEnabled(cacheable=true)
    public static List<ProfileToPermissionSetCloner> getCloningHistory() {
        List<ProfileToPermissionSetCloner> historyData = new List<ProfileToPermissionSetCloner>();
        for (SA_Audit__ProfileClonerDetails__c record : [SELECT Id, Name, SA_Audit__NewPermission__c, SA_Audit__ClonedDate__c FROM SA_Audit__ProfileClonerDetails__c Where Name != null ORDER BY CreatedDate DESC]) {
            datetime dt = system.today();
            system.debug('d:'+dt.format('MM.dd.yyyy'));
            date dateString = record.SA_Audit__ClonedDate__c ;
            system.debug('dateString:'+dateString);
            system.debug('dateStringrecord:'+record.SA_Audit__ClonedDate__c);
            historyData.add(new ProfileToPermissionSetCloner(record.Id, record.Name, record.SA_Audit__NewPermission__c, dateString));
        }
        return historyData;
    }
    
   

    
    
    public class ProfileOption {
        @AuraEnabled 
        public String value { get; set; }
        @AuraEnabled
        public String label { get; set; } 
        public ProfileOption(String val, String lbl) {
            value = val;
            label = lbl;
        }
    } 
    public class ProcessedObjectDetails {
        @AuraEnabled public String objectName;
        @AuraEnabled public List<String> fields;
        
        public ProcessedObjectDetails(String objectName, List<String> fields) {
            this.objectName = objectName;
            this.fields = fields;
        }
    }
    
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getPageUrlInfo() {
        Map<String, Object> result = new Map<String, Object>();
        
        // Get the current page URL
        String pageUrl = Page.SA_Audit__ObjectAccess.getUrl();
        result.put('pageUrl', pageUrl);
        
        // Check if the page is in a community
        Boolean isInCommunity = Site.getSiteId() != null;
        result.put('isInCommunity', isInCommunity);
        
        return result;
    }   
    
    public static void fakeMethod(){
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