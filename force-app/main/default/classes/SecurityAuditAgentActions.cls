/**
 * @description Invocable actions for Security Audit Agent
 * Wraps existing controllers to make them callable by Agentforce
 */
public with sharing class SecurityAuditAgentActions {
    
    /**
     * Get users with a specific system permission
     */
    @InvocableMethod(label='Find Users with System Permission' 
                     description='Returns list of users who have a specific system permission like ModifyAllData, ManageUsers, etc.'
                     category='Security Audit')
    public static List<PermissionResult> getUsersWithPermission(List<PermissionRequest> requests) {
        List<PermissionResult> results = new List<PermissionResult>();
        
        if (requests == null || requests.isEmpty()) {
            return results;
        }
        
        PermissionRequest request = requests[0];
        PermissionResult result = new PermissionResult();
        
        try {
            // Get all system permissions from PermissionsManagerController
            List<PermissionsManagerController.SystemPermissionWrapper> allPerms = 
                PermissionsManagerController.getSystemPermissions();
            
            // Find users with the requested permission
            List<String> usersWithPermission = new List<String>();
            
            for (PermissionsManagerController.SystemPermissionWrapper perm : allPerms) {
                if (perm.name.equalsIgnoreCase(request.permissionName) || 
                    perm.label.containsIgnoreCase(request.permissionName)) {
                    
                    // Get users who have this permission
                    Set<Id> userIds = getUserIdsWithPermission(perm.name);
                    
                    if (!userIds.isEmpty()) {
                        Map<Id, User> users = new Map<Id, User>([
                            SELECT Id, Name, Email, Profile.Name 
                            FROM User 
                            WHERE Id IN :userIds AND IsActive = true
                            LIMIT 100
                        ]);
                        
                        for (User u : users.values()) {
                            usersWithPermission.add(u.Name + ' (' + u.Email + ') - Profile: ' + u.Profile.Name);
                        }
                    }
                    break;
                }
            }
            
            result.foundUsers = String.join(usersWithPermission, '\n');
            result.userCount = usersWithPermission.size();
            result.permissionName = request.permissionName;
            
            if (usersWithPermission.isEmpty()) {
                result.message = 'No active users found with permission: ' + request.permissionName;
            } else {
                result.message = 'Found ' + usersWithPermission.size() + ' users with ' + request.permissionName + ' permission';
            }
            
        } catch (Exception e) {
            result.message = 'Error: ' + e.getMessage();
        }
        
        results.add(result);
        return results;
    }
    
    /**
     * Helper method to get user IDs with a specific permission
     */
    private static Set<Id> getUserIdsWithPermission(String permissionApiName) {
        Set<Id> userIds = new Set<Id>();
        
        // Query PermissionSetAssignment for users with this permission
        for (PermissionSetAssignment psa : [
            SELECT AssigneeId 
            FROM PermissionSetAssignment 
            WHERE PermissionSet.PermissionsModifyAllData = true
            OR PermissionSet.PermissionsManageUsers = true
            OR PermissionSet.PermissionsApiEnabled = true
            LIMIT 1000
        ]) {
            userIds.add(psa.AssigneeId);
        }
        
        return userIds;
    }
    
    // Input wrapper
    public class PermissionRequest {
        @InvocableVariable(label='Permission Name' description='System permission to search for (e.g., ModifyAllData, ManageUsers, ApiEnabled)' required=true)
        public String permissionName;
    }
    
    // Output wrapper
    public class PermissionResult {
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Users Found')
        public String foundUsers;
        
        @InvocableVariable(label='User Count')
        public Integer userCount;
        
        @InvocableVariable(label='Permission Name')
        public String permissionName;
    }
}