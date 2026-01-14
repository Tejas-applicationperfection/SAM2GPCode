public with sharing class unusedPermissionsetsDataforReportBatch implements Database.Batchable<sObject> {
    
    
     public Database.QueryLocator start(Database.BatchableContext context) {
         
             if (Test.isRunningTest()){
             return Database.getQueryLocator([
            SELECT Id, Name, (SELECT Assignee.Name FROM Assignments LIMIT 100) FROM PermissionSet WHERE NOT Name LIKE 'X00%' limit 200
        ]);
        }else{
            return Database.getQueryLocator([
            SELECT Name FROM SA_Audit__Audithistory__c WHERE Name != NULL LIMIT 40000
        ]);
     }
   
    }
  
 public void execute(Database.BatchableContext context, List<SA_Audit__Audithistory__c> scope) {
    try {  
        // Query existing audit records in the database
        Set<String> existingAuditRecordNames = new Set<String>();
        for (SA_Audit__Audithistory__c record : [SELECT Name FROM SA_Audit__Audithistory__c  LIMIT 40000]) {
            existingAuditRecordNames.add(record.Name);
        }
        
        List<SA_Audit__Audithistory__c> auditRecords = new List<SA_Audit__Audithistory__c>();
        Map<String, List<String>> permissionSetsAndAssignees = new Map<String, List<String>>();
        
        Set<Id> permissionSetGroupIds = new Set<Id>();
        
        // Iterate through Permission Sets
        for (PermissionSet pset : [SELECT Id, Name, 
                                         (SELECT Assignee.Name FROM Assignments), 
                                         (SELECT PermissionSetGroupId FROM PermissionSetGroupComponents) 
                                   FROM PermissionSet 
                                   WHERE NOT Name LIKE 'X00%' 
                                   LIMIT 200]) {
            // Check if audit record already exists for this Permission Set
            if (!existingAuditRecordNames.contains(pset.Name)) {
                List<String> assigneeNames = new List<String>();
                List<PermissionSetAssignment> assignments = pset.Assignments;
                
                // Populate assignee names
                if (assignments != null) {
                    for (PermissionSetAssignment assignment : assignments) {
                        if (assignment.Assignee != null && assignment.Assignee.Name != null) {
                            assigneeNames.add(assignment.Assignee.Name);
                        }
                    }
                }
                
                // Collect PermissionSetGroupIds
                for (PermissionSetGroupComponent psetGrpComp : pset.PermissionSetGroupComponents) {
                    if (psetGrpComp.PermissionSetGroupId != null) {
                        permissionSetGroupIds.add(psetGrpComp.PermissionSetGroupId);
                    }
                }
                
                // Add assignee names to the map
                permissionSetsAndAssignees.put(pset.Name, assigneeNames);
                
                // Create and populate audit record
                SA_Audit__Audithistory__c auditRecord = new SA_Audit__Audithistory__c(); 
                if ( 
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isAccessible() &&   
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isCreateable() &&
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isUpdateable()&&
                    
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__UsedPermissionsetsName__c.isAccessible() &&   
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__UsedPermissionsetsName__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__UsedPermissionsetsName__c.isUpdateable() && 
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__PermissionMember__c.isAccessible() &&   
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__PermissionMember__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__PermissionMember__c.isUpdateable() && 
                    
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__PsetGrpInsidePset__c.isAccessible() &&   
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__PsetGrpInsidePset__c.isCreateable() &&
                    Schema.sObjectType.SA_Audit__Audithistory__c.fields.SA_Audit__PsetGrpInsidePset__c.isUpdateable()
                ){ 
                auditRecord.Name = pset.Name; 
                String assigneeNamesString = String.join(assigneeNames, ', ');
                auditRecord.SA_Audit__UsedPermissionsetsName__c = pset.Name; 
                auditRecord.SA_Audit__PermissionMember__c = assigneeNamesString;
                
                // Temporarily store group IDs to be replaced with names later
                List<String> permissionSetGroupIdsAsStrings = new List<String>();
                for (Id psetGrpId : permissionSetGroupIds) {
                    permissionSetGroupIdsAsStrings.add(psetGrpId);
                }
                auditRecord.SA_Audit__PsetGrpInsidePset__c = String.join(permissionSetGroupIdsAsStrings, ', ');
                
                auditRecords.add(auditRecord);
                    }}
        }
        
        // Retrieve PermissionSetGroup names
        Map<Id, String> psetGroupNames = new Map<Id, String>();
        if (!permissionSetGroupIds.isEmpty()) {
            for (PermissionSetGroup psetGroup : [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE Id IN :permissionSetGroupIds]) {
                psetGroupNames.put(psetGroup.Id, psetGroup.DeveloperName);
            }
        }
        
        // Replace PermissionSetGroup IDs with their names in audit records
        for (SA_Audit__Audithistory__c auditRecord : auditRecords) {
            List<String> psetGroupNamesList = new List<String>();
            for (String psetGroupId : auditRecord.SA_Audit__PsetGrpInsidePset__c.split(', ')) {
                if (psetGroupNames.containsKey(Id.valueOf(psetGroupId))) {
                    psetGroupNamesList.add(psetGroupNames.get(Id.valueOf(psetGroupId)));
                }
            }
            if ( Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isAccessible() &&   
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isCreateable() &&
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isUpdateable() && 
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__PsetGrpInsidePset__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__PsetGrpInsidePset__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__PsetGrpInsidePset__c.isUpdateable()) {
                    auditRecord.SA_Audit__PsetGrpInsidePset__c = String.join(psetGroupNamesList, ', ');
                }}
        
        // Insert the audit records
        if (!auditRecords.isEmpty()) {
            insert auditRecords;
        }
        
        // Insert unused Permission Sets into audit records
        List<PermissionSet> unusedPermissions = [SELECT Name FROM PermissionSet WHERE Id NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment) AND (NOT Name LIKE 'X00%')];
             System.debug('Unused Permission Sets Count: ' + unusedPermissions.size());
        if (!unusedPermissions.isEmpty()) {
            List<SA_Audit__Audithistory__c> unusedPermissionSetRecords = new List<SA_Audit__Audithistory__c>();
            for (PermissionSet unusedPermissionSet : unusedPermissions) {
                // Check if the unused permission set record already exists
                if ( Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isAccessible() &&   
                Schema.sObjectType.SA_Audit__Audithistory__c.fields.Name.isCreateable() &&
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.Name.isUpdateable() && 
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPermissionsetsName__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPermissionsetsName__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__AuditHistory__c.fields.SA_Audit__UnusedPermissionsetsName__c.isUpdateable()) {
                if (!existingAuditRecordNames.contains(unusedPermissionSet.Name)) {
                    SA_Audit__Audithistory__c unusedPermissionSetRecord = new SA_Audit__Audithistory__c();
                    unusedPermissionSetRecord.Name = unusedPermissionSet.Name;
                    unusedPermissionSetRecord.SA_Audit__UnusedPermissionsetsName__c = unusedPermissionSet.Name;
                    unusedPermissionSetRecords.add(unusedPermissionSetRecord);
                }
                }
            }
              System.debug('Unused Permission Sets to Insert: ' + unusedPermissionSetRecords.size());
            // Insert only new unused permission records
            if (!unusedPermissionSetRecords.isEmpty()) {
                insert unusedPermissionSetRecords;
            }
        }
    } catch (Exception e) {
        System.debug('Error in execute method: ' + e.getMessage());
    }
}

    public void finish(Database.BatchableContext context) {
        System.debug('Batch execution finished');
      if (!Test.isRunningTest()) {      
          Database.executeBatch(new PermissionSetGroupsDataforReportBatch(), 50);
        }
    }
    
}