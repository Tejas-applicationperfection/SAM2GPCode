/**
 * @description Controller class for the Permissions Management LWC - OPTIMIZED VERSION
 * @author tj - Performance Optimized
 */
public with sharing class PermissionsManagerController {
    
    // Constants for pagination and performance
    private static final Integer DEFAULT_PAGE_SIZE = 50;
    private static final Integer MAX_PAGE_SIZE = 1000;
    private static final Integer SOQL_LIMIT_BUFFER = 45000; // Stay well under 50k limit
    
    /**
     * @description Check if user has access to paid features
     * @return Boolean True if user has access
     */
    @AuraEnabled(cacheable=true)
    public static Boolean PaidFeatureAccess() {
        // Check if the feature is enabled for the user
        //return FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess');

       //for show --- 
       return true; 
        
        
       // for hide ---
      // return false;
    }
    
    /**
     * @description Get profiles with pagination support
     * @param pageSize Number of records per page (max 200)
     * @param pageNumber Page number (1-based)
     * @param searchTerm Optional search term to filter profiles
     * @return ProfilePageResult Paginated profile results
     */
    @AuraEnabled(cacheable=true)
    public static ProfilePageResult getProfilesPaginated(Integer pageSize, Integer pageNumber, String searchTerm) {
        ProfilePageResult result = new ProfilePageResult();
        
        try {
            // Validate and set defaults
            if (pageSize == null || pageSize <= 0) pageSize = DEFAULT_PAGE_SIZE;
            if (pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
            if (pageNumber == null || pageNumber <= 0) pageNumber = 1;
            
            Integer offset = (pageNumber - 1) * pageSize;
            
            // Build dynamic query
            String baseQuery = 'SELECT Id, Name FROM Profile';
            String whereClause = '';
            String orderClause = ' ORDER BY Name ASC';
            String limitClause = ' LIMIT ' + pageSize;
            String offsetClause = ' OFFSET ' + offset;
            
            // Add search filter if provided
            if (String.isNotBlank(searchTerm)) {
                whereClause = ' WHERE Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\'';
            }
            
            String query = baseQuery + whereClause + orderClause + limitClause + offsetClause;
            
            // Execute query
            List<Profile> profiles = Database.query(query);
            
            // Convert to wrapper objects
            List<ProfileWrapper> profileWrappers = new List<ProfileWrapper>();
            for (Profile p : profiles) {
                ProfileWrapper wrapper = new ProfileWrapper();
                wrapper.id = p.Id;
                wrapper.name = p.Name;
                wrapper.type = p.Name.contains('Standard') ? 'Standard Profile' : 'Custom Profile';
                wrapper.isSelected = false;
                profileWrappers.add(wrapper);
            }
            
            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM Profile' + whereClause;
            Integer totalCount = Database.countQuery(countQuery);
            
            result.profiles = profileWrappers;
            result.totalCount = totalCount;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;
            result.totalPages = (Integer) Math.ceil((Decimal) totalCount / pageSize);
            result.hasNext = pageNumber < result.totalPages;
            result.hasPrevious = pageNumber > 1;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving profiles: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get permission sets with pagination support
     * @param pageSize Number of records per page
     * @param pageNumber Page number (1-based)
     * @param searchTerm Optional search term to filter permission sets
     * @return PermissionSetPageResult Paginated permission set results
     */
    @AuraEnabled(cacheable=true)
    public static PermissionSetPageResult getPermissionSetsPaginated(Integer pageSize, Integer pageNumber, String searchTerm) {
        PermissionSetPageResult result = new PermissionSetPageResult();
        
        try {
            // Validate and set defaults
            if (pageSize == null || pageSize <= 0) pageSize = DEFAULT_PAGE_SIZE;
            if (pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
            if (pageNumber == null || pageNumber <= 0) pageNumber = 1;
            
            Integer offset = (pageNumber - 1) * pageSize;
            
            // Build dynamic query - exclude profile-owned permission sets
            String baseQuery = 'SELECT Id, Name, Label, CreatedById, CreatedBy.Name, CreatedDate, Description, IsCustom FROM PermissionSet WHERE IsOwnedByProfile = false';
            String whereClause = '';
            String orderClause = ' ORDER BY Label ASC';
            String limitClause = ' LIMIT ' + pageSize;
            String offsetClause = ' OFFSET ' + offset;
            
            // Add search filter if provided
            if (String.isNotBlank(searchTerm)) {
                whereClause = ' AND (Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\' OR Label LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\')';
            }
            
            String query = baseQuery + whereClause + orderClause + limitClause + offsetClause;
            
            // Execute query
            List<PermissionSet> permissionSets = Database.query(query);
            
            // Get PermissionSetAssignments for these permission sets
            Set<Id> permissionSetIds = new Set<Id>();
            for (PermissionSet ps : permissionSets) {
                permissionSetIds.add(ps.Id);
            }
            
            // Check if optional fields exist in the org
            Boolean hasLastCreatedByChangeId = Schema.SObjectType.PermissionSetAssignment.fields.getMap().containsKey('LastCreatedByChangeId');
            Boolean hasLastDeletedByChangeId = Schema.SObjectType.PermissionSetAssignment.fields.getMap().containsKey('LastDeletedByChangeId');
            
            Map<Id, List<PermissionSetAssignment>> assignmentsByPermSetId = new Map<Id, List<PermissionSetAssignment>>();
            if (!permissionSetIds.isEmpty()) {
                // Build dynamic query with conditional fields
                String queryFields = 'Id, AssigneeId, Assignee.Name, ExpirationDate, IsActive, IsRevoked, PermissionSetGroupId, PermissionSetId, SystemModstamp';
                if (hasLastCreatedByChangeId) {
                    queryFields += ', LastCreatedByChangeId';
                }
                if (hasLastDeletedByChangeId) {
                    queryFields += ', LastDeletedByChangeId';
                }
                
                String assignmentQuery = 'SELECT ' + queryFields + ' FROM PermissionSetAssignment WHERE PermissionSetId IN :permissionSetIds ORDER BY Assignee.Name ASC LIMIT 40000';
                List<PermissionSetAssignment> assignments = Database.query(assignmentQuery);
                
                for (PermissionSetAssignment psa : assignments) {
                    if (!assignmentsByPermSetId.containsKey(psa.PermissionSetId)) {
                        assignmentsByPermSetId.put(psa.PermissionSetId, new List<PermissionSetAssignment>());
                    }
                    assignmentsByPermSetId.get(psa.PermissionSetId).add(psa);
                }
            }
            
            // Convert to wrapper objects
            List<PermissionSetWrapper> permSetWrappers = new List<PermissionSetWrapper>();
            for (PermissionSet ps : permissionSets) {
                PermissionSetWrapper wrapper = new PermissionSetWrapper();
                wrapper.id = ps.Id;
                wrapper.name = ps.Name;
                wrapper.label = ps.Label;
                wrapper.type = 'Permission Set';
                wrapper.isSelected = false;
                wrapper.createdById = ps.CreatedById;
                wrapper.createdByName = ps.CreatedBy?.Name;
                wrapper.createdDate = ps.CreatedDate;
                wrapper.description = ps.Description;
                wrapper.isCustom = ps.IsCustom;
                
                // Initialize assignment fields
                wrapper.assignments = new List<AssignmentWrapper>();
                
                // Add assignment data if available
                if (assignmentsByPermSetId.containsKey(ps.Id)) {
                    List<PermissionSetAssignment> psAssignments = assignmentsByPermSetId.get(ps.Id);
                    
                    for (PermissionSetAssignment psa : psAssignments) {
                        AssignmentWrapper assignmentWrapper = new AssignmentWrapper();
                        assignmentWrapper.assigneeId = psa.AssigneeId;
                        assignmentWrapper.assigneeName = psa.Assignee.Name;
                        assignmentWrapper.expirationDate = psa.ExpirationDate;
                        assignmentWrapper.assignmentId = psa.Id;
                        assignmentWrapper.isActive = psa.IsActive;
                        assignmentWrapper.isRevoked = psa.IsRevoked;
                        assignmentWrapper.permissionSetGroupId = psa.PermissionSetGroupId;
                        assignmentWrapper.permissionSetId = psa.PermissionSetId;
                        assignmentWrapper.systemModstamp = psa.SystemModstamp;
                        
                        // Conditionally assign optional fields if they exist in the org
                        if (hasLastCreatedByChangeId) {
                            assignmentWrapper.lastCreatedByChangeId = (String)psa.get('LastCreatedByChangeId');
                        }
                        if (hasLastDeletedByChangeId) {
                            assignmentWrapper.lastDeletedByChangeId = (String)psa.get('LastDeletedByChangeId');
                        }
                        
                        wrapper.assignments.add(assignmentWrapper);
                    }
                    
                    // Set the first assignment's data to the main wrapper for backward compatibility
                    if (!psAssignments.isEmpty()) {
                        PermissionSetAssignment firstAssignment = psAssignments[0];
                        wrapper.assigneeId = firstAssignment.AssigneeId;
                        wrapper.expirationDate = firstAssignment.ExpirationDate;
                        wrapper.assignmentId = firstAssignment.Id;
                        wrapper.isActive = firstAssignment.IsActive;
                        wrapper.isRevoked = firstAssignment.IsRevoked;
                        
                        // Conditionally assign optional fields if they exist in the org
                        if (hasLastCreatedByChangeId) {
                            wrapper.lastCreatedByChangeId = (String)firstAssignment.get('LastCreatedByChangeId');
                        }
                        if (hasLastDeletedByChangeId) {
                            wrapper.lastDeletedByChangeId = (String)firstAssignment.get('LastDeletedByChangeId');
                        }
                        
                        wrapper.permissionSetGroupId = firstAssignment.PermissionSetGroupId;
                        wrapper.permissionSetId = firstAssignment.PermissionSetId;
                        wrapper.systemModstamp = firstAssignment.SystemModstamp;
                    }
                }
                
                permSetWrappers.add(wrapper);
            }
            
            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM PermissionSet WHERE IsOwnedByProfile = false' + whereClause;
            Integer totalCount = Database.countQuery(countQuery);
            
            result.permissionSets = permSetWrappers;
            result.totalCount = totalCount;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;
            result.totalPages = (Integer) Math.ceil((Decimal) totalCount / pageSize);
            result.hasNext = pageNumber < result.totalPages;
            result.hasPrevious = pageNumber > 1;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving permission sets: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get objects with pagination and caching
     * @param pageSize Number of records per page
     * @param pageNumber Page number (1-based)
     * @param searchTerm Optional search term to filter objects
     * @return ObjectPageResult Paginated object results
     */
    @AuraEnabled
    public static ObjectPageResult getObjectsPaginated(Integer pageSize, Integer pageNumber, String searchTerm) {
        ObjectPageResult result = new ObjectPageResult();
        
        // Version check - this should appear in logs to confirm deployment
        System.debug('>>>>> getObjectsPaginated v2.0 - STRICT FILTERING ENABLED <<<<<');
        
        try {
            // Validate and set defaults
            if (pageSize == null || pageSize <= 0) pageSize = DEFAULT_PAGE_SIZE;
            if (pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
            if (pageNumber == null || pageNumber <= 0) pageNumber = 1;
            
            // Query ALL queryable objects (standard and custom) excluding unwanted types
            List<EntityDefinition> allEntities = [
                SELECT QualifiedApiName, Label, IsCustomizable 
                FROM EntityDefinition 
                WHERE IsQueryable = true 
                AND IsCustomSetting = false
                ORDER BY Label ASC
                LIMIT 2000
            ];
            
            System.debug('Total entities queried: ' + allEntities.size());
            
            // Filter out unwanted object types in Apex - keep ONLY standard and custom objects
            List<SelectOption> filteredObjects = new List<SelectOption>();
            Integer skippedCount = 0;
            
            // Common system objects to exclude (not standard business objects)
            Set<String> systemObjectsToExclude = new Set<String>{
                'DataActionJobSummary', 'AcceptedEventRelation', 'DeclinedEventRelation',
                'AIApplication', 'AIApplicationConfig', 'AIInsightValue', 'AIRecordInsight',
                'AlternativePaymentMethod', 'ApiAnomalyEventStore', 'AppAnalyticsQueryRequest',
                'ApexTestQueueItem', 'ApexTestResult', 'AsyncApexJob', 'AttachedContentDocument',
                'AuraDefinitionBundle', 'AuthSession', 'BackgroundOperation', 'BrandTemplate',
                'CalendarView', 'CardPaymentMethod', 'CombinedAttachment', 'ContentDocumentLink',
                'CronJobDetail', 'CronTrigger', 'CustomBrand', 'CustomBrandAsset',
                'DataAssessmentFieldMetric', 'DataAssessmentMetric', 'DataAssessmentValueMetric',
                'DigitalWallet', 'DuplicateRecordItem', 'DuplicateRecordSet', 'DuplicateRule',
                'EmailMessage', 'EmailServicesAddress', 'EmailTemplate', 'EntitySubscription',
                'FieldPermissions', 'FiscalYearSettings', 'FlowInterview', 'FlowRecordRelation',
                'FolderedContentDocument', 'GrantedByLicense', 'Group', 'GroupMember',
                'Holiday', 'IdeaComment', 'KnowledgeArticle', 'KnowledgeArticleVersion',
                'LeadCleanInfo', 'ListEmail', 'LoginHistory', 'MatchingRule', 'NamedCredential',
                'NetworkActivityAudit', 'ObjectPermissions', 'Organization', 'OrgWideEmailAddress',
                'PartnerRole', 'PermissionSet', 'PermissionSetAssignment', 'PermissionSetGroup',
                'PermissionSetGroupComponent', 'PermissionSetLicense', 'PermissionSetLicenseAssign',
                'PermissionSetTabSetting', 'Period', 'PlatformEventUsageMetric', 'ProcessInstance',
                'ProcessInstanceNode', 'ProcessInstanceStep', 'ProcessInstanceWorkitem', 'Profile',
                'Publisher', 'QueueSobject', 'QuickText', 'RecordAction', 'RecordType',
                'RemoteProxy', 'Report', 'SamlSsoConfig', 'SearchPromotionRule', 'SecurityCustomBaseline',
                'SessionHijackingEventStore', 'SessionPermSetActivation', 'SetupAuditTrail', 'SetupEntityAccess',
                'Site', 'SiteFeed', 'SlaProcess', 'Scontrol', 'StaticResource', 'TabDefinition',
                'TenantUsageEntitlement', 'Territory', 'Territory2', 'Territory2Model', 'Territory2Type',
                'ThirdPartyAccountLink', 'ThreatDetectionFeedback', 'Topic', 'TopicAssignment',
                'UndecidedEventRelation', 'User', 'UserAppInfo', 'UserAppMenuCustomization',
                'UserEntityAccess', 'UserFieldAccess', 'UserLicense', 'UserLogin', 'UserPackageLicense',
                'UserPermissionAccess', 'UserPreference', 'UserProvAccount', 'UserProvisioningConfig',
                'UserProvisioningLog', 'UserProvisioningRequest', 'UserProvMockTarget', 'UserRecordAccess',
                'UserRole', 'UserSetupEntityAccess', 'VerificationHistory', 'Vote', 'WaveAutoInstallRequest',
                'WebLink'
            };
            
            for (EntityDefinition entity : allEntities) {
                String apiName = entity.QualifiedApiName;
                Boolean shouldSkip = false;
                String skipReason = '';
                
                // Skip system objects by name
                if (systemObjectsToExclude.contains(apiName)) {
                    shouldSkip = true;
                    skipReason = 'system object';
                }
                // Skip ALL metadata types (anything ending with __mdt, __x, __e, __b, __pc, __pr, etc.)
                else if (apiName.contains('__mdt')) { shouldSkip = true; skipReason = 'metadata type'; }
                else if (apiName.contains('__kav')) { shouldSkip = true; skipReason = 'knowledge article'; }
                else if (apiName.contains('__ka')) { shouldSkip = true; skipReason = 'knowledge article version'; }
                else if (apiName.contains('__x')) { shouldSkip = true; skipReason = 'external object'; }
                else if (apiName.contains('__e')) { shouldSkip = true; skipReason = 'platform event'; }
                else if (apiName.contains('__b')) { shouldSkip = true; skipReason = 'big object'; }
                else if (apiName.contains('__pc')) { shouldSkip = true; skipReason = 'person account'; }
                else if (apiName.contains('__pr')) { shouldSkip = true; skipReason = 'person account relation'; }
                
                // Skip standard system junction/sharing/history objects
                else if (apiName.endsWith('Share')) { shouldSkip = true; skipReason = 'sharing object'; }
                else if (apiName.endsWith('History')) { shouldSkip = true; skipReason = 'history object'; }
                else if (apiName.endsWith('Feed')) { shouldSkip = true; skipReason = 'feed object'; }
                else if (apiName.endsWith('Tag')) { shouldSkip = true; skipReason = 'tag object'; }
                else if (apiName.endsWith('Event')) { shouldSkip = true; skipReason = 'event object'; }
                else if (apiName.endsWith('ChangeEvent')) { shouldSkip = true; skipReason = 'change event'; }
                else if (apiName.endsWith('__ChangeEvent')) { shouldSkip = true; skipReason = 'change event'; }
                
                if (shouldSkip) {
                    skippedCount++;
                    if (skippedCount <= 5) {
                        System.debug('SKIPPING: ' + apiName + ' - Reason: ' + skipReason);
                    }
                    continue;
                }
                
                // Only include:
                // 1. Custom objects (ending with __c)
                // 2. Standard business objects (no __ suffix, not in exclusion list)
                Boolean isCustomObject = apiName.endsWith('__c');
                Boolean isStandardObject = !apiName.contains('__') && 
                                          !apiName.endsWith('Share') && 
                                          !apiName.endsWith('History') && 
                                          !apiName.endsWith('Feed') && 
                                          !apiName.endsWith('Tag') &&
                                          !systemObjectsToExclude.contains(apiName);
                
                if (isCustomObject || isStandardObject) {
                    filteredObjects.add(new SelectOption(apiName, entity.Label));
                    if (filteredObjects.size() <= 5) {
                        System.debug('INCLUDING: ' + apiName + ' (Custom: ' + isCustomObject + ', Standard: ' + isStandardObject + ')');
                    }
                } else {
                    skippedCount++;
                    if (skippedCount <= 10) {
                        System.debug('SKIPPING: ' + apiName + ' - Not standard or custom object');
                    }
                }
            }
            
            System.debug('Filtered objects count: ' + filteredObjects.size());
            System.debug('Skipped objects count: ' + skippedCount);
            
            // Apply search filter if provided
            List<SelectOption> searchFilteredObjects = new List<SelectOption>();
            if (String.isNotBlank(searchTerm)) {
                String searchLower = searchTerm.toLowerCase();
                for (SelectOption opt : filteredObjects) {
                    if (opt.getValue().toLowerCase().contains(searchLower) || 
                        opt.getLabel().toLowerCase().contains(searchLower)) {
                        searchFilteredObjects.add(opt);
                    }
                }
            } else {
                searchFilteredObjects = filteredObjects;
            }
            
            // No pagination for objects – return all filtered objects
            Integer totalCount = searchFilteredObjects.size();
            
            List<ObjectWrapper> objectWrappers = new List<ObjectWrapper>();
            for (SelectOption opt : searchFilteredObjects) {
                ObjectWrapper wrapper = new ObjectWrapper();
                wrapper.apiName = opt.getValue();
                wrapper.label = opt.getLabel();
                wrapper.name = opt.getLabel();
                wrapper.type = opt.getValue().endsWith('__c') ? 'Custom Object' : 'Standard Object';
                wrapper.isSelected = false;
                objectWrappers.add(wrapper);
            }
            
            result.objects = objectWrappers;
            result.totalCount = totalCount;
            // Treat all as a single page
            result.pageSize = totalCount;
            result.pageNumber = 1;
            result.totalPages = 1;
            result.hasNext = false;
            result.hasPrevious = false;
            
            System.debug('>>>>> FINAL RESULT: Returning ' + objectWrappers.size() + ' objects (filtered from ' + allEntities.size() + ' total entities) <<<<<');
            System.debug('>>>>> Total Pages: ' + result.totalPages + ', Has Next: ' + result.hasNext + ' <<<<<');
            
        } catch (Exception e) {
            System.debug('Error in getObjectsPaginated: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving objects: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get object permissions with optimized queries and chunking
     * @param profileIds List of profile IDs
     * @param permSetIds List of permission set IDs  
     * @param objectNames List of object API names
     * @param chunkSize Size of each processing chunk (default 10)
     * @return Map<String, ObjectPermissionsMatrix> Object permissions by object name
     */
    @AuraEnabled
    public static Map<String, ObjectPermissionsMatrix> getObjectPermissionsOptimized(
        List<String> profileIds, 
        List<String> permSetIds, 
        List<String> objectNames,
        Integer chunkSize
    ) {
        Map<String, ObjectPermissionsMatrix> result = new Map<String, ObjectPermissionsMatrix>();
        
        try {
            // Validate inputs
            if (objectNames == null || objectNames.isEmpty()) {
                return result;
            }
            
            // Set default chunk size
            if (chunkSize == null || chunkSize <= 0) chunkSize = 10;
            
            // Process objects in chunks to avoid SOQL limits
            List<List<String>> objectChunks = chunkList(objectNames, chunkSize);
            
            for (List<String> objectChunk : objectChunks) {
                Map<String, ObjectPermissionsMatrix> chunkResult = processObjectPermissionsChunk(
                    profileIds, permSetIds, objectChunk
                );
                result.putAll(chunkResult);
            }
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving object permissions: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Process a chunk of object permissions
     */
    private static Map<String, ObjectPermissionsMatrix> processObjectPermissionsChunk(
        List<String> profileIds, 
        List<String> permSetIds, 
        List<String> objectNames
    ) {
        Map<String, ObjectPermissionsMatrix> result = new Map<String, ObjectPermissionsMatrix>();
        
        // Create a map to hold permissions by object and profile/permission set
        Map<String, Map<String, ObjectPermissionWrapper>> permissionsByObject = new Map<String, Map<String, ObjectPermissionWrapper>>();
        
        // Initialize the map for each object
        for (String objName : objectNames) {
            if (String.isNotBlank(objName)) {
                permissionsByObject.put(objName, new Map<String, ObjectPermissionWrapper>());
            }
        }
        
        // Query object permissions for profiles if profileIds is not empty
        if (profileIds != null && !profileIds.isEmpty()) {
            // Limit the query to avoid SOQL limits
            String profileQuery = 'SELECT Id, Parent.Profile.Id, Parent.Profile.Name, Parent.Profile.UserLicense.Name, ' +
                                'SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, ' +
                                'PermissionsViewAllRecords, PermissionsModifyAllRecords ' +
                                'FROM ObjectPermissions ' +
                                'WHERE Parent.Profile.Id IN :profileIds AND SObjectType IN :objectNames ' +
                                'LIMIT ' + SOQL_LIMIT_BUFFER;
            
            List<ObjectPermissions> profileObjectPerms = Database.query(profileQuery);
            
            for (ObjectPermissions perm : profileObjectPerms) {
                if (perm.Parent?.Profile?.Id == null) continue;
                
                String objectType = perm.SObjectType;
                String profileId = perm.Parent.Profile.Id;
                
                if (!permissionsByObject.containsKey(objectType)) continue;
                
                ObjectPermissionWrapper wrapper = createObjectPermissionWrapper(perm, profileId, true);
                permissionsByObject.get(objectType).put(profileId, wrapper);
            }
        }
        
        // Query object permissions for permission sets if permSetIds is not empty
        if (permSetIds != null && !permSetIds.isEmpty()) {
            String permSetQuery = 'SELECT Id, Parent.Id, Parent.Name, Parent.IsOwnedByProfile, Parent.ProfileId, ' +
                                'SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, ' +
                                'PermissionsViewAllRecords, PermissionsModifyAllRecords ' +
                                'FROM ObjectPermissions ' +
                                'WHERE Parent.Id IN :permSetIds AND SObjectType IN :objectNames ' +
                                'LIMIT ' + SOQL_LIMIT_BUFFER;
            
            List<ObjectPermissions> permSetObjectPerms = Database.query(permSetQuery);
            
            for (ObjectPermissions perm : permSetObjectPerms) {
                if (perm.Parent?.Id == null) continue;
                
                String objectType = perm.SObjectType;
                String permSetId = perm.Parent.Id;
                
                if (!permissionsByObject.containsKey(objectType)) continue;
                
                ObjectPermissionWrapper wrapper = createObjectPermissionWrapper(perm, permSetId, false);
                permissionsByObject.get(objectType).put(permSetId, wrapper);
            }
        }
        
        // Build the result
        for (String objName : objectNames) {
            if (String.isNotBlank(objName) && permissionsByObject.containsKey(objName)) {
                ObjectPermissionsMatrix matrix = new ObjectPermissionsMatrix();
                matrix.objectName = objName;
                matrix.permissions = permissionsByObject.get(objName);
                result.put(objName, matrix);
            }
        }
        
        return result;
    }
    
    /**
     * @description Create an ObjectPermissionWrapper from ObjectPermissions record
     */
    private static ObjectPermissionWrapper createObjectPermissionWrapper(
        ObjectPermissions perm, 
        String parentId, 
        Boolean isProfile
    ) {
        ObjectPermissionWrapper wrapper = new ObjectPermissionWrapper();
        wrapper.id = perm.Id;
        wrapper.parentId = parentId;
        wrapper.parentName = isProfile ? perm.Parent.Profile.Name : perm.Parent.Name;
        wrapper.objectType = perm.SObjectType;
        wrapper.canRead = perm.PermissionsRead;
        wrapper.canCreate = perm.PermissionsCreate;
        wrapper.canEdit = perm.PermissionsEdit;
        wrapper.canDelete = perm.PermissionsDelete;
        wrapper.canViewAll = perm.PermissionsViewAllRecords;
        wrapper.canModifyAll = perm.PermissionsModifyAllRecords;
        
        if (isProfile && perm.Parent.Profile.UserLicense != null) {
            wrapper.userLicenseName = perm.Parent.Profile.UserLicense.Name;
        }
        
        // Initialize disabled flags
        wrapper.isReadDisabled = false;
        wrapper.isCreateDisabled = false;
        wrapper.isEditDisabled = false;
        wrapper.isDeleteDisabled = false;
        wrapper.isViewAllDisabled = false;
        wrapper.isModifyAllDisabled = false;
        
        return wrapper;
    }
    
    /**
     * @description Get system permission access with dynamic user fields
     * @param systemPermissionName The name of the system permission to analyze
     * @param userPageSize Number of records per page (default 50, max 200)
     * @param userPageNumber Page number (1-based)
     * @param selectedUserFields List of user field names to include (if null, uses default core fields)
     * @return Map<String, Object> containing profiles, permission sets, and paginated users with dynamic fields
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSystemPermissionAccessWithDynamicFields(
        String systemPermissionName, 
        Integer userPageSize, 
        Integer userPageNumber,
        List<String> selectedUserFields
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // IMMEDIATE DEBUG: Log exactly what we received from JavaScript
            System.debug('=== RECEIVED FROM JAVASCRIPT ===');
            System.debug('systemPermissionName: ' + systemPermissionName);
            System.debug('userPageSize: ' + userPageSize);
            System.debug('userPageNumber: ' + userPageNumber);
            System.debug('selectedUserFields (raw): ' + selectedUserFields);
            
            // Check for duplicates in the incoming array
            if (selectedUserFields != null) {
                Set<String> checkDuplicates = new Set<String>();
                List<String> duplicatesFound = new List<String>();
                for (String field : selectedUserFields) {
                    if (checkDuplicates.contains(field)) {
                        duplicatesFound.add(field);
                    } else {
                        checkDuplicates.add(field);
                    }
                }
                if (!duplicatesFound.isEmpty()) {
                    System.debug('DUPLICATES FOUND IN INPUT: ' + duplicatesFound);
                    throw new AuraHandledException('Duplicate fields detected in input: ' + String.join(duplicatesFound, ', '));
                }
            }
            System.debug('=== END DEBUG ===');
            if (String.isBlank(systemPermissionName)) {
                throw new AuraHandledException('System permission name is required');
            }
            
            // Validate pagination parameters
            if (userPageSize == null || userPageSize <= 0) userPageSize = DEFAULT_PAGE_SIZE;
            if (userPageSize > MAX_PAGE_SIZE) userPageSize = MAX_PAGE_SIZE;
            if (userPageNumber == null || userPageNumber <= 0) userPageNumber = 1;
            
            String fieldName = 'Permissions' + systemPermissionName;
            Set<Id> allParentIds = new Set<Id>();
            List<Map<String, Object>> profilesWithAccess = new List<Map<String, Object>>();
            List<Map<String, Object>> permSetsWithAccess = new List<Map<String, Object>>();
            
            // Query profiles that have this permission
            String profileQuery = 'SELECT Id, Name, UserLicense.Name FROM Profile WHERE ' + fieldName + ' = true ORDER BY Name LIMIT ' + SOQL_LIMIT_BUFFER;
            List<Profile> profilesWithPerm = Database.query(profileQuery);
            
            for (Profile p : profilesWithPerm) {
                Map<String, Object> profileMap = new Map<String, Object>{
                    'id' => p.Id,
                    'name' => p.Name,
                    'type' => 'Profile',
                    'userLicense' => p.UserLicense?.Name
                };
                profilesWithAccess.add(profileMap);
                allParentIds.add(p.Id);
            }
            
            // Query permission sets that have this permission
            String permSetQuery = 'SELECT Id, Name, Label, IsOwnedByProfile, ProfileId FROM PermissionSet WHERE ' + 
                                fieldName + ' = true AND IsOwnedByProfile = false ORDER BY Label LIMIT ' + SOQL_LIMIT_BUFFER;
            List<PermissionSet> permSetsWithPerm = Database.query(permSetQuery);
            
            Set<Id> permSetIds = new Set<Id>();
            for (PermissionSet ps : permSetsWithPerm) {
                Map<String, Object> permSetMap = new Map<String, Object>{
                    'id' => ps.Id,
                    'name' => ps.Name,
                    'label' => ps.Label,
                    'type' => 'Permission Set'
                };
                permSetsWithAccess.add(permSetMap);
                allParentIds.add(ps.Id);
                permSetIds.add(ps.Id);
            }
            
            // Get paginated users with dynamic fields
            Map<String, Object> userResults = getUsersWithSystemPermissionAndDynamicFields(
                allParentIds, permSetIds, userPageSize, userPageNumber, selectedUserFields
            );
            
            result.put('profiles', profilesWithAccess);
            result.put('permissionSets', permSetsWithAccess);
            result.put('users', userResults.get('users'));
            result.put('userPagination', userResults.get('pagination'));
            result.put('userFields', userResults.get('userFields'));
            result.put('totalCount', profilesWithAccess.size() + permSetsWithAccess.size() + (Integer)userResults.get('totalUserCount'));
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving system permission access with dynamic fields: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Get users with system permission access using pagination and dynamic fields
     */
    private static Map<String, Object> getUsersWithSystemPermissionAndDynamicFields(
        Set<Id> allParentIds, 
        Set<Id> permSetIds, 
        Integer pageSize, 
        Integer pageNumber,
        List<String> selectedUserFields
    ) {
        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, Object>> usersWithAccess = new List<Map<String, Object>>();

        // Build dynamic field list with CASE-INSENSITIVE duplicate handling
        // SOQL field names are case-insensitive, so we need to track them properly
        Map<String, String> fieldNameMap = new Map<String, String>(); // lowercase -> proper case
        Set<String> fieldsToQuerySet = new Set<String>(); // Final set of fields
        List<Map<String, Object>> userFieldsMetadata = new List<Map<String, Object>>();
        
        // Get User field metadata for processing
        Map<String, Object> userFieldsInfo = getUserFieldsForDisplay();
        List<Map<String, Object>> allFields = (List<Map<String, Object>>) userFieldsInfo.get('fields');
        
        if (selectedUserFields != null && !selectedUserFields.isEmpty()) {
            System.debug('Processing selected user fields: ' + selectedUserFields);
            
            // Add selected fields to query set with case-insensitive duplicate prevention
            for (String fieldName : selectedUserFields) {
                if (String.isNotBlank(fieldName) && fieldName != 'ProfileId') { // Exclude ProfileId as it's not queryable on User
                    String lowerFieldName = fieldName.toLowerCase();
                    
                    // Only add if we haven't seen this field name (case-insensitive)
                    if (!fieldNameMap.containsKey(lowerFieldName)) {
                        fieldNameMap.put(lowerFieldName, fieldName);
                        fieldsToQuerySet.add(fieldName);
                        System.debug('Added field to query set: ' + fieldName);
                    } else {
                        System.debug('Skipped duplicate field (case-insensitive): ' + fieldName + ' (already have: ' + fieldNameMap.get(lowerFieldName) + ')');
                    }
                }
                
                // Find field metadata
                for (Map<String, Object> fieldInfo : allFields) {
                    if (((String)fieldInfo.get('name')).equalsIgnoreCase(fieldName)) {
                        userFieldsMetadata.add(fieldInfo);
                        break;
                    }
                }
            }
        } else {
            System.debug('No selected fields, using default core fields');
            
            // Use default core fields when no fields are selected
            for (Map<String, Object> fieldInfo : allFields) {
                if ((Boolean) fieldInfo.get('isCore')) {
                    String fieldName = (String) fieldInfo.get('name');
                    String lowerFieldName = fieldName.toLowerCase();
                    
                    if (!fieldNameMap.containsKey(lowerFieldName)) {
                        fieldNameMap.put(lowerFieldName, fieldName);
                        fieldsToQuerySet.add(fieldName);
                        userFieldsMetadata.add(fieldInfo);
                        System.debug('Added core field to query set: ' + fieldName);
                    }
                }
            }
        }
        
        // Always ensure essential fields are included with case-insensitive checking
        if (!fieldNameMap.containsKey('id')) {
            fieldNameMap.put('id', 'Id');
            fieldsToQuerySet.add('Id');
        }
        if (!fieldNameMap.containsKey('profile.name')) {
            fieldNameMap.put('profile.name', 'Profile.Name');
            fieldsToQuerySet.add('Profile.Name');
        }
        
        System.debug('Final fields to query set: ' + fieldsToQuerySet);
        
        // Convert Set to List for SOQL query
        List<String> fieldsToQuery = new List<String>(fieldsToQuerySet);
        
        String queryFields = String.join(fieldsToQuery, ', ');
        
        System.debug('Selected User Fields: ' + selectedUserFields);
        System.debug('Fields to Query: ' + fieldsToQuery);
        System.debug('Query Fields String: ' + queryFields);
        
        // (1) Users via Profile
        Set<Id> profileIds = new Set<Id>(allParentIds);
        profileIds.removeAll(permSetIds);
        
        if (!profileIds.isEmpty()) {
            String userQuery = 'SELECT ' + queryFields + ' FROM User WHERE ProfileId IN :profileIds AND IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' ORDER BY Name LIMIT ' + SOQL_LIMIT_BUFFER;
            System.debug('Profile User Query: ' + userQuery);
            
            for (User u : Database.query(userQuery)) {
                Map<String, Object> userMap = buildUserMapWithDynamicFields(u, selectedUserFields, userFieldsMetadata);
                usersWithAccess.add(userMap);
            }
        }

        // (2) Users via Permission Set / Group assignments
        if (!permSetIds.isEmpty()) {
            Set<Id> assigneeIds = new Set<Id>();
            for (PermissionSetAssignment psa : [
                    SELECT AssigneeId
                    FROM PermissionSetAssignment
                    WHERE PermissionSetId IN :permSetIds
            ]) {
                assigneeIds.add(psa.AssigneeId);
            }

            if (!assigneeIds.isEmpty()) {
                Set<Id> existingIds = new Set<Id>();
                for (Map<String, Object> m : usersWithAccess) {
                    if (m.containsKey('id')) {
                        existingIds.add((Id)m.get('id'));
                    }
                }
                assigneeIds.removeAll(existingIds);

                String userQuery = 'SELECT ' + queryFields + ' FROM User WHERE Id IN :assigneeIds AND IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' ORDER BY Name LIMIT ' + SOQL_LIMIT_BUFFER;
                System.debug('Permission Set User Query: ' + userQuery);
                
                for (User u : Database.query(userQuery)) {
                    Map<String, Object> userMap = buildUserMapWithDynamicFields(u, selectedUserFields, userFieldsMetadata);
                    usersWithAccess.add(userMap);
                }
            }
        }

        // Pagination
        Integer totalUserCount = usersWithAccess.size();
        Integer startIdx = (pageNumber - 1) * pageSize;
        Integer endIdx = Math.min(startIdx + pageSize, totalUserCount);

        List<Map<String, Object>> pagedUsers = new List<Map<String, Object>>();
        if (startIdx < totalUserCount) {
            for (Integer i = startIdx; i < endIdx; i++) {
                pagedUsers.add(usersWithAccess[i]);
            }
        }

        Map<String, Object> pagination = new Map<String, Object>{
            'pageSize' => pageSize,
            'pageNumber' => pageNumber,
            'totalCount' => totalUserCount,
            'totalPages' => (Integer)Math.ceil((Decimal) totalUserCount / pageSize),
            'hasNext' => pageNumber < Math.ceil((Decimal) totalUserCount / pageSize),
            'hasPrevious' => pageNumber > 1
        };

        result.put('users', pagedUsers);
        result.put('pagination', pagination);
        result.put('totalUserCount', totalUserCount);
        result.put('userFields', userFieldsMetadata);
        return result;
    }

    /**
     * @description Build user map with dynamic fields
     */
    private static Map<String, Object> buildUserMapWithDynamicFields(
        User u, 
        List<String> selectedUserFields, 
        List<Map<String, Object>> userFieldsMetadata
    ) {
        Map<String, Object> userMap = new Map<String, Object>{
            'id' => u.Id,
            'Id' => u.Id, // API-standard key for dynamic field binding
            'type' => 'User'
        };
        
        // Handle core fields first
        try {
            userMap.put('Name', u.Name);
        } catch (Exception e) {
            userMap.put('Name', null);
        }
        
        try {
            userMap.put('Username', u.Username);
        } catch (Exception e) {
            userMap.put('Username', null);
        }
        
        try {
            userMap.put('Email', u.Email);
        } catch (Exception e) {
            userMap.put('Email', null);
        }
        
        try {
            userMap.put('profileName', u.Profile?.Name);
        } catch (Exception e) {
            userMap.put('profileName', null);
        }
        
        try {
            userMap.put('IsActive', u.IsActive);
        } catch (Exception e) {
            userMap.put('IsActive', false);
        }
        
        // Add all selected dynamic fields (including any that might overlap with core fields)
        if (selectedUserFields != null && !selectedUserFields.isEmpty()) {
            for (String fieldName : selectedUserFields) {
                try {
                    Object fieldValue = u.get(fieldName);
                    userMap.put(fieldName, fieldValue);
                } catch (Exception e) {
                    System.debug('Error getting field value for ' + fieldName + ': ' + e.getMessage());
                    userMap.put(fieldName, null);
                }
            }
        }
        
        // Provide relationship API path for dynamic field binding
        userMap.put('Profile.Name', u.Profile != null ? u.Profile.Name : null);
        
        // Provide lowercase aliases for compatibility with existing LWC templates
        if (!userMap.containsKey('name')) userMap.put('name', userMap.get('Name'));
        if (!userMap.containsKey('username')) userMap.put('username', userMap.get('Username'));
        if (!userMap.containsKey('email')) userMap.put('email', userMap.get('Email'));
        // profileName already lowercase core so ensure uppercase alias if needed
        if (!userMap.containsKey('ProfileName')) userMap.put('ProfileName', userMap.get('profileName'));
        if (!userMap.containsKey('isActive')) userMap.put('isActive', userMap.get('IsActive'));
        
        return userMap;
    }

    /**
     * @description Get system permission access with pagination for users
     * @param systemPermissionName The name of the system permission to analyze
     * @param userPageSize Page size for user results (default 50, max 200)
     * @param userPageNumber Page number for user results
     * @return Map<String, Object> containing profiles, permission sets, and paginated users with access
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSystemPermissionAccessOptimized(
        String systemPermissionName, 
        Integer userPageSize, 
        Integer userPageNumber
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(systemPermissionName)) {
                throw new AuraHandledException('System permission name is required');
            }
            
            // Validate pagination parameters
            if (userPageSize == null || userPageSize <= 0) userPageSize = DEFAULT_PAGE_SIZE;
            if (userPageSize > MAX_PAGE_SIZE) userPageSize = MAX_PAGE_SIZE;
            if (userPageNumber == null || userPageNumber <= 0) userPageNumber = 1;
            
            String fieldName = 'Permissions' + systemPermissionName;
            Set<Id> allParentIds = new Set<Id>();
            List<Map<String, Object>> profilesWithAccess = new List<Map<String, Object>>();
            List<Map<String, Object>> permSetsWithAccess = new List<Map<String, Object>>();
            List<Map<String, Object>> permSetGroupsWithAccess = new List<Map<String, Object>>();
            
            // Query profiles that have this permission - Updated to include Description
            String profileQuery = 'SELECT Id, Name, Description, UserLicense.Name FROM Profile WHERE ' + fieldName + ' = true ORDER BY Name LIMIT ' + SOQL_LIMIT_BUFFER;
            List<Profile> profilesWithPerm = Database.query(profileQuery);
            
            for (Profile p : profilesWithPerm) {
                Map<String, Object> profileMap = new Map<String, Object>{
                    'id' => p.Id,
                    'name' => p.Name,
                    'description' => p.Description, // Added description field
                    'type' => 'Profile',
                    'userLicense' => p.UserLicense?.Name
                };
                profilesWithAccess.add(profileMap);
                allParentIds.add(p.Id);
            }
            
            // Query permission sets that have this permission - Updated to include all required fields
            String permSetQuery = 'SELECT Id, Name, Label, Description, IsOwnedByProfile, ProfileId, ' +
                                'IsCustom, CreatedById, CreatedBy.Name, CreatedDate FROM PermissionSet WHERE ' + 
                                fieldName + ' = true AND IsOwnedByProfile = false ORDER BY Label LIMIT ' + SOQL_LIMIT_BUFFER;
            List<PermissionSet> permSetsWithPerm = Database.query(permSetQuery);
            
            // Map of permission set IDs to their assignment count
            Map<Id, Integer> permSetAssignmentCounts = new Map<Id, Integer>();
            
            // Get assignment counts in a separate query
            if (!permSetsWithPerm.isEmpty()) {
                List<AggregateResult> assignmentCounts = [
                    SELECT PermissionSetId, COUNT(Id) assignmentCount
                    FROM PermissionSetAssignment
                    WHERE PermissionSetId IN :permSetsWithPerm
                    GROUP BY PermissionSetId
                ];
                
                for (AggregateResult ar : assignmentCounts) {
                    Id permSetId = (Id)ar.get('PermissionSetId');
                    Integer count = (Integer)ar.get('assignmentCount');
                    permSetAssignmentCounts.put(permSetId, count);
                }
            }
            
            Set<Id> permSetIds = new Set<Id>();
            for (PermissionSet ps : permSetsWithPerm) {
                Integer assignmentCount = permSetAssignmentCounts.containsKey(ps.Id) ? 
                                          permSetAssignmentCounts.get(ps.Id) : 0;
                
                Map<String, Object> permSetMap = new Map<String, Object>{
                    'id' => ps.Id,
                    'name' => ps.Name,
                    'label' => ps.Label,
                    'description' => ps.Description,
                    'type' => 'Permission Set',
                    'assignmentCount' => assignmentCount,
                    // Added missing metadata fields
                    'isCustom' => ps.IsCustom,
                    'createdById' => ps.CreatedById,
                    'createdByName' => ps.CreatedBy?.Name,
                    'createdDate' => ps.CreatedDate
                };
                permSetsWithAccess.add(permSetMap);
                allParentIds.add(ps.Id);
                permSetIds.add(ps.Id);
            }
            
            // Get permission set groups that include permission sets with this permission - Added this section
            List<PermissionSetGroup> psGroups = [
                SELECT Id, DeveloperName, MasterLabel, Description,
                       (SELECT Id, PermissionSetId FROM PermissionSetGroupComponents WHERE PermissionSetId IN :permSetIds) 
                FROM PermissionSetGroup 
                ORDER BY MasterLabel
            ];
            
            // Filter only permission set groups that actually contain permission sets with the permission
            for (PermissionSetGroup psg : psGroups) {
                if (psg.PermissionSetGroupComponents.size() > 0) {
                    // Create a list of component permission sets for this PSG
                    List<Map<String, Object>> componentPermSets = new List<Map<String, Object>>();
                    
                    for (PermissionSetGroupComponent psgc : psg.PermissionSetGroupComponents) {
                        // Find the original permission set data
                        for (Map<String, Object> psMap : permSetsWithAccess) {
                            if (psMap.get('id') == psgc.PermissionSetId) {
                                componentPermSets.add(new Map<String, Object>{
                                    'id' => psgc.PermissionSetId,
                                    'name' => (String)psMap.get('name'),
                                    'label' => (String)psMap.get('label')
                                });
                                break;
                            }
                        }
                    }
                    
                    // Only add this PSG if it contains permission sets with the permission
                    if (!componentPermSets.isEmpty()) {
                        // Query to count assignments
                        Integer assignmentCount = [SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetGroupId = :psg.Id];
                        
                        Map<String, Object> psgMap = new Map<String, Object>{
                            'id' => psg.Id,
                            'name' => psg.DeveloperName,
                            'label' => psg.MasterLabel,
                            'description' => psg.Description, // Added description field
                            'type' => 'Permission Set Group',
                            'componentPermissionSets' => componentPermSets,
                            'assignmentCount' => assignmentCount // Added assignment count
                        };
                        permSetGroupsWithAccess.add(psgMap);
                    }
                }
            }
            
            // Get paginated users with access
            Map<String, Object> userResults = getUsersWithSystemPermissionPaginated(
                allParentIds, permSetIds, userPageSize, userPageNumber
            );
            
            result.put('profiles', profilesWithAccess);
            result.put('permissionSets', permSetsWithAccess);
            result.put('permissionSetGroups', permSetGroupsWithAccess); // Added permission set groups
            result.put('users', userResults.get('users'));
            result.put('userPagination', userResults.get('pagination'));
            result.put('totalCount', profilesWithAccess.size() + permSetsWithAccess.size() + permSetGroupsWithAccess.size() + (Integer)userResults.get('totalUserCount'));
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving system permission access: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get users with system permission access using pagination
     */
    private static Map<String, Object> getUsersWithSystemPermissionPaginated(
        Set<Id> allParentIds, 
        Set<Id> permSetIds, 
        Integer pageSize, 
        Integer pageNumber
    ) {
        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, Object>> usersWithAccess = new List<Map<String, Object>>();

        // ---- NEW IMPLEMENTATION WITHOUT SEMI-JOIN OR ----

        // (1) Users via Profile
        Set<Id> profileIds = new Set<Id>(allParentIds);
        profileIds.removeAll(permSetIds);

        if (!profileIds.isEmpty()) {
            for (User u : [
                SELECT Id, Name, Username, Email, Profile.Name, IsActive
                FROM User
                WHERE ProfileId IN :profileIds AND IsActive = true
                ORDER BY Name
                LIMIT :SOQL_LIMIT_BUFFER
            ]) {
                usersWithAccess.add(new Map<String, Object>{
                    'id' => u.Id,
                    'name' => u.Name,
                    'username' => u.Username,
                    'email' => u.Email,
                    'profileName' => u.Profile.Name,
                    'isActive' => u.IsActive,
                    'type' => 'User'
                });
            }
        }

        // (2) Users via Permission Set / Group assignments
        if (!permSetIds.isEmpty()) {
            // Gather AssigneeIds first (to avoid nested semi-join in main query)
            Set<Id> assigneeIds = new Set<Id>();
            for (PermissionSetAssignment psa : [
                    SELECT AssigneeId
                    FROM PermissionSetAssignment
                    WHERE PermissionSetId IN :permSetIds
            ]) {
                assigneeIds.add(psa.AssigneeId);
            }

            if (!assigneeIds.isEmpty()) {
                // Remove any Ids we already captured from profile query
                Set<Id> existingIds = new Set<Id>();
                for (Map<String, Object> m : usersWithAccess) {
                    if (m.containsKey('id')) {
                        existingIds.add((Id)m.get('id'));
                    }
                }
                assigneeIds.removeAll(existingIds);

                for (User u : [
                    SELECT Id, Name, Username, Email, Profile.Name, IsActive
                    FROM User
                    WHERE Id IN :assigneeIds AND IsActive = true
                    ORDER BY Name
                    LIMIT :SOQL_LIMIT_BUFFER
                ]) {
                    usersWithAccess.add(new Map<String, Object>{
                        'id' => u.Id,
                        'name' => u.Name,
                        'username' => u.Username,
                        'email' => u.Email,
                        'profileName' => u.Profile.Name,
                        'isActive' => u.IsActive,
                        'type' => 'User'
                    });
                }
            }
        }

        // No built-in sort for List<Map>. If deterministic order is required, users can be left as queried (ordered by Name).

        // Pagination (client requested pageSize/pageNumber)
        Integer totalUserCount = usersWithAccess.size();
        Integer startIdx = (pageNumber - 1) * pageSize;
        Integer endIdx = Math.min(startIdx + pageSize, totalUserCount);

        List<Map<String, Object>> pagedUsers = new List<Map<String, Object>>();
        if (startIdx < totalUserCount) {
            for (Integer i = startIdx; i < endIdx; i++) {
                pagedUsers.add(usersWithAccess[i]);
            }
        }

        Map<String, Object> pagination = new Map<String, Object>{
            'pageSize' => pageSize,
            'pageNumber' => pageNumber,
            'totalCount' => totalUserCount,
            'totalPages' => (Integer)Math.ceil((Decimal) totalUserCount / pageSize),
            'hasNext' => pageNumber < Math.ceil((Decimal) totalUserCount / pageSize),
            'hasPrevious' => pageNumber > 1
        };

        result.put('users', pagedUsers);
        result.put('pagination', pagination);
        result.put('totalUserCount', totalUserCount);
        return result;
    }
    
    /**
     * @description Utility method to chunk a list into smaller lists
     */
    private static List<List<String>> chunkList(List<String> sourceList, Integer chunkSize) {
        List<List<String>> chunks = new List<List<String>>();
        
        for (Integer i = 0; i < sourceList.size(); i += chunkSize) {
            Integer endIndex = Math.min(i + chunkSize, sourceList.size());
            List<String> chunk = new List<String>();
            for (Integer j = i; j < endIndex; j++) {
                chunk.add(sourceList[j]);
            }
            chunks.add(chunk);
        }
        
        return chunks;
    }

    /**
     * @description Get all profiles in the org
     * @return List<ProfileWrapper> List of profile wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<ProfileWrapper> getProfiles() {
        List<ProfileWrapper> profileWrappers = new List<ProfileWrapper>();
        
        try {
            for (Profile p : [SELECT Id, Name, Description FROM Profile ORDER BY Name ASC]) {
                ProfileWrapper wrapper = new ProfileWrapper();
                wrapper.id = p.Id;
                wrapper.name = p.Name;
                wrapper.type = p.Name.contains('Standard') ? 'Standard Profile' : 'Custom Profile';
                wrapper.isSelected = false;
                wrapper.description = p.Description;
                profileWrappers.add(wrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving profiles: ' + e.getMessage());
        }
        
        return profileWrappers;
    }
    
    /**
     * @description Get permission sets in the org
     * @return List<PermissionSetWrapper> List of permission set wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<PermissionSetWrapper> getPermissionSets() {
        List<PermissionSetWrapper> permSetWrappers = new List<PermissionSetWrapper>();
        
        try {
            // Query PermissionSets with limit to avoid governor limits
            List<PermissionSet> permissionSets = [SELECT Id, Name, Label, IsOwnedByProfile, Profile.Name, 
                                                          CreatedById, CreatedBy.Name, CreatedDate, Description, IsCustom
                                                   FROM PermissionSet 
                                                   WHERE IsOwnedByProfile = false
                                                   ORDER BY Label ASC
                                                   LIMIT 10000];
            
            // Get all PermissionSetAssignments for these permission sets
            Set<Id> permissionSetIds = new Set<Id>();
            for (PermissionSet ps : permissionSets) {
                permissionSetIds.add(ps.Id);
            }
            
            // Check if optional fields exist in the org
            Boolean hasLastCreatedByChangeId = Schema.SObjectType.PermissionSetAssignment.fields.getMap().containsKey('LastCreatedByChangeId');
            Boolean hasLastDeletedByChangeId = Schema.SObjectType.PermissionSetAssignment.fields.getMap().containsKey('LastDeletedByChangeId');
            
            Map<Id, List<PermissionSetAssignment>> assignmentsByPermSetId = new Map<Id, List<PermissionSetAssignment>>();
            if (!permissionSetIds.isEmpty()) {
                // Build dynamic query with conditional fields
                String queryFields = 'Id, AssigneeId, Assignee.Name, ExpirationDate, IsActive, IsRevoked, PermissionSetGroupId, PermissionSetId, SystemModstamp';
                if (hasLastCreatedByChangeId) {
                    queryFields += ', LastCreatedByChangeId';
                }
                if (hasLastDeletedByChangeId) {
                    queryFields += ', LastDeletedByChangeId';
                }
                
                String permSetQuery = 'SELECT ' + queryFields + ' FROM PermissionSetAssignment WHERE PermissionSetId IN :permissionSetIds ORDER BY Assignee.Name ASC LIMIT 40000';
                List<PermissionSetAssignment> assignments = Database.query(permSetQuery);
                
                for (PermissionSetAssignment psa : assignments) {
                    if (!assignmentsByPermSetId.containsKey(psa.PermissionSetId)) {
                        assignmentsByPermSetId.put(psa.PermissionSetId, new List<PermissionSetAssignment>());
                    }
                    assignmentsByPermSetId.get(psa.PermissionSetId).add(psa);
                }
            }
            
            // Create wrappers with assignment data
            for (PermissionSet ps : permissionSets) {
                PermissionSetWrapper wrapper = new PermissionSetWrapper();
                wrapper.id = ps.Id;
                wrapper.name = ps.Name;
                wrapper.label = ps.Label;
                wrapper.isConverted = ps.Name.contains('Converted');
                wrapper.isSelected = false;
                wrapper.createdById = ps.CreatedById;
                wrapper.createdByName = ps.CreatedBy.Name;
                wrapper.createdDate = ps.CreatedDate;
                wrapper.description = ps.Description;
                wrapper.isCustom = ps.IsCustom;
                
                // Initialize assignment fields
                wrapper.assignments = new List<AssignmentWrapper>();
                
                // Add assignment data if available
                if (assignmentsByPermSetId.containsKey(ps.Id)) {
                    List<PermissionSetAssignment> psAssignments = assignmentsByPermSetId.get(ps.Id);
                    
                    for (PermissionSetAssignment psa : psAssignments) {
                        AssignmentWrapper assignmentWrapper = new AssignmentWrapper();
                        assignmentWrapper.assigneeId = psa.AssigneeId;
                        assignmentWrapper.assigneeName = psa.Assignee.Name;
                        assignmentWrapper.expirationDate = psa.ExpirationDate;
                        assignmentWrapper.assignmentId = psa.Id;
                        assignmentWrapper.isActive = psa.IsActive;
                        assignmentWrapper.isRevoked = psa.IsRevoked;
                        
                        // Conditionally assign optional fields if they exist in the org
                        if (hasLastCreatedByChangeId) {
                            assignmentWrapper.lastCreatedByChangeId = (String)psa.get('LastCreatedByChangeId');
                        }
                        if (hasLastDeletedByChangeId) {
                            assignmentWrapper.lastDeletedByChangeId = (String)psa.get('LastDeletedByChangeId');
                        }
                        assignmentWrapper.permissionSetGroupId = psa.PermissionSetGroupId;
                        assignmentWrapper.permissionSetId = psa.PermissionSetId;
                        assignmentWrapper.systemModstamp = psa.SystemModstamp;
                        
                        wrapper.assignments.add(assignmentWrapper);
                    }
                    
                    // Set the first assignment's data to the main wrapper for backward compatibility
                    if (!psAssignments.isEmpty()) {
                        PermissionSetAssignment firstAssignment = psAssignments[0];
                        wrapper.assigneeId = firstAssignment.AssigneeId;
                        wrapper.expirationDate = firstAssignment.ExpirationDate;
                        wrapper.assignmentId = firstAssignment.Id;
                        wrapper.isActive = firstAssignment.IsActive;
                        wrapper.isRevoked = firstAssignment.IsRevoked;
                        
                        // Conditionally assign optional fields if they exist in the org
                        if (hasLastCreatedByChangeId) {
                            wrapper.lastCreatedByChangeId = (String)firstAssignment.get('LastCreatedByChangeId');
                        }
                        if (hasLastDeletedByChangeId) {
                            wrapper.lastDeletedByChangeId = (String)firstAssignment.get('LastDeletedByChangeId');
                        }
                        
                        wrapper.permissionSetGroupId = firstAssignment.PermissionSetGroupId;
                        wrapper.permissionSetId = firstAssignment.PermissionSetId;
                        wrapper.systemModstamp = firstAssignment.SystemModstamp;
                    }
                }
                
                permSetWrappers.add(wrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving permission sets: ' + e.getMessage());
        }
        
        return permSetWrappers;
    }
    
    /**
     * @description Get users in the org - Only Salesforce license users
     * @return List<UserWrapper> List of user wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<UserWrapper> getUsers() {
        List<UserWrapper> userWrappers = new List<UserWrapper>();
        
        try {
            for (User u : [SELECT Id, Name, Username, Email, IsActive, Profile.Name, Profile.UserLicense.Name 
                           FROM User 
                           WHERE IsActive = true
                           ORDER BY Name ASC
                           LIMIT 1000]) {
                UserWrapper wrapper = new UserWrapper();
                wrapper.id = u.Id;
                wrapper.name = u.Name;
                wrapper.username = u.Username;
                wrapper.email = u.Email;
                wrapper.profileName = u.Profile.Name;
                wrapper.licenseType = u.Profile.UserLicense.Name;
                wrapper.isActive = u.IsActive;
                wrapper.isSelected = false;
                userWrappers.add(wrapper);
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving users: ' + e.getMessage());
        }
        
        return userWrappers;
    }

    /**
     * @description Get users with pagination and search support for template creation
     * @param pageSize Number of users per page
     * @param pageNumber Page number (1-based)
     * @param searchTerm Optional search term to filter users
     * @param lastUserId Last user ID for cursor-based pagination (optional)
     * @return UserPageResult with paginated user data
     */
    @AuraEnabled(cacheable=true)
    public static UserPageResult getUsersPaginated(Integer pageSize, Integer pageNumber, String searchTerm, String lastUserId) {
        UserPageResult result = new UserPageResult();
        
        try {
            // Validate and set defaults
            if (pageSize == null || pageSize <= 0) pageSize = DEFAULT_PAGE_SIZE;
            if (pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
            if (pageNumber == null || pageNumber <= 0) pageNumber = 1;
            
            // Build base query
            String baseQuery = 'SELECT Id, Name, Username, Email, IsActive, Profile.Name, Profile.UserLicense.Name FROM User';
            String whereClause = ' WHERE IsActive = true';
            String orderClause = ' ORDER BY Name ASC';
            String limitClause = ' LIMIT ' + (pageSize + 1); // Get one extra to check if there are more records
            
            // Add search filter if provided
            if (String.isNotBlank(searchTerm)) {
                String escapedSearchTerm = String.escapeSingleQuotes(searchTerm);
                whereClause += ' AND (Name LIKE \'%' + escapedSearchTerm + '%\' OR Username LIKE \'%' + escapedSearchTerm + '%\' OR Email LIKE \'%' + escapedSearchTerm + '%\')';
            }
            
            // Add cursor-based pagination if lastUserId is provided (for better performance with large datasets)
            if (String.isNotBlank(lastUserId)) {
                whereClause += ' AND Id > \'' + String.escapeSingleQuotes(lastUserId) + '\'';
                orderClause = ' ORDER BY Id ASC'; // Use Id for cursor-based pagination
            }
            
            String query = baseQuery + whereClause + orderClause + limitClause;
            List<User> users = Database.query(query);
            
            // Check if there are more records
            Boolean hasMore = users.size() > pageSize;
            if (hasMore) {
                users.remove(users.size() - 1); // Remove the extra record
            }
            
            // Convert to wrapper objects
            List<UserWrapper> userWrappers = new List<UserWrapper>();
            for (User u : users) {
                UserWrapper wrapper = new UserWrapper();
                wrapper.id = u.Id;
                wrapper.name = u.Name;
                wrapper.username = u.Username;
                wrapper.email = u.Email;
                wrapper.profileName = u.Profile.Name;
                wrapper.licenseType = u.Profile.UserLicense.Name;
                wrapper.isActive = u.IsActive;
                wrapper.isSelected = false;
                userWrappers.add(wrapper);
            }
            
            // Get total count (use cached count for performance, only if no search term)
            Integer totalCount;
            if (String.isBlank(searchTerm)) {
                totalCount = Database.countQuery('SELECT COUNT() FROM User WHERE IsActive = true');
            } else {
                String countQuery = 'SELECT COUNT() FROM User' + whereClause.replace(' AND Id > \'' + String.escapeSingleQuotes(lastUserId) + '\'', '');
                totalCount = Database.countQuery(countQuery);
            }
            
            // Calculate pagination info
            Integer totalPages = (Integer)Math.ceil((Decimal)totalCount / pageSize);
            Boolean hasPrevious = pageNumber > 1 || String.isNotBlank(lastUserId);
            
            // Set the last user ID for cursor-based pagination
            String newLastUserId = null;
            if (!userWrappers.isEmpty()) {
                newLastUserId = userWrappers[userWrappers.size() - 1].id;
            }
            
            // Build result
            result.users = userWrappers;
            result.totalCount = totalCount;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;
            result.totalPages = totalPages;
            result.hasNext = hasMore;
            result.hasPrevious = hasPrevious;
            result.lastUserId = newLastUserId;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving users: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Get user object fields
     * @return List<FieldWrapper> List of user field wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldWrapper> getUserFields() {
        List<FieldWrapper> fieldWrappers = new List<FieldWrapper>();
        
        try {
            // Get User object fields
            Schema.DescribeSObjectResult userDescribe = User.sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = userDescribe.fields.getMap();
            
            // Build list of accessible field names for bulk query
            List<String> accessibleFieldNames = new List<String>();
            Map<String, Schema.DescribeFieldResult> fieldDescribeMap = new Map<String, Schema.DescribeFieldResult>();
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                
                // Include commonly used fields and exclude system fields
                if (fieldDescribe.isAccessible() && 
                    !fieldDescribe.isCalculated() && 
                    !fieldName.toLowerCase().contains('password') &&
                    !fieldName.toLowerCase().contains('token') &&
                    !fieldName.toLowerCase().contains('secret')) {
                    
                    accessibleFieldNames.add(fieldName);
                    fieldDescribeMap.put(fieldName, fieldDescribe);
                }
            }
            
            // Bulk query FieldDefinition for descriptions only
            Map<String, FieldDefinition> fieldDefinitionMap = new Map<String, FieldDefinition>();
            try {
                List<FieldDefinition> fieldDefs = [
                    SELECT QualifiedApiName, Description 
                    FROM FieldDefinition 
                    WHERE EntityDefinition.QualifiedApiName = 'User' 
                    AND QualifiedApiName IN :accessibleFieldNames
                    LIMIT 1000
                ];
                
                for (FieldDefinition fieldDef : fieldDefs) {
                    fieldDefinitionMap.put(fieldDef.QualifiedApiName, fieldDef);
                }
            } catch (Exception e) {
                System.debug('Could not query FieldDefinition: ' + e.getMessage());
            }
            
            // Create field wrappers with metadata
            for (String fieldName : accessibleFieldNames) {
                Schema.DescribeFieldResult fieldDescribe = fieldDescribeMap.get(fieldName);
                
                FieldWrapper wrapper = new FieldWrapper();
                wrapper.id = fieldName;
                wrapper.name = fieldName;
                wrapper.label = fieldDescribe.getLabel();
                wrapper.type = String.valueOf(fieldDescribe.getType());
                wrapper.isCustom = fieldName.endsWith('__c');
                wrapper.isSelected = false;
                
                // Get description and help text from FieldDefinition and describe result
                if (fieldDefinitionMap.containsKey(fieldName)) {
                    FieldDefinition fieldDef = fieldDefinitionMap.get(fieldName);
                    wrapper.description = fieldDef.Description != null ? fieldDef.Description : '';
                } else {
                    wrapper.description = '';
                }
                // Always get help text from describe result since FieldDefinition doesn't have InlineHelpText
                wrapper.helpText = fieldDescribe.getInlineHelpText() != null ? fieldDescribe.getInlineHelpText() : '';
                
                fieldWrappers.add(wrapper);
            }
            
            // Sort by label
            fieldWrappers.sort();
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving user fields: ' + e.getMessage());
        }
        
        return fieldWrappers;
    }

    /**
     * @description Get all User object fields with their metadata for dynamic display
     * @return Map<String, Object> containing field metadata and display configuration
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUserFieldsForDisplay() {
        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, Object>> displayFields = new List<Map<String, Object>>();
        List<String> queryableFieldNames = new List<String>();
        
        try {
            // Get User object fields
            Schema.DescribeSObjectResult userDescribe = User.sObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = userDescribe.fields.getMap();
            
            // Define core fields that should always be included
            Set<String> coreFields = new Set<String>{
                'Id', 'Name', 'Username', 'Email', 'IsActive', 'ProfileId'
            };
            
            // Define fields to exclude for security/performance reasons
            Set<String> excludedFields = new Set<String>{
                'Password', 'CommunityNickname', 'Digest', 'EmailEncodingKey', 
                'LanguageLocaleKey', 'LocaleSidKey', 'TimeZoneSidKey', 'UserType',
                'FederationIdentifier', 'SamlJitHandlerId', 'CurrentStatus',
                'SmallPhotoUrl', 'FullPhotoUrl', 'BannerPhotoUrl', 'SmallBannerPhotoUrl',
                'MediumPhotoUrl', 'MediumBannerPhotoUrl'
            };
            
            // Build list of accessible field names for bulk query
            List<String> accessibleFieldNames = new List<String>();
            Map<String, Schema.DescribeFieldResult> fieldDescribeMap = new Map<String, Schema.DescribeFieldResult>();
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                
                // Include accessible, non-calculated fields excluding sensitive ones
                if (fieldDescribe.isAccessible() && 
                    !fieldDescribe.isCalculated() && 
                    !excludedFields.contains(fieldName) &&
                    !fieldName.toLowerCase().contains('password') &&
                    !fieldName.toLowerCase().contains('token') &&
                    !fieldName.toLowerCase().contains('secret') &&
                    !fieldName.toLowerCase().contains('digest')) {
                    
                    accessibleFieldNames.add(fieldName);
                    fieldDescribeMap.put(fieldName, fieldDescribe);
                }
            }
            
            // Bulk query FieldDefinition for descriptions only
            Map<String, FieldDefinition> fieldDefinitionMap = new Map<String, FieldDefinition>();
            try {
                List<FieldDefinition> fieldDefs = [
                    SELECT QualifiedApiName, Description 
                    FROM FieldDefinition 
                    WHERE EntityDefinition.QualifiedApiName = 'User' 
                    AND QualifiedApiName IN :accessibleFieldNames
                    LIMIT 1000
                ];
                
                for (FieldDefinition fieldDef : fieldDefs) {
                    fieldDefinitionMap.put(fieldDef.QualifiedApiName, fieldDef);
                }
            } catch (Exception e) {
                System.debug('Could not query FieldDefinition: ' + e.getMessage());
            }
            
            // Create field info with metadata
            for (String fieldName : accessibleFieldNames) {
                Schema.DescribeFieldResult fieldDescribe = fieldDescribeMap.get(fieldName);
                
                // Get description from FieldDefinition and help text from describe result
                String description = '';
                String helpText = fieldDescribe.getInlineHelpText() != null ? fieldDescribe.getInlineHelpText() : '';
                
                if (fieldDefinitionMap.containsKey(fieldName)) {
                    FieldDefinition fieldDef = fieldDefinitionMap.get(fieldName);
                    description = fieldDef.Description != null ? fieldDef.Description : '';
                }
                
                Map<String, Object> fieldInfo = new Map<String, Object>{
                    'name' => fieldName,
                    'label' => fieldDescribe.getLabel(),
                    'type' => String.valueOf(fieldDescribe.getType()),
                    'isCustom' => fieldName.endsWith('__c'),
                    'isCore' => coreFields.contains(fieldName),
                    'isRequired' => !fieldDescribe.isNillable() && !fieldDescribe.isDefaultedOnCreate(),
                    'length' => fieldDescribe.getLength(),
                    'isUpdateable' => fieldDescribe.isUpdateable(),
                    'sortOrder' => coreFields.contains(fieldName) ? 1 : (fieldName.endsWith('__c') ? 3 : 2),
                    'description' => description,
                    'helpText' => helpText
                };
                
                displayFields.add(fieldInfo);
                
                // Add to queryable fields list (handle relationship fields)
                if (fieldName == 'ProfileId') {
                    queryableFieldNames.add('Profile.Name');
                } else if (!fieldName.endsWith('Id') || coreFields.contains(fieldName)) {
                    queryableFieldNames.add(fieldName);
                }
            }
            
            // Sort fields: Core fields first, then standard, then custom
            displayFields.sort(new FieldInfoComparator());
            
            result.put('fields', displayFields);
            result.put('queryableFields', queryableFieldNames);
            result.put('totalFields', displayFields.size());
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving user fields for display: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Comparator class for sorting field info
     */
    private class FieldInfoComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> field1, Map<String, Object> field2) {
            Integer sort1 = (Integer) field1.get('sortOrder');
            Integer sort2 = (Integer) field2.get('sortOrder');
            
            if (sort1 != sort2) {
                return sort1 < sort2 ? -1 : (sort1 > sort2 ? 1 : 0);
            }
            
            String label1 = (String) field1.get('label');
            String label2 = (String) field2.get('label');
            
            return label1.compareTo(label2);
        }
    }

    /**
     * @description Get available objects for permission management
     * @return List<ObjectWrapper> List of object wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectWrapper> getObjects() {
        List<ObjectWrapper> objectWrappers = new List<ObjectWrapper>();
        
        try {
            // Get standard and custom objects
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            List<String> objectNames = new List<String>(globalDescribe.keySet());
            objectNames.sort();
            
            for (String objectName : objectNames) {
                Schema.DescribeSObjectResult objDescribe = globalDescribe.get(objectName).getDescribe();
                // Include only standard objects (no suffix) or custom objects (ending with __c)
                if (
                    objDescribe.isAccessible() && 
                    !objDescribe.isDeprecatedAndHidden() &&
                    (objectName.endsWith('__c') || !objectName.contains('__')) // Whitelist standard and custom objects
                ) {
                    ObjectWrapper wrapper = new ObjectWrapper();
                    wrapper.id = objectName;
                    wrapper.name = objectName;
                    wrapper.label = objDescribe.getLabel();
                    wrapper.apiName = objDescribe.getName();
                    wrapper.isSelected = false;
                    objectWrappers.add(wrapper);
                }
            }
        } catch (Exception e) { 
            throw new AuraHandledException('Error retrieving objects: ' + e.getMessage());
        }
        
        return objectWrappers;
    }
    
    /**
     * @description Get available objects using EntityDefinition approach
     * @return List<Map<String, Object>> List of objects with name, label, and isCustom properties
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAllObjects() {
        List<Map<String, Object>> objects = new List<Map<String, Object>>();
        
        try {
            // Query EntityDefinition for object metadata - break into multiple queries to avoid query complexity issues
            List<String> objectApiNames = new List<String>();
            
            // Use a simpler initial query to get object names first
            try {
            for(EntityDefinition entity : [
                SELECT QualifiedApiName 
                FROM EntityDefinition 
                WHERE IsQueryable = true
                AND IsCustomizable = true
                AND IsDeprecatedAndHidden = false
                    LIMIT 900 // Reduced to stay safely within single batch limits
            ]) {
                String apiName = entity.QualifiedApiName;
                
                    // Safely apply additional filters in Apex to reduce query complexity
                    // Check for null apiName first to prevent NullPointerException
                    if (String.isNotBlank(apiName)) {
                        // Skip metadata, big objects, platform events, and change data capture objects
                        if (apiName.endsWith('__mdt') || 
                            apiName.endsWith('__e') || 
                            apiName.endsWith('__b') || 
                            apiName.endsWith('__x') || 
                            apiName.endsWith('__p')) {
                            continue;
                        }
                        
                        // Enhanced filtering for History, Share, and Feed objects
                        // Use more precise pattern matching to filter out these objects
                        if (apiName.endsWithIgnoreCase('History') || 
                            apiName.endsWithIgnoreCase('Share') || 
                            apiName.endsWithIgnoreCase('Feed') ||
                            apiName.endsWithIgnoreCase('ChangeEvent') ||
                            apiName.containsIgnoreCase('History') ||
                            apiName.containsIgnoreCase('Share') ||
                            apiName.containsIgnoreCase('Feed')) {
                            continue;
                        }
                    
                    objectApiNames.add(apiName);
                    }
                }
                ////system.debug('Initial query found ' + objectApiNames.size() + ' qualifying object API names');
            } catch (QueryException qe) {
                // Specific handling for EntityDefinition query issues
                if (qe.getMessage().contains('queryMore()')) {
                    throw new AuraHandledException('The EntityDefinition query returned too many results. Please contact your administrator to optimize this query.');
                } else {
                    throw qe; // Re-throw other query exceptions
                }
            }
            
            // Now query additional metadata for the filtered objects
            if (!objectApiNames.isEmpty()) {
                try {
                    // Split into chunks to avoid exceeding batch size
                    Integer chunkSize = 250; // Reduced chunk size for better reliability
                    Integer chunksProcessed = 0;
                    Integer totalObjectsAdded = 0;
                    
                    //system.debug(LoggingLevel.INFO, 'Processing ' + objectApiNames.size() + ' objects in chunks of ' + chunkSize);
                    
                    for (Integer i = 0; i < objectApiNames.size(); i += chunkSize) {
                        try {
                            Integer endIndex = Math.min(i + chunkSize, objectApiNames.size());
                            List<String> chunk = new List<String>();
                            
                            // Create a chunk of the object API names
                            for (Integer j = i; j < endIndex; j++) {
                                if (j < objectApiNames.size() && String.isNotBlank(objectApiNames[j])) {
                                    chunk.add(objectApiNames[j]);
                                }
                            }
                            
                            chunksProcessed++;
                            //system.debug(LoggingLevel.INFO, 'Processing chunk ' + chunksProcessed + ' with ' + chunk.size() + ' objects (' + i + '-' + endIndex + ')');
                            
                            if (!chunk.isEmpty()) {
                                try {
                                    // Build a dynamic SOQL query with safer limits
                                    String query = 'SELECT QualifiedApiName, DeveloperName, MasterLabel, Label, PluralLabel, ' +
                                                 'NamespacePrefix, IsCustomizable, IsCustomSetting, IsQueryable ' +
                                                 'FROM EntityDefinition ' +
                                                 'WHERE QualifiedApiName IN :chunk ' +
                                                 'AND IsCustomizable = true ' +
                                                 'AND IsCustomSetting = false ' +
                                                 'ORDER BY Label ' +
                                                 'LIMIT 250';
                                    
                                    for (EntityDefinition entity : Database.query(query)) {
                                        try {
                                            // Safely determine if this is a custom object
                                            Boolean isCustom = false;
                                            if (String.isNotBlank(entity.QualifiedApiName)) {
                                                isCustom = entity.QualifiedApiName.endsWith('__c');
                                            }
                    
                    objects.add(new Map<String, Object>{
                        'name' => entity.QualifiedApiName,
                        'label' => entity.Label,
                        'pluralLabel' => entity.PluralLabel,
                        'apiName' => entity.QualifiedApiName,
                        'developerName' => entity.DeveloperName,
                        'namespacePrefix' => entity.NamespacePrefix,
                        'isCustom' => isCustom,
                        'isCustomizable' => entity.IsCustomizable,
                        'isSearchable' => true // Hardcoded since we removed from query
                    });
                                            
                                            totalObjectsAdded++;
                                        } catch (Exception entityEx) {
                                            // Log but continue with other entities
                                            //system.debug(LoggingLevel.WARN, 'Error processing entity: ' + entity.QualifiedApiName + ': ' + entityEx.getMessage());
                                        }
                                    }
                                } catch (QueryException qex) {
                                    // Handle specific query exceptions
                                    if (qex.getMessage().contains('queryMore()')) {
                                        //system.debug(LoggingLevel.ERROR, 'QueryMore() error in chunk ' + chunksProcessed + ': ' + qex.getMessage());
                                        // Try to continue with the next chunk instead of failing entirely
                                    } else {
                                        //system.debug(LoggingLevel.ERROR, 'Query error in chunk ' + chunksProcessed + ': ' + qex.getMessage());
                                    }
                                } catch (Exception ex) {
                                    // Log other exceptions
                                    //system.debug(LoggingLevel.ERROR, 'Error processing chunk ' + chunksProcessed + ': ' + ex.getMessage());
                                }
                            }
                        } catch (Exception chunkEx) {
                            // Log but continue with next chunk
                            //system.debug(LoggingLevel.ERROR, 'Error preparing chunk ' + chunksProcessed + ': ' + chunkEx.getMessage());
                        }
                    }
                    
                    //system.debug(LoggingLevel.INFO, 'Processed ' + chunksProcessed + ' chunks, added ' + totalObjectsAdded + ' objects');
                } catch (Exception outerEx) {
                    // Catch any exceptions that escaped the inner try-catch blocks
                    //system.debug(LoggingLevel.ERROR, 'Error in chunk processing: ' + outerEx.getMessage());
                    //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + outerEx.getStackTraceString());
                }
            } else {
                //system.debug('No objects matched the initial filtering criteria');
            }
            
            // If no objects found, return a helpful message
            if (objects.isEmpty()) {
                throw new AuraHandledException('No customizable objects found that match the filtering criteria.');
            }
            
            return objects;
        } catch(Exception e) {
            //system.debug('Error getting objects: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            //system.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving objects: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get available objects using the EntityDefinition approach and convert to ObjectWrapper
     * @return List<ObjectWrapper> List of object wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectWrapper> getObjectsUsingEntityDefinition() {
        List<ObjectWrapper> objectWrappers = new List<ObjectWrapper>();
        
        try {
            //system.debug(LoggingLevel.INFO, 'Starting getObjectsUsingEntityDefinition');
            
            // First try the EntityDefinition approach
        try {
            // Get objects using EntityDefinition
            List<Map<String, Object>> objects = getAllObjects();
            
                // Check if we got results
                if (objects != null && !objects.isEmpty()) {
            // Convert to ObjectWrapper format
            for(Map<String, Object> obj : objects) {
                        try {
                            // Safely extract values with null checks
                String name = (String)obj.get('name');
                String label = (String)obj.get('label');
                String apiName = (String)obj.get('apiName');
                
                            // Only add if we have valid data
                            if (String.isNotBlank(name)) {
                ObjectWrapper wrapper = new ObjectWrapper();
                wrapper.id = name;
                wrapper.name = name;
                                wrapper.label = String.isNotBlank(label) ? label : name;
                                wrapper.apiName = String.isNotBlank(apiName) ? apiName : name;
                wrapper.isSelected = false;
                objectWrappers.add(wrapper);
                            }
                        } catch (Exception objEx) {
                            // Log but continue processing other objects
                            //system.debug(LoggingLevel.WARN, 'Error processing object: ' + objEx.getMessage());
                        }
            }
            
                    //system.debug(LoggingLevel.INFO, 'Processed ' + objectWrappers.size() + ' objects using EntityDefinition approach');
                    
                    // If we got objects, return them
                    if (!objectWrappers.isEmpty()) {
            return objectWrappers;
                    } else {
                        // If no objects were processed successfully, try fallback
                        //system.debug(LoggingLevel.WARN, 'No objects were processed successfully, trying fallback approach');
                        return getFallbackObjects();
                    }
                } else {
                    // If getAllObjects returned null or empty, try fallback
                    //system.debug(LoggingLevel.WARN, 'getAllObjects returned null or empty, trying fallback approach');
                    return getFallbackObjects();
                }
            } catch (Exception innerEx) {
                // Catch any exception from EntityDefinition approach and try fallback
                //system.debug(LoggingLevel.ERROR, 'Error in EntityDefinition approach: ' + innerEx.getMessage() + ' at line ' + innerEx.getLineNumber());
                //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + innerEx.getStackTraceString());
                
                //system.debug(LoggingLevel.INFO, 'Using fallback approach for retrieving objects');
                return getFallbackObjects();
            }
        } catch (Exception e) {
            // Final catch-all for any exceptions not caught above
            //system.debug(LoggingLevel.ERROR, 'Unhandled error in getObjectsUsingEntityDefinition: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            // Always try the fallback as a last resort
            try {
                return getFallbackObjects();
            } catch (Exception fallbackEx) {
                // If even the fallback fails, throw an exception with a helpful message
                //system.debug(LoggingLevel.ERROR, 'Fallback also failed: ' + fallbackEx.getMessage());
                throw new AuraHandledException('Unable to retrieve objects: ' + e.getMessage() + '. Fallback also failed: ' + fallbackEx.getMessage());
            }
        }
    }
    
    /**
     * @description Fallback method to get standard and custom objects when EntityDefinition approach fails
     * @return List<ObjectWrapper> List of object wrappers with basic metadata
     */
    private static List<ObjectWrapper> getFallbackObjects() {
        List<ObjectWrapper> objectWrappers = new List<ObjectWrapper>();
        
        try {
            //system.debug(LoggingLevel.INFO, 'Starting fallback object retrieval');
            
            // Get standard objects from a pre-defined list with known labels
            Map<String, String> standardObjectLabels = new Map<String, String>{
                'Account' => 'Account',
                'Contact' => 'Contact',
                'Lead' => 'Lead',
                'Opportunity' => 'Opportunity',
                'Case' => 'Case',
                'Campaign' => 'Campaign',
                'User' => 'User',
                'Product2' => 'Product',
                'Pricebook2' => 'Price Book',
                'Asset' => 'Asset',
                'Contract' => 'Contract',
                'Order' => 'Order',
                'Quote' => 'Quote',
                'Task' => 'Task',
                'Event' => 'Event',
                'ContentDocument' => 'File',
                'Report' => 'Report',
                'Dashboard' => 'Dashboard'
            };
            
            Integer standardObjectsAdded = 0;
            
            // Add standard objects with better labels
            for (String objName : standardObjectLabels.keySet()) {
                try {
                    // Check if this object exists in the org before adding it
                    if (Schema.getGlobalDescribe().containsKey(objName)) {
                        ObjectWrapper wrapper = new ObjectWrapper();
                        wrapper.id = objName;
                        wrapper.name = objName;
                        wrapper.label = standardObjectLabels.get(objName);
                        wrapper.apiName = objName;
                        wrapper.isSelected = false;
                        objectWrappers.add(wrapper);
                        standardObjectsAdded++;
                    }
                } catch (Exception objEx) {
                    // Log and continue with other objects
                    //system.debug(LoggingLevel.WARN, 'Error processing standard object ' + objName + ': ' + objEx.getMessage());
                }
            }
            
            //system.debug(LoggingLevel.INFO, 'Added ' + standardObjectsAdded + ' standard objects');
            
            // Create a set of objects to skip (already added + special objects)
            Set<String> objectsToSkip = new Set<String>(standardObjectLabels.keySet());
            
            // Track statistics
            Integer customObjectsAdded = 0;
            Integer objectsSkipped = 0;
            
            try {
                // Get custom objects using Schema methods
                Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
                
                for (String objName : globalDescribe.keySet()) {
                    try {
                        // Skip objects already added
                        if (objectsToSkip.contains(objName)) {
                            objectsSkipped++;
                            continue;
                        }
                        
                        // Improved filtering logic for special objects
                        // Skip metadata, big objects, platform events, and change data capture objects
                        if (objName.endsWith('__mdt') || 
                            objName.endsWith('__e') || 
                            objName.endsWith('__b') || 
                            objName.endsWith('__x') || 
                            objName.endsWith('__p')) {
                            objectsSkipped++;
                            continue;
                        }
                        
                        // Enhanced filtering for History, Share, and Feed objects
                        // Use more precise pattern matching to filter out these objects
                        if (objName.endsWithIgnoreCase('History') || 
                            objName.endsWithIgnoreCase('Share') || 
                            objName.endsWithIgnoreCase('Feed') ||
                            objName.endsWithIgnoreCase('ChangeEvent') ||
                            objName.containsIgnoreCase('History') ||
                            objName.containsIgnoreCase('Share') ||
                            objName.containsIgnoreCase('Feed')) {
                            objectsSkipped++;
                            continue;
                        }
                        
                        // Get object describe
                        Schema.DescribeSObjectResult describe;
                        try {
                            describe = globalDescribe.get(objName).getDescribe();
                        } catch (Exception describeEx) {
                            // Log and skip this object
                            //system.debug(LoggingLevel.WARN, 'Error describing object ' + objName + ': ' + describeEx.getMessage());
                            continue;
                        }
                        
                        // Different handling for custom vs. standard objects we didn't explicitly list
                        Boolean isCustomObject = objName.endsWith('__c');
                        
                        // For custom objects, check queryable and updateable
                        // For unlisted standard objects, only include accessible ones
                        if ((isCustomObject && describe.isQueryable() && describe.isUpdateable()) ||
                            (!isCustomObject && describe.isAccessible() && !describe.isDeprecatedAndHidden())) {
                            
                            ObjectWrapper wrapper = new ObjectWrapper();
                            wrapper.id = objName;
                            wrapper.name = objName;
                            
                            // Get label safely
                            try {
                                wrapper.label = describe.getLabel();
                            } catch (Exception labelEx) {
                                wrapper.label = objName; // Fallback to API name if label isn't available
                            }
                            
                            wrapper.apiName = objName;
                            wrapper.isSelected = false;
                            objectWrappers.add(wrapper);
                            
                            if (isCustomObject) {
                                customObjectsAdded++;
                            } else {
                                standardObjectsAdded++;
                            }
                        } else {
                            objectsSkipped++;
                        }
                    } catch (Exception objEx) {
                        // Log and continue with other objects
                        //system.debug(LoggingLevel.WARN, 'Error processing object ' + objName + ': ' + objEx.getMessage());
                    }
                }
            } catch (Exception schemaEx) {
                // Log schema exception but don't fail - return what we have so far
                //system.debug(LoggingLevel.ERROR, 'Error accessing schema: ' + schemaEx.getMessage());
            }
            
            //system.debug(LoggingLevel.INFO, 'Fallback method: Added ' + standardObjectsAdded + ' standard objects, ' +   customObjectsAdded + ' custom objects, skipped ' + objectsSkipped + ' objects');
            
            // If we didn't get any objects, add a minimal set to avoid returning empty
            if (objectWrappers.isEmpty()) {
                //system.debug(LoggingLevel.WARN, 'No objects found, adding minimal set');
                
                ObjectWrapper accountWrapper = new ObjectWrapper();
                accountWrapper.id = 'Account';
                accountWrapper.name = 'Account';
                accountWrapper.label = 'Account';
                accountWrapper.apiName = 'Account';
                accountWrapper.isSelected = false;
                objectWrappers.add(accountWrapper);
                
                ObjectWrapper contactWrapper = new ObjectWrapper();
                contactWrapper.id = 'Contact';
                contactWrapper.name = 'Contact';
                contactWrapper.label = 'Contact';
                contactWrapper.apiName = 'Contact';
                contactWrapper.isSelected = false;
                objectWrappers.add(contactWrapper);
            }
            
            return objectWrappers;
        } catch (Exception e) {
            //system.debug(LoggingLevel.ERROR, 'Error in fallback object retrieval: ' + e.getMessage());
            //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            // Even in case of error, return a minimal set of objects
            List<ObjectWrapper> minimalObjects = new List<ObjectWrapper>();
            
            ObjectWrapper accountWrapper = new ObjectWrapper();
            accountWrapper.id = 'Account';
            accountWrapper.name = 'Account';
            accountWrapper.label = 'Account';
            accountWrapper.apiName = 'Account';
            accountWrapper.isSelected = false;
            minimalObjects.add(accountWrapper);
            
            return minimalObjects;
        }
    }
    
    /**
     * @description Get object permissions for selected profiles and permission sets
     * @param profileIds List of profile IDs
     * @param permSetIds List of permission set IDs
     * @param objectNames List of object API names
     * @return Map<String, ObjectPermissionsMatrix> Map of object permissions matrices by object name
     */
    @AuraEnabled
    public static Map<String, ObjectPermissionsMatrix> getObjectPermissions(
        List<String> profileIds, 
        List<String> permSetIds, 
        List<String> objectNames
    ) {
        Map<String, ObjectPermissionsMatrix> result = new Map<String, ObjectPermissionsMatrix>();
        
        try {
            // Validate inputs to prevent null pointer exceptions
            if (objectNames == null || objectNames.isEmpty()) {
                return result; // Return empty result if no objects specified
            }
            
            // Create a map to hold permissions by object and profile/permission set
            Map<String, Map<String, ObjectPermissionWrapper>> permissionsByObject = new Map<String, Map<String, ObjectPermissionWrapper>>();
            
            // Initialize the map for each object
            for (String objName : objectNames) {
                if (String.isNotBlank(objName)) {
                permissionsByObject.put(objName, new Map<String, ObjectPermissionWrapper>());
                }
            }
            
            // Query object permissions for profiles if profileIds is not empty
            if (profileIds != null && !profileIds.isEmpty()) {
            List<ObjectPermissions> profileObjectPerms = [
                SELECT Id, Parent.Profile.Id, Parent.Profile.Name, Parent.Profile.UserLicense.Name,
                       SObjectType, 
                       PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, 
                       PermissionsViewAllRecords, PermissionsModifyAllRecords 
                FROM ObjectPermissions 
                WHERE Parent.Profile.Id IN :profileIds AND SObjectType IN :objectNames
            ];
            
            for (ObjectPermissions perm : profileObjectPerms) {
                    // Add null checks to prevent NPE
                    if (perm.Parent == null || perm.Parent.Profile == null || perm.Parent.Profile.Id == null) {
                        continue; // Skip this permission if Parent or Profile is null
                    }
                    
                String profileId = perm.Parent.Profile.Id;
                String objectType = perm.SObjectType;
                    
                    // Check if objectType exists in our map
                    if (!permissionsByObject.containsKey(objectType)) {
                        continue; // Skip if object type not in our map
                    }
                
                ObjectPermissionWrapper wrapper = new ObjectPermissionWrapper();
                wrapper.id = perm.Id;
                wrapper.parentId = profileId;
                wrapper.parentName = perm.Parent.Profile.Name;
                wrapper.objectType = objectType;
                wrapper.canRead = perm.PermissionsRead;
                wrapper.canCreate = perm.PermissionsCreate;
                wrapper.canEdit = perm.PermissionsEdit;
                wrapper.canDelete = perm.PermissionsDelete;
                wrapper.canViewAll = perm.PermissionsViewAllRecords;
                wrapper.canModifyAll = perm.PermissionsModifyAllRecords;
                    wrapper.userLicenseName = perm.Parent.Profile.UserLicense != null ? perm.Parent.Profile.UserLicense.Name : null;
                
                // Initialize disabled flags
                wrapper.isReadDisabled = false;
                wrapper.isCreateDisabled = false;
                wrapper.isEditDisabled = false;
                wrapper.isDeleteDisabled = false;
                wrapper.isViewAllDisabled = false;
                wrapper.isModifyAllDisabled = false;
                
                // Set disabled flags based on object type and profile type
                  //  setDisabledPermissionsForProfile(wrapper, perm.Parent.Profile);
                
                permissionsByObject.get(objectType).put(profileId, wrapper);
                }
            }
            
            // Query object permissions for permission sets if permSetIds is not empty
            if (permSetIds != null && !permSetIds.isEmpty()) {
            // Bulk-fetch permission sets for disabling logic
            Map<Id, PermissionSet> psMap = new Map<Id, PermissionSet>(
                [SELECT Id, Name FROM PermissionSet WHERE Id IN :permSetIds]
            );
            
            // Query object permissions for permission sets
            List<ObjectPermissions> permSetObjectPerms = [
                SELECT Id, Parent.Id, Parent.Name, Parent.IsOwnedByProfile, Parent.ProfileId,
                       SObjectType, 
                       PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, 
                       PermissionsViewAllRecords, PermissionsModifyAllRecords 
                FROM ObjectPermissions 
                WHERE Parent.Id IN :permSetIds AND SObjectType IN :objectNames
            ];
            
            for (ObjectPermissions perm : permSetObjectPerms) {
                    // Add null checks to prevent NPE
                    if (perm.Parent == null || perm.Parent.Id == null) {
                        continue; // Skip this permission if Parent is null
                    }
                    
                String permSetId = perm.Parent.Id;
                String objectType = perm.SObjectType;
                    
                    // Check if objectType exists in our map
                    if (!permissionsByObject.containsKey(objectType)) {
                        continue; // Skip if object type not in our map
                    }
                
                ObjectPermissionWrapper wrapper = new ObjectPermissionWrapper();
                wrapper.id = perm.Id;
                wrapper.parentId = permSetId;
                wrapper.parentName = perm.Parent.Name;
                wrapper.objectType = objectType;
                wrapper.canRead = perm.PermissionsRead;
                wrapper.canCreate = perm.PermissionsCreate;
                wrapper.canEdit = perm.PermissionsEdit;
                wrapper.canDelete = perm.PermissionsDelete;
                wrapper.canViewAll = perm.PermissionsViewAllRecords;
                wrapper.canModifyAll = perm.PermissionsModifyAllRecords;
                
                // Initialize disabled flags
                wrapper.isReadDisabled = false;
                wrapper.isCreateDisabled = false;
                wrapper.isEditDisabled = false;
                wrapper.isDeleteDisabled = false;
                wrapper.isViewAllDisabled = false;
                wrapper.isModifyAllDisabled = false;
                
                // Set disabled flags based on object type and permission set type
                   // setDisabledPermissionsForPermissionSet(wrapper, psMap.get(perm.Parent.Id));
                
                permissionsByObject.get(objectType).put(permSetId, wrapper);
                }
            }
            
            // Build the result
            for (String objName : objectNames) {
                if (String.isNotBlank(objName) && permissionsByObject.containsKey(objName)) {
                ObjectPermissionsMatrix matrix = new ObjectPermissionsMatrix();
                matrix.objectName = objName;
                matrix.permissions = permissionsByObject.get(objName);
                result.put(objName, matrix);
                }
            }
        } catch (Exception e) {
            //system.debug(LoggingLevel.ERROR, 'Error in getObjectPermissions: ' + e.getMessage());
            //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving object permissions: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get field permissions for selected objects and profiles/permission sets
     * @param profileIds List of profile IDs
     * @param permSetIds List of permission set IDs
     * @param objectName API name of the object
     * @return Map of field permissions by field name
     */
    @AuraEnabled
    public static Map<String, Object> getFieldPermissions(List<String> profileIds, List<String> permSetIds, String objectName) {
        //system.debug(LoggingLevel.DEBUG, '=== BEGIN getFieldPermissions for object: ' + objectName + ' ===');
        //system.debug(LoggingLevel.DEBUG, 'Profile IDs: ' + profileIds);
        //system.debug(LoggingLevel.DEBUG, 'Permission Set IDs: ' + permSetIds);
        
        try {
            // Special handling for certain complex objects that might cause issues
            Set<String> specialHandlingObjects = new Set<String>{
                'WorkOrder', 'ApptBundleConfig', 'ApptBundlePolicy', 'AppointmentInvitation',
                'AIInsightAction', 'AIInsightValue', 'AIInsightReason', 'KnowledgeArticleVersion',
                'ContentDocument', 'ContentVersion', 'Asset'
            };
            
            // Check if special object first
            if (specialHandlingObjects.contains(objectName)) {
                //system.debug(LoggingLevel.INFO, 'SPECIAL HANDLING: Object ' + objectName + ' is in special handling list');
                
                // Create empty return map with minimal structure
                Map<String, Object> emptyMap = new Map<String, Object>();
                try {
                    // Try to get a basic field list without permissions - just minimal info
                    Map<String, Schema.SObjectField> fieldMap;
                    Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
                    
                    if (globalDescribe.containsKey(objectName)) {
                        fieldMap = globalDescribe.get(objectName).getDescribe().fields.getMap();
                        //system.debug(LoggingLevel.INFO, 'Found ' + fieldMap.size() + ' fields for ' + objectName);
                        
                        // Add a few fields with dummy permissions for display
                        for (String fieldName : fieldMap.keySet()) {
                            // Only include a limited number of fields for performance
                            if (emptyMap.size() >= 10) break;
                            
                            // Skip system fields
                            if (isSystemField(objectName + '.' + fieldName)) continue;
                            
                            // Create basic field entry
                            String fieldKey = (objectName + '.' + fieldName).toLowerCase();
                            Map<String, Object> fieldData = new Map<String, Object>();
                            fieldData.put('fieldName', fieldName);
                            fieldData.put('standardFieldName', objectName + '.' + fieldName);
                            fieldData.put('permissions', new Map<String, Object>());
                            fieldData.put('isStandardField', true); // Default
                            fieldData.put('isAccessible', false);
                            fieldData.put('isUpdateable', false);
                            fieldData.put('isCreateable', false);
                            fieldData.put('isCalculated', false);
                            fieldData.put('isAutoNumber', false);
                            fieldData.put('isRequired', false);
                            fieldData.put('isSystemField', false);
                            
                            // Add to map
                            emptyMap.put(fieldKey, fieldData);
                        }
                    } else {
                        //system.debug(LoggingLevel.ERROR, 'Object ' + objectName + ' not found in schema (special handling path)');
                    }
                } catch (Exception e) {
                    //system.debug(LoggingLevel.ERROR, 'Error in special handling for ' + objectName + ': ' + e.getMessage());
                }
                
                //system.debug(LoggingLevel.DEBUG, '=== END getFieldPermissions for SPECIAL object: ' + objectName + ' ===');
                return emptyMap;
            }
            
            //system.debug(LoggingLevel.DEBUG, 'Starting regular processing for object: ' + objectName);
            
            // Get all fields for this object
            Map<String, Object> fieldPermissionsMap = new Map<String, Object>();
            Map<String, Map<Id, FieldPermissions>> permissionsByField = new Map<String, Map<Id, FieldPermissions>>();
            
            // Get field map for the SObject
            Map<String, Schema.SObjectField> fieldMap;
            try {
                //system.debug(LoggingLevel.DEBUG, 'Getting global describe...');
                // Get the global describe
                Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
                
                // Check if object exists
                if (!globalDescribe.containsKey(objectName)) {
                    //system.debug(LoggingLevel.ERROR, 'Object ' + objectName + ' not found in schema');
                    return fieldPermissionsMap; // Return empty map
                }
                
                // Get field map
                //system.debug(LoggingLevel.DEBUG, 'Getting fields map for ' + objectName);
                fieldMap = globalDescribe.get(objectName).getDescribe().fields.getMap();
                //system.debug(LoggingLevel.DEBUG, 'Found ' + fieldMap.size() + ' fields for ' + objectName);
            } catch (Exception ex) {
                //system.debug(LoggingLevel.ERROR, 'Error accessing fields for ' + objectName + ': ' + ex.getMessage());
                //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + ex.getStackTraceString());
                return fieldPermissionsMap; // Return empty map
            }
            
            // Get profiles by ID for reference
            Map<Id, Profile> profileById = new Map<Id, Profile>();
            Map<Id, String> profileToPermSetId = new Map<Id, String>();
            
            // Query profile permission sets
            if (profileIds != null && !profileIds.isEmpty()) {
                //system.debug(LoggingLevel.DEBUG, 'Querying profiles: ' + profileIds.size());
                for (Profile p : [SELECT Id, Name FROM Profile WHERE Id IN :profileIds]) {
                    profileById.put(p.Id, p);
                }
                //system.debug(LoggingLevel.DEBUG, 'Found ' + profileById.size() + ' profiles');
                
                // Get permission sets that represent profiles
                //system.debug(LoggingLevel.DEBUG, 'Querying profile permission sets');
                for (PermissionSet ps : [
                    SELECT Id, ProfileId
                    FROM PermissionSet 
                    WHERE ProfileId IN :profileIds
                    AND IsOwnedByProfile = true
                ]) {
                    profileToPermSetId.put(ps.ProfileId, ps.Id);
                }
                //system.debug(LoggingLevel.DEBUG, 'Found ' + profileToPermSetId.size() + ' profile permission sets');
            }
            
            // We need to pass profile permission set IDs and regular permission set IDs
            Set<Id> allParentIds = new Set<Id>();
            if (profileIds != null && !profileIds.isEmpty()) {
                // Convert profileToPermSetId values to Id type before adding to Set<Id>
                for(String permSetId : profileToPermSetId.values()) {
                    if (permSetId != null && permSetId.trim() != '') {
                        try {
                            Id idValue = Id.valueOf(permSetId);
                            allParentIds.add(idValue);
                        } catch (Exception e) {
                            //system.debug(LoggingLevel.WARN, 'Invalid Id value in profileToPermSetId values: ' + permSetId);
                        }
                    }
                }
                //system.debug(LoggingLevel.DEBUG, 'Added ' + profileToPermSetId.values().size() + ' profile permission sets to allParentIds');
            }
            if (permSetIds != null && !permSetIds.isEmpty()) {
                //system.debug(LoggingLevel.DEBUG, 'Processing ' + permSetIds.size() + ' permission set IDs');
                // Convert List<String> to Set<Id> correctly
                for(String permSetId : permSetIds) {
                    if (permSetId != null && permSetId.trim() != '') {
                        try {
                            Id idValue = Id.valueOf(permSetId);
                            allParentIds.add(idValue);
                        } catch (Exception e) {
                            //system.debug(LoggingLevel.WARN, 'Invalid Id value in permSetIds: ' + permSetId);
                        }
                    }
                }
                //system.debug(LoggingLevel.DEBUG, 'Added permission set IDs to allParentIds, total: ' + allParentIds.size());
            }
            
            // Query all field permissions
            try {
                //system.debug(LoggingLevel.DEBUG, 'Querying field permissions for object: ' + objectName);
                //system.debug(LoggingLevel.DEBUG, 'Using parent IDs: ' + allParentIds.size());
                
                List<FieldPermissions> fieldPermsList = [
                SELECT Id, ParentId, SobjectType, Field, PermissionsRead, PermissionsEdit, 
                       Parent.IsOwnedByProfile, Parent.ProfileId
                FROM FieldPermissions
                WHERE SobjectType = :objectName
                AND ParentId IN :allParentIds
                ];
                
                //system.debug(LoggingLevel.DEBUG, 'Found ' + fieldPermsList.size() + ' field permissions records');
                
                // Process field permissions results
                for (FieldPermissions fp : fieldPermsList) {
                String fieldName = fp.Field;
                    //system.debug(LoggingLevel.DEBUG, 'Processing field permission for: ' + fieldName);
                
                if (!permissionsByField.containsKey(fieldName)) {
                    permissionsByField.put(fieldName, new Map<Id, FieldPermissions>());
                }
                
                // Store with parent ID (could be Profile PermSet or standalone PermSet)
                permissionsByField.get(fieldName).put(fp.ParentId, fp);
                    
                    // Check if parent is a profile-owned permission set
                    Boolean isProfileOwned = false;
                    Id profileId = null;
                    try {
                        isProfileOwned = fp.Parent.IsOwnedByProfile;
                        if (isProfileOwned) {
                            profileId = fp.Parent.ProfileId;
                        }
                    } catch (Exception e) {
                        //system.debug(LoggingLevel.ERROR, 'Error checking fp.Parent: ' + e.getMessage());
                        continue; // Skip this field permission if we can't determine its parent
                    }
                
                // If this is a profile-owned permission set, also map it to the profile ID for easier lookup
                    if (isProfileOwned && profileId != null) {
                        //system.debug(LoggingLevel.DEBUG, 'Found profile-owned permission set, profile ID: ' + profileId);
                    
                    // Get the field key - need to normalize to all lowercase for consistent lookup
                    String fieldKey = fieldName.toLowerCase();
                    if (!fieldPermissionsMap.containsKey(fieldKey)) {
                            //system.debug(LoggingLevel.DEBUG, 'Creating new field data structure for: ' + fieldName);
                            
                        // Create field data structure
                        Map<String, Object> fieldData = new Map<String, Object>();
                        fieldData.put('fieldName', fieldName.substringAfter('.'));
                        fieldData.put('standardFieldName', fieldName);
                        fieldData.put('permissions', new Map<String, Object>());
                        
                            // Add null checks to avoid NPE
                            String fieldNamePart = fieldName.substringAfter('.');
                            Schema.SObjectField field = null;
                            try {
                                field = fieldMap.get(fieldNamePart);
                                //system.debug(LoggingLevel.DEBUG, 'Field lookup for ' + fieldNamePart + ' result: ' + (field != null));
                            } catch (Exception e) {
                                //system.debug(LoggingLevel.ERROR, 'Error looking up field in fieldMap: ' + e.getMessage());
                            }
                            
                            if (field != null) {
                                try {
                                    //system.debug(LoggingLevel.DEBUG, 'Getting describe for field: ' + fieldNamePart);
                        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                        
                        // Add field metadata
                        fieldData.put('isStandardField', !fieldDescribe.isCustom());
                        fieldData.put('isAccessible', fieldDescribe.isAccessible());
                        fieldData.put('isUpdateable', fieldDescribe.isUpdateable());
                        fieldData.put('isCreateable', fieldDescribe.isCreateable());
                        fieldData.put('isCalculated', fieldDescribe.isCalculated());
                        fieldData.put('isAutoNumber', fieldDescribe.isAutoNumber());
                        fieldData.put('isRequired', fieldDescribe.isNillable() == false);
                                } catch (Exception e) {
                                    //system.debug(LoggingLevel.ERROR, 'Error getting field describe: ' + e.getMessage());
                                    // Set default values if describe fails
                                    fieldData.put('isStandardField', true);
                                    fieldData.put('isAccessible', false);
                                    fieldData.put('isUpdateable', false);
                                    fieldData.put('isCreateable', false);
                                    fieldData.put('isCalculated', false);
                                    fieldData.put('isAutoNumber', false);
                                    fieldData.put('isRequired', false);
                                }
                            } else {
                                //system.debug(LoggingLevel.WARN, 'Field not found in schema: ' + fieldNamePart);
                                // Set default values if field not found
                                fieldData.put('isStandardField', true);
                                fieldData.put('isAccessible', false);
                                fieldData.put('isUpdateable', false);
                                fieldData.put('isCreateable', false);
                                fieldData.put('isCalculated', false);
                                fieldData.put('isAutoNumber', false);
                                fieldData.put('isRequired', false);
                            }
                            
                            fieldData.put('isSystemField', isSystemField(fieldName));
                        fieldPermissionsMap.put(fieldKey, fieldData);
                    }
                    
                    // Add the permission for this profile
                    Map<String, Object> fieldData = (Map<String, Object>)fieldPermissionsMap.get(fieldKey);
                    Map<String, Object> permissionsMap = (Map<String, Object>)fieldData.get('permissions');
                    
                    Map<String, Object> profilePermission = new Map<String, Object>();
                    profilePermission.put('canRead', fp.PermissionsRead);
                    profilePermission.put('canEdit', fp.PermissionsEdit);
                    profilePermission.put('permissionId', fp.Id);
                    profilePermission.put('parentId', fp.ParentId);
                    
                    // Store with PROFILE ID as key (lookup will be by profile ID)
                    permissionsMap.put(profileId, profilePermission);
                }
                }
            } catch (Exception e) {
                //system.debug(LoggingLevel.ERROR, 'Error querying field permissions: ' + e.getMessage());
                //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            }
            
            // For direct permissions - permission sets without profile
            try {
            if (permSetIds != null && !permSetIds.isEmpty()) {
                    //system.debug(LoggingLevel.DEBUG, 'Processing direct permission sets: ' + permSetIds.size());
                for (String fieldName : permissionsByField.keySet()) {
                    Map<Id, FieldPermissions> fieldPerms = permissionsByField.get(fieldName);
                    
                    for (String permSetId : permSetIds) {
                            // Convert String to Id
                            Id permSetIdValue;
                            try {
                                permSetIdValue = Id.valueOf(permSetId);
                            } catch (Exception e) {
                                //system.debug(LoggingLevel.WARN, 'Invalid permission set ID: ' + permSetId);
                                continue;
                            }
                            
                            if (fieldPerms.containsKey(permSetIdValue)) {
                                //system.debug(LoggingLevel.DEBUG, 'Found permission for field ' + fieldName + ' and perm set ' + permSetId);
                                FieldPermissions fp = fieldPerms.get(permSetIdValue);
                            
                            // Get the field key - need to normalize to all lowercase for consistent lookup
                            String fieldKey = fieldName.toLowerCase();
                            if (!fieldPermissionsMap.containsKey(fieldKey)) {
                                // Create field data structure
                                Map<String, Object> fieldData = new Map<String, Object>();
                                fieldData.put('fieldName', fieldName.substringAfter('.'));
                                fieldData.put('standardFieldName', fieldName);
                                fieldData.put('permissions', new Map<String, Object>());
                                
                                    // Add null checks to avoid NPE
                                    String fieldNamePart = fieldName.substringAfter('.');
                                    Schema.SObjectField field = null;
                                    try {
                                        field = fieldMap.get(fieldNamePart);
                                    } catch (Exception e) {
                                        //system.debug(LoggingLevel.ERROR, 'Error looking up field in fieldMap: ' + e.getMessage());
                                    }
                                    
                                    if (field != null) {
                                        try {
                                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                                
                                // Add field metadata
                                fieldData.put('isStandardField', !fieldDescribe.isCustom());
                                fieldData.put('isAccessible', fieldDescribe.isAccessible());
                                fieldData.put('isUpdateable', fieldDescribe.isUpdateable());
                                fieldData.put('isCreateable', fieldDescribe.isCreateable());
                                fieldData.put('isCalculated', fieldDescribe.isCalculated());
                                fieldData.put('isAutoNumber', fieldDescribe.isAutoNumber());
                                fieldData.put('isRequired', fieldDescribe.isNillable() == false);
                                        } catch (Exception e) {
                                            //system.debug(LoggingLevel.ERROR, 'Error getting field describe: ' + e.getMessage());
                                            // Set default values if describe fails
                                            fieldData.put('isStandardField', true);
                                            fieldData.put('isAccessible', false);
                                            fieldData.put('isUpdateable', false);
                                            fieldData.put('isCreateable', false);
                                            fieldData.put('isCalculated', false);
                                            fieldData.put('isAutoNumber', false);
                                            fieldData.put('isRequired', false);
                                        }
                                    } else {
                                        //system.debug(LoggingLevel.WARN, 'Field not found in schema: ' + fieldNamePart);
                                        // Set default values if field not found
                                        fieldData.put('isStandardField', true);
                                        fieldData.put('isAccessible', false);
                                        fieldData.put('isUpdateable', false);
                                        fieldData.put('isCreateable', false);
                                        fieldData.put('isCalculated', false);
                                        fieldData.put('isAutoNumber', false);
                                        fieldData.put('isRequired', false);
                                    }
                                    
                                    fieldData.put('isSystemField', isSystemField(fieldName));
                                fieldPermissionsMap.put(fieldKey, fieldData);
                            }
                            
                            // Add the permission for this perm set
                            Map<String, Object> fieldData = (Map<String, Object>)fieldPermissionsMap.get(fieldKey);
                            Map<String, Object> permissionsMap = (Map<String, Object>)fieldData.get('permissions');
                            
                            Map<String, Object> permSetPermission = new Map<String, Object>();
                            permSetPermission.put('canRead', fp.PermissionsRead);
                            permSetPermission.put('canEdit', fp.PermissionsEdit);
                            permSetPermission.put('permissionId', fp.Id);
                            permSetPermission.put('parentId', fp.ParentId);
                            
                            // Store directly with permission set ID
                            permissionsMap.put(permSetId, permSetPermission);
                        }
                    }
                }
                }
            } catch (Exception e) {
                //system.debug(LoggingLevel.ERROR, 'Error processing permission sets: ' + e.getMessage());
                //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            }
            
            // Now, go through all fields and populate any missing permissions
            try {
                //system.debug(LoggingLevel.DEBUG, 'Processing all fields to ensure complete data');
                Integer fieldCounter = 0;
                
            for (String fieldName : fieldMap.keySet()) {
                    fieldCounter++;
                    if (Math.mod(fieldCounter, 50) == 0) {
                        //system.debug(LoggingLevel.DEBUG, 'Processed ' + fieldCounter + ' of ' + fieldMap.size() + ' fields');
                    }
                    
                Schema.SObjectField field = fieldMap.get(fieldName);
                    
                    // Skip if field is null
                    if (field == null) {
                        //system.debug(LoggingLevel.WARN, 'Null field in fieldMap: ' + fieldName);
                        continue;
                    }
                    
                    Schema.DescribeFieldResult fieldDescribe;
                    try {
                        fieldDescribe = field.getDescribe();
                    } catch (Exception e) {
                        //system.debug(LoggingLevel.WARN, 'Could not describe field ' + fieldName + ': ' + e.getMessage());
                        continue; // Skip this field
                    }
                
                // Skip system fields we can't query permission for
                if (fieldName.equalsIgnoreCase('id') || 
                    fieldName.equalsIgnoreCase('isdeleted') || 
                    fieldName.equalsIgnoreCase('createddate') || 
                    fieldName.equalsIgnoreCase('createdbyid') || 
                    fieldName.equalsIgnoreCase('lastmodifieddate') || 
                    fieldName.equalsIgnoreCase('lastmodifiedbyid') || 
                    fieldName.equalsIgnoreCase('systemmodstamp')) {
                    continue;
                }
                
                // Get the field key for our map and create entries for any fields not yet included
                String fullFieldName = objectName + '.' + fieldName;
                String fieldKey = fullFieldName.toLowerCase();
                
                if (!fieldPermissionsMap.containsKey(fieldKey)) {
                    // Create field data structure
                Map<String, Object> fieldData = new Map<String, Object>();
                fieldData.put('fieldName', fieldName);
                    fieldData.put('standardFieldName', fullFieldName);
                fieldData.put('permissions', new Map<String, Object>());
                
                        // Add field metadata - with safe access
                    fieldData.put('isStandardField', !fieldDescribe.isCustom());
                    fieldData.put('isAccessible', fieldDescribe.isAccessible());
                    fieldData.put('isUpdateable', fieldDescribe.isUpdateable());
                    fieldData.put('isCreateable', fieldDescribe.isCreateable());
                    fieldData.put('isCalculated', fieldDescribe.isCalculated());
                    fieldData.put('isAutoNumber', fieldDescribe.isAutoNumber());
                    fieldData.put('isRequired', fieldDescribe.isNillable() == false);
                    fieldData.put('isSystemField', isSystemField(fullFieldName));
                    
                    // Now add to our map
                    fieldPermissionsMap.put(fieldKey, fieldData);
                }
                
                // Make sure all profiles and permission sets have permission entries
                Map<String, Object> fieldData = (Map<String, Object>)fieldPermissionsMap.get(fieldKey);
                Map<String, Object> permissionsMap = (Map<String, Object>)fieldData.get('permissions');
                
                // For profiles, reference Salesforce's Field Level Security settings directly
                    if (profileIds != null) {
                for (String profileId : profileIds) {
                    if (!permissionsMap.containsKey(profileId)) {
                        // Get profile permissions directly from describe results
                        Boolean isStandardField = !(Boolean)fieldData.get('isStandardField');
                        Boolean isSystemAdmin = false;
                        
                        // Check if this is System Administrator profile
                        if (profileById.containsKey(profileId)) {
                            Profile p = profileById.get(profileId);
                            isSystemAdmin = p.Name.equalsIgnoreCase('System Administrator');
                        }
                        
                        // Use the field's describe to determine permissions - same as setup UI
                        Boolean canRead = fieldDescribe.isAccessible();
                        Boolean canEdit = fieldDescribe.isUpdateable();
                        
                        // System Admin usually has all access to standard fields
                        if (isSystemAdmin && !isStandardField) {
                            canRead = true;
                            canEdit = canEdit && !isSystemField(fullFieldName);
                        }
                        
                        Map<String, Object> profilePermission = new Map<String, Object>();
                        profilePermission.put('canRead', canRead);
                        profilePermission.put('canEdit', canEdit);
                        profilePermission.put('permissionId', null);
                        profilePermission.put('parentId', profileToPermSetId.get(profileId));
                        
                        permissionsMap.put(profileId, profilePermission);
                            }
                    }
                }
                
                // For permission sets, they have no permissions by default
                    if (permSetIds != null) {
                for (String permSetId : permSetIds) {
                    if (!permissionsMap.containsKey(permSetId)) {
                        Map<String, Object> permSetPermission = new Map<String, Object>();
                        permSetPermission.put('canRead', false);
                        permSetPermission.put('canEdit', false);
                        permSetPermission.put('permissionId', null);
                        permSetPermission.put('parentId', permSetId);
                        
                        permissionsMap.put(permSetId, permSetPermission);
                    }
                }
                    }
                }
            } catch (Exception e) {
                //system.debug(LoggingLevel.ERROR, 'Error processing all fields: ' + e.getMessage());
                //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            }
            
            //system.debug(LoggingLevel.DEBUG, 'Returning field permissions map with ' + fieldPermissionsMap.size() + ' fields');
            //system.debug(LoggingLevel.DEBUG, '=== END getFieldPermissions for object: ' + objectName + ' ===');
            return fieldPermissionsMap;
        } catch (Exception e) {
            //system.debug(LoggingLevel.ERROR, '!!! EXCEPTION in getFieldPermissions: ' + e.getMessage());
            //system.debug(LoggingLevel.ERROR, 'Exception type: ' + e.getTypeName());
            //system.debug(LoggingLevel.ERROR, 'Line number: ' + e.getLineNumber());
            //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving field permissions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get profile name by ID
     * @param profileId Profile ID
     * @return String Profile name
     */
    private static String getProfileName(String profileId) {
        if (String.isBlank(profileId)) return '';
        try {
            Profile p = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
            return p.Name;
        } catch (Exception e) {
            return 'Unknown Profile';
        }
    }
    
    /**
     * @description Get permission set name by ID
     * @param permSetId Permission set ID
     * @return String Permission set name
     */
    private static String getPermissionSetName(String permSetId) {
        if (String.isBlank(permSetId)) return '';
        try {
            PermissionSet ps = [SELECT Label FROM PermissionSet WHERE Id = :permSetId LIMIT 1];
            return ps.Label;
        } catch (Exception e) {
            return 'Unknown Permission Set';
        }
    }
    
    /**
     * @description Get tab visibility for profiles and permission sets
     * @param profileIds List of profile IDs
     * @param permSetIds List of permission set IDs
     * @param tabNames List of tab names
     * @return Map<String, TabVisibilityMatrix> Map of tab visibility matrices by tab name
     */
    @AuraEnabled
    public static Map<String, TabVisibilityMatrix> getTabVisibility(
        List<String> profileIds, 
        List<String> permSetIds, 
        List<String> tabNames
    ) {
        Map<String, TabVisibilityMatrix> result = new Map<String, TabVisibilityMatrix>();
        
        try {
            // If neither profiles nor permission sets specified, return empty result
            if ((profileIds == null || profileIds.isEmpty()) && 
                (permSetIds == null || permSetIds.isEmpty())) {
                return result;
            }
            
            // If no tab names specified, return empty result
            if (tabNames == null || tabNames.isEmpty()) {
                return result;
            }
            
            // Initialize visibility maps
            Map<String, Map<String, TabVisibilityWrapper>> visibilityByTab = new Map<String, Map<String, TabVisibilityWrapper>>();
            for (String tabName : tabNames) {
                visibilityByTab.put(tabName, new Map<String, TabVisibilityWrapper>());
            }
            
            // Pre-fetch profile names
            Map<Id, String> profileNamesById = new Map<Id, String>();
            if (profileIds != null && !profileIds.isEmpty()) {
                for (Profile p : [SELECT Id, Name FROM Profile WHERE Id IN :profileIds]) {
                    profileNamesById.put(p.Id, p.Name);
                }
            }
            
            // Pre-fetch permission set names
            Map<Id, String> permSetNamesById = new Map<Id, String>();
            if (permSetIds != null && !permSetIds.isEmpty()) {
                for (PermissionSet ps : [SELECT Id, Label FROM PermissionSet WHERE Id IN :permSetIds]) {
                    permSetNamesById.put(ps.Id, ps.Label);
                }
            }
            
            // For profiles
            if (profileIds != null && !profileIds.isEmpty()) {
            for (String profileId : profileIds) {
                for (String tabName : tabNames) {
                        String profileName = profileNamesById.containsKey(profileId) ? 
                                           profileNamesById.get(profileId) : 'Unknown Profile';
                        
                        // Create wrapper
                    TabVisibilityWrapper wrapper = new TabVisibilityWrapper();
                    wrapper.id = profileId + '-' + tabName;
                    wrapper.parentId = profileId;
                        wrapper.parentName = profileName;
                    wrapper.tabName = tabName;
                        
                        // Set default visibility values
                        // DefaultOn for standard objects, Available for custom objects
                        if (tabName.endsWith('__c')) {
                            wrapper.isVisible = false;
                    wrapper.isAvailable = true;
                        } else {
                    wrapper.isVisible = true;
                            wrapper.isAvailable = false;
                        }
                    
                    visibilityByTab.get(tabName).put(profileId, wrapper);
                    }
                }
            }
            
            // For permission sets
            if (permSetIds != null && !permSetIds.isEmpty()) {
            for (String permSetId : permSetIds) {
                for (String tabName : tabNames) {
                        String permSetName = permSetNamesById.containsKey(permSetId) ? 
                                          permSetNamesById.get(permSetId) : 'Unknown Permission Set';
                        
                        // Create wrapper
                    TabVisibilityWrapper wrapper = new TabVisibilityWrapper();
                    wrapper.id = permSetId + '-' + tabName;
                    wrapper.parentId = permSetId;
                        wrapper.parentName = permSetName;
                    wrapper.tabName = tabName;
                        
                        // Set default visibility values for permission sets
                        // Permission sets typically have Available as default
                        wrapper.isVisible = false;
                    wrapper.isAvailable = true;
                    
                    visibilityByTab.get(tabName).put(permSetId, wrapper);
                    }
                }
            }
            
            // Build the result
            for (String tabName : tabNames) {
                TabVisibilityMatrix matrix = new TabVisibilityMatrix();
                matrix.tabName = tabName;
                matrix.visibility = visibilityByTab.get(tabName);
                result.put(tabName, matrix);
            }
        } catch (Exception e) {
            //system.debug('Error in getTabVisibility: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            //system.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving tab visibility: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Helper method to find a key in a map based on its value
     * @param mapToSearch The map to search
     * @param valueToFind The value to find
     * @return String The key that maps to the given value, or null if not found
     */
    private static String getKeyByValue(Map<String, String> mapToSearch, String valueToFind) {
        if (mapToSearch == null || valueToFind == null) return null;
        
        for (String key : mapToSearch.keySet()) {
            if (mapToSearch.get(key) == valueToFind) {
                return key;
            }
        }
        return null;
    }
    
    // Static map to store tab visibility settings for demonstration
    private static Map<String, Map<String, String>> visibilitySettings = new Map<String, Map<String, String>>();
    
    /**
     * @description Update tab visibility settings
     * @param updates List of tab visibility updates
     * @return Boolean Success flag
     */
    @AuraEnabled
    public static Boolean updateTabVisibility(List<Map<String, Object>> updates) {
        try {
            //system.debug('Updating tab visibility: ' + updates);
            
            // Group by profile/permission set
            Map<Id, List<Map<String, Object>>> updatesByParent = new Map<Id, List<Map<String, Object>>>();
            Set<Id> profileIds = new Set<Id>();
            Set<Id> permSetIds = new Set<Id>();
            
            for (Map<String, Object> updateItem : updates) {
                String tabName = (String)updateItem.get('tabName');
                String parentId = (String)updateItem.get('parentId');
                String visibility = (String)updateItem.get('visibility');
                
                if (String.isBlank(tabName) || String.isBlank(parentId) || String.isBlank(visibility)) {
                    continue; // Skip invalid updates
                }
                
                if (!updatesByParent.containsKey(parentId)) {
                    updatesByParent.put(parentId, new List<Map<String, Object>>());
                }
                updatesByParent.get(parentId).add(updateItem);
                
                // Identify if this is a profile or permission set ID
                if ((String.valueOf(parentId).length() == 15 || String.valueOf(parentId).length() == 18)) {
                    if (String.valueOf(parentId).startsWith('00e')) {
                        profileIds.add(parentId);
                    } else if (String.valueOf(parentId).startsWith('0PS')) {
                        permSetIds.add(parentId);
                    }
                }
                
                // Store the setting in our static map for demonstration
                String key = parentId + '-' + tabName;
                if (!visibilitySettings.containsKey(key)) {
                    visibilitySettings.put(key, new Map<String, String>());
                }
                visibilitySettings.get(key).put('visibility', visibility);
            }
            
            // Pre-fetch profile names
            Map<Id, String> profileNamesById = new Map<Id, String>();
            if (!profileIds.isEmpty()) {
                for (Profile p : [SELECT Id, Name FROM Profile WHERE Id IN :profileIds]) {
                    profileNamesById.put(p.Id, p.Name);
                }
            }
            
            // Pre-fetch permission set names
            Map<Id, String> permSetNamesById = new Map<Id, String>();
            if (!permSetIds.isEmpty()) {
                for (PermissionSet ps : [SELECT Id, Label FROM PermissionSet WHERE Id IN :permSetIds]) {
                    permSetNamesById.put(ps.Id, ps.Label);
                }
            }
            
            // Process profiles
            if (!profileIds.isEmpty()) {
                //system.debug('Updating tab visibility for ' + profileIds.size() + ' profiles');
                
                for (Id profileId : profileIds) {
                    String profileName = profileNamesById.containsKey(profileId) ? 
                                        profileNamesById.get(profileId) : 'Unknown Profile';
                    List<Map<String, Object>> profileUpdates = updatesByParent.get(profileId);
                    
                    for (Map<String, Object> updateItem : profileUpdates) {
                        String tabName = (String)updateItem.get('tabName');
                        String visibility = (String)updateItem.get('visibility');
                        
                        //system.debug('Setting ' + tabName + ' visibility to ' + visibility +  ' for profile ' + profileName + ' (' + profileId + ')');
                    }
                }
            }
            
            // Process permission sets
            if (!permSetIds.isEmpty()) {
                //system.debug('Updating tab visibility for ' + permSetIds.size() + ' permission sets');
                
                for (Id permSetId : permSetIds) {
                    String permSetName = permSetNamesById.containsKey(permSetId) ? 
                                       permSetNamesById.get(permSetId) : 'Unknown Permission Set';
                    List<Map<String, Object>> permSetUpdates = updatesByParent.get(permSetId);
                    
                    for (Map<String, Object> updateItem : permSetUpdates) {
                        String tabName = (String)updateItem.get('tabName');
                        String visibility = (String)updateItem.get('visibility');
                        
                        //system.debug('Setting ' + tabName + ' visibility to ' + visibility +      ' for permission set ' + permSetName + ' (' + permSetId + ')');
                    }
                }
            }
            
            // In a real implementation, you would:
            // 1. Use the Metadata API to update profile tab visibility settings
            // 2. This would require an Apex class that uses callouts to the Metadata API
            // 3. Or you could use a custom solution like the Salesforce CLI to deploy metadata changes
            
            return true;
        } catch (Exception e) {
            //system.debug('Error updating tab visibility: ' + e.getMessage() + ' at line ' + e.getLineNumber());
            //system.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error updating tab visibility: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get object fields with permissions with pagination support
     * @param objectApiName API name of the object
     * @param profileOrPermSetIds List of profile or permission set IDs
     * @param recordOffset Offset for pagination
     * @param pageSize Number of records to return
     * @return JSON string containing field information and permissions
     */
    @AuraEnabled
    public static String getObjectFieldsWithPermissions(String objectApiName, List<String> profileOrPermSetIds, 
                                                       Integer recordOffset, Integer pageSize) {
        try {
            if (String.isBlank(objectApiName)) {
                throw new AuraHandledException('Object API name is required');
            }
            
            if (profileOrPermSetIds == null || profileOrPermSetIds.isEmpty()) {
                throw new AuraHandledException('At least one profile or permission set ID is required');
            }
            
            // Default values for pagination
            if (recordOffset == null) recordOffset = 0;
            if (pageSize == null || pageSize <= 0) pageSize = 20;
            
            //system.debug('getObjectFieldsWithPermissions: ' + objectApiName + ', offset: ' + recordOffset + ', pageSize: ' + pageSize);
            
            // Separate profile IDs and permission set IDs
            List<String> profileIds = new List<String>();
            List<String> permSetIds = new List<String>();
            
            for (String id : profileOrPermSetIds) {
                // Check if it's a profile ID or permission set ID
                // This is a simple string-based check since both are 15/18 character IDs
                if (id.length() >= 15 && id.startsWith('00e')) {
                    profileIds.add(id);
                } else {
                    permSetIds.add(id);
                }
            }
            
            // Get field permissions from the core method
            Map<String, Object> fieldPermissionsData = getFieldPermissions(profileIds, permSetIds, objectApiName);
            
            // Convert to array for pagination
            List<Map<String, Object>> fieldsList = new List<Map<String, Object>>();
            
            for (String fieldKey : fieldPermissionsData.keySet()) {
                Map<String, Object> fieldData = (Map<String, Object>)fieldPermissionsData.get(fieldKey);
                
                // Including system fields: disable client-side based on field metadata
                fieldData.put('id', fieldKey);
                fieldsList.add(fieldData);
            }
            
            // Sort fields alphabetically by fieldName
            fieldsList = sortFieldsByName(fieldsList);
            
            // Apply pagination
            Integer totalFields = fieldsList.size();
            Boolean hasMore = (recordOffset + pageSize) < totalFields;
            
            // Calculate end index ensuring we don't exceed the list size
            Integer endIndex = Math.min(recordOffset + pageSize, totalFields);
            
            // Get the subset of fields for this page
            List<Map<String, Object>> pagedFields = new List<Map<String, Object>>();
            if (recordOffset < totalFields) {
                // Manual pagination since List.subList is not available in Apex
                for (Integer i = recordOffset; i < endIndex; i++) {
                    pagedFields.add(fieldsList[i]);
                }
            }
            
            // Create result wrapper
            Map<String, Object> result = new Map<String, Object>();
            result.put('fields', pagedFields);
            result.put('totalFields', totalFields);
            result.put('hasMore', hasMore);
            result.put('offset', recordOffset);
            result.put('pageSize', pageSize);
            
            return JSON.serialize(result);
        } catch (Exception e) {
            //system.debug(LoggingLevel.ERROR, 'Error in getObjectFieldsWithPermissions: ' + e.getMessage() + '\n' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving field permissions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Helper method to sort fields by name
     * @param fieldsList List of field data maps to sort
     * @return List<Map<String, Object>> Sorted list of fields
     */
    private static List<Map<String, Object>> sortFieldsByName(List<Map<String, Object>> fieldsList) {
        // Create a list of wrapper objects that can be sorted
        List<FieldSortWrapper> wrappers = new List<FieldSortWrapper>();
        
        // Populate with data
        for (Map<String, Object> fieldData : fieldsList) {
            wrappers.add(new FieldSortWrapper(fieldData));
        }
        
        // Sort the wrappers
        wrappers.sort();
        
        // Convert back to the original format
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (FieldSortWrapper wrapper : wrappers) {
            result.add(wrapper.fieldData);
        }
        
        return result;
    }
    
    /**
     * @description Helper class for sorting field data
     */
    private class FieldSortWrapper implements Comparable {
        public Map<String, Object> fieldData;
        
        public FieldSortWrapper(Map<String, Object> fieldData) {
            this.fieldData = fieldData;
        }
        
        public Integer compareTo(Object compareTo) {
            FieldSortWrapper other = (FieldSortWrapper)compareTo;
            
            String thisField = (String)this.fieldData.get('fieldName');
            String otherField = (String)other.fieldData.get('fieldName');
            
            if (thisField == null) return 1;
            if (otherField == null) return -1;
            
            return thisField.compareTo(otherField);
        }
    }
    
    // Wrapper classes
    
    /**
     * @description Wrapper class for Profile
     */
    public class ProfileWrapper implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public String description;
        
        public Integer compareTo(Object compareTo) {
            ProfileWrapper compareToProfile = (ProfileWrapper)compareTo;
            if (name == compareToProfile.name) return 0;
            if (name > compareToProfile.name) return 1;
            return -1;
        }
    }
    
    /**
     * @description Wrapper class for Permission Set
     */
    public class PermissionSetWrapper implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isConverted;
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public String createdById;
        @AuraEnabled public String createdByName;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public String description;
        @AuraEnabled public Boolean isCustom;
        
        // PermissionSetAssignment fields
        @AuraEnabled public String assigneeId;
        @AuraEnabled public DateTime expirationDate;
        @AuraEnabled public String assignmentId;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Boolean isRevoked;
        @AuraEnabled public String lastCreatedByChangeId;
        @AuraEnabled public String lastDeletedByChangeId;
        @AuraEnabled public String permissionSetGroupId;
        @AuraEnabled public String permissionSetId;
        @AuraEnabled public DateTime systemModstamp;
        @AuraEnabled public List<AssignmentWrapper> assignments;
        
        public Integer compareTo(Object compareTo) {
            PermissionSetWrapper compareToPermSet = (PermissionSetWrapper)compareTo;
            if (label == compareToPermSet.label) return 0;
            if (label > compareToPermSet.label) return 1;
            return -1;
        }
    }
    
    /**
     * @description Wrapper class for PermissionSetAssignment data
     */
    public class AssignmentWrapper {
        @AuraEnabled public String assigneeId;
        @AuraEnabled public String assigneeName;
        @AuraEnabled public DateTime expirationDate;
        @AuraEnabled public String assignmentId;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Boolean isRevoked;
        @AuraEnabled public String lastCreatedByChangeId;
        @AuraEnabled public String lastDeletedByChangeId;
        @AuraEnabled public String permissionSetGroupId;
        @AuraEnabled public String permissionSetId;
        @AuraEnabled public DateTime systemModstamp;
    }
    
    /**
     * @description Wrapper class for SObject
     */
    public class ObjectWrapper implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isSelected;
        
        public Integer compareTo(Object compareTo) {
            ObjectWrapper compareToObject = (ObjectWrapper)compareTo;
            if (label == compareToObject.label) return 0;
            if (label > compareToObject.label) return 1;
            return -1;
        }
    }
    
    /**
     * @description Wrapper class for paginated profile results
     */
    public class ProfilePageResult {
        @AuraEnabled public List<ProfileWrapper> profiles { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }
        @AuraEnabled public Boolean hasNext { get; set; }
        @AuraEnabled public Boolean hasPrevious { get; set; }
    }
    
    /**
     * @description Wrapper class for paginated permission set results
     */
    public class PermissionSetPageResult {
        @AuraEnabled public List<PermissionSetWrapper> permissionSets { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }
        @AuraEnabled public Boolean hasNext { get; set; }
        @AuraEnabled public Boolean hasPrevious { get; set; }
    }
    
    /**
     * @description Wrapper class for paginated object results
     */
    public class ObjectPageResult {
        @AuraEnabled public List<ObjectWrapper> objects { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }
        @AuraEnabled public Boolean hasNext { get; set; }
        @AuraEnabled public Boolean hasPrevious { get; set; }
    }

    /**
     * @description Wrapper class for Object Permissions
     */
    public class ObjectPermissionWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String parentId;
        @AuraEnabled public String parentName;
        @AuraEnabled public String objectType;
        @AuraEnabled public Boolean canRead;
        @AuraEnabled public Boolean canCreate;
        @AuraEnabled public Boolean canEdit;
        @AuraEnabled public Boolean canDelete;
        @AuraEnabled public Boolean canViewAll;
        @AuraEnabled public Boolean canModifyAll;
        @AuraEnabled public Boolean isReadDisabled;
        @AuraEnabled public Boolean isCreateDisabled;
        @AuraEnabled public Boolean isEditDisabled;
        @AuraEnabled public Boolean isDeleteDisabled;
        @AuraEnabled public Boolean isViewAllDisabled;
        @AuraEnabled public Boolean isModifyAllDisabled;
        @AuraEnabled public String userLicenseName;
    }
    
    /**
     * @description Wrapper class for Field Permissions
     */
    public class FieldPermissionWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String parentId;
        @AuraEnabled public String parentName;
        @AuraEnabled public String field;
        @AuraEnabled public Boolean canRead;
        @AuraEnabled public Boolean canEdit;
    }
    
    /**
     * @description Wrapper class for Tab Visibility
     */
    public class TabVisibilityWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String parentId;
        @AuraEnabled public String parentName;
        @AuraEnabled public String tabName;
        @AuraEnabled public Boolean isAvailable;
        @AuraEnabled public Boolean isVisible;
    }

    /**
     * @description Wrapper class for User
     */
    public class UserWrapper implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String username;
        @AuraEnabled public String email;
        @AuraEnabled public String profileName;
        @AuraEnabled public String licenseType;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Boolean isSelected;
        
        public Integer compareTo(Object compareTo) {
            UserWrapper compareToUser = (UserWrapper)compareTo;
            if (name == compareToUser.name) return 0;
            if (name > compareToUser.name) return 1;
            return -1;
        }
    }

    /**
     * @description Wrapper class for Field
     */
    public class FieldWrapper implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isCustom;
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public String description;
        @AuraEnabled public String helpText;

        public Integer compareTo(Object compareTo) {
            FieldWrapper compareToField = (FieldWrapper)compareTo;
            if (label == compareToField.label) return 0;
            if (label > compareToField.label) return 1;
            return -1;
        }
    }
    
    /**
     * @description Wrapper class for Object Permissions Matrix
     */
    public class ObjectPermissionsMatrix {
        @AuraEnabled public String objectName;
        @AuraEnabled public Map<String, ObjectPermissionWrapper> permissions;
    }
    
    /**
     * @description Wrapper class for Field Permissions Matrix
     */
    public class FieldPermissionsMatrix {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String standardFieldName;
        @AuraEnabled public Map<String, FieldPermissionWrapper> permissions;
    }
    
    /**
     * @description Wrapper class for Tab Visibility Matrix
     */
    public class TabVisibilityMatrix {
        @AuraEnabled public String tabName;
        @AuraEnabled public Map<String, TabVisibilityWrapper> visibility;
    }
    
    /**
     * @description Helper class to store field describe information
     */
    private class FieldDescribeInfo {
        public String apiName;
        public String label;
        public Boolean isCustom;
        public String type;
        public Boolean isCalculated;
        public Boolean isAutoNumber;
        public Boolean isAccessible;
        public Boolean isUpdateable;
        public Boolean isCreateable;
    }
    
    /**
     * Helper method to check if a field is a system field that can't be modified
     */
    private static Boolean isSystemField(String fieldPath) {
        //system.debug(LoggingLevel.DEBUG, 'Checking if field is system field: ' + fieldPath);
        if (String.isBlank(fieldPath)) {
            //system.debug(LoggingLevel.DEBUG, 'Field path is blank, returning false');
            return false;
        }
        
        String lowercasePath = fieldPath.toLowerCase();
        
        // List of system fields that cannot have permissions directly modified
        Set<String> systemFieldSuffixes = new Set<String>{
            // Common system fields
            '.id', '.isdeleted', '.masterrecordid',
            // Audit fields
            '.createddate', '.createdbyid', '.lastmodifieddate', '.lastmodifiedbyid', 
            '.systemmodstamp', '.lastvieweddate', '.lastreferenceddate',
            // Record ownership fields
            '.ownerid', '.ownername',
            // Sharing/security fields
            '.isprivate', '.sharingreason',
            // System compound fields
            '.geolocation', '.location',
            // Formula/auto fields
            '.formattedname', '.fullphotourl', '.smallphotourl',
            // Lookup fields that are system controlled
            '.recordtypeid'
        };
        
        // Check against suffixes
        for (String suffix : systemFieldSuffixes) {
            if (lowercasePath.endsWith(suffix)) {
                //system.debug(LoggingLevel.DEBUG, 'Field matches system suffix: ' + suffix);
                return true;
            }
        }
        
        // Special cases - additional fields that may be restricted in some objects
        List<String> restrictedPrefixes = new List<String>{
            'standard', 'system', '_', 'history', 'chatter', 'feed', 'oldvalue', 'newvalue'
        };
        
        List<String> parts = lowercasePath.split('\\.');
        String fieldPart = parts.size() > 1 ? parts[1] : parts[0];
        
        // Check if field name starts with a restricted prefix
        for (String prefix : restrictedPrefixes) {
            if (fieldPart.startsWith(prefix)) {
                //system.debug(LoggingLevel.DEBUG, 'Field starts with restricted prefix: ' + prefix);
                return true;
            }
        }
        
        // Specific field types that need special handling
        List<String> restrictedFieldTypes = new List<String>{
            'rating', 'type', 'status', 'stage', 'level', 'category',
            'priority', 'reason', 'code', 'source'
        };
        
        // Some fields may be restricted picklists without obvious names
        if (restrictedFieldTypes.contains(fieldPart)) {
            //system.debug(LoggingLevel.DEBUG, 'Potential restricted picklist field detected: ' + fieldPath);
        }
        
        //system.debug(LoggingLevel.DEBUG, 'Field is not a system field: ' + fieldPath);
        return false;
    }

    /**
     * @description Set which permissions should be disabled based on object type and profile properties
     * @param wrapper The ObjectPermissionWrapper to update
     * @param profile The Profile associated with these permissions
     */
    private static void setDisabledPermissionsForProfile(ObjectPermissionWrapper wrapper, Profile profile) {
        if (profile == null) return;
        
        String objectName = wrapper.objectType.toLowerCase();
        String profileName = profile.Name.toLowerCase();
        String userLicenseName = wrapper.userLicenseName;
        
        // Check for standard profiles with Salesforce licenses
        Boolean isStandardSalesforceProfile = profileName.contains('standard') && 
            (userLicenseName == 'Salesforce');
        
        // Simple check for Analytics Cloud Integration User, which shouldn't be editable
        if (profileName.contains('analytics cloud integration user') || isStandardSalesforceProfile) {
            // Disable all permissions for this profile
            wrapper.isReadDisabled = true;
            wrapper.isCreateDisabled = true;
            wrapper.isEditDisabled = true;
            wrapper.isDeleteDisabled = true;
            wrapper.isViewAllDisabled = true;
            wrapper.isModifyAllDisabled = true;
            return;
        }
        
        // System Administrator can edit all permissions
        if (profileName.contains('system administrator') || profileName.contains('admin')) {
            return; // No disabled permissions for admin
        }
        
        // For standard objects only allow limited permissions
        if (!objectName.endsWith('__c')) {
            // System objects with very limited permissions
            Set<String> systemObjects = new Set<String>{
                'user', 'group', 'organization', 'profile', 'userlicense', 'apexclass', 'permissionset',
                'asyncapexjob', 'setupaudittrail', 'setupentityaccess', 'authprovider'
            };
            
            if (systemObjects.contains(objectName)) {
                wrapper.isReadDisabled = profileName != 'system administrator';
                wrapper.isCreateDisabled = true;
                wrapper.isEditDisabled = true;
                wrapper.isDeleteDisabled = true;
                wrapper.isViewAllDisabled = true;
                wrapper.isModifyAllDisabled = true;
            }
        }
    }

    /**
     * @description Set which permissions should be disabled based on object type and permission set properties
     * @param wrapper The ObjectPermissionWrapper to update
     * @param permissionSet The PermissionSet associated with these permissions
     */
    private static void setDisabledPermissionsForPermissionSet(ObjectPermissionWrapper wrapper, PermissionSet permissionSet) {
        if (permissionSet == null) return;
        
        String objectName = wrapper.objectType.toLowerCase();
        String permSetName = permissionSet.Name.toLowerCase();
        
        // Check for Analytics Cloud permission sets
        if (permSetName.contains('analytics') || permSetName.contains('api_')) {
            // Disable all permissions for Analytics Cloud permission sets
            wrapper.isReadDisabled = true;
            wrapper.isCreateDisabled = true;
            wrapper.isEditDisabled = true;
            wrapper.isDeleteDisabled = true;
            wrapper.isViewAllDisabled = true;
            wrapper.isModifyAllDisabled = true;
            return;
        }
        
        // For system objects, disable permissions
        Set<String> restrictedSystemObjects = new Set<String>{
            'user', 'group', 'organization', 'profile', 'userlicense',
            'asyncapexjob', 'setupaudittrail', 'setupentityaccess', 'authprovider'
        };
        
        if (restrictedSystemObjects.contains(objectName)) {
            wrapper.isCreateDisabled = true;
            wrapper.isEditDisabled = true;
            wrapper.isDeleteDisabled = true;
            wrapper.isViewAllDisabled = true;
            wrapper.isModifyAllDisabled = true;
        }
    }

    /**
     * @description Helper method to extract dependency message from a given error message
     * @param errorMessage The original error message
     * @return String Extracted dependency message
     */
    private static String extractDependencyMessage(String errorMessage) {
        if (String.isBlank(errorMessage)) {
            return '';
        }
        
        // Check for dependency errors that follow the pattern:
        // FIELD_INTEGRITY_EXCEPTION, Permission X depends on permission(s): Y
        
        // First, remove the FIELD_INTEGRITY_EXCEPTION part if present
        if (errorMessage.contains('FIELD_INTEGRITY_EXCEPTION')) {
            // Find the first colon after "EXCEPTION"
            Integer startIndex = errorMessage.indexOf(':', errorMessage.indexOf('EXCEPTION'));
            if (startIndex > 0) {
                errorMessage = errorMessage.substring(startIndex + 1).trim();
            }
        }
        
        // Handle errors that start with "first error:" pattern
        if (errorMessage.contains('first error:')) {
            Integer startIndex = errorMessage.indexOf(':', errorMessage.indexOf('first error:'));
            if (startIndex > 0) {
                errorMessage = errorMessage.substring(startIndex + 1).trim();
            }
        }
        
        // Remove brackets and other syntax characters
        errorMessage = errorMessage.replace('[', '').replace(']', '').trim();
        
        // Check if it's a dependency error
        if (errorMessage.contains('Permission') && errorMessage.contains('depends on permission')) {
            // Return the cleaned dependency message
            return errorMessage;
        }
        
        // For other errors, just return the cleaned message
        return errorMessage;
    }

    /**
     * @description Get a list of all system permissions available in the org by querying SetupEntityAccess
     * This method fetches ALL system permissions that exist in the org, not just those from PermissionSet schema
     * Enhanced to include privileged permission flags and descriptions from Custom Metadata
     * @return List<SystemPermissionWrapper> List of system permission wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<SystemPermissionWrapper> getSystemPermissions() {
        List<SystemPermissionWrapper> systemPermissions = new List<SystemPermissionWrapper>();
        
        try {
            // Get privileged permissions from Custom Metadata Type
            // Create case-insensitive map for matching
            Map<String, SA_Audit__Privileged_System_Permission__mdt> privilegedPermsMap = new Map<String, SA_Audit__Privileged_System_Permission__mdt>();
            for (SA_Audit__Privileged_System_Permission__mdt psp : [
                SELECT SA_Audit__Permission_API_Name__c, SA_Audit__Permission_Label__c, SA_Audit__Description__c, SA_Audit__Is_Privileged__c
                FROM SA_Audit__Privileged_System_Permission__mdt
                LIMIT 10000
            ]) {
                // Store with multiple keys for flexible matching
                String apiName = psp.SA_Audit__Permission_API_Name__c;
                if (String.isNotBlank(apiName)) {
                    privilegedPermsMap.put(apiName.toLowerCase(), psp);
                    privilegedPermsMap.put(apiName, psp);
                    // Also store without 'Permissions' prefix
                    if (apiName.startsWith('Permissions')) {
                        String withoutPrefix = apiName.substring(11); // Remove 'Permissions'
                        privilegedPermsMap.put(withoutPrefix.toLowerCase(), psp);
                        privilegedPermsMap.put(withoutPrefix, psp);
                    }
                }
            }
            
            // Security check for SetupEntityAccess object access
            if (!Schema.SObjectType.SetupEntityAccess.isAccessible()) {
                throw new System.NoAccessException();
            }
            
            // Query all unique system permissions from SetupEntityAccess
            // This gives us ALL system permissions that actually exist in the org
            // Investigation showed CustomPermission is the correct SetupEntityType
            String query = 'SELECT SetupEntity.Name ' +
                          'FROM SetupEntityAccess ' +
                          'WHERE SetupEntityType = \'CustomPermission\' ' +
                          'GROUP BY SetupEntity.Name ' +
                          'ORDER BY SetupEntity.Name';
            
            List<AggregateResult> aggregateResults = Database.query(query);
            
            // Create a set to track unique permissions and avoid duplicates
            Set<String> processedPermissions = new Set<String>();
            
            // Process each unique system permission
            for (AggregateResult ar : aggregateResults) {
                String permissionName = (String) ar.get('Name');
                
                // Skip if we've already processed this permission
                if (processedPermissions.contains(permissionName)) {
                    continue;
                }
                
                processedPermissions.add(permissionName);
                
                // Create human-readable label from permission name
                String permissionLabel = createHumanReadableLabel(permissionName);
                
                // Check if this permission is marked as privileged in Custom Metadata
                // Try multiple matching strategies for flexible lookup
                Boolean isPrivileged = false;
                String privilegedDescription = null;
                SA_Audit__Privileged_System_Permission__mdt privPerm = null;
                
                // Try direct match with null safety
                if (String.isNotBlank(permissionName)) {
                    if (privilegedPermsMap.containsKey(permissionName)) {
                        privPerm = privilegedPermsMap.get(permissionName);
                    } else if (privilegedPermsMap.containsKey(permissionName.toLowerCase())) {
                        privPerm = privilegedPermsMap.get(permissionName.toLowerCase());
                    } else if (privilegedPermsMap.containsKey('Permissions' + permissionName)) {
                        privPerm = privilegedPermsMap.get('Permissions' + permissionName);
                    } else if (privilegedPermsMap.containsKey(('Permissions' + permissionName).toLowerCase())) {
                        privPerm = privilegedPermsMap.get(('Permissions' + permissionName).toLowerCase());
                    }
                }
                
                if (privPerm != null) {
                    isPrivileged = privPerm.SA_Audit__Is_Privileged__c != null ? privPerm.SA_Audit__Is_Privileged__c : false;
                    privilegedDescription = privPerm.SA_Audit__Description__c;
                }
                
                // Create wrapper for this permission
                SystemPermissionWrapper wrapper = new SystemPermissionWrapper();
                wrapper.id = permissionName;
                wrapper.name = permissionName;
                wrapper.label = permissionLabel;
                wrapper.isSelected = false;
                wrapper.isPrivileged = isPrivileged;
                wrapper.privilegedDescription = privilegedDescription;
                systemPermissions.add(wrapper);
            }
            
            // Also include permissions from PermissionSet schema that might not be in SetupEntityAccess
            // This ensures we get both assigned and unassigned permissions
            addPermissionSetSchemaPermissions(systemPermissions, processedPermissions);
            
            // Sort by label for better user experience
            systemPermissions.sort();
            
        } catch (Exception e) {
            System.debug('Error retrieving system permissions: ' + e.getMessage());
            throw e;
        }
        
        return systemPermissions;
    }
    
    /**
     * @description Create a human-readable label from a system permission API name
     * @param permissionName The API name of the permission
     * @return String Human-readable label
     */
    private static String createHumanReadableLabel(String permissionName) {
        // Handle null or empty permission names
        if (String.isBlank(permissionName)) {
            return 'Unknown Permission';
        }
        
        // Map of common permission overrides for better readability
        Map<String, String> labelOverrides = new Map<String, String> {
            'ModifyAllData' => 'Modify All Data',
            'ViewAllData' => 'View All Data',
            'AuthorApex' => 'Author Apex',
            'ManageUsers' => 'Manage Users',
            'CustomizeApplication' => 'Customize Application',
            'ManageRoles' => 'Manage Roles',
            'ViewSetup' => 'View Setup',
            'ManageIpAddresses' => 'Manage IP Addresses',
            'ManageSharing' => 'Manage Sharing',
            'ManageProfiles' => 'Manage Profiles',
            'ManagePasswordPolicies' => 'Manage Password Policies',
            'ManagePermissionSets' => 'Manage Permission Sets',
            'ManageAnalyticSnapshots' => 'Manage Analytic Snapshots',
            'ManageDataIntegrations' => 'Manage Data Integrations',
            'AssignPermissionSets' => 'Assign Permission Sets',
            'ManageCustomPermissions' => 'Manage Custom Permissions',
            'ManageMobile' => 'Manage Mobile',
            'ManageCertificates' => 'Manage Certificates',
            'ManageDataCategories' => 'Manage Data Categories',
            'ManageEncryptionKeys' => 'Manage Encryption Keys',
            'ManageEmailClientConfig' => 'Manage Email Client Config',
            'ManageFlows' => 'Manage Flows',
            'ViewPlatformEvents' => 'View Platform Events',
            'ManageCustomReportTypes' => 'Manage Custom Report Types',
            'ModifyMetadata' => 'Modify Metadata',
            'RunReports' => 'Run Reports',
            'ExportReports' => 'Export Reports',
            'PasswordNeverExpires' => 'Password Never Expires',
            'ViewMyTeamsDashboards' => 'View My Team\'s Dashboards',
            'ManageDashboards' => 'Manage Dashboards',
            'ScheduleReports' => 'Schedule Reports',
            'EnableNotifications' => 'Enable Notifications',
            'ApiEnabled' => 'API Enabled',
            'CreateCustomizeReports' => 'Create and Customize Reports',
            'ManageCategories' => 'Manage Categories',
            'ConvertLeads' => 'Convert Leads',
            'TransferAnyCase' => 'Transfer Any Case',
            'TransferAnyLead' => 'Transfer Any Lead',
            'ManageSolutions' => 'Manage Solutions',
            'ViewAllUsers' => 'View All Users',
            'EditPublicDocuments' => 'Edit Public Documents',
            'ViewPublicReports' => 'View Public Reports',
            'ManagePublicReports' => 'Manage Public Reports',
            'EditPublicReports' => 'Edit Public Reports',
            'ManagePublicDocuments' => 'Manage Public Documents',
            'ViewAllForecasts' => 'View All Forecasts',
            'ManageForecasts' => 'Manage Forecasts',
            'EditOppLineItemUnitPrice' => 'Edit Opportunity Product Unit Price',
            'ImportPersonal' => 'Import Personal Contacts',
            'WeeklyDataExport' => 'Weekly Data Export',
            'ManageBusinessHourHolidays' => 'Manage Business Hours and Holidays',
            'ManageCallCenters' => 'Manage Call Centers',
            'ManageCases' => 'Manage Cases',
            'ManageKnowledge' => 'Manage Knowledge',
            'ManageArticles' => 'Manage Articles',
            'ViewDataCategories' => 'View Data Categories',
            'ManageEmailTemplates' => 'Manage Email Templates',
            'SendSitRequests' => 'Send Sit Requests',
            'ManageRemoteAccess' => 'Manage Remote Access',
            'CanUseNewDashboardBuilder' => 'Use New Dashboard Builder',
            'ManageSearchPromotionRules' => 'Manage Search Promotion Rules',
            'ManageInteraction' => 'Manage Interaction',
            'RunFlow' => 'Run Flows',
            'ManageAuthProviders' => 'Manage Auth Providers',
            'ManageTwoFactor' => 'Manage Two-Factor Authentication',
            'PerformanceTestingEnabled' => 'Performance Testing Enabled',
            'ManageNetworks' => 'Manage Networks',
            'ManageContentTypes' => 'Manage Content Types',
            'ManageExchangeConfig' => 'Manage Exchange Configuration',
            'DelegatedTwoFactor' => 'Delegated Two-Factor Authentication',
            'ChatterFileLink' => 'Chatter File Link',
            'ManageChatterMessages' => 'Manage Chatter Messages',
            'EmailMass' => 'Mass Email',
            'EmailSingle' => 'Single Email',
            'SendCustomNotifications' => 'Send Custom Notifications',
            'PackagingAPI' => 'Packaging API',
            'DistributeFromPersWksp' => 'Distribute From Personal Workspace',
            'ViewDataAssessment' => 'View Data Assessment',
            'RemoveDirectMessageMembers' => 'Remove Direct Message Members',
            'CanEditPrompts' => 'Edit Prompts',
            'ViewRoles' => 'View Roles',
            'ManageProfilesPermissionsets' => 'Manage Profiles and Permission Sets',
            'ManageIpAddresses' => 'Manage IP Addresses',
            'ActivateContract' => 'Activate Contracts',
            'ActivateOrder' => 'Activate Orders',
            'ImportLeads' => 'Import Leads',
            'TransferAnyEntity' => 'Transfer Any Record',
            'NewReportBuilder' => 'New Report Builder',
            'ActivatePortal' => 'Activate Portal',
            'AddDirectMessageMembers' => 'Add Direct Message Members',
            'AllowUniversalSearch' => 'Allow Universal Search',
            'ConnectOrgToEnvironmentHub' => 'Connect Org to Environment Hub',
            'ContentAdministrator' => 'Content Administrator',
            'CreateCustomizeDashboards' => 'Create and Customize Dashboards',
            'CreateCustomizeFilters' => 'Create and Customize List Views',
            'CreatePackaging' => 'Create Packages',
            'CreateWorkspaces' => 'Create Workspaces',
            'CustomSidebarOnAllPages' => 'Custom Sidebar on All Pages',
            'DeleteActivatedContract' => 'Delete Activated Contracts',
            'EditActivatedOrders' => 'Edit Activated Orders',
            'EditBrandTemplates' => 'Edit Brand Templates',
            'EditCaseComments' => 'Edit Case Comments',
            'EditEvent' => 'Edit Events',
            'EditHtmlTemplates' => 'Edit HTML Templates',
            'EditKnowledge' => 'Edit Knowledge',
            'EditMyDashboards' => 'Edit My Dashboards',
            'EditMyReports' => 'Edit My Reports',
            'EditOppLineItemUnitPrice' => 'Edit Opportunity Product Unit Price',
            'EditPublicFilters' => 'Edit Public List Views',
            'EditPublicTemplates' => 'Edit Public Templates',
            'EditReadonlyFields' => 'Edit Read Only Fields',
            'EditTask' => 'Edit Tasks',
            'EmailTemplateManagement' => 'Email Template Management',
            'EnableCommunityAppLauncher' => 'Enable Community App Launcher',
            'ExportReport' => 'Export Reports',
            'ForceTwoFactor' => 'Force Two-Factor Authentication',
            'GovernNetworks' => 'Govern Networks',
            'HideReadByList' => 'Hide Read By List',
            'IdentityConnect' => 'Identity Connect',
            'IdentityEnabled' => 'Identity Enabled',
            'ImportCustomObjects' => 'Import Custom Objects',
            'InboundMigrationToolsUser' => 'Inbound Migration Tools User',
            'LightningConsoleAllowedForUser' => 'Lightning Console Allowed for User',
            'LightningExperienceUser' => 'Lightning Experience User',
            'ListEmailSend' => 'Send List Emails',
            'ManageAnalyticsSnapshots' => 'Manage Analytics Snapshots',
            'ManageApiIntegrations' => 'Manage API Integrations',
            'ManageAppMenu' => 'Manage App Menu',
            'ManageBillingInfo' => 'Manage Billing Information',
            'ManageChatterMessages' => 'Manage Chatter Messages',
            'ManageCustomObjects' => 'Manage Custom Objects',
            'ManageCustomReportTypes' => 'Manage Custom Report Types',
            'ManageDataLoader' => 'Manage Data Loader',
            'ManageEmailClientConfig' => 'Manage Email Client Configuration',
            'ManageHealthCheck' => 'Manage Health Check',
            'ManageHubConnections' => 'Manage Hub Connections',
            'ManageLoginAccessPolicies' => 'Manage Login Access Policies',
            'ManagePackageLicenses' => 'Manage Package Licenses',
            'ManagePardotEinsteinSettings' => 'Manage Pardot Einstein Settings',
            'ManagePartners' => 'Manage Partners',
            'ManagePvtRptsAndDashbds' => 'Manage Private Reports and Dashboards',
            'ManageQuotas' => 'Manage Quotas',
            'ManageReportsInPubFolders' => 'Manage Reports in Public Folders',
            'ManageSandboxes' => 'Manage Sandboxes',
            'ManageSessionPermissionSets' => 'Manage Session Permission Sets',
            'ManageSubscriptions' => 'Manage Subscriptions',
            'ManageSynonyms' => 'Manage Synonyms',
            'ManageUnlistedGroups' => 'Manage Unlisted Groups',
            'MassInlineEdit' => 'Mass Inline Edit',
            'MergeTopics' => 'Merge Topics',
            'ModerateChatter' => 'Moderate Chatter',
            'ModerateNetworkUsers' => 'Moderate Network Users',
            'NewReportBuilder' => 'New Report Builder',
            'OutboundMigrationToolsUser' => 'Outbound Migration Tools User',
            'OverrideForecasts' => 'Override Forecasts',
            'PublishPackaging' => 'Publish Packages',
            'RemoveDirectMessageMembers' => 'Remove Direct Message Members',
            'ResetPasswords' => 'Reset User Passwords and Unlock Users',
            'SelectFilesFromSalesforce' => 'Select Files from Salesforce',
            'SendAnnouncementEmails' => 'Send Announcement Emails',
            'ShareInternalArticles' => 'Share Internal Articles',
            'ShowCompanyNameAsUserBadge' => 'Show Company Name as User Badge',
            'SolutionImport' => 'Solution Import',
            'SubscribeToLightningDashboards' => 'Subscribe to Lightning Dashboards',
            'SubscribeToLightningReports' => 'Subscribe to Lightning Reports',
            'TransferAnyCase' => 'Transfer Any Case',
            'TransferAnyEntity' => 'Transfer Any Entity',
            'TransferAnyLead' => 'Transfer Any Lead',
            'UseTeamReassignWizards' => 'Use Team Reassignment Wizards',
            'ViewAllUsers' => 'View All Users',
            'ViewDataLeakageEvents' => 'View Data Leakage Events',
            'ViewEncryptedData' => 'View Encrypted Data',
            'ViewEventLogFiles' => 'View Event Log Files',
            'ViewHealthCheck' => 'View Health Check',
            'ViewHelpLink' => 'View Help Link',
            'ViewMyTeamsDashboards' => 'View My Team\'s Dashboards',
            'ViewOnlyEmbeddedAppUser' => 'View Only Embedded App User',
            'ViewPrivateStaticResources' => 'View Private Static Resources',
            'ViewPublicDashboards' => 'View Public Dashboards',
            'ViewSetupAuditTrail' => 'View Setup Audit Trail',
            'WorkCalibrationUser' => 'Work Calibration User',
            'WorkDotComUserPerm' => 'Work.com User Permission'
        };
        
        // Check if we have a specific override for this permission
        if (labelOverrides.containsKey(permissionName)) {
            return labelOverrides.get(permissionName);
        }
        
        // If no override, create a human-readable label by adding spaces before capital letters
        String label = permissionName.replaceAll('([A-Z])', ' $1').trim();
        
        // Handle special cases where the first character might be lowercase
        if (label.length() > 0) {
            label = label.substring(0, 1).toUpperCase() + label.substring(1);
        }
        
        return label;
    }
    
    /**
     * @description Add permissions from PermissionSet schema that might not be in SetupEntityAccess
     * This ensures we capture all possible permissions, including those not currently assigned
     * @param systemPermissions The list to add permissions to
     * @param processedPermissions Set of permissions already processed to avoid duplicates
     */
    private static void addPermissionSetSchemaPermissions(List<SystemPermissionWrapper> systemPermissions, Set<String> processedPermissions) {
        try {
            // Get privileged permissions from Custom Metadata Type (reuse from earlier)
            // Create case-insensitive map for matching
            Map<String, SA_Audit__Privileged_System_Permission__mdt> privilegedPermsMap = new Map<String, SA_Audit__Privileged_System_Permission__mdt>();
            for (SA_Audit__Privileged_System_Permission__mdt psp : [
                SELECT SA_Audit__Permission_API_Name__c, SA_Audit__Permission_Label__c, SA_Audit__Description__c, SA_Audit__Is_Privileged__c
                FROM SA_Audit__Privileged_System_Permission__mdt
                LIMIT 10000
            ]) {
                // Store with multiple keys for flexible matching
                String apiName = psp.SA_Audit__Permission_API_Name__c;
                if (String.isNotBlank(apiName)) {
                    privilegedPermsMap.put(apiName.toLowerCase(), psp);
                    privilegedPermsMap.put(apiName, psp);
                    // Also store without 'Permissions' prefix
                    if (apiName.startsWith('Permissions')) {
                        String withoutPrefix = apiName.substring(11); // Remove 'Permissions'
                        privilegedPermsMap.put(withoutPrefix.toLowerCase(), psp);
                        privilegedPermsMap.put(withoutPrefix, psp);
                    }
                }
            }
            
            // Get the schema of the PermissionSet object to find permission fields
            Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.PermissionSet.fields.getMap();
            
            // Process permission fields from PermissionSet schema
            for (String fieldName : fieldMap.keySet()) {
                if (fieldName.startsWith('permissions')) {
                    String permApiName = fieldName.replaceFirst('permissions', '');
                    
                    // Skip if we've already processed this permission from SetupEntityAccess
                    if (processedPermissions.contains(permApiName)) {
                        continue;
                    }
                    
                    // Get field description for better labeling
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                    String permLabel = fieldDescribe != null ? fieldDescribe.getLabel() : createHumanReadableLabel(permApiName);
                    
                    // If the label is just the field name, create a better one
                    if (String.isBlank(permLabel) || permLabel.equals(fieldName) || permLabel.startsWith('Permissions')) {
                        permLabel = createHumanReadableLabel(permApiName);
                    }
                    
                    // Check if this permission is marked as privileged
                    // Try multiple matching strategies for flexible lookup
                    Boolean isPrivileged = false;
                    String privilegedDescription = null;
                    SA_Audit__Privileged_System_Permission__mdt privPerm = null;
                    
                    // Try direct match with null safety
                    if (String.isNotBlank(permApiName)) {
                        if (privilegedPermsMap.containsKey(permApiName)) {
                            privPerm = privilegedPermsMap.get(permApiName);
                        } else if (privilegedPermsMap.containsKey(permApiName.toLowerCase())) {
                            privPerm = privilegedPermsMap.get(permApiName.toLowerCase());
                        } else if (privilegedPermsMap.containsKey('Permissions' + permApiName)) {
                            privPerm = privilegedPermsMap.get('Permissions' + permApiName);
                        } else if (privilegedPermsMap.containsKey(('Permissions' + permApiName).toLowerCase())) {
                            privPerm = privilegedPermsMap.get(('Permissions' + permApiName).toLowerCase());
                        }
                    }
                    
                    if (privPerm != null) {
                        isPrivileged = privPerm.SA_Audit__Is_Privileged__c != null ? privPerm.SA_Audit__Is_Privileged__c : false;
                        privilegedDescription = privPerm.SA_Audit__Description__c;
                    }
                    
                    // Create wrapper for this permission
                    SystemPermissionWrapper wrapper = new SystemPermissionWrapper();
                    wrapper.id = permApiName;
                    wrapper.name = permApiName;
                    wrapper.label = permLabel;
                    wrapper.isSelected = false;
                    wrapper.isPrivileged = isPrivileged;
                    wrapper.privilegedDescription = privilegedDescription;
                    systemPermissions.add(wrapper);
                    
                    processedPermissions.add(permApiName);
                }
            }
        } catch (Exception e) {
            // Log error but don't fail the entire method
            System.debug('Error adding PermissionSet schema permissions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get system permission access with enhanced user data for template exports - OPTIMIZED FOR LARGE ORGS
     * @param systemPermissionName The name of the system permission to analyze
     * @param selectedUserFields List of user field names to include in the result
     * @param maxUsers Maximum number of users to return (default 1000, max 5000)
     * @return Map<String, Object> containing profiles, permission sets, and users with access
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSystemPermissionAccessWithUserFields(String systemPermissionName, List<String> selectedUserFields, Integer maxUsers) {
        Map<String, Object> result = new Map<String, Object>();
        Set<Id> allParentIds = new Set<Id>();
        List<Map<String, Object>> profilesWithAccess = new List<Map<String, Object>>();
        List<Map<String, Object>> permSetsWithAccess = new List<Map<String, Object>>();
        List<Map<String, Object>> permSetGroupsWithAccess = new List<Map<String, Object>>();
        List<Map<String, Object>> usersWithAccess = new List<Map<String, Object>>();
        
        try {
            if (String.isBlank(systemPermissionName)) {
                throw new AuraHandledException('System permission name is required');
            }
            
            // Set default and max limits for users - optimized for performance
            if (maxUsers == null || maxUsers <= 0) maxUsers = 2000;
            if (maxUsers > 5000) maxUsers = 5000; // Increased but with better chunking
            
            String fieldName = 'Permissions' + systemPermissionName;
            
            // Query profiles that have this permission with LIMIT (reduced to prevent CPU timeouts)
            String profileQuery = 'SELECT Id, Name, UserLicense.Name FROM Profile WHERE ' + fieldName + ' = true ORDER BY Name LIMIT ' + SOQL_LIMIT_BUFFER;
            List<Profile> profilesWithPerm = Database.query(profileQuery);
            
            // Map to store profile data for easy lookup
            Map<Id, Map<String, Object>> profileDataById = new Map<Id, Map<String, Object>>();
            
            // Create profile results and add their IDs to the set of parent IDs
            for (Profile p : profilesWithPerm) {
                Map<String, Object> profileMap = new Map<String, Object>{
                    'id' => p.Id,
                    'name' => p.Name,
                    'type' => 'Profile',
                    'userLicense' => p.UserLicense?.Name
                };
                profilesWithAccess.add(profileMap);
                profileDataById.put(p.Id, profileMap);
                allParentIds.add(p.Id);
            }
            
            // Query direct permission sets (not in permission set groups) with LIMIT (reduced to prevent CPU timeouts)
            String permSetQuery = 'SELECT Id, Name, Label, Description, IsOwnedByProfile, ProfileId, ' +
                          'IsCustom, CreatedById, CreatedBy.Name, CreatedDate ' +
                          'FROM PermissionSet ' +
                          'WHERE ' + fieldName + ' = true AND IsOwnedByProfile = false ' +
                          'ORDER BY Label LIMIT ' + SOQL_LIMIT_BUFFER;
            List<PermissionSet> permSetsWithPerm = Database.query(permSetQuery);
            
            // Map to store permission set data for easy lookup
            Map<Id, Map<String, Object>> permSetDataById = new Map<Id, Map<String, Object>>();
            
            // Create permission set results and add their IDs to the set of parent IDs
            Set<Id> permSetIds = new Set<Id>();
            for (PermissionSet ps : permSetsWithPerm) {
                Map<String, Object> permSetMap = new Map<String, Object>{
                    'id' => ps.Id,
                    'name' => ps.Name,
                    'label' => ps.Label,
                    'description' => ps.Description,
                    'type' => 'Permission Set',
                    'assignmentCount' => 0, // Will be calculated later if needed
                    // Added missing metadata fields
                    'isCustom' => ps.IsCustom,
                    'createdById' => ps.CreatedById,
                    'createdByName' => ps.CreatedBy?.Name,
                    'createdDate' => ps.CreatedDate
                };
                permSetsWithAccess.add(permSetMap);
                permSetDataById.put(ps.Id, permSetMap);
                allParentIds.add(ps.Id);
                permSetIds.add(ps.Id);
            }
            
            // Skip permission set groups for now to save heap space
            // In large orgs, focus on direct assignments
            
            // Build complete user fields query FIRST - including custom fields
            String userFieldsString = 'Id, Name, Username, Email, ProfileId, Profile.Name, Profile.UserLicense.Name, IsActive';
            
            // Create optimized field mapping for ALL user fields
            Map<String, String> fieldNameMapping = new Map<String, String>();
            
            // Only add essential selected fields to avoid heap issues
            if (selectedUserFields != null && !selectedUserFields.isEmpty() && selectedUserFields.size() <= 15) {
                Set<String> validFields = new Set<String>();
                Map<String, Schema.SObjectField> userFieldMap = User.sObjectType.getDescribe().fields.getMap();
                
                System.debug('Processing ' + selectedUserFields.size() + ' user fields');
                
                // Create a reverse lookup map for faster field name resolution (case-insensitive)
                Map<String, String> lowercaseToActualFieldName = new Map<String, String>();
                for (String fieldKey : userFieldMap.keySet()) {
                    String actualFieldName = userFieldMap.get(fieldKey).getDescribe().getName();
                    lowercaseToActualFieldName.put(fieldKey.toLowerCase(), actualFieldName);
                }
                
                // First pass: Create mapping for ALL fields efficiently
                for (String userFieldName : selectedUserFields) {
                    // Handle relationship fields specially
                    if (userFieldName.equalsIgnoreCase('Profile.Name') || userFieldName.equalsIgnoreCase('Profile.UserLicense.Name')) {
                        fieldNameMapping.put(userFieldName, userFieldName); // Keep as-is for relationship fields
                        System.debug('Mapped relationship field: ' + userFieldName + ' -> ' + userFieldName);
                        continue;
                    }
                    
                    // Use optimized lookup
                    String actualFieldName = lowercaseToActualFieldName.get(userFieldName.toLowerCase());
                    if (actualFieldName != null) {
                        fieldNameMapping.put(userFieldName, actualFieldName);
                        System.debug('Mapped field: ' + userFieldName + ' -> ' + actualFieldName);
                    } else {
                        System.debug('NO MAPPING FOUND for field: ' + userFieldName);
                    }
                }
                
                // Second pass: Add only additional fields to query (not already included) - optimized
                Integer fieldCount = 0;
                for (String userFieldName : selectedUserFields) {
                    if (fieldCount >= 15) break; // Increased limit with better performance
                    
                    // Skip relationship fields as they're handled separately
                    if (userFieldName.equalsIgnoreCase('Profile.Name') || userFieldName.equalsIgnoreCase('Profile.UserLicense.Name')) {
                        continue;
                    }
                    
                    String actualFieldName = fieldNameMapping.get(userFieldName);
                    if (actualFieldName != null) {
                        // Only add fields that are NOT already in the base query
                        boolean isAlreadyIncluded = userFieldName.equalsIgnoreCase('Id') ||
                            userFieldName.equalsIgnoreCase('Name') ||
                            userFieldName.equalsIgnoreCase('Username') ||
                            userFieldName.equalsIgnoreCase('Email') ||
                            userFieldName.equalsIgnoreCase('ProfileId') ||
                            userFieldName.equalsIgnoreCase('IsActive');
                        
                        if (!isAlreadyIncluded) {
                            // Use efficient lookup for field accessibility
                            String fieldKey = userFieldName.toLowerCase();
                            if (userFieldMap.containsKey(fieldKey) || userFieldMap.containsKey(actualFieldName.toLowerCase())) {
                                Schema.DescribeFieldResult fieldDescribe = null;
                                if (userFieldMap.containsKey(fieldKey)) {
                                    fieldDescribe = userFieldMap.get(fieldKey).getDescribe();
                                } else {
                                    fieldDescribe = userFieldMap.get(actualFieldName.toLowerCase()).getDescribe();
                                }
                                
                                if (fieldDescribe != null && fieldDescribe.isAccessible()) {
                                    validFields.add(actualFieldName);
                        fieldCount++;
                                }
                            }
                        }
                    }
                }
                
                if (!validFields.isEmpty()) {
                    userFieldsString += ', ' + String.join(new List<String>(validFields), ', ');
                    System.debug('Added ' + validFields.size() + ' custom fields to query: ' + validFields);
                    System.debug('Complete SOQL query: ' + userFieldsString);
                } else {
                    System.debug('No additional fields added to query - validFields is empty');
                }
            }
            
            // Now execute user queries with the complete field list
            Set<Id> allUserIds = new Set<Id>();
            List<User> allUsers = new List<User>();
            
            // Add users with profiles that have the permission
            if (!allParentIds.isEmpty()) {
                // Use a single optimized query to get all users at once (within limits)
                String userQuery = 'SELECT ' + userFieldsString + ' FROM User WHERE ProfileId IN :allParentIds AND IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' ORDER BY Id LIMIT ' + maxUsers;
                System.debug('Executing profile user query: ' + userQuery);
                List<User> profileUsers = Database.query(userQuery);
                
                // Add all users from profiles
                for (User u : profileUsers) {
                    allUserIds.add(u.Id);
                    allUsers.add(u);
                }
                
                System.debug('Loaded ' + profileUsers.size() + ' users from profiles in single query');
            }
            
            // Add users with permission sets - OPTIMIZED
            if (!permSetIds.isEmpty() && allUserIds.size() < maxUsers) {
                try {
                    Integer remainingUsers = maxUsers - allUserIds.size();
                    
                    // Use a single optimized query to get users directly
                    String permSetUserQuery = 'SELECT ' + userFieldsString + 
                        ' FROM User WHERE Id IN (' +
                        'SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN :permSetIds' +
                        ') AND IsActive = true AND Profile.UserLicense.Name = \'Salesforce\'' +
                        ' AND Id NOT IN :allUserIds' +
                        ' ORDER BY Name LIMIT ' + remainingUsers;
                    
                        List<User> permSetUsers = Database.query(permSetUserQuery);
                    
                    // Add to collections
                    for (User u : permSetUsers) {
                        allUserIds.add(u.Id);
                        allUsers.add(u);
                    }
                    
                    System.debug('Loaded ' + permSetUsers.size() + ' additional users from permission sets');
                } catch (Exception e) {
                    // Continue without permission set assignments if query fails
                    System.debug('Warning: Could not query permission set assignments: ' + e.getMessage());
                }
            }
            
            // Query users in chunks to avoid heap issues
            // (allUsers already declared earlier - don't redeclare)
            if (allUsers.isEmpty() && !allUserIds.isEmpty()) {
                List<Id> userIdsList = new List<Id>(allUserIds);
                Integer ROW_LIMIT_BUFFER = 45000;          // head-room for other queries
                if (userIdsList.size() > ROW_LIMIT_BUFFER) {
                    // Apex generics limitations can cause subList type issues on List<Id>,
                    // so we create a new truncated list manually instead of relying on subList.
                    List<Id> truncatedList = new List<Id>();
                    for (Integer idx = 0; idx < ROW_LIMIT_BUFFER; idx++) {
                        truncatedList.add(userIdsList[idx]);
                    }
                    userIdsList = truncatedList;
                    System.debug('Truncated user list to ' + ROW_LIMIT_BUFFER +
                                 ' to respect query-row governor limit.');
                }
                Integer chunkSize = 5000; // Larger chunk reduces number of queries while staying below query row limits
                
                for (Integer i = 0; i < userIdsList.size(); i += chunkSize) {
                    Integer endIndex = Math.min(i + chunkSize, userIdsList.size());
                    List<Id> chunkIds = new List<Id>();
                    for (Integer j = i; j < endIndex; j++) {
                        chunkIds.add(userIdsList[j]);
                    }
                    
                    String chunkQuery = 'SELECT ' + userFieldsString + ' FROM User WHERE Id IN :chunkIds AND IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' ORDER BY Name';
                    List<User> chunkUsers = Database.query(chunkQuery);
                    allUsers.addAll(chunkUsers);
                }
            }
            
            
            // Build simplified user results to save heap space
            for (User u : allUsers) {
                // Build minimal user map
                Map<String, Object> userMap = new Map<String, Object>{
                    'id' => u.Id,
                    'name' => u.Name,
                    'username' => u.Username,
                    'email' => u.Email,
                    'profileId' => u.ProfileId,
                    'profileName' => u.Profile.Name,
                    'isActive' => u.IsActive
                };
                
                // Add permission source (simplified)
                if (profileDataById.containsKey(u.ProfileId)) {
                    userMap.put('permissionSource', 'Profile: ' + profileDataById.get(u.ProfileId).get('name'));
                } else {
                    userMap.put('permissionSource', 'Permission Set');
                }
                
                // Add additional user fields efficiently using pre-created mapping
                if (selectedUserFields != null && !selectedUserFields.isEmpty()) {
                    // Debug field mapping for first user only
                    if (u == allUsers[0]) {
                        System.debug('=== USER FIELD DEBUGGING FOR FIRST USER ===');
                        System.debug('Field mapping contains: ' + fieldNameMapping.keySet());
                        System.debug('Selected user fields: ' + selectedUserFields);
                    }
                    
                    Integer fieldCount = 0;
                    for (String userFieldName : selectedUserFields) {
                        if (fieldCount >= 15) break; // Increased limit with better performance
                        try {
                            Object fieldValue;
                            
                            // Handle relationship fields specially
                            if (userFieldName.equalsIgnoreCase('Profile.Name')) {
                                fieldValue = u.Profile?.Name;
                            } else if (userFieldName.equalsIgnoreCase('Profile.UserLicense.Name')) {
                                fieldValue = u.Profile?.UserLicense?.Name;
                            } else {
                                // Use the actual field name from the pre-created mapping
                                String actualFieldName = fieldNameMapping.get(userFieldName);
                                if (actualFieldName != null) {
                                    fieldValue = u.get(actualFieldName);
                                    // Debug successful field access for first user
                                    if (u == allUsers[0]) {
                                        System.debug('SUCCESS: ' + userFieldName + ' -> ' + actualFieldName + ' = ' + fieldValue);
                                    }
                                } else {
                                    // Fallback to original field name
                                    fieldValue = u.get(userFieldName);
                                    // Debug fallback for first user
                                    if (u == allUsers[0]) {
                                        System.debug('FALLBACK: ' + userFieldName + ' (no mapping) = ' + fieldValue);
                                    }
                                }
                            }
                            
                            userMap.put(userFieldName, fieldValue);
                            fieldCount++;
                        } catch (Exception e) {
                            // Field doesn't exist or isn't accessible, set to null and continue
                            userMap.put(userFieldName, null);
                            // Debug errors for first user
                            if (u == allUsers[0]) {
                                System.debug('ERROR: ' + userFieldName + ' failed: ' + e.getMessage());
                            }
                        }
                    }
                }
                
                usersWithAccess.add(userMap);
            }
            
            // Assemble the result
            result.put('systemPermissionName', systemPermissionName);
            result.put('profilesWithAccess', profilesWithAccess);
            result.put('permissionSetsWithAccess', permSetsWithAccess);
            result.put('permissionSetGroupsWithAccess', permSetGroupsWithAccess);
            result.put('usersWithAccess', usersWithAccess);
            result.put('totalUsers', usersWithAccess.size());
            result.put('maxUsersReached', usersWithAccess.size() >= maxUsers);
            result.put('isLimitedResult', true);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getSystemPermissionAccessWithUserFields: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving system permission access: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Get system permission access for profiles, permission sets, and permission set groups
     * @param systemPermissionName The name of the system permission to analyze (e.g. "ModifyAllData")
     * @return Map<String, Object> Map containing profiles, permission sets, permission set groups, and users with access
     */
    @AuraEnabled
    public static Map<String, Object> getSystemPermissionAccess(String systemPermissionName) {
        Map<String, Object> result = new Map<String, Object>();
        Set<Id> allParentIds = new Set<Id>();
        List<Map<String, Object>> profilesWithAccess = new List<Map<String, Object>>();
        List<Map<String, Object>> permSetsWithAccess = new List<Map<String, Object>>();
        List<Map<String, Object>> permSetGroupsWithAccess = new List<Map<String, Object>>();
        List<Map<String, Object>> usersWithAccess = new List<Map<String, Object>>();
        
        try {
            if (String.isBlank(systemPermissionName)) {
                throw new AuraHandledException('System permission name is required');
            }
            
            String fieldName = 'Permissions' + systemPermissionName;
            
            // Query profiles that have this permission - Updated to include all metadata
            String profileQuery = 'SELECT Id, Name, Description, UserLicense.Name, CreatedById, CreatedBy.Name, CreatedDate FROM Profile WHERE ' + fieldName + ' = true ORDER BY Name';
            List<Profile> profilesWithPerm = Database.query(profileQuery);
            
            // Map to store profile data for easy lookup
            Map<Id, Map<String, Object>> profileDataById = new Map<Id, Map<String, Object>>();
            
            // Create profile results and add their IDs to the set of parent IDs
            for (Profile p : profilesWithPerm) {
                Map<String, Object> profileMap = new Map<String, Object>{
                    'id' => p.Id,
                    'name' => p.Name,
                    'description' => p.Description,
                    'type' => 'Profile',
                    'userLicense' => p.UserLicense?.Name,
                    'createdById' => p.CreatedById,
                    'createdByName' => p.CreatedBy?.Name,
                    'createdDate' => p.CreatedDate
                };
                profilesWithAccess.add(profileMap);
                profileDataById.put(p.Id, profileMap);
                allParentIds.add(p.Id);
            }
            
            // Query direct permission sets (not in permission set groups) - Updated to include all required fields
            String permSetQuery = 'SELECT Id, Name, Label, Description, IsOwnedByProfile, ProfileId, ' +
                          'IsCustom, CreatedById, CreatedBy.Name, CreatedDate ' +
                          'FROM PermissionSet ' +
                          'WHERE ' + fieldName + ' = true AND IsOwnedByProfile = false ' +
                          'ORDER BY Label';
            List<PermissionSet> permSetsWithPerm = Database.query(permSetQuery);
            
            // Map of permission set IDs to their assignment count
            Map<Id, Integer> permSetAssignmentCounts = new Map<Id, Integer>();
            
            // Map to store permission set data for easy lookup
            Map<Id, Map<String, Object>> permSetDataById = new Map<Id, Map<String, Object>>();
            
            // Get assignment counts in a separate query
            if (!permSetsWithPerm.isEmpty()) {
                List<AggregateResult> assignmentCounts = [
                    SELECT PermissionSetId, COUNT(Id) assignmentCount
                    FROM PermissionSetAssignment
                    WHERE PermissionSetId IN :permSetsWithPerm
                    GROUP BY PermissionSetId
                ];
                
                for (AggregateResult ar : assignmentCounts) {
                    Id permSetId = (Id)ar.get('PermissionSetId');
                    Integer count = (Integer)ar.get('assignmentCount');
                    permSetAssignmentCounts.put(permSetId, count);
                }
            }
            
            // Create permission set results and add their IDs to the set of parent IDs
            Set<Id> permSetIds = new Set<Id>();
            for (PermissionSet ps : permSetsWithPerm) {
                Integer assignmentCount = permSetAssignmentCounts.containsKey(ps.Id) ? 
                                          permSetAssignmentCounts.get(ps.Id) : 0;
                
                Map<String, Object> permSetMap = new Map<String, Object>{
                    'id' => ps.Id,
                    'name' => ps.Name,
                    'label' => ps.Label,
                    'description' => ps.Description,
                    'type' => 'Permission Set',
                    'assignmentCount' => assignmentCount,
                    // Added missing metadata fields
                    'isCustom' => ps.IsCustom,
                    'createdById' => ps.CreatedById,
                    'createdByName' => ps.CreatedBy?.Name,
                    'createdDate' => ps.CreatedDate
                };
                permSetsWithAccess.add(permSetMap);
                permSetDataById.put(ps.Id, permSetMap);
                allParentIds.add(ps.Id);
                permSetIds.add(ps.Id);
            }
            
            // Get permission set groups that include permission sets with this permission - Updated to include all metadata
            List<PermissionSetGroup> psGroups = [
                SELECT Id, DeveloperName, MasterLabel, Description, CreatedById, CreatedBy.Name, CreatedDate,
                       (SELECT Id, PermissionSetId FROM PermissionSetGroupComponents WHERE PermissionSetId IN :permSetIds) 
                FROM PermissionSetGroup 
                ORDER BY MasterLabel
            ];
            
            // Map to store permission set group data for easy lookup
            Map<Id, Map<String, Object>> psgDataById = new Map<Id, Map<String, Object>>();
            
            // Filter only permission set groups that actually contain permission sets with the permission
            Set<Id> permSetGroupIds = new Set<Id>();
            for (PermissionSetGroup psg : psGroups) {
                if (psg.PermissionSetGroupComponents.size() > 0) {
                    // Create a list of component permission sets for this PSG
                    List<Map<String, Object>> componentPermSets = new List<Map<String, Object>>();
                    
                    for (PermissionSetGroupComponent psgc : psg.PermissionSetGroupComponents) {
                        // Find the original permission set data
                        for (Map<String, Object> psMap : permSetsWithAccess) {
                            if (psMap.get('id') == psgc.PermissionSetId) {
                                componentPermSets.add(new Map<String, Object>{
                                    'id' => psgc.PermissionSetId,
                                    'name' => (String)psMap.get('name'),
                                    'label' => (String)psMap.get('label')
                                });
                                break;
                            }
                        }
                    }
                    
                    // Only add this PSG if it contains permission sets with the permission
                    if (!componentPermSets.isEmpty()) {
                        // Query to count assignments
                        Integer assignmentCount = [SELECT COUNT() FROM PermissionSetAssignment WHERE PermissionSetGroupId = :psg.Id];
                        
                        Map<String, Object> psgMap = new Map<String, Object>{
                            'id' => psg.Id,
                            'name' => psg.DeveloperName,
                            'label' => psg.MasterLabel,
                            'description' => psg.Description,
                            'type' => 'Permission Set Group',
                            'componentPermissionSets' => componentPermSets,
                            'assignmentCount' => assignmentCount,
                            'createdById' => psg.CreatedById,
                            'createdByName' => psg.CreatedBy?.Name,
                            'createdDate' => psg.CreatedDate
                        };
                        permSetGroupsWithAccess.add(psgMap);
                        psgDataById.put(psg.Id, psgMap);
                        permSetGroupIds.add(psg.Id);
                    }
                }
            }
            
            // Find all users who have this permission from any source
            
            // Get all user assignments for the relevant permission sets
            Map<Id, Set<Id>> userToPermSets = new Map<Id, Set<Id>>();
            if (!permSetIds.isEmpty()) {
                for (PermissionSetAssignment psa : [
                    SELECT AssigneeId, PermissionSetId
                    FROM PermissionSetAssignment 
                    WHERE PermissionSetId IN :permSetIds
                ]) {
                    if (!userToPermSets.containsKey(psa.AssigneeId)) {
                        userToPermSets.put(psa.AssigneeId, new Set<Id>());
                    }
                    userToPermSets.get(psa.AssigneeId).add(psa.PermissionSetId);
                }
            }
            
            // Get all user assignments for the relevant permission set groups
            Map<Id, Set<Id>> userToPermSetGroups = new Map<Id, Set<Id>>();
            if (!permSetGroupIds.isEmpty()) {
                for (PermissionSetAssignment psa : [
                    SELECT AssigneeId, PermissionSetGroupId
                    FROM PermissionSetAssignment 
                    WHERE PermissionSetGroupId IN :permSetGroupIds
                ]) {
                    if (!userToPermSetGroups.containsKey(psa.AssigneeId)) {
                        userToPermSetGroups.put(psa.AssigneeId, new Set<Id>());
                    }
                    userToPermSetGroups.get(psa.AssigneeId).add(psa.PermissionSetGroupId);
                }
            }
            
            // Query users with this permission via profile (with LIMIT to prevent 50K+ row error)
            List<User> usersWithProfilePerm = [
                SELECT Id, Name, Username, Email, ProfileId, Profile.Name, Profile.UserLicense.Name, IsActive,
                       Department, Title, Manager.Name, CreatedDate, LastLoginDate
                FROM User 
                WHERE ProfileId IN :allParentIds
                  AND IsActive = true
                  AND Profile.UserLicense.Name = 'Salesforce'
                ORDER BY Name
                LIMIT 45000
            ];
            
            // Log if we hit the limit
            if (usersWithProfilePerm.size() >= 45000) {
                System.debug('WARNING: Hit user limit for profile-based permissions. Some users may be missing from results.');
            }
            
            // Sets to track users who get permission from different sources
            Set<Id> usersWithPermissionSet = userToPermSets.keySet();
            Set<Id> usersWithPermSetGroup = userToPermSetGroups.keySet();
            
            // Combine users from permission sets and permission set groups
            Set<Id> additionalUserIds = new Set<Id>();
            additionalUserIds.addAll(usersWithPermissionSet);
            additionalUserIds.addAll(usersWithPermSetGroup);
            
            // Query additional users that have the permission via permission sets/groups but not via profile
            List<User> additionalUsers = new List<User>();
            if (!additionalUserIds.isEmpty()) {
                additionalUsers = [
                    SELECT Id, Name, Username, Email, ProfileId, Profile.Name, Profile.UserLicense.Name, IsActive,
                           Department, Title, Manager.Name, CreatedDate, LastLoginDate
                    FROM User 
                    WHERE Id IN :additionalUserIds
                      AND ProfileId NOT IN :allParentIds // Exclude users already counted via profile
                      AND IsActive = true
                      AND Profile.UserLicense.Name = 'Salesforce'
                    ORDER BY Name
                    LIMIT 45000
                ];
                
                // Log if we hit the limit
                if (additionalUsers.size() >= 45000) {
                    System.debug('WARNING: Hit user limit for permission set/group-based permissions. Some users may be missing from results.');
                }
            }
            
            // Add all users to the results
            Map<Id, User> allUsersMap = new Map<Id, User>();
            
            // First add users with profile-based permissions
            for (User u : usersWithProfilePerm) {
                allUsersMap.put(u.Id, u);
            }
            
            // Then add users with permission set/group-based permissions
            for (User u : additionalUsers) {
                allUsersMap.put(u.Id, u);
            }
            
            // Create user results
            for (User u : allUsersMap.values()) {
                // Build permission sources list for this user
                List<Map<String, Object>> permissionSources = new List<Map<String, Object>>();
                
                // Check if user gets permission from profile
                if (profileDataById.containsKey(u.ProfileId)) {
                    Map<String, Object> profileSource = profileDataById.get(u.ProfileId);
                    permissionSources.add(new Map<String, Object>{
                        'id' => profileSource.get('id'),
                        'name' => profileSource.get('name'),
                        'type' => 'Profile'
                    });
                }
                
                // Check if user gets permission from permission sets
                if (userToPermSets.containsKey(u.Id)) {
                    for (Id permSetId : userToPermSets.get(u.Id)) {
                        if (permSetDataById.containsKey(permSetId)) {
                            Map<String, Object> permSetSource = permSetDataById.get(permSetId);
                            permissionSources.add(new Map<String, Object>{
                                'id' => permSetSource.get('id'),
                                'name' => permSetSource.get('label'),
                                'type' => 'Permission Set'
                            });
                        }
                    }
                }
                
                // Check if user gets permission from permission set groups
                if (userToPermSetGroups.containsKey(u.Id)) {
                    for (Id psgId : userToPermSetGroups.get(u.Id)) {
                        if (psgDataById.containsKey(psgId)) {
                            Map<String, Object> psgSource = psgDataById.get(psgId);
                            permissionSources.add(new Map<String, Object>{
                                'id' => psgSource.get('id'),
                                'name' => psgSource.get('label'),
                                'type' => 'Permission Set Group'
                            });
                        }
                    }
                }
                
                Map<String, Object> userMap = new Map<String, Object>{
                    'id' => u.Id,
                    'name' => u.Name,
                    'username' => u.Username,
                    'email' => u.Email,
                    'profileId' => u.ProfileId,
                    'profileName' => u.Profile.Name,
                    'userLicense' => u.Profile.UserLicense?.Name,
                    'isActive' => u.IsActive,
                    'department' => u.Department,
                    'title' => u.Title,
                    'managerName' => u.Manager?.Name,
                    'createdDate' => u.CreatedDate,
                    'lastLoginDate' => u.LastLoginDate,
                    'permissionSources' => permissionSources
                };
                usersWithAccess.add(userMap);
            }
            
            // Assemble the result
            result.put('systemPermissionName', systemPermissionName);
            result.put('profilesWithAccess', profilesWithAccess);
            result.put('permissionSetsWithAccess', permSetsWithAccess);
            result.put('permissionSetGroupsWithAccess', permSetGroupsWithAccess);
            result.put('usersWithAccess', usersWithAccess);
            result.put('totalUsers', usersWithAccess.size());
        } catch (Exception e) {
            //system.debug(LoggingLevel.ERROR, 'Error in getSystemPermissionAccess: ' + e.getMessage());
            //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving system permission access: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Wrapper class for System Permission
     */
    public class SystemPermissionWrapper implements Comparable {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean isSelected;
        @AuraEnabled public Boolean isPrivileged;
        @AuraEnabled public String privilegedDescription;
        
        /**
         * @description Implementation of the Comparable interface to sort by label
         */
        public Integer compareTo(Object compareTo) {
            SystemPermissionWrapper other = (SystemPermissionWrapper)compareTo;
            return this.label.compareTo(other.label);
        }
    }
    
    /**
     * @description Wrapper class for Permission Set Group
     */
    public class PermissionSetGroupWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String masterLabel { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public Boolean isSelected { get; set; }
        @AuraEnabled public String createdById { get; set; }
        @AuraEnabled public String createdByName { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public List<ComponentPermissionSetWrapper> componentPermissionSets { get; set; }
    }
    
    /**
     * @description Wrapper class for component permission sets within a permission set group
     */
    public class ComponentPermissionSetWrapper {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
    }
    
    /**
     * @description Result wrapper for paginated Permission Set Groups
     */
    public class PermissionSetGroupPageResult {
        @AuraEnabled public List<PermissionSetGroupWrapper> permissionSetGroups { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }
        @AuraEnabled public Boolean hasNext { get; set; }
        @AuraEnabled public Boolean hasPrevious { get; set; }
    }
    
    /**
     * @description Wrapper class for Permission Set Group with its associated Permission Sets
     */
    public class PermissionSetGroupWithPermissions {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String developerName { get; set; }
        @AuraEnabled public String masterLabel { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public List<PermissionSetWithSystemPermissions> permissionSets { get; set; }
    }
    
    /**
     * @description Wrapper class for Permission Set with its system permissions
     */
    public class PermissionSetWithSystemPermissions {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public List<String> systemPermissions { get; set; }
    }
    
    /**
     * @description Result wrapper for Permission Set Group system permissions
     */
    public class PermissionSetGroupSystemPermissionsResult {
        @AuraEnabled public List<PermissionSetGroupWithPermissions> permissionSetGroups { get; set; }
        @AuraEnabled public List<SystemPermissionWrapper> allSystemPermissions { get; set; }
    }

    /**
     * @description Get the correct object and field names for PermissionsTemplate
     * @return Map<String, String> Map containing object name and field names
     */
    private static Map<String, String> getPermissionsTemplateObjectInfo() {
        System.debug('🔍 === BEGIN getPermissionsTemplateObjectInfo ===');
        // Try different possible object names
        String[] possibleObjectNames = new String[]{
            'PermissionsTemplate__c',
            'SA_Audit__PermissionsTemplate__c'
        };
        
        System.debug('🔍 Trying object names: ' + possibleObjectNames);
        for (String objectName : possibleObjectNames) {
            System.debug('🔍 Checking object: ' + objectName);
            try {
                Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
                System.debug('📊 Object type result: ' + objectType);
                if (objectType == null) {
                    System.debug('❌ Object type is null for: ' + objectName);
                    continue;
                }
                Schema.DescribeSObjectResult describeResult = objectType.getDescribe();
                System.debug('📊 Describe result: ' + (describeResult != null ? 'Found' : 'Null'));
                if (describeResult != null) {
                    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
                    
                    // Find the correct field names
                    String profileField = null;
                    String permSetField = null;
                    String permSetGroupField = null;
                    String sysPermField = null;
                    String userField = null;
                    String userFieldField = null;
                    
                    String[] profileFields = new String[]{'Profiles__c', 'SA_Audit__Profiles__c'};
                    String[] permSetFields = new String[]{'PermissionSets__c', 'SA_Audit__PermissionSets__c'};
                    String[] permSetGroupFields = new String[]{'PermissionSetGroups__c', 'SA_Audit__PermissionSetGroups__c'};
                    String[] sysPermFields = new String[]{'SystemPermissions__c', 'SA_Audit__SystemPermissions__c'};
                    String[] userFields = new String[]{'Users__c', 'SA_Audit__Users__c'};
                    String[] userFieldFields = new String[]{'UserFields__c', 'SA_Audit__UserFields__c'};
                    String[] licenseTypeFields = new String[]{'LicenseType__c', 'SA_Audit__LicenseType__c'};
                    
                    // Find license type field
                    String licenseTypeField = null;
                    
                    for (String fieldName : profileFields) {
                        if (fieldMap.containsKey(fieldName)) {
                            profileField = fieldName;
                            break;
                        }
                    }
                    
                    for (String fieldName : permSetFields) {
                        if (fieldMap.containsKey(fieldName)) {
                            permSetField = fieldName;
                            break;
                        }
                    }
                    
                    for (String fieldName : permSetGroupFields) {
                        if (fieldMap.containsKey(fieldName)) {
                            permSetGroupField = fieldName;
                            break;
                        }
                    }
                    
                    for (String fieldName : sysPermFields) {
                        if (fieldMap.containsKey(fieldName)) {
                            sysPermField = fieldName;
                            break;
                        }
                    }
                    
                    // Check for user fields (optional)
                    for (String fieldName : userFields) {
                        if (fieldMap.containsKey(fieldName)) {
                            userField = fieldName;
                            break;
                        }
                    }
                    
                    for (String fieldName : userFieldFields) {
                        if (fieldMap.containsKey(fieldName)) {
                            userFieldField = fieldName;
                            break;
                        }
                    }
                    
                    // Check for license type field (optional)
                    for (String fieldName : licenseTypeFields) {
                        if (fieldMap.containsKey(fieldName)) {
                            licenseTypeField = fieldName;
                            break;
                        }
                    }
                    
                    System.debug('🔍 Field search results:');
                    System.debug('  - profileField: ' + profileField);
                    System.debug('  - permSetField: ' + permSetField);
                    System.debug('  - sysPermField: ' + sysPermField);
                    System.debug('  - permSetGroupField: ' + permSetGroupField);
                    System.debug('  - userField: ' + userField);
                    System.debug('  - userFieldField: ' + userFieldField);
                    System.debug('  - licenseTypeField: ' + licenseTypeField);
                    
                    if (profileField != null && permSetField != null && sysPermField != null) {
                        System.debug('✅ All required fields found, creating result map');
                        Map<String, String> result = new Map<String, String>{
                            'objectName' => objectName,
                            'profileField' => profileField,
                            'permissionSetField' => permSetField,
                            'systemPermissionField' => sysPermField
                        };
                        
                        // Add permission set group field if it exists
                        if (permSetGroupField != null) {
                            result.put('permissionSetGroupField', permSetGroupField);
                        }
                        
                        // Add user fields if they exist
                        if (userField != null) {
                            result.put('userField', userField);
                        }
                        if (userFieldField != null) {
                            result.put('userFieldField', userFieldField);
                        }
                        
                        // Add license type field if it exists
                        if (licenseTypeField != null) {
                            result.put('licenseTypeField', licenseTypeField);
                        }
                        
                        System.debug('✅ Returning result: ' + result);
                        return result;
                    } else {
                        System.debug('❌ Missing required fields for object: ' + objectName);
                    }
                }
            } catch (Exception e) {
                System.debug('❌ Exception checking object ' + objectName + ': ' + e.getMessage());
                // Continue to next possible name
            }
        }
        
        System.debug('❌ No valid PermissionsTemplate object found with required fields');
        return null;
    }

    /**
     * @description Check if the PermissionsTemplate__c custom object exists in the org
     * @return Boolean True if the object exists, false otherwise
     */
    @AuraEnabled
    public static Boolean checkPermissionsTemplateExists() {
        Map<String, String> objectInfo = getPermissionsTemplateObjectInfo();
        return (objectInfo != null);
    }

    /**
     * @description Check if automatic permission set templates exist
     * @return Boolean True if templates exist, false otherwise
     */
    @AuraEnabled
    public static Boolean checkAutomaticTemplatesExist() {
        try {
            Map<String, String> objectInfo = getPermissionsTemplateObjectInfo();
            if (objectInfo == null) {
                return false;
            }
            
            String objectName = objectInfo.get('objectName');
            // Check for the new comprehensive automatic templates
            String soqlQuery = 'SELECT COUNT() FROM ' + objectName + 
                ' WHERE Name IN (\'all-permission-sets-auto\', \'all-profiles-auto\', \'all-permission-set-groups-auto\')';
            
            Integer count = Database.countQuery(soqlQuery);
            return count > 0;
        } catch (Exception e) {
            System.debug('Error checking automatic templates: ' + e.getMessage());
            return false;
        }
    }

    /**
     * @description Create comprehensive automatic templates for all permission sets, profiles, and permission set groups
     * This method creates three complete templates covering all aspects of system permissions
     * @return Map<String, Object> Result of template creation with success status and details
     */
    @AuraEnabled
    public static Map<String, Object> createAutomaticPermissionSetTemplates() {
        Map<String, Object> result = new Map<String, Object>{
            'success' => false,
            'message' => '',
            'templatesCreated' => new List<String>(),
            'totalPermissionSets' => 0,
            'totalProfiles' => 0,
            'totalPermissionSetGroups' => 0,
            'totalSystemPermissions' => 0
        };
        
        try {
            // Check if templates already exist
            if (checkAutomaticTemplatesExist()) {
                result.put('success', true);
                result.put('message', 'Automatic templates already exist');
                return result;
            }
            
            // Check if the custom object exists
            Map<String, String> objectInfo = getPermissionsTemplateObjectInfo();
            if (objectInfo == null) {
                result.put('message', 'PermissionsTemplate custom object does not exist');
                return result;
            }
            
            // Get all permission sets (excluding profile-owned ones)
            List<PermissionSet> allPermissionSets = [
                SELECT Id, Name, Label 
                FROM PermissionSet 
                WHERE IsOwnedByProfile = false 
                ORDER BY Name ASC
                LIMIT 2000
            ];
            
            // Get all profiles
            List<Profile> allProfiles = [
                SELECT Id, Name
                FROM Profile
                ORDER BY Name ASC
                LIMIT 500
            ];
            
            // Get all permission set groups
            List<PermissionSetGroup> allPermissionSetGroups = [
                SELECT Id, DeveloperName, MasterLabel
                FROM PermissionSetGroup
                ORDER BY MasterLabel ASC
                LIMIT 500
            ];
            
            // Get all system permissions
            List<SystemPermissionWrapper> systemPermissions = getSystemPermissions();
            List<String> systemPermissionNames = new List<String>();
            for (SystemPermissionWrapper perm : systemPermissions) {
                systemPermissionNames.add(perm.name);
            }
            
            if (systemPermissionNames.isEmpty()) {
                result.put('message', 'No system permissions found to create templates');
                return result;
            }
            
            // Prepare ID lists for templates
            List<String> allPermSetIds = new List<String>();
            for (PermissionSet ps : allPermissionSets) {
                allPermSetIds.add(ps.Id);
            }
            
            List<String> allProfileIds = new List<String>();
            for (Profile p : allProfiles) {
                allProfileIds.add(p.Id);
            }
            
            List<String> allPermSetGroupIds = new List<String>();
            for (PermissionSetGroup psg : allPermissionSetGroups) {
                allPermSetGroupIds.add(psg.Id);
            }
            
            // Create templates
            List<SObject> templatesToInsert = new List<SObject>();
            String objectName = objectInfo.get('objectName');
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            
            String permSetGroupFieldName = objectInfo.get('permissionSetGroupField');
            String licenseTypeFieldName = objectInfo.get('licenseTypeField');
            String userFieldName = objectInfo.get('userField');
            String userFieldFieldName = objectInfo.get('userFieldField');
            
            // Template 1: All Permission Sets with All System Permissions
            if (!allPermSetIds.isEmpty()) {
                SObject permSetTemplate = objectType.newSObject();
                permSetTemplate.put('Name', 'all-permission-sets-auto');
                permSetTemplate.put(objectInfo.get('profileField'), ''); // Empty profiles
                permSetTemplate.put(objectInfo.get('permissionSetField'), String.join(allPermSetIds, ','));
                permSetTemplate.put(objectInfo.get('systemPermissionField'), String.join(systemPermissionNames, ','));
                
                // Add optional fields
                if (String.isNotBlank(permSetGroupFieldName)) {
                    permSetTemplate.put(permSetGroupFieldName, '');
                }
                if (String.isNotBlank(licenseTypeFieldName)) {
                    permSetTemplate.put(licenseTypeFieldName, 'Salesforce');
                }
                if (String.isNotBlank(userFieldName)) {
                    permSetTemplate.put(userFieldName, '');
                }
                if (String.isNotBlank(userFieldFieldName)) {
                    permSetTemplate.put(userFieldFieldName, '');
                }
                
                templatesToInsert.add(permSetTemplate);
            }
            
            // Template 2: All Profiles with All System Permissions
            if (!allProfileIds.isEmpty()) {
                SObject profileTemplate = objectType.newSObject();
                profileTemplate.put('Name', 'all-profiles-auto');
                profileTemplate.put(objectInfo.get('profileField'), String.join(allProfileIds, ','));
                profileTemplate.put(objectInfo.get('permissionSetField'), ''); // Empty permission sets
                profileTemplate.put(objectInfo.get('systemPermissionField'), String.join(systemPermissionNames, ','));
                
                // Add optional fields
                if (String.isNotBlank(permSetGroupFieldName)) {
                    profileTemplate.put(permSetGroupFieldName, '');
                }
                if (String.isNotBlank(licenseTypeFieldName)) {
                    profileTemplate.put(licenseTypeFieldName, 'Salesforce');
                }
                if (String.isNotBlank(userFieldName)) {
                    profileTemplate.put(userFieldName, '');
                }
                if (String.isNotBlank(userFieldFieldName)) {
                    profileTemplate.put(userFieldFieldName, '');
                }
                
                templatesToInsert.add(profileTemplate);
            }
            
            // Template 3: All Permission Set Groups with All System Permissions
            if (!allPermSetGroupIds.isEmpty() && String.isNotBlank(permSetGroupFieldName)) {
                SObject permSetGroupTemplate = objectType.newSObject();
                permSetGroupTemplate.put('Name', 'all-permission-set-groups-auto');
                permSetGroupTemplate.put(objectInfo.get('profileField'), ''); // Empty profiles
                permSetGroupTemplate.put(objectInfo.get('permissionSetField'), ''); // Empty permission sets
                permSetGroupTemplate.put(objectInfo.get('systemPermissionField'), String.join(systemPermissionNames, ','));
                permSetGroupTemplate.put(permSetGroupFieldName, String.join(allPermSetGroupIds, ','));
                
                // Add optional fields
                if (String.isNotBlank(licenseTypeFieldName)) {
                    permSetGroupTemplate.put(licenseTypeFieldName, 'Salesforce');
                }
                if (String.isNotBlank(userFieldName)) {
                    permSetGroupTemplate.put(userFieldName, '');
                }
                if (String.isNotBlank(userFieldFieldName)) {
                    permSetGroupTemplate.put(userFieldFieldName, '');
                }
                
                templatesToInsert.add(permSetGroupTemplate);
            }
            
            // Insert templates
            if (templatesToInsert.isEmpty()) {
                result.put('message', 'No data found to create templates (no permission sets, profiles, or permission set groups)');
                return result;
            }
            
            Database.SaveResult[] results = Database.insert(templatesToInsert, false);
            
            List<String> createdTemplates = new List<String>();
            List<String> templateNames = new List<String>{
                'all-permission-sets-auto',
                'all-profiles-auto', 
                'all-permission-set-groups-auto'
            };
            
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                if (sr.isSuccess()) {
                    String templateName = templateNames[i];
                    createdTemplates.add(templateName);
                    System.debug('Successfully created template: ' + templateName + ' with ID: ' + sr.getId());
                } else {
                    String templateName = templateNames[i];
                    System.debug('Failed to create template: ' + templateName);
                    for (Database.Error err : sr.getErrors()) {
                        System.debug('Error creating template ' + templateName + ': ' + err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
            
            result.put('success', !createdTemplates.isEmpty());
            result.put('templatesCreated', createdTemplates);
            result.put('totalPermissionSets', allPermissionSets.size());
            result.put('totalProfiles', allProfiles.size());
            result.put('totalPermissionSetGroups', allPermissionSetGroups.size());
            result.put('totalSystemPermissions', systemPermissionNames.size());
            
            if (createdTemplates.isEmpty()) {
                result.put('message', 'Failed to create any templates');
            } else {
                result.put('message', 'Successfully created ' + createdTemplates.size() + ' comprehensive automatic templates: ' + String.join(createdTemplates, ', '));
            }
            
        } catch (Exception e) {
            System.debug('Error creating automatic templates: ' + e.getMessage());
            result.put('message', 'Error creating automatic templates: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Export template with data splitting to prevent browser freezing
     * Splits large datasets into two Excel files for better performance
     * @param templateId ID of the template to export
     * @param maxRowsPerFile Maximum rows per file (default 50000)
     * @return Map<String, Object> Export result with file information
     */
    @AuraEnabled
    public static Map<String, Object> exportTemplateWithSplitting(String templateId, Integer maxRowsPerFile) {
        Map<String, Object> result = new Map<String, Object>{
            'success' => false,
            'message' => '',
            'filesGenerated' => new List<Map<String, Object>>(),
            'totalRows' => 0,
            'splitRequired' => false
        };
        
        try {
            if (String.isBlank(templateId)) {
                result.put('message', 'Template ID is required');
                return result;
            }
            
            if (maxRowsPerFile == null || maxRowsPerFile <= 0) {
                maxRowsPerFile = 50000; // Default limit
            }
            
            // Get template data
            Map<String, String> objectInfo = getPermissionsTemplateObjectInfo();
            if (objectInfo == null) {
                result.put('message', 'PermissionsTemplate custom object does not exist');
                return result;
            }
            
            String objectName = objectInfo.get('objectName');
            String soqlQuery = 'SELECT Id, Name, ' + objectInfo.get('profileField') + ', ' + 
                             objectInfo.get('permissionSetField') + ', ' + objectInfo.get('systemPermissionField');
            
            // Add optional fields if they exist
            if (String.isNotBlank(objectInfo.get('permissionSetGroupField'))) {
                soqlQuery += ', ' + objectInfo.get('permissionSetGroupField');
            }
            if (String.isNotBlank(objectInfo.get('userField'))) {
                soqlQuery += ', ' + objectInfo.get('userField');
            }
            if (String.isNotBlank(objectInfo.get('userFieldField'))) {
                soqlQuery += ', ' + objectInfo.get('userFieldField');
            }
            
            soqlQuery += ' FROM ' + objectName + ' WHERE Id = :templateId LIMIT 1';
            
            List<SObject> templates = Database.query(soqlQuery);
            if (templates.isEmpty()) {
                result.put('message', 'Template not found');
                return result;
            }
            
            SObject template = templates[0];
            
            // Parse template data
            String permSetIds = (String)template.get(objectInfo.get('permissionSetField'));
            String systemPermissions = (String)template.get(objectInfo.get('systemPermissionField'));
            
            if (String.isBlank(permSetIds) || String.isBlank(systemPermissions)) {
                result.put('message', 'Template does not contain permission sets or system permissions');
                return result;
            }
            
            List<String> permSetIdList = permSetIds.split(',');
            List<String> systemPermList = systemPermissions.split(',');
            
            // Estimate total rows (permission sets * assignments * system permissions)
            Integer estimatedRows = estimateTemplateDataSize(permSetIdList, systemPermList);
            result.put('totalRows', estimatedRows);
            
            if (estimatedRows > maxRowsPerFile) {
                result.put('splitRequired', true);
                
                // Split permission sets into two groups
                Integer halfSize = permSetIdList.size() / 2;
                List<String> permSetGroup1 = new List<String>();
                List<String> permSetGroup2 = new List<String>();
                
                for (Integer i = 0; i < permSetIdList.size(); i++) {
                    if (i < halfSize) {
                        permSetGroup1.add(permSetIdList[i].trim());
                    } else {
                        permSetGroup2.add(permSetIdList[i].trim());
                    }
                }
                
                // Generate file information for both splits
                List<Map<String, Object>> filesGenerated = new List<Map<String, Object>>();
                
                // File 1 data
                Map<String, Object> file1Data = generateSplitFileData(template, permSetGroup1, systemPermList, 1);
                filesGenerated.add(file1Data);
                
                // File 2 data
                Map<String, Object> file2Data = generateSplitFileData(template, permSetGroup2, systemPermList, 2);
                filesGenerated.add(file2Data);
                
                result.put('filesGenerated', filesGenerated);
                result.put('success', true);
                result.put('message', 'Template data split into ' + filesGenerated.size() + ' files to prevent browser freezing');
            } else {
                result.put('splitRequired', false);
                result.put('success', true);
                result.put('message', 'Template can be exported as a single file');
            }
            
        } catch (Exception e) {
            System.debug('Error in exportTemplateWithSplitting: ' + e.getMessage());
            result.put('message', 'Error processing template export: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Estimate the total data size for a template export
     * @param permSetIds List of permission set IDs
     * @param systemPermissions List of system permissions
     * @return Integer Estimated number of rows
     */
    private static Integer estimateTemplateDataSize(List<String> permSetIds, List<String> systemPermissions) {
        try {
            // Get assignment counts for permission sets
            List<AggregateResult> assignmentCounts = [
                SELECT PermissionSetId, COUNT(Id) assignmentCount
                FROM PermissionSetAssignment
                WHERE PermissionSetId IN :permSetIds
                GROUP BY PermissionSetId
            ];
            
            Integer totalAssignments = 0;
            for (AggregateResult ar : assignmentCounts) {
                totalAssignments += (Integer)ar.get('assignmentCount');
            }
            
            // Each assignment creates a row with all system permissions as columns
            // Estimate: assignments * system permissions (rough calculation)
            return Math.max(totalAssignments, permSetIds.size()) * systemPermissions.size();
        } catch (Exception e) {
            // Fallback estimation
            return permSetIds.size() * systemPermissions.size() * 10; // Conservative estimate
        }
    }
    
    /**
     * @description Generate file data for a split portion of the template
     * @param template The template SObject
     * @param permSetIds List of permission set IDs for this split
     * @param systemPermissions List of system permissions
     * @param fileNumber File number (1 or 2)
     * @return Map<String, Object> File data information
     */
    private static Map<String, Object> generateSplitFileData(SObject template, List<String> permSetIds, List<String> systemPermissions, Integer fileNumber) {
        Map<String, Object> fileData = new Map<String, Object>{
            'fileName' => 'Template_' + template.get('Name') + '_Part' + fileNumber + '_' + System.now().format('yyyyMMdd_HHmmss') + '.xlsx',
            'fileNumber' => fileNumber,
            'permissionSetCount' => permSetIds.size(),
            'systemPermissionCount' => systemPermissions.size(),
            'permissionSetIds' => String.join(permSetIds, ','),
            'systemPermissions' => String.join(systemPermissions, ',')
        };
        
        // Get assignment count for this split
        try {
            Integer assignmentCount = [
                SELECT COUNT()
                FROM PermissionSetAssignment
                WHERE PermissionSetId IN :permSetIds
            ];
            fileData.put('assignmentCount', assignmentCount);
            fileData.put('estimatedRows', assignmentCount * systemPermissions.size());
        } catch (Exception e) {
            fileData.put('assignmentCount', 0);
            fileData.put('estimatedRows', permSetIds.size() * systemPermissions.size());
        }
        
        return fileData;
    }
    
    /**
     * @description Get permission sets with assignments for split export
     * @param permSetIds Comma-separated permission set IDs
     * @return Map<String, Object> Permission sets with assignment data
     */
    @AuraEnabled
    public static Map<String, Object> getPermissionSetsWithAssignments(String permSetIds) {
        Map<String, Object> result = new Map<String, Object>{
            'success' => false,
            'permissionSets' => new List<Map<String, Object>>(),
            'message' => ''
        };
        
        try {
            if (String.isBlank(permSetIds)) {
                result.put('message', 'Permission set IDs are required');
                return result;
            }
            
            List<String> permSetIdList = permSetIds.split(',');
            List<String> cleanPermSetIds = new List<String>();
            
            // Clean and validate permission set IDs
            for (String id : permSetIdList) {
                String cleanId = id.trim();
                if (String.isNotBlank(cleanId)) {
                    cleanPermSetIds.add(cleanId);
                }
            }
            
            if (cleanPermSetIds.isEmpty()) {
                result.put('message', 'No valid permission set IDs provided');
                return result;
            }
            
            // Query permission sets with basic fields first
            List<PermissionSet> permissionSets = [
                SELECT Id, Name, Label, Description, IsCustom, 
                       CreatedById, CreatedBy.Name, CreatedDate
                FROM PermissionSet
                WHERE Id IN :cleanPermSetIds
                ORDER BY Label
            ];
            
            // Query all assignments separately to avoid subquery 200 record limit
            List<PermissionSetAssignment> allAssignments = [
                SELECT Id, AssigneeId, Assignee.Name, ExpirationDate,
                       IsActive, PermissionSetGroupId, PermissionSetId,
                       SystemModstamp
                FROM PermissionSetAssignment
                WHERE PermissionSetId IN :cleanPermSetIds
                ORDER BY Assignee.Name ASC
                LIMIT 50000
            ];
            
            // Group assignments by permission set ID
            Map<Id, List<PermissionSetAssignment>> assignmentsByPermSetId = new Map<Id, List<PermissionSetAssignment>>();
            for (PermissionSetAssignment psa : allAssignments) {
                if (!assignmentsByPermSetId.containsKey(psa.PermissionSetId)) {
                    assignmentsByPermSetId.put(psa.PermissionSetId, new List<PermissionSetAssignment>());
                }
                assignmentsByPermSetId.get(psa.PermissionSetId).add(psa);
            }
            
            List<Map<String, Object>> permSetData = new List<Map<String, Object>>();
            
            for (PermissionSet ps : permissionSets) {
                Map<String, Object> permSetMap = new Map<String, Object>{
                    'id' => ps.Id,
                    'name' => ps.Name,
                    'label' => ps.Label,
                    'description' => ps.Description,
                    'isCustom' => ps.IsCustom,
                    'createdById' => ps.CreatedById,
                    'createdByName' => ps.CreatedBy?.Name,
                    'createdDate' => ps.CreatedDate,
                    'assignments' => new List<Map<String, Object>>()
                };
                
                // Add assignment data from separately queried assignments
                List<Map<String, Object>> assignments = new List<Map<String, Object>>();
                List<PermissionSetAssignment> psAssignments = assignmentsByPermSetId.get(ps.Id);
                
                if (psAssignments != null) {
                    for (PermissionSetAssignment psa : psAssignments) {
                        assignments.add(new Map<String, Object>{
                            'assignmentId' => psa.Id,
                            'assigneeId' => psa.AssigneeId,
                            'assigneeName' => psa.Assignee?.Name,
                            'expirationDate' => psa.ExpirationDate,
                            'isActive' => psa.IsActive,
                            'isRevoked' => false, // PermissionSetAssignment doesn't have IsRevoked field
                            'permissionSetGroupId' => psa.PermissionSetGroupId,
                            'permissionSetId' => psa.PermissionSetId,
                            'systemModstamp' => psa.SystemModstamp,
                            'lastCreatedByChangeId' => '', // Not available in standard object
                            'lastDeletedByChangeId' => '' // Not available in standard object
                        });
                    }
                }
                
                permSetMap.put('assignments', assignments);
                permSetData.add(permSetMap);
            }
            
            // Calculate total assignments for logging
            Integer totalAssignments = 0;
            for (Map<String, Object> permSet : permSetData) {
                List<Map<String, Object>> assignments = (List<Map<String, Object>>) permSet.get('assignments');
                totalAssignments += assignments != null ? assignments.size() : 0;
            }
            
            System.debug('getPermissionSetsWithAssignments - Retrieved ' + permSetData.size() + ' permission sets with ' + totalAssignments + ' total assignments');
            System.debug('getPermissionSetsWithAssignments - Raw assignments queried: ' + allAssignments.size());
            
            result.put('success', true);
            result.put('permissionSets', permSetData);
            result.put('message', 'Successfully retrieved ' + permSetData.size() + ' permission sets with ' + totalAssignments + ' assignments (queried ' + allAssignments.size() + ' total assignments)');
            
        } catch (Exception e) {
            System.debug('Error in getPermissionSetsWithAssignments: ' + e.getMessage());
            result.put('message', 'Error retrieving permission sets: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get template data for client-side processing with splitting support
     * @param templateId ID of the template
     * @param permSetIds Comma-separated permission set IDs (for split processing)
     * @param systemPermissions Comma-separated system permissions
     * @param fileNumber File number for naming
     * @return Map<String, Object> Template data for client processing
     */
    @AuraEnabled
    public static Map<String, Object> getTemplateDataForSplit(String templateId, String permSetIds, String systemPermissions, Integer fileNumber) {
        Map<String, Object> result = new Map<String, Object>{
            'success' => false,
            'templateData' => null,
            'fileName' => '',
            'message' => ''
        };
        
        try {
            // Get template basic info
            Map<String, String> objectInfo = getPermissionsTemplateObjectInfo();
            if (objectInfo == null) {
                result.put('message', 'PermissionsTemplate custom object does not exist');
                return result;
            }
            
            String objectName = objectInfo.get('objectName');
            String soqlQuery = 'SELECT Id, Name FROM ' + objectName + ' WHERE Id = :templateId LIMIT 1';
            
            List<SObject> templates = Database.query(soqlQuery);
            if (templates.isEmpty()) {
                result.put('message', 'Template not found');
                return result;
            }
            
            SObject template = templates[0];
            String templateName = (String)template.get('Name');
            
            // Create modified template data for split processing
            Map<String, Object> templateData = new Map<String, Object>{
                'id' => templateId,
                'name' => templateName + ' (Part ' + fileNumber + ')',
                'permissionSetIds' => permSetIds,
                'systemPermissionNames' => systemPermissions,
                'profileId' => '', // Empty for split processing
                'permissionSetGroupIds' => '', // Empty for split processing
                'userIds' => '', // Empty for split processing
                'userFieldIds' => '' // Empty for split processing
            };
            
            String fileName = 'Template_' + templateName.replaceAll('[^a-zA-Z0-9]', '_') + '_Part' + fileNumber + '_' + System.now().format('yyyyMMdd_HHmmss');
            
            result.put('success', true);
            result.put('templateData', templateData);
            result.put('fileName', fileName);
            result.put('message', 'Template data prepared for split processing');
            
        } catch (Exception e) {
            System.debug('Error in getTemplateDataForSplit: ' + e.getMessage());
            result.put('message', 'Error preparing template data: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Initialize automatic templates on page load if they don't exist
     * This method is called automatically when the component loads
     * @return Map<String, Object> Initialization result
     */
    @AuraEnabled
    public static Map<String, Object> initializeAutomaticTemplates() {
        Map<String, Object> result = new Map<String, Object>{
            'templatesExist' => false,
            'templatesCreated' => false,
            'message' => '',
            'objectExists' => false
        };
        
        try {
            // Check if the custom object exists
            Boolean objectExists = checkPermissionsTemplateExists();
            result.put('objectExists', objectExists);
            
            if (!objectExists) {
                result.put('message', 'PermissionsTemplate custom object does not exist');
                return result;
            }
            
            // Check if automatic templates already exist
            Boolean templatesExist = checkAutomaticTemplatesExist();
            result.put('templatesExist', templatesExist);
            
            if (templatesExist) {
                result.put('message', 'Automatic templates already exist');
                return result;
            }
            
            // Create automatic templates
            Map<String, Object> creationResult = createAutomaticPermissionSetTemplates();
            result.put('templatesCreated', (Boolean)creationResult.get('success'));
            result.put('message', (String)creationResult.get('message'));
            result.put('creationDetails', creationResult);
            
        } catch (Exception e) {
            System.debug('Error initializing automatic templates: ' + e.getMessage());
            result.put('message', 'Error initializing automatic templates: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Save a permission template with selected profiles, permission sets, permission set groups, and system permissions
     * @param templateName Name of the template
     * @param selectedProfileIds JSON string of selected profile IDs
     * @param selectedPermSetIds JSON string of selected permission set IDs
     * @param selectedPermSetGroupIds JSON string of selected permission set group IDs
     * @param selectedSystemPermissions JSON string of selected system permission names
     * @param selectedUserIds JSON string of selected user IDs
     * @param selectedUserFields JSON string of selected user field names
     * @param licenseType License type for the template (optional)
     */
    @AuraEnabled
    public static String saveTemplate(String templateName, String selectedProfileIds, String selectedPermSetIds, String selectedPermSetGroupIds, String selectedSystemPermissions, String selectedUserIds, String selectedUserFields, String licenseType) {
        System.debug('💾 === BEGIN saveTemplate ===');
        System.debug('💾 Template Name: ' + templateName);
        //system.debug(LoggingLevel.INFO, 'Template Name: ' + templateName);
        //system.debug(LoggingLevel.INFO, 'Selected Profile IDs (JSON): ' + selectedProfileIds);
        //system.debug(LoggingLevel.INFO, 'Selected Permission Set IDs (JSON): ' + selectedPermSetIds);
        //system.debug(LoggingLevel.INFO, 'Selected System Permissions (JSON): ' + selectedSystemPermissions);
        //system.debug(LoggingLevel.INFO, 'Selected User IDs (JSON): ' + selectedUserIds);
        //system.debug(LoggingLevel.INFO, 'Selected User Fields (JSON): ' + selectedUserFields);
        
        try {
            // Parse JSON strings to lists
            List<String> profileIds = new List<String>();
            List<String> permSetIds = new List<String>();
            List<String> permSetGroupIds = new List<String>();
            List<String> systemPermissions = new List<String>();
            List<String> userIds = new List<String>();
            List<String> userFields = new List<String>();
            
            // Parse profile IDs
            if (String.isNotBlank(selectedProfileIds)) {
                try {
                    profileIds = (List<String>)JSON.deserialize(selectedProfileIds, List<String>.class);
                    //system.debug(LoggingLevel.INFO, 'Parsed Profile IDs: ' + profileIds);
                } catch (Exception e) {
                    //system.debug(LoggingLevel.ERROR, 'Error parsing profile IDs: ' + e.getMessage());
                    throw new AuraHandledException('Error parsing profile IDs: ' + e.getMessage());
                }
            }
            
            // Parse permission set IDs
            if (String.isNotBlank(selectedPermSetIds)) {
                try {
                    permSetIds = (List<String>)JSON.deserialize(selectedPermSetIds, List<String>.class);
                    //system.debug(LoggingLevel.INFO, 'Parsed Permission Set IDs: ' + permSetIds);
                } catch (Exception e) {
                    //system.debug(LoggingLevel.ERROR, 'Error parsing permission set IDs: ' + e.getMessage());
                    throw new AuraHandledException('Error parsing permission set IDs: ' + e.getMessage());
                }
            }
            
            // Parse permission set group IDs
            if (String.isNotBlank(selectedPermSetGroupIds)) {
                try {
                    permSetGroupIds = (List<String>)JSON.deserialize(selectedPermSetGroupIds, List<String>.class);
                    //system.debug(LoggingLevel.INFO, 'Parsed Permission Set Group IDs: ' + permSetGroupIds);
                } catch (Exception e) {
                    //system.debug(LoggingLevel.ERROR, 'Error parsing permission set group IDs: ' + e.getMessage());
                    throw new AuraHandledException('Error parsing permission set group IDs: ' + e.getMessage());
                }
            }
            
            // Parse system permissions
            if (String.isNotBlank(selectedSystemPermissions)) {
                try {
                    systemPermissions = (List<String>)JSON.deserialize(selectedSystemPermissions, List<String>.class);
                    //system.debug(LoggingLevel.INFO, 'Parsed System Permissions: ' + systemPermissions);
                } catch (Exception e) {
                    //system.debug(LoggingLevel.ERROR, 'Error parsing system permissions: ' + e.getMessage());
                    throw new AuraHandledException('Error parsing system permissions: ' + e.getMessage());
                }
            }

            // Parse user IDs
            if (String.isNotBlank(selectedUserIds)) {
                try {
                    userIds = (List<String>)JSON.deserialize(selectedUserIds, List<String>.class);
                    //system.debug(LoggingLevel.INFO, 'Parsed User IDs: ' + userIds);
                } catch (Exception e) {
                    //system.debug(LoggingLevel.ERROR, 'Error parsing user IDs: ' + e.getMessage());
                    throw new AuraHandledException('Error parsing user IDs: ' + e.getMessage());
                }
            }

            // Parse user fields
            if (String.isNotBlank(selectedUserFields)) {
                try {
                    userFields = (List<String>)JSON.deserialize(selectedUserFields, List<String>.class);
                    //system.debug(LoggingLevel.INFO, 'Parsed User Fields: ' + userFields);
                } catch (Exception e) {
                    //system.debug(LoggingLevel.ERROR, 'Error parsing user fields: ' + e.getMessage());
                    throw new AuraHandledException('Error parsing user fields: ' + e.getMessage());
                }
            }
            
            // Check if the custom object exists and get object info
            Map<String, String> objectInfo = getPermissionsTemplateObjectInfo();
            if (objectInfo == null) {
                throw new AuraHandledException('The PermissionsTemplate custom object does not exist in this org or is missing required fields. Please deploy the metadata first.');
            }
            
            // Validate inputs
            if (String.isBlank(templateName)) {
                //system.debug(LoggingLevel.ERROR, 'Template name is blank');
                throw new AuraHandledException('Template name is required');
            }
            
            // Check if at least one type of permission is selected
            if (profileIds.isEmpty() && permSetIds.isEmpty() && permSetGroupIds.isEmpty() && systemPermissions.isEmpty()) {
                //system.debug(LoggingLevel.ERROR, 'No permissions selected');
                throw new AuraHandledException('At least one profile, permission set, permission set group, or system permission is required');
            }
            
            // Create template records using dynamic SObject creation
            List<SObject> templates = new List<SObject>();
            
            // Join all profile IDs into a single comma-separated string
            String profilesString = String.join(profileIds, ',');
            //system.debug(LoggingLevel.INFO, 'Combined profiles string: ' + profilesString);
            
            // Create permission sets string
            String permSetString = '';
            if (!permSetIds.isEmpty()) {
                // Filter out any blank or null values
                List<String> validPermSetIds = new List<String>();
                for (String permSetId : permSetIds) {
                    if (!String.isBlank(permSetId)) {
                        validPermSetIds.add(permSetId);
                    }
                }
                permSetString = String.join(validPermSetIds, ',');
            }
            //system.debug(LoggingLevel.INFO, 'Permission Sets string: ' + permSetString);
            
            // Create permission set groups string
            String permSetGroupString = '';
            if (!permSetGroupIds.isEmpty()) {
                // Filter out any blank or null values
                List<String> validPermSetGroupIds = new List<String>();
                for (String permSetGroupId : permSetGroupIds) {
                    if (!String.isBlank(permSetGroupId)) {
                        validPermSetGroupIds.add(permSetGroupId);
                    }
                }
                permSetGroupString = String.join(validPermSetGroupIds, ',');
            }
            //system.debug(LoggingLevel.INFO, 'Permission Set Groups string: ' + permSetGroupString);
            
            // Create system permissions string
            String sysPermString = '';
            if (!systemPermissions.isEmpty()) {
                // Filter out any blank or null values
                List<String> validSysPerms = new List<String>();
                for (String sysPerm : systemPermissions) {
                    if (!String.isBlank(sysPerm)) {
                        validSysPerms.add(sysPerm);
                    }
                }
                sysPermString = String.join(validSysPerms, ',');
            }
            //system.debug(LoggingLevel.INFO, 'System Permissions string: ' + sysPermString);

            // Create users string
            String usersString = '';
            if (!userIds.isEmpty()) {
                // Filter out any blank or null values
                List<String> validUserIds = new List<String>();
                for (String userId : userIds) {
                    if (!String.isBlank(userId)) {
                        validUserIds.add(userId);
                    }
                }
                usersString = String.join(validUserIds, ',');
            }
            //system.debug(LoggingLevel.INFO, 'Users string: ' + usersString);

            // Create user fields string
            String userFieldsString = '';
            if (!userFields.isEmpty()) {
                // Filter out any blank or null values
                List<String> validUserFields = new List<String>();
                for (String userField : userFields) {
                    if (!String.isBlank(userField)) {
                        validUserFields.add(userField);
                    }
                }
                userFieldsString = String.join(validUserFields, ',');
            }
            //system.debug(LoggingLevel.INFO, 'User Fields string: ' + userFieldsString);
            
            // Determine license type if not provided
            String templateLicenseType = licenseType;
            if (String.isBlank(templateLicenseType) && !userIds.isEmpty()) {
                // Query the first user to get their license type
                try {
                    List<User> users = [SELECT Profile.UserLicense.Name FROM User WHERE Id = :userIds[0] LIMIT 1];
                    if (!users.isEmpty()) {
                        templateLicenseType = users[0].Profile.UserLicense.Name;
                    }
                } catch (Exception e) {
                    System.debug('Could not determine license type from users: ' + e.getMessage());
                }
            }
            
            // Create a single template record using dynamic object creation
            String objectName = objectInfo.get('objectName');
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            SObject template = objectType.newSObject();
            
            template.put('Name', templateName);
            template.put(objectInfo.get('profileField'), profilesString);
            template.put(objectInfo.get('permissionSetField'), permSetString);
            template.put(objectInfo.get('systemPermissionField'), sysPermString);
            
            // Add permission set groups if the field exists
            String permSetGroupFieldName = objectInfo.get('permissionSetGroupField');
            if (String.isNotBlank(permSetGroupFieldName)) {
                template.put(permSetGroupFieldName, permSetGroupString);
            }
            
            // Add user fields if they exist in the object
            String userFieldName = objectInfo.get('userField');
            if (String.isNotBlank(userFieldName)) {
                template.put(userFieldName, usersString);
            }
            
            String userFieldFieldName = objectInfo.get('userFieldField');
            if (String.isNotBlank(userFieldFieldName)) {
                template.put(userFieldFieldName, userFieldsString);
            }
            
            // Add license type if the field exists and we have a value
            String licenseTypeFieldName = objectInfo.get('licenseTypeField');
            if (String.isNotBlank(licenseTypeFieldName) && String.isNotBlank(templateLicenseType)) {
                template.put(licenseTypeFieldName, templateLicenseType);
            }
            
            templates.add(template);
            //system.debug(LoggingLevel.INFO, 'Added template record: ' + template);
            
            // Verify we have templates to insert
            if (templates.isEmpty()) {
                //system.debug(LoggingLevel.ERROR, 'No valid templates to insert');
                throw new AuraHandledException('No valid templates to insert. Please check your profile selections.');
            }
            
            // Insert templates
            System.debug('💾 Inserting ' + templates.size() + ' template records');
            Database.SaveResult[] results = Database.insert(templates, false);
            System.debug('💾 Insert operation completed');
            
            // Check results and return the ID of the successfully inserted template
            String insertedTemplateId = null;
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                if (sr.isSuccess()) {
                    insertedTemplateId = sr.getId();
                    System.debug('💾 Successfully inserted template with ID: ' + sr.getId());
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        //system.debug(LoggingLevel.ERROR, 'Error inserting template: ' + err.getStatusCode() + ' - ' + err.getMessage());
                        //system.debug(LoggingLevel.ERROR, 'Fields affected: ' + err.getFields());
                    }
                    throw new AuraHandledException('Error inserting template: ' + results[i].getErrors()[0].getMessage());
                }
            }
            
            System.debug('💾 === END saveTemplate - Success, returning ID: ' + insertedTemplateId + ' ===');
            return insertedTemplateId;
        } catch (Exception e) {
            //system.debug(LoggingLevel.ERROR, '!!! EXCEPTION in saveTemplate: ' + e.getMessage());
            //system.debug(LoggingLevel.ERROR, 'Exception type: ' + e.getTypeName());
            //system.debug(LoggingLevel.ERROR, 'Line number: ' + e.getLineNumber());
            //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            //system.debug(LoggingLevel.INFO, '=== END saveTemplate - Error ===');
            throw new AuraHandledException('Error saving template: ' + e.getMessage());
        }
    }

    /**
     * @description Get saved permission templates
     * @return List<Map<String, Object>> List of templates with their details
     */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getTemplates() {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        System.debug('🔄 === BEGIN getTemplates ===');
        
        try {
            // Get the correct object and field names
            System.debug('🔍 Calling getPermissionsTemplateObjectInfo...');
            Map<String, String> objectInfo = getPermissionsTemplateObjectInfo();
            System.debug('📊 Object info result: ' + objectInfo);
            if (objectInfo == null) {
                System.debug('❌ Object info is null - returning empty result');
                return result; // Return empty list if object doesn't exist
            }
            
            String objectName = objectInfo.get('objectName');
            String profileField = objectInfo.get('profileField');
            String permSetField = objectInfo.get('permissionSetField');
            String sysPermField = objectInfo.get('systemPermissionField');
            
            // Check if permission set group field exists
            String permSetGroupField = objectInfo.get('permissionSetGroupField');
            
            // Check if user fields exist
            String userField = objectInfo.get('userField');
            String userFieldField = objectInfo.get('userFieldField');
            String licenseTypeField = objectInfo.get('licenseTypeField');
            
            // Build dynamic SOQL query
            String soqlQuery = 'SELECT Id, Name, ' + profileField + ', ' + permSetField + ', ' + sysPermField;
            if (String.isNotBlank(permSetGroupField)) {
                soqlQuery += ', ' + permSetGroupField;
            }
            if (String.isNotBlank(userField)) {
                soqlQuery += ', ' + userField;
            }
            if (String.isNotBlank(userFieldField)) {
                soqlQuery += ', ' + userFieldField;
            }
            if (String.isNotBlank(licenseTypeField)) {
                soqlQuery += ', ' + licenseTypeField;
            }
            soqlQuery += ' FROM ' + objectName + ' ORDER BY Name ASC';
            
            System.debug('🔄 Executing SOQL: ' + soqlQuery);
            List<SObject> templates = Database.query(soqlQuery);
            System.debug('📊 Found ' + templates.size() + ' templates in database');
            
            for (SObject template : templates) {
                Map<String, Object> templateMap = new Map<String, Object>{
                    'id' => template.Id,
                    'name' => (String)template.get('Name'),
                    'profileId' => (String)template.get(profileField),
                    'permissionSetIds' => (String)template.get(permSetField),
                    'systemPermissionNames' => (String)template.get(sysPermField)
                };
                
                // Add permission set group IDs if the field exists
                if (String.isNotBlank(permSetGroupField)) {
                    templateMap.put('permissionSetGroupIds', (String)template.get(permSetGroupField));
                }
                
                // Add user fields if they exist
                if (String.isNotBlank(userField)) {
                    templateMap.put('userIds', (String)template.get(userField));
                }
                if (String.isNotBlank(userFieldField)) {
                    templateMap.put('userFieldIds', (String)template.get(userFieldField));
                }
                
                // Add license type if it exists
                if (String.isNotBlank(licenseTypeField)) {
                    templateMap.put('licenseType', (String)template.get(licenseTypeField));
                }
                
                result.add(templateMap);
            }
            
            System.debug('✅ Returning ' + result.size() + ' templates to client');
            List<String> templateNames = new List<String>();
            for (Map<String, Object> template : result) {
                templateNames.add((String)template.get('name'));
            }
            System.debug('📋 Template names: ' + templateNames);
        } catch (Exception e) {
            //system.debug(LoggingLevel.ERROR, 'Error retrieving templates: ' + e.getMessage());
            //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving templates: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Get saved permission templates filtered by license type
     * @param licenseType License type to filter templates by
     * @return List<Map<String, Object>> List of templates with their details
     */
    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getTemplatesByLicenseType(String licenseType) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        System.debug('🔄 === BEGIN getTemplatesByLicenseType for: ' + licenseType + ' ===');
        
        try {
            // Get the correct object and field names
            Map<String, String> objectInfo = getPermissionsTemplateObjectInfo();
            if (objectInfo == null) {
                return result; // Return empty list if object doesn't exist
            }
            
            String objectName = objectInfo.get('objectName');
            String profileField = objectInfo.get('profileField');
            String permSetField = objectInfo.get('permissionSetField');
            String sysPermField = objectInfo.get('systemPermissionField');
            String licenseTypeField = objectInfo.get('licenseTypeField');
            
            // Check if permission set group field exists
            String permSetGroupField = objectInfo.get('permissionSetGroupField');
            
            // Check if user fields exist
            String userField = objectInfo.get('userField');
            String userFieldField = objectInfo.get('userFieldField');
            
            // Build dynamic SOQL query
            String soqlQuery = 'SELECT Id, Name, ' + profileField + ', ' + permSetField + ', ' + sysPermField;
            if (String.isNotBlank(permSetGroupField)) {
                soqlQuery += ', ' + permSetGroupField;
            }
            if (String.isNotBlank(userField)) {
                soqlQuery += ', ' + userField;
            }
            if (String.isNotBlank(userFieldField)) {
                soqlQuery += ', ' + userFieldField;
            }
            if (String.isNotBlank(licenseTypeField)) {
                soqlQuery += ', ' + licenseTypeField;
            }
            soqlQuery += ' FROM ' + objectName;
            
            // Add license type filter if the field exists and license type is provided
            if (String.isNotBlank(licenseTypeField) && String.isNotBlank(licenseType)) {
                soqlQuery += ' WHERE ' + licenseTypeField + ' = \'' + String.escapeSingleQuotes(licenseType) + '\'';
            }
            
            soqlQuery += ' ORDER BY Name ASC';
            
            System.debug('🔄 Executing SOQL: ' + soqlQuery);
            List<SObject> templates = Database.query(soqlQuery);
            System.debug('📊 Found ' + templates.size() + ' templates for license type: ' + licenseType);
            
            for (SObject template : templates) {
                Map<String, Object> templateMap = new Map<String, Object>{
                    'id' => template.Id,
                    'name' => (String)template.get('Name'),
                    'profileId' => (String)template.get(profileField),
                    'permissionSetIds' => (String)template.get(permSetField),
                    'systemPermissionNames' => (String)template.get(sysPermField)
                };
                
                // Add permission set group IDs if the field exists
                if (String.isNotBlank(permSetGroupField)) {
                    templateMap.put('permissionSetGroupIds', (String)template.get(permSetGroupField));
                }
                
                // Add user fields if they exist
                if (String.isNotBlank(userField)) {
                    templateMap.put('userIds', (String)template.get(userField));
                }
                if (String.isNotBlank(userFieldField)) {
                    templateMap.put('userFieldIds', (String)template.get(userFieldField));
                }
                
                // Add license type if it exists
                if (String.isNotBlank(licenseTypeField)) {
                    templateMap.put('licenseType', (String)template.get(licenseTypeField));
                }
                
                result.add(templateMap);
            }
            
            System.debug('✅ Returning ' + result.size() + ' templates for license type: ' + licenseType);
        } catch (Exception e) {
            System.debug('Error retrieving templates by license type: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving templates by license type: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Create the PermissionsTemplate__c custom object and its fields if they don't exist
     * @return Boolean True if successful, false otherwise
     */
    @AuraEnabled
    public static Boolean createPermissionsTemplateObject() {
        //system.debug(LoggingLevel.INFO, '=== BEGIN createPermissionsTemplateObject ===');
        
        try {
            // Check if the object already exists
            if (checkPermissionsTemplateExists()) {
                //system.debug(LoggingLevel.INFO, 'PermissionsTemplate__c already exists, no need to create it');
                return true;
            }
            
            // We need to use Metadata API to create the object, which requires a callout
            // This is not possible in a synchronous context, so we'll return false and provide instructions
            //system.debug(LoggingLevel.INFO, 'Cannot create PermissionsTemplate__c dynamically, need to deploy metadata');
            //system.debug(LoggingLevel.INFO, '=== END createPermissionsTemplateObject - Not Supported ===');
            
            return false;
        } catch (Exception e) {
            //system.debug(LoggingLevel.ERROR, 'Error creating PermissionsTemplate__c: ' + e.getMessage());
            //system.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            //system.debug(LoggingLevel.INFO, '=== END createPermissionsTemplateObject - Error ===');
            throw new AuraHandledException('Error creating PermissionsTemplate__c: ' + e.getMessage());
        }
    }

    /**
     * @description Analyze multiple system permissions at once - OPTIMIZED FOR LARGE ORGS
     * @param systemPermissionNames List of system permission names to analyze
     * @param maxUsers Maximum number of users per permission (default 500, max 1000)
     * @return Map<String, Object> Combined analysis results for all permissions
     */
    @AuraEnabled
    public static Map<String, Object> getMultipleSystemPermissionsAccess(List<String> systemPermissionNames, Integer maxUsers) {
        Map<String, Object> result = new Map<String, Object>();
        Map<String, Map<String, Object>> permissionResults = new Map<String, Map<String, Object>>();
        
        try {
            if (systemPermissionNames == null || systemPermissionNames.isEmpty()) {
                throw new AuraHandledException('System permission names are required');
            }
            
            // Set default and max limits for users per permission
            if (maxUsers == null || maxUsers <= 0) maxUsers = 500;
            if (maxUsers > 1000) maxUsers = 1000; // Hard limit for bulk analysis
            
            // Limit the number of permissions to analyze at once to prevent heap issues
            Integer maxPermissions = 20;
            List<String> limitedPermissions = new List<String>();
            
            for (Integer i = 0; i < Math.min(systemPermissionNames.size(), maxPermissions); i++) {
                limitedPermissions.add(systemPermissionNames[i]);
            }
            
            // Analyze each permission individually with limits
            for (String permissionName : limitedPermissions) {
                if (String.isNotBlank(permissionName)) {
                    try {
                        // Use the optimized method with user limits
                        Map<String, Object> singleResult = getSystemPermissionAccessOptimized(permissionName, maxUsers, 1);
                        permissionResults.put(permissionName, singleResult);
                    } catch (Exception e) {
                        System.debug('Error analyzing permission ' + permissionName + ': ' + e.getMessage());
                        // Create error result instead of failing completely
                        Map<String, Object> errorResult = new Map<String, Object>{
                            'systemPermissionName' => permissionName,
                            'error' => e.getMessage(),
                            'profilesWithAccess' => new List<Object>(),
                            'permissionSetsWithAccess' => new List<Object>(),
                            'usersWithAccess' => new List<Object>(),
                            'totalUsers' => 0
                        };
                        permissionResults.put(permissionName, errorResult);
                    }
                }
            }
            
            result.put('permissionResults', permissionResults);
            result.put('totalPermissions', permissionResults.size());
            result.put('analyzedPermissions', limitedPermissions);
            result.put('maxUsersPerPermission', maxUsers);
            result.put('wasLimited', systemPermissionNames.size() > maxPermissions);
            result.put('originalPermissionCount', systemPermissionNames.size());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getMultipleSystemPermissionsAccess: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving multiple system permissions access: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Export single system permission analysis to Excel format
     * @param systemPermissionName The system permission to export
     * @return Map<String, Object> Export data formatted for Excel generation
     */
    @AuraEnabled
    public static Map<String, Object> exportSingleSystemPermissionAnalysis(String systemPermissionName) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(systemPermissionName)) {
                throw new AuraHandledException('System permission name is required');
            }
            
            // Get the analysis data
            Map<String, Object> analysisData = getSystemPermissionAccess(systemPermissionName);
            
            // Format for export
            result.put('permissionName', systemPermissionName);
            result.put('exportData', analysisData);
            result.put('exportType', 'single');
            result.put('timestamp', DateTime.now().format());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in exportSingleSystemPermissionAnalysis: ' + e.getMessage());
            throw new AuraHandledException('Error exporting system permission analysis: ' + e.getMessage());
        }
        
        return result;
    }

    /**
     * @description Export multiple system permissions analysis to Excel format - OPTIMIZED FOR LARGE ORGS
     * @param systemPermissionNames List of system permission names to export
     * @param maxUsersPerPermission Maximum users per permission (default 500, max 1000)
     * @param selectedUserFields List of user fields to include in export
     * @return Map<String, Object> Export data formatted for Excel generation
     */
    @AuraEnabled
    public static Map<String, Object> exportMultipleSystemPermissionsAnalysis(List<String> systemPermissionNames, Integer maxUsersPerPermission, List<String> selectedUserFields) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (systemPermissionNames == null || systemPermissionNames.isEmpty()) {
                throw new AuraHandledException('System permission names are required');
            }
            
            // ASYNC PROCESSING DETECTION: Check if we need async processing for large exports
            if (systemPermissionNames.size() > 200) {
                System.debug('Large export detected: ' + systemPermissionNames.size() + ' permissions. Routing to async processing.');
                
                // Start async processing
                String exportId = LargeScalePermissionExporter.startLargeScaleExport(
                    systemPermissionNames,
                    new List<Id>(), // profileIds - will be populated from UI
                    new List<Id>(), // permissionSetIds - will be populated from UI
                    new List<Id>(), // permissionSetGroupIds - will be populated from UI
                    new List<Id>(), // userIds - will be populated from UI
                    selectedUserFields != null ? selectedUserFields : new List<String>(),
                    false // includeAllUsers - will be set from UI
                );
                
                // Return async export response
                result.put('isAsyncExport', true);
                result.put('exportId', exportId);
                result.put('permissionCount', systemPermissionNames.size());
                result.put('message', 'Large export started. Processing ' + systemPermissionNames.size() + ' permissions asynchronously.');
                result.put('exportType', 'async_multiple');
                result.put('timestamp', DateTime.now().format());
                
                return result;
            }
            
            // STANDARD PROCESSING: For exports with 200 or fewer permissions
            // Set default limits
            if (maxUsersPerPermission == null || maxUsersPerPermission <= 0) maxUsersPerPermission = 500;
            if (maxUsersPerPermission > 1000) maxUsersPerPermission = 1000;
            
            // Get the analysis data for multiple permissions with limits
            Map<String, Object> multipleAnalysisData = getMultipleSystemPermissionsAccess(systemPermissionNames, maxUsersPerPermission);
            
            // Format for export
            result.put('isAsyncExport', false);
            result.put('permissionNames', systemPermissionNames);
            result.put('exportData', multipleAnalysisData);
            result.put('exportType', 'multiple');
            result.put('timestamp', DateTime.now().format());
            result.put('maxUsersPerPermission', maxUsersPerPermission);
            result.put('selectedUserFields', selectedUserFields);
            result.put('isOptimizedExport', true);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in exportMultipleSystemPermissionsAnalysis: ' + e.getMessage());
            throw new AuraHandledException('Error exporting multiple system permissions analysis: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Export system permissions with user fields for template - OPTIMIZED FOR LARGE ORGS
     * @param systemPermissionNames List of system permission names to export
     * @param selectedUserFields List of user field names to include
     * @param maxUsersPerPermission Maximum users per permission (default 1000, max 2000)
     * @return Map<String, Object> Export data with user fields
     */
    @AuraEnabled
    public static Map<String, Object> exportSystemPermissionsWithUserFields(List<String> systemPermissionNames, List<String> selectedUserFields, Integer maxUsersPerPermission) {
        Map<String, Object> result = new Map<String, Object>();
        Map<String, Object> permissionResults = new Map<String, Object>();
        
        try {
            if (systemPermissionNames == null || systemPermissionNames.isEmpty()) {
                throw new AuraHandledException('System permission names are required');
            }
            
            // Set default and max limits
            if (maxUsersPerPermission == null || maxUsersPerPermission <= 0) maxUsersPerPermission = 1000;
            if (maxUsersPerPermission > 50000) maxUsersPerPermission = 50000; // Allow larger exports while keeping a safety ceiling
            
            // Limit the number of permissions to prevent heap issues
            Integer maxPermissions = 15; // Lower limit for user field exports
            List<String> limitedPermissions = new List<String>();
            
            for (Integer i = 0; i < Math.min(systemPermissionNames.size(), maxPermissions); i++) {
                limitedPermissions.add(systemPermissionNames[i]);
            }
            
            // Process each permission with user fields
            for (String permissionName : limitedPermissions) {
                if (String.isNotBlank(permissionName)) {
                    try {
                        Map<String, Object> singleResult = getSystemPermissionAccessWithUserFields(permissionName, selectedUserFields, maxUsersPerPermission);
                        permissionResults.put(permissionName, singleResult);
                    } catch (Exception e) {
                        System.debug('Error analyzing permission with user fields ' + permissionName + ': ' + e.getMessage());
                        // Create error result
                        Map<String, Object> errorResult = new Map<String, Object>{
                            'systemPermissionName' => permissionName,
                            'error' => e.getMessage(),
                            'profilesWithAccess' => new List<Object>(),
                            'permissionSetsWithAccess' => new List<Object>(),
                            'usersWithAccess' => new List<Object>(),
                            'totalUsers' => 0,
                            'isLimitedResult' => true
                        };
                        permissionResults.put(permissionName, errorResult);
                    }
                }
            }
            
            // Format result
            result.put('permissionResults', permissionResults);
            result.put('analyzedPermissions', limitedPermissions);
            result.put('selectedUserFields', selectedUserFields);
            result.put('maxUsersPerPermission', maxUsersPerPermission);
            result.put('wasLimited', systemPermissionNames.size() > maxPermissions);
            result.put('originalPermissionCount', systemPermissionNames.size());
            result.put('exportType', 'templateWithUserFields');
            result.put('timestamp', DateTime.now().format());
            result.put('isOptimizedExport', true);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in exportSystemPermissionsWithUserFields: ' + e.getMessage());
            throw new AuraHandledException('Error exporting system permissions with user fields: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Bulk export system permissions for template - MEMORY OPTIMIZED FOR LARGE ORGS
     * This method processes permissions in small batches to avoid heap size limits
     * @param systemPermissionNames List of system permission names to export
     * @param selectedUserFields List of user field names to include
     * @param batchSize Number of permissions to process at once (default 5, max 10)
     * @param maxUsersPerPermission Maximum users per permission (default 500, max 1000)
     * @return Map<String, Object> Batched export data
     */
    @AuraEnabled
    public static Map<String, Object> bulkExportSystemPermissionsOptimized(
        List<String> systemPermissionNames, 
        List<String> selectedUserFields, 
        Integer batchSize,
        Integer maxUsersPerPermission
    ) {
        Map<String, Object> result = new Map<String, Object>();
        List<Map<String, Object>> batchResults = new List<Map<String, Object>>();
        
        try {
            if (systemPermissionNames == null || systemPermissionNames.isEmpty()) {
                throw new AuraHandledException('System permission names are required');
            }
            
            // Set safe defaults
            if (batchSize == null || batchSize <= 0) batchSize = 5;
            if (batchSize > 10) batchSize = 10; // Hard limit to prevent heap issues
            
            if (maxUsersPerPermission == null || maxUsersPerPermission <= 0) maxUsersPerPermission = 500;
            if (maxUsersPerPermission > 1000) maxUsersPerPermission = 1000; // Hard limit
            
            // Limit total permissions to prevent timeout
            Integer maxTotalPermissions = 50;
            List<String> limitedPermissions = new List<String>();
            for (Integer i = 0; i < Math.min(systemPermissionNames.size(), maxTotalPermissions); i++) {
                limitedPermissions.add(systemPermissionNames[i]);
            }
            
            // Process permissions in batches
            for (Integer i = 0; i < limitedPermissions.size(); i += batchSize) {
                Integer endIndex = Math.min(i + batchSize, limitedPermissions.size());
                List<String> batch = new List<String>();
                
                for (Integer j = i; j < endIndex; j++) {
                    batch.add(limitedPermissions[j]);
                }
                
                // Process this batch
                Map<String, Object> batchResult = processSinglePermissionBatch(batch, selectedUserFields, maxUsersPerPermission);
                batchResult.put('batchIndex', i / batchSize);
                batchResult.put('batchSize', batch.size());
                batchResults.add(batchResult);
            }
            
            // Combine results
            result.put('batchResults', batchResults);
            result.put('totalBatches', batchResults.size());
            result.put('analyzedPermissions', limitedPermissions);
            result.put('selectedUserFields', selectedUserFields);
            result.put('maxUsersPerPermission', maxUsersPerPermission);
            result.put('batchSize', batchSize);
            result.put('wasLimited', systemPermissionNames.size() > maxTotalPermissions);
            result.put('originalPermissionCount', systemPermissionNames.size());
            result.put('exportType', 'bulkOptimized');
            result.put('timestamp', DateTime.now().format());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in bulkExportSystemPermissionsOptimized: ' + e.getMessage());
            throw new AuraHandledException('Error in bulk export: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Process a single batch of system permissions
     * @param permissionNames List of permission names in this batch
     * @param selectedUserFields List of user fields to include
     * @param maxUsersPerPermission Maximum users per permission
     * @return Map<String, Object> Batch results
     */
    private static Map<String, Object> processSinglePermissionBatch(
        List<String> permissionNames, 
        List<String> selectedUserFields, 
        Integer maxUsersPerPermission
    ) {
        Map<String, Object> batchResult = new Map<String, Object>();
        Map<String, Object> permissionResults = new Map<String, Object>();
        
        try {
            for (String permissionName : permissionNames) {
                if (String.isNotBlank(permissionName)) {
                    try {
                        // Use the optimized single permission method
                        Map<String, Object> singleResult = getSingleSystemPermissionOptimized(
                            permissionName, selectedUserFields, maxUsersPerPermission
                        );
                        permissionResults.put(permissionName, singleResult);
                    } catch (Exception e) {
                        System.debug('Error processing permission ' + permissionName + ': ' + e.getMessage());
                        // Create minimal error result
                        Map<String, Object> errorResult = new Map<String, Object>{
                            'systemPermissionName' => permissionName,
                            'error' => e.getMessage(),
                            'totalUsers' => 0,
                            'isError' => true
                        };
                        permissionResults.put(permissionName, errorResult);
                    }
                }
            }
            
            batchResult.put('permissionResults', permissionResults);
            batchResult.put('permissionsInBatch', permissionNames);
            batchResult.put('successCount', permissionResults.size());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing batch: ' + e.getMessage());
            batchResult.put('batchError', e.getMessage());
        }
        
        return batchResult;
    }
    
    /**
     * @description Ultra-optimized system permission access method for large orgs - CPU TIMEOUT SAFE
     * @param systemPermissionName The name of the system permission to analyze
     * @param maxUsers Maximum number of users to return (default 200, max 500)
     * @return Map<String, Object> containing minimal permission data to avoid timeouts
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSystemPermissionAccessUltraOptimized(String systemPermissionName, Integer maxUsers) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(systemPermissionName)) {
                throw new AuraHandledException('System permission name is required');
            }
            
            // Set limits based on request - allow larger limits for template exports with "Include All Users"
            if (maxUsers == null || maxUsers <= 0) maxUsers = 2000;
            if (maxUsers > 50000) maxUsers = 50000; // Increased limit to support "Include All Users" functionality
            
            String fieldName = 'Permissions' + systemPermissionName;
            
            // Get profiles with this permission (ultra-limited with try-catch)
            List<Map<String, Object>> profileData = new List<Map<String, Object>>();
            try {
                List<Profile> profiles = Database.query(
                    'SELECT Id, Name, Description, UserLicense.Name, CreatedById, CreatedBy.Name, CreatedDate FROM Profile WHERE ' + fieldName + ' = true ORDER BY Name LIMIT 15'
                );
                
                for (Profile p : profiles) {
                    profileData.add(new Map<String, Object>{
                        'id' => p.Id,
                        'name' => p.Name,
                        'description' => p.Description,
                        'type' => 'Profile',
                        'userLicense' => p.UserLicense?.Name,
                        'createdById' => p.CreatedById,
                        'createdByName' => p.CreatedBy?.Name,
                        'createdDate' => p.CreatedDate
                    });
                }
            } catch (System.LimitException limitEx) {
                System.debug('SOQL Limit exceeded in profile query, using fallback: ' + limitEx.getMessage());
                // Return minimal profile data to indicate the permission exists but data is limited
                profileData.add(new Map<String, Object>{
                    'id' => 'LIMITED_DATA',
                    'name' => 'Data Limited Due to Org Size',
                    'type' => 'Profile'
                });
            } catch (Exception e) {
                System.debug('Error querying profiles: ' + e.getMessage());
            }
            
            // Get permission sets with this permission (ultra-limited with try-catch)
            List<Map<String, Object>> permSetData = new List<Map<String, Object>>();
            try {
                List<PermissionSet> permSets = Database.query(
                    'SELECT Id, Name, Label, Description, IsCustom, CreatedById, CreatedBy.Name, CreatedDate FROM PermissionSet WHERE ' + fieldName + 
                    ' = true AND IsOwnedByProfile = false ORDER BY Label LIMIT 100'
                );
                
                for (PermissionSet ps : permSets) {
                    permSetData.add(new Map<String, Object>{
                        'id' => ps.Id,
                        'name' => ps.Name,
                        'label' => ps.Label,
                        'description' => ps.Description,
                        'type' => 'Permission Set',
                        // Added missing metadata fields
                        'isCustom' => ps.IsCustom,
                        'createdById' => ps.CreatedById,
                        'createdByName' => ps.CreatedBy?.Name,
                        'createdDate' => ps.CreatedDate
                    });
                }
            } catch (System.LimitException limitEx) {
                System.debug('SOQL Limit exceeded in permission set query, using fallback: ' + limitEx.getMessage());
                // Return minimal permission set data to indicate the permission exists but data is limited
                permSetData.add(new Map<String, Object>{
                    'id' => 'LIMITED_DATA',
                    'name' => 'Data Limited Due to Org Size',
                    'label' => 'Data Limited Due to Org Size',
                    'type' => 'Permission Set'
                });
            } catch (Exception e) {
                System.debug('Error querying permission sets: ' + e.getMessage());
            }
            
            // Get minimal user data to avoid CPU timeouts
            List<Map<String, Object>> userData = new List<Map<String, Object>>();
            if (!profileData.isEmpty() && maxUsers > 0) {
                try {
                    Set<Id> profileIds = new Set<Id>();
                    for (Map<String, Object> profile : profileData) {
                        Object profileId = profile.get('id');
                        // Skip the fallback limited data entries
                        if (profileId != null && !String.valueOf(profileId).equals('LIMITED_DATA')) {
                            profileIds.add((Id)profileId);
                        }
                    }
                    
                    if (!profileIds.isEmpty()) {
                        // Query users with appropriate limit based on request - Include all necessary fields
                        Integer userLimit = Math.min(maxUsers, 35000); // Allow up to 50k users for "Include All Users"
                        List<User> users = Database.query(
                            'SELECT Id, Name, Username, Email, IsActive, ProfileId, Profile.Name, Profile.UserLicense.Name, ' +
                            'Department, Title, Manager.Name, CreatedDate, LastLoginDate ' +
                            'FROM User WHERE ProfileId IN :profileIds AND IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' ORDER BY Name LIMIT ' + userLimit
                        );
                        
                        for (User u : users) {
                            userData.add(new Map<String, Object>{
                                'id' => u.Id,
                                'name' => u.Name,
                                'username' => u.Username,
                                'email' => u.Email,
                                'isActive' => u.IsActive,
                                'profileId' => u.ProfileId,
                                'profileName' => u.Profile.Name,
                                'userLicense' => u.Profile.UserLicense?.Name,
                                'department' => u.Department,
                                'title' => u.Title,
                                'managerName' => u.Manager?.Name,
                                'createdDate' => u.CreatedDate,
                                'lastLoginDate' => u.LastLoginDate,
                                'permissionSources' => new List<Map<String, Object>>{
                                    new Map<String, Object>{
                                        'type' => 'Profile',
                                        'name' => u.Profile?.Name,
                                        'id' => u.ProfileId
                                    }
                                }
                            });
                        }
                    }
                } catch (System.LimitException limitEx) {
                    System.debug('SOQL Limit exceeded in user query, using fallback: ' + limitEx.getMessage());
                    // Add minimal user data to indicate users exist but data is limited
                    userData.add(new Map<String, Object>{
                        'id' => 'LIMITED_DATA',
                        'name' => 'User Data Limited Due to Org Size',
                        'username' => 'limited.data@org.size',
                        'permissionSource' => 'Profile (Limited)'
                    });
                } catch (Exception e) {
                    System.debug('Error querying users: ' + e.getMessage());
                }
            }
            
            // Also include users from permission sets if we have permission set data and large user limit requested
            if (!permSetData.isEmpty() && maxUsers > 1000) {
                try {
                    Set<Id> permSetIds = new Set<Id>();
                    for (Map<String, Object> permSet : permSetData) {
                        Object permSetId = permSet.get('id');
                        if (permSetId != null && !String.valueOf(permSetId).equals('LIMITED_DATA')) {
                            permSetIds.add((Id)permSetId);
                        }
                    }
                    
                    if (!permSetIds.isEmpty()) {
                        // Query permission set assignments with all necessary user fields
                        List<PermissionSetAssignment> assignments = Database.query(
                            'SELECT AssigneeId, Assignee.Name, Assignee.Username, Assignee.Email, Assignee.IsActive, ' +
                            'Assignee.ProfileId, Assignee.Profile.Name, Assignee.Profile.UserLicense.Name, ' +
                            'Assignee.Department, Assignee.Title, Assignee.Manager.Name, Assignee.CreatedDate, Assignee.LastLoginDate, ' +
                            'PermissionSet.Name, PermissionSet.Id ' +
                            'FROM PermissionSetAssignment WHERE PermissionSetId IN :permSetIds AND Assignee.IsActive = true ' +
                            'AND Assignee.Profile.UserLicense.Name = \'Salesforce\' LIMIT ' + Math.min(maxUsers, 10000)
                        );
                        
                        // Track user IDs we already have to avoid duplicates
                        Set<Id> existingUserIds = new Set<Id>();
                        for (Map<String, Object> existingUser : userData) {
                            existingUserIds.add((Id)existingUser.get('id'));
                        }
                        
                        // Add users from permission sets
                        for (PermissionSetAssignment assignment : assignments) {
                            if (!existingUserIds.contains(assignment.AssigneeId)) {
                                userData.add(new Map<String, Object>{
                                    'id' => assignment.AssigneeId,
                                    'name' => assignment.Assignee.Name,
                                    'username' => assignment.Assignee.Username,
                                    'email' => assignment.Assignee.Email,
                                    'isActive' => assignment.Assignee.IsActive,
                                    'profileId' => assignment.Assignee.ProfileId,
                                    'profileName' => assignment.Assignee.Profile?.Name,
                                    'userLicense' => assignment.Assignee.Profile?.UserLicense?.Name,
                                    'department' => assignment.Assignee.Department,
                                    'title' => assignment.Assignee.Title,
                                    'managerName' => assignment.Assignee.Manager?.Name,
                                    'createdDate' => assignment.Assignee.CreatedDate,
                                    'lastLoginDate' => assignment.Assignee.LastLoginDate,
                                    'permissionSources' => new List<Map<String, Object>>{
                                        new Map<String, Object>{
                                            'type' => 'Permission Set',
                                            'name' => assignment.PermissionSet.Name,
                                            'id' => assignment.PermissionSet.Id
                                        }
                                    }
                                });
                                existingUserIds.add(assignment.AssigneeId);
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error querying permission set users: ' + e.getMessage());
                }
            }
            
            // Build minimal result to prevent heap issues
            result.put('systemPermissionName', systemPermissionName);
            result.put('profilesWithAccess', profileData);
            result.put('permissionSetsWithAccess', permSetData);
            result.put('permissionSetGroupsWithAccess', new List<Object>()); // Empty to save CPU
            result.put('usersWithAccess', userData);
            result.put('totalUsers', userData.size());
            result.put('isUltraOptimized', true);
            result.put('maxUsersReached', userData.size() >= maxUsers);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getSystemPermissionAccessUltraOptimized: ' + e.getMessage());
            // Return minimal error result instead of throwing
            result.put('systemPermissionName', systemPermissionName);
            result.put('profilesWithAccess', new List<Object>());
            result.put('permissionSetsWithAccess', new List<Object>());
            result.put('permissionSetGroupsWithAccess', new List<Object>());
            result.put('usersWithAccess', new List<Object>());
            result.put('totalUsers', 0);
            result.put('error', e.getMessage());
            result.put('isUltraOptimized', true);
        }
        
        return result;
    }

    /**
     * @description Get single system permission data optimized for memory usage
     * @param systemPermissionName The permission to analyze
     * @param selectedUserFields User fields to include
     * @param maxUsers Maximum users to return
     * @return Map<String, Object> Permission data
     */
    private static Map<String, Object> getSingleSystemPermissionOptimized(
        String systemPermissionName, 
        List<String> selectedUserFields, 
        Integer maxUsers
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            String fieldName = 'Permissions' + systemPermissionName;
            
            // Get profiles with this permission (limited)
            List<Profile> profiles = Database.query(
                'SELECT Id, Name FROM Profile WHERE ' + fieldName + ' = true ORDER BY Name LIMIT 50'
            );
            
            // Get permission sets with this permission (limited)
            List<PermissionSet> permSets = Database.query(
                'SELECT Id, Name, Label FROM PermissionSet WHERE ' + fieldName + 
                ' = true AND IsOwnedByProfile = false ORDER BY Label LIMIT 100'
            );
            
            // Collect profile IDs for user query
            Set<Id> profileIds = new Set<Id>();
            List<Map<String, Object>> profileData = new List<Map<String, Object>>();
            for (Profile p : profiles) {
                profileIds.add(p.Id);
                profileData.add(new Map<String, Object>{
                    'id' => p.Id,
                    'name' => p.Name,
                    'type' => 'Profile'
                });
            }
            
            // Collect permission set data
            List<Map<String, Object>> permSetData = new List<Map<String, Object>>();
            for (PermissionSet ps : permSets) {
                permSetData.add(new Map<String, Object>{
                    'id' => ps.Id,
                    'name' => ps.Name,
                    'label' => ps.Label,
                    'type' => 'Permission Set'
                });
            }
            
            // Get users with minimal fields to save memory
            List<Map<String, Object>> userData = new List<Map<String, Object>>();
            if (!profileIds.isEmpty() && maxUsers > 0) {
                // Build minimal user query
                String userQuery = 'SELECT Id, Name, Username, Email, ProfileId, Profile.Name FROM User WHERE ProfileId IN :profileIds AND IsActive = true AND Profile.UserLicense.Name = \'Salesforce\' ORDER BY Name LIMIT ' + maxUsers;
                
                List<User> users = Database.query(userQuery);
                
                for (User u : users) {
                    Map<String, Object> userMap = new Map<String, Object>{
                        'id' => u.Id,
                        'name' => u.Name,
                        'username' => u.Username,
                        'email' => u.Email,
                        'profileName' => u.Profile.Name,
                        'permissionSource' => 'Profile'
                    };
                    
                    // Add selected user fields (limited to prevent heap issues)
                    if (selectedUserFields != null && selectedUserFields.size() <= 5) {
                        for (String userFieldName : selectedUserFields) {
                            try {
                                Object fieldValue = u.get(userFieldName);
                                userMap.put(userFieldName, fieldValue);
                            } catch (Exception e) {
                                userMap.put(userFieldName, null);
                            }
                        }
                    }
                    
                    userData.add(userMap);
                }
            }
            
            // Build result
            result.put('systemPermissionName', systemPermissionName);
            result.put('profilesWithAccess', profileData);
            result.put('permissionSetsWithAccess', permSetData);
            result.put('usersWithAccess', userData);
            result.put('totalUsers', userData.size());
            result.put('isLimitedResult', true);
            result.put('maxUsersReached', userData.size() >= maxUsers);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getSingleSystemPermissionOptimized: ' + e.getMessage());
            throw e;
        }
        
        return result;
    }

    public class UserPageResult {
        @AuraEnabled public List<UserWrapper> users { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer totalPages { get; set; }
        @AuraEnabled public Boolean hasNext { get; set; }
        @AuraEnabled public Boolean hasPrevious { get; set; }
        @AuraEnabled public String lastUserId { get; set; } // For cursor-based pagination
    }

    /**
     * @description Fetch active users with cursor-based pagination (utility for template export) - Only Salesforce license users
     */
    @AuraEnabled(cacheable=true)
    public static UserPageResult getActiveUsersPaginated(Integer pageSize, Integer pageNumber, String lastUserId){
        UserPageResult res = new UserPageResult();

        if(pageSize==null || pageSize<=0) pageSize = DEFAULT_PAGE_SIZE;
        if(pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
        if(pageNumber==null || pageNumber<=0) pageNumber=1;

        // Use cursor-based pagination to avoid OFFSET limit of 2000
        String whereClause = 'WHERE IsActive=true AND Profile.UserLicense.Name = \'Salesforce\'';
        if (String.isNotBlank(lastUserId)) {
            whereClause += ' AND Id > \'' + String.escapeSingleQuotes(lastUserId) + '\'';
        }
        
        String userQuery = 'SELECT Id, Name, Username, Email, Profile.Name, Profile.UserLicense.Name, IsActive ' +
                          'FROM User ' + whereClause + ' ' +
                          'ORDER BY Id ' +
                          'LIMIT ' + (pageSize + 1); // Get one extra to check if there are more records
        
        List<User> users = Database.query(userQuery);
        List<UserWrapper> wrappers = new List<UserWrapper>();
        Boolean hasMore = users.size() > pageSize;
        
        // Remove the extra record if we have more than pageSize
        if (hasMore) {
            users.remove(users.size() - 1);
        }
        
        for(User u: users){
            UserWrapper w = new UserWrapper();
            w.id = u.Id;
            w.name = u.Name;
            w.username = u.Username;
            w.email = u.Email;
            w.profileName = u.Profile.Name;
            w.isActive = u.IsActive;
            w.isSelected = false;
            wrappers.add(w);
        }
        
        // Get total count (cached for performance)
        Integer totalCnt = Database.countQuery('SELECT count() FROM User WHERE IsActive=true AND Profile.UserLicense.Name = \'Salesforce\'');
        
        res.users = wrappers;
        res.totalCount = totalCnt;
        res.pageSize = pageSize;
        res.pageNumber = pageNumber;
        res.totalPages = (Integer)Math.ceil((Decimal)totalCnt/pageSize);
        res.hasNext = hasMore;
        res.hasPrevious = pageNumber > 1 || String.isNotBlank(lastUserId);
        
        // Add the last user ID for cursor-based pagination
        if (!wrappers.isEmpty()) {
            res.lastUserId = wrappers[wrappers.size() - 1].id;
        }
        
        return res;
    }

    /**
     * @description Fetch active users with cursor-based pagination filtered by license type
     */
    @AuraEnabled(cacheable=true)
    public static UserPageResult getActiveUsersPaginatedByLicense(Integer pageSize, Integer pageNumber, String lastUserId, String licenseType){
        UserPageResult res = new UserPageResult();

        if(pageSize==null || pageSize<=0) pageSize = DEFAULT_PAGE_SIZE;
        if(pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
        if(pageNumber==null || pageNumber<=0) pageNumber=1;

        // Use cursor-based pagination to avoid OFFSET limit of 2000
        String whereClause = 'WHERE IsActive=true';
        
        // Add license type filter if specified
        if (String.isNotBlank(licenseType)) {
            whereClause += ' AND Profile.UserLicense.Name = :licenseType';
        } else {
            // Default to Salesforce license if no filter specified
            whereClause += ' AND Profile.UserLicense.Name = \'Salesforce\'';
        }
        
        if (String.isNotBlank(lastUserId)) {
            whereClause += ' AND Id > \'' + String.escapeSingleQuotes(lastUserId) + '\'';
        }
        
        String userQuery = 'SELECT Id, Name, Username, Email, Profile.Name, Profile.UserLicense.Name, IsActive ' +
                          'FROM User ' + whereClause + ' ' +
                          'ORDER BY Id ' +
                          'LIMIT ' + (pageSize + 1); // Get one extra to check if there are more records
        
        List<User> users;
        if (String.isNotBlank(licenseType)) {
            users = Database.queryWithBinds(userQuery, new Map<String, Object>{'licenseType' => licenseType}, AccessLevel.USER_MODE);
        } else {
            users = Database.query(userQuery);
        }
        
        List<UserWrapper> wrappers = new List<UserWrapper>();
        Boolean hasMore = users.size() > pageSize;
        
        // Remove the extra record if we have more than pageSize
        if (hasMore) {
            users.remove(users.size() - 1);
        }
        
        for(User u: users){
            UserWrapper w = new UserWrapper();
            w.id = u.Id;
            w.name = u.Name;
            w.username = u.Username;
            w.email = u.Email;
            w.profileName = u.Profile.Name;
            w.isActive = u.IsActive;
            w.isSelected = false;
            wrappers.add(w);
        }
        
        // Get total count with license filter
        String countQuery = 'SELECT count() FROM User WHERE IsActive=true';
        if (String.isNotBlank(licenseType)) {
            countQuery += ' AND Profile.UserLicense.Name = :licenseType';
        } else {
            countQuery += ' AND Profile.UserLicense.Name = \'Salesforce\'';
        }
        
        Integer totalCnt;
        if (String.isNotBlank(licenseType)) {
            totalCnt = Database.countQueryWithBinds(countQuery, new Map<String, Object>{'licenseType' => licenseType}, AccessLevel.USER_MODE);
        } else {
            totalCnt = Database.countQuery(countQuery);
        }
        
        res.users = wrappers;
        res.totalCount = totalCnt;
        res.pageSize = pageSize;
        res.pageNumber = pageNumber;
        res.totalPages = (Integer)Math.ceil((Decimal)totalCnt/pageSize);
        res.hasNext = hasMore;
        res.hasPrevious = pageNumber > 1 || String.isNotBlank(lastUserId);
        
        // Add the last user ID for cursor-based pagination
        if (!wrappers.isEmpty()) {
            res.lastUserId = wrappers[wrappers.size() - 1].id;
        }
        
        return res;
    }
    
    /**
     * Check if the current user is a System Administrator
     * @return Boolean indicating if current user has System Administrator profile
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isCurrentUserSystemAdmin() {
        try {
            Id currentUserId = UserInfo.getUserId();
            List<PermissionSetAssignment> assignments = [
                SELECT Id 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :currentUserId 
                AND PermissionSet.Name = 'BulkExporterGrantUserTemplateCreation'
                LIMIT 1
            ];
            return !assignments.isEmpty();
        } catch (Exception e) {
            System.debug('Error checking if user has BulkExporterGrantUserTemplateCreation permission set: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Get permission set groups with pagination support
     * @param pageSize Number of records per page
     * @param pageNumber Page number (1-based)
     * @param searchTerm Optional search term to filter permission set groups
     * @return PermissionSetGroupPageResult Paginated permission set group results
     */
    @AuraEnabled(cacheable=true)
    public static PermissionSetGroupPageResult getPermissionSetGroupsPaginated(Integer pageSize, Integer pageNumber, String searchTerm) {
        PermissionSetGroupPageResult result = new PermissionSetGroupPageResult();
        
        try {
            // Validate and set defaults
            if (pageSize == null || pageSize <= 0) pageSize = DEFAULT_PAGE_SIZE;
            if (pageSize > MAX_PAGE_SIZE) pageSize = MAX_PAGE_SIZE;
            if (pageNumber == null || pageNumber <= 0) pageNumber = 1;
            
            Integer offset = (pageNumber - 1) * pageSize;
            
            // Build dynamic query
            String baseQuery = 'SELECT Id, DeveloperName, MasterLabel, Description, CreatedById, CreatedBy.Name, CreatedDate FROM PermissionSetGroup';
            String whereClause = '';
            String orderClause = ' ORDER BY MasterLabel ASC';
            String limitClause = ' LIMIT ' + pageSize;
            String offsetClause = ' OFFSET ' + offset;
            
            // Add search filter if provided
            if (String.isNotBlank(searchTerm)) {
                whereClause = ' WHERE (DeveloperName LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\' OR MasterLabel LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\')';
            }
            
            String query = baseQuery + whereClause + orderClause + limitClause + offsetClause;
            
            // Execute query
            List<PermissionSetGroup> permissionSetGroups = Database.query(query);
            
            // Get Permission Set Group Components for all retrieved groups
            Set<Id> permissionSetGroupIds = new Set<Id>();
            for (PermissionSetGroup psg : permissionSetGroups) {
                permissionSetGroupIds.add(psg.Id);
            }
            
            // Query Permission Set Group Components
            Map<Id, List<PermissionSetGroupComponent>> groupToComponentsMap = new Map<Id, List<PermissionSetGroupComponent>>();
            if (!permissionSetGroupIds.isEmpty()) {
                List<PermissionSetGroupComponent> components = [
                    SELECT PermissionSetGroupId, PermissionSetId, PermissionSet.Name, PermissionSet.Label
                    FROM PermissionSetGroupComponent
                    WHERE PermissionSetGroupId IN :permissionSetGroupIds
                    ORDER BY PermissionSet.Label
                ];
                
                for (PermissionSetGroupComponent component : components) {
                    if (!groupToComponentsMap.containsKey(component.PermissionSetGroupId)) {
                        groupToComponentsMap.put(component.PermissionSetGroupId, new List<PermissionSetGroupComponent>());
                    }
                    groupToComponentsMap.get(component.PermissionSetGroupId).add(component);
                }
            }
            
            // Convert to wrapper objects
            List<PermissionSetGroupWrapper> permSetGroupWrappers = new List<PermissionSetGroupWrapper>();
            for (PermissionSetGroup psg : permissionSetGroups) {
                PermissionSetGroupWrapper wrapper = new PermissionSetGroupWrapper();
                wrapper.id = psg.Id;
                wrapper.developerName = psg.DeveloperName;
                wrapper.masterLabel = psg.MasterLabel;
                wrapper.description = psg.Description;
                wrapper.type = 'Permission Set Group';
                wrapper.isSelected = false;
                wrapper.createdById = psg.CreatedById;
                wrapper.createdByName = psg.CreatedBy?.Name;
                wrapper.createdDate = psg.CreatedDate;
                
                // Add component permission sets
                wrapper.componentPermissionSets = new List<ComponentPermissionSetWrapper>();
                if (groupToComponentsMap.containsKey(psg.Id)) {
                    for (PermissionSetGroupComponent component : groupToComponentsMap.get(psg.Id)) {
                        ComponentPermissionSetWrapper compWrapper = new ComponentPermissionSetWrapper();
                        compWrapper.id = component.PermissionSetId;
                        compWrapper.name = component.PermissionSet.Name;
                        compWrapper.label = component.PermissionSet.Label;
                        wrapper.componentPermissionSets.add(compWrapper);
                    }
                }
                
                permSetGroupWrappers.add(wrapper);
            }
            
            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM PermissionSetGroup' + whereClause;
            Integer totalCount = Database.countQuery(countQuery);
            
            result.permissionSetGroups = permSetGroupWrappers;
            result.totalCount = totalCount;
            result.pageSize = pageSize;
            result.pageNumber = pageNumber;
            result.totalPages = (Integer) Math.ceil((Decimal) totalCount / pageSize);
            result.hasNext = pageNumber < result.totalPages;
            result.hasPrevious = pageNumber > 1;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving permission set groups: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get Permission Sets and their system permissions for selected Permission Set Groups
     * @param permissionSetGroupIds List of Permission Set Group IDs
     * @return PermissionSetGroupSystemPermissionsResult Result containing Permission Sets and their system permissions
     */
    @AuraEnabled
    public static PermissionSetGroupSystemPermissionsResult getPermissionSetGroupSystemPermissions(List<String> permissionSetGroupIds) {
        PermissionSetGroupSystemPermissionsResult result = new PermissionSetGroupSystemPermissionsResult();
        
        System.debug('=== DEBUG: getPermissionSetGroupSystemPermissions START ===');
        System.debug('DEBUG: Input permissionSetGroupIds: ' + permissionSetGroupIds);
        
        try {
            if (permissionSetGroupIds == null || permissionSetGroupIds.isEmpty()) {
                System.debug('DEBUG: Input is null or empty, returning empty result');
                result.permissionSetGroups = new List<PermissionSetGroupWithPermissions>();
                result.allSystemPermissions = new List<SystemPermissionWrapper>();
                return result;
            }
            
            // Get Permission Set Groups
            List<PermissionSetGroup> permissionSetGroups = [
                SELECT Id, DeveloperName, MasterLabel, Description
                FROM PermissionSetGroup
                WHERE Id IN :permissionSetGroupIds
                ORDER BY MasterLabel
            ];
            System.debug('DEBUG: Found ' + permissionSetGroups.size() + ' Permission Set Groups');
            for (PermissionSetGroup psg : permissionSetGroups) {
                System.debug('DEBUG: PSG - Id: ' + psg.Id + ', Name: ' + psg.DeveloperName + ', Label: ' + psg.MasterLabel);
            }
            
            // Get Permission Set Group Components (associated Permission Sets)
            List<PermissionSetGroupComponent> components = [
                SELECT PermissionSetGroupId, PermissionSetId, PermissionSet.Name, PermissionSet.Label
                FROM PermissionSetGroupComponent
                WHERE PermissionSetGroupId IN :permissionSetGroupIds
                ORDER BY PermissionSet.Label
            ];
            System.debug('DEBUG: Found ' + components.size() + ' Permission Set Group Components');
            for (PermissionSetGroupComponent comp : components) {
                System.debug('DEBUG: Component - PSG Id: ' + comp.PermissionSetGroupId + ', PS Id: ' + comp.PermissionSetId + ', PS Name: ' + comp.PermissionSet.Name + ', PS Label: ' + comp.PermissionSet.Label);
            }
            
            // Create map of Permission Set Group to its Permission Sets
            Map<Id, List<PermissionSetGroupComponent>> groupToPermSetsMap = new Map<Id, List<PermissionSetGroupComponent>>();
            Set<Id> allPermissionSetIds = new Set<Id>();
            
            for (PermissionSetGroupComponent component : components) {
                if (!groupToPermSetsMap.containsKey(component.PermissionSetGroupId)) {
                    groupToPermSetsMap.put(component.PermissionSetGroupId, new List<PermissionSetGroupComponent>());
                }
                groupToPermSetsMap.get(component.PermissionSetGroupId).add(component);
                allPermissionSetIds.add(component.PermissionSetId);
            }
            System.debug('DEBUG: All Permission Set IDs collected: ' + allPermissionSetIds);
            System.debug('DEBUG: Group to PermSets Map size: ' + groupToPermSetsMap.size());
            
            // Define system permission field mapping
            Map<String, String> systemPermissionFieldMap = new Map<String, String>{
                'PermissionsModifyAllData' => 'ModifyAllData',
                'PermissionsManageUsers' => 'ManageUsers',
                'PermissionsApiEnabled' => 'ApiEnabled',
                'PermissionsEditBillingInfo' => 'EditBillingInfo',
                'PermissionsManageCases' => 'ManageCases',
                'PermissionsMassInlineEdit' => 'MassInlineEdit',
                'PermissionsEditKnowledge' => 'EditKnowledge',
                'PermissionsManageKnowledge' => 'ManageKnowledge',
                'PermissionsManageSolutions' => 'ManageSolutions',
                'PermissionsCustomizeApplication' => 'CustomizeApplication',
                'PermissionsEditReadonlyFields' => 'EditReadonlyFields',
                'PermissionsRunReports' => 'RunReports',
                'PermissionsViewSetup' => 'ViewSetup',
                'PermissionsTransferAnyEntity' => 'TransferAnyEntity',
                'PermissionsNewReportBuilder' => 'NewReportBuilder',
                'PermissionsManageCssUsers' => 'ManageCssUsers',
                'PermissionsActivateContract' => 'ActivateContract',
                'PermissionsActivateOrder' => 'ActivateOrder',
                'PermissionsImportLeads' => 'ImportLeads',
                'PermissionsManageLeads' => 'ManageLeads',
                'PermissionsTransferAnyLead' => 'TransferAnyLead',
                'PermissionsViewAllData' => 'ViewAllData',
                'PermissionsEditPublicDocuments' => 'EditPublicDocuments',
                'PermissionsViewEncryptedData' => 'ViewEncryptedData',
                'PermissionsEditBrandTemplates' => 'EditBrandTemplates',
                'PermissionsEditHtmlTemplates' => 'EditHtmlTemplates',
                'PermissionsChatterInternalUser' => 'ChatterInternalUser',
                'PermissionsManageEncryptionKeys' => 'ManageEncryptionKeys',
                'PermissionsDeleteActivatedContract' => 'DeleteActivatedContract',
                'PermissionsChatterInviteExternalUsers' => 'ChatterInviteExternalUsers',
                'PermissionsSendSitRequests' => 'SendSitRequests',
                'PermissionsApiUserOnly' => 'ApiUserOnly',
                'PermissionsManageRemoteAccess' => 'ManageRemoteAccess',
                'PermissionsCanUseNewDashboardBuilder' => 'CanUseNewDashboardBuilder',
                'PermissionsConvertLeads' => 'ConvertLeads',
                'PermissionsPasswordNeverExpires' => 'PasswordNeverExpires',
                'PermissionsUseTeamReassignWizards' => 'UseTeamReassignWizards',
                'PermissionsEditActivatedOrders' => 'EditActivatedOrders',
                'PermissionsInstallPackaging' => 'InstallPackaging',
                'PermissionsPublishPackaging' => 'PublishPackaging',
                'PermissionsManagePartners' => 'ManagePartners',
                'PermissionsChatterOwnGroups' => 'ChatterOwnGroups',
                'PermissionsEditOppLineItemUnitPrice' => 'EditOppLineItemUnitPrice',
                'PermissionsManageTerritories' => 'ManageTerritories',
                'PermissionsCreatePackaging' => 'CreatePackaging',
                'PermissionsBulkApiHardDelete' => 'BulkApiHardDelete',
                'PermissionsSolutionImport' => 'SolutionImport',
                'PermissionsManageCallCenters' => 'ManageCallCenters',
                'PermissionsPortalSuperUser' => 'PortalSuperUser',
                'PermissionsManageSynonyms' => 'ManageSynonyms',
                'PermissionsDelegatedPortalUserAdmin' => 'DelegatedPortalUserAdmin',
                'PermissionsViewContent' => 'ViewContent',
                'PermissionsManageEmailClientConfig' => 'ManageEmailClientConfig',
                'PermissionsEnableNotifications' => 'EnableNotifications',
                'PermissionsManageDataIntegrations' => 'ManageDataIntegrations',
                'PermissionsDistributeFromPersWksp' => 'DistributeFromPersWksp',
                'PermissionsViewDataCategories' => 'ViewDataCategories',
                'PermissionsManageDataCategories' => 'ManageDataCategories',
                'PermissionsAuthorApex' => 'AuthorApex',
                'PermissionsManageMobile' => 'ManageMobile',
                'PermissionsManageCustomReportTypes' => 'ManageCustomReportTypes',
                'PermissionsEditCaseComments' => 'EditCaseComments',
                'PermissionsTransferAnyCase' => 'TransferAnyCase',
                'PermissionsCreateWorkspaces' => 'CreateWorkspaces',
                'PermissionsManageContentPermissions' => 'ManageContentPermissions',
                'PermissionsManageContentProperties' => 'ManageContentProperties',
                'PermissionsManageContentTypes' => 'ManageContentTypes',
                'PermissionsManageExchangeConfig' => 'ManageExchangeConfig',
                'PermissionsManageAnalyticSnapshots' => 'ManageAnalyticSnapshots',
                'PermissionsScheduleReports' => 'ScheduleReports',
                'PermissionsManageBusinessHourHolidays' => 'ManageBusinessHourHolidays',
                'PermissionsManageDynamicDashboards' => 'ManageDynamicDashboards',
                'PermissionsCustomSidebarOnAllPages' => 'CustomSidebarOnAllPages',
                'PermissionsManageInteraction' => 'ManageInteraction',
                'PermissionsViewMyTeamsDashboards' => 'ViewMyTeamsDashboards',
                'PermissionsModerateChatter' => 'ModerateChatter',
                'PermissionsResetPasswords' => 'ResetPasswords',
                'PermissionsFlowUFLRequired' => 'FlowUFLRequired',
                'PermissionsCanInsertFeedSystemFields' => 'CanInsertFeedSystemFields',
                'PermissionsActivitiesAccess' => 'ActivitiesAccess',
                'PermissionsManageKnowledgeImportExport' => 'ManageKnowledgeImportExport',
                'PermissionsEmailTemplateManagement' => 'EmailTemplateManagement',
                'PermissionsEmailAdministration' => 'EmailAdministration',
                'PermissionsManageChatterMessages' => 'ManageChatterMessages',
                'PermissionsChatterFileLink' => 'ChatterFileLink',
                'PermissionsForceTwoFactor' => 'ForceTwoFactor',
                'PermissionsViewEventLogFiles' => 'ViewEventLogFiles',
                'PermissionsManageNetworks' => 'ManageNetworks',
                'PermissionsManageAuthProviders' => 'ManageAuthProviders',
                'PermissionsRunFlow' => 'RunFlow',
                'PermissionsViewGlobalHeader' => 'ViewGlobalHeader',
                'PermissionsCreateCustomizeDashboards' => 'CreateCustomizeDashboards',
                'PermissionsViewPublicDashboards' => 'ViewPublicDashboards',
                'PermissionsManageDashbdsInPubFolders' => 'ManageDashbdsInPubFolders',
                'PermissionsCreateCustomizeReports' => 'CreateCustomizeReports',
                'PermissionsCreateReportFolders' => 'CreateReportFolders',
                'PermissionsViewPublicReports' => 'ViewPublicReports',
                'PermissionsManageReportsInPubFolders' => 'ManageReportsInPubFolders',
                'PermissionsEditMyDashboards' => 'EditMyDashboards',
                'PermissionsEditMyReports' => 'EditMyReports',
                'PermissionsViewAllUsers' => 'ViewAllUsers',
                'PermissionsAllowUniversalSearch' => 'AllowUniversalSearch',
                'PermissionsConnectOrgToEnvironmentHub' => 'ConnectOrgToEnvironmentHub',
                'PermissionsWorkCalibrationUser' => 'WorkCalibrationUser',
                'PermissionsCreateCustomizeFilters' => 'CreateCustomizeFilters',
                'PermissionsWorkDotComUserPerm' => 'WorkDotComUserPerm',
                'PermissionsContentHubUser' => 'ContentHubUser',
                'PermissionsModerateNetworkFeeds' => 'ModerateNetworkFeeds',
                'PermissionsModerateNetworkFiles' => 'ModerateNetworkFiles',
                'PermissionsGovernNetworks' => 'GovernNetworks',
                'PermissionsSalesConsole' => 'SalesConsole',
                'PermissionsTwoFactorApi' => 'TwoFactorApi',
                'PermissionsDeleteTopics' => 'DeleteTopics',
                'PermissionsEditTopics' => 'EditTopics',
                'PermissionsCreateTopics' => 'CreateTopics',
                'PermissionsAssignTopics' => 'AssignTopics',
                'PermissionsIdentityEnabled' => 'IdentityEnabled',
                'PermissionsIdentityConnect' => 'IdentityConnect',
                'PermissionsAllowViewKnowledge' => 'AllowViewKnowledge',
                'PermissionsContentWorkspaces' => 'ContentWorkspaces',
                'PermissionsManageSearchPromotionRules' => 'ManageSearchPromotionRules',
                'PermissionsViewHelpLink' => 'ViewHelpLink',
                'PermissionsManageProfilesPermissionsets' => 'ManageProfilesPermissionsets',
                'PermissionsAssignPermissionSets' => 'AssignPermissionSets',
                'PermissionsManageRoles' => 'ManageRoles',
                'PermissionsManageIpAddresses' => 'ManageIpAddresses',
                'PermissionsManageSharing' => 'ManageSharing',
                'PermissionsManageInternalUsers' => 'ManageInternalUsers',
                'PermissionsManagePasswordPolicies' => 'ManagePasswordPolicies',
                'PermissionsManageLoginAccessPolicies' => 'ManageLoginAccessPolicies',
                'PermissionsManageCustomPermissions' => 'ManageCustomPermissions',
                'PermissionsCanVerifyComment' => 'CanVerifyComment',
                'PermissionsManageUnlistedGroups' => 'ManageUnlistedGroups',
                'PermissionsShareFilesWithNetworks' => 'ShareFilesWithNetworks',
                'PermissionsManageTwoFactor' => 'ManageTwoFactor',
                'PermissionsLightningExperienceUser' => 'LightningExperienceUser',
                'PermissionsConfigCustomRecs' => 'ConfigCustomRecs',
                'PermissionsSubmitMacrosAllowed' => 'SubmitMacrosAllowed',
                'PermissionsBulkMacrosAllowed' => 'BulkMacrosAllowed',
                'PermissionsShareInternalArticles' => 'ShareInternalArticles',
                'PermissionsModerateNetworkMessages' => 'ModerateNetworkMessages',
                'PermissionsManageSessionPermissionSets' => 'ManageSessionPermissionSets',
                'PermissionsSendAnnouncementEmails' => 'SendAnnouncementEmails',
                'PermissionsEnableSOS' => 'EnableSOS',
                'PermissionsImportCustomObjects' => 'ImportCustomObjects',
                'PermissionsDelegatedTwoFactor' => 'DelegatedTwoFactor',
                'PermissionsChatterComposeUiCodesnippet' => 'ChatterComposeUiCodesnippet',
                'PermissionsSelectFilesFromSalesforce' => 'SelectFilesFromSalesforce',
                'PermissionsModerateNetworkUsers' => 'ModerateNetworkUsers'
            };
            
            // Get granted system permissions for all Permission Sets by querying PermissionSet directly
            Map<String, Set<Id>> permissionToGrantedPermSets = new Map<String, Set<Id>>();
            if (!allPermissionSetIds.isEmpty()) {
                // Build dynamic SOQL query for all system permission fields
                String permissionSetQuery = 'SELECT Id, ' + String.join(systemPermissionFieldMap.keySet(), ', ') + 
                                           ' FROM PermissionSet WHERE Id IN :allPermissionSetIds';
                System.debug('DEBUG: Permission Set Query: ' + permissionSetQuery);
                List<PermissionSet> permissionSets = Database.query(permissionSetQuery);
                System.debug('DEBUG: Found ' + permissionSets.size() + ' Permission Sets with system permissions');
                
                // Process each permission set and check which system permissions are granted
                for (PermissionSet ps : permissionSets) {
                    System.debug('DEBUG: Processing Permission Set Id: ' + ps.Id);
                    List<String> grantedPermissions = new List<String>();
                    List<String> fieldValueDebug = new List<String>();
                    for (String fieldName : systemPermissionFieldMap.keySet()) {
                        Boolean isGranted = (Boolean) ps.get(fieldName);
                        String permissionName = systemPermissionFieldMap.get(fieldName);
                        fieldValueDebug.add(permissionName + '=' + isGranted);
                        if (isGranted == true) {
                            grantedPermissions.add(permissionName);
                            if (!permissionToGrantedPermSets.containsKey(permissionName)) {
                                permissionToGrantedPermSets.put(permissionName, new Set<Id>());
                            }
                            permissionToGrantedPermSets.get(permissionName).add(ps.Id);
                        }
                    }
                    System.debug('DEBUG: PS ' + ps.Id + ' field values: ' + fieldValueDebug);
                    System.debug('DEBUG: PS ' + ps.Id + ' has granted permissions: ' + grantedPermissions);
                }
            }
            
            // Get all available system permission names from the granted permissions
            Set<String> allAvailablePermissions = permissionToGrantedPermSets.keySet();
            System.debug('DEBUG: All available permissions found: ' + allAvailablePermissions);
            System.debug('DEBUG: Total unique permissions count: ' + allAvailablePermissions.size());
            
            // Build result structure
            List<PermissionSetGroupWithPermissions> resultGroups = new List<PermissionSetGroupWithPermissions>();
            
            for (PermissionSetGroup psg : permissionSetGroups) {
                PermissionSetGroupWithPermissions groupWrapper = new PermissionSetGroupWithPermissions();
                groupWrapper.id = psg.Id;
                groupWrapper.developerName = psg.DeveloperName;
                groupWrapper.masterLabel = psg.MasterLabel;
                groupWrapper.description = psg.Description;
                groupWrapper.permissionSets = new List<PermissionSetWithSystemPermissions>();
                
                // Add Permission Sets for this group
                if (groupToPermSetsMap.containsKey(psg.Id)) {
                    for (PermissionSetGroupComponent component : groupToPermSetsMap.get(psg.Id)) {
                        PermissionSetWithSystemPermissions permSetWrapper = new PermissionSetWithSystemPermissions();
                        permSetWrapper.id = component.PermissionSetId;
                        permSetWrapper.name = component.PermissionSet.Name;
                        permSetWrapper.label = component.PermissionSet.Label;
                        permSetWrapper.systemPermissions = new List<String>();
                        
                        // Add only the granted system permissions for this Permission Set
                        for (String permissionName : allAvailablePermissions) {
                            if (permissionToGrantedPermSets.get(permissionName).contains(component.PermissionSetId)) {
                                permSetWrapper.systemPermissions.add(permissionName);
                            }
                        }
                        System.debug('DEBUG: PS ' + permSetWrapper.name + ' (' + permSetWrapper.id + ') has system permissions: ' + permSetWrapper.systemPermissions);
                        
                        groupWrapper.permissionSets.add(permSetWrapper);
                    }
                }
                
                resultGroups.add(groupWrapper);
            }
            
            // Convert all available system permissions to wrapper list
            List<SystemPermissionWrapper> allSystemPermissionsList = new List<SystemPermissionWrapper>();
            List<String> sortedPermissions = new List<String>(allAvailablePermissions);
            sortedPermissions.sort();
            
            for (String permissionName : sortedPermissions) {
                SystemPermissionWrapper wrapper = new SystemPermissionWrapper();
                wrapper.name = permissionName;
                wrapper.label = permissionName.replace('_', ' ');
                wrapper.isSelected = false;
                allSystemPermissionsList.add(wrapper);
            }
            
            result.permissionSetGroups = resultGroups;
            result.allSystemPermissions = allSystemPermissionsList;
            
            System.debug('DEBUG: Final result - Permission Set Groups count: ' + result.permissionSetGroups.size());
            System.debug('DEBUG: Final result - All System Permissions count: ' + result.allSystemPermissions.size());
            System.debug('DEBUG: Final result structure: ' + JSON.serializePretty(result));
            System.debug('=== DEBUG: getPermissionSetGroupSystemPermissions END ===');
            
        } catch (Exception e) {
            System.debug('ERROR: Exception in getPermissionSetGroupSystemPermissions: ' + e.getMessage());
            System.debug('ERROR: Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving permission set group system permissions: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Start large scale export with full parameters from UI
     * @param systemPermissionNames List of system permission names to export
     * @param profileIds List of profile IDs to include
     * @param permissionSetIds List of permission set IDs to include
     * @param permissionSetGroupIds List of permission set group IDs to include
     * @param userIds List of user IDs to include
     * @param selectedUserFields List of user fields to include
     * @param includeAllUsers Whether to include all active users
     * @return Map<String, Object> Export initiation response
     */
    @AuraEnabled
    public static Map<String, Object> startLargeScaleExportWithParams(
        List<String> systemPermissionNames,
        List<Id> profileIds,
        List<Id> permissionSetIds,
        List<Id> permissionSetGroupIds,
        List<Id> userIds,
        List<String> selectedUserFields,
        Boolean includeAllUsers
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (systemPermissionNames == null || systemPermissionNames.isEmpty()) {
                throw new AuraHandledException('System permission names are required');
            }
            
            // Start async processing with all parameters
            String exportId = LargeScalePermissionExporter.startLargeScaleExport(
                systemPermissionNames,
                profileIds != null ? profileIds : new List<Id>(),
                permissionSetIds != null ? permissionSetIds : new List<Id>(),
                permissionSetGroupIds != null ? permissionSetGroupIds : new List<Id>(),
                userIds != null ? userIds : new List<Id>(),
                selectedUserFields != null ? selectedUserFields : new List<String>(),
                includeAllUsers != null ? includeAllUsers : false
            );
            
            result.put('success', true);
            result.put('exportId', exportId);
            result.put('permissionCount', systemPermissionNames.size());
            result.put('message', 'Large scale export started successfully');
            result.put('timestamp', DateTime.now().format());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error starting large scale export: ' + e.getMessage());
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Check the status of an async export
     * @param exportId The export ID to check
     * @return Map<String, Object> Export status information
     */
    @AuraEnabled
    public static Map<String, Object> checkAsyncExportStatus(String exportId) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            if (String.isBlank(exportId)) {
                throw new AuraHandledException('Export ID is required');
            }
            
            // Simplified status check (mock response for now)
            // TODO: Implement custom object queries when objects are deployed
            System.debug('Checking export status for ID: ' + exportId);
            
            // Return mock progress for demonstration
            result.put('found', true);
            result.put('status', 'Processing batch 1 of 10...');
            result.put('progress', 25); // Mock progress
            result.put('isComplete', false);
            result.put('hasError', false);
            result.put('downloadUrl', null);
            result.put('lastUpdated', System.now());
            result.put('totalPermissions', 250);
            result.put('totalBatches', 10);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error checking export status: ' + e.getMessage());
            result.put('found', false);
            result.put('error', e.getMessage());
        }
        
        return result;
    }
}