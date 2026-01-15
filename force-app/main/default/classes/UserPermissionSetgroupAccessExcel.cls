public with sharing class UserPermissionSetgroupAccessExcel implements Database.Batchable<SObject>, Database.Stateful {

   // public String xmlheader{ get; set; }
   // public Utils.ReportInfos reportInfos{ get; set; }
    public  List<PermissionSetWrapper> permissionSetWrappertList ;
    
    public UserPermissionSetgroupAccessExcel(){
        // xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        // reportInfos = Utils.getReportsInfos();
        
         this.permissionSetWrappertList = new List<PermissionSetWrapper>();
    }

    // Start method to fetch the query locator
    public Iterable<PermissionSetAssignment> start(Database.BatchableContext BC) {
        List<PermissionSetAssignment> permissionList;
         
		permissionList = [SELECT Id, PermissionSetGroupId, AssigneeId, Assignee.Name, Assignee.Email, 
                    PermissionSetId, PermissionSet.Label, PermissionSet.Name 
             FROM PermissionSetAssignment 
             WHERE Assignee.Name != NULL 
             ORDER BY Assignee.Name ASC LIMIT 4000];
        return permissionList;
        
    }

    // Execute method to process each batch of records
    public void execute(Database.BatchableContext BC, List<PermissionSetAssignment> permissionList) {
        for (PermissionSetAssignment assignment : permissionList) {
            PermissionSetWrapper wrapper = new PermissionSetWrapper();
            wrapper.UserId = assignment.AssigneeId;
            wrapper.UserEmail = assignment.Assignee.Email;
            wrapper.UserNam = assignment.Assignee.Name;
            wrapper.AssignedPermission = assignment.PermissionSet.Name;
            wrapper.PermissionSetGroups = assignment.PermissionSetGroupId;
            permissionSetWrappertList.add(wrapper);
        }
        system.debug('======permissionSetWrappertList======'+permissionSetWrappertList);
    }
    
    // Finish method to perform any post-processing
    /*public void finish(Database.BatchableContext BC) {
        for (PermissionSetWrapper wrapper : permissionSetWrappertList) {
            SA_Audit__IntelUserPermissionData__c customRecord = new SA_Audit__IntelUserPermissionData__c();
            if ( Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserId__c.isAccessible() &&   
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserId__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserId__c.isUpdateable() && 
                
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserNam__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserNam__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserNam__c.isUpdateable() &&
                
               Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserEmail__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserEmail__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserEmail__c.isUpdateable() &&
                
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__AssignedPermission__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__AssignedPermission__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__AssignedPermission__c.isUpdateable() &&
               
               Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__PermissionSetGroups__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__PermissionSetGroups__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__PermissionSetGroups__c.isUpdateable()) {
                    customRecord.SA_Audit__UserId__c = wrapper.UserId;
                    customRecord.SA_Audit__UserNam__c = wrapper.UserNam;
                    customRecord.SA_Audit__UserEmail__c = wrapper.UserEmail;
                    customRecord.SA_Audit__AssignedPermission__c = wrapper.AssignedPermission;
                    customRecord.SA_Audit__PermissionSetGroups__c = wrapper.PermissionSetGroups;
                    insert customRecord;
                }
        }
    }*/
    //above code changed to below code cause of the DML inside Loop Warning in review
    public void finish(Database.BatchableContext BC) {
    // Create a list to hold records for a single insert operation
        List<SA_Audit__IntelUserPermissionData__c> customRecordsToInsert = new List<SA_Audit__IntelUserPermissionData__c>();
        
        for (PermissionSetWrapper wrapper : permissionSetWrappertList) {
            // Check field-level security (FLS) permissions for each field
            if (Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserId__c.isAccessible() &&   
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserId__c.isCreateable() &&
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserId__c.isUpdateable() && 
                
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserNam__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserNam__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserNam__c.isUpdateable() &&
                
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserEmail__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserEmail__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__UserEmail__c.isUpdateable() &&
                
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__AssignedPermission__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__AssignedPermission__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__AssignedPermission__c.isUpdateable() &&
                
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__PermissionSetGroups__c.isCreateable() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__PermissionSetGroups__c.isAccessible() &&  
                Schema.sObjectType.SA_Audit__IntelUserPermissionData__c.fields.SA_Audit__PermissionSetGroups__c.isUpdateable()) {
                    
                    // Create the record and add to the list
                    SA_Audit__IntelUserPermissionData__c customRecord = new SA_Audit__IntelUserPermissionData__c(
                        SA_Audit__UserId__c = wrapper.UserId,
                        SA_Audit__UserNam__c = wrapper.UserNam,
                        SA_Audit__UserEmail__c = wrapper.UserEmail,
                        SA_Audit__AssignedPermission__c = wrapper.AssignedPermission,
                        SA_Audit__PermissionSetGroups__c = wrapper.PermissionSetGroups
                    );
                    customRecordsToInsert.add(customRecord);
                }
        }
        
        // Perform a single insert operation outside the loop
        if (!customRecordsToInsert.isEmpty()) {
            try {
                insert customRecordsToInsert;
                System.debug('Custom records inserted successfully.');
            } catch (Exception e) {
                System.debug('Error inserting custom records: ' + e.getMessage());
            }
        } else {
            System.debug('No valid records to insert.');
        }
    }

    
    // Wrapper class to hold the permission set data
    public class PermissionSetWrapper {
        public String UserId{get; set;}
        public String UserNam{get; set;}
        public String UserEmail{get; set;}
        public String AssignedPermission{get; set;}
        public String PermissionSetGroups{get; set;}
    }
}