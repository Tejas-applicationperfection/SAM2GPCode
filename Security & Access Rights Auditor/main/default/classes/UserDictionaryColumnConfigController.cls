public with sharing class UserDictionaryColumnConfigController {
    
    /**
     * Get column visibility settings for the current user
     * @return Map of column names to visibility settings
     */
    public static Map<String, Boolean> getColumnVisibilitySettings() {
        Map<String, Boolean> columnVisibility = new Map<String, Boolean>{
            'ShowFieldName' => false,
            'ShowFieldType' => false,
            'ShowDescription' => false,
            'ShowHelpText' => false,
            'ShowHighlightedData' => false,
            'ShowSensitivity' => false,
            'ShowFieldUsage' => false,
            'ShowDataOwner' => false,
            'ShowComplianceCategorization' => false
        };
        
        // Get current user's ID and profile ID
        Id userId = UserInfo.getUserId();
        Id profileId = UserInfo.getProfileId();
        System.debug('Getting column visibility settings for user ID: ' + userId + ', profile ID: ' + profileId);
        
        try {
            // First check for user-specific settings
            List<UserDictionaryColumnConfig__c> userConfigs = [
                SELECT 
                    Id,
                    UserId__c,
                    ProfileId__c,
                    ShowFieldName__c, 
                    ShowFieldType__c, 
                    ShowDescription__c, 
                    ShowHelpText__c, 
                    ShowHighlightedData__c, 
                    ShowSensitivity__c, 
                    ShowFieldUsage__c, 
                    ShowDataOwner__c, 
                    ShowComplianceCategorization__c
                FROM UserDictionaryColumnConfig__c 
                WHERE UserId__c = :userId 
                LIMIT 1
            ];
            
            // If no user-specific settings, check for profile settings
            if (userConfigs.isEmpty()) {
                System.debug('No user-specific settings found, checking profile settings');
                userConfigs = [
                    SELECT 
                        Id,
                        UserId__c,
                        ProfileId__c,
                        ShowFieldName__c, 
                        ShowFieldType__c, 
                        ShowDescription__c, 
                        ShowHelpText__c, 
                        ShowHighlightedData__c, 
                        ShowSensitivity__c, 
                        ShowFieldUsage__c, 
                        ShowDataOwner__c, 
                        ShowComplianceCategorization__c
                    FROM UserDictionaryColumnConfig__c 
                    WHERE ProfileId__c = :profileId 
                    LIMIT 1
                ];
            }
            
            System.debug('Found ' + userConfigs.size() + ' column visibility configurations');
            
            if (!userConfigs.isEmpty()) {
                UserDictionaryColumnConfig__c config = userConfigs[0];
                System.debug('Configuration ID: ' + config.Id + 
                           ', UserId__c: ' + config.UserId__c + 
                           ', ProfileId__c: ' + config.ProfileId__c);
                
                // Update visibility map with settings from the database
                columnVisibility.put('ShowFieldName', config.ShowFieldName__c);
                columnVisibility.put('ShowFieldType', config.ShowFieldType__c);
                columnVisibility.put('ShowDescription', config.ShowDescription__c);
                columnVisibility.put('ShowHelpText', config.ShowHelpText__c);
                columnVisibility.put('ShowHighlightedData', config.ShowHighlightedData__c);
                columnVisibility.put('ShowSensitivity', config.ShowSensitivity__c);
                columnVisibility.put('ShowFieldUsage', config.ShowFieldUsage__c);
                columnVisibility.put('ShowDataOwner', config.ShowDataOwner__c);
                columnVisibility.put('ShowComplianceCategorization', config.ShowComplianceCategorization__c);
                
                System.debug('Column visibility settings from database: ' + 
                           'ShowFieldName=' + config.ShowFieldName__c + 
                           ', ShowFieldType=' + config.ShowFieldType__c + 
                           ', ShowDescription=' + config.ShowDescription__c + 
                           ', ShowHelpText=' + config.ShowHelpText__c + 
                           ', ShowHighlightedData=' + config.ShowHighlightedData__c + 
                           ', ShowSensitivity=' + config.ShowSensitivity__c + 
                           ', ShowFieldUsage=' + config.ShowFieldUsage__c + 
                           ', ShowDataOwner=' + config.ShowDataOwner__c + 
                           ', ShowComplianceCategorization=' + config.ShowComplianceCategorization__c);
                
                System.debug('Found column visibility settings');
            } else {
                System.debug('No column visibility settings found. Using defaults.');
            }
        } catch (Exception e) {
            // If no settings found, use defaults (all columns visible)
            System.debug('Error retrieving column visibility settings: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
        }
        
        System.debug('Returning column visibility settings: ' + columnVisibility);
        return columnVisibility;
    }
    
    /**
     * Get column visibility settings for a specific user or profile
     * @param userId The ID of the user to get settings for (optional)
     * @param profileId The ID of the profile to get settings for (used if userId is null)
     * @return Map of column names to visibility settings
     */
    public static Map<String, Boolean> getColumnVisibilitySettingsFor(Id userId, Id profileId) {
        return getColumnVisibilitySettingsFor(userId, profileId, null);
    }
    
    /**
     * Get column visibility settings for a specific user, profile, or permission set
     * @param userId The ID of the user to get settings for (optional)
     * @param profileId The ID of the profile to get settings for (used if userId is null)
     * @param permissionSetId The ID of the permission set to get settings for (used if userId and profileId are null)
     * @return Map of column names to visibility settings
     */
    public static Map<String, Boolean> getColumnVisibilitySettingsFor(Id userId, Id profileId, Id permissionSetId) {
        Map<String, Boolean> columnVisibility = new Map<String, Boolean>{
            'ShowFieldName' => false,
            'ShowFieldType' => false,
            'ShowDescription' => false,
            'ShowHelpText' => false,
            'ShowHighlightedData' => false,
            'ShowSensitivity' => false,
            'ShowFieldUsage' => false,
            'ShowDataOwner' => false,
            'ShowComplianceCategorization' => false
        };
        
        try {
            List<UserDictionaryColumnConfig__c> configs;
            
            if (userId != null) {
                configs = [
                    SELECT 
                        ShowFieldName__c, 
                        ShowFieldType__c, 
                        ShowDescription__c, 
                        ShowHelpText__c, 
                        ShowHighlightedData__c, 
                        ShowSensitivity__c, 
                        ShowFieldUsage__c, 
                        ShowDataOwner__c, 
                        ShowComplianceCategorization__c
                    FROM UserDictionaryColumnConfig__c 
                    WHERE UserId__c = :userId 
                    LIMIT 1
                ];
            } else if (profileId != null) {
                configs = [
                    SELECT 
                        ShowFieldName__c, 
                        ShowFieldType__c, 
                        ShowDescription__c, 
                        ShowHelpText__c, 
                        ShowHighlightedData__c, 
                        ShowSensitivity__c, 
                        ShowFieldUsage__c, 
                        ShowDataOwner__c, 
                        ShowComplianceCategorization__c
                    FROM UserDictionaryColumnConfig__c 
                    WHERE ProfileId__c = :profileId 
                    LIMIT 1
                ];
            } else if (permissionSetId != null) {
                configs = [
                    SELECT 
                        ShowFieldName__c, 
                        ShowFieldType__c, 
                        ShowDescription__c, 
                        ShowHelpText__c, 
                        ShowHighlightedData__c, 
                        ShowSensitivity__c, 
                        ShowFieldUsage__c, 
                        ShowDataOwner__c, 
                        ShowComplianceCategorization__c
                    FROM UserDictionaryColumnConfig__c 
                    WHERE PermissionSetId__c = :permissionSetId 
                    LIMIT 1
                ];
            }
            
            if (configs != null && !configs.isEmpty()) {
                UserDictionaryColumnConfig__c config = configs[0];
                
                // Update visibility map with settings from the database
                columnVisibility.put('ShowFieldName', config.ShowFieldName__c);
                columnVisibility.put('ShowFieldType', config.ShowFieldType__c);
                columnVisibility.put('ShowDescription', config.ShowDescription__c);
                columnVisibility.put('ShowHelpText', config.ShowHelpText__c);
                columnVisibility.put('ShowHighlightedData', config.ShowHighlightedData__c);
                columnVisibility.put('ShowSensitivity', config.ShowSensitivity__c);
                columnVisibility.put('ShowFieldUsage', config.ShowFieldUsage__c);
                columnVisibility.put('ShowDataOwner', config.ShowDataOwner__c);
                columnVisibility.put('ShowComplianceCategorization', config.ShowComplianceCategorization__c);
            }
        } catch (Exception e) {
            System.debug('Error retrieving column visibility settings: ' + e.getMessage());
        }
        
        return columnVisibility;
    }
    
    /**
     * Save column visibility settings for a specific user or profile
     * @param userId The ID of the user to save settings for (optional)
     * @param profileId The ID of the profile to save settings for (used if userId is null)
     * @param columnVisibility Map of column names to visibility settings
     * @return True if save was successful, false otherwise
     */
    public static Boolean saveColumnVisibilitySettings(Id userId, Id profileId, Map<String, Boolean> columnVisibility) {
        return saveColumnVisibilitySettings(userId, profileId, null, columnVisibility);
    }
    
    /**
     * Save column visibility settings for a specific user, profile, or permission set
     * @param userId The ID of the user to save settings for (optional)
     * @param profileId The ID of the profile to save settings for (used if userId is null)
     * @param permissionSetId The ID of the permission set to save settings for (used if userId and profileId are null)
     * @param columnVisibility Map of column names to visibility settings
     * @return True if save was successful, false otherwise
     */
    public static Boolean saveColumnVisibilitySettings(Id userId, Id profileId, Id permissionSetId, Map<String, Boolean> columnVisibility) {
        try {
            // Check if settings already exist
            List<UserDictionaryColumnConfig__c> existingConfigs;
            
            if (userId != null) {
                existingConfigs = [
                    SELECT Id FROM UserDictionaryColumnConfig__c 
                    WHERE UserId__c = :userId
                    LIMIT 1
                ];
            } else if (profileId != null) {
                existingConfigs = [
                    SELECT Id FROM UserDictionaryColumnConfig__c 
                    WHERE ProfileId__c = :profileId
                    LIMIT 1
                ];
            } else if (permissionSetId != null) {
                existingConfigs = [
                    SELECT Id FROM UserDictionaryColumnConfig__c 
                    WHERE PermissionSetId__c = :permissionSetId
                    LIMIT 1
                ];
            } else {
                // No valid ID provided
                return false;
            }
            
            UserDictionaryColumnConfig__c config;
            
            if (!existingConfigs.isEmpty()) {
                config = existingConfigs[0];
            } else {
                // Create new config if none exists
                config = new UserDictionaryColumnConfig__c();
                
                if (userId != null) {
                    User u = [SELECT Name, ProfileId FROM User WHERE Id = :userId LIMIT 1];
                    config.Name = 'Config for user: ' + u.Name;
                    config.UserId__c = userId;
                    config.ProfileId__c = u.ProfileId; // Store the profile ID as well for reference
                } else if (profileId != null) {
                    Profile p = [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
                    config.Name = 'Config for profile: ' + p.Name;
                    config.ProfileId__c = profileId;
                } else if (permissionSetId != null) {
                    PermissionSet ps = [SELECT Label FROM PermissionSet WHERE Id = :permissionSetId LIMIT 1];
                    config.Name = 'Config for permission set: ' + ps.Label;
                    config.PermissionSetId__c = permissionSetId;
                }
            }
            
            // Update config with new visibility settings
            config.ShowFieldName__c = columnVisibility.get('ShowFieldName');
            config.ShowFieldType__c = columnVisibility.get('ShowFieldType');
            config.ShowDescription__c = columnVisibility.get('ShowDescription');
            config.ShowHelpText__c = columnVisibility.get('ShowHelpText');
            config.ShowHighlightedData__c = columnVisibility.get('ShowHighlightedData');
            config.ShowSensitivity__c = columnVisibility.get('ShowSensitivity');
            config.ShowFieldUsage__c = columnVisibility.get('ShowFieldUsage');
            config.ShowDataOwner__c = columnVisibility.get('ShowDataOwner');
            config.ShowComplianceCategorization__c = columnVisibility.get('ShowComplianceCategorization');
            
            upsert config;
            return true;
        } catch (Exception e) {
            System.debug('Error saving column visibility settings: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Get all profiles in the org
     * @return List of SelectOption objects for all profiles
     */
    public static List<SelectOption> getAllProfiles() {
        List<SelectOption> options = new List<SelectOption>();
        
        for (Profile p : [SELECT Id, Name FROM Profile ORDER BY Name]) {
            options.add(new SelectOption(p.Id, p.Name));
        }
        
        return options;
    }
    
    /**
     * Get all users in the org
     * @return List of SelectOption objects for all users
     */
    public static List<SelectOption> getAllUsers() {
        List<SelectOption> options = new List<SelectOption>();
        
        // Add a "None" option to indicate profile-based settings
        options.add(new SelectOption('', '-- Select a User --'));
        
        for (User u : [SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true ORDER BY Name]) {
            options.add(new SelectOption(u.Id, u.Name + ' (' + u.Profile.Name + ')'));
        }
        
        return options;
    }
    
    /**
     * Get all Permission Sets in the org
     * @return List of SelectOption objects for all Permission Sets
     */
    public static List<SelectOption> getAllPermissionSets() {
        List<SelectOption> options = new List<SelectOption>();
        
        for (PermissionSet ps : [SELECT Id, Label FROM PermissionSet WHERE IsOwnedByProfile = false ORDER BY Label]) {
            options.add(new SelectOption(ps.Id, ps.Label));
        }
        
        return options;
    }
}