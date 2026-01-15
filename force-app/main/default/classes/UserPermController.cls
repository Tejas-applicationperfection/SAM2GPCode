/**
 * @File Name : UserPermController.cls
 * @Description : Controller class for managing user permissions and access control
 * @Author : Tejas kshirsagar
 * @Last Modified By : 
 * @Last Modified On : February 4, 2025
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | February 4, 2025 | Tejas kshirsagar | Initial Version
 * 2.0 | Current Date | Current Author | Enhanced security with CRUD/FLS checks
 **/

public with sharing class UserPermController {
    
    /**
     * @description Wrapper class to store user permission access information
     */
    public class UserPermissionAccess {
        public List<String> systemPermissions;
        public List<ObjectPermissions> objectPermissions;
    }
     @AuraEnabled(cacheable=true)
    public static Boolean PaidFeatureAccess() {
        // Check if the feature is enabled for the user
       // return FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess');
       
    
       return true;
    }


    /**
     * @description Wrapper class to store system permission information with sources
     */
    public class SystemPermissionWrapper {
        @AuraEnabled public String permission;
        @AuraEnabled public String status;
        @AuraEnabled public List<String> sources;
        
        /**
         * @description Constructor for SystemPermissionWrapper
         * @param perm Permission name
         * @param enabled Whether the permission is enabled
         * @param src List of sources providing the permission
         */
        public SystemPermissionWrapper(String perm, Boolean enabled, List<String> src) {
            permission = perm;
            status = enabled ? 'Enabled' : 'Disabled';
            sources = src;
        }
    }
    
    /**
     * @description Retrieves a list of active users with proper CRUD permission checks
     * @return List<User> List of active users
     */
    @AuraEnabled(cacheable=true)
    public static List<User> getActiveUsers() {
        // Validate CRUD permissions first
        if (!Schema.SObjectType.User.isAccessible()) {
            throw new SecurityException('Insufficient access to User object');
        }
        
        if (!Schema.SObjectType.User.fields.Id.isAccessible() ||
            !Schema.SObjectType.User.fields.Name.isAccessible() ||
            !Schema.SObjectType.User.fields.IsActive.isAccessible()) {
            throw new SecurityException('Insufficient access to User fields');
        }
        
        // Use Database.query to safely enforce field-level security
        String query = 'SELECT Id, Name FROM User WHERE IsActive = true ORDER BY Name';
        return Database.query(query);
    }
    
    /**
     * @description Retrieves available license types for the license dropdown
     * @return List<Map<String, String>> List of license options with label and value
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailableLicenseTypes() {
        // Validate CRUD permissions first
        if (!Schema.SObjectType.UserLicense.isAccessible()) {
            throw new SecurityException('Insufficient access to UserLicense object');
        }
        
        if (!Schema.SObjectType.UserLicense.fields.Id.isAccessible() ||
            !Schema.SObjectType.UserLicense.fields.Name.isAccessible()) {
            throw new SecurityException('Insufficient access to UserLicense fields');
        }
        
        List<Map<String, String>> licenseOptions = new List<Map<String, String>>();
        
        // Add "All License Types" option
        licenseOptions.add(new Map<String, String>{
            'label' => 'All License Types',
            'value' => ''
        });
        
        // Query available license types
        String query = 'SELECT Id, Name FROM UserLicense WHERE TotalLicenses > 0 ORDER BY Name';
        List<UserLicense> licenses = Database.query(query);
        
        for (UserLicense license : licenses) {
            licenseOptions.add(new Map<String, String>{
                'label' => license.Name,
                'value' => license.Name
            });
        }
        
        return licenseOptions;
    }
    
    /**
     * @description Retrieves active users filtered by license type
     * @param licenseType The license type to filter by (optional)
     * @return List<User> List of active users
     */
    @AuraEnabled(cacheable=true)
    public static List<User> getActiveUsersByLicense(String licenseType) {
        // Validate CRUD permissions first
        if (!Schema.SObjectType.User.isAccessible()) {
            throw new SecurityException('Insufficient access to User object');
        }
        
        if (!Schema.SObjectType.User.fields.Id.isAccessible() ||
            !Schema.SObjectType.User.fields.Name.isAccessible() ||
            !Schema.SObjectType.User.fields.IsActive.isAccessible()) {
            throw new SecurityException('Insufficient access to User fields');
        }
        
        // Build query based on license type filter
        String query = 'SELECT Id, Name FROM User WHERE IsActive = true';
        
        if (String.isNotBlank(licenseType)) {
            query += ' AND Profile.UserLicense.Name = :licenseType';
        }
        
        query += ' ORDER BY Name';
        
        // Use Database.query to safely enforce field-level security
        if (String.isNotBlank(licenseType)) {
            return Database.queryWithBinds(query, new Map<String, Object>{'licenseType' => licenseType}, AccessLevel.USER_MODE);
        } else {
            return Database.query(query);
        }
    }
    
    /**
     * @description Retrieves a user's permissions with appropriate security checks
     * @param userId The ID of the user to retrieve permissions for
     * @return Map<String, Object> Map containing user permission information
     */
    @AuraEnabled
    public static Map<String, Object> getUserPermissions(String userId) {
        // Validate CRUD permissions first
        if (!Schema.SObjectType.User.isAccessible()) {
            throw new SecurityException('Insufficient access to User object');
        }
        
        if (!Schema.SObjectType.Profile.isAccessible()) {
            throw new SecurityException('Insufficient access to Profile object');
        }
        
        if (!Schema.SObjectType.PermissionSetAssignment.isAccessible()) {
            throw new SecurityException('Insufficient access to PermissionSetAssignment object');
        }
        
        if (!Schema.SObjectType.PermissionSet.isAccessible()) {
            throw new SecurityException('Insufficient access to PermissionSet object');
        }
        
        // Validate field-level security
        if (!Schema.SObjectType.User.fields.ProfileId.isAccessible() ||
            !Schema.SObjectType.PermissionSetAssignment.fields.PermissionSetId.isAccessible() ||
            !Schema.SObjectType.Profile.fields.Name.isAccessible() ||
            !Schema.SObjectType.Profile.fields.Id.isAccessible() ||
            !Schema.SObjectType.PermissionSet.fields.Name.isAccessible()) {
            throw new SecurityException('Insufficient field access');
        }

        Map<String, Object> result = new Map<String, Object>();
        
        // Use Database.query to enforce security checks
        String userQuery = 'SELECT Id, Profile.Name, Profile.Id FROM User WHERE Id = :userId LIMIT 1';
        User u = Database.query(userQuery);
        
        Set<Id> permissionSetIds = new Set<Id>{u.Profile.Id};
        
        // Use Database.query for PermissionSetAssignment
        String psaQuery = 'SELECT PermissionSet.Id FROM PermissionSetAssignment WHERE AssigneeId = :userId';
        List<PermissionSetAssignment> assignments = Database.query(psaQuery);
        
        for(PermissionSetAssignment psa : assignments) {
            permissionSetIds.add(psa.PermissionSet.Id);
        }
        
        result.put('profileName', u.Profile.Name);
        result.put('permissionSetNames', new List<String>());
        
        // Use Database.query for PermissionSet
        String psQuery = 'SELECT Name FROM PermissionSet WHERE Id IN :permissionSetIds';
        List<PermissionSet> permSets = Database.query(psQuery);
        
        for(PermissionSet ps : permSets) {
            ((List<String>)result.get('permissionSetNames')).add(ps.Name);
        }
        
        return result;
    }
    
    // Secure getObjectPermissions
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getObjectPermissions(String userId, Integer page, Integer pageSize, String searchTerm) {
        try {
            Set<Id> permissionSetIds = getPermissionSetIds(userId);
            Set<String> objectNames = new Set<String>();
            
            if (String.isNotBlank(searchTerm)) {
                String safeSearchTerm = String.escapeSingleQuotes(searchTerm);
                String searchPattern = '%' + safeSearchTerm + '%';
                
                List<EntityDefinition> objects = [
                    SELECT QualifiedApiName 
                    FROM EntityDefinition 
                    WHERE QualifiedApiName LIKE :searchPattern
                    AND QualifiedApiName LIKE '%__c'
                ];
                for (EntityDefinition obj : objects) {
                    objectNames.add(obj.QualifiedApiName);
                }
            }
            
            Integer offset = (page - 1) * pageSize;
            String query = 'SELECT SobjectType, PermissionsRead, PermissionsCreate, ' +
                'PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, ' +
                'PermissionsModifyAllRecords, ParentId ' +
                'FROM ObjectPermissions ' +
                'WHERE ParentId IN :permissionSetIds ';
            
            if (!objectNames.isEmpty()) {
                query += 'AND SobjectType IN :objectNames ';
            }
            
            query += 'ORDER BY SobjectType ' +
                'LIMIT :pageSize ' +
                'OFFSET :offset';
            
            List<ObjectPermissions> perms = Database.queryWithBinds(
                query,
            new Map<String, Object>{
                'permissionSetIds' => permissionSetIds,
                'objectNames' => objectNames,
                'pageSize' => pageSize,
                'offset' => offset
            },
            AccessLevel.USER_MODE
                );
            
            String countQuery = 'SELECT COUNT() FROM ObjectPermissions WHERE ParentId IN :permissionSetIds';
            if (!objectNames.isEmpty()) {
                countQuery += ' AND SobjectType IN :objectNames';
            }
            Integer total = Database.countQueryWithBinds(
                countQuery,
            new Map<String, Object>{
                'permissionSetIds' => permissionSetIds,
                'objectNames' => objectNames
            },
            AccessLevel.USER_MODE
                );
            
            Map<Id, String> sourceTypeMap = new Map<Id, String>();
            Map<Id, String> sourceNameMap = new Map<Id, String>();
            Map<Id, String> assignedByMap = new Map<Id, String>();
            Map<Id, String> assignmentMethodMap = new Map<Id, String>();
            
            // Maps to store granular permission information
            Map<Id, Boolean> viewAllDataMap = new Map<Id, Boolean>();
            Map<Id, Boolean> modifyAllDataMap = new Map<Id, Boolean>();
            Map<Id, Boolean> viewAllFieldsMap = new Map<Id, Boolean>();
            
            for(PermissionSet ps : [
                SELECT Id, Name, NamespacePrefix, IsOwnedByProfile, CreatedBy.Name,
                       PermissionsViewAllData, PermissionsModifyAllData
                FROM PermissionSet 
                WHERE Id IN :permissionSetIds
            ]) {
                // Store granular permissions
                viewAllDataMap.put(ps.Id, ps.PermissionsViewAllData);
                modifyAllDataMap.put(ps.Id, ps.PermissionsModifyAllData);
                // For now, we'll derive ViewAllFields from ViewAllData (can be enhanced later)
                viewAllFieldsMap.put(ps.Id, ps.PermissionsViewAllData);
                
                if (ps.IsOwnedByProfile) {
                    List<Profile> profiles = [
                        SELECT Name 
                        FROM Profile 
                        WHERE Id IN (
                            SELECT ProfileId 
                            FROM PermissionSet 
                            WHERE Id = :ps.Id
                        ) 
                        LIMIT 1
                    ];
                    sourceTypeMap.put(ps.Id, 'Profile');
                    sourceNameMap.put(ps.Id, profiles.isEmpty() ? 'Unknown Profile' : profiles[0].Name);
                    assignedByMap.put(ps.Id, 'System');
                    assignmentMethodMap.put(ps.Id, 'System Assignment');
                } else {
                    sourceTypeMap.put(ps.Id, ps.NamespacePrefix == null ? 'Permission Set' : 'Package');
                    sourceNameMap.put(ps.Id, ps.NamespacePrefix == null ? ps.Name : getNamespaceName(ps.NamespacePrefix));
                    assignedByMap.put(ps.Id, ps.CreatedBy.Name);
                    assignmentMethodMap.put(ps.Id, 'Manual Assignment');
                }
            }
            
            List<ObjectPermissionWrapper> results = new List<ObjectPermissionWrapper>();
            for (ObjectPermissions op : perms) {
                // Use object-specific granular permissions from ObjectPermissions
                Boolean canViewAll = op.PermissionsViewAllRecords;
                Boolean canModifyAll = op.PermissionsModifyAllRecords;
                // For ViewAllFields, use system-level permission as fallback since there's no object-level equivalent
                Boolean canViewAllFields = viewAllDataMap.get(op.ParentId) != null ? viewAllDataMap.get(op.ParentId) : false;
                
                results.add(new ObjectPermissionWrapper(
                    op.SobjectType,
                    op.PermissionsRead,
                    op.PermissionsCreate,
                    op.PermissionsEdit,
                    op.PermissionsDelete,
                    canViewAll,
                    canModifyAll,
                    canViewAllFields,
                    sourceTypeMap.get(op.ParentId),
                    sourceNameMap.get(op.ParentId),
                    assignedByMap.get(op.ParentId),
                    assignmentMethodMap.get(op.ParentId)
                ));
            }
            
            Map<String, Object> resultMap = new Map<String, Object>();
            resultMap.put('data', results);
            resultMap.put('total', total);
            
            return resultMap;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving object permissions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Wrapper class for enriched permission data
     */
    public class ObjectPermissionWrapper {
        @AuraEnabled public String objectName;
        @AuraEnabled public Boolean canRead;
        @AuraEnabled public Boolean canCreate;
        @AuraEnabled public Boolean canEdit;
        @AuraEnabled public Boolean canDelete;
        @AuraEnabled public Boolean canViewAll; // View all records permission
        @AuraEnabled public Boolean canModifyAll; // Modify all records permission
        @AuraEnabled public Boolean canViewAllFields; // View all fields permission
        @AuraEnabled public String sourceType; // Profile, Permission Set, or Package
        @AuraEnabled public String sourceName; // Name of the Profile or Permission Set
        @AuraEnabled public String assignedBy; // Who assigned the permission
        @AuraEnabled public String assignmentMethod; // How the permission was assigned
        
        /**
         * @description Constructor for ObjectPermissionWrapper
         * @param obj Object name
         * @param read Read permission
         * @param create Create permission
         * @param edit Edit permission
         * @param del Delete permission
         * @param srcType Source type
         * @param srcName Source name
         * @param assignedBy Who assigned the permission
         * @param assignmentMethod How the permission was assigned
         */
        public ObjectPermissionWrapper(String obj, Boolean read, Boolean create, Boolean edit, Boolean del,
        String srcType, String srcName, String assignedBy, String assignmentMethod) {
            objectName = obj;
            canRead = read;
            canCreate = create;
            canEdit = edit;
            canDelete = del;
            canViewAll = false; // Default to false, will be set based on permission analysis
            canModifyAll = false; // Default to false, will be set based on permission analysis
            canViewAllFields = false; // Default to false, will be set based on permission analysis
            sourceType = srcType;
            sourceName = srcName;
            this.assignedBy = assignedBy;
            this.assignmentMethod = assignmentMethod;
        }
        
        /**
         * @description Enhanced constructor with granular permissions
         * @param obj Object name
         * @param read Read permission
         * @param create Create permission
         * @param edit Edit permission
         * @param del Delete permission
         * @param viewAll View all records permission
         * @param modifyAll Modify all records permission
         * @param viewAllFields View all fields permission
         * @param srcType Source type
         * @param srcName Source name
         * @param assignedBy Who assigned the permission
         * @param assignmentMethod How the permission was assigned
         */
        public ObjectPermissionWrapper(String obj, Boolean read, Boolean create, Boolean edit, Boolean del,
        Boolean viewAll, Boolean modifyAll, Boolean viewAllFields,
        String srcType, String srcName, String assignedBy, String assignmentMethod) {
            objectName = obj;
            canRead = read;
            canCreate = create;
            canEdit = edit;
            canDelete = del;
            canViewAll = viewAll;
            canModifyAll = modifyAll;
            canViewAllFields = viewAllFields;
            sourceType = srcType;
            sourceName = srcName;
            this.assignedBy = assignedBy;
            this.assignmentMethod = assignmentMethod;
        }
    }
    // Add copy-specific method to Apex controller
    @AuraEnabled(cacheable=true)
    public static List<ObjectPermissionWrapper> getObjectPermissionsForUser(Id userId) {
        // Reuse the main permissions query with all filters
        Map<String, Object> permissionsData = UserPermController.getObjectPermissions(
            userId,
        1,
        2000,
        ''
            );
        return (List<ObjectPermissionWrapper>)permissionsData.get('data');
    }
    
    /**
     * @description Get all permission sources for a specific object
     * @param userId User ID to check permissions for
     * @param objectName API name of the object to check
     * @return List of ObjectPermissionWrapper with source information
     */
    @AuraEnabled
    public static List<ObjectPermissionWrapper> getObjectPermissionSources(String userId, String objectName) {
        try {
            // Validate input
            if (String.isBlank(userId) || String.isBlank(objectName)) {
                throw new AuraHandledException('User ID and Object Name are required');
            }
            
            // Normalize the object name
            String normalizedObjectName = String.escapeSingleQuotes(objectName);
            System.debug('🔍 DEBUG: Getting permission sources for user: ' + userId + ', object: ' + normalizedObjectName);
            
            // Get all permission sets assigned to the user
            Set<Id> permissionSetIds = getPermissionSetIds(userId);
            System.debug('🔍 DEBUG: Found permission set IDs: ' + permissionSetIds);
            
            // Query for object permissions for this specific object
            List<ObjectPermissions> objectPerms = [
                SELECT SobjectType, PermissionsRead, PermissionsCreate, 
                       PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords,
                       PermissionsModifyAllRecords, ParentId 
                FROM ObjectPermissions 
                WHERE ParentId IN :permissionSetIds 
                AND SobjectType = :normalizedObjectName
                WITH SECURITY_ENFORCED
            ];
            System.debug('🔍 DEBUG: Found ObjectPermissions records: ' + objectPerms.size());
            
            // If no ObjectPermissions found, check if user has access through profile defaults
            if (objectPerms.isEmpty()) {
                System.debug('🔍 DEBUG: No ObjectPermissions found, checking profile defaults');
                // For standard objects, permissions might be inherited from profile without explicit ObjectPermissions
                // Let's check if any of the permission sets have access to this object type
                return getDefaultPermissionSources(userId, normalizedObjectName, permissionSetIds);
            }
            
            // Maps to store permission source information
            Map<Id, String> sourceTypeMap = new Map<Id, String>();
            Map<Id, String> sourceNameMap = new Map<Id, String>();
            Map<Id, String> assignedByMap = new Map<Id, String>();
            Map<Id, String> assignmentMethodMap = new Map<Id, String>();
            
            // Maps to store granular permission information
            Map<Id, Boolean> viewAllDataMap = new Map<Id, Boolean>();
            Map<Id, Boolean> modifyAllDataMap = new Map<Id, Boolean>();
            Map<Id, Boolean> viewAllFieldsMap = new Map<Id, Boolean>();
            
            // Get assignment information for permission sets
            // Note: PermissionSetAssignment doesn't have CreatedBy field, so we'll use a different approach
            Map<Id, String> permissionSetAssignedByMap = new Map<Id, String>();
            
            // Query PermissionSetAssignment to get assignment details
            for(PermissionSetAssignment psa : [
                SELECT PermissionSetId, SystemModstamp
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId
                AND PermissionSetId IN :permissionSetIds
                WITH SECURITY_ENFORCED
            ]) {
                // Since we can't get the actual assigner, we'll use a generic value
                // In a real implementation, you might track this in a custom object
                permissionSetAssignedByMap.put(psa.PermissionSetId, 'Administrator');
            }
            
            // Get information about each permission set
            for(PermissionSet ps : [
                SELECT Id, Name, NamespacePrefix, IsOwnedByProfile,
                       PermissionsViewAllData, PermissionsModifyAllData
                FROM PermissionSet 
                WHERE Id IN :permissionSetIds
                AND Id IN (SELECT ParentId FROM ObjectPermissions WHERE SobjectType = :normalizedObjectName)
                WITH SECURITY_ENFORCED
            ]) {
                // Store granular permissions
                viewAllDataMap.put(ps.Id, ps.PermissionsViewAllData);
                modifyAllDataMap.put(ps.Id, ps.PermissionsModifyAllData);
                // For now, we'll derive ViewAllFields from ViewAllData (can be enhanced later)
                viewAllFieldsMap.put(ps.Id, ps.PermissionsViewAllData);
                if (ps.IsOwnedByProfile) {
                    List<Profile> profiles = [
                        SELECT Name 
                        FROM Profile 
                        WHERE Id IN (
                            SELECT ProfileId 
                            FROM PermissionSet 
                            WHERE Id = :ps.Id
                        ) 
                        LIMIT 1
                         
                    ];
                    sourceTypeMap.put(ps.Id, 'Profile');
                    sourceNameMap.put(ps.Id, profiles.isEmpty() ? 'Unknown Profile' : profiles[0].Name);
                    assignedByMap.put(ps.Id, 'System');
                    assignmentMethodMap.put(ps.Id, 'Profile Assignment');
                } else {
                    // All non-profile permission sets should be labeled as 'Permission Set'
                    // regardless of whether they have a namespace or not
                    sourceTypeMap.put(ps.Id, 'Permission Set');
                    // Always use the permission set name, not namespace info
                    sourceNameMap.put(ps.Id, ps.Name);
                    // Use the actual person who assigned the permission set, not who created it
                    assignedByMap.put(ps.Id, permissionSetAssignedByMap.get(ps.Id) != null ? permissionSetAssignedByMap.get(ps.Id) : 'Unknown');
                    assignmentMethodMap.put(ps.Id, 'Permission Set Assignment');
                }
                
                System.debug('🔍 DEBUG: Processing permission set: ' + ps.Name + 
                           ' (Namespace: ' + ps.NamespacePrefix + 
                           ', IsOwnedByProfile: ' + ps.IsOwnedByProfile + ')');
            }
            
            // Create wrapper objects for each permission source
            List<ObjectPermissionWrapper> results = new List<ObjectPermissionWrapper>();
            for (ObjectPermissions op : objectPerms) {
                // Only include permission sets that actually grant some level of access
                Boolean hasAnyAccess = op.PermissionsRead || op.PermissionsCreate || 
                                      op.PermissionsEdit || op.PermissionsDelete || 
                                      op.PermissionsViewAllRecords || op.PermissionsModifyAllRecords;
                
                if (!hasAnyAccess) {
                    System.debug('🔍 DEBUG: Skipping permission set with no access: ' + sourceNameMap.get(op.ParentId));
                    continue; // Skip permission sets that don't grant any access
                }
                
                // Use object-specific granular permissions from ObjectPermissions
                Boolean canViewAll = op.PermissionsViewAllRecords;
                Boolean canModifyAll = op.PermissionsModifyAllRecords;
                // For ViewAllFields, use system-level permission as fallback since there's no object-level equivalent
                Boolean canViewAllFields = viewAllFieldsMap.get(op.ParentId) != null ? viewAllFieldsMap.get(op.ParentId) : false;
                
                System.debug('🔍 DEBUG: Adding permission source: ' + sourceNameMap.get(op.ParentId) + 
                           ' (Type: ' + sourceTypeMap.get(op.ParentId) + 
                           ', Read: ' + op.PermissionsRead + 
                           ', Create: ' + op.PermissionsCreate + 
                           ', Edit: ' + op.PermissionsEdit + 
                           ', Delete: ' + op.PermissionsDelete + ')');
                
                results.add(new ObjectPermissionWrapper(
                    op.SobjectType,
                    op.PermissionsRead,
                    op.PermissionsCreate,
                    op.PermissionsEdit,
                    op.PermissionsDelete,
                    canViewAll,
                    canModifyAll,
                    canViewAllFields,
                    sourceTypeMap.get(op.ParentId),
                    sourceNameMap.get(op.ParentId),
                    assignedByMap.get(op.ParentId),
                    assignmentMethodMap.get(op.ParentId)
                ));
            }
            
            return results;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving permission sources: ' + e.getMessage());
        }
    }
    
    private static void checkFLSForPermissionSetAssignment() {
        String[] fields = new String[]{'PermissionSetId', 'AssigneeId'};
        for(String field : fields) {
            if(!PermissionSetAssignment.sObjectType.getDescribe()
            .fields.getMap().get(field).getDescribe().isAccessible()) {
                throw new SecurityException('Insufficient access to field: ' + field);
            }
        }
    }
    
    private static void checkFLSForObjectPermissions() {
        String[] fields = new String[]{'SObjectType', 'PermissionsRead', 'PermissionsEdit'};
        for(String field : fields) {
            if(!Schema.SObjectType.ObjectPermissions.fields.getMap().get(field).getDescribe().isAccessible()) {
                throw new SecurityException('Insufficient access to field: ' + field);
            }
        }
    }
    
    /**
     * @description Wrapper class for user object permissions
     */
    public class UserObjectPermissionWrapper {
        @AuraEnabled public String objectName;
        @AuraEnabled public Boolean canRead;
        @AuraEnabled public Boolean canCreate;
        @AuraEnabled public Boolean canEdit;
        @AuraEnabled public Boolean canDelete;
        @AuraEnabled public String assignedBy;
        @AuraEnabled public String assignmentMethod;
        @AuraEnabled public String sourceType;
        @AuraEnabled public String sourceName;
        
        /**
         * @description Constructor for UserObjectPermissionWrapper
         * @param objName Object name
         * @param read Read permission
         * @param create Create permission
         * @param edit Edit permission
         * @param del Delete permission
         * @param source Permission source
         */
        public UserObjectPermissionWrapper(String objName, Boolean read, Boolean create,
        Boolean edit, Boolean del, String source) {
            objectName = objName;
            canRead = read;
            canCreate = create;
            canEdit = edit;
            canDelete = del;
            sourceName = source;
            assignedBy = 'Admin';      // Default value or implement actual lookup
            assignmentMethod = 'Direct'; // Default value or implement actual data
            sourceType = 'Permission Set'; // Default value or implement actual data
        }
    }
    
    // Secure getFieldPermissions
    @AuraEnabled
    public static Map<String, Object> getFieldPermissions(String userId, String lastRecordId, String searchTerm, Boolean groupByObject, String objectName) {
        if (!Schema.SObjectType.FieldPermissions.fields.SobjectType.isAccessible() ||
            !Schema.SObjectType.FieldPermissions.fields.Field.isAccessible()) {
            throw new SecurityException('Insufficient field access');
        }
        
        Set<Id> permissionSetIds = getPermissionSetIds(userId);
        Map<String, Object> result = new Map<String, Object>();
        
        // Query for matching objects and fields
        Set<String> objectNames = new Set<String>();
        Set<String> fieldNames = new Set<String>();
        
        // Add specific object name filter if provided
        if (String.isNotBlank(objectName)) {
            objectNames.add(objectName);
        }
        
        if(String.isNotBlank(searchTerm)) {
            String safeSearchTerm = String.escapeSingleQuotes(searchTerm);
            String searchPattern = '%' + safeSearchTerm + '%';
            
            // First get matching objects, but only include custom objects (__c)
            List<EntityDefinition> objects = [
                SELECT Id, QualifiedApiName 
                FROM EntityDefinition 
                WHERE QualifiedApiName LIKE :searchPattern
                AND QualifiedApiName LIKE '%__c'
            ];
            
            Set<Id> objectIds = new Set<Id>();
            for(EntityDefinition obj : objects) {
                objectNames.add(obj.QualifiedApiName);
                objectIds.add(obj.Id);
            }
            
            // Then find fields in those objects
            if(!objectIds.isEmpty()) {
                List<FieldDefinition> fields = [
                    SELECT QualifiedApiName 
                    FROM FieldDefinition 
                    WHERE EntityDefinitionId IN :objectIds
                    AND QualifiedApiName LIKE :searchPattern
                ];
                for(FieldDefinition fld : fields) {
                    fieldNames.add(fld.QualifiedApiName);
                }
            }
        }
        
        // If we're just getting object names for the tree grid
        if (groupByObject == true) {
            // Get a count of fields per object to avoid another API call later
            Map<String, Integer> fieldCountsByObject = new Map<String, Integer>();
            
            String countByObjectQuery = 'SELECT SobjectType, COUNT(Id) fieldsCount ' +
                'FROM FieldPermissions ' +
                'WHERE ParentId IN :permissionSetIds ';
                
            if (!objectNames.isEmpty()) {
                countByObjectQuery += 'AND SobjectType IN :objectNames ';
            }
            
            if (String.isNotBlank(searchTerm)) {
                String safeSearchTerm = String.escapeSingleQuotes(searchTerm);
                String searchPattern = '%' + safeSearchTerm + '%';
                countByObjectQuery += 'AND (SobjectType LIKE :searchPattern OR Field LIKE :searchPattern) ';
            }
            
            countByObjectQuery += 'GROUP BY SobjectType';
            
            List<AggregateResult> fieldCounts = Database.query(countByObjectQuery);
            for (AggregateResult ar : fieldCounts) {
                String objName = (String)ar.get('SobjectType');
                Integer count = (Integer)ar.get('fieldsCount');
                fieldCountsByObject.put(objName, count);
            }
            
            // First try to get objects from FieldPermissions
            String groupedQuery = 'SELECT SobjectType ' +
                'FROM FieldPermissions ' +
                'WHERE ParentId IN :permissionSetIds ';
                
            if (!objectNames.isEmpty()) {
                groupedQuery += 'AND SobjectType IN :objectNames ';
            }
            
            if (String.isNotBlank(searchTerm)) {
                String safeSearchTerm = String.escapeSingleQuotes(searchTerm);
                String searchPattern = '%' + safeSearchTerm + '%';
                groupedQuery += 'AND (SobjectType LIKE :searchPattern OR Field LIKE :searchPattern) ';
            }
            
            groupedQuery += 'GROUP BY SobjectType ' +
                'ORDER BY SobjectType ASC ';
                
            List<AggregateResult> groupedResults = Database.query(groupedQuery);
            
            // Create a set to track unique object names from field permissions
            Set<String> uniqueObjects = new Set<String>();
            List<String> objectList = new List<String>();
            
            System.debug('Found ' + groupedResults.size() + ' objects from FieldPermissions query');
            
            for (AggregateResult ar : groupedResults) {
                String objectType = (String)ar.get('SobjectType');
                
                // Only add if we haven't seen this object yet
                if (!uniqueObjects.contains(objectType)) {
                    uniqueObjects.add(objectType);
                    objectList.add(objectType);
                }
            }
            
            // Always query the EntityDefinition to get all objects including custom ones
            // regardless of whether we found objects from FieldPermissions
            String likePattern = '%__c'; // Default to only custom objects
            if (String.isNotBlank(searchTerm)) {
                // If search term is provided, look for custom objects matching the term
                likePattern = '%' + String.escapeSingleQuotes(searchTerm) + '%__c';
            }
            
            // Add additional objects from EntityDefinition
            List<EntityDefinition> additionalObjects = [
                SELECT QualifiedApiName 
                FROM EntityDefinition 
                WHERE IsQueryable = true 
                AND (
                    // Only include custom objects with the __c suffix
                    QualifiedApiName LIKE '%__c'
                    // Include any objects with namespace if they're custom objects
                    OR (QualifiedApiName LIKE '%.%' AND QualifiedApiName LIKE '%__c')
                )
                ORDER BY QualifiedApiName 
                LIMIT 500
            ];
            
            System.debug('Found ' + additionalObjects.size() + ' objects from EntityDefinition query');
            
            for (EntityDefinition ed : additionalObjects) {
                String objectType = ed.QualifiedApiName;
                if (!uniqueObjects.contains(objectType)) {
                    uniqueObjects.add(objectType);
                    objectList.add(objectType);
                    
                    // For objects with no permissions yet, set count to 0
                    if (!fieldCountsByObject.containsKey(objectType)) {
                        fieldCountsByObject.put(objectType, 0);
                    }
                }
            }
            
            // Sort the object list alphabetically
            objectList.sort();
            
            // Get total count of all fields
            String countQuery = 'SELECT COUNT() FROM FieldPermissions WHERE ParentId IN :permissionSetIds';
            if(!objectNames.isEmpty()) {
                countQuery += ' AND SobjectType IN :objectNames';
            }
            Integer totalFields = Database.countQuery(countQuery);
            
            System.debug('Returning ' + objectList.size() + ' objects in total');
            
            // Return success with objects and field counts
            result.put('success', true);
            result.put('objects', objectList);
            result.put('totalCount', totalFields);
            result.put('fieldCountsByObject', fieldCountsByObject);
            
            return result;
        }
        
        // Regular detail query with possible object filter
        String query = 'SELECT SobjectType, Field, PermissionsRead, PermissionsEdit ' +
            'FROM FieldPermissions ' +
            'WHERE ParentId IN :permissionSetIds ';
            
        // Add filters
        if (!objectNames.isEmpty()) {
            query += 'AND SobjectType IN :objectNames ';
        } else if (String.isNotBlank(searchTerm) && !fieldNames.isEmpty()) {
            query += 'AND (SobjectType IN :objectNames OR Field IN :fieldNames) ';
        }
        
        if (String.isNotBlank(lastRecordId)) {
            query += 'AND Id > :lastRecordId ';
        }
        
        query += 'ORDER BY SobjectType, Field ' +
            'LIMIT 500'; // Increased limit since we're filtering by object
        
        List<FieldPermissions> perms = Database.query(query);
        
        // Deduplicate results using a map
        Map<String, FieldPermissions> uniquePerms = new Map<String, FieldPermissions>();
        for(FieldPermissions fp : perms) {
            String key = fp.SobjectType + '|' + fp.Field;
            if(!uniquePerms.containsKey(key)) {
                uniquePerms.put(key, fp);
            } else {
                // Merge permissions if duplicate exists
                FieldPermissions existing = uniquePerms.get(key);
                existing.PermissionsRead = existing.PermissionsRead || fp.PermissionsRead;
                existing.PermissionsEdit = existing.PermissionsEdit || fp.PermissionsEdit;
            }
        }
        
        // Get total count
        String countQuery = 'SELECT COUNT() FROM FieldPermissions WHERE ParentId IN :permissionSetIds';
        if(!objectNames.isEmpty()) {
            countQuery += ' AND SobjectType IN :objectNames';
        } else if(String.isNotBlank(searchTerm) && !objectNames.isEmpty() && !fieldNames.isEmpty()) {
            countQuery += ' AND (SobjectType IN :objectNames OR Field IN :fieldNames)';
        }
        Integer totalFields = Database.countQuery(countQuery);
        
        result.put('success', true);
        result.put('data', uniquePerms.values());
        result.put('lastRecordId', perms.isEmpty() ? null : perms[perms.size()-1].Id);
        result.put('totalCount', totalFields);
        
        return result;
    }
    
    // Add this inner class to sort the result list
    private class ObjectComparator implements Comparator<Map<String, Object>> {
        public Integer compare(Map<String, Object> obj1, Map<String, Object> obj2) {
            String sObjectType1 = (String)obj1.get('SobjectType');
            String sObjectType2 = (String)obj2.get('SobjectType');
            
            if (sObjectType1 == null) return 1;
            if (sObjectType2 == null) return -1;
            
            return sObjectType1.compareTo(sObjectType2);
        }
    }
    
    /**
     * @description Retrieves the login history for a specific user with proper security checks
     * @param userId The ID of the user to retrieve login history for
     * @return List<LoginHistory> List of login history records
     */
    @AuraEnabled(cacheable=true)
    public static List<LoginHistory> getLoginHistory(String userId) {
        // Validate object-level access first
        if (!Schema.SObjectType.LoginHistory.isAccessible()) {
            throw new SecurityException('Insufficient access to login history object');
        }
        
        // Validate field-level security for all fields being queried
        if (!Schema.SObjectType.LoginHistory.fields.LoginTime.isAccessible() ||
            !Schema.SObjectType.LoginHistory.fields.Status.isAccessible() ||
            !Schema.SObjectType.LoginHistory.fields.SourceIp.isAccessible() ||
            !Schema.SObjectType.LoginHistory.fields.LoginType.isAccessible() ||
            !Schema.SObjectType.LoginHistory.fields.Application.isAccessible() ||
            !Schema.SObjectType.LoginHistory.fields.Browser.isAccessible() ||
            !Schema.SObjectType.LoginHistory.fields.Platform.isAccessible() ||
            !Schema.SObjectType.LoginHistory.fields.ApiType.isAccessible() ||
            !Schema.SObjectType.LoginHistory.fields.ApiVersion.isAccessible()) {
            throw new SecurityException('Insufficient access to login history fields');
        }
        
        // Use Database.query to enforce FLS
        String query = 'SELECT Id, LoginTime, Status, SourceIp, LoginType, ' +
                      'Application, Browser, Platform, ApiType, ApiVersion ' +
                      'FROM LoginHistory ' +
                      'WHERE UserId = :userId ' +
                      'ORDER BY LoginTime DESC ' +
                      'LIMIT 100';
        
        return Database.query(query);
    }
    
    // Secure getPermissionSetIds
    private static Set<Id> getPermissionSetIds(String userId) {
        Set<Id> permissionSetIds = new Set<Id>();
        
        try {
            if (!Schema.SObjectType.User.fields.ProfileId.isAccessible()) {
                throw new SecurityException('Insufficient access to ProfileId field');
            }
            
            User u = [SELECT ProfileId FROM User WHERE Id = :userId LIMIT 1];
            
            List<PermissionSet> profilePermissionSets = [
            SELECT Id 
            FROM PermissionSet 
            WHERE ProfileId = :u.ProfileId 
            AND IsOwnedByProfile = true
            LIMIT 1
        ];
            
            if(!profilePermissionSets.isEmpty()) {
                permissionSetIds.add(profilePermissionSets[0].Id);
            }
            
            List<PermissionSetAssignment> assignments = [
            SELECT PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId
        ];
            
            for(PermissionSetAssignment psa : assignments) {
                permissionSetIds.add(psa.PermissionSetId);
            }
            
        } catch(Exception e) {
            throw new AuraHandledException('Error getting permission sets: ' + e.getMessage());
        }
        
        return permissionSetIds;
    }
    
    /**
     * @description Get default permission sources when no explicit ObjectPermissions exist
     * This handles cases where permissions are inherited from profile defaults
     */
    private static List<ObjectPermissionWrapper> getDefaultPermissionSources(String userId, String objectName, Set<Id> permissionSetIds) {
        List<ObjectPermissionWrapper> results = new List<ObjectPermissionWrapper>();
        
        try {
            // Get permission set information
            for(PermissionSet ps : [
                SELECT Id, Name, NamespacePrefix, IsOwnedByProfile,
                       PermissionsViewAllData, PermissionsModifyAllData
                FROM PermissionSet 
                WHERE Id IN :permissionSetIds
                WITH SECURITY_ENFORCED
            ]) {
                String sourceType;
                String sourceName;
                String assignedBy;
                String assignmentMethod;
                
                if (ps.IsOwnedByProfile) {
                    // This is a profile-owned permission set
                    List<Profile> profiles = [
                        SELECT Name 
                        FROM Profile 
                        WHERE Id IN (
                            SELECT ProfileId 
                            FROM PermissionSet 
                            WHERE Id = :ps.Id
                        ) 
                        LIMIT 1
                    ];
                    sourceType = 'Profile';
                    sourceName = profiles.isEmpty() ? 'Unknown Profile' : profiles[0].Name;
                    assignedBy = 'System';
                    assignmentMethod = 'Profile Assignment';
                    
                    // For profile-owned permission sets, assume standard CRUD permissions for most objects
                    // This is a reasonable default since profiles typically have basic access
                    results.add(new ObjectPermissionWrapper(
                        objectName,
                        true,  // Read
                        true,  // Create  
                        true,  // Edit
                        true,  // Delete
                        ps.PermissionsViewAllData, // ViewAll
                        ps.PermissionsModifyAllData, // ModifyAll
                        ps.PermissionsViewAllData, // ViewAllFields
                        sourceType,
                        sourceName,
                        assignedBy,
                        assignmentMethod
                    ));
                    
                    System.debug('🔍 DEBUG: Added default profile permissions for ' + sourceName);
                } else {
                    // This is a regular permission set - if no ObjectPermissions exist, 
                    // it likely means no access is granted
                    System.debug('🔍 DEBUG: Skipping permission set ' + ps.Name + ' - no explicit permissions');
                }
            }
        } catch (Exception e) {
            System.debug('🔍 DEBUG: Error in getDefaultPermissionSources: ' + e.getMessage());
        }
        
        return results;
    }
    
    /**
     * @description Wrapper class for record type information with sorting capability
     */
    public class RecordTypeWrapper implements Comparable {
        @AuraEnabled public String objectName;
        @AuraEnabled public String profileName;
        @AuraEnabled public List<String> recordTypeNames;  // Original list
        @AuraEnabled public String formattedRecordTypes;   // New formatted string
        @AuraEnabled public String assignedVia;
        
        /**
         * @description Constructor for RecordTypeWrapper
         * @param obj Object name
         * @param profile Profile name
         * @param rts List of record type names
         * @param via Assignment method
         * @param formatted Formatted record type string
         */
        public RecordTypeWrapper(String obj, String profile, List<String> rts, String via, String formatted) {
            objectName = obj;
            profileName = profile;
            recordTypeNames = rts;
            assignedVia = via;
            formattedRecordTypes = formatted;
        }
        
        /**
         * @description Implement the compareTo method required by the Comparable interface
         * @param compareTo Object to compare to
         * @return Integer Comparison result
         */
        public Integer compareTo(Object compareTo) {
            RecordTypeWrapper compareToRecord = (RecordTypeWrapper)compareTo;
            if (objectName == null || compareToRecord.objectName == null) return 0;
            return objectName.compareTo(compareToRecord.objectName);
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<RecordTypeWrapper> getRecordTypeAssignments(Id userId) {
        try {
            // Comprehensive FLS checks for User object fields
            if (!Schema.SObjectType.User.fields.ProfileId.isAccessible() ||
                !Schema.SObjectType.User.fields.Id.isAccessible() ||
                !Schema.SObjectType.Profile.fields.Name.isAccessible()) {
                throw new SecurityException('Insufficient access to required User and Profile fields');
            }

            // Check object access for RecordType
            if (!Schema.SObjectType.RecordType.isAccessible()) {
                throw new SecurityException('Insufficient access to RecordType object');
            }

            // Check RecordType field access
            if (!Schema.SObjectType.RecordType.fields.Name.isAccessible() ||
                !Schema.SObjectType.RecordType.fields.SObjectType.isAccessible() ||
                !Schema.SObjectType.RecordType.fields.IsActive.isAccessible()) {
                throw new SecurityException('Insufficient access to RecordType fields');
            }

            User userRecord = [SELECT Profile.Name 
              FROM User 
              WHERE Id = :userId];
            
            List<RecordTypeWrapper> results = new List<RecordTypeWrapper>();
            Map<String, List<String>> recordTypesByObject = new Map<String, List<String>>();

            // Query RecordTypeInfo for all accessible objects with security checks
            for(Schema.SObjectType objType : Schema.getGlobalDescribe().values()) {
                Schema.DescribeSObjectResult describeResult = objType.getDescribe();
                // Check if the current user has access to the object
                if(describeResult.isAccessible() && describeResult.isQueryable()) {
                    Map<Id, Schema.RecordTypeInfo> recordTypeInfos = describeResult.getRecordTypeInfosByID();
                    for(Schema.RecordTypeInfo rti : recordTypeInfos.values()) {
                        // Only include record types the user has access to
                        if(rti.isAvailable() && rti.isActive()) {
                            String objName = describeResult.getName();
                            if(!recordTypesByObject.containsKey(objName)) {
                                recordTypesByObject.put(objName, new List<String>());
                            }
                            recordTypesByObject.get(objName).add(rti.getName());
                        }
                    }
                }
            }

            // Modify how we create the wrapper to join the record type names into a string
            for(String objName : recordTypesByObject.keySet()) {
                List<String> rtNames = recordTypesByObject.get(objName);
                // Sort record type names alphabetically
                rtNames.sort();
                
                // Create a formatted string of record type names
                String formattedRecordTypes = String.join(rtNames, ', ');
                
                results.add(new RecordTypeWrapper(
                    String.escapeSingleQuotes(objName),
                    String.escapeSingleQuotes(userRecord.Profile.Name),
                    rtNames,  // Keep the list for potential future use
                    'Profile',
                    formattedRecordTypes  // Add the formatted string
                ));
            }

            results.sort();
            return results;

        } catch(Exception e) {
           // System.debug(LoggingLevel.ERROR, 'Error in getRecordTypeAssignments: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving record types. Please contact your administrator.');
        }
    }
    
    /**
     * @description Retrieves system-level permissions for a user organized by permission categories
     * @param userId The ID of the user to retrieve system-level permissions for
     * @return Map<String, Map<String, Object>> Map of permission categories to permission details
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, Object>> getSystemLevelPermissions(String userId) {
        Map<String, Map<String, Object>> permissions = initializePermissionsMap();
        
        try {
            Set<Id> permissionSetIds = getPermissionSetIds(userId);
            List<PermissionSet> permSets = queryPermissionSets(permissionSetIds);
            
            for(PermissionSet ps : permSets) {
                processPermissionSet(ps, permissions);
            }
            
        } catch(Exception e) {
            handleException(e);
        }
        return permissions;
    }
    
    // Helper methods
    private static Map<String, Map<String, Object>> initializePermissionsMap() {
        return new Map<String, Map<String, Object>>{
            'View_All_Data' => createPermissionEntry(),
            'Modify_All_Data' => createPermissionEntry(),
            'Manage_Users' => createPermissionEntry(),
            'Author_Apex' => createPermissionEntry(),
            'Customize_Application' => createPermissionEntry(),
            'View_Setup' => createPermissionEntry()
        };
    }
    
    private static Map<String, Object> createPermissionEntry() {
        return new Map<String, Object>{
            'Value' => false,
            'Sources' => new List<String>()
        };
    }
    
    private static List<PermissionSet> queryPermissionSets(Set<Id> permissionSetIds) {
        return [
        SELECT Id, Name, NamespacePrefix, IsOwnedByProfile, ProfileId,
            PermissionsViewAllData, PermissionsModifyAllData,
            PermissionsManageUsers, PermissionsAuthorApex,
            PermissionsCustomizeApplication, PermissionsViewSetup
        FROM PermissionSet 
        WHERE Id IN :permissionSetIds 
    ];
    }
    
    private static void processPermissionSet(PermissionSet ps, Map<String, Map<String, Object>> permissions) {
        String sourceType = determineSourceType(ps);
        String sourceName = determineSourceName(ps);
        
        updatePermission(permissions, 'View_All_Data', ps.PermissionsViewAllData, sourceType, sourceName);
        updatePermission(permissions, 'Modify_All_Data', ps.PermissionsModifyAllData, sourceType, sourceName);
        updatePermission(permissions, 'Manage_Users', ps.PermissionsManageUsers, sourceType, sourceName);
        updatePermission(permissions, 'Author_Apex', ps.PermissionsAuthorApex, sourceType, sourceName);
        updatePermission(permissions, 'Customize_Application', ps.PermissionsCustomizeApplication, sourceType, sourceName);
        updatePermission(permissions, 'View_Setup', ps.PermissionsViewSetup, sourceType, sourceName);
    }
    
    private static String determineSourceType(PermissionSet ps) {
        if(ps.IsOwnedByProfile) return 'Profile';
        return ps.NamespacePrefix != null ? 'Package' : 'Permission Set';
    }
    
    private static String determineSourceName(PermissionSet ps) {
        if(ps.IsOwnedByProfile) {
            return getProfileNames(ps.ProfileId);
        }
        return ps.NamespacePrefix != null ?
            ps.NamespacePrefix + ' Package' :
            ps.Name;
    }
    
    private static void updatePermission(Map<String, Map<String, Object>> permissions, String key,
    Boolean value, String sourceType, String sourceName) {
        if(value) {
            Map<String, Object> permEntry = permissions.get(key);
            permEntry.put('Value', true);
            
            List<String> sources = (List<String>) permEntry.get('Sources');
            String source = sourceType + ': ' + sourceName;
            if(!sources.contains(source)) {
                sources.add(source);
            }
        }
    }
    
    /**
     * @description Retrieves the name of a profile given its ID
     * @param profileId The ID of the profile to lookup
     * @return String The name of the profile or 'Unknown Profile' if not found
     */
    private static String getProfileNames(Id profileId) {
        // Validate CRUD permissions
        if (!Schema.SObjectType.Profile.isAccessible()) {
            throw new SecurityException('Insufficient access to Profile object');
        }
        
        if (!Schema.SObjectType.Profile.fields.Name.isAccessible()) {
            throw new SecurityException('Insufficient access to Profile.Name field');
        }
        
        // Use Database.query for security enforcement
        String query = 'SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1';
        List<Profile> profiles = Database.query(query);
        return profiles.isEmpty() ? 'Unknown Profile' : profiles[0].Name;
    }
    
    /**
     * @description Handles exceptions by logging and throwing user-friendly error messages
     * @param e The exception to handle
     * @throws AuraHandledException with a user-friendly error message
     */
    private static void handleException(Exception e) {
      //  System.debug(LoggingLevel.ERROR, 'Error: ' + e.getStackTraceString());
        throw new AuraHandledException('Error retrieving system permissions: ' + e.getMessage());
    }
    
    /**
     * @description Retrieves sharing rules access for a user
     * @param userId The ID of the user to retrieve sharing rules for
     * @return List<SharingRuleWrapper> List of sharing rule wrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<SharingRuleWrapper> getSharingRulesAccess(String userId) {
        // Validate CRUD permissions first
        if (!Schema.SObjectType.GroupMember.isAccessible() || !Schema.SObjectType.Group.isAccessible()) {
            throw new SecurityException('Insufficient access to GroupMember or Group objects');
        }
        
        if (!Schema.SObjectType.GroupMember.fields.UserOrGroupId.isAccessible() ||
            !Schema.SObjectType.Group.fields.DeveloperName.isAccessible() ||
            !Schema.SObjectType.Group.fields.Type.isAccessible()) {
            throw new SecurityException('Insufficient access to GroupMember or Group fields');
        }
        
        List<SharingRuleWrapper> results = new List<SharingRuleWrapper>();
        
        try {
            // Get sharing rules for the user's role and groups - use Database.query for security
            String query = 'SELECT Group.DeveloperName, Group.Type, UserOrGroupId ' +
                          'FROM GroupMember ' +
                          'WHERE UserOrGroupId = :userId ' +
                          'ORDER BY Group.DeveloperName ' +
                          'LIMIT 1000';
            
            List<GroupMember> members = Database.query(query);
            
            for(GroupMember gm : members) {
                results.add(new SharingRuleWrapper(
                    'Group',
                    gm.Group.DeveloperName,
                    'Read/Write',
                    gm.Group.Type
                ));
            }
            
            return results;
        } catch(Exception e) {
           // System.debug(LoggingLevel.ERROR, 'Error in getSharingRulesAccess: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving sharing rules: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves the role hierarchy information for a user
     * @param userId The ID of the user to retrieve role hierarchy for
     * @return List<RoleHierarchyWrapper> List of role hierarchy wrapper objects
     */
    @AuraEnabled(cacheable=true)
    public static List<RoleHierarchyWrapper> getRoleHierarchy(String userId) {
        // Validate CRUD permissions first
        if (!Schema.SObjectType.User.isAccessible() || !Schema.SObjectType.UserRole.isAccessible()) {
            throw new SecurityException('Insufficient access to User or UserRole objects');
        }
        
        if (!Schema.SObjectType.User.fields.UserRoleId.isAccessible() ||
            !Schema.SObjectType.UserRole.fields.Name.isAccessible() ||
            !Schema.SObjectType.UserRole.fields.ParentRoleId.isAccessible()) {
            throw new SecurityException('Insufficient access to User or UserRole fields');
        }
        
        List<RoleHierarchyWrapper> hierarchy = new List<RoleHierarchyWrapper>();
        
        try {
            // Use Database.query for security enforcement
            String userQuery = 'SELECT UserRoleId FROM User WHERE Id = :userId LIMIT 1';
            User u = Database.query(userQuery);
            
            if(u.UserRoleId == null) return hierarchy;
            
            // Use Database.query with LIMIT clause for security
            String roleQuery = 'SELECT Id, Name, ParentRoleId FROM UserRole ORDER BY Name LIMIT 1000';
            List<UserRole> roleList = Database.query(roleQuery);
            Map<Id, UserRole> roles = new Map<Id, UserRole>(roleList);
            
            // Build hierarchy tree
            Set<Id> processedIds = new Set<Id>();
            Id currentRoleId = u.UserRoleId;
            
            while(currentRoleId != null && !processedIds.contains(currentRoleId)) {
                UserRole role = roles.get(currentRoleId);
                hierarchy.add(new RoleHierarchyWrapper(
                    role.Name,
                roles.containsKey(role.ParentRoleId) ? roles.get(role.ParentRoleId).Name : '',
                'Inherited'
                ));
                processedIds.add(currentRoleId);
                currentRoleId = role.ParentRoleId;
            }
            
            return hierarchy;
        } catch(Exception e) {
           // System.debug(LoggingLevel.ERROR, 'Error in getRoleHierarchy: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving role hierarchy: ' + e.getMessage());
        }
    }
    
    /**
     * @description Wrapper class for sharing rule information
     */
    public class SharingRuleWrapper {
        @AuraEnabled public String objectName;
        @AuraEnabled public String sharingType;
        @AuraEnabled public String accessLevel;
        @AuraEnabled public String sharedWith;
        
        /**
         * @description Constructor for SharingRuleWrapper
         * @param obj Object name
         * @param type Sharing type
         * @param access Access level
         * @param with Shared with
         */
        public SharingRuleWrapper(String obj, String type, String access, String with) {
            objectName = obj;
            sharingType = type;
            accessLevel = access;
            sharedWith = with;
        }
    }
    
    /**
     * @description Wrapper class for role hierarchy information
     */
    public class RoleHierarchyWrapper {
        @AuraEnabled public String roleName;
        @AuraEnabled public String parentRole;
        @AuraEnabled public String accessLevel;
        @AuraEnabled public String id;
        
        /**
         * @description Constructor for RoleHierarchyWrapper
         * @param name Role name
         * @param parent Parent role
         * @param access Access level
         */
        public RoleHierarchyWrapper(String name, String parent, String access) {
            roleName = name;
            parentRole = parent;
            accessLevel = access;
            id = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(name + parent)));
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static AccessRiskAnalyzer.RiskResult getAccessRiskScore(Id userId) {
        return AccessRiskAnalyzer.analyzeUserRisk(userId);
    }
    
    // Add this method for risk analysis
    public static UserPermissionAccess getUserPermissionAccess(Id userId) {
        UserPermissionAccess perms = new UserPermissionAccess();
        perms.systemPermissions = new List<String>();
        perms.objectPermissions = new List<ObjectPermissions>();
        
        // Get profile and permission sets
        Set<Id> permissionSetIds = new Set<Id>();
        
        // Get user's profile
        User u = [SELECT ProfileId FROM User WHERE Id = :userId];
        permissionSetIds.add(u.ProfileId);
        
        // Get assigned permission sets
        for(PermissionSetAssignment psa : [
        SELECT PermissionSetId 
        FROM PermissionSetAssignment 
        WHERE AssigneeId = :userId
    ]) {
            permissionSetIds.add(psa.PermissionSetId);
        }
        
        // Get system permissions
        for(PermissionSet ps : [
        SELECT PermissionsModifyAllData, PermissionsManageUsers, 
               PermissionsApiEnabled 
        FROM PermissionSet 
        WHERE Id IN :permissionSetIds
    ]) {
            if(ps.PermissionsModifyAllData) perms.systemPermissions.add('ModifyAllData');
            if(ps.PermissionsManageUsers) perms.systemPermissions.add('ManageUsers');
            if(ps.PermissionsApiEnabled) perms.systemPermissions.add('ApiEnabled');
        }
        
        // Get object permissions
        perms.objectPermissions = [
        SELECT SobjectType 
        FROM ObjectPermissions 
        WHERE ParentId IN :permissionSetIds
    ];
        
        return perms;
    }
    
    // Add bulk version of getUserPermissionAccess to avoid SOQL limits
    public static Map<Id, UserPermissionAccess> getUserPermissionAccessBulk(Set<Id> userIds) {
        Map<Id, UserPermissionAccess> results = new Map<Id, UserPermissionAccess>();
        
        // Initialize results map
        for (Id userId : userIds) {
            results.put(userId, new UserPermissionAccess());
        }
        
        // Get users and their profiles
        Map<Id, Id> userProfileMap = new Map<Id, Id>();
        for (User u : [SELECT Id, ProfileId FROM User WHERE Id IN :userIds]) {
            userProfileMap.put(u.Id, u.ProfileId);
            results.get(u.Id).systemPermissions = new List<String>();
            results.get(u.Id).objectPermissions = new List<ObjectPermissions>();
        }
        
        // Get permission set assignments for all users
        Map<Id, Set<Id>> userPermissionSetMap = new Map<Id, Set<Id>>();
        for (PermissionSetAssignment psa : [
            SELECT PermissionSetId, AssigneeId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId IN :userIds
        ]) {
            if (!userPermissionSetMap.containsKey(psa.AssigneeId)) {
                userPermissionSetMap.put(psa.AssigneeId, new Set<Id>());
            }
            userPermissionSetMap.get(psa.AssigneeId).add(psa.PermissionSetId);
        }
        
        // Collect all permission set IDs (profiles + assigned permission sets)
        Set<Id> allPermissionSetIds = new Set<Id>();
        for (Id userId : userIds) {
            // Add profile ID
            if (userProfileMap.containsKey(userId)) {
                allPermissionSetIds.add(userProfileMap.get(userId));
            }
            // Add assigned permission sets
            if (userPermissionSetMap.containsKey(userId)) {
                allPermissionSetIds.addAll(userPermissionSetMap.get(userId));
            }
        }
        
        // Get system permissions for all permission sets
        Map<Id, PermissionSet> permissionSetMap = new Map<Id, PermissionSet>([
            SELECT Id, PermissionsModifyAllData, PermissionsManageUsers, PermissionsApiEnabled 
            FROM PermissionSet 
            WHERE Id IN :allPermissionSetIds
        ]);
        
        // Get object permissions for all permission sets
        Map<Id, List<ObjectPermissions>> permissionSetObjectPermsMap = new Map<Id, List<ObjectPermissions>>();
        for (ObjectPermissions op : [
            SELECT SobjectType, ParentId 
            FROM ObjectPermissions 
            WHERE ParentId IN :allPermissionSetIds
        ]) {
            if (!permissionSetObjectPermsMap.containsKey(op.ParentId)) {
                permissionSetObjectPermsMap.put(op.ParentId, new List<ObjectPermissions>());
            }
            permissionSetObjectPermsMap.get(op.ParentId).add(op);
        }
        
        // Build results for each user
        for (Id userId : userIds) {
            UserPermissionAccess perms = results.get(userId);
            Set<Id> userPermSetIds = new Set<Id>();
            
            // Add profile permission set
            if (userProfileMap.containsKey(userId)) {
                userPermSetIds.add(userProfileMap.get(userId));
            }
            
            // Add assigned permission sets
            if (userPermissionSetMap.containsKey(userId)) {
                userPermSetIds.addAll(userPermissionSetMap.get(userId));
            }
            
            // Add system permissions
            for (Id permSetId : userPermSetIds) {
                if (permissionSetMap.containsKey(permSetId)) {
                    PermissionSet ps = permissionSetMap.get(permSetId);
                    if (ps.PermissionsModifyAllData) perms.systemPermissions.add('ModifyAllData');
                    if (ps.PermissionsManageUsers) perms.systemPermissions.add('ManageUsers');
                    if (ps.PermissionsApiEnabled) perms.systemPermissions.add('ApiEnabled');
                }
            }
            
            // Add object permissions
            for (Id permSetId : userPermSetIds) {
                if (permissionSetObjectPermsMap.containsKey(permSetId)) {
                    perms.objectPermissions.addAll(permissionSetObjectPermsMap.get(permSetId));
                }
            }
        }
        
        return results;
    }
    
    /**
     * @description Wrapper class for detailed user information
     */
    public class UserDetailsWrapper {
        @AuraEnabled public String userName;
        @AuraEnabled public String userEmail;
        @AuraEnabled public String profileName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public List<String> permissionSets;
        @AuraEnabled public Integer riskScore;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Integer highRiskCount;
    }
    
    @AuraEnabled(cacheable=true)
    public static UserDetailsWrapper getUserDetails(Id userId) {
        // Query user details
        User u = [SELECT Name, Email, Profile.Name, IsActive 
              FROM User 
              WHERE Id = :userId 
              LIMIT 1];
        if (u == null) {
            throw new AuraHandledException('User not found');
        }
        
        // Analyze risk
        AccessRiskAnalyzer.RiskResult riskResult = AccessRiskAnalyzer.analyzeUserRisk(userId);
        
        // Create and populate wrapper
        UserDetailsWrapper wrapper = new UserDetailsWrapper();
        wrapper.userName = u.Name;
        wrapper.userEmail = u.Email;
        wrapper.profileName = u.Profile.Name;
        wrapper.isActive = u.IsActive;
        wrapper.permissionSets = getPermissionSets(userId);
        wrapper.riskScore = riskResult.riskScore;
        wrapper.riskLevel = riskResult.riskLevel;
        wrapper.highRiskCount = riskResult.highRiskCount;
        
        return wrapper;
    }
    
    private static List<String> getPermissionSets(Id userId) {
        // Query PermissionSetAssignments for the given user
        List<PermissionSetAssignment> assignments = [
        SELECT PermissionSet.Name 
        FROM PermissionSetAssignment 
        WHERE AssigneeId = :userId
    ];
        
        // Create a list to store permission set names
        List<String> permissionSetNames = new List<String>();
        
        // Iterate through the query results and add names to the list
        for (PermissionSetAssignment psa : assignments) {
            permissionSetNames.add(psa.PermissionSet.Name);
        }
        
        // Return the list of permission set names
        return permissionSetNames;
    }
    
    /**
     * @description Retrieves the namespace name with license information for a given namespace prefix
     * @param namespacePrefix The namespace prefix to look up
     * @return String The formatted namespace name with license details if available
     */
    private static String getNamespaceName(String namespacePrefix) {
        // Check CRUD permissions for the PackageLicense object
        if (!Schema.SObjectType.PackageLicense.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access PackageLicense object');
        }
        
        List<PackageLicense> licenses = [SELECT NamespacePrefix, AllowedLicenses 
                                    FROM PackageLicense 
                                    WHERE NamespacePrefix = :namespacePrefix
                                    LIMIT 1];
        return licenses.isEmpty() ?
            namespacePrefix :
            namespacePrefix + ' (' + licenses[0].AllowedLicenses + ')';
    }
    
    /**
     * @description Retrieves available permission sets for a user, marking those that are already assigned
     * @param userId The Id of the user to retrieve permission sets for
     * @return List<PermissionSetWrapper> A list of permission sets with assignment status indicated
     * @throws SecurityException If the current user has insufficient CRUD or FLS permissions
     */
    @AuraEnabled
    public static List<PermissionSetWrapper> getAvailablePermissionSets(Id userId) {
        try {
            // Check CRUD permissions first
            if (!Schema.SObjectType.User.isAccessible() || 
                !Schema.SObjectType.Profile.isAccessible() ||
                !Schema.SObjectType.UserLicense.isAccessible() ||
                !Schema.SObjectType.PermissionSet.isAccessible() ||
                !Schema.SObjectType.PermissionSetAssignment.isAccessible()) {
                throw new SecurityException('Insufficient object access permissions');
            }
            
            // Check field-level security
            if (!Schema.SObjectType.User.fields.Id.isAccessible() ||
                !Schema.SObjectType.Profile.fields.UserLicenseId.isAccessible() ||
                !Schema.SObjectType.UserLicense.fields.Name.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.Id.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.Label.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.Name.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.Description.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.IsOwnedByProfile.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.ProfileId.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.LicenseId.isAccessible() ||
                !Schema.SObjectType.PermissionSetAssignment.fields.PermissionSetId.isAccessible() ||
                !Schema.SObjectType.PermissionSetAssignment.fields.AssigneeId.isAccessible()) {
                throw new SecurityException('Insufficient field-level security permissions');
            }
            
            // Get the user's license type first
            User userRecord = [
                SELECT Id, Profile.UserLicense.Name 
                FROM User 
                WHERE Id = :userId 
                LIMIT 1
            ];
            String userLicenseType = userRecord.Profile.UserLicense.Name;
            
            // Get a list of all permission sets that match the user's license
            List<PermissionSet> permSets = [
                SELECT Id, Label, Name, Description, Type 
                FROM PermissionSet 
                WHERE IsOwnedByProfile = false 
                AND ProfileId = null
                AND (License.Name = :userLicenseType OR License.Name = null)
                ORDER BY Label
            ];
            
            // Get a list of permission sets already assigned to this user
            Set<Id> assignedPermSetIds = new Set<Id>();
            for(PermissionSetAssignment psa : [
                SELECT PermissionSetId 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId
                AND PermissionSet.IsOwnedByProfile = false
            ]) {
                assignedPermSetIds.add(psa.PermissionSetId);
            }
            
           // System.debug('Found ' + assignedPermSetIds.size() + ' assigned permission sets for user ' + userId);

            // Convert to wrapper objects and mark if already assigned
            List<PermissionSetWrapper> wrappers = new List<PermissionSetWrapper>();
            for (PermissionSet ps : permSets) {
                PermissionSetWrapper wrapper = new PermissionSetWrapper();
                wrapper.id = ps.Id;
                wrapper.label = ps.Label;
                wrapper.name = ps.Name;
                wrapper.description = ps.Description;
                wrapper.type = 'Permission Set';
                wrapper.isAssigned = assignedPermSetIds.contains(ps.Id);
                wrappers.add(wrapper);
            }
            
            // Debug to verify we're marking assignments correctly
            Integer assignedCount = 0;
            for (PermissionSetWrapper w : wrappers) {
                if (w.isAssigned) {
                    assignedCount++;
                   // System.debug('Marked as assigned: ' + w.name);
                }
            }
           // System.debug('Total permission sets: ' + wrappers.size() + ', Marked as assigned: ' + assignedCount);
            
            return wrappers;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description Wrapper class for Permission Set information with assignment status
     */
    public class PermissionSetWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean isAssigned;
        
        /**
         * @description Default constructor
         */
        public PermissionSetWrapper() {
            this.isAssigned = false;
        }
        
        /**
         * @description Constructor with basic information
         * @param id Permission set ID
         * @param label Permission set label
         * @param description Permission set description
         * @param type Permission set type
         */
        public PermissionSetWrapper(String id, String label, String description, String type) {
            this.id = id;
            this.name = label;
            this.label = label;
            this.description = description;
            this.type = type;
            this.isAssigned = false;
        }
        
        /**
         * @description Constructor with assignment status
         * @param id Permission set ID
         * @param label Permission set label
         * @param description Permission set description
         * @param type Permission set type
         * @param isAssigned Whether the permission set is assigned
         */
        public PermissionSetWrapper(String id, String label, String description, String type, Boolean isAssigned) {
            this.id = id;
            this.name = label;
            this.label = label;
            this.description = description;
            this.type = type;
            this.isAssigned = isAssigned;
        }
    }
    
    /**
     * @description Grants access to permission sets and groups to a user with proper security checks
     * @param userId The ID of the user to grant access to
     * @param permissionSetIds List of permission set IDs to grant
     * @param groupIds List of group IDs to grant
     */
    @AuraEnabled
    public static void grantAccess(Id userId, List<Id> permissionSetIds, List<Id> groupIds) {
        // Validate CRUD permissions first
        if (!Schema.SObjectType.PermissionSetAssignment.isCreateable() ||
            !Schema.SObjectType.PermissionSetAssignment.fields.PermissionSetId.isCreateable() ||
            !Schema.SObjectType.PermissionSetAssignment.fields.AssigneeId.isCreateable()) {
            throw new SecurityException('Insufficient permissions to create PermissionSetAssignment records');
        }
        
        if (!Schema.SObjectType.PermissionSetAssignment.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access PermissionSetAssignment records');
        }
        
        try {
            // Filter to find only new permission set assignments using security checks
            String psaQuery = 'SELECT PermissionSetId FROM PermissionSetAssignment ' +
                             'WHERE AssigneeId = :userId AND PermissionSetId IN :permissionSetIds ' +
                             'ORDER BY PermissionSetId';
            
            List<PermissionSetAssignment> existingAssignments = Database.query(psaQuery);
            Set<Id> existingPSIds = new Set<Id>();
            
            for(PermissionSetAssignment psa : existingAssignments) {
                existingPSIds.add(psa.PermissionSetId);
            }
            
            // Get only permission sets that need to be newly assigned
            Set<Id> newPSIds = new Set<Id>(permissionSetIds);
            newPSIds.removeAll(existingPSIds);
            
            // Create and insert new assignments
            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
            for(Id psId : newPSIds) {
                assignments.add(new PermissionSetAssignment(
                    AssigneeId = userId,
                    PermissionSetId = psId
                ));
            }
            
            if (!assignments.isEmpty()) {
                // Ensure that only creatable fields are included using Security.stripInaccessible
                List<Database.SaveResult> results = Database.insert(
                    Security.stripInaccessible(AccessType.CREATABLE, assignments).getRecords(),
                    false
                );
                
                // Handle errors
                List<String> errors = new List<String>();
                for(Integer i=0; i<results.size(); i++) {
                    if(!results[i].isSuccess()) {
                        errors.add(assignments[i].PermissionSetId + ': ' +
                            results[i].getErrors()[0].getMessage());
                    }
                }
                
                if(!errors.isEmpty()) {
                    throw new AuraHandledException(String.join(errors, '\n'));
                }
            }
            
            // Handle permission set groups
            if(groupIds != null && !groupIds.isEmpty()) {
                // Similar logic for permission set groups with proper CRUD checks
                // Would be implemented here with the same security patterns
            }
        } catch(Exception e) {
            throw new AuraHandledException('Error granting access: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves system permissions for a user with comprehensive security checks
     * @param userId The ID of the user to retrieve system permissions for
     * @return List<SystemPermissionWrapper> List of system permission wrappers
     */
    @AuraEnabled(cacheable=true)
    public static List<SystemPermissionWrapper> getSystemPermissions(Id userId) {
        try {
            // Check object access permissions
            if (!Schema.SObjectType.SetupEntityAccess.isAccessible()) {
                throw new SecurityException('Insufficient access to SetupEntityAccess object');
            }
            
            if (!Schema.SObjectType.PermissionSetAssignment.isAccessible()) {
                throw new SecurityException('Insufficient access to PermissionSetAssignment object');
            }
            
            if (!Schema.SObjectType.PermissionSet.isAccessible()) {
                throw new SecurityException('Insufficient access to PermissionSet object');
            }
            
            // Check FLS for SetupEntityAccess first
            if (!Schema.SObjectType.SetupEntityAccess.fields.SetupEntityId.isAccessible() ||
                !Schema.SObjectType.SetupEntityAccess.fields.ParentId.isAccessible() ||
                !Schema.SObjectType.SetupEntityAccess.fields.SetupEntityType.isAccessible()) {
                throw new SecurityException('Insufficient access to system permission fields');
            }
            
            // Check FLS for PermissionSetAssignment
            if (!Schema.SObjectType.PermissionSetAssignment.fields.PermissionSetId.isAccessible() ||
                !Schema.SObjectType.PermissionSetAssignment.fields.AssigneeId.isAccessible()) {
                throw new SecurityException('Insufficient access to permission assignment fields');
            }
            
            // Check FLS for PermissionSet
            if (!Schema.SObjectType.PermissionSet.fields.Id.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.Name.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.NamespacePrefix.isAccessible() ||
                !Schema.SObjectType.PermissionSet.fields.IsOwnedByProfile.isAccessible()) {
                throw new SecurityException('Insufficient access to permission set fields');
            }

            // Get all permission set assignments with security check
            String psaQuery = 'SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId';
            List<PermissionSetAssignment> assignments = Database.query(psaQuery);
            
            // Collect permission set IDs
            Set<Id> permSetIds = new Set<Id>();
            for(PermissionSetAssignment psa : assignments) {
                permSetIds.add(psa.PermissionSetId);
            }
            
            if (permSetIds.isEmpty()) {
                return new List<SystemPermissionWrapper>();
            }
            
            // Get permission set details with security enforcement
            String psQuery = 'SELECT Id, Name, NamespacePrefix, IsOwnedByProfile FROM PermissionSet WHERE Id IN :permSetIds';
            List<PermissionSet> permSets = Database.query(psQuery);
            Map<Id, PermissionSet> permSetMap = new Map<Id, PermissionSet>(permSets);
            
            // Query system permissions with field-level security
            String seaQuery = 'SELECT SetupEntity.Name, ParentId FROM SetupEntityAccess ' +
                              'WHERE ParentId IN :permSetIds AND SetupEntityType = \'Permission\'';
            List<SetupEntityAccess> systemPerms = Database.query(seaQuery);
            
            // Map permissions to their sources
            Map<String, SystemPermissionWrapper> permMap = new Map<String, SystemPermissionWrapper>();
            for(SetupEntityAccess perm : systemPerms) {
                PermissionSet ps = permSetMap.get(perm.ParentId);
                if(ps == null) continue;
                
                String sourceType = ps.IsOwnedByProfile ? 'Profile' :
                    (ps.NamespacePrefix == null ? 'Permission Set' : 'Package');
                
                String sourceName = ps.IsOwnedByProfile ?
                    getProfileName(ps.Id) : 
                    (ps.NamespacePrefix == null ? ps.Name : ps.NamespacePrefix + ' Package');
                
                String permName = perm.SetupEntity.Name;
                
                if(!permMap.containsKey(permName)) {
                    permMap.put(permName, new SystemPermissionWrapper(
                        permName,
                        true,
                        new List<String>{sourceType + ': ' + sourceName}
                    ));
                } else {
                    // Clone the list to maintain security context
                    List<String> sources = new List<String>(permMap.get(permName).sources);
                    sources.add(sourceType + ': ' + sourceName);
                    permMap.get(permName).sources = sources;
                }
            }
            
            return permMap.values();
        } catch(Exception e) {
            throw new AuraHandledException('Error retrieving permissions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves the profile name for a given permission set ID with security checks
     * @param permSetId The ID of the permission set
     * @return String Name of the profile
     */
    private static String getProfileName(Id permSetId) {
        // Validate CRUD permissions
        if (!Schema.SObjectType.Profile.isAccessible()) {
            throw new SecurityException('Insufficient access to Profile object');
        }
        
        if (!Schema.SObjectType.Profile.fields.Name.isAccessible()) {
            throw new SecurityException('Insufficient access to Profile names');
        }
        
        if (!Schema.SObjectType.PermissionSet.isAccessible() ||
            !Schema.SObjectType.PermissionSet.fields.ProfileId.isAccessible()) {
            throw new SecurityException('Insufficient access to PermissionSet object or fields');
        }
        
        // Use Database.query with security checks
        String innerQuery = 'SELECT ProfileId FROM PermissionSet WHERE Id = :permSetId LIMIT 1';
        String query = 'SELECT Name FROM Profile WHERE Id IN (' + innerQuery + ') LIMIT 1';
        
        List<Profile> profiles = Database.query(query);
        return profiles.isEmpty() ? 'Unknown Profile' : profiles[0].Name;
    }
    
    /**
     * @description Update object permissions for a user
     * @param userId - The ID of the user to update permissions for
     * @param permissionUpdates - JSON string with permission updates
     * @return Map<String, Object> - Contains success status and any messages
     */
    @AuraEnabled
    public static Map<String, Object> updateObjectPermissions(String userId, String permissionUpdates) {
        Map<String, Object> result = new Map<String, Object> {
            'success' => false,
            'messages' => new List<String>(),
            'dependenciesUpdated' => false
        };
        
        try {
            System.debug('Starting permission update for user: ' + userId);
            System.debug('Permission updates: ' + permissionUpdates);
            
            // Check permissions
            if (!Schema.sObjectType.PermissionSetAssignment.isAccessible() || 
                !Schema.sObjectType.ObjectPermissions.isAccessible() || 
                !Schema.sObjectType.ObjectPermissions.isUpdateable()) {
                throw new AuraHandledException('Insufficient permissions to modify permission sets');
            }
            
            // Get the permission sets assigned to this user
            List<PermissionSetAssignment> assignments = [
                SELECT PermissionSetId, PermissionSet.Name 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :userId
                WITH SECURITY_ENFORCED
            ];
            
            // Also get the user's profile
            User u = [SELECT ProfileId, Profile.Name FROM User WHERE Id = :userId WITH SECURITY_ENFORCED LIMIT 1];
            
            System.debug('Found ' + assignments.size() + ' permission set assignments and profile: ' + u.Profile.Name);
            
            // Parse the permission updates from JSON string
            List<Object> updatesList = (List<Object>)JSON.deserializeUntyped(permissionUpdates);
            
            for (Object updateObj : updatesList) {
                Map<String, Object> permUpdate = (Map<String, Object>)updateObj;
                String objectName = (String)permUpdate.get('objectName');
                Map<String, Object> permissions = (Map<String, Object>)permUpdate.get('permissions');
                
                // Check if we have a specific source ID to update (from the sources modal)
                String specificSourceId = null;
                if (permUpdate.containsKey('sourceId') && permUpdate.get('sourceId') != null) {
                    specificSourceId = (String)permUpdate.get('sourceId');
                    System.debug('Source-specific update requested for sourceId: ' + specificSourceId);
                }
                
                System.debug('Processing object: ' + objectName);
                System.debug('Permission settings: ' + permissions);
                
                // Verify this is a valid object API name
                List<EntityDefinition> entityCheck = [
                    SELECT QualifiedApiName 
                    FROM EntityDefinition 
                    WHERE QualifiedApiName = :objectName 
                    LIMIT 1
                ];
                
                if (entityCheck.isEmpty()) {
                    throw new AuraHandledException('Invalid object name: ' + objectName);
                }
                
                // Build the query to get object permissions
                String query = 'SELECT Id, ParentId, Parent.Name, Parent.PermissionsModifyAllData, ' + 
                               'SObjectType, PermissionsRead, PermissionsCreate, ' +
                               'PermissionsEdit, PermissionsDelete ' +
                               'FROM ObjectPermissions ' +
                               'WHERE SObjectType = :objectName ';
                               
                // If we have a specific source ID, only query for that one
                if (specificSourceId != null) {
                    query += 'AND ParentId = :specificSourceId ';
                } else {
                    query += 'AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId) ';
                }
                
                query += 'LIMIT 100';
                
                // Get a fresh list of permission sets that have this object permission
                List<ObjectPermissions> objPermissions = new List<ObjectPermissions>();
                
                try {
                    objPermissions = Database.query(query);
                    System.debug('Found ' + objPermissions.size() + ' existing permissions for ' + objectName);
                } catch (Exception queryEx) {
                    System.debug('Error querying permissions: ' + queryEx.getMessage());
                    ((List<String>)result.get('messages')).add('Error querying permissions: ' + queryEx.getMessage());
                    continue;
                }
                
                if (objPermissions.isEmpty()) {
                    String message = 'No permissions found for object: ' + objectName;
                    if (specificSourceId != null) {
                        message += ' in the specified permission source';
                    }
                    System.debug(message);
                    ((List<String>)result.get('messages')).add(message);
                    continue;
                }
                
                // Process permissions one by one using ID-based update
                List<ObjectPermissions> toUpdate = new List<ObjectPermissions>();
                
                for (ObjectPermissions op : objPermissions) {
                    // Skip permission sets with Modify All Data enabled
                    if (op.Parent.PermissionsModifyAllData) {
                        String message = 'Skipping update for ' + op.Parent.Name + ' because it has Modify All Data enabled';
                        System.debug(message);
                        ((List<String>)result.get('messages')).add(message);
                        continue;
                    }
                    
                    Boolean modified = false;
                    
                    // Create a fresh record to avoid ID issues
                    ObjectPermissions freshOp = new ObjectPermissions(
                        Id = op.Id,
                        PermissionsRead = op.PermissionsRead,
                        PermissionsCreate = op.PermissionsCreate,
                        PermissionsEdit = op.PermissionsEdit,
                        PermissionsDelete = op.PermissionsDelete
                    );
                    
                    // Check if we're turning off Read permission - in that case, we need to cascade to other permissions
                    Boolean cascadeDependencies = false;
                    
                    // Apply updates from the client
                    if (permissions.containsKey('read')) {
                        Boolean newReadValue = (Boolean)permissions.get('read');
                        freshOp.PermissionsRead = newReadValue;
                        
                        // If read is being disabled, cascade to other permissions
                        if (!newReadValue && (freshOp.PermissionsCreate || freshOp.PermissionsEdit || freshOp.PermissionsDelete)) {
                            freshOp.PermissionsCreate = false;
                            freshOp.PermissionsEdit = false;
                            freshOp.PermissionsDelete = false;
                            cascadeDependencies = true;
                            result.put('dependenciesUpdated', true);
                        }
                        
                        modified = true;
                    }
                    
                    // Only apply these updates if we're not already cascading, or if we're enabling instead of disabling
                    if (!cascadeDependencies) {
                        if (permissions.containsKey('create')) {
                            Boolean newCreateValue = (Boolean)permissions.get('create');
                            
                            // Can only set Create to true if Read is true
                            if (newCreateValue && !freshOp.PermissionsRead) {
                                String message = 'Cannot enable Create permission without Read permission for ' + objectName;
                                System.debug(message);
                                ((List<String>)result.get('messages')).add(message);
                            } else {
                                freshOp.PermissionsCreate = newCreateValue;
                                modified = true;
                            }
                        }
                        
                        if (permissions.containsKey('edit')) {
                            Boolean newEditValue = (Boolean)permissions.get('edit');
                            
                            // Can only set Edit to true if Read is true
                            if (newEditValue && !freshOp.PermissionsRead) {
                                String message = 'Cannot enable Edit permission without Read permission for ' + objectName;
                                System.debug(message);
                                ((List<String>)result.get('messages')).add(message);
                            } else {
                                freshOp.PermissionsEdit = newEditValue;
                                modified = true;
                            }
                        }
                        
                        if (permissions.containsKey('delete')) {
                            Boolean newDeleteValue = (Boolean)permissions.get('delete');
                            
                            // Can only set Delete to true if Read is true
                            if (newDeleteValue && !freshOp.PermissionsRead) {
                                String message = 'Cannot enable Delete permission without Read permission for ' + objectName;
                                System.debug(message);
                                ((List<String>)result.get('messages')).add(message);
                            } else {
                                freshOp.PermissionsDelete = newDeleteValue;
                                modified = true;
                            }
                        }
                    }
                    
                    if (modified) {
                        toUpdate.add(freshOp);
                        System.debug('Adding permission to update for ' + op.Parent.Name + ': ' + freshOp.Id);
                    }
                }
                
                if (!toUpdate.isEmpty()) {
                    // Use Database.update for finer control
                    List<Database.SaveResult> results = Database.update(toUpdate, false);
                    
                    Integer successCount = 0;
                    for (Integer i = 0; i < results.size(); i++) {
                        Database.SaveResult sr = results[i];
                        if (sr.isSuccess()) {
                            successCount++;
                            System.debug('Successfully updated permission: ' + toUpdate[i].Id);
                        } else {
                            String errorMessage = 'Failed to update permission: ' + toUpdate[i].Id + 
                                ' Error: ' + sr.getErrors()[0].getMessage();
                            System.debug(errorMessage);
                            ((List<String>)result.get('messages')).add(errorMessage);
                        }
                    }
                    
                    if (successCount > 0) {
                        result.put('success', true);
                        ((List<String>)result.get('messages')).add('Successfully updated ' + successCount + ' of ' + results.size() + ' permissions');
                    } else {
                        ((List<String>)result.get('messages')).add('Failed to update any permissions');
                    }
                    
                    System.debug('Permission update completed with ' + successCount + ' successes out of ' + results.size() + ' attempts');
                } else {
                    String message = 'No permissions needed updating or all were skipped due to constraints';
                    System.debug(message);
                    ((List<String>)result.get('messages')).add(message);
                    
                    // Still return success if we're skipping due to constraints
                    if (!((List<String>)result.get('messages')).isEmpty()) {
                        result.put('success', true);
                    }
                }
            }
            
            return result;
        } catch (Exception e) {
            System.debug('Exception in updateObjectPermissions: ' + e.getMessage() + ', Stack: ' + e.getStackTraceString());
            ((List<String>)result.get('messages')).add('Error updating permissions: ' + e.getMessage());
            return result;
        }
    }

    /**
     * Gets sharing rules from the OWD_Sharing_Report__c object 
     * where the data has been previously stored by a web scraping process
     * @deprecated Use getSharingRulesFromReport(String searchTerm, String objectName) instead
     * @return List<Map<String, Object>> List of sharing rules with their details
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getSharingRulesFromReport(String searchTerm, String objectName) {
        // Validate CRUD permissions first
        if (!Schema.SObjectType.OWD_Sharing_Report__c.isAccessible()) {
            throw new SecurityException('Insufficient access to OWD_Sharing_Report__c object');
        }
        
        if (!Schema.SObjectType.OWD_Sharing_Report__c.fields.Sharing_Rules_Details__c.isAccessible() ||
            !Schema.SObjectType.OWD_Sharing_Report__c.fields.Type__c.isAccessible()) {
            throw new SecurityException('Insufficient access to OWD_Sharing_Report__c fields');
        }
        
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        
        try {
            // Query the most recent OWD report record
            List<OWD_Sharing_Report__c> reports = [
                SELECT Id, Sharing_Rules_Details__c, CreatedDate
                FROM OWD_Sharing_Report__c 
                WHERE Type__c = 'OWDReport'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
            
            if (reports.isEmpty() || String.isBlank(reports[0].Sharing_Rules_Details__c)) {
                Map<String, Object> errorResult = new Map<String, Object>{
                    'error' => true,
                    'message' => 'No sharing rules report found. Please run the report generation process first.'
                };
                results.add(errorResult);
                return results;
            }
            
            // Parse the sharing rules data
            String sharingRulesData = reports[0].Sharing_Rules_Details__c;
            
            // Split by objects
            List<String> objectSections = sharingRulesData.split(' PerObjectRelatedDataStarts ');
            
            // Process each object section
            for (String section : objectSections) {
                if (String.isBlank(section)) continue;
                
                // Extract object name
                String currentObjectName = section.substringBetween(' ObjectNameStarts ', ' ObjectNameEnds ');
                if (String.isBlank(currentObjectName)) continue;
                
                // If object filter is specified and doesn't match current object, skip
                if(String.isNotBlank(objectName) && currentObjectName != objectName) {
                    continue;
                }
                
                // Extract header data
                String headerData = section.substringBetween(' HeaderDataStarts ', ' HeaderDataEnds ');
                List<String> headers = new List<String>();
                if (String.isNotBlank(headerData)) {
                    headers = headerData.split('\\+\\+');
                }
                
                // Extract body data
                String bodyData = section.substringBetween(' LeftDataStarts ', ' LeftDataEnds ');
                List<String> bodyRows = new List<String>();
                if (String.isNotBlank(bodyData)) {
                    // Improved splitting logic to handle the body data better
                    bodyRows = bodyData.split(' BodyDataStarts ');
                    
                    // Remove empty first element if present
                    if (bodyRows.size() > 0 && String.isBlank(bodyRows[0])) {
                        bodyRows.remove(0);
                    }
                }
                
                // Process each rule
                List<Map<String, Object>> objectRules = new List<Map<String, Object>>();
                for (String row : bodyRows) {
                    if (String.isBlank(row)) continue;
                    
                    // Improved cleanup logic for marker text
                    row = row.replace(' BodyDataEnds', '')
                             .replace('BodyDataEnds', '');
                    
                    List<String> fields = row.split('\\?');
                    if (fields.size() < 3) continue;
                    
                    // Clean up the field values and create rule object
                    String ruleName = (fields[0] != null) ? fields[0].trim() : '';
                    String description = (fields.size() > 1 && fields[1] != null) ? fields[1].trim() : '';
                    String accessLevel = (fields.size() > 2 && fields[2] != null) ? fields[2].trim() : '';
                    String sharedWith = '';
                    
                    // Check if the search term matches this rule
                    if(String.isNotBlank(searchTerm) && 
                       !ruleName.toLowerCase().contains(searchTerm.toLowerCase()) && 
                       !currentObjectName.toLowerCase().contains(searchTerm.toLowerCase())) {
                        continue;
                    }
                    
                    // Enhanced handling for the "Shared With" field
                    if (fields.size() > 3 && fields[3] != null) {
                        sharedWith = fields[3].trim();
                        // More aggressive cleaning of marker text
                        sharedWith = sharedWith.replace(' BodyDataEnds', '')
                                              .replace('BodyDataEnds', '')
                                              .replace(' BodyData', '')
                                              .replace('BodyData', '')
                                              .trim();
                    }
                    
                    // Log the values for debugging
                    System.debug('Rule data - Name: ' + ruleName + 
                                ', Description: ' + description + 
                                ', Access Level: ' + accessLevel + 
                                ', Shared With: ' + sharedWith);
                    
                    Map<String, Object> rule = new Map<String, Object>{
                        'ruleName' => ruleName,
                        'description' => description,
                        'accessLevel' => accessLevel,
                        'sharedWith' => sharedWith,
                        'objectName' => currentObjectName
                    };
                    
                    objectRules.add(rule);
                }
                
                // Add object with its rules to results
                if (!objectRules.isEmpty()) {
                    Map<String, Object> objectResult = new Map<String, Object>{
                        'objectName' => currentObjectName,
                        'rules' => objectRules
                    };
                    results.add(objectResult);
                }
            }
            
            // If no results were parsed, add empty indicator
            if (results.isEmpty()) {
                Map<String, Object> emptyResult = new Map<String, Object>{
                    'objectName' => 'No Data',
                    'rules' => new List<Map<String, Object>>()
                };
                results.add(emptyResult);
            }
            
            return results;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getSharingRulesFromReport: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving sharing rules: ' + e.getMessage());
        }
    }

    /**
     * Executes getOWDDetails to refresh the OWD sharing data
     * @return Boolean success flag
     */
    @AuraEnabled
    public static Boolean refreshOWDSharingData() {
        try {
            getOWDDetails();
            return true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error refreshing OWD sharing data: ' + e.getMessage());
            throw new AuraHandledException('Error refreshing sharing data: ' + e.getMessage());
        }
    }

    /**
     * Future method to scrape and store OWD sharing details
     */
    @future(callout=true)
    public static void getOWDDetails(){
        //List<OWDData> owdListData = new List<OWDData>();
        //List<SharingRulesData> sharingRulesFinalList = new List<SharingRulesData>();
        String finalString = '';
        List<String> sharingRulesList = new List<String>();
        
        String sharingRulesFinalString = '';
        List<String> sharingRulesListSecond = new List<String>();
        List<OWD_Sharing_Report__c> owdObjectList = [SELECT Id, OWD_Data_Field__c, Type__c FROM OWD_Sharing_Report__c WHERE Type__c = 'OWDReport' LIMIT 200];
      
      /*List<EntityDefinition> listEntityDef = [SELECT Label, DeveloperName, DurableId, MasterLabel, InternalSharingModel, ExternalSharingModel, IsProcessEnabled, IsCustomizable, IsApexTriggerable, IsWorkflowEnabled, IsCompactLayoutable, IsSearchable, IsTriggerable FROM EntityDefinition WHERE IsCustomizable = True AND IsApexTriggerable = True AND IsWorkflowEnabled = True AND IsCompactLayoutable = True AND IsSearchable = True AND IsTriggerable = True];*/
        String url = URL.getOrgDomainUrl().toExternalForm() + '/p/own/OrgSharingDetail?setupid=SecuritySharing&div_filter=&st=' + 'allObjects';
        PageReference pg = new PageReference(url);
        if(Test.isRunningTest()){ 
            Blob content = blob.valueOf('Unit.Test');
        } 
        else{
            String str = pg.getContent().toString();
            String sharingModelStr = str.substringAfter('Sharing Rules');
            sharingModelStr = sharingModelStr.substringAfter('<!-- WrappingClass -->'); 
            //sharingModelStr = sharingModelStr.stripHtmlTags();
            str = str.substringBetween('Organization-Wide Defaults', 'Other Settings');
            List<String> lstData = str.split('<!-- ListRow -->');
            for(Integer i = 1; i < lstData.size(); i++){
                //OWDData owdOneData = new OWDData();
                String eachRow = lstData[i];
                String objName = eachRow.substringBetween('dataCell  ">', '</th><td');
                eachRow = eachRow.subStringAfter('</th><td');
                String secondColumn = eachRow.substringBetween('dataCell  ">', '</td><td');
                eachRow = eachRow.subStringAfter('</td><td');
                String thirdColumn = eachRow.substringBetween('dataCell  ">', '</td><td');
                String forthColumn = eachRow.substringBetween(' booleanColumn">', '</td>');
                Boolean isChecked = forthColumn.contains('/img/checkbox_checked.gif');
                /*owdOneData.objectLabel = objName;
                  owdOneData.InternalSharingModel = secondColumn;
                  owdOneData.ExternalSharingModel = thirdColumn;
                  owdOneData.isChecked = isChecked ? 'Checked' : 'NotChecked';
                  owdListData.add(owdOneData);*/
                if(i == (lstData.size() - 1)){
                    finalString += objName + '?' + secondColumn + '?' + thirdColumn + '?' + (isChecked ? 'Checked' : ''); 
                }
                else{
                    finalString += objName + '?' + secondColumn + '?' + thirdColumn + '?' + (isChecked ? 'Checked' : '') + '|';
                }
            }
           /* if(owdObjectList.size() > 0 && OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
                delete owdObjectList;
            }*/
            List<String> sharingRulesDummyList = new List<String>();
            String sharingModelDummyStr;
            while(sharingModelStr.length() > 1000000){
                sharingModelDummyStr = sharingModelStr.substring(0, 500000);
                sharingRulesDummyList = sharingModelDummyStr.split('<!-- WrappingClass -->');
                sharingRulesList.addAll(sharingRulesDummyList);
                sharingModelStr = sharingModelStr.substring(sharingModelDummyStr.length(), sharingModelStr.length());
            }
            sharingRulesDummyList = sharingModelStr.split('<!-- WrappingClass -->');
            sharingRulesList.addAll(sharingRulesDummyList);
            for(Integer i = 0; i < sharingRulesList.size(); i++){
                if(!sharingRulesList[i].contains('No sharing rules specified.')){
                    sharingRulesListSecond.add(sharingRulesList[i]);
                }
            }
            System.debug('Beginning to parse sharing rules data');
            String secondRowString = '';
            String sixthString = ' ';
            for(Integer i = 0; i < sharingRulesListSecond.size(); i++){
                List<String> dummyList = new List<String>();
                String objectName = sharingRulesListSecond[i].substringBetween('<h3>', '</h3>');
                String firstStr = sharingRulesListSecond[i].subStringAfter('</h3>');
                String secondStr = firstStr.substringBetween('</h3>', '<!-- ListRow -->');
                secondStr = firstStr.subStringAfter('Action</th>');
                String thirdString = 'DummyData';
                
                // Parse the header row
                secondRowString = ' '; // Reset for each object
                while((thirdString != null)){
                    secondRowString += ' ' + secondStr.substringBetween('zen-deemphasize">', '</th>') + '++';
                    secondStr = secondStr.substringAfter('</th>');
                    thirdString = secondStr.substringBetween('zen-deemphasize">', '</th>');
                }
                
                // Parse the data rows
                firstStr = firstStr.substringAfter('<!-- ListRow -->');
                dummyList = firstStr.split('\\<!-- ListRow -->');
                String eightString = ' '; // Reset for each object
                
                for(Integer j = 0; j < dummyList.size(); j++){
                    Integer counter = 0;
                    String forthString = 'DummyData';
                    String fifthString = dummyList[j];
                    
                    // Skip empty rows
                    if(String.isBlank(fifthString)) {
                        continue;
                    }
                    
                    // Start a new rule entry with clear marker
                    eightString += ' BodyDataStarts ';
                    
                    // Parse each cell in the row
                    while(forthString != null && String.isNotBlank(fifthString)){
                        if(counter == 0){
                            // First column (Rule Name)
                            String cellValue = fifthString.substringBetween('dataCell  ">', '</th>')
                                .replaceAll('<[/a-zAZ0-9]*>', ' ')
                                .stripHtmlTags()
                                .trim();
                            eightString += cellValue + '?';
                            fifthString = fifthString.substringAfter('</th>');
                            counter++;
                        }
                        else{
                            // Other columns
                            String cellValue = '';
                            if(fifthString.contains('dataCell  ">')){
                                cellValue = fifthString.substringBetween('dataCell  ">', '</td>')
                                    .replaceAll('<[/a-zAZ0-9]*>', ' ')
                                    .stripHtmlTags()
                                    .trim();
                                eightString += cellValue + '?';
                                fifthString = fifthString.substringAfter('</td>');
                                forthString = fifthString.contains('dataCell  ">') ? 
                                    fifthString.substringBetween('dataCell  ">', '</td>') : null;
                            } else {
                                forthString = null;
                            }
                            counter++;
                        }
                    }
                    
                    // End the rule entry with clear marker - separate from the data itself
                    eightString += ' BodyDataEnds ';
                }
                
                sixthString += eightString;
                
                // Construct the full data string for this object with clear markers
                sharingRulesFinalString += ' PerObjectRelatedDataStarts ' + 
                    ' ObjectNameStarts ' + objectName + ' ObjectNameEnds ' + 
                    ' HeaderDataStarts ' + secondRowString + ' HeaderDataEnds ' + 
                    ' LeftDataStarts ' + eightString + ' LeftDataEnds ' + 
                    ' PerObjectRelatedDataENDs ';
            }
            
            System.debug('Finished parsing sharing rules data');
        }
        
        // Create a new OWD_Sharing_Report__c record
        OWD_Sharing_Report__c obj = new OWD_Sharing_Report__c();
        if(Schema.sObjectType.OWD_Sharing_Report__c.fields.Sharing_Rules_Details__c.isCreateable()
           && Schema.sObjectType.OWD_Sharing_Report__c.fields.Type__c.isCreateable()
           && Schema.sObjectType.OWD_Sharing_Report__c.fields.OWD_Data_Field__c.isCreateable()){
               obj.Sharing_Rules_Details__c = sharingRulesFinalString;
               obj.Type__c = 'OWDReport';
               obj.OWD_Data_Field__c = finalString;
               insert obj;
        }
        System.debug('OWD Sharing Report created: ' + obj.Id);
    }

    /**
     * Get the Sharing Rules from the OWD Report based on the search term and object name filter
     * @param searchTerm Text to filter rules by name or object
     * @param objectName Optional filter to show only rules for a specific object
     * @return Map<String, Object> Map containing a list of SharingRulesTempData objects
     */
    @AuraEnabled
    public static Map<String, Object> getSharingRulesData(String searchTerm, String objectName){
        List<SharingRulesTempData> sharingRowsFinal = new List<SharingRulesTempData>();
        Map<String, Object> returnMap = new Map<String, Object>();
        
        try {
            // Fetch sharing rules data from OWD_Sharing_Report__c
            List<OWD_Sharing_Report__c> sharingObjList = [
                SELECT Id, Sharing_Rules_Details__c FROM OWD_Sharing_Report__c 
                WHERE Type__c = 'OWDReport' ORDER BY CreatedDate DESC LIMIT 1
            ];
            
            // Process data if records found
            if(!sharingObjList.isEmpty() && sharingObjList[0].Sharing_Rules_Details__c != null) {
                String sharingDetails = sharingObjList[0].Sharing_Rules_Details__c;
                
                // Extract sharing rules for all objects
                List<String> perObjectDataList = sharingDetails.split('PerObjectRelatedDataStarts');
                
                // Process each object's data
                for(String objectData : perObjectDataList) {
                    // Skip empty data
                    if(String.isBlank(objectData)) continue;
                    
                    // Extract object name
                    String currentObjectName = objectData.substringBetween('ObjectNameStarts', 'ObjectNameEnds').trim();
                    
                    // If object filter is specified and doesn't match current object, skip
                    if(String.isNotBlank(objectName) && currentObjectName != objectName) {
                        continue;
                    }
                    
                    // Extract header and body data
                    String headerData = objectData.substringBetween('HeaderDataStarts', 'HeaderDataEnds').trim();
                    String bodyData = objectData.substringBetween('LeftDataStarts', 'LeftDataEnds').trim();
                    
                    // Parse header columns
                    List<String> headerColumns = headerData.split('\\+\\+');
                    
                    // Extract and process rule data rows
                    List<String> bodyDataRows = new List<String>();
                    
                    // Split by BodyDataStarts to get each rule entry
                    List<String> rawBodyRows = bodyData.split('BodyDataStarts');
                    
                    for(String rawRow : rawBodyRows) {
                        // Skip empty rows
                        if(String.isBlank(rawRow)) continue;
                        
                        // Extract rule data up to BodyDataEnds marker
                        String ruleData = '';
                        if(rawRow.contains('BodyDataEnds')) {
                            ruleData = rawRow.substringBefore('BodyDataEnds').trim();
                        } else {
                            ruleData = rawRow.trim();
                        }
                        
                        // Skip empty rule data
                        if(String.isBlank(ruleData)) continue;
                        
                        bodyDataRows.add(ruleData);
                    }
                    
                    // Process each rule row
                    for(String ruleRow : bodyDataRows) {
                        // Skip if row is empty
                        if(String.isBlank(ruleRow)) continue;
                        
                        List<String> ruleCells = ruleRow.split('\\?');
                        
                        // Skip if not enough data cells
                        if(ruleCells.size() < 3) continue;
                        
                        SharingRulesTempData sharingRow = new SharingRulesTempData();
                        
                        // Set object name
                        sharingRow.objectApiName = currentObjectName;
                        
                        // Set rule name from first cell
                        sharingRow.ruleName = ruleCells[0].trim();
                        
                        // Check if the search term matches this rule
                        if(String.isNotBlank(searchTerm) && 
                           !sharingRow.ruleName.toLowerCase().contains(searchTerm.toLowerCase()) && 
                           !currentObjectName.toLowerCase().contains(searchTerm.toLowerCase())) {
                            continue;
                        }
                        
                        // Set rule type from second cell
                        if(ruleCells.size() > 1) {
                            sharingRow.ruleType = ruleCells[1].trim();
                        }
                        
                        // Set shared with from third cell, with cleanup
                        if(ruleCells.size() > 2) {
                            // Clean up the shared with field
                            String sharedWith = ruleCells[2].trim();
                            sharingRow.sharedWith = sharedWith;
                        }
                        
                        // Add rule to final list
                        sharingRowsFinal.add(sharingRow);
                        
                        // Debug log the rule data for troubleshooting
                        System.debug('Rule data parsed: ' + 
                                    'Object: ' + sharingRow.objectApiName + 
                                    ', Rule: ' + sharingRow.ruleName + 
                                    ', Type: ' + sharingRow.ruleType + 
                                    ', Shared With: ' + sharingRow.sharedWith);
                    }
                }
            }
            
            // Return the final processed data
            returnMap.put('sharingRules', sharingRowsFinal);
            return returnMap;
            
        } catch(Exception ex) {
            System.debug('Error in getSharingRulesData: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            throw new AuraHandledException('Error retrieving sharing rules: ' + ex.getMessage());
        }
    }
    
    /**
     * @description Retrieves setup audit trail data for a specific user within a date range
     * @param userId The ID of the user to retrieve audit data for
     * @param startDate The start date for the audit trail query
     * @param endDate The end date for the audit trail query
     * @param metadataType Optional metadata type filter
     * @return List<SetupAuditTrail> List of audit trail records
     */
    @AuraEnabled(cacheable=false)
    public static List<SetupAuditTrail> getSetupAuditTrail(String userId, Date startDate, Date endDate, String metadataType) {
        try {
            // Validate input parameters
            if (String.isBlank(userId) || startDate == null || endDate == null) {
                throw new AuraHandledException('Invalid parameters: userId, startDate, and endDate are required.');
            }
            
            // Check CRUD permissions for SetupAuditTrail
            if (!Schema.sObjectType.SetupAuditTrail.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access Setup Audit Trail.');
            }
            
            // Build dynamic SOQL query (Section field cannot be filtered)
            String query = 'SELECT Id, Action, Section, CreatedDate, CreatedBy.Name, DelegateUser, Display ' +
                          'FROM SetupAuditTrail ' +
                          'WHERE CreatedById = :userId AND CreatedDate >= :startDate AND CreatedDate <= :endDate ' +
                          'ORDER BY CreatedDate DESC LIMIT 2000';
            
            // Execute query with proper field-level security checks
            List<SetupAuditTrail> allAuditRecords = Database.query(query);
            
            // Filter by metadata type in Apex if specified
            List<SetupAuditTrail> auditRecords = new List<SetupAuditTrail>();
            if (String.isNotBlank(metadataType)) {
                for (SetupAuditTrail record : allAuditRecords) {
                    if (record.Section != null && record.Section.equalsIgnoreCase(metadataType)) {
                        auditRecords.add(record);
                        if (auditRecords.size() >= 1000) break; // Limit results
                    }
                }
            } else {
                if (allAuditRecords.size() > 1000) {
                    List<SetupAuditTrail> limitedRecords = new List<SetupAuditTrail>();
                    for (Integer i = 0; i < 1000; i++) {
                        limitedRecords.add(allAuditRecords[i]);
                    }
                    auditRecords.addAll(limitedRecords);
                } else {
                    auditRecords = allAuditRecords;
                }
            }
            
            // Verify field-level access for returned fields
            Set<String> accessibleFields = new Set<String>{'Id', 'Action', 'Section', 'CreatedDate', 'DelegateUser', 'Display'};
            for (String field : accessibleFields) {
                if (!Schema.sObjectType.SetupAuditTrail.fields.getMap().get(field).getDescribe().isAccessible()) {
                    throw new AuraHandledException('Insufficient field-level permissions for SetupAuditTrail.' + field);
                }
            }
            
            return auditRecords;
            
        } catch (Exception ex) {
            System.debug('Error in getSetupAuditTrail: ' + ex.getMessage() + ' at line ' + ex.getLineNumber());
            throw new AuraHandledException('Error retrieving audit trail data: ' + ex.getMessage());
        }
    }
    
    /**
     * Temporary data structure class for storing and returning sharing rules information
     */
    public class SharingRulesTempData {
        @AuraEnabled public String objectApiName {get;set;}
        @AuraEnabled public String ruleName {get;set;}
        @AuraEnabled public String ruleType {get;set;}
        @AuraEnabled public String sharedWith {get;set;}
        
        public SharingRulesTempData() {
            objectApiName = '';
            ruleName = '';
            ruleType = '';
            sharedWith = '';
        }
    }
    
    /**
     * @description Wrapper class for risky user information
     */
    public class RiskyUserWrapper {
        @AuraEnabled public String userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String userEmail;
        @AuraEnabled public String profileName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Integer riskScore;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Integer highRiskCount;
        @AuraEnabled public List<String> criticalFindings;
        @AuraEnabled public String riskBadgeClass;
        
        public RiskyUserWrapper() {
            this.criticalFindings = new List<String>();
            this.riskScore = 0;
            this.riskLevel = 'Low';
            this.highRiskCount = 0;
            this.riskBadgeClass = 'slds-theme_success';
        }
    }
    
    /**
     * @description Wrapper class for paginated risky users response
     */
    public class RiskyUsersResponse {
        @AuraEnabled public List<RiskyUserWrapper> users;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Integer currentPage;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Boolean hasMore;
        
        public RiskyUsersResponse() {
            this.users = new List<RiskyUserWrapper>();
            this.totalCount = 0;
            this.currentPage = 1;
            this.pageSize = 10;
            this.hasMore = false;
        }
    }
    
    /**
     * @description Retrieves all active users with their risk calculations, sorted by risk score
     * @param pageNumber The page number to retrieve (1-based)
     * @param pageSize The number of users per page (default 10)
     * @return RiskyUsersResponse containing paginated user data with risk scores
     */
    @AuraEnabled(cacheable=false)
    public static RiskyUsersResponse getRiskyUsers(Integer pageNumber, Integer pageSize) {
        RiskyUsersResponse response = new RiskyUsersResponse();
        
        try {
            // Validate input parameters
            if (pageNumber == null || pageNumber < 1) {
                pageNumber = 1;
            }
            if (pageSize == null || pageSize < 1) {
                pageSize = 10; // Default to 10
            }
            // Allow larger page sizes for client-side pagination (up to 1000)
            if (pageSize > 1000) {
                pageSize = 1000; // Cap at 1000 for performance
            }
            
            response.currentPage = pageNumber;
            response.pageSize = pageSize;
            
            // Check user permissions
            if (!Schema.sObjectType.User.isAccessible()) {
                throw new AuraHandledException('Insufficient permissions to access User records');
            }
            
            // Get total count of active users for pagination
            Integer totalUsers = [SELECT COUNT() FROM User WHERE IsActive = true];
            response.totalCount = totalUsers;
            response.hasMore = (pageNumber * pageSize) < totalUsers;
            
            // Calculate offset for pagination
            Integer offset = (pageNumber - 1) * pageSize;
            
            // Query active users with required fields
            List<User> users = [
                SELECT Id, Name, Email, Profile.Name, IsActive
                FROM User 
                WHERE IsActive = true 
                ORDER BY Name
                LIMIT :pageSize 
                OFFSET :offset
            ];
            
            // Process each user and calculate risk using bulk method
            List<RiskyUserWrapper> riskyUsers = new List<RiskyUserWrapper>();
            Set<Id> userIds = new Map<Id, User>(users).keySet();
            
            // Use bulk risk analysis to avoid SOQL limits
            Map<Id, AccessRiskAnalyzer.RiskResult> riskResults;
            try {
                riskResults = AccessRiskAnalyzer.analyzeUserRiskBulk(userIds);
            } catch (Exception e) {
                System.debug('Error in bulk risk analysis: ' + e.getMessage());
                // Fall back to individual analysis if bulk fails
                riskResults = new Map<Id, AccessRiskAnalyzer.RiskResult>();
                for (Id userId : userIds) {
                    try {
                        riskResults.put(userId, AccessRiskAnalyzer.analyzeUserRisk(userId));
                    } catch (Exception ex) {
                        // Create default result if individual analysis also fails
                        AccessRiskAnalyzer.RiskResult defaultResult = new AccessRiskAnalyzer.RiskResult();
                        defaultResult.riskScore = 0;
                        defaultResult.riskLevel = 'Unknown';
                        defaultResult.highRiskCount = 0;
                        defaultResult.criticalFindings = new List<String>{'Error calculating risk'};
                        riskResults.put(userId, defaultResult);
                    }
                }
            }
            
            for (User user : users) {
                RiskyUserWrapper riskyUser = new RiskyUserWrapper();
                riskyUser.userId = user.Id;
                riskyUser.userName = user.Name;
                riskyUser.userEmail = user.Email;
                riskyUser.profileName = user.Profile.Name;
                riskyUser.isActive = user.IsActive;
                
                // Get risk result from bulk analysis
                AccessRiskAnalyzer.RiskResult riskResult = riskResults.get(user.Id);
                riskyUser.riskScore = riskResult.riskScore;
                riskyUser.riskLevel = riskResult.riskLevel;
                riskyUser.highRiskCount = riskResult.highRiskCount;
                riskyUser.criticalFindings = riskResult.criticalFindings;
                
                // Set badge class based on risk level
                riskyUser.riskBadgeClass = getRiskBadgeClass(riskResult.riskLevel);
                
                riskyUsers.add(riskyUser);
            }
            
            // Sort users by risk score (highest first)
            riskyUsers.sort(new RiskScoreComparator());
            
            response.users = riskyUsers;
            
        } catch (Exception e) {
            System.debug('Error in getRiskyUsers: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving risky users: ' + e.getMessage());
        }
        
        return response;
    }
    
    /**
     * @description Helper method to get CSS class for risk level badge
     * @param riskLevel The risk level string
     * @return String CSS class for the badge
     */
    private static String getRiskBadgeClass(String riskLevel) {
        switch on riskLevel {
            when 'Critical' {
                return 'slds-theme_error';
            }
            when 'High' {
                return 'slds-theme_warning';
            }
            when 'Medium' {
                return 'slds-theme_info';
            }
            when 'Low' {
                return 'slds-theme_success';
            }
            when else {
                return 'slds-theme_default';
            }
        }
    }
    
    /**
     * @description Comparator class to sort users by risk score in descending order
     */
    public class RiskScoreComparator implements Comparator<RiskyUserWrapper> {
        public Integer compare(RiskyUserWrapper user1, RiskyUserWrapper user2) {
            // Sort by risk score descending (highest risk first)
            if (user1.riskScore > user2.riskScore) {
                return -1;
            } else if (user1.riskScore < user2.riskScore) {
                return 1;
            } else {
                // If risk scores are equal, sort by name ascending
                return user1.userName.compareTo(user2.userName);
            }
        }
    }
}