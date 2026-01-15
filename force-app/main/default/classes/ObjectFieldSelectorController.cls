public with sharing class ObjectFieldSelectorController {
    /**
     * Feature management access check (mirrors ObjectAccess.getPaidFeatureAccess)
     * Returns true to preserve current behavior; add FeatureManagement check when ready.
     */
    @AuraEnabled(cacheable=true)
    public static Boolean getPaidFeatureAccess() {
        try {
            // Uncomment and adjust parameter when Feature Management is configured
            // return FeatureManagement.checkPackageBooleanValue('ObjectAccessPaid');

            // Preserve existing behavior: allow access by default
            return true;
        } catch (System.NoDataFoundException e) {
            return false;
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Get available object types
     * @return List<String> List of object type options
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getObjectTypes() {
        List<String> objectTypes = new List<String>();
        objectTypes.add('Organization');
        objectTypes.add('Managed');
        return objectTypes;
    }
    
    /**
     * Get objects based on the selected object type
     * @param objectType The type of objects to retrieve ('Organization' or 'Managed')
     * @return List<ObjectInfo> List of objects with their metadata
     */
    @AuraEnabled(cacheable=true)
    public static List<ObjectInfo> getObjectsByType(String objectType) {
        List<ObjectInfo> objectList = new List<ObjectInfo>();
        
        try {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            
            for (String objectName : globalDescribe.keySet()) {
                Schema.SObjectType sObjectType = globalDescribe.get(objectName);
                Schema.DescribeSObjectResult describe = sObjectType.getDescribe();
                
                // Check if user has access to this object
                if (!describe.isAccessible()) {
                    continue; // Skip objects user doesn't have access to
                }
                
                // Filter based on object type and user permissions
                if (objectType == 'Organization') {
                    // Organization objects: Standard and Custom objects (not from managed packages)
                    if (describe.isCustom() && describe.getName().contains('__c') && 
                        describe.getName().countMatches('__') == 1) {
                        // Custom objects
                        objectList.add(new ObjectInfo(describe.getName(), describe.getLabel()));
                    } else if (!describe.isCustom() && !describe.getName().contains('__')) {
                        // Standard objects
                        objectList.add(new ObjectInfo(describe.getName(), describe.getLabel()));
                    }
                } else if (objectType == 'Managed') {
                    // Managed package objects: Objects with namespace (contains __ but not ending with __c)
                    if (describe.isCustom() && describe.getName().contains('__') && 
                        describe.getName().countMatches('__') > 1) {
                        objectList.add(new ObjectInfo(describe.getName(), describe.getLabel()));
                    }
                }
            }
            
            // Sort objects alphabetically by label
            objectList.sort();
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving objects: ' + e.getMessage());
        }
        
        return objectList;
    }
    
    /**
     * Get fields for a specific object
     * @param objectName The API name of the object
     * @return List<FieldInfo> List of fields with their metadata
     */
    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getObjectFields(String objectName) {
        List<FieldInfo> fieldInfoList = new List<FieldInfo>();
        
        try {
            // First check if user has access to the object
            Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
            if (sObjectType == null) {
                throw new AuraHandledException('Object not found: ' + objectName);
            }
            
            Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
            if (!objectDescribe.isAccessible()) {
                throw new AuraHandledException('You do not have permission to access this object: ' + objectName);
            }
            
            // Query EntityParticle for comprehensive field metadata
            List<EntityParticle> fieldsList = [
                SELECT DataType, FieldDefinition.EntityDefinitionId, NamespacePrefix, 
                       FieldDefinition.SecurityClassification, FieldDefinition.QualifiedApiName, 
                       FieldDefinition.ComplianceGroup, inlineHelpText, FieldDefinition.Description, 
                       FieldDefinition.BusinessStatus, FieldDefinition.BusinessOwnerId, Label, IsUpdatable
                FROM EntityParticle
                WHERE EntityDefinition.QualifiedApiName = :objectName AND DataType != 'percent'
                ORDER BY Label ASC
                LIMIT 2500
            ];

            // Get field describe information for permission checks
            Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
            
            for (EntityParticle field : fieldsList) {
                // Check field-level security - only include fields user can access
                Schema.SObjectField sObjectField = fieldMap.get(field.FieldDefinition.QualifiedApiName);
                if (sObjectField != null) {
                    Schema.DescribeFieldResult fieldDescribe = sObjectField.getDescribe();
                    
                    // Skip fields user doesn't have permission to read
                    if (!fieldDescribe.isAccessible()) {
                        System.debug('User does not have access to field: ' + field.FieldDefinition.QualifiedApiName);
                        continue;
                    }
                }
                
                FieldInfo fieldInfo = new FieldInfo();
                fieldInfo.name = field.FieldDefinition.QualifiedApiName;
                fieldInfo.label = field.Label;
                fieldInfo.type = field.DataType;
                fieldInfo.inlineHelpText = field.inlineHelpText;
                fieldInfo.description = field.FieldDefinition.Description;
                fieldInfo.isRequired = false; // EntityParticle doesn't have required info
                
                // Set BusinessStatus (Field Usage) - Use standard Salesforce BusinessStatus values directly
                if (field.FieldDefinition.BusinessStatus != null) {
                    fieldInfo.isActive = field.FieldDefinition.BusinessStatus;
                } else {
                    fieldInfo.isActive = null; // No default value
                }
                
                // Set Data Owner
                if (field.FieldDefinition.BusinessOwnerId != null) {
                    try {
                        User owner = [SELECT Name FROM User WHERE Id = :field.FieldDefinition.BusinessOwnerId LIMIT 1];
                        fieldInfo.dataOwner = owner.Name;
                    } catch (Exception e) {
                        fieldInfo.dataOwner = null; // No default value
                    }
                } else {
                    fieldInfo.dataOwner = null; // No default value
                }
                
                // Set Security Classification (Data Sensitivity Level)
                if (field.FieldDefinition.SecurityClassification != null) {
                    fieldInfo.dataSensitivityLevel = field.FieldDefinition.SecurityClassification;
                } else {
                    fieldInfo.dataSensitivityLevel = null; // No default value
                }
                
                // Set Compliance Groups
                if (field.FieldDefinition.ComplianceGroup != null && 
                    field.FieldDefinition.ComplianceGroup.trim() != '') {
                    fieldInfo.complianceCategorization = field.FieldDefinition.ComplianceGroup.split(';');
                } else {
                    fieldInfo.complianceCategorization = new List<String>();
                }
                
                fieldInfoList.add(fieldInfo);
                
                System.debug('Added field: ' + fieldInfo.name + ' (accessible to user)');
            }
            
            // Sort fields alphabetically
            fieldInfoList.sort();
            
            System.debug('Total accessible fields returned: ' + fieldInfoList.size());
            
        } catch (Exception e) {
            System.debug('Error in getObjectFields: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving object fields: ' + e.getMessage());
        }
        
        return fieldInfoList;
    }
    
    /**
     * Inner class to represent object information
     */
    public class ObjectInfo implements Comparable {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        
        public ObjectInfo(String name, String label) {
            this.name = name;
            this.label = label;
        }
        
        public Integer compareTo(Object compareTo) {
            ObjectInfo compareToObj = (ObjectInfo) compareTo;
            if (label == compareToObj.label) return 0;
            if (label > compareToObj.label) return 1;
            return -1;
        }
    }

    /**
     * Inner class to represent field information
     */
    public class FieldInfo implements Comparable {
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public String type;
        @AuraEnabled public String inlineHelpText;
        @AuraEnabled public String description;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public String isActive; // Changed from Boolean to String to match BusinessStatus
        @AuraEnabled public String dataOwner;
        @AuraEnabled public String dataSensitivityLevel;
        @AuraEnabled public List<String> complianceCategorization;
        
        public Integer compareTo(Object compareTo) {
            FieldInfo compareToField = (FieldInfo) compareTo;
            if (label == compareToField.label) return 0;
            if (label > compareToField.label) return 1;
            return -1;
        }
    }
    
}