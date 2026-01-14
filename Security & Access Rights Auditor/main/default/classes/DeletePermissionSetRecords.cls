public with sharing class DeletePermissionSetRecords {
    public static void DeleteRecords(){
        
        SA_Audit__BatchApexStatus__c customSettingRecord = SA_Audit__BatchApexStatus__c.getValues('PermissionSet');
        if(customSettingRecord != null){
           if(SA_Audit__BatchApexStatus__c.sObjectType.getDescribe().isDeletable()){
             delete customSettingRecord;
               
               
            }
        }
        List<SA_Audit__BatchApexStatus__c> OWDObjectRecord = [Select SA_Audit__Is_Batch_Apex_Executed__c from SA_Audit__BatchApexStatus__c Where SA_Audit__Is_Batch_Apex_Executed__c = true ];
        if(SA_Audit__BatchApexStatus__c.sObjectType.getDescribe().isDeletable()){
            //delete OWDObjectRecord;
            Database.DeleteResult[] OWDObjectRecords= Database.delete(OWDObjectRecord , false);
            for(Database.DeleteResult rep : OWDObjectRecords) {
                if (rep.isSuccess()) {
                    System.debug('Successfully deleted account with ID: ' + rep.getId());
                }
        }
        }
            List<SA_Audit__OWD_Sharing_Report__c> objData = [SELECT Id, SA_Audit__OWD_Data_Field__c, SA_Audit__Sharing_Rules_Details__c FROM SA_Audit__OWD_Sharing_Report__c  WHERE SA_Audit__Type__c = 'PermissionSet' ];
             if(SA_Audit__OWD_Sharing_Report__c.sObjectType.getDescribe().isDeletable()){
               //delete objData;
                 Database.DeleteResult[] OWDObjectRecordss= Database.delete(objData , false);
                 for(Database.DeleteResult rep2 : OWDObjectRecordss) {
                if (rep2.isSuccess()) {
                    System.debug('Successfully deleted account with ID: ' + rep2.getId());
                }
            }
            
             }
    }     
}