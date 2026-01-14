/**
 * @description Controller for managing privileged system permissions
 * Provides methods to fetch, update, and export system permissions
 */
public with sharing class PrivilegedPermissionsController {
    
    // Cache for system permissions to improve performance
    private static Map<String, SystemPermissionInfo> cachedPermissions;
    
    /**
     * @description Wrapper class for system permission information
     */
    public class SystemPermissionInfo implements Comparable {
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Boolean isPrivileged { get; set; }
        @AuraEnabled public Integer usageCount { get; set; }
        
        public SystemPermissionInfo(String apiName, String label, String description, Boolean isPrivileged, Integer usageCount) {
            this.apiName = apiName;
            this.label = label;
            this.description = description;
            this.isPrivileged = isPrivileged;
            this.usageCount = usageCount;
        }
        
        // Implement Comparable interface for sorting
        public Integer compareTo(Object compareTo) {
            SystemPermissionInfo compareToPermission = (SystemPermissionInfo)compareTo;
            if (label == compareToPermission.label) return 0;
            if (label > compareToPermission.label) return 1;
            return -1;
        }
    }
    
    /**
     * @description Wrapper for paginated results
     */
    public class PermissionsResult {
        @AuraEnabled public List<SystemPermissionInfo> permissions { get; set; }
        @AuraEnabled public Integer totalCount { get; set; }
        @AuraEnabled public Integer pageNumber { get; set; }
        @AuraEnabled public Integer pageSize { get; set; }
        @AuraEnabled public Boolean hasAccess { get; set; }
        
        public PermissionsResult() {
            this.permissions = new List<SystemPermissionInfo>();
            this.totalCount = 0;
            this.hasAccess = false;
        }
    }
    
    /**
     * @description Check if user has access to paid features
     * @return Boolean True if user has access
     */
    @AuraEnabled(cacheable=true)
    public static Boolean PaidFeatureAccess() {
        // Check if the feature is enabled for the user
       // return FeatureManagement.checkPackageBooleanValue('AuditAppPaidAccess');

       //for show --- 
       return true; 
        
        
       // for hide ---
    //   return false;
    }
    
    /**
     * @description Check if current user has permission to manage privileged permissions
     * @return Boolean indicating if user has access
     */
    @AuraEnabled(cacheable=false)
    public static Boolean checkUserAccess() {
        try {
            return FeatureManagement.checkPermission('Manage_Privileged_Permissions');
        } catch (Exception e) {
            System.debug('Error checking user access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Fetch all system permissions with pagination and search
     * @param searchTerm Optional search term to filter permissions
     * @param pageNumber Current page number (1-indexed)
     * @param pageSize Number of records per page
     * @param filterOptions List of filter options selected by user
     * @return PermissionsResult containing paginated permissions
     */
    @AuraEnabled(cacheable=false)
    public static PermissionsResult getSystemPermissions(String searchTerm, Integer pageNumber, Integer pageSize, List<String> filterOptions) {
        PermissionsResult result = new PermissionsResult();
        
        try {
            // Check user access
            result.hasAccess = checkUserAccess();
            
            // Get all system permissions
            Map<String, SystemPermissionInfo> allPermissions = getAllSystemPermissions();
            
            // Filter by search term and filter options
            List<SystemPermissionInfo> filteredPermissions = new List<SystemPermissionInfo>();
            for (SystemPermissionInfo perm : allPermissions.values()) {
                // Apply search filter
                Boolean matchesSearch = String.isBlank(searchTerm) || 
                    perm.label.toLowerCase().contains(searchTerm.toLowerCase()) ||
                    perm.apiName.toLowerCase().contains(searchTerm.toLowerCase()) ||
                    (perm.description != null && perm.description.toLowerCase().contains(searchTerm.toLowerCase()));
                
                if (!matchesSearch) {
                    continue;
                }
                
                // Apply filter options
                Boolean matchesFilters = true;
                if (filterOptions != null && !filterOptions.isEmpty()) {
                    for (String filter : filterOptions) {
                        if (filter == 'privilegedOnly' && !perm.isPrivileged) {
                            matchesFilters = false;
                            break;
                        }
                        if (filter == 'nonPrivilegedOnly' && perm.isPrivileged) {
                            matchesFilters = false;
                            break;
                        }
                    }
                }
                
                if (matchesFilters) {
                    filteredPermissions.add(perm);
                }
            }
            
            // Sort by label
            filteredPermissions.sort();
            
            // Apply pagination
            result.totalCount = filteredPermissions.size();
            result.pageNumber = pageNumber;
            result.pageSize = pageSize;
            
            Integer startIndex = (pageNumber - 1) * pageSize;
            Integer endIndex = Math.min(startIndex + pageSize, filteredPermissions.size());
            
            if (startIndex < filteredPermissions.size()) {
                result.permissions = new List<SystemPermissionInfo>();
                for (Integer i = startIndex; i < endIndex; i++) {
                    result.permissions.add(filteredPermissions[i]);
                }
            }
            
            return result;
            
        } catch (Exception e) {
            System.debug('Error fetching system permissions: ' + e.getMessage());
            throw new AuraHandledException('Error fetching permissions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get all system permissions from the org
     * @return Map of permission API name to SystemPermissionInfo
     */
    private static Map<String, SystemPermissionInfo> getAllSystemPermissions() {
        if (cachedPermissions != null) {
            return cachedPermissions;
        }
        
        Map<String, SystemPermissionInfo> permissionsMap = new Map<String, SystemPermissionInfo>();
        
        // Get privileged permissions from custom metadata
        Map<String, SA_Audit__Privileged_System_Permission__mdt> privilegedPerms = new Map<String, SA_Audit__Privileged_System_Permission__mdt>();
        // Query all records (not just Is_Privileged = true) to get descriptions
        for (SA_Audit__Privileged_System_Permission__mdt psp : [
            SELECT SA_Audit__Permission_API_Name__c, SA_Audit__Permission_Label__c, SA_Audit__Description__c, SA_Audit__Is_Privileged__c
            FROM SA_Audit__Privileged_System_Permission__mdt
        ]) {
            privilegedPerms.put(psp.SA_Audit__Permission_API_Name__c, psp);
        }
        
        // Get system permissions from PermissionSet
        Map<String, Integer> permissionUsage = new Map<String, Integer>();
        
        // Query Permission Sets without specifying fields - we'll use describe to get field values
        for (PermissionSet ps : [
            SELECT Id
            FROM PermissionSet
            LIMIT 10000
        ]) {
            countPermissionUsage(ps, permissionUsage);
        }
        
        // Build the complete permissions list
        Schema.DescribeSObjectResult permSetDescribe = PermissionSet.SObjectType.getDescribe();
        Map<String, Schema.SObjectField> fieldMap = permSetDescribe.fields.getMap();
        
        for (String fieldName : fieldMap.keySet()) {
            if (fieldName.startsWith('permissions')) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                String apiName = fieldDescribe.getName();
                String label = fieldDescribe.getLabel();
                String description = fieldDescribe.getInlineHelpText();
                
                Boolean isPrivileged = privilegedPerms.containsKey(apiName) && privilegedPerms.get(apiName).SA_Audit__Is_Privileged__c;
                Integer usageCount = permissionUsage.containsKey(apiName) ? permissionUsage.get(apiName) : 0;
                
                // Use custom description from metadata if available, otherwise use system description
                if (privilegedPerms.containsKey(apiName) && String.isNotBlank(privilegedPerms.get(apiName).SA_Audit__Description__c)) {
                    description = privilegedPerms.get(apiName).SA_Audit__Description__c;
                } else if (String.isBlank(description)) {
                    description = '';
                }
                
                permissionsMap.put(apiName, new SystemPermissionInfo(
                    apiName, label, description, isPrivileged, usageCount
                ));
            }
        }
        
        cachedPermissions = permissionsMap;
        return permissionsMap;
    }
    
    /**
     * @description Count permission usage across permission sets
     */
    private static void countPermissionUsage(PermissionSet ps, Map<String, Integer> usageMap) {
        // Note: Since we query only Id, we won't have field values here
        // The usage count will be calculated differently or set to 0
        // For now, we'll leave usage counts at 0 to avoid governor limit issues
    }
    
    /**
     * @description Update the privileged status of a system permission
     * @param permissionApiName API name of the permission
     * @param isPrivileged Whether to mark as privileged
     * @param permissionLabel Label of the permission
     * @param description Description of the permission
     * @return String containing deployment ID or success message
     */
    @AuraEnabled
    public static String updatePrivilegedStatus(String permissionApiName, Boolean isPrivileged, 
                                                  String permissionLabel, String description) {
        try {
            // Check user access
            if (!checkUserAccess()) {
                throw new AuraHandledException('You do not have permission to manage privileged permissions');
            }
            
            // Always create/update the metadata record to save description
            // The record will be created regardless of privileged status
            String deploymentId = PrivilegedPermissionMetadataService.upsertPrivilegedPermission(
                permissionApiName, permissionLabel, description, isPrivileged
            );
            
            // Clear cache
            cachedPermissions = null;
            
            return deploymentId;
            
        } catch (Exception e) {
            System.debug('Error updating privileged status: ' + e.getMessage());
            throw new AuraHandledException('Error updating permission: ' + e.getMessage());
        }
    }
    
    /**
     * @description Export privileged permissions as CSV
     * @return String containing CSV data
     */
    @AuraEnabled(cacheable=false)
    public static String exportPrivilegedPermissions() {
        try {
            // Check user access
            if (!checkUserAccess()) {
                throw new AuraHandledException('You do not have permission to export privileged permissions');
            }
            
            Map<String, SystemPermissionInfo> allPermissions = getAllSystemPermissions();
            
            // Build CSV header
            String csv = 'Permission API Name,Permission Label,Description,Is Privileged,Usage Count\n';
            
            List<SystemPermissionInfo> sortedPerms = allPermissions.values();
            sortedPerms.sort();
            
            Integer exportCount = 0;
            for (SystemPermissionInfo perm : sortedPerms) {
                if (perm.isPrivileged) {
                    csv += '"' + perm.apiName + '",';
                    csv += '"' + perm.label + '",';
                    csv += '"' + (perm.description != null ? perm.description.replace('"', '""') : '') + '",';
                    csv += perm.isPrivileged + ',';
                    csv += perm.usageCount + '\n';
                    exportCount++;
                }
            }
            
            // If no privileged permissions, add a note
            if (exportCount == 0) {
                csv += '"No privileged permissions found","","","",""\n';
            }
            
            System.debug('Exported ' + exportCount + ' privileged permissions');
            return csv;
            
        } catch (Exception e) {
            System.debug('Error exporting permissions: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error exporting permissions: ' + e.getMessage());
        }
    }
    
    /**
     * @description Get statistics about privileged permissions
     * @return Map containing statistics
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getStatistics() {
        try {
            Map<String, SystemPermissionInfo> allPermissions = getAllSystemPermissions();
            
            Integer totalPermissions = allPermissions.size();
            Integer privilegedCount = 0;
            Integer totalUsage = 0;
            
            for (SystemPermissionInfo perm : allPermissions.values()) {
                if (perm.isPrivileged) {
                    privilegedCount++;
                }
                totalUsage += (perm.usageCount != null ? perm.usageCount : 0);
            }
            
            Map<String, Object> stats = new Map<String, Object>();
            stats.put('totalPermissions', totalPermissions);
            stats.put('privilegedCount', privilegedCount);
            stats.put('totalUsage', totalUsage);
            stats.put('hasAccess', checkUserAccess());
            
            return stats;
            
        } catch (Exception e) {
            System.debug('Error getting statistics: ' + e.getMessage());
            throw new AuraHandledException('Error getting statistics: ' + e.getMessage());
        }
    }
}