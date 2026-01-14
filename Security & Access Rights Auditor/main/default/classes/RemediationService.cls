public with sharing class RemediationService {
    private static final Map<String,Schema.SObjectType> PERMISSION_TYPES = new Map<String,Schema.SObjectType>{
        'PermissionSet' => PermissionSetAssignment.SObjectType,
        'SystemPermission' => PermissionSet.SObjectType
    };

    private static final Map<Id, List<PermissionSetAssignment>> undoPermissionSets = new Map<Id, List<PermissionSetAssignment>>();
    private static final Map<Id, Id> originalProfiles = new Map<Id, Id>();

    private static final String UNDO_TYPE_PERMISSIONS = 'PermissionSet';
    private static final String UNDO_TYPE_PROFILE = 'Profile';

    @AuraEnabled(cacheable=false)
    public static void revokePermission(String userId, String permissionType) {
        if(String.isBlank(userId)) {
            throw new RemediationException('Invalid user Id');
        }
        validatePermissionType(permissionType);
        
        if(permissionType == 'PermissionSet') {
            removePermissionSets(userId);
        } else if(permissionType == 'SystemPermission') {
            removeSystemPermissions(userId);
        }
    }

    @AuraEnabled(cacheable=false)
    public static void removeRole(String userId) {
        if(String.isBlank(userId)) {
            throw new RemediationException('Invalid user Id');
        }
        if(!Schema.SObjectType.User.fields.UserRoleId.isAccessible() ||
           !Schema.SObjectType.User.fields.UserRoleId.isUpdateable()) {
            throw new RemediationException('Insufficient access to User Role field');
        }

        List<User> users = [SELECT UserRoleId FROM User WHERE Id = :userId LIMIT 1];
        if(!users.isEmpty() && users[0].UserRoleId != null) {
            users[0].UserRoleId = null;
            update Security.stripInaccessible(
                AccessType.UPDATABLE, 
                users,
                true
            ).getRecords();
        }
    }

    @AuraEnabled(cacheable=false)
    public static void revokePermissionSets(String userId) {
        if(String.isBlank(userId)) {
            throw new RemediationException('Invalid user Id');
        }
        if(!Schema.SObjectType.PermissionSetAssignment.isAccessible() ||
           !Schema.SObjectType.PermissionSetAssignment.isDeletable()) {
            throw new RemediationException('Insufficient access to PermissionSetAssignment');
        }

        List<PermissionSetAssignment> assignments = [
            SELECT Id, AssigneeId, PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId 
            AND PermissionSet.IsOwnedByProfile = false
        ];
        
        if(!assignments.isEmpty()) {
            // Try to save undo state but continue even if it fails
            try {
                saveUndoState(userId, UNDO_TYPE_PERMISSIONS, JSON.serialize(assignments));
            } catch(Exception e) {
                System.debug(LoggingLevel.WARN, 'Could not save undo state: ' + e.getMessage());
                // Continue with the operation even if undo state fails
            }
            
            // Process setup object in separate transaction
            deletePermissionSetAssignments(JSON.serialize(assignments));
        }
    }

    @AuraEnabled(cacheable=false)
    public static void revokeSelectedPermissionSets(String userId, List<String> permissionSetNames) {
        if(String.isBlank(userId)) {
            throw new RemediationException('Invalid user Id');
        }
        
        if(permissionSetNames != null) {
            for(String psName : permissionSetNames) {
                if(String.isBlank(psName)) {
                    throw new RemediationException('Invalid permission set name');
                }
            }
        }

        if(!Schema.SObjectType.PermissionSetAssignment.isAccessible() ||
           !Schema.SObjectType.PermissionSetAssignment.isDeletable()) {
            throw new RemediationException('Insufficient access to PermissionSetAssignment');
        }
        
        if(permissionSetNames == null || permissionSetNames.isEmpty()) {
            // If no specific permission sets are provided, revoke all
            revokePermissionSets(userId);
            return;
        }
        
        List<PermissionSetAssignment> assignments = [
            SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId 
            AND PermissionSet.Name IN :permissionSetNames
            AND PermissionSet.IsOwnedByProfile = false
        ];
        
        if(!assignments.isEmpty()) {
            // Try to save undo state but continue even if it fails
            try {
                saveUndoState(userId, UNDO_TYPE_PERMISSIONS, JSON.serialize(assignments));
            } catch(Exception e) {
                System.debug(LoggingLevel.WARN, 'Could not save undo state: ' + e.getMessage());
                // Continue with the operation even if undo state fails
            }
            
            // Process setup object in separate transaction
            deletePermissionSetAssignments(JSON.serialize(assignments));
        }
    }

    @future
    private static void deletePermissionSetAssignments(String assignmentsJSON) {
        try {
            if(!Schema.SObjectType.PermissionSetAssignment.isDeletable()) {
                throw new RemediationException('Insufficient permissions to delete PermissionSetAssignment');
            }

            List<PermissionSetAssignment> assignments = 
                (List<PermissionSetAssignment>)JSON.deserialize(
                    assignmentsJSON, 
                    List<PermissionSetAssignment>.class
                );
            
            delete Security.stripInaccessible(
                AccessType.UPDATABLE, 
                assignments,
                true
            ).getRecords();
        } catch(JSONException e) {
            System.debug(LoggingLevel.ERROR, 'JSON deserialization failed: ' + e.getMessage());
            throw new RemediationException('Failed to process permission set assignments: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false) 
    public static void resetSystemPermissions(String userId) {
        removeSystemPermissions(userId);
    }

    private static void removePermissionSets(String userId) {
        List<PermissionSetAssignment> assignments = [
            SELECT Id, AssigneeId, PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId = :userId 
            AND PermissionSet.IsOwnedByProfile = false
        ];
        
        if(!assignments.isEmpty()) {
            undoPermissionSets.put(userId, assignments.deepClone(true));
            delete Security.stripInaccessible(
                AccessType.UPDATABLE, 
                assignments,
                true
            ).getRecords();
        }
    } 

    private static void removeSystemPermissions(String userId) {
        if(UserInfo.getUserId() == userId) {
            throw new RemediationException('Cannot reset permissions for current user');
        }

        User u = [SELECT Id, ProfileId FROM User WHERE Id = :userId LIMIT 1];
        originalProfiles.put(userId, u.ProfileId);
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        u.ProfileId = p.Id;
        
        
        try {
            update Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<User>{u},
                true
            ).getRecords();
        } catch(DmlException e) {
            throw new RemediationException(
                'Profile update failed: ' + e.getMessage() + 
                ' - Users cannot modify their own profile'
            );
        }


    }

    @AuraEnabled(cacheable=false)
    public static void undoRevokePermissionSets(String userId) {
        try {
            List<PermissionSetUndoo__c> undoRecords = [
                    SELECT Id, Data__c 
                FROM PermissionSetUndoo__c 
                WHERE UserId__c = :userId 
                AND Type__c = :UNDO_TYPE_PERMISSIONS
                AND IsProcessed__c = false
            ];
            
            if(undoRecords.isEmpty()) {
                throw new RemediationException('No undo records found');
            }

            List<PermissionSetAssignment> assignments = (List<PermissionSetAssignment>)
                JSON.deserializeStrict(undoRecords[0].Data__c, List<PermissionSetAssignment>.class);
            
            // Clear IDs and process in separate transaction
            processUndoAssignments(JSON.serialize(assignments), undoRecords[0].Id);
            
        } catch(Exception e) {
            throw new RemediationException('Undo failed: ' + e.getMessage());
        }
    }

    @future 
    private static void processUndoAssignments(String assignmentsJSON, String undoRecordId) {
        // Process setup object first
        List<PermissionSetAssignment> assignments = 
            (List<PermissionSetAssignment>)JSON.deserialize(
                assignmentsJSON, 
                List<PermissionSetAssignment>.class
            );
        
        for(PermissionSetAssignment psa : assignments) {
            psa.Id = null;
        }
        
        insert Security.stripInaccessible(
            AccessType.CREATABLE,
            assignments,
            true
        ).getRecords();

        // Enqueue custom object deletion in queueable
        try {
            System.enqueueJob(new UndoRecordCleanupQueueable(undoRecordId));
        } catch(Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not enqueue cleanup job: ' + e.getMessage());
            // Continue even if cleanup fails
        }
    }

    @AuraEnabled(cacheable=false)
    public static void undoResetSystemPermissions(String userId) {
        if(originalProfiles.containsKey(userId)) {
            User u = new User(Id = userId, ProfileId = originalProfiles.get(userId));
            update Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<User>{u},
                true
            ).getRecords();
            originalProfiles.remove(userId);
        }
    }

    private static void validatePermissionType(String type) {
        if(!PERMISSION_TYPES.containsKey(type)) {
            throw new RemediationException('Invalid permission type: ' + type);
        }
        if(!PERMISSION_TYPES.get(type).getDescribe().isDeletable()) {
            throw new RemediationException('Insufficient permissions to delete ' + type);
        }
    }

    private static void saveUndoState(String userId, String type, String data) {
        try {
            // Check if the custom object exists and if the user has access
            Boolean hasAccess = true;
            
            try {
                Schema.DescribeSObjectResult describeResult = Schema.SObjectType.PermissionSetUndoo__c;
                hasAccess = describeResult != null && 
                            describeResult.isCreateable() &&
                            Schema.SObjectType.PermissionSetUndoo__c.fields.UserId__c.isCreateable() &&
                            Schema.SObjectType.PermissionSetUndoo__c.fields.Type__c.isCreateable() &&
                            Schema.SObjectType.PermissionSetUndoo__c.fields.Data__c.isCreateable() &&
                            Schema.SObjectType.PermissionSetUndoo__c.fields.IsProcessed__c.isCreateable();
            } catch(Exception e) {
                // Object doesn't exist or user can't see it
                hasAccess = false;
                System.debug(LoggingLevel.WARN, 'PermissionSetUndoo__c object is not accessible: ' + e.getMessage());
            }
            
            if(!hasAccess) {
                System.debug(LoggingLevel.WARN, 'Skipping undo state creation due to insufficient permissions');
                return; // Skip undo state creation but allow the operation to continue
            }

            PermissionSetUndoo__c undoRecord = new PermissionSetUndoo__c(
                UserId__c = userId,
                Type__c = type,
                Data__c = data,
                IsProcessed__c = false
            );
            
            insert Security.stripInaccessible(
                AccessType.CREATABLE, 
                new List<PermissionSetUndoo__c>{undoRecord},
                true
            ).getRecords();
        } catch(Exception e) {
            // Log the error but don't throw - we want the operation to continue even if undo state fails
            System.debug(LoggingLevel.ERROR, 'Error saving undo state: ' + e.getMessage());
        }
    }

    public class RemediationException extends Exception {}

    public with sharing  class UndoRecordCleanupQueueable implements Queueable {
        private String undoRecordId;
        
        public UndoRecordCleanupQueueable(String undoRecordId) {
            this.undoRecordId = undoRecordId;
        }
        
        public void execute(QueueableContext context) {
            try {
                if(!Schema.SObjectType.PermissionSetUndoo__c.isDeletable()) {
                    System.debug(LoggingLevel.WARN, 'Insufficient permissions to delete undo records');
                    return;
                }
                List<PermissionSetUndoo__c> recordsToDelete = [SELECT Id FROM PermissionSetUndoo__c WHERE Id = :this.undoRecordId];
                delete Security.stripInaccessible(
                    AccessType.READABLE, 
                    recordsToDelete,
                    true
                ).getRecords();
            } catch(Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error cleaning up undo record: ' + e.getMessage());
            }
        }
    }
}