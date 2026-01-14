/**
 * @description Helper class for managing Custom Metadata Types via Metadata API
 * Allows runtime creation and update of Privileged System Permission records
 */
public class PrivilegedPermissionMetadataService {
    
    /**
     * @description Create or update a privileged permission metadata record
     * @param permissionApiName API name of the permission
     * @param permissionLabel Label of the permission
     * @param description Description of the permission
     * @param isPrivileged Whether this is a privileged permission
     * @return String containing the deployment ID
     */
    public static String upsertPrivilegedPermission(String permissionApiName, String permissionLabel, 
                                                     String description, Boolean isPrivileged) {
        
        // Create metadata for deployment
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'SA_Audit__Privileged_System_Permission__mdt.' + sanitizeApiName(permissionApiName);
        customMetadata.label = permissionLabel.left(40); // Max label length
        
        // Add field values
        Metadata.CustomMetadataValue apiNameField = new Metadata.CustomMetadataValue();
        apiNameField.field = 'SA_Audit__Permission_API_Name__c';
        apiNameField.value = permissionApiName;
        
        Metadata.CustomMetadataValue labelField = new Metadata.CustomMetadataValue();
        labelField.field = 'SA_Audit__Permission_Label__c';
        labelField.value = permissionLabel;
        
        Metadata.CustomMetadataValue descField = new Metadata.CustomMetadataValue();
        descField.field = 'SA_Audit__Description__c';
        descField.value = description;
        
        Metadata.CustomMetadataValue privField = new Metadata.CustomMetadataValue();
        privField.field = 'SA_Audit__Is_Privileged__c';
        privField.value = isPrivileged;
        
        customMetadata.values = new List<Metadata.CustomMetadataValue>{
            apiNameField, labelField, descField, privField
        };
        
        // Deploy the metadata
        Metadata.DeployContainer container = new Metadata.DeployContainer();
        container.addMetadata(customMetadata);
        
        // Enqueue deployment
        Id deploymentId = Metadata.Operations.enqueueDeployment(container, null);
        
        return deploymentId;
    }
    
    /**
     * @description Delete a privileged permission metadata record
     * @param permissionApiName API name of the permission to delete
     * @return String containing the deployment ID
     */
    public static String deletePrivilegedPermission(String permissionApiName) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
        customMetadata.fullName = 'SA_Audit__Privileged_System_Permission__mdt.' + sanitizeApiName(permissionApiName);
        
        Metadata.DeployContainer container = new Metadata.DeployContainer();
        // Note: Deletion requires different approach - typically done via destructiveChanges.xml
        
        return null;
    }
    
    /**
     * @description Sanitize API name for custom metadata record name
     * @param apiName Original API name
     * @return Sanitized name suitable for metadata record
     */
    private static String sanitizeApiName(String apiName) {
        // Remove 'Permissions' prefix and convert to valid metadata name
        String sanitized = apiName.replace('Permissions', '');
        sanitized = sanitized.replaceAll('[^a-zA-Z0-9_]', '_');
        return sanitized;
    }
    
    /**
     * @description Callback handler for metadata deployments
     */
    public class DeployCallback implements Metadata.DeployCallback {
        
        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug('Deployment succeeded: ' + result.id);
            } else {
                System.debug('Deployment failed: ' + result.id);
                if (result.details != null && result.details.componentFailures != null) {
                    for (Metadata.DeployMessage msg : result.details.componentFailures) {
                        System.debug('Error: ' + msg.fullName + ' - ' + msg.problem);
                    }
                }
            }
        }
    }
}