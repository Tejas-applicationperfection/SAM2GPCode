public with sharing class ColumnVisibilityController {
    /**
     * Configuration types for UI components
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getConfigurationTypes() {
        List<String> types = new List<String>();
        types.add('By Profile');
        types.add('By User');
        types.add('By Permission Set');
        return types;
    }

    /**
     * Proxy to retrieve objects by type for LWC consumption
     * Delegates to ObjectFieldSelectorController to avoid duplication
     * @param objectType 'Organization' or 'Managed'
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectFieldSelectorController.ObjectInfo> getObjects(String objectType) {
        try {
            return ObjectFieldSelectorController.getObjectsByType(objectType);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving objects: ' + e.getMessage());
        }
    }
    
    /**
     * Get all profiles accessible to the current user
     * @return List<Profile> List of profiles
     */
    @AuraEnabled(cacheable=true)
    public static List<Profile> getProfiles() {
        try {
            return [
                SELECT Id, Name 
                FROM Profile 
                WHERE Id != NULL 
                ORDER BY Name ASC
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving profiles: ' + e.getMessage());
        }
    }
    
    /**
     * Get all active users accessible to the current user
     * @return List<User> List of users
     */
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers() {
        try {
            return [
                SELECT Id, Name, Username, Email, Profile.Name
                FROM User 
                WHERE IsActive = true 
                ORDER BY Name ASC
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving users: ' + e.getMessage());
        }
    }
    
    /**
     * Get all permission sets accessible to the current user
     * @return List<PermissionSet> List of permission sets
     */
    @AuraEnabled(cacheable=true)
    public static List<PermissionSet> getPermissionSets() {
        try {
            return [
                SELECT Id, Name, Label, Description
                FROM PermissionSet 
                WHERE IsOwnedByProfile = false 
                ORDER BY Label ASC
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving permission sets: ' + e.getMessage());
        }
    }
    
    /**
     * Save column visibility configuration using custom object storage
     * @param targetType Type of target (Profile, User, PermissionSet)
     * @param targetId ID of the target
     * @param targetName Name of the target
     * @param showFieldName Show field name column
     * @param showFieldType Show field type column
     * @param showDescription Show description column
     * @param showHelpText Show help text column
     * @param showSensitivity Show sensitivity column
     * @param showFieldUsage Show field usage column
     * @param showDataOwner Show data owner column
     * @param showComplianceCategorizaton Show compliance categorization column
     */
    @AuraEnabled
    public static String saveColumnConfiguration(String targetType, String targetId, String targetName,
                                               Boolean showFieldName, Boolean showFieldType, Boolean showDescription,
                                               Boolean showHelpText, Boolean showSensitivity, Boolean showFieldUsage,
                                               Boolean showDataOwner, Boolean showComplianceCategorizaton) {
        try {
            System.debug('Saving configuration for: ' + targetType + ' - ' + targetName);
            
            // Check if configuration already exists
            List<Field_Visibility_Config__c> existingConfigs = [
                SELECT Id FROM Field_Visibility_Config__c 
                WHERE Target_Type__c = :targetType AND Target_ID__c = :targetId 
                LIMIT 1
            ];
            
            Field_Visibility_Config__c configRecord;
            
            if (!existingConfigs.isEmpty()) {
                // Update existing configuration
                configRecord = existingConfigs[0];
            } else {
                // Create new configuration
                configRecord = new Field_Visibility_Config__c();
                configRecord.Target_Type__c = targetType;
                configRecord.Target_ID__c = targetId;
                configRecord.Target_Name__c = targetName;
            }
            
            // Set all configuration fields
            configRecord.Show_Field_Name__c = showFieldName;
            configRecord.Show_Field_Type__c = showFieldType;
            configRecord.Show_Description__c = showDescription;
            configRecord.Show_Help_Text__c = showHelpText;
            configRecord.Show_Data_Owner__c = showDataOwner;
            configRecord.Show_Field_Usage__c = showFieldUsage;
            configRecord.Show_Compliance_Categorization__c = showComplianceCategorizaton;
            configRecord.Show_Sensitivity__c = showSensitivity;
            
            // Upsert the record
            upsert configRecord;
            
            return 'Configuration saved successfully for ' + targetName + '!';
            
        } catch (Exception e) {
            System.debug('Error saving configuration: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving configuration: ' + e.getMessage());
        }
    }
    
    /**
     * Save column visibility configuration using configuration object
     * @param objectName Name of the object being configured
     * @param configuration Configuration object containing target and field visibility settings
     * @return String Success message
     */
    @AuraEnabled
    public static String saveColumnVisibility(String objectName, Map<String, Object> configuration) {
        try {
            System.debug('Saving column visibility configuration for object: ' + objectName);
            System.debug('Configuration: ' + JSON.serialize(configuration));
            
            // Validate input parameters
            if (String.isBlank(objectName)) {
                throw new AuraHandledException('Object name is required');
            }
            
            if (configuration == null || configuration.isEmpty()) {
                throw new AuraHandledException('Configuration object is required');
            }
            
            // Extract configuration details
            String targetType = (String) configuration.get('targetType');
            String targetId = (String) configuration.get('targetId');
            String targetName = (String) configuration.get('targetName');
            Object visibleFieldsObj = configuration.get('visibleFields');
            
            // Validate required fields
            if (String.isBlank(targetType)) {
                throw new AuraHandledException('Target type is required');
            }
            
            if (String.isBlank(targetId)) {
                throw new AuraHandledException('Target ID is required');
            }
            
            if (visibleFieldsObj == null) {
                throw new AuraHandledException('Visible fields list is required');
            }
            
            // Convert visibleFields to List<String>
            List<String> visibleFields;
            if (visibleFieldsObj instanceof List<String>) {
                visibleFields = (List<String>) visibleFieldsObj;
            } else if (visibleFieldsObj instanceof List<Object>) {
                visibleFields = new List<String>();
                for (Object obj : (List<Object>) visibleFieldsObj) {
                    if (obj != null) {
                        visibleFields.add(String.valueOf(obj));
                    }
                }
            } else {
                throw new AuraHandledException('Visible fields must be a list');
            }
            
            System.debug('Processed configuration - TargetType: ' + targetType + ', TargetId: ' + targetId + ', VisibleFields: ' + visibleFields);
            
            // Check if configuration already exists
            List<Field_Visibility_Config__c> existingConfigs = [
                SELECT Id FROM Field_Visibility_Config__c 
                WHERE Target_Type__c = :targetType AND Target_ID__c = :targetId 
                LIMIT 1
            ];
            
            Field_Visibility_Config__c configRecord;
            
            if (!existingConfigs.isEmpty()) {
                // Update existing configuration
                configRecord = existingConfigs[0];
                System.debug('Updating existing configuration record: ' + configRecord.Id);
            } else {
                // Create new configuration
                configRecord = new Field_Visibility_Config__c();
                configRecord.Target_Type__c = targetType;
                configRecord.Target_ID__c = targetId;
                System.debug('Creating new configuration record');
            }
            
            // Set target name
            configRecord.Target_Name__c = targetName != null ? targetName : 'Unknown';
            
            // Set field visibility based on selected fields
            configRecord.Show_Field_Name__c = visibleFields.contains('Field_Name__c') || visibleFields.contains('fieldName');
            configRecord.Show_Field_Type__c = visibleFields.contains('Field_Type__c') || visibleFields.contains('fieldType');
            configRecord.Show_Description__c = visibleFields.contains('Description__c') || visibleFields.contains('description');
            configRecord.Show_Help_Text__c = visibleFields.contains('Help_Text__c') || visibleFields.contains('helpText');
            configRecord.Show_Sensitivity__c = visibleFields.contains('Sensitivity__c') || visibleFields.contains('sensitivity');
            configRecord.Show_Field_Usage__c = visibleFields.contains('Field_Usage__c') || visibleFields.contains('fieldUsage');
            configRecord.Show_Data_Owner__c = visibleFields.contains('Data_Owner__c') || visibleFields.contains('dataOwner');
            configRecord.Show_Compliance_Categorization__c = visibleFields.contains('Compliance_Categorization__c') || visibleFields.contains('complianceCategorization');
            
            System.debug('Field visibility settings - FieldName: ' + configRecord.Show_Field_Name__c + 
                        ', FieldType: ' + configRecord.Show_Field_Type__c + 
                        ', Description: ' + configRecord.Show_Description__c + 
                        ', HelpText: ' + configRecord.Show_Help_Text__c + 
                        ', Sensitivity: ' + configRecord.Show_Sensitivity__c + 
                        ', FieldUsage: ' + configRecord.Show_Field_Usage__c + 
                        ', DataOwner: ' + configRecord.Show_Data_Owner__c + 
                        ', Compliance: ' + configRecord.Show_Compliance_Categorization__c);
            
            // Upsert the record
            upsert configRecord;
            
            System.debug('Configuration saved successfully for ' + targetName + ' with ID: ' + configRecord.Id);
            return 'Configuration saved successfully for ' + targetName + '!';
            
        } catch (Exception e) {
            System.debug('Error saving column visibility configuration: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            System.debug('Error type: ' + e.getTypeName());
            
            // Provide more specific error messages
            String errorMessage = 'Error saving configuration: ';
            if (e instanceof DmlException) {
                errorMessage += 'Database operation failed. Please check your permissions and try again.';
            } else if (e instanceof AuraHandledException) {
                errorMessage += e.getMessage();
            } else {
                errorMessage += 'An unexpected error occurred. Please try again or contact your administrator.';
            }
            
            throw new AuraHandledException(errorMessage);
        }
    }

    /**
     * Get visibility settings used by columnVisibilityManager LWC
     * Returns the same payload shape as ColumnConfiguration
     */
    @AuraEnabled(cacheable=true)
    public static ColumnConfiguration getVisibilitySettings(String targetType, String targetId, String objectName) {
        // Currently objectName is not persisted; reserved for future per-object configs
        return getExistingConfiguration(targetType, targetId);
    }

    /**
     * Save visibility settings from columnVisibilityManager LWC
     * Accepts a single settings map argument for easier LWC invocation
     */
    @AuraEnabled
    public static String saveVisibilitySettings(Map<String, Object> settings) {
        if (settings == null || settings.isEmpty()) {
            throw new AuraHandledException('Settings are required');
        }

        // Extract values safely
        String targetType = (String) settings.get('targetType');
        String targetId = (String) settings.get('targetId');
        String targetName = (String) settings.get('targetName');
        // objectName present but currently unused in persistence
        // String objectName = (String) settings.get('objectName');

        if (String.isBlank(targetType) || String.isBlank(targetId)) {
            throw new AuraHandledException('Target type and target ID are required');
        }

        // Booleans may arrive as Boolean or String("true"/"false")
        Boolean showFieldName = parseBoolean(settings.get('showFieldName'), true);
        Boolean showDescription = parseBoolean(settings.get('showDescription'), true);
        Boolean showHelpText = parseBoolean(settings.get('showHelpText'), true);
        Boolean showFieldUsage = parseBoolean(settings.get('showFieldUsage'), true);
        Boolean showComplianceCategorization = parseBoolean(settings.get('showComplianceCategorization'), true);
        Boolean showFieldType = parseBoolean(settings.get('showFieldType'), true);
        Boolean showSensitivity = parseBoolean(settings.get('showSensitivity'), true);
        Boolean showDataOwner = parseBoolean(settings.get('showDataOwner'), true);

        try {
            // Upsert logic identical to saveColumnConfiguration
            List<Field_Visibility_Config__c> existingConfigs = [
                SELECT Id FROM Field_Visibility_Config__c 
                WHERE Target_Type__c = :targetType AND Target_ID__c = :targetId 
                LIMIT 1
            ];

            Field_Visibility_Config__c configRecord;
            if (!existingConfigs.isEmpty()) {
                configRecord = existingConfigs[0];
            } else {
                configRecord = new Field_Visibility_Config__c();
                configRecord.Target_Type__c = targetType;
                configRecord.Target_ID__c = targetId;
            }

            configRecord.Target_Name__c = targetName != null ? targetName : 'Unknown';
            configRecord.Show_Field_Name__c = showFieldName;
            configRecord.Show_Field_Type__c = showFieldType;
            configRecord.Show_Description__c = showDescription;
            configRecord.Show_Help_Text__c = showHelpText;
            configRecord.Show_Sensitivity__c = showSensitivity;
            configRecord.Show_Field_Usage__c = showFieldUsage;
            configRecord.Show_Data_Owner__c = showDataOwner;
            configRecord.Show_Compliance_Categorization__c = showComplianceCategorization;

            upsert configRecord;
            return 'Configuration saved successfully for ' + (targetName != null ? targetName : targetId) + '!';
        } catch (Exception e) {
            throw new AuraHandledException('Error saving configuration: ' + e.getMessage());
        }
    }

    // Helper to parse loose boolean values coming from JS
    private static Boolean parseBoolean(Object val, Boolean defaultValue) {
        if (val == null) return defaultValue;
        if (val instanceof Boolean) return (Boolean) val;
        String s = String.valueOf(val);
        if (s == null) return defaultValue;
        s = s.trim().toLowerCase();
        if (s == 'true') return true;
        if (s == 'false') return false;
        return defaultValue;
    }
    
    /**
     * Get existing column configuration for a target using custom object storage
     * @param targetType Type of target (Profile, User, PermissionSet)
     * @param targetId ID of the target
     * @return ColumnConfiguration Existing configuration or null
     */
    @AuraEnabled(cacheable=true)
    public static ColumnConfiguration getExistingConfiguration(String targetType, String targetId) {
        try {
            System.debug('Looking for configuration: ' + targetType + ' - ' + targetId);
            
            // Query for existing configuration record
            List<Field_Visibility_Config__c> configs = [
                SELECT Target_Type__c, Target_ID__c, Target_Name__c,
                       Show_Field_Name__c, Show_Field_Type__c, Show_Description__c, 
                       Show_Help_Text__c, Show_Data_Owner__c, Show_Field_Usage__c,
                       Show_Compliance_Categorization__c, Show_Sensitivity__c
                FROM Field_Visibility_Config__c 
                WHERE Target_Type__c = :targetType AND Target_ID__c = :targetId 
                LIMIT 1
            ];
            
            if (!configs.isEmpty()) {
                // Found existing configuration
                Field_Visibility_Config__c config = configs[0];
                System.debug('Found existing configuration for: ' + config.Target_Name__c);
                
                return new ColumnConfiguration(
                    config.Target_Type__c,
                    config.Target_ID__c,
                    config.Target_Name__c,
                    config.Show_Field_Name__c,
                    config.Show_Field_Type__c,
                    config.Show_Description__c,
                    config.Show_Help_Text__c,
                    config.Show_Sensitivity__c,
                    config.Show_Field_Usage__c,
                    config.Show_Data_Owner__c,
                    config.Show_Compliance_Categorization__c
                );
            }
            
            System.debug('No existing configuration found, returning default');
            
            // Return default configuration (all columns visible)
            return new ColumnConfiguration(
                targetType,
                targetId,
                '', // target name will be set by the component
                true, // showFieldName
                true, // showFieldType
                true, // showDescription
                true, // showHelpText
                true, // showSensitivity
                true, // showFieldUsage
                true, // showDataOwner
                true  // showComplianceCategorizaton
            );
            
        } catch (Exception e) {
            System.debug('Error getting existing configuration: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            // Return default configuration on error
            return new ColumnConfiguration(
                targetType,
                targetId,
                '',
                true, true, true, true, true, true, true, true
            );
        }
    }
    
    /**
     * Get column configuration for current user
     * @return ColumnConfiguration Configuration for current user
     */
    @AuraEnabled(cacheable=true)
    public static ColumnConfiguration getCurrentUserConfiguration() {
        try {
            String currentUserId = UserInfo.getUserId();
            String currentProfileId = UserInfo.getProfileId();
            
            System.debug('Getting configuration for user: ' + currentUserId + ', profile: ' + currentProfileId);
            
            // Check for user-specific configuration first (highest priority)
            ColumnConfiguration userConfig = getExistingConfiguration('User', currentUserId);
            if (userConfig != null && !isDefaultConfiguration(userConfig)) {
                System.debug('Found user-specific configuration');
                return userConfig;
            }
            
            // Check for profile-specific configuration (medium priority)
            ColumnConfiguration profileConfig = getExistingConfiguration('Profile', currentProfileId);
            if (profileConfig != null && !isDefaultConfiguration(profileConfig)) {
                System.debug('Found profile-specific configuration');
                return profileConfig;
            }
            
            // Check for permission set configurations (lower priority)
            List<PermissionSetAssignment> userPermSets = [
                SELECT PermissionSetId
                FROM PermissionSetAssignment
                WHERE AssigneeId = :currentUserId
                AND PermissionSet.IsOwnedByProfile = false
            ];
            
            for (PermissionSetAssignment psa : userPermSets) {
                ColumnConfiguration permSetConfig = getExistingConfiguration('PermissionSet', psa.PermissionSetId);
                if (permSetConfig != null && !isDefaultConfiguration(permSetConfig)) {
                    System.debug('Found permission set configuration: ' + psa.PermissionSetId);
                    return permSetConfig;
                }
            }
            
            System.debug('No specific configuration found, returning default (all visible)');
            
            // Return default configuration (all columns visible)
            return new ColumnConfiguration(
                'Default',
                currentUserId,
                'Default',
                true, true, true, true, true, true, true, true
            );
            
        } catch (Exception e) {
            System.debug('Error getting current user configuration: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            
            // Return default configuration on error
            return new ColumnConfiguration(
                'Default',
                UserInfo.getUserId(),
                'Default',
                true, true, true, true, true, true, true, true
            );
        }
    }
    
    // Helper method to check if a configuration is default (all true)
    private static Boolean isDefaultConfiguration(ColumnConfiguration config) {
        return config.showFieldName && config.showFieldType && config.showDescription && 
               config.showHelpText && config.showSensitivity && config.showFieldUsage && 
               config.showDataOwner && config.showComplianceCategorizaton;
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isSystemAdministrator() {
        try {
            // Get current user's profile
            User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            
            // Debug information
            System.debug('Current Profile Name: ' + currentUser.Profile.Name);
            
            // Only allow System Administrator profile
            Boolean isAdmin = currentUser.Profile.Name == 'System Administrator';
            
            System.debug('Is System Administrator: ' + isAdmin);
            return isAdmin;
            
        } catch (Exception e) {
            System.debug('Error checking system admin status: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * Wrapper class for column configuration
     */
    public class ColumnConfiguration {
        @AuraEnabled public String targetType;
        @AuraEnabled public String targetId;
        @AuraEnabled public String targetName;
        @AuraEnabled public Boolean showFieldName;
        @AuraEnabled public Boolean showFieldType;
        @AuraEnabled public Boolean showDescription;
        @AuraEnabled public Boolean showHelpText;
        @AuraEnabled public Boolean showSensitivity;
        @AuraEnabled public Boolean showFieldUsage;
        @AuraEnabled public Boolean showDataOwner;
        @AuraEnabled public Boolean showComplianceCategorizaton;
        
        public ColumnConfiguration() {}
        
        public ColumnConfiguration(String targetType, String targetId, String targetName,
                                 Boolean showFieldName, Boolean showFieldType, Boolean showDescription,
                                 Boolean showHelpText, Boolean showSensitivity, Boolean showFieldUsage,
                                 Boolean showDataOwner, Boolean showComplianceCategorizaton) {
            this.targetType = targetType;
            this.targetId = targetId;
            this.targetName = targetName;
            this.showFieldName = showFieldName;
            this.showFieldType = showFieldType;
            this.showDescription = showDescription;
            this.showHelpText = showHelpText;
            this.showSensitivity = showSensitivity;
            this.showFieldUsage = showFieldUsage;
            this.showDataOwner = showDataOwner;
            this.showComplianceCategorizaton = showComplianceCategorizaton;
        }
    }
}