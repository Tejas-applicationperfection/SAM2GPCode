/*
Author       : Himanshu Kr. Varshney
Description  : Batch Apex for Intel tab feature named Permission Sets with No Users Assigned, Option 15
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class PermissionSetsWithNoUsersBatchApex implements Database.Batchable<PermissionSet>, Database.Stateful{
    public List<WrapperData> wrapperDataList;
       string ActiveCounts = '0';
      string InActiveCounts= '0';
    public PermissionSetsWithNoUsersBatchApex(){
        this.wrapperDataList = new List<WrapperData>();
         

    }
    public Iterable<PermissionSet> start(Database.BatchableContext BC){
        
        List<PermissionSet> permissionList;
        if(Test.isRunningTest()){ 
            permissionList = [SELECT Id, Label, Name, ProfileId, Profile.Name FROM PermissionSet WHERE (NOT PermissionSet.Name LIKE 'X00%') LIMIT 100];
        }
        else{
            permissionList = [SELECT Id, Label, Name, ProfileId, Profile.Name FROM PermissionSet WHERE (NOT PermissionSet.Name LIKE 'X00%')];   
        }
        return permissionList; 
    }
    public void execute(Database.BatchableContext BC, List<PermissionSet> permissionList){
               
       // List<PermissionSetAssignment> permissionSetList = [SELECT AssigneeId, Assignee.Name, Assignee.isActive, PermissionSet.Label, Id, PermissionSetId FROM PermissionSetAssignment WHERE (NOT PermissionSet.Name LIKE 'X00%')];
      // List<PermissionSetAssignment> permissionSetList = [SELECT AssigneeId, Assignee.Name, Assignee.isActive, PermissionSet.Label, Id, PermissionSetId FROM PermissionSetAssignment WHERE (NOT PermissionSet.Name LIKE 'X00%') AND NamespacePrefix != null AND PermissionSetId IN :permissionList];
        List<PermissionSetAssignment> permissionSetList = [
            SELECT AssigneeId, Assignee.Name,PermissionSet.Id, PermissionSet.NamespacePrefix, Assignee.isActive, PermissionSet.Label, Id, PermissionSetId 
            FROM PermissionSetAssignment 
            WHERE (NOT PermissionSet.Name LIKE 'X00%') 
         
            AND PermissionSetId IN :permissionList  
        ];
        
         String orgId = UserInfo.getOrganizationId();
           Organization org = [SELECT Id , Name, NamespacePrefix FROM Organization WHERE ID = :orgID];

        for(PermissionSet perRecord: permissionList){
            ActiveCounts = '0';
             InActiveCounts = '0';
            WrapperData oneWrapperData = new WrapperData();
            oneWrapperData.permissionSetName = perRecord.Label;
            for(PermissionSetAssignment perSetAssignment: permissionSetList){
                if(perSetAssignment.PermissionSet.NamespacePrefix != org.NamespacePrefix){
					oneWrapperData.IsManaged = true;
                }else{
                    oneWrapperData.IsManaged = false;
                }            
                if(perSetAssignment.PermissionSetId == perRecord.Id){
                    if(perSetAssignment.Assignee.isActive){
                        oneWrapperData.usedByActiveUser = 'Yes ';
                        
                        ActiveCounts =  String.valueOf(Integer.ValueOf(ActiveCounts) + 1 );
                        system.debug('Testing ActiveCounts'+ActiveCounts);
                          //oneWrapperData.ActiveCountperm =  ActiveCounts;
                    }
                    else{
                        oneWrapperData.usedByInactiveUser = 'Yes ';
                        InActiveCounts =  String.valueOf(Integer.ValueOf(InActiveCounts) + 1 );
                        system.debug('Testing InActiveCounts'+InActiveCounts);
                        //oneWrapperData.InActiveCountperm = InActiveCounts;
                    }
                }
               
            }
            oneWrapperData.ActiveCountperm =  ActiveCounts;
            oneWrapperData.InActiveCountperm = InActiveCounts;
            //system.debug('testing'+'ActiveCountperm='+oneWrapperData.ActiveCountperm +'-InActiveCountperm-'+ oneWrapperData.InActiveCountperm +'usedByActiveUser---'+ oneWrapperData.usedByActiveUser +'usedByInactiveUser--'+ oneWrapperData.usedByInactiveUser );
            If( oneWrapperData.ActiveCountperm == '0' && oneWrapperData.usedByActiveUser == 'Yes ' ){
                oneWrapperData.usedByActiveUser = 'YES ';
                 oneWrapperData.ActiveCountperm = ''; 
            }
            if(oneWrapperData.ActiveCountperm == '0' && ( oneWrapperData.usedByActiveUser == Null ||oneWrapperData.usedByActiveUser == '' )){
                oneWrapperData.usedByActiveUser = 'NO ';
                 oneWrapperData.ActiveCountperm = '';
            }   
            
            
            if(oneWrapperData.InActiveCountperm == '0' && oneWrapperData.usedByInactiveUser == 'Yes '){
                 oneWrapperData.usedByInactiveUser = 'YES ';
                oneWrapperData.InActiveCountperm  = '';
            }
            
            if(oneWrapperData.InActiveCountperm == '0' && ( oneWrapperData.usedByInactiveUser == Null ||oneWrapperData.usedByInactiveUser == '' )){
                oneWrapperData.usedByInactiveUser = 'NO ';
                     oneWrapperData.InActiveCountperm = ''; 
            }   
            
            wrapperDataList.add(oneWrapperData);
        }
    }
    public void finish(Database.BatchableContext BC){
        SA_Audit__OWD_Sharing_Report__c owdObjRecord = new SA_Audit__OWD_Sharing_Report__c();
        List<SA_Audit__OWD_Sharing_Report__c> owdSharingReportList = [SELECT Id, SA_Audit__Type__c, SA_Audit__Managed_Package_License_Datails__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'PermissionSet' LIMIT 100];
        if(owdSharingReporTList.size() > 0 && SA_Audit__OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
            delete owdSharingReportList;
        }
        if(Schema.sObjectType.SA_Audit__OWD_Sharing_Report__c.fields.SA_Audit__Type__c.isCreateable()){
            owdObjRecord.SA_Audit__Type__c = 'PermissionSet';
            insert owdObjRecord;
        }
        Blob excelData;
        if(Schema.sObjectType.Attachment.fields.Body.isCreateable() && Schema.sObjectType.Attachment.fields.parentId.isCreateable() && Schema.sObjectType.Attachment.fields.ContentType.isCreateable() && Schema.sObjectType.Attachment.fields.Name.isCreateable()){

        Attachment attach = new Attachment();
        attach.Name = 'PermissionSetsWithNoUsersReport';
        attach.ContentType = 'text/plain';
        attach.parentId = owdObjRecord.Id;
        attach.Body = Blob.valueOf(JSON.serialize(wrapperDataList));
             insert attach;}
        /*SA_Audit__BatchApexStatus__c customSettingRecord = SA_Audit__BatchApexStatus__c.getValues('Permission Set');
        customSettingRecord.SA_Audit__Batch_Apex_Id__c = permissionSetBatchApexId;
        customSettingRecord.SA_Audit__Is_Batch_Apex_Executed__c = true;
        update customSettingRecord;*/
        
    }
    //Below Class will Hold the Wrapper Data 
    public class WrapperData{
        @AuraEnabled
        public String permissionSetName {get; set;}
        @AuraEnabled
        public String usedByActiveUser {get; set;}
        @AuraEnabled
        public String usedByInactiveUser {get; set;}
        @AuraEnabled
        public string ActiveCountperm {get; set;}
        @AuraEnabled
        public string InActiveCountperm {get; set;}
         @AuraEnabled
        public Boolean IsManaged {get; set;}
    }
}