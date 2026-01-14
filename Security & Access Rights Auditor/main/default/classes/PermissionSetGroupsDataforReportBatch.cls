public with sharing class PermissionSetGroupsDataforReportBatch implements Database.Batchable<sObject>, Database.Stateful {
    private List<PermissionSetAssignment> allPermissionSetAssignments;
    private Set<String> usedPermissionSetGroups;
    private Map<String, List<String>> permissionSetGroupsMap;
    private List<PermissionSetGroup> allPermissionSetGroups;
    private Set<String> allPermissionSetGroupNames;
    private List<SA_Audit__AuditHistory__c> auditRecords;

    public PermissionSetGroupsDataforReportBatch() {
        auditRecords = new List<SA_Audit__AuditHistory__c>();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        try {
            if (Test.isRunningTest()) {
                return Database.getQueryLocator([
                    SELECT Assignee.Name, PermissionSetGroup.DeveloperName
                    FROM PermissionSetAssignment
                    WHERE PermissionSetGroup.DeveloperName != null
                    ORDER BY PermissionSetGroup.DeveloperName ASC LIMIT 10
                ]);
            } else {
                return Database.getQueryLocator([
                    SELECT Assignee.Name, PermissionSetGroup.DeveloperName
                    FROM PermissionSetAssignment
                    WHERE PermissionSetGroup.DeveloperName != null
                    ORDER BY PermissionSetGroup.DeveloperName ASC
                ]);
            }
        } catch (Exception e) {
            System.debug('Error in start method: ' + e.getMessage());
            return Database.getQueryLocator([SELECT Id FROM PermissionSetAssignment WHERE Id = NULL]); // Return an empty query locator
        }
    }

    public void execute(Database.BatchableContext context, List<PermissionSetAssignment> scope) {
        try {
            if (allPermissionSetAssignments == null) {
                allPermissionSetAssignments = new List<PermissionSetAssignment>();
                usedPermissionSetGroups = new Set<String>();
                permissionSetGroupsMap = new Map<String, List<String>>();
            }

            // Process records
            allPermissionSetAssignments.addAll(scope);

            for (PermissionSetAssignment psAssignment : scope) {
                String groupName = psAssignment.PermissionSetGroup.DeveloperName;
                usedPermissionSetGroups.add(groupName);

                if (!permissionSetGroupsMap.containsKey(groupName)) {
                    permissionSetGroupsMap.put(groupName, new List<String>());
                }
                permissionSetGroupsMap.get(groupName).add(psAssignment.Assignee.Name);
            }
        } catch (Exception e) {
            System.debug('Error in execute method: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext context) {
        try {
            allPermissionSetGroups = new List<PermissionSetGroup>();
            allPermissionSetGroupNames = new Set<String>();

            // Use a FOR loop to handle large result sets incrementally
            for (PermissionSetGroup groupf : [SELECT DeveloperName FROM PermissionSetGroup WHERE DeveloperName != NULL]) {
                allPermissionSetGroups.add(groupf);
                allPermissionSetGroupNames.add(groupf.DeveloperName);
            }

            // Generate audit records
            /*for (String groupName : allPermissionSetGroupNames) {
                SA_Audit__AuditHistory__c auditRecord = new SA_Audit__AuditHistory__c();
              if(Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPermissionSetsGroup__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPermissionSetsGroup__c.isUpdateable() && 
                 Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedPermissionSetsGroup__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedPermissionSetsGroup__c.isUpdateable() &&
                 Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__permissionSetsGroupMember__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__permissionSetsGroupMember__c.isUpdateable()
                 
                ){
                if (usedPermissionSetGroups.contains(groupName)) {
                    auditRecord.SA_Audit__UsedPermissionSetsGroup__c = groupName;
                    List<String> assigneeNames = permissionSetGroupsMap.get(groupName);
                    if (assigneeNames != null && !assigneeNames.isEmpty()) {
                        auditRecord.SA_Audit__permissionSetsGroupMember__c = String.join(assigneeNames, ', ');
                    }
                } else {
                    auditRecord.SA_Audit__UnusedPermissionSetsGroup__c = groupName;
                }
                     // Field is createable and updateable, so set the value
                    auditRecords.add(auditRecord);
                
            }

            // Check if we can upsert the audit records
            if (Schema.getGlobalDescribe().get('SA_Audit__AuditHistory__c').getDescribe().isCreateable() &&
                Schema.getGlobalDescribe().get('SA_Audit__AuditHistory__c').getDescribe().isUpdateable()) {
                try {
                    if (!auditRecords.isEmpty()) {
                        upsert auditRecords;
                    }
                } catch (DmlException e) {
                    for (Integer i = 0; i < e.getNumDml(); i++) {
                        System.debug('Error upserting audit records: ' + e.getDmlMessage(i));
                    }
                }
            } else {
                // Handle permission error if not createable or updateable
                System.debug('You do not have permission to create or update SA_Audit__AuditHistory__c records');
            }
        }*/
            // List to hold audit records for bulk DML
            List<SA_Audit__AuditHistory__c> auditRecords = new List<SA_Audit__AuditHistory__c>();
            
            // Iterate over permission set group names and populate audit records
            for (String groupName : allPermissionSetGroupNames) {
                if (Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPermissionSetsGroup__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPermissionSetsGroup__c.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedPermissionSetsGroup__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UsedPermissionSetsGroup__c.isUpdateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__permissionSetsGroupMember__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__permissionSetsGroupMember__c.isUpdateable()) {
                        
                        SA_Audit__AuditHistory__c auditRecord = new SA_Audit__AuditHistory__c();
                        
                        if (usedPermissionSetGroups.contains(groupName)) {
                            auditRecord.SA_Audit__UsedPermissionSetsGroup__c = groupName;
                            List<String> assigneeNames = permissionSetGroupsMap.get(groupName);
                            if (assigneeNames != null && !assigneeNames.isEmpty()) {
                                auditRecord.SA_Audit__permissionSetsGroupMember__c = String.join(assigneeNames, ', ');
                            }
                        } else {
                            auditRecord.SA_Audit__UnusedPermissionSetsGroup__c = groupName;
                        }
                        
                        // Add to the list of records to be upserted
                        auditRecords.add(auditRecord);
                    }
            }
            
            // Perform the DML operation outside the loop
            if (!auditRecords.isEmpty()) {
                if (Schema.getGlobalDescribe().get('SA_Audit__AuditHistory__c').getDescribe().isCreateable() &&
                    Schema.getGlobalDescribe().get('SA_Audit__AuditHistory__c').getDescribe().isUpdateable()) {
                        try {
                            upsert auditRecords;
                        } catch (DmlException e) {
                            for (Integer i = 0; i < e.getNumDml(); i++) {
                                System.debug('Error upserting audit records: ' + e.getDmlMessage(i));
                            }
                        }
                    } else {
                        // Handle permission error if not createable or updateable
                        System.debug('You do not have permission to create or update SA_Audit__AuditHistory__c records.');
                    }
            }


            Database.executeBatch(new rolesDataforReportBatch(), 50);
        } catch (Exception e) {
            System.debug('Error in finish method: ' + e.getMessage());
        }
    }
}

/*public class PermissionSetGroupsDataforReportBatch implements Database.Batchable<sObject>, Database.Stateful {
    private List<PermissionSetAssignment> allPermissionSetAssignments;
    private Set<String> usedPermissionSetGroups;
    private Map<String, List<String>> permissionSetGroupsMap;
    private List<PermissionSetGroup> allPermissionSetGroups;
    private Set<String> allPermissionSetGroupNames;
    private List<SA_Audit__AuditHistory__c> auditRecords;

    public PermissionSetGroupsDataforReportBatch() {
        auditRecords = new List<SA_Audit__AuditHistory__c>();
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
       
        
        
        try {
        if (Test.isRunningTest()){
              return Database.getQueryLocator([
            SELECT Assignee.Name, PermissionSetGroup.DeveloperName
            FROM PermissionSetAssignment
            WHERE PermissionSetGroup.DeveloperName != null
            ORDER BY PermissionSetGroup.DeveloperName ASC limit 10
        ]);
        }else{
              return Database.getQueryLocator([
            SELECT Assignee.Name, PermissionSetGroup.DeveloperName
            FROM PermissionSetAssignment
            WHERE PermissionSetGroup.DeveloperName != null
            ORDER BY PermissionSetGroup.DeveloperName ASC
        ]);
        }
        }catch (Exception e) {
            System.debug('Error in start method: ' + e.getMessage());
            return Database.getQueryLocator([SELECT Id FROM PermissionSetAssignment WHERE Id = NULL]); // Return an empty query locator
        }
    }

    public void execute(Database.BatchableContext context, List<PermissionSetAssignment> scope) {
        // Initialize variables
      try {   if (allPermissionSetAssignments == null) {
            allPermissionSetAssignments = new List<PermissionSetAssignment>();
            usedPermissionSetGroups = new Set<String>();
            permissionSetGroupsMap = new Map<String, List<String>>();
        }

        // Process records
        allPermissionSetAssignments.addAll(scope);

        for (PermissionSetAssignment psAssignment : scope) {
            String groupName = psAssignment.PermissionSetGroup.DeveloperName;
            usedPermissionSetGroups.add(groupName);

            if (!permissionSetGroupsMap.containsKey(groupName)) {
                permissionSetGroupsMap.put(groupName, new List<String>());
            }
            permissionSetGroupsMap.get(groupName).add(psAssignment.Assignee.Name);
        }}  catch (Exception e) {
            System.debug('Error in execute method: ' + e.getMessage());
        }
    }
 
public void finish(Database.BatchableContext context) {
    try {  allPermissionSetGroups = new List<PermissionSetGroup>();
    allPermissionSetGroupNames = new Set<String>();

    // Use a FOR loop to handle large result sets incrementally
    for (PermissionSetGroup groupf : [SELECT DeveloperName FROM PermissionSetGroup WHERE DeveloperName != NULL]) {
        allPermissionSetGroups.add(groupf);
        allPermissionSetGroupNames.add(groupf.DeveloperName);
    }

    // Generate audit records
    for (String groupName : allPermissionSetGroupNames) {
        SA_Audit__AuditHistory__c auditRecord = new SA_Audit__AuditHistory__c();

        if (usedPermissionSetGroups.contains(groupName)) {
            auditRecord.SA_Audit__UsedPermissionSetsGroup__c = groupName;
            List<String> assigneeNames = permissionSetGroupsMap.get(groupName);
            if (assigneeNames != null && !assigneeNames.isEmpty()) {
                auditRecord.SA_Audit__permissionSetsGroupMember__c = String.join(assigneeNames, ', ');
            }
        } else {
            auditRecord.SA_Audit__UnusedPermissionSetsGroup__c = groupName;
        }
        auditRecords.add(auditRecord);
    }

    // Upsert audit records
    try {
        if (!auditRecords.isEmpty()) {
            upsert auditRecords;
        }
    } catch (DmlException e) {
        for (Integer i = 0; i < e.getNumDml(); i++) {
            System.debug('Error upserting audit records: ' + e.getDmlMessage(i));
        }
    }
    Database.executeBatch(new rolesDataforReportBatch(), 50);
         } catch (Exception e) {
            System.debug('Error in finish method: ' + e.getMessage());
        }
}


}*/