public with sharing class UserCloneController {
    /**
     * Clones permissions from one user to another with selective options
     * @param sourceUserId - ID of the user to copy permissions from
     * @param targetUserId - ID of the user to apply permissions to
     * @param cloneOptions - Map of options indicating which elements to clone
     * @return CloneResult - Contains information about the cloned permissions
     */
    /**
     * Clones permissions with license override option
     * @param sourceUserId - ID of the user to copy permissions from
     * @param targetUserId - ID of the user to apply permissions to
     * @param cloneOptions - Map of options indicating which elements to clone
     * @param overrideLicenseCompatibility - Whether to skip profile cloning due to license incompatibility
     * @return CloneResult - Contains information about the cloned permissions
     */
    @AuraEnabled
    public static CloneResult clonePermissionsWithOverride(String sourceUserId, String targetUserId, Map<String, Boolean> cloneOptions, Boolean overrideLicenseCompatibility) {
        try {
            CloneResult result = new CloneResult();
            
            // Set default values if cloneOptions is null
            if (cloneOptions == null) {
                cloneOptions = new Map<String, Boolean>{
                    'userPermissions' => true,
                    'userRole' => true,
                    'profile' => true,
                    'permissionSets' => true,
                    'permissionSetGroups' => true
                };
            }
            
            // If overriding license compatibility, skip profile cloning
            if (overrideLicenseCompatibility == true) {
                cloneOptions.put('profile', false);
            }
            
            // Get all User Permission fields dynamically
            List<String> userPermissionFields = getUserPermissionFields();
            
            // Build dynamic query for cloning
            String cloneQuery = buildCloneUserQuery(userPermissionFields);
            
            // Query source user with all necessary fields including user settings
            List<User> sourceUsers = Database.query(cloneQuery + ' WHERE Id = :sourceUserId');
            if (sourceUsers.isEmpty()) {
                throw new AuraHandledException('Source user not found with Id: ' + sourceUserId);
            }
            
            User sourceUser = sourceUsers[0];
            
            // Get target user info
            User targetUserWithProfile = [SELECT Profile.Name, UserRole.Name, ProfileId, UserRoleId 
                                    FROM User 
                                    WHERE Id = :targetUserId];
            result.profileName = targetUserWithProfile.Profile.Name;
            result.userRole = targetUserWithProfile.UserRole.Name;
            
            // Clone user permissions if selected
            if (cloneOptions.get('userPermissions') == true) {
                // Dynamically copy all UserPermissions fields and get count
                Integer permissionsCount = copyUserPermissions(sourceUser, targetUserId, userPermissionFields);
                result.userPermissionsCloned = permissionsCount;
            }
            
            // Clone profile if selected
            if (cloneOptions.get('profile') == true) {
                try {
                    User userToUpdate = new User(Id = targetUserId, ProfileId = sourceUser.ProfileId);
                    checkUpdateAccess(userToUpdate);
                    update userToUpdate;
                    
                    // Update the result with new profile name
                    User updatedUser = [SELECT Profile.Name FROM User WHERE Id = :targetUserId];
                    result.profileName = updatedUser.Profile.Name;
                } catch (DmlException e) {
                    if (e.getMessage().contains('FIELD_INTEGRITY_EXCEPTION')) {
                        // Handle license compatibility issue
                        if (e.getMessage().contains('compatible with the user\'s license')) {
                            result.licenseCompatibilityError = true;
                            result.errorMessage = 'Profile is not compatible with the target user\'s license. Would you like to proceed without changing the profile?';
                        }
                        // Handle user type change restrictions (e.g., Guest to System Administrator)
                        else if (e.getMessage().contains('Changing User Type') || e.getMessage().contains('not allowed')) {
                            result.licenseCompatibilityError = true;
                            result.errorMessage = 'Cannot change user type with this profile assignment. Profile cloning will be skipped to continue with other permissions.';
                        }
                        // Handle other field integrity exceptions
                        else {
                            result.licenseCompatibilityError = true;
                            result.errorMessage = 'Profile assignment failed due to system restrictions. Profile cloning will be skipped to continue with other permissions.';
                        }
                        
                        result.sourceProfileId = sourceUser.ProfileId;
                        result.targetUserId = targetUserId;
                        
                        // Get profile names for better user experience
                        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Id IN (:sourceUser.ProfileId, :targetUserWithProfile.ProfileId)];
                        for (Profile p : profiles) {
                            if (p.Id == sourceUser.ProfileId) {
                                result.sourceProfileName = p.Name;
                            } else if (p.Id == targetUserWithProfile.ProfileId) {
                                result.targetProfileName = p.Name;
                            }
                        }
                        
                        // Continue with other cloning operations instead of stopping
                        System.debug(LoggingLevel.WARN, 'Profile cloning skipped due to compatibility issue: ' + e.getMessage());
                        return continuePermissionCloning(sourceUser, targetUserId, cloneOptions, result);
                    } else {
                        throw e; // Re-throw if it's a different error
                    }
                }
            }
            
            // Continue with the rest of the cloning process...
            return continuePermissionCloning(sourceUser, targetUserId, cloneOptions, result);
            
        } catch(Exception e) {
            throw new AuraHandledException(getFormattedError(e));
        }
    }
    
    @AuraEnabled
    public static CloneResult clonePermissions(String sourceUserId, String targetUserId, Map<String, Boolean> cloneOptions) {
        return clonePermissionsWithOverride(sourceUserId, targetUserId, cloneOptions, false);
    }
    
    /**
     * Continues the permission cloning process after profile handling
     */
    private static CloneResult continuePermissionCloning(User sourceUser, String targetUserId, Map<String, Boolean> cloneOptions, CloneResult result) {
        try {
            // Get target user info for profile name updates
            User targetUserWithProfile = [SELECT Profile.Name, UserRole.Name, ProfileId, UserRoleId 
                                    FROM User 
                                    WHERE Id = :targetUserId];
            
            // Clone user role if selected
            if (cloneOptions.get('userRole') == true && sourceUser.UserRoleId != null) {
                try {
                    User userToUpdate = new User(Id = targetUserId, UserRoleId = sourceUser.UserRoleId);
                    checkUpdateAccess(userToUpdate);
                    update userToUpdate;
                    
                    // Update the result with new role name
                    User updatedUser = [SELECT UserRole.Name FROM User WHERE Id = :targetUserId];
                    result.userRole = updatedUser.UserRole.Name;
                } catch (DmlException e) {
                    // Handle all DML exceptions with user-friendly messages
                    result.hasError = true;
                    result.errorMessage = getFormattedError(e);
                    
                    // Set specific error type for known issues
                    if (e.getMessage().contains('FIELD_INTEGRITY_EXCEPTION')) {
                        if (e.getMessage().contains('Digital Experiences')) {
                            result.errorType = 'EXTERNAL_PROFILE_RESTRICTION';
                        } else if (e.getMessage().contains('changing user type from partner to system administrator')) {
                            result.errorType = 'PARTNER_PROFILE_RESTRICTION';
                        } else {
                            result.errorType = 'PROFILE_RESTRICTION';
                        }
                    } else {
                        result.errorType = 'ROLE_UPDATE_ERROR';
                    }
                    
                    System.debug(LoggingLevel.ERROR, 'Role update error: ' + e.getMessage());
                    
                    // Continue with other cloning operations but skip role update
                    result.userRole = 'Role update skipped due to restrictions';
                } catch (Exception e) {
                    // Handle any other unexpected exceptions
                    result.hasError = true;
                    result.errorMessage = getFormattedError(e);
                    result.errorType = 'UNEXPECTED_ERROR';
                    
                    System.debug(LoggingLevel.ERROR, 'Unexpected error during role update: ' + e.getMessage());
                    result.userRole = 'Role update failed';
                }
            }
            
            // Clone permission sets if selected
            if (cloneOptions.get('permissionSets') == true) {
                List<PermissionSetAssignment> sourcePermSets = [
                    SELECT PermissionSetId, PermissionSet.Name, PermissionSet.Type 
                    FROM PermissionSetAssignment 
                    WHERE AssigneeId = :sourceUser.Id
                    AND PermissionSet.IsOwnedByProfile = false
                    AND PermissionSet.Type != 'Group'
                ];
                
                Set<Id> existingPermSetIds = new Set<Id>();
                
                // Remove existing permission set assignments from target user only if allowRemovals is true
                if (cloneOptions.get('allowRemovals') != false) {
                    List<PermissionSetAssignment> existingPermSets = [
                        SELECT Id 
                        FROM PermissionSetAssignment 
                        WHERE AssigneeId = :targetUserId
                        AND PermissionSet.IsOwnedByProfile = false
                        AND PermissionSet.Type != 'Group'
                    ];
                    
                    if(!existingPermSets.isEmpty()) {
                        delete existingPermSets;
                    }
                } else {
                    // If not removing existing assignments, get existing permission set IDs to avoid duplicates
                    List<PermissionSetAssignment> existingPermSets = [
                        SELECT PermissionSetId 
                        FROM PermissionSetAssignment 
                        WHERE AssigneeId = :targetUserId
                        AND PermissionSet.IsOwnedByProfile = false
                        AND PermissionSet.Type != 'Group'
                    ];
                    
                    for(PermissionSetAssignment psa : existingPermSets) {
                        existingPermSetIds.add(psa.PermissionSetId);
                    }
                }
                
                List<PermissionSetAssignment> newPermSets = new List<PermissionSetAssignment>();
                for(PermissionSetAssignment psa : sourcePermSets) {
                    // Only add if it doesn't already exist on target user
                    if (!existingPermSetIds.contains(psa.PermissionSetId)) {
                        newPermSets.add(new PermissionSetAssignment(
                            AssigneeId = targetUserId,
                            PermissionSetId = psa.PermissionSetId
                        ));
                    }
                }
                
                if(!newPermSets.isEmpty()) {
                    // Check FLS before insert
                    checkCreateAccessForList(newPermSets);
                    
                    // Check field-level security for PermissionSetAssignment fields
                    Schema.DescribeSObjectResult psaDescribe = PermissionSetAssignment.SObjectType.getDescribe();
                    Map<String, Schema.SObjectField> psaFieldMap = psaDescribe.fields.getMap();
                    
                    if (!psaFieldMap.get('AssigneeId').getDescribe().isCreateable() ||
                        !psaFieldMap.get('PermissionSetId').getDescribe().isCreateable()) {
                            throw new FLSException('Insufficient permissions to create PermissionSetAssignment records with all required fields.');
                        }
                    
                    try {
                        insert newPermSets;
                        result.permissionSetsCloned = newPermSets.size();
                    } catch (DmlException e) {
                        // Handle specific DML exceptions for permission sets
                        if (e.getMessage().contains('LICENSE_LIMIT_EXCEEDED')) {
                            result.hasError = true;
                            result.errorMessage = 'License Limit Exceeded: ' + e.getMessage() + 
                                '. Some permission sets could not be assigned due to license limitations. Please contact your Salesforce administrator to increase license limits or deactivate unused users.';
                            result.errorType = 'LICENSE_LIMIT_ERROR';
                            System.debug(LoggingLevel.ERROR, 'Permission set assignment failed due to license limits: ' + e.getMessage());
                            // Continue with other operations but mark as having errors
                        } else {
                            // Re-throw other DML exceptions
                            throw e;
                        }
                    }
                }
            }
            
            // Clone permission set groups if selected
            if (cloneOptions.get('permissionSetGroups') == true) {
                List<PermissionSetAssignment> sourcePermSetGroups = [
                    SELECT PermissionSetId, PermissionSet.Name 
                    FROM PermissionSetAssignment 
                    WHERE AssigneeId = :sourceUser.Id
                    AND PermissionSet.IsOwnedByProfile = false
                    AND PermissionSet.Type = 'Group'
                ];
                
                Set<Id> existingPermSetGroupIds = new Set<Id>();
                
                // Remove existing permission set group assignments from target user only if allowRemovals is true
                if (cloneOptions.get('allowRemovals') != false) {
                    List<PermissionSetAssignment> existingPermSetGroups = [
                        SELECT Id 
                        FROM PermissionSetAssignment 
                        WHERE AssigneeId = :targetUserId
                        AND PermissionSet.IsOwnedByProfile = false
                        AND PermissionSet.Type = 'Group'
                    ];
                    
                    if(!existingPermSetGroups.isEmpty()) {
                        delete existingPermSetGroups;
                    }
                } else {
                    // If not removing existing assignments, get existing permission set group IDs to avoid duplicates
                    List<PermissionSetAssignment> existingPermSetGroups = [
                        SELECT PermissionSetId 
                        FROM PermissionSetAssignment 
                        WHERE AssigneeId = :targetUserId
                        AND PermissionSet.IsOwnedByProfile = false
                        AND PermissionSet.Type = 'Group'
                    ];
                    
                    for(PermissionSetAssignment psa : existingPermSetGroups) {
                        existingPermSetGroupIds.add(psa.PermissionSetId);
                    }
                }
                
                List<PermissionSetAssignment> newPermSetGroups = new List<PermissionSetAssignment>();
                for(PermissionSetAssignment psa : sourcePermSetGroups) {
                    // Only add if it doesn't already exist on target user
                    if (!existingPermSetGroupIds.contains(psa.PermissionSetId)) {
                        newPermSetGroups.add(new PermissionSetAssignment(
                            AssigneeId = targetUserId,
                            PermissionSetId = psa.PermissionSetId
                        ));
                    }
                }
                
                if(!newPermSetGroups.isEmpty()) {
                    // Check FLS before insert
                    checkCreateAccessForList(newPermSetGroups);
                    
                    // Check field-level security for PermissionSetAssignment fields
                    Schema.DescribeSObjectResult psaDescribe = PermissionSetAssignment.SObjectType.getDescribe();
                    Map<String, Schema.SObjectField> psaFieldMap = psaDescribe.fields.getMap();
                    
                    if (!psaFieldMap.get('AssigneeId').getDescribe().isCreateable() ||
                        !psaFieldMap.get('PermissionSetId').getDescribe().isCreateable()) {
                            throw new FLSException('Insufficient permissions to create PermissionSetAssignment records with all required fields.');
                        }
                    
                    try {
                        insert newPermSetGroups;
                        result.permissionSetGroupsCloned = newPermSetGroups.size();
                    } catch (DmlException e) {
                        // Handle specific DML exceptions for permission set groups
                        if (e.getMessage().contains('LICENSE_LIMIT_EXCEEDED')) {
                            result.hasError = true;
                            result.errorMessage = 'License Limit Exceeded: ' + e.getMessage() + 
                                '. Some permission set groups could not be assigned due to license limitations. Please contact your Salesforce administrator to increase license limits or deactivate unused users.';
                            result.errorType = 'LICENSE_LIMIT_ERROR';
                            System.debug(LoggingLevel.ERROR, 'Permission set group assignment failed due to license limits: ' + e.getMessage());
                            // Continue with other operations but mark as having errors
                        } else {
                            // Re-throw other DML exceptions
                            throw e;
                        }
                    }
                }
            }
            
            // Clone group memberships (public groups and queues)
            // Check if we should clone public groups and/or queues
            Boolean clonePublicGroups = cloneOptions.get('publicGroups') != false;
            Boolean cloneQueues = cloneOptions.get('queueMembership') != false;
            
            if (clonePublicGroups || cloneQueues) {
                // Build list of group types to include
                List<String> groupTypesToClone = new List<String>();
                if (clonePublicGroups) groupTypesToClone.add('Regular');
                if (cloneQueues) groupTypesToClone.add('Queue');
                
                List<GroupMember> sourceGroups = [SELECT GroupId, Group.Type
                                                  FROM GroupMember 
                                                  WHERE UserOrGroupId = :sourceUser.Id
                                                  AND Group.Type IN :groupTypesToClone];
                
                Set<Id> existingGroupIds = new Set<Id>();
                
                // Remove existing group memberships from target user only if allowRemovals is true
                if (cloneOptions.get('allowRemovals') != false) {
                    List<GroupMember> existingGroups = [
                        SELECT Id 
                        FROM GroupMember 
                        WHERE UserOrGroupId = :targetUserId
                        AND Group.Type IN :groupTypesToClone
                    ];
                    
                    if(!existingGroups.isEmpty()) {
                        delete existingGroups;
                    }
                } else {
                    // If not removing existing memberships, get existing group IDs to avoid duplicates
                    List<GroupMember> existingGroups = [
                        SELECT GroupId 
                        FROM GroupMember 
                        WHERE UserOrGroupId = :targetUserId
                        AND Group.Type IN :groupTypesToClone
                    ];
                    
                    for(GroupMember gm : existingGroups) {
                        existingGroupIds.add(gm.GroupId);
                    }
                }
                
                List<GroupMember> newGroups = new List<GroupMember>();
                for(GroupMember gm : sourceGroups) {
                    // Only add if the user is not already a member of this group
                    if (!existingGroupIds.contains(gm.GroupId)) {
                        newGroups.add(new GroupMember(
                            GroupId = gm.GroupId,
                            UserOrGroupId = targetUserId
                        ));
                    }
                }
                
                if(!newGroups.isEmpty()) {
                    // Check FLS before insert
                    checkCreateAccessForList(newGroups);
                    
                    // Check field-level security for GroupMember fields
                    Schema.DescribeSObjectResult gmDescribe = GroupMember.SObjectType.getDescribe();
                    Map<String, Schema.SObjectField> gmFieldMap = gmDescribe.fields.getMap();
                    
                    if (!gmFieldMap.get('GroupId').getDescribe().isCreateable() ||
                        !gmFieldMap.get('UserOrGroupId').getDescribe().isCreateable()) {
                            throw new FLSException('Insufficient permissions to create GroupMember records with all required fields.');
                        }
                    insert newGroups;
                    result.groupsCloned = newGroups.size();
                }
            }
            
            // Save clone history to SA_Audit__UserClonerDetails__c
            try {
                saveUserCloneHistory(sourceUser.Id, targetUserId);
            } catch(Exception historyEx) {
                System.debug('Warning: Failed to save clone history: ' + historyEx.getMessage());
                // Don't fail the main operation if history saving fails
            }
            
            system.debug('Permissions cloned successfully: ' + result);
            return result;
        } catch(Exception e) {
            throw new AuraHandledException(getFormattedError(e));
        }
    }
    // Add FLS check methods at the top of the class
    private static void checkCreateAccess(SObject record) {
        if (record == null) return;
        
        String objectType = String.valueOf(record.getSObjectType());
        if (!Schema.getGlobalDescribe().get(objectType).getDescribe().isCreateable()) {
            throw new FLSException('Insufficient permissions to create ' + objectType + ' records.');
        }
    }
    
    private static void checkCreateAccessForList(List<SObject> records) {
        if (records == null || records.isEmpty()) return;
        
        String objectType = String.valueOf(records[0].getSObjectType());
        if (!Schema.getGlobalDescribe().get(objectType).getDescribe().isCreateable()) {
            throw new FLSException('Insufficient permissions to create ' + objectType + ' records.');
        }
    }
    
    private static void checkUpdateAccess(SObject record) {
        if (record == null) return;
        
        String objectType = String.valueOf(record.getSObjectType());
        if (!Schema.getGlobalDescribe().get(objectType).getDescribe().isUpdateable()) {
            throw new FLSException('Insufficient permissions to update ' + objectType + ' records.');
        }
    }
    
    public class FLSException extends Exception {}
    
    @AuraEnabled(cacheable=true)
    public static List<UserWrapper> getAllUsers() {
        List<UserWrapper> userList = new List<UserWrapper>();
        for(User usr : [SELECT Id, Name, Email, Username FROM User WHERE IsActive = true AND Profile.UserLicense.Name = 'Salesforce' ORDER BY Name limit 200]) {
            userList.add(new UserWrapper(usr.Id, usr.Name, usr.Email, usr.Username));
        }
        return userList;
    }
    
    /**
     * Search users with pagination support for large datasets
     * @param searchTerm - Search term to filter users by name, email, or username
     * @param pageSize - Number of records per page (max 50 for performance)
     * @param offset - Number of records to skip for pagination
     * @return UserSearchResult - Contains users list and total count
     */
    @AuraEnabled(cacheable=true)
    public static UserSearchResult searchUsers(String searchTerm, Integer pageSize, Integer offset) {
        try {
            // Validate and sanitize inputs
            if (pageSize == null || pageSize <= 0 || pageSize > 50) {
                pageSize = 20; // Default page size
            }
            if (offset == null || offset < 0) {
                offset = 0;
            }
            
            String sanitizedSearchTerm = '';
            if (String.isNotBlank(searchTerm)) {
                // Sanitize search term to prevent SOQL injection
                sanitizedSearchTerm = String.escapeSingleQuotes(searchTerm.trim());
            }
            
            List<UserWrapper> userList = new List<UserWrapper>();
            Integer totalCount = 0;
            
            // Build dynamic SOQL query - include multiple user license types, exclude community licenses
            String whereClause = 'WHERE IsActive = true'  
                + ' AND Profile.UserLicense.Name != \'Customer Community Login\''
                + ' AND Profile.UserLicense.Name != \'Partner Community User\''
                + ' AND Profile.UserLicense.Name != \'Company Communities\'';
            
            if (String.isNotBlank(sanitizedSearchTerm)) {
                whereClause += ' AND (Name LIKE \'%' + sanitizedSearchTerm + '%\' OR Email LIKE \'%' + sanitizedSearchTerm + '%\' OR Username LIKE \'%' + sanitizedSearchTerm + '%\')';
            }
            
            // Get total count for pagination
            String countQuery = 'SELECT COUNT() FROM User ' + whereClause;
            totalCount = Database.countQuery(countQuery);
            
            // Get paginated results
            String dataQuery = 'SELECT Id, Name, Email, Username FROM User ' + whereClause + ' ORDER BY Name LIMIT ' + pageSize + ' OFFSET ' + offset;
            List<User> users = Database.query(dataQuery);
            
            for(User usr : users) {
                userList.add(new UserWrapper(usr.Id, usr.Name, usr.Email, usr.Username));
            }
            
            return new UserSearchResult(userList, totalCount, pageSize, offset);
            
        } catch (Exception e) {
            System.debug('Error in searchUsers: ' + e.getMessage());
            throw new AuraHandledException('Error searching users: ' + e.getMessage());
        }
    }
    
    /**
     * Get initial users for dropdown (first 20 active users)
     * @return List<UserWrapper> - Initial list of users
     */
    @AuraEnabled(cacheable=true)
    public static List<UserWrapper> getInitialUsers() {
        List<UserWrapper> userList = new List<UserWrapper>();
        try {
            // Use same filtering logic as searchUsers to include more license types
            for(User usr : [SELECT Id, Name, Email, Username 
                           FROM User 
                           WHERE IsActive = true
                           AND Profile.UserLicense.Name != 'Customer Community Login'
                           AND Profile.UserLicense.Name != 'Partner Community User'
                           AND Profile.UserLicense.Name != 'Company Communities'
                           ORDER BY Name 
                           LIMIT 500]) {
                userList.add(new UserWrapper(usr.Id, usr.Name, usr.Email, usr.Username));
            }
        } catch (Exception e) {
            System.debug('Error in getInitialUsers: ' + e.getMessage());
        }
        return userList;
    }
    
    /**
     * Wrapper class for user search results with pagination
     */
    public class UserSearchResult {
        @AuraEnabled public List<UserWrapper> users;
        @AuraEnabled public Integer totalCount;
        @AuraEnabled public Integer pageSize;
        @AuraEnabled public Integer offset;
        @AuraEnabled public Boolean hasMore;
        @AuraEnabled public Integer currentPage;
        @AuraEnabled public Integer totalPages;
        
        public UserSearchResult(List<UserWrapper> users, Integer totalCount, Integer pageSize, Integer offset) {
            this.users = users;
            this.totalCount = totalCount;
            this.pageSize = pageSize;
            this.offset = offset;
            this.currentPage = (offset / pageSize) + 1;
            this.totalPages = (Integer) Math.ceil((Decimal) totalCount / pageSize);
            this.hasMore = (offset + pageSize) < totalCount;
        }
    }
    
    public class UserWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String username;
        
        public UserWrapper(String id, String name, String email, String username) {
            this.id = id;
            this.name = name;
            this.email = email;
            this.username = username;
        }
    }
    // Enhanced error formatting method to preserve detailed Salesforce error messages
    private static String getFormattedError(Exception e) {
        String originalMessage = e.getMessage();
        String errorMessage = originalMessage.toLowerCase();
        
        // For FIELD_INTEGRITY_EXCEPTION and other detailed errors, preserve the original message
        // as it contains specific actionable information from Salesforce
        if(errorMessage.contains('field_integrity_exception') || 
           errorMessage.contains('digital experiences') ||
           errorMessage.contains('profile id:') ||
           errorMessage.contains('setup >')) {
            // Return the original detailed message as it's more specific and actionable
            return originalMessage;
        }
        
        // Handle duplicate username errors with enhanced context
        if(errorMessage.contains('duplicate username')) {
            return 'Duplicate Username Error: ' + originalMessage + 
                '. Please use a different email address for the new user.';
        }
        
        // Handle permission assignment errors with enhanced context
        if(errorMessage.contains('invalid cross reference')) {
            return 'Permission Assignment Error: ' + originalMessage + 
                '. This might be due to licensing restrictions or profile limitations.';
        }
        
        // Handle access permission errors with enhanced context
        if(errorMessage.contains('insufficient access')) {
            return 'Access Permission Error: ' + originalMessage + 
                '. Please contact your Salesforce administrator.';
        }
        
        // Handle license limit errors with enhanced context
        if(errorMessage.contains('license limit') || errorMessage.contains('license_limit_exceeded')) {
            return 'License Limit Error: ' + originalMessage + 
                '. Please contact your Salesforce administrator to increase license limits or deactivate unused users.';
        }
        
        // For other errors, return the original message with minimal enhancement
        return originalMessage;
    }
    @AuraEnabled
    public static UserCloneDetailsWrapper getSourceUserDetails(String userId) {
        UserCloneDetailsWrapper wrapper = new UserCloneDetailsWrapper();
        
        // Dynamically build query with all UserPermissions fields
        List<String> userPermissionFields = getUserPermissionFields();
        String dynamicQuery = buildUserQuery(userPermissionFields);
        
        // Execute dynamic query
        List<User> users = Database.query(dynamicQuery + ' WHERE Id = :userId');
        if (users.isEmpty()) {
            throw new AuraHandledException('User not found with Id: ' + userId);
        }
        
        User sourceUser = users[0];
        
        // Populate basic user information
        wrapper.basicInfo = new BasicUserInfo();
        wrapper.basicInfo.name = sourceUser.Name;
        wrapper.basicInfo.email = sourceUser.Email;
        wrapper.basicInfo.username = sourceUser.Username;
        wrapper.basicInfo.alias = sourceUser.Alias;
        wrapper.basicInfo.isActive = sourceUser.IsActive;
        wrapper.basicInfo.title = sourceUser.Title;
        wrapper.basicInfo.department = sourceUser.Department;
        wrapper.basicInfo.division = sourceUser.Division;
        wrapper.basicInfo.companyName = sourceUser.CompanyName;
        wrapper.basicInfo.phone = sourceUser.Phone;
        wrapper.basicInfo.mobilePhone = sourceUser.MobilePhone;
        wrapper.basicInfo.lastLoginDate = sourceUser.LastLoginDate;
        
        // Populate security and access information with dynamic permissions
        wrapper.securityInfo = new SecurityInfo();
        wrapper.securityInfo.profileId = sourceUser.ProfileId;
        wrapper.securityInfo.profileName = sourceUser.Profile.Name;
        wrapper.securityInfo.userRole = sourceUser.UserRole?.Name;
        wrapper.securityInfo.managerName = sourceUser.Manager?.Name;
        
        // Dynamically populate all user permissions
        wrapper.securityInfo.allUserPermissions = new Map<String, Boolean>();
        for (String permissionField : userPermissionFields) {
            Boolean permissionValue = (Boolean) sourceUser.get(permissionField);
            wrapper.securityInfo.allUserPermissions.put(permissionField, permissionValue != null ? permissionValue : false);
        }
        
        // Maintain backward compatibility for key permission flags if they exist in the current org
        wrapper.securityInfo.isMarketingUser     = userPermissionFields.contains('UserPermissionsMarketingUser')          ? (Boolean) sourceUser.get('UserPermissionsMarketingUser')          : false;
        wrapper.securityInfo.isOfflineUser       = userPermissionFields.contains('UserPermissionsOfflineUser')            ? (Boolean) sourceUser.get('UserPermissionsOfflineUser')            : false;
        wrapper.securityInfo.isCallCenterUser    = userPermissionFields.contains('UserPermissionsCallCenterAutoLogin')    ? (Boolean) sourceUser.get('UserPermissionsCallCenterAutoLogin')    : false;
        wrapper.securityInfo.isSFContentUser     = userPermissionFields.contains('UserPermissionsSFContentUser')          ? (Boolean) sourceUser.get('UserPermissionsSFContentUser')          : false;
        wrapper.securityInfo.isInteractionUser   = userPermissionFields.contains('UserPermissionsInteractionUser')        ? (Boolean) sourceUser.get('UserPermissionsInteractionUser')        : false;
        wrapper.securityInfo.isSupportUser       = userPermissionFields.contains('UserPermissionsSupportUser')            ? (Boolean) sourceUser.get('UserPermissionsSupportUser')            : false;
        wrapper.securityInfo.isKnowledgeUser     = userPermissionFields.contains('UserPermissionsKnowledgeUser')          ? (Boolean) sourceUser.get('UserPermissionsKnowledgeUser')          : false;
        
        // Populate locale and preferences
        wrapper.localeInfo = new LocaleInfo();
        wrapper.localeInfo.localeSidKey = sourceUser.LocaleSidKey;
        wrapper.localeInfo.languageLocaleKey = sourceUser.LanguageLocaleKey;
        wrapper.localeInfo.timeZoneSidKey = sourceUser.TimeZoneSidKey;
        wrapper.localeInfo.emailEncodingKey = sourceUser.EmailEncodingKey;
        wrapper.localeInfo.communityNickname = sourceUser.CommunityNickname;
        wrapper.localeInfo.digestFrequency = sourceUser.DigestFrequency;
        wrapper.localeInfo.groupNotificationFrequency = sourceUser.DefaultGroupNotificationFrequency;
        
        // Get Permission Sets with limit optimization
        List<PermissionSetAssignment> permSets = [
            SELECT PermissionSet.Name, PermissionSet.Label, PermissionSet.Type
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId
            AND PermissionSet.IsOwnedByProfile = false
            ORDER BY PermissionSet.Name
            LIMIT 50
        ];
        
        wrapper.permissionSets = new List<PermissionSetInfo>();
        for (PermissionSetAssignment psa : permSets) {
            PermissionSetInfo psInfo = new PermissionSetInfo();
            psInfo.name = psa.PermissionSet.Name;
            psInfo.label = psa.PermissionSet.Label;
            psInfo.type = psa.PermissionSet.Type;
            wrapper.permissionSets.add(psInfo);
        }
        
        // Get Public Groups with limit optimization
        List<GroupMember> groups = [
            SELECT Group.Name, Group.Type, Group.DeveloperName
            FROM GroupMember 
            WHERE UserOrGroupId = :userId
            AND Group.Type IN ('Regular', 'Queue')
            ORDER BY Group.Name
            LIMIT 50
        ];
        
        wrapper.publicGroups = new List<GroupInfo>();
        for (GroupMember gm : groups) {
            GroupInfo groupInfo = new GroupInfo();
            groupInfo.name = gm.Group.Name;
            groupInfo.type = gm.Group.Type;
            groupInfo.developerName = gm.Group.DeveloperName;
            wrapper.publicGroups.add(groupInfo);
        }
        
        // Set summary counts
        wrapper.permissionSetCount = permSets.size();
        wrapper.publicGroupCount = groups.size();
        
        return wrapper;
    }
    
    /**
     * Dynamically retrieves all User Permission fields from User object
     * These are boolean fields that start with 'Permissions' (e.g., PermissionsMarketingUser, PermissionsFlowUser)
     * @return List of User Permission field API names
     */
    public static List<String> getUserPermissionFields() {
        List<String> userPermissionFields = new List<String>();
        
        System.debug('UserCloneController - getUserPermissionFields: Starting method');
        
        // Get User object describe
        Schema.DescribeSObjectResult userDescribe = User.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = userDescribe.fields.getMap();
        System.debug('UserCloneController - getUserPermissionFields: Total User fields: ' + fieldMap.size());
        
        // Filter fields that are User permission fields (can start with 'Permissions' or contain 'permission')
        for (String fieldName : fieldMap.keySet()) {
            String fieldNameLower = fieldName.toLowerCase();
            // Check for fields that start with 'Permissions' or contain 'permission' (case insensitive)
            if (fieldName.startsWith('Permissions') || fieldNameLower.contains('permission')) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                // Include all boolean UserPermissions fields regardless of FLS since cloning runs in system context
                if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {
                    userPermissionFields.add(fieldName);
                    System.debug(LoggingLevel.FINE, 'Discovered User Permission field: ' + fieldName + 
                    ' | Updateable: ' + fieldDescribe.isUpdateable() + 
                    ' | Creatable: ' + fieldDescribe.isCreateable());
                }
            }
        }
        
        System.debug('Found ' + userPermissionFields.size() + ' User Permission fields: ' + userPermissionFields);
        
        return userPermissionFields;
    }
    
    /**
     * Filters the provided field list and returns only those that exist on the User object
     * Relationship fields (those containing a dot) are always retained because they are valid in SOQL
     */
    private static List<String> filterExistingUserFields(List<String> fieldNames) {
        Map<String, Schema.SObjectField> userFieldMap = User.SObjectType.getDescribe().fields.getMap();
        List<String> validFields = new List<String>();
        for (String f : fieldNames) {
            // Keep relationship fields (Profile.Name etc.) or those present in describe map
            if (f.contains('.') || userFieldMap.containsKey(f)) {
                validFields.add(f);
            }
        }
        return validFields;
    }
    
    /**
     * Builds dynamic SOQL query including all necessary User fields
     * @param userPermissionFields List of UserPermissions fields to include
     * @return Complete SOQL query string
     */
    private static String buildUserQuery(List<String> userPermissionFields) {
        // Create a Set to avoid duplicates from the beginning
        Set<String> uniqueFields = new Set<String>{
            'Id', 'Name', 'Email', 'Username', 'Alias',
            'Profile.Name', 'UserRole.Name', 'Manager.Name',
            'LocaleSidKey', 'LanguageLocaleKey', 'TimeZoneSidKey',
            'EmailEncodingKey', 'CommunityNickname', 'DigestFrequency',
            'DefaultGroupNotificationFrequency', 'JigsawImportLimitOverride',
            'LastLoginDate', 'CreatedDate', 'LastModifiedDate',
            'Department', 'Division', 'Title', 'CompanyName', 'Street', 
            'City', 'State', 'PostalCode', 'Country',
            'Phone', 'MobilePhone', 'Fax', 'Extension'
        };
        
        // Add all User Permission fields
        uniqueFields.addAll(userPermissionFields);
        
        // Get all boolean fields from User object (including IsActive)
        Map<String, Schema.SObjectField> fieldMap = User.SObjectType.getDescribe().fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {
                uniqueFields.add(fieldName);
            }
        }
        
        // Filter out any fields that do not exist in target org and maintain uniqueness
        Set<String> validFieldsSet = new Set<String>();
        Map<String, Schema.SObjectField> userFieldMap = User.SObjectType.getDescribe().fields.getMap();
        
        for (String fieldName : uniqueFields) {
            // Keep relationship fields (Profile.Name etc.) or those present in describe map
            if (fieldName.contains('.') || userFieldMap.containsKey(fieldName)) {
                validFieldsSet.add(fieldName);
            }
        }
        
        List<String> validFields = new List<String>(validFieldsSet);
        
        return 'SELECT ' + String.join(validFields, ', ') + ' FROM User';
    }
    
    /**
     * Builds a dynamic SOQL query for cloning User object including all necessary fields
     * @param userPermissionFields - List of User Permission field names
     * @return String - The constructed SOQL query for cloning
     */
    private static String buildCloneUserQuery(List<String> userPermissionFields) {
        // Create a Set to avoid duplicates from the beginning
        Set<String> uniqueFields = new Set<String>{
            'Id', 'Username', 'Alias', 'TimeZoneSidKey', 'LocaleSidKey', 'EmailEncodingKey',
            'LanguageLocaleKey', 'ProfileId', 'UserRoleId', 'Title', 'CompanyName', 'Department',
            'Division', 'Workday_Id__c', 'Street', 'City', 'State', 'PostalCode', 'Country', 'Phone', 'Fax', 'MobilePhone',
            'SenderEmail', 'SenderName', 'Signature', 'StayInTouchSubject', 'StayInTouchSignature', 'StayInTouchNote',
            'ManagerId', 'DelegatedApproverId', 'StartDay', 'EndDay'
        };
        
        // Add all UserPermissions fields
        uniqueFields.addAll(userPermissionFields);
        
        // Get all boolean fields from User object
        Map<String, Schema.SObjectField> fieldMap = User.SObjectType.getDescribe().fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
            if (fieldDescribe.getType() == Schema.DisplayType.BOOLEAN) {
                uniqueFields.add(fieldName);
            }
        }
        
        // Ensure only existing fields are queried
        List<String> validFields = filterExistingUserFields(new List<String>(uniqueFields));
        
        return 'SELECT ' + String.join(validFields, ', ') + ' FROM User';
     }
     
     /**
      * Dynamically copies all UserPermissions fields from source user to new user
      * @param sourceUser - The source user object with UserPermissions data
      * @param newUserId - The ID of the newly created user
      * @param userPermissionFields - List of UserPermissions field names
      * @return Integer - The count of user permissions that were cloned
      */
     /**
      * Copies all User Permission boolean fields from source user to target user
      * @param sourceUser - The source User object with permissions to copy
      * @param newUserId - The ID of the newly created user
      * @param userPermissionFields - List of User Permission field names
      * @return Integer - The count of user permissions that were cloned
      */
     private static Integer copyUserPermissions(User sourceUser, Id newUserId, List<String> userPermissionFields) {
         try {
             // If no user permission fields are available, return 0
             if (userPermissionFields == null || userPermissionFields.isEmpty()) {
                 System.debug(LoggingLevel.INFO, 'No User Permission fields available in this org');
                 return 0;
             }
             
             // Create a User object for update with only UserPermissions fields
             User userToUpdate = new User(Id = newUserId);
             
             // Counter for actual permissions copied
             Integer permissionsCopied = 0;
             
             // Track permissions for detailed logging
             Map<String, Object> permissionValues = new Map<String, Object>();
             
             // Dynamically copy all UserPermissions fields
             for (String fieldName : userPermissionFields) {
                 try {
                     // Always copy the field value, even if null (to ensure false values are copied)
                     Object fieldValue = sourceUser.get(fieldName);
                     userToUpdate.put(fieldName, fieldValue);
                     permissionsCopied++;
                     
                     // Track for logging
                     permissionValues.put(fieldName, fieldValue);
                     
                     System.debug(LoggingLevel.FINE, 'Copying permission field: ' + fieldName + ' with value: ' + fieldValue);
                 } catch (SObjectException soe) {
                     // Handle field-specific errors without failing the entire operation
                     System.debug(LoggingLevel.ERROR, 'Error copying field ' + fieldName + ': ' + soe.getMessage());
                 }
             }
             
             // Only update if there are permissions to copy
             if (permissionsCopied > 0) {
                 // Use Database.update with allOrNone=false to handle partial success
                 Database.SaveResult result = Database.update(userToUpdate, false);
                 
                 if (!result.isSuccess()) {
                     // Log errors but continue processing
                     for (Database.Error err : result.getErrors()) {
                         System.debug(LoggingLevel.ERROR, 'Error updating user permissions: ' + err.getMessage());
                     }
                 }
             }
             
             // Log detailed summary
             System.debug(LoggingLevel.INFO, 'Successfully copied ' + permissionsCopied + ' UserPermissions fields to new user: ' + newUserId);
             System.debug(LoggingLevel.FINE, 'Permission values copied: ' + JSON.serialize(permissionValues));
             
             return permissionsCopied;
             
         } catch (Exception e) {
             System.debug(LoggingLevel.ERROR, 'Error copying UserPermissions: ' + e.getMessage() + '\n' + e.getStackTraceString());
             // Log the error but don't fail the entire cloning process
             return 0; // Return 0 instead of throwing exception to prevent failure
         }
     }
     
     // Enhanced wrapper classes for comprehensive user details
    public class UserCloneDetailsWrapper {
        @AuraEnabled public BasicUserInfo basicInfo;
        @AuraEnabled public SecurityInfo securityInfo;
        @AuraEnabled public LocaleInfo localeInfo;
        @AuraEnabled public List<PermissionSetInfo> permissionSets;
        @AuraEnabled public List<GroupInfo> publicGroups;
        @AuraEnabled public Integer permissionSetCount;
        @AuraEnabled public Integer publicGroupCount;
    }
    
    public class BasicUserInfo {
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        @AuraEnabled public String username;
        @AuraEnabled public String alias;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public String title;
        @AuraEnabled public String department;
        @AuraEnabled public String division;
        @AuraEnabled public String companyName;
        @AuraEnabled public String phone;
        @AuraEnabled public String mobilePhone;
        @AuraEnabled public DateTime lastLoginDate;
    }
    
    public class SecurityInfo {
        @AuraEnabled public String profileId;
        @AuraEnabled public String profileName;
        @AuraEnabled public String userRole;
        @AuraEnabled public String managerName;
        @AuraEnabled public Boolean isMarketingUser;
        @AuraEnabled public Boolean isOfflineUser;
        @AuraEnabled public Boolean isCallCenterUser;
        @AuraEnabled public Boolean isSFContentUser;
        @AuraEnabled public Boolean isInteractionUser;
        @AuraEnabled public Boolean isSupportUser;
        @AuraEnabled public Boolean isKnowledgeUser;
        @AuraEnabled public Map<String, Boolean> allUserPermissions;
    }
    
    public class LocaleInfo {
        @AuraEnabled public String localeSidKey;
        @AuraEnabled public String languageLocaleKey;
        @AuraEnabled public String timeZoneSidKey;
        @AuraEnabled public String emailEncodingKey;
        @AuraEnabled public String communityNickname;
        @AuraEnabled public String digestFrequency;
        @AuraEnabled public String groupNotificationFrequency;
    }
    
    public class PermissionSetInfo {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public String description;
    }
    
    public class GroupInfo {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String type;
        @AuraEnabled public String developerName;
    }
    
    public class UserPermissionChange {
        @AuraEnabled public String fieldName;
        @AuraEnabled public String label;
        @AuraEnabled public String fromValue;
        @AuraEnabled public String toValue;
        @AuraEnabled public String changeType; // 'Added', 'Removed', 'Changed'
    }
    public class CloneResult {
        @AuraEnabled public String newUserId;
        @AuraEnabled public Integer permissionSetsCloned;
        @AuraEnabled public Integer permissionSetGroupsCloned;
        @AuraEnabled public Integer groupsCloned;
        @AuraEnabled public Integer userPermissionsCloned;
        @AuraEnabled public String profileName;
        @AuraEnabled public String userRole;
        
        // License compatibility error handling
        @AuraEnabled public Boolean licenseCompatibilityError;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String sourceProfileId;
        @AuraEnabled public String sourceProfileName;
        @AuraEnabled public String targetProfileName;
        @AuraEnabled public String targetUserId;
        
        // External profile error handling
        @AuraEnabled public Boolean hasError;
        @AuraEnabled public String errorType;
    }
    
    // Phase 1 DTOs for Dry-Run Preview + Diff, License Compatibility Assistant, and Compare View
    public class CloneDiffResult {
        @AuraEnabled public ProfileChange profileChange;
        @AuraEnabled public RoleChange roleChange;
        @AuraEnabled public List<PermissionSetInfo> addedPermissionSets;
        @AuraEnabled public List<PermissionSetInfo> removedPermissionSets;
        @AuraEnabled public List<PermissionSetInfo> addedPermissionSetGroups;
        @AuraEnabled public List<PermissionSetInfo> removedPermissionSetGroups;
        @AuraEnabled public List<GroupInfo> addedGroups;
        @AuraEnabled public List<GroupInfo> removedGroups;
        @AuraEnabled public List<GroupInfo> addedPublicGroups;
        @AuraEnabled public List<GroupInfo> removedPublicGroups;
        @AuraEnabled public List<GroupInfo> addedQueues;
        @AuraEnabled public List<GroupInfo> removedQueues;
        @AuraEnabled public List<UserPermissionChange> userPermissionChanges;
        @AuraEnabled public DiffSummary summary;
        
        public CloneDiffResult() {
            this.addedPermissionSets = new List<PermissionSetInfo>();
            this.removedPermissionSets = new List<PermissionSetInfo>();
            this.addedPermissionSetGroups = new List<PermissionSetInfo>();
            this.removedPermissionSetGroups = new List<PermissionSetInfo>();
            this.addedGroups = new List<GroupInfo>();
            this.removedGroups = new List<GroupInfo>();
            this.addedPublicGroups = new List<GroupInfo>();
            this.removedPublicGroups = new List<GroupInfo>();
            this.addedQueues = new List<GroupInfo>();
            this.removedQueues = new List<GroupInfo>();
            this.userPermissionChanges = new List<UserPermissionChange>();
            this.summary = new DiffSummary();
        }
    }
    
    public class ProfileChange {
        @AuraEnabled public String fromProfileName;
        @AuraEnabled public String toProfileName;
        @AuraEnabled public String fromProfileId;
        @AuraEnabled public String toProfileId;
        @AuraEnabled public Boolean licenseCompatible;
        @AuraEnabled public String userLicenseName;
    }
    
    public class RoleChange {
        @AuraEnabled public String fromRoleName;
        @AuraEnabled public String toRoleName;
        @AuraEnabled public String fromRoleId;
        @AuraEnabled public String toRoleId;
    }
    
    public class DiffSummary {
        @AuraEnabled public Integer permissionSetsAdded;
        @AuraEnabled public Integer permissionSetsRemoved;
        @AuraEnabled public Integer permissionSetGroupsAdded;
        @AuraEnabled public Integer permissionSetGroupsRemoved;
        @AuraEnabled public Integer groupsAdded;
        @AuraEnabled public Integer groupsRemoved;
        @AuraEnabled public Integer publicGroupsAdded;
        @AuraEnabled public Integer publicGroupsRemoved;
        @AuraEnabled public Integer queuesAdded;
        @AuraEnabled public Integer queuesRemoved;
        @AuraEnabled public Integer userPermissionsChanged;
        @AuraEnabled public Boolean hasProfileChange;
        @AuraEnabled public Boolean hasRoleChange;
        @AuraEnabled public Boolean hasUserPermissionChanges;
        
        public DiffSummary() {
            this.permissionSetsAdded = 0;
            this.permissionSetsRemoved = 0;
            this.permissionSetGroupsAdded = 0;
            this.permissionSetGroupsRemoved = 0;
            this.groupsAdded = 0;
            this.groupsRemoved = 0;
            this.publicGroupsAdded = 0;
            this.publicGroupsRemoved = 0;
            this.queuesAdded = 0;
            this.queuesRemoved = 0;
            this.userPermissionsChanged = 0;
            this.hasProfileChange = false;
            this.hasRoleChange = false;
            this.hasUserPermissionChanges = false;
        }
    }
    
    public class CompatibleProfileSuggestion {
        @AuraEnabled public String profileId;
        @AuraEnabled public String profileName;
        @AuraEnabled public String userLicenseName;
        @AuraEnabled public String reason;
        @AuraEnabled public Boolean isRecommended;
    }
    
    // Phase 1 Methods for Dry-Run Preview + Diff, License Compatibility Assistant, and Compare View
    
    /**
     * Clones permissions selectively based on user choices from dry-run preview
     * @param sourceUserId The ID of the source user
     * @param targetUserId The ID of the target user
     * @param selectedPermissions Map containing selected permissions to clone
     * @return CloneResult containing the results of the selective cloning
     */
    @AuraEnabled(cacheable=false)
    public static CloneResult clonePermissionsSelectively(String sourceUserId, String targetUserId, Map<String, Object> selectedPermissions) {
        try {
            CloneResult result = new CloneResult();
            
            // Get source and target user details
            User sourceUser = [SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name FROM User WHERE Id = :sourceUserId LIMIT 1];
            User targetUser = [SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name FROM User WHERE Id = :targetUserId LIMIT 1];
            
            // Handle profile change if selected
            if (selectedPermissions.containsKey('profileChange') && (Boolean)selectedPermissions.get('profileChange')) {
                try {
                    User userToUpdate = new User(Id = targetUserId, ProfileId = sourceUser.ProfileId);
                    checkUpdateAccess(userToUpdate);
                    update userToUpdate;
                    result.profileName = sourceUser.Profile.Name;
                } catch (DmlException e) {
                    result.hasError = true;
                    result.errorMessage = getFormattedError(e);
                    result.errorType = 'PROFILE_UPDATE_ERROR';
                }
            }
            
            // Handle role change if selected
            if (selectedPermissions.containsKey('roleChange') && (Boolean)selectedPermissions.get('roleChange')) {
                try {
                    User userToUpdate = new User(Id = targetUserId, UserRoleId = sourceUser.UserRoleId);
                    checkUpdateAccess(userToUpdate);
                    update userToUpdate;
                    result.userRole = sourceUser.UserRole?.Name;
                } catch (DmlException e) {
                    result.hasError = true;
                    result.errorMessage = getFormattedError(e);
                    result.errorType = 'ROLE_UPDATE_ERROR';
                }
            }
            
            // Handle permission sets
            if (selectedPermissions.containsKey('selectedPermissionSets')) {
                List<String> selectedPermSetIds = convertToStringList(selectedPermissions.get('selectedPermissionSets'));
                if (!selectedPermSetIds.isEmpty()) {
                    List<PermissionSetAssignment> newPermSets = new List<PermissionSetAssignment>();
                    for (String permSetId : selectedPermSetIds) {
                        newPermSets.add(new PermissionSetAssignment(
                            AssigneeId = targetUserId,
                            PermissionSetId = permSetId
                        ));
                    }
                    
                    try {
                        checkCreateAccessForList(newPermSets);
                        insert newPermSets;
                        result.permissionSetsCloned = newPermSets.size();
                    } catch (DmlException e) {
                        if (e.getMessage().contains('LICENSE_LIMIT_EXCEEDED')) {
                            result.hasError = true;
                            result.errorMessage = 'License Limit Exceeded: ' + e.getMessage() + 
                                '. Some permission sets could not be assigned due to license limitations.';
                            result.errorType = 'LICENSE_LIMIT_ERROR';
                        } else {
                            throw e;
                        }
                    }
                }
            }
            
            // Handle permission set groups
            if (selectedPermissions.containsKey('selectedPermissionSetGroups')) {
                List<String> selectedPermSetGroupIds = convertToStringList(selectedPermissions.get('selectedPermissionSetGroups'));
                if (!selectedPermSetGroupIds.isEmpty()) {
                    List<PermissionSetAssignment> newPermSetGroups = new List<PermissionSetAssignment>();
                    for (String permSetGroupId : selectedPermSetGroupIds) {
                        newPermSetGroups.add(new PermissionSetAssignment(
                            AssigneeId = targetUserId,
                            PermissionSetId = permSetGroupId
                        ));
                    }
                    
                    try {
                        checkCreateAccessForList(newPermSetGroups);
                        insert newPermSetGroups;
                        result.permissionSetGroupsCloned = newPermSetGroups.size();
                    } catch (DmlException e) {
                        if (e.getMessage().contains('LICENSE_LIMIT_EXCEEDED')) {
                            result.hasError = true;
                            result.errorMessage = 'License Limit Exceeded: ' + e.getMessage() + 
                                '. Some permission set groups could not be assigned due to license limitations.';
                            result.errorType = 'LICENSE_LIMIT_ERROR';
                        } else {
                            throw e;
                        }
                    }
                }
            }
            
            // Handle public groups
            if (selectedPermissions.containsKey('selectedPublicGroups')) {
                List<String> selectedGroupIds = convertToStringList(selectedPermissions.get('selectedPublicGroups'));
                if (!selectedGroupIds.isEmpty()) {
                    List<GroupMember> newGroupMembers = new List<GroupMember>();
                    for (String groupId : selectedGroupIds) {
                        newGroupMembers.add(new GroupMember(
                            UserOrGroupId = targetUserId,
                            GroupId = groupId
                        ));
                    }
                    
                    try {
                        checkCreateAccessForList(newGroupMembers);
                        insert newGroupMembers;
                        result.groupsCloned = newGroupMembers.size();
                    } catch (DmlException e) {
                        result.hasError = true;
                        result.errorMessage = getFormattedError(e);
                        result.errorType = 'GROUP_ASSIGNMENT_ERROR';
                    }
                }
            }
            
            // Handle user permissions
            if (selectedPermissions.containsKey('selectedUserPermissions')) {
                List<String> selectedUserPermFields = convertToStringList(selectedPermissions.get('selectedUserPermissions'));
                if (!selectedUserPermFields.isEmpty()) {
                    result.userPermissionsCloned = copySelectedUserPermissions(sourceUserId, targetUserId, selectedUserPermFields);
                }
            }
            
            // Handle removals if specified
            if (selectedPermissions.containsKey('removeUnselectedPermissions') && (Boolean)selectedPermissions.get('removeUnselectedPermissions')) {
                handlePermissionRemovals(targetUserId, selectedPermissions);
            }
            
            return result;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error in selective cloning: ' + getFormattedError(e));
        }
    }
    
    /**
     * Copies selected user permissions from source to target user
     * @param sourceUserId The ID of the source user
     * @param targetUserId The ID of the target user
     * @param selectedFields List of selected user permission field names
     * @return Number of permissions copied
     */
    private static Integer copySelectedUserPermissions(String sourceUserId, String targetUserId, List<String> selectedFields) {
        try {
            if (selectedFields.isEmpty()) {
                return 0;
            }
            
            // Build dynamic query for selected fields only
            String query = 'SELECT Id, ' + String.join(selectedFields, ', ') + ' FROM User WHERE Id IN (:sourceUserId, :targetUserId)';
            List<User> users = Database.query(query);
            
            User sourceUser = null;
            User targetUser = null;
            
            for (User user : users) {
                if (user.Id == sourceUserId) {
                    sourceUser = user;
                } else if (user.Id == targetUserId) {
                    targetUser = user;
                }
            }
            
            if (sourceUser == null || targetUser == null) {
                return 0;
            }
            
            // Copy selected permissions
            User userToUpdate = new User(Id = targetUserId);
            Integer permissionsCopied = 0;
            
            for (String fieldName : selectedFields) {
                try {
                    Boolean sourceValue = (Boolean) sourceUser.get(fieldName);
                    userToUpdate.put(fieldName, sourceValue);
                    permissionsCopied++;
                } catch (Exception fieldEx) {
                    System.debug(LoggingLevel.ERROR, 'Error copying field ' + fieldName + ': ' + fieldEx.getMessage());
                }
            }
            
            if (permissionsCopied > 0) {
                checkUpdateAccess(userToUpdate);
                update userToUpdate;
            }
            
            return permissionsCopied;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error copying selected user permissions: ' + e.getMessage());
            return 0;
        }
    }
    
    /**
     * Handles removal of unselected permissions
     * @param targetUserId The ID of the target user
     * @param selectedPermissions Map containing selected permissions
     */
    private static void handlePermissionRemovals(String targetUserId, Map<String, Object> selectedPermissions) {
        try {
            // Remove unselected permission sets
            if (selectedPermissions.containsKey('removedPermissionSets')) {
                List<String> permSetsToRemove = convertToStringList(selectedPermissions.get('removedPermissionSets'));
                if (!permSetsToRemove.isEmpty()) {
                    List<PermissionSetAssignment> assignmentsToDelete = [
                        SELECT Id FROM PermissionSetAssignment 
                        WHERE AssigneeId = :targetUserId AND PermissionSetId IN :permSetsToRemove
                    ];
                    if (!assignmentsToDelete.isEmpty()) {
                        delete assignmentsToDelete;
                    }
                }
            }
            
            // Remove unselected permission set groups
            if (selectedPermissions.containsKey('removedPermissionSetGroups')) {
                List<String> permSetGroupsToRemove = convertToStringList(selectedPermissions.get('removedPermissionSetGroups'));
                if (!permSetGroupsToRemove.isEmpty()) {
                    List<PermissionSetAssignment> assignmentsToDelete = [
                        SELECT Id FROM PermissionSetAssignment 
                        WHERE AssigneeId = :targetUserId AND PermissionSetId IN :permSetGroupsToRemove
                    ];
                    if (!assignmentsToDelete.isEmpty()) {
                        delete assignmentsToDelete;
                    }
                }
            }
            
            // Remove unselected public groups
            if (selectedPermissions.containsKey('removedPublicGroups')) {
                List<String> groupsToRemove = convertToStringList(selectedPermissions.get('removedPublicGroups'));
                if (!groupsToRemove.isEmpty()) {
                    List<GroupMember> membersToDelete = [
                        SELECT Id FROM GroupMember 
                        WHERE UserOrGroupId = :targetUserId AND GroupId IN :groupsToRemove
                    ];
                    if (!membersToDelete.isEmpty()) {
                        delete membersToDelete;
                    }
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error removing unselected permissions: ' + e.getMessage());
        }
    }
    
    /**
     * Performs a dry-run comparison between source and target users to show what would change
     * @param sourceUserId The ID of the source user
     * @param targetUserId The ID of the target user
     * @return CloneDiffResult containing the differences
     */
    @AuraEnabled(cacheable=false)
    public static CloneDiffResult previewCloneDiff(String sourceUserId, String targetUserId) {
        try {
            CloneDiffResult diffResult = new CloneDiffResult();
            
            // Get source and target user details
            User sourceUser = [SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name FROM User WHERE Id = :sourceUserId LIMIT 1];
            User targetUser = [SELECT Id, ProfileId, Profile.Name, UserRoleId, UserRole.Name FROM User WHERE Id = :targetUserId LIMIT 1];
            
            // Compare profiles
            if (sourceUser.ProfileId != targetUser.ProfileId) {
                diffResult.profileChange = new ProfileChange();
                diffResult.profileChange.fromProfileId = targetUser.ProfileId;
                diffResult.profileChange.fromProfileName = targetUser.Profile.Name;
                diffResult.profileChange.toProfileId = sourceUser.ProfileId;
                diffResult.profileChange.toProfileName = sourceUser.Profile.Name;
                diffResult.profileChange.licenseCompatible = checkProfileLicenseCompatibility(sourceUser.ProfileId, targetUser.Id);
                diffResult.summary.hasProfileChange = true;
            }
            
            // Compare roles
            if (sourceUser.UserRoleId != targetUser.UserRoleId) {
                diffResult.roleChange = new RoleChange();
                diffResult.roleChange.fromRoleId = targetUser.UserRoleId;
                diffResult.roleChange.fromRoleName = targetUser.UserRole?.Name;
                diffResult.roleChange.toRoleId = sourceUser.UserRoleId;
                diffResult.roleChange.toRoleName = sourceUser.UserRole?.Name;
                diffResult.summary.hasRoleChange = true;
            }
            
            // Compare permission sets
            Set<Id> sourcePermissionSets = getPermissionSetIds(sourceUserId);
            Set<Id> targetPermissionSets = getPermissionSetIds(targetUserId);
            
            Set<Id> toAdd = new Set<Id>(sourcePermissionSets);
            toAdd.removeAll(targetPermissionSets);
            
            Set<Id> toRemove = new Set<Id>(targetPermissionSets);
            toRemove.removeAll(sourcePermissionSets);
            
            if (!toAdd.isEmpty()) {
                diffResult.addedPermissionSets = getPermissionSetDetails(toAdd);
                diffResult.summary.permissionSetsAdded = diffResult.addedPermissionSets.size();
            }
            
            if (!toRemove.isEmpty()) {
                diffResult.removedPermissionSets = getPermissionSetDetails(toRemove);
                diffResult.summary.permissionSetsRemoved = diffResult.removedPermissionSets.size();
            }
            
            // Compare permission set groups
            Set<Id> sourcePermissionSetGroups = getPermissionSetGroupIds(sourceUserId);
            Set<Id> targetPermissionSetGroups = getPermissionSetGroupIds(targetUserId);
            
            Set<Id> groupsToAdd = new Set<Id>(sourcePermissionSetGroups);
            groupsToAdd.removeAll(targetPermissionSetGroups);
            
            Set<Id> groupsToRemove = new Set<Id>(targetPermissionSetGroups);
            groupsToRemove.removeAll(sourcePermissionSetGroups);
            
            if (!groupsToAdd.isEmpty()) {
                diffResult.addedPermissionSetGroups = getPermissionSetGroupDetails(groupsToAdd);
                diffResult.summary.permissionSetGroupsAdded = diffResult.addedPermissionSetGroups.size();
            }
            
            if (!groupsToRemove.isEmpty()) {
                diffResult.removedPermissionSetGroups = getPermissionSetGroupDetails(groupsToRemove);
                diffResult.summary.permissionSetGroupsRemoved = diffResult.removedPermissionSetGroups.size();
            }
            
            // Compare groups (public groups and queues separately)
            Set<Id> sourceGroups = getGroupIds(sourceUserId);
            Set<Id> targetGroups = getGroupIds(targetUserId);
            
            Set<Id> publicGroupsToAdd = new Set<Id>(sourceGroups);
            publicGroupsToAdd.removeAll(targetGroups);
            
            Set<Id> publicGroupsToRemove = new Set<Id>(targetGroups);
            publicGroupsToRemove.removeAll(sourceGroups);
            
            // Get all groups to add/remove with type information
            List<GroupInfo> allGroupsToAdd = getGroupDetails(publicGroupsToAdd);
            List<GroupInfo> allGroupsToRemove = getGroupDetails(publicGroupsToRemove);
            
            // Separate regular groups from queues
            for (GroupInfo groupInfo : allGroupsToAdd) {
                if (groupInfo.type == 'Queue') {
                    diffResult.addedQueues.add(groupInfo);
                    diffResult.summary.queuesAdded++;
                } else {
                    diffResult.addedPublicGroups.add(groupInfo);
                    diffResult.summary.publicGroupsAdded++;
                }
            }
            
            for (GroupInfo groupInfo : allGroupsToRemove) {
                if (groupInfo.type == 'Queue') {
                    diffResult.removedQueues.add(groupInfo);
                    diffResult.summary.queuesRemoved++;
                } else {
                    diffResult.removedPublicGroups.add(groupInfo);
                    diffResult.summary.publicGroupsRemoved++;
                }
            }
            
            // Keep the combined lists for backward compatibility
            if (!publicGroupsToAdd.isEmpty()) {
                diffResult.addedGroups = allGroupsToAdd;
                diffResult.summary.groupsAdded = diffResult.addedGroups.size();
            }
            
            if (!publicGroupsToRemove.isEmpty()) {
                diffResult.removedGroups = allGroupsToRemove;
                diffResult.summary.groupsRemoved = diffResult.removedGroups.size();
            }
            
            // Compare user permissions
            List<String> userPermissionFields = getUserPermissionFields();
            System.debug('UserCloneController - previewCloneDiff: userPermissionFields size: ' + userPermissionFields.size());
            if (!userPermissionFields.isEmpty()) {
                diffResult.userPermissionChanges = compareUserPermissions(sourceUserId, targetUserId, userPermissionFields);
                System.debug('UserCloneController - previewCloneDiff: userPermissionChanges size: ' + (diffResult.userPermissionChanges != null ? String.valueOf(diffResult.userPermissionChanges.size()) : 'null'));
                System.debug('UserCloneController - previewCloneDiff: userPermissionChanges: ' + diffResult.userPermissionChanges);
                diffResult.summary.userPermissionsChanged = diffResult.userPermissionChanges.size();
                diffResult.summary.hasUserPermissionChanges = !diffResult.userPermissionChanges.isEmpty();
            } else {
                System.debug('UserCloneController - previewCloneDiff: No user permission fields found');
            }
            
            return diffResult;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error generating clone preview: ' + e.getMessage());
        }
    }
    
    /**
     * Compares user permissions between source and target users
     * @param sourceUserId The ID of the source user
     * @param targetUserId The ID of the target user
     * @param userPermissionFields List of user permission field names
     * @return List of UserPermissionChange objects representing the differences
     */
    private static List<UserPermissionChange> compareUserPermissions(String sourceUserId, String targetUserId, List<String> userPermissionFields) {
        List<UserPermissionChange> changes = new List<UserPermissionChange>();
        
        System.debug('UserCloneController - compareUserPermissions: Starting comparison');
        System.debug('UserCloneController - sourceUserId: ' + sourceUserId);
        System.debug('UserCloneController - targetUserId: ' + targetUserId);
        System.debug('UserCloneController - userPermissionFields: ' + userPermissionFields);
        System.debug('UserCloneController - userPermissionFields size: ' + (userPermissionFields != null ? String.valueOf(userPermissionFields.size()) : 'null'));
        
        try {
            // Build dynamic query to get user permission fields for both users
            String query = 'SELECT Id, ' + String.join(userPermissionFields, ', ') + ' FROM User WHERE Id IN (:sourceUserId, :targetUserId)';
            System.debug('UserCloneController - Query: ' + query);
            List<User> users = Database.query(query);
            System.debug('UserCloneController - Query returned ' + users.size() + ' users');
            
            if (users.size() != 2) {
                return changes; // Return empty list if we don't have both users
            }
            
            User sourceUser = null;
            User targetUser = null;
            
            for (User user : users) {
                if (user.Id == sourceUserId) {
                    sourceUser = user;
                } else if (user.Id == targetUserId) {
                    targetUser = user;
                }
            }
            
            if (sourceUser == null || targetUser == null) {
                return changes; // Return empty list if we don't have both users
            }
            
            // Compare each user permission field
            for (String fieldName : userPermissionFields) {
                try {
                    Boolean sourceValue = (Boolean) sourceUser.get(fieldName);
                    Boolean targetValue = (Boolean) targetUser.get(fieldName);
                    
                    // Convert null values to false for comparison
                    sourceValue = sourceValue != null ? sourceValue : false;
                    targetValue = targetValue != null ? targetValue : false;
                    
                    // Only add to changes if values are different
                    if (sourceValue != targetValue) {
                        UserPermissionChange change = new UserPermissionChange();
                        change.fieldName = fieldName;
                        change.label = getPermissionLabel(fieldName);
                        change.fromValue = String.valueOf(targetValue);
                        change.toValue = String.valueOf(sourceValue);
                        
                        if (sourceValue && !targetValue) {
                            change.changeType = 'Added';
                        } else if (!sourceValue && targetValue) {
                            change.changeType = 'Removed';
                        } else {
                            change.changeType = 'Changed';
                        }
                        
                        changes.add(change);
                        System.debug('UserCloneController - Added change: ' + change.fieldName + ' from ' + change.fromValue + ' to ' + change.toValue);
                    }
                } catch (Exception fieldEx) {
                    // Log field-specific errors but continue processing other fields
                    System.debug(LoggingLevel.ERROR, 'Error comparing field ' + fieldName + ': ' + fieldEx.getMessage());
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error comparing user permissions: ' + e.getMessage());
        }
        
        System.debug('UserCloneController - compareUserPermissions: Returning ' + changes.size() + ' changes');
        System.debug('UserCloneController - Final changes list: ' + changes);
        return changes;
    }
    
    /**
     * Gets a user-friendly label for a permission field
     * @param fieldName The API name of the permission field
     * @return A user-friendly label for the permission
     */
    private static String getPermissionLabel(String fieldName) {
        // Remove 'Permissions' prefix and convert camelCase to readable format
        String label = fieldName;
        
        if (label.startsWith('Permissions')) {
            label = label.substring(11); // Remove 'Permissions' prefix
        }
        
        // Convert camelCase to space-separated words
        label = label.replaceAll('([A-Z])', ' $1').trim();
        
        // Handle common abbreviations and special cases
        label = label.replace('Api', 'API');
        label = label.replace('Crm', 'CRM');
        label = label.replace('Sfdc', 'SFDC');
        label = label.replace('Cms', 'CMS');
        label = label.replace('Chatter', 'Chatter');
        label = label.replace('Lightning', 'Lightning');
        
        return label;
    }
    
    /**
     * Gets compatible profile suggestions for a user based on their current license
     * @param userId The ID of the user
     * @param sourceProfileId The profile ID being cloned from
     * @return List of compatible profile suggestions
     */
    @AuraEnabled(cacheable=false)
    public static List<CompatibleProfileSuggestion> getCompatibleProfiles(String userId, String sourceProfileId) {
        System.debug('getCompatibleProfiles called with userId: ' + userId + ', sourceProfileId: ' + sourceProfileId);
        
        try {
            List<CompatibleProfileSuggestion> suggestions = new List<CompatibleProfileSuggestion>();
            
            // Validate input parameters
            if (String.isBlank(userId) || String.isBlank(sourceProfileId)) {
                System.debug('Invalid parameters - userId: ' + userId + ', sourceProfileId: ' + sourceProfileId);
                throw new AuraHandledException('User ID and Source Profile ID are required');
            }
            
            System.debug('Querying target user with ID: ' + userId);
            // Get user's current license with null check
            List<User> targetUsers = [SELECT Id, Profile.UserLicense.Name FROM User WHERE Id = :userId LIMIT 1];
            if (targetUsers.isEmpty()) {
                System.debug('Target user not found for ID: ' + userId);
                throw new AuraHandledException('Target user not found');
            }
            User targetUser = targetUsers[0];
            System.debug('Target user found: ' + targetUser);
            
            if (targetUser.Profile?.UserLicense?.Name == null) {
                System.debug('Target user license is null');
                throw new AuraHandledException('Target user does not have a valid license');
            }
            String userLicense = targetUser.Profile.UserLicense.Name;
            System.debug('Target user license: ' + userLicense);
            
            System.debug('Querying source profile with ID: ' + sourceProfileId);
            // Get source profile details with null check
            List<Profile> sourceProfiles = [SELECT Id, Name, UserLicense.Name FROM Profile WHERE Id = :sourceProfileId LIMIT 1];
            if (sourceProfiles.isEmpty()) {
                System.debug('Source profile not found for ID: ' + sourceProfileId);
                throw new AuraHandledException('Source profile not found');
            }
            Profile sourceProfile = sourceProfiles[0];
            System.debug('Source profile found: ' + sourceProfile);
            
            if (sourceProfile.UserLicense?.Name == null) {
                System.debug('Source profile license is null');
                throw new AuraHandledException('Source profile does not have a valid license');
            }
            System.debug('Source profile license: ' + sourceProfile.UserLicense.Name);
            
            // If source profile is compatible, add it as primary suggestion
            if (sourceProfile.UserLicense.Name == userLicense) {
                System.debug('Source profile is compatible, adding as primary suggestion');
                CompatibleProfileSuggestion primarySuggestion = new CompatibleProfileSuggestion();
                primarySuggestion.profileId = sourceProfile.Id;
                primarySuggestion.profileName = sourceProfile.Name;
                primarySuggestion.userLicenseName = sourceProfile.UserLicense.Name;
                primarySuggestion.reason = 'Exact match from source user';
                primarySuggestion.isRecommended = true;
                suggestions.add(primarySuggestion);
            } else {
                System.debug('Source profile not compatible, finding alternatives');
                // Find alternative profiles with same license
                List<Profile> compatibleProfiles = [SELECT Id, Name, UserLicense.Name 
                                                   FROM Profile 
                                                   WHERE UserLicense.Name = :userLicense 
                                                   AND Id != :targetUser.ProfileId
                                                   ORDER BY Name];
                System.debug('Found ' + compatibleProfiles.size() + ' compatible profiles');
                
                for (Profile profile : compatibleProfiles) {
                    CompatibleProfileSuggestion suggestion = new CompatibleProfileSuggestion();
                    suggestion.profileId = profile.Id;
                    suggestion.profileName = profile.Name;
                    suggestion.userLicenseName = profile.UserLicense.Name;
                    suggestion.reason = 'Compatible with ' + userLicense + ' license';
                    suggestion.isRecommended = false;
                    suggestions.add(suggestion);
                }
            }
            
            System.debug('Returning ' + suggestions.size() + ' suggestions');
            return suggestions;
            
        } catch (Exception e) {
            System.debug('Exception in getCompatibleProfiles: ' + e.getMessage());
            System.debug('Exception type: ' + e.getTypeName());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            String errorMessage = 'Error getting compatible profiles';
            if (e.getMessage() != null && !String.isBlank(e.getMessage())) {
                errorMessage += ': ' + e.getMessage();
            }
            throw new AuraHandledException(errorMessage);
        }
    }
    
    // Helper methods for Phase 1 features
    private static Boolean checkProfileLicenseCompatibility(String profileId, String userId) {
        try {
            Profile sourceProfile = [SELECT UserLicense.Name FROM Profile WHERE Id = :profileId LIMIT 1];
            User targetUser = [SELECT Profile.UserLicense.Name FROM User WHERE Id = :userId LIMIT 1];
            return sourceProfile.UserLicense.Name == targetUser.Profile.UserLicense.Name;
        } catch (Exception e) {
            return false;
        }
    }
    
    private static Set<Id> getPermissionSetIds(String userId) {
        Set<Id> permissionSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSet.IsOwnedByProfile = false]) {
            permissionSetIds.add(psa.PermissionSetId);
        }
        return permissionSetIds;
    }
    
    private static Set<Id> getPermissionSetGroupIds(String userId) {
        Set<Id> permissionSetGroupIds = new Set<Id>();
        for (PermissionSetAssignment psa : [SELECT PermissionSetGroupId FROM PermissionSetAssignment WHERE AssigneeId = :userId AND PermissionSetGroupId != null]) {
            permissionSetGroupIds.add(psa.PermissionSetGroupId);
        }
        return permissionSetGroupIds;
    }
    
    private static Set<Id> getGroupIds(String userId) {
        Set<Id> groupIds = new Set<Id>();
        for (GroupMember gm : [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :userId AND Group.Type = 'Regular']) {
            groupIds.add(gm.GroupId);
        }
        return groupIds;
    }
    
    private static List<PermissionSetInfo> getPermissionSetDetails(Set<Id> permissionSetIds) {
        List<PermissionSetInfo> permissionSets = new List<PermissionSetInfo>();
        for (PermissionSet ps : [SELECT Id, Name, Label, Description FROM PermissionSet WHERE Id IN :permissionSetIds]) {
            PermissionSetInfo psInfo = new PermissionSetInfo();
            psInfo.id = ps.Id;
            psInfo.name = ps.Name;
            psInfo.label = ps.Label;
            psInfo.description = ps.Description;
            permissionSets.add(psInfo);
        }
        return permissionSets;
    }
    
    private static List<PermissionSetInfo> getPermissionSetGroupDetails(Set<Id> permissionSetGroupIds) {
        List<PermissionSetInfo> permissionSetGroups = new List<PermissionSetInfo>();
        for (PermissionSetGroup psg : [SELECT Id, DeveloperName, MasterLabel, Description FROM PermissionSetGroup WHERE Id IN :permissionSetGroupIds]) {
            PermissionSetInfo psgInfo = new PermissionSetInfo();
            psgInfo.id = psg.Id;
            psgInfo.name = psg.DeveloperName;
            psgInfo.label = psg.MasterLabel;
            psgInfo.description = psg.Description;
            permissionSetGroups.add(psgInfo);
        }
        return permissionSetGroups;
    }
    
    private static List<GroupInfo> getGroupDetails(Set<Id> groupIds) {
        List<GroupInfo> groups = new List<GroupInfo>();
        for (Group g : [SELECT Id, Name, Type, DeveloperName FROM Group WHERE Id IN :groupIds]) {
            GroupInfo groupInfo = new GroupInfo();
            groupInfo.id = g.Id;
            groupInfo.name = g.Name;
            groupInfo.type = g.Type;
            groupInfo.developerName = g.DeveloperName;
            groups.add(groupInfo);
        }
        return groups;
    }
    
    @future
    public static void saveCloneHistory(String sourceUserId, String newUserId, String newUserName) {
        try {
            User sourceUser = [SELECT Name FROM User WHERE Id = :sourceUserId];
            
            SA_Audit__RecentCloneUserLog__c cloneLog = new SA_Audit__RecentCloneUserLog__c(
                Name = newUserName,
                SA_Audit__Source_User__c = sourceUser.Name,
                SA_Audit__Source_User_Id__c = sourceUserId,
                SA_Audit__New_User_Id__c = newUserId,
                SA_Audit__UserClonedDate__c = Date.today(),
                SA_Audit__Clone_DateTime__c = DateTime.now()
            );
            
            // Check FLS before insert
            checkCreateAccess(cloneLog);
            
            // Check field-level security for each field
            Schema.DescribeSObjectResult describeResult = SA_Audit__RecentCloneUserLog__c.SObjectType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            
            if (!fieldMap.get('Name').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__Source_User__c').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__Source_User_Id__c').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__New_User_Id__c').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__UserClonedDate__c').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__Clone_DateTime__c').getDescribe().isCreateable()) {
                    throw new FLSException('Insufficient permissions to create RecentCloneUserLog__c record with all required fields.');
                }
            insert cloneLog;
        } catch(Exception e) {
            System.debug('Error saving clone history: ' + e.getMessage());
        }
    }
    
    /**
     * Save user clone history to SA_Audit__UserClonerDetails__c
     */
    @TestVisible
    private static void saveUserCloneHistory(String sourceUserId, String targetUserId) {

        try {
            // Get source and target user details
            List<User> users = [SELECT Id, Name FROM User WHERE Id IN (:sourceUserId, :targetUserId)];
            Map<Id, User> userMap = new Map<Id, User>(users);
            
            User sourceUser = userMap.get(sourceUserId);
            User targetUser = userMap.get(targetUserId);
            
            if (sourceUser == null || targetUser == null) {
                throw new AuraHandledException('Unable to find source or target user for history logging');
            }
            
            // Create history record
            SA_Audit__UserClonerDetails__c historyRecord = new SA_Audit__UserClonerDetails__c(
                Name = sourceUser.Name,
                SA_Audit__ClonedUserName__c = targetUser.Name,
                SA_Audit__ClonedDate__c = System.now(),
                SA_Audit__SourceUserId__c = sourceUserId,
                SA_Audit__ClonedUserId__c = targetUserId
            );
            
            // FLS check for SA_Audit__UserClonerDetails__c
            Schema.DescribeSObjectResult describeResult = SA_Audit__UserClonerDetails__c.sObjectType.getDescribe();
            if (!describeResult.isCreateable()) {
                throw new FLSException('Insufficient permissions to create UserClonerDetails records.');
            }
            
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            
            if (!fieldMap.get('Name').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__ClonedUserName__c').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__ClonedDate__c').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__SourceUserId__c').getDescribe().isCreateable() ||
                !fieldMap.get('SA_Audit__ClonedUserId__c').getDescribe().isCreateable()) {
                    throw new FLSException('Insufficient permissions to create UserClonerDetails record with all required fields.');
                }
            
            insert historyRecord;

            
        } catch(Exception e) {
            System.debug('Error saving user clone history: ' + e.getMessage());
            throw e; // Re-throw to be caught by calling method
        }
    }
    

    
    /**
     * Get user clone history from SA_Audit__UserClonerDetails__c
     */
    @AuraEnabled
    public static List<UserCloneHistoryWrapper> getUserCloneHistory() {
        System.debug('Starting getUserCloneHistory method');
        try {
            // FLS check for SA_Audit__UserClonerDetails__c (skip in test context)
            if (!Test.isRunningTest()) {
                Schema.DescribeSObjectResult describeResult = SA_Audit__UserClonerDetails__c.sObjectType.getDescribe();
                if (!describeResult.isAccessible()) {
                    throw new FLSException('Insufficient permissions to access UserClonerDetails records.');
                }
                
                Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
                
                if (!fieldMap.get('Name').getDescribe().isAccessible() ||
                    !fieldMap.get('SA_Audit__ClonedUserName__c').getDescribe().isAccessible() ||
                    !fieldMap.get('SA_Audit__ClonedDate__c').getDescribe().isAccessible() ||
                    !fieldMap.get('SA_Audit__SourceUserId__c').getDescribe().isAccessible() ||
                    !fieldMap.get('SA_Audit__ClonedUserId__c').getDescribe().isAccessible()) {
                        throw new FLSException('Insufficient permissions to access required UserClonerDetails fields.');
                    }
            }
            
            List<SA_Audit__UserClonerDetails__c> historyRecords = [
                SELECT Id, Name, SA_Audit__ClonedUserName__c, SA_Audit__ClonedDate__c, 
                       SA_Audit__SourceUserId__c, SA_Audit__ClonedUserId__c
                FROM SA_Audit__UserClonerDetails__c 
                ORDER BY SA_Audit__ClonedDate__c DESC 
                LIMIT 100
            ];
            
            List<UserCloneHistoryWrapper> wrapperList = new List<UserCloneHistoryWrapper>();
            
            for (SA_Audit__UserClonerDetails__c record : historyRecords) {
                UserCloneHistoryWrapper wrapper = new UserCloneHistoryWrapper();
                wrapper.id = record.Id;
                wrapper.sourceUserName = record.Name;
                wrapper.clonedUserName = record.SA_Audit__ClonedUserName__c;
                wrapper.clonedDate = record.SA_Audit__ClonedDate__c;
                wrapper.sourceUserId = record.SA_Audit__SourceUserId__c;
                wrapper.clonedUserId = record.SA_Audit__ClonedUserId__c;
                wrapper.clonedUserDetailUrl = '/lightning/r/User/' + record.SA_Audit__ClonedUserId__c + '/view';
                wrapperList.add(wrapper);
            }
            
            return wrapperList;
            
        } catch(Exception e) {
            System.debug('Error in getUserCloneHistory: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving clone history: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static CloneResult cloneUser(String sourceUserId, String newUserEmail, String newUserFirstName, String newUserLastName) {
        try {
            CloneResult result = new CloneResult();
            
            // Get all UserPermissions fields dynamically
            List<String> userPermissionFields = getUserPermissionFields();
            
            // Build dynamic query for cloning
            String cloneQuery = buildCloneUserQuery(userPermissionFields);
            
            // Query source user with all necessary fields including user settings
            List<User> sourceUsers = Database.query(cloneQuery + ' WHERE Id = :sourceUserId');
            if (sourceUsers.isEmpty()) {
                throw new AuraHandledException('Source user not found with Id: ' + sourceUserId);
            }
            
            User sourceUser = sourceUsers[0];
            
            // Create new user with all settings
            User newUser = new User(
                FirstName = newUserFirstName,
                LastName = newUserLastName,
                Email = newUserEmail,
                Username = newUserEmail,
                Alias = newUserFirstName.left(1) + newUserLastName.left(4),
                TimeZoneSidKey = sourceUser.TimeZoneSidKey,
                LocaleSidKey = sourceUser.LocaleSidKey,
                EmailEncodingKey = sourceUser.EmailEncodingKey,
                LanguageLocaleKey = sourceUser.LanguageLocaleKey,
                ProfileId = sourceUser.ProfileId,
                UserRoleId = sourceUser.UserRoleId,
                Title = sourceUser.Title,
                CompanyName = sourceUser.CompanyName,
                Department = sourceUser.Department,
                Division = sourceUser.Division,
                Street = sourceUser.Street,
                City = sourceUser.City,
                State = sourceUser.State,
                PostalCode = sourceUser.PostalCode,
                Country = sourceUser.Country,
                Phone = sourceUser.Phone,
                Fax = sourceUser.Fax,
                MobilePhone = sourceUser.MobilePhone,
                EmailPreferencesAutoBcc = sourceUser.EmailPreferencesAutoBcc,
                EmailPreferencesAutoBccStayInTouch = sourceUser.EmailPreferencesAutoBccStayInTouch,
                EmailPreferencesStayInTouchReminder = sourceUser.EmailPreferencesStayInTouchReminder,
                SenderEmail = sourceUser.SenderEmail,
                SenderName = sourceUser.SenderName,
                Signature = sourceUser.Signature,
                StayInTouchSubject = sourceUser.StayInTouchSubject,
                StayInTouchSignature = sourceUser.StayInTouchSignature,
                StayInTouchNote = sourceUser.StayInTouchNote,
                ForecastEnabled = sourceUser.ForecastEnabled,
                ManagerId = sourceUser.ManagerId,
                DelegatedApproverId = sourceUser.DelegatedApproverId,
                UserPreferencesActivityRemindersPopup = sourceUser.UserPreferencesActivityRemindersPopup,
                UserPreferencesEventRemindersCheckboxDefault = sourceUser.UserPreferencesEventRemindersCheckboxDefault,
                UserPreferencesHideCSNGetChatterMobileTask = sourceUser.UserPreferencesHideCSNGetChatterMobileTask, 
                UserPreferencesLightningExperiencePreferred = sourceUser.UserPreferencesLightningExperiencePreferred,
                StartDay = sourceUser.StartDay,
                EndDay = sourceUser.EndDay
            );
            // Dynamically assign Workday Id if the custom field exists and is createable in target org
            Map<String, Schema.SObjectField> userFieldMap = User.SObjectType.getDescribe().fields.getMap();
            if(userFieldMap.containsKey('Workday_Id__c') && userFieldMap.get('Workday_Id__c').getDescribe().isCreateable()) {
                 Object wdValue = sourceUser.get('Workday_Id__c');
                 if(wdValue == null) {
                     wdValue = 'AUTO-' + String.valueOf(System.currentTimeMillis());
                 }
                 newUser.put('Workday_Id__c', wdValue);
             }
            
            // Check FLS before insert
            checkCreateAccess(newUser);
            
            // Insert new user with dynamic fallback for missing required fields
            try {
                insert newUser;
            } catch (DmlException dmle) {
                // Handle validation exception
                if (dmle.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION) {
                    // Attempt to extract failing field API name from the error message
                    String errMsg = dmle.getDmlMessage(0);
                    String failingField;
                    Matcher m = Pattern.compile('\\[(.*?)\\]').matcher(errMsg);
                    if (m.find()) {
                        failingField = m.group(1);
                    }

                    // If we successfully parsed a field, and it is createable, retry with a placeholder value
                    Map<String, Schema.SObjectField> retryFieldMap = User.SObjectType.getDescribe().fields.getMap();
                    if (!String.isBlank(failingField) && retryFieldMap.containsKey(failingField) && retryFieldMap.get(failingField).getDescribe().isCreateable()) {
                        newUser.put(failingField, 'AUTO-' + String.valueOf(System.currentTimeMillis()));
                        insert newUser; // second attempt
                    } else {
                        // Rethrow if we cannot resolve the field gracefully
                        throw dmle;
                    }
                } 
                // Handle duplicate value error
                else if (dmle.getDmlType(0) == StatusCode.DUPLICATE_VALUE && dmle.getDmlMessage(0).contains('Workday_Id__c')) {
                    // Generate a unique Workday ID using timestamp for uniqueness
                    String uniqueWorkdayId = 'AUTO-' + String.valueOf(System.currentTimeMillis());
                    newUser.put('Workday_Id__c', uniqueWorkdayId);
                    System.debug('Retry with unique Workday_Id__c: ' + uniqueWorkdayId);
                    insert newUser; // retry with unique value
                } 
                // Handle other duplicate values
                else if (dmle.getDmlType(0) == StatusCode.DUPLICATE_VALUE) {
                    // Extract field name from error message
                    String errMsg = dmle.getDmlMessage(0);
                    String fieldName;
                    Matcher m = Pattern.compile('duplicate value found: (\\w+)').matcher(errMsg);
                    if (m.find()) {
                        fieldName = m.group(1);
                        if (!String.isBlank(fieldName) && fieldName.endsWith('__c') && 
                            userFieldMap.containsKey(fieldName) && 
                            userFieldMap.get(fieldName).getDescribe().isCreateable()) {
                            // Generate a unique value using timestamp
                            newUser.put(fieldName, 'AUTO-' + String.valueOf(System.currentTimeMillis()));
                            System.debug('Retry with unique value for field: ' + fieldName);
                            insert newUser; // retry with unique value
                        } else {
                            throw dmle; // We can't resolve this duplicate issue
                        }
                    } else {
                        throw dmle; // Couldn't parse the field name
                    }
                } else {
                    throw dmle; // Rethrow other types of exceptions
                }
            }
            system.debug('New user created with Id: ' + newUser.Id);
            result.newUserId = newUser.Id;
            
            // Dynamically copy all UserPermissions fields
            copyUserPermissions(sourceUser, newUser.Id, userPermissionFields);
            
            // Get Profile and Role names
            User userWithProfile = [SELECT Profile.Name, UserRole.Name 
                                    FROM User 
                                    WHERE Id = :newUser.Id];
            result.profileName = userWithProfile.Profile.Name;
            result.userRole = userWithProfile.UserRole.Name;
            
            // Clone permission sets
            List<PermissionSetAssignment> sourcePermSets = [
                SELECT PermissionSetId 
                FROM PermissionSetAssignment 
                WHERE AssigneeId = :sourceUserId
                AND PermissionSet.IsOwnedByProfile = false
            ];
            
            List<PermissionSetAssignment> newPermSets = new List<PermissionSetAssignment>();
            for(PermissionSetAssignment psa : sourcePermSets) {
                newPermSets.add(new PermissionSetAssignment(
                    AssigneeId = newUser.Id,
                    PermissionSetId = psa.PermissionSetId
                ));
            }
            
            if(!newPermSets.isEmpty()) {
                // Check FLS before insert
                checkCreateAccessForList(newPermSets);
                
                // Check field-level security for PermissionSetAssignment fields
                Schema.DescribeSObjectResult psaDescribe = PermissionSetAssignment.SObjectType.getDescribe();
                Map<String, Schema.SObjectField> psaFieldMap = psaDescribe.fields.getMap();
                
                if (!psaFieldMap.get('AssigneeId').getDescribe().isCreateable() ||
                    !psaFieldMap.get('PermissionSetId').getDescribe().isCreateable()) {
                        throw new FLSException('Insufficient permissions to create PermissionSetAssignment records with all required fields.');
                    }
                insert newPermSets;
                result.permissionSetsCloned = newPermSets.size();
            }
            
            // Clone group memberships
            List<GroupMember> sourceGroups = [SELECT GroupId 
                                              FROM GroupMember 
                                              WHERE UserOrGroupId = :sourceUserId];
            
            List<GroupMember> newGroups = new List<GroupMember>();
            for(GroupMember gm : sourceGroups) {
                newGroups.add(new GroupMember(
                    GroupId = gm.GroupId,
                    UserOrGroupId = newUser.Id
                ));
            }
            
            if(!newGroups.isEmpty()) {
                // Check FLS before insert
                checkCreateAccessForList(newGroups);
                
                // Check field-level security for GroupMember fields
                Schema.DescribeSObjectResult gmDescribe = GroupMember.SObjectType.getDescribe();
                Map<String, Schema.SObjectField> gmFieldMap = gmDescribe.fields.getMap();
                
                if (!gmFieldMap.get('GroupId').getDescribe().isCreateable() ||
                    !gmFieldMap.get('UserOrGroupId').getDescribe().isCreateable()) {
                        throw new FLSException('Insufficient permissions to create GroupMember records with all required fields.');
                    }
                insert newGroups;
                result.groupsCloned = newGroups.size();
            }
            saveCloneHistory(sourceUserId, newUser.Id, newUserFirstName + ' ' + newUserLastName);
            
            // Save clone history to SA_Audit__UserClonerDetails__c
            try {
                saveUserCloneHistory(sourceUserId, newUser.Id);
            } catch(Exception historyEx) {
                System.debug('Warning: Failed to save user clone history: ' + historyEx.getMessage());
                // Don't fail the main operation if history saving fails
            }
            
            system.debug('User cloned successfully.'+result);
            return result;
        } catch(Exception e) {
            throw new AuraHandledException(getFormattedError(e));
        }
    }
    // Modify the catch block in freezeAndCloneUser method
    @AuraEnabled
    public static CloneResult freezeAndCloneUser(String sourceUserId, String newUserEmail, String newUserFirstName, String newUserLastName) {
        Savepoint sp = Database.setSavepoint();
        try {
            // Check license availability first
            Integer activeUsers = [SELECT COUNT() FROM User WHERE IsActive = true AND Profile.UserLicense.Name = 'Salesforce'];
            Integer totalLicenses = [SELECT TotalLicenses FROM UserLicense WHERE Name = 'Salesforce' LIMIT 1].TotalLicenses;
            
            if (activeUsers >= totalLicenses) {
                throw new AuraHandledException('Your organization has reached its user license limit. Please deactivate the source user first.');
            }
            
            // First deactivate the source user
            User sourceUser = [SELECT Username, Alias, TimeZoneSidKey, LocaleSidKey, EmailEncodingKey, 
                               LanguageLocaleKey, ProfileId, UserRoleId, IsActive
                               FROM User 
                               WHERE Id = :sourceUserId];
            
            sourceUser.IsActive = false;
            
            // Check FLS before update
            checkUpdateAccess(sourceUser);
            update sourceUser;
            
            // Clone the user and return the result
            CloneResult result = cloneUser(sourceUserId, newUserEmail, newUserFirstName, newUserLastName);
            return result;
            
        } catch(Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(getFormattedError(e));
        }
    }
    
    //for critical access banner 
    public class CriticalAccessWrapper {
        @AuraEnabled public String userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String profileName;
        @AuraEnabled public Datetime lastLogin;
        @AuraEnabled public List<String> modifyAllSources;
        @AuraEnabled public List<String> authorApexSources;
        @AuraEnabled public List<String> apiAccessSources;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<CriticalAccessWrapper> getCriticalAccessData() {
        List<CriticalAccessWrapper> wrappers = new List<CriticalAccessWrapper>();
        Map<Id, User> users = new Map<Id, User>([
            SELECT Id, Name, Profile.Name, ProfileId, LastLoginDate
            FROM User 
            WHERE IsActive = true 
            AND Profile.UserLicense.Name = 'Salesforce'
            ORDER BY LastLoginDate DESC 
            LIMIT 1000
        ]);
        
        // Get all relevant permission sets and profiles
        Map<Id, PermissionSet> permissionSets = getRelevantPermissionSets(users.values());
        Map<Id, Profile> profiles = new Map<Id, Profile>([
            SELECT Id, Name, PermissionsModifyAllData, 
            PermissionsAuthorApex, PermissionsApiEnabled 
            FROM Profile 
            WHERE Id IN (SELECT ProfileId FROM User WHERE Id IN :users.keySet())
        ]);
        
        // Process users in batches
        // Replace the batch processing loop with
        processUserBatch(users.values(), permissionSets, profiles, wrappers);
        
        return wrappers;
    }
    
    private static Map<Id, PermissionSet> getRelevantPermissionSets(List<User> users) {
        Set<Id> permissionSetIds = new Set<Id>();
        for(PermissionSetAssignment psa : [
            SELECT PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId IN :users
        ]) {
            permissionSetIds.add(psa.PermissionSetId);
        }
        
        return new Map<Id, PermissionSet>([
            SELECT Id, Name, Label, PermissionsModifyAllData, 
            PermissionsAuthorApex, PermissionsApiEnabled
            FROM PermissionSet 
            WHERE Id IN :permissionSetIds 
            AND (PermissionsModifyAllData = true 
                 OR PermissionsAuthorApex = true 
                 OR PermissionsApiEnabled = true)
        ]);
    }
    
    private static void processUserBatch(List<User> users, Map<Id, PermissionSet> permissionSets,
                                         Map<Id, Profile> profiles, List<CriticalAccessWrapper> wrappers) {
                                             Map<Id, List<PermissionSetAssignment>> userAssignments = new Map<Id, List<PermissionSetAssignment>>();
                                             for(PermissionSetAssignment psa : [
                                                 SELECT AssigneeId, PermissionSetId 
                                                 FROM PermissionSetAssignment 
                                                 WHERE AssigneeId IN :users 
                                                 AND PermissionSetId IN :permissionSets.keySet()
                                             ]) {
                                                 if(!userAssignments.containsKey(psa.AssigneeId)) {
                                                     userAssignments.put(psa.AssigneeId, new List<PermissionSetAssignment>());
                                                 }
                                                 userAssignments.get(psa.AssigneeId).add(psa);
                                             }
                                             
                                             for(User u : users) {
                                                 CriticalAccessWrapper wrapper = createWrapper(u, profiles.get(u.ProfileId));
                                                 addPermissionSetSources(wrapper, userAssignments.get(u.Id), permissionSets);
                                                 if(!wrapper.modifyAllSources.isEmpty() || 
                                                    !wrapper.authorApexSources.isEmpty() || 
                                                    !wrapper.apiAccessSources.isEmpty()) {
                                                        wrappers.add(wrapper);
                                                    }
                                             }
                                         }
    
    private static CriticalAccessWrapper createWrapper(User u, Profile p) {
        CriticalAccessWrapper wrapper = new CriticalAccessWrapper();
        wrapper.userId = u.Id;
        wrapper.userName = u.Name;
        wrapper.profileName = p != null ? p.Name : 'Unknown Profile'; // Handle null profile
        wrapper.lastLogin = u.LastLoginDate;
        wrapper.modifyAllSources = new List<String>();
        wrapper.authorApexSources = new List<String>();
        wrapper.apiAccessSources = new List<String>();
        
        if(p != null) {
            if(p.PermissionsModifyAllData) wrapper.modifyAllSources.add(p.Name);
            if(p.PermissionsAuthorApex) wrapper.authorApexSources.add(p.Name);
            if(p.PermissionsApiEnabled) wrapper.apiAccessSources.add(p.Name);
        }
        
        return wrapper;
    }
    
    // Update addPermissionSetSources method
    private static void addPermissionSetSources(CriticalAccessWrapper wrapper, 
                                                List<PermissionSetAssignment> assignments,
                                                Map<Id, PermissionSet> permissionSets) {
                                                    if(assignments != null) {
                                                        for(PermissionSetAssignment psa : assignments) {
                                                            PermissionSet ps = permissionSets.get(psa.PermissionSetId);
                                                            if(ps != null) {
                                                                String sourceName = String.isNotBlank(ps.Label) ? ps.Label : ps.Name;
                                                                
                                                                if(ps.PermissionsModifyAllData) wrapper.modifyAllSources.add(sourceName);
                                                                if(ps.PermissionsAuthorApex) wrapper.authorApexSources.add(sourceName);
                                                                if(ps.PermissionsApiEnabled) wrapper.apiAccessSources.add(sourceName);
                                                            }
                                                        }
                                                    }
                                                }
    
    /**
     * Wrapper class for user clone history data
     */
    public class UserCloneHistoryWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String sourceUserName;
        @AuraEnabled public String clonedUserName;
        @AuraEnabled public DateTime clonedDate;
        @AuraEnabled public String sourceUserId;
        @AuraEnabled public String clonedUserId;
        @AuraEnabled public String clonedUserDetailUrl;
        
        public UserCloneHistoryWrapper() {
            // Default constructor
        }
    }
    
    /**
     * Helper method to convert Object to List<String>
     * Handles conversion from JavaScript arrays to Apex List<String>
     * @param obj The object to convert (typically from JavaScript)
     * @return List of strings, or empty list if conversion fails
     */
    private static List<String> convertToStringList(Object obj) {
        List<String> result = new List<String>();
        
        if (obj == null) {
            return result;
        }
        
        try {
            // Try direct cast first (might work if already List<String>)
            if (obj instanceof List<String>) {
                return (List<String>) obj;
            }
            
            // Handle List<Object> from JavaScript
            if (obj instanceof List<Object>) {
                List<Object> objList = (List<Object>) obj;
                for (Object item : objList) {
                    if (item != null) {
                        result.add(String.valueOf(item));
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error converting to List<String>: ' + e.getMessage());
        }
        
        return result;
    }

}