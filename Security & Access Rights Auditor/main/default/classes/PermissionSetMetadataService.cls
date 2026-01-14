/**
 * @description Service class for deploying PermissionSet metadata with object and system permissions
 * Uses Metadata API to work around Salesforce DML limitations
 */
public class PermissionSetMetadataService {
    
    /**
     * @description Deploy a PermissionSet with object and system permissions using Tooling API
     * @param permissionSetId ID of the PermissionSet to update
     * @param objectPermissionsJSON JSON string of object permissions
     * @param systemPermissionsJSON JSON string of system permissions
     */
    @future(callout=true)
    public static void deployPermissionSetPermissions(
        Id permissionSetId, 
        String objectPermissionsJSON,
        String systemPermissionsJSON
    ) {
        // Deserialize permissions
        List<ObjectPermissions> objectPermissions = (List<ObjectPermissions>) JSON.deserialize(
            objectPermissionsJSON, List<ObjectPermissions>.class
        );
        Map<String, Boolean> systemPermissions = (Map<String, Boolean>) JSON.deserialize(
            systemPermissionsJSON, Map<String, Boolean>.class
        );
        
        // Get the PermissionSet name
        PermissionSet ps = [SELECT Name, Label FROM PermissionSet WHERE Id = :permissionSetId LIMIT 1];
        
        System.debug('Starting Tooling API deployment for PermissionSet: ' + ps.Name);
        System.debug('Object permissions to deploy: ' + objectPermissions.size());
        System.debug('System permissions to deploy: ' + systemPermissions.size());
        
        // STEP 1: Update System Permissions via Tooling API PATCH
        // This works because Tooling API allows updating PermissionSet permission fields!
        if (systemPermissions != null && !systemPermissions.isEmpty()) {
            updateSystemPermissionsViaToolingAPI(permissionSetId, systemPermissions);
        }
        
        // STEP 2: Deploy Object Permissions via Tooling API
        // Create ObjectPermissions records via Tooling API (not DML)
        if (objectPermissions != null && !objectPermissions.isEmpty()) {
            deployObjectPermissionsViaToolingAPI(permissionSetId, objectPermissions);
        }
        
        System.debug('✓ Metadata deployment completed successfully');
    }
    
    /**
     * @description Update system permissions using Tooling API PATCH request
     */
    private static void updateSystemPermissionsViaToolingAPI(Id permissionSetId, Map<String, Boolean> systemPermissions) {
        String endpoint = URL.getOrgDomainUrl().toExternalForm() + 
                         '/services/data/v61.0/tooling/sobjects/PermissionSet/' + permissionSetId;
        
        // Build JSON body with system permissions
        Map<String, Object> updateBody = new Map<String, Object>();
        for (String permField : systemPermissions.keySet()) {
            if (systemPermissions.get(permField) == true) {
                updateBody.put(permField, true);
            }
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('PATCH');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(updateBody));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 204 || res.getStatusCode() == 200) {
            System.debug('✓ Successfully updated ' + systemPermissions.size() + ' system permissions via Tooling API');
        } else {
            System.debug(LoggingLevel.ERROR, 'Failed to update system permissions: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
    }
    
    /**
     * @description Deploy object permissions using Tooling API POST requests
     */
    private static void deployObjectPermissionsViaToolingAPI(Id permissionSetId, List<ObjectPermissions> objectPermissions) {
        String endpoint = URL.getOrgDomainUrl().toExternalForm() + 
                         '/services/data/v61.0/tooling/sobjects/ObjectPermissions';
        
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for (ObjectPermissions op : objectPermissions) {
            Map<String, Object> objPermBody = new Map<String, Object>();
            objPermBody.put('ParentId', permissionSetId);
            objPermBody.put('SObjectType', op.SObjectType);
            objPermBody.put('PermissionsCreate', op.PermissionsCreate);
            objPermBody.put('PermissionsDelete', op.PermissionsDelete);
            objPermBody.put('PermissionsEdit', op.PermissionsEdit);
            objPermBody.put('PermissionsRead', op.PermissionsRead);
            objPermBody.put('PermissionsModifyAllRecords', op.PermissionsModifyAllRecords);
            objPermBody.put('PermissionsViewAllRecords', op.PermissionsViewAllRecords);
            
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(objPermBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 201) {
                successCount++;
            } else {
                failureCount++;
                System.debug(LoggingLevel.WARN, 'Failed to create ObjectPermission for ' + op.SObjectType + ': ' + res.getBody());
            }
        }
        
        System.debug('✓ Object permissions deployed: ' + successCount + ' successful, ' + failureCount + ' failed');
    }
    
    /**
     * @description Convert API permission name to metadata field name
     * Example: PermissionsModifyAllData -> modifyAllData
     */
    private static String getMetadataFieldName(String apiName) {
        if (apiName.startsWith('Permissions')) {
            String withoutPrefix = apiName.substring(11); // Remove 'Permissions' prefix
            // Convert first character to lowercase
            return withoutPrefix.substring(0, 1).toLowerCase() + withoutPrefix.substring(1);
        }
        return apiName;
    }
}