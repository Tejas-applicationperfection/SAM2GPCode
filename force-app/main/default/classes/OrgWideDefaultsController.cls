/*
Author       : Himanshu Kr. Varshney
Description  : Apex Controller for Intel Tab(For Option 14)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class OrgWideDefaultsController{
/*
Author  : Himanshu Kr. Varshney
Purpose : Below Method will Give Us Data related to OWD
*/  
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<List<String>> owdListItmes{ get; set; }
    public OrgWideDefaultsController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        SA_Audit__OWD_Sharing_Report__c objData = [SELECT Id, SA_Audit__OWD_Data_Field__c FROM SA_Audit__OWD_Sharing_Report__c WHERE SA_Audit__Type__c = 'OWDReport' ORDER BY CreatedDate DESC LIMIT 1];      
        List<List<String>> finalList = new List<List<String>>();
        List<String> strList = objData.OWD_Data_Field__c.split('\\|');
        for(Integer i = 0; i < strList.size(); i++){
            List<String> secondList = strList[i].split('\\?');
            finalList.add(secondList);
        }
        reportInfos = Utils.getReportsInfos(); 
        owdListItmes = finalList;
    }
    //Below Wrapper Class will Save the Data which are Related to OWD
    public class OWDData{
        @AuraEnabled
        public String objectLabel;
        @AuraEnabled
        public String InternalSharingModel;
        @AuraEnabled
        public String ExternalSharingModel;
        @AuraEnabled
        public String isChecked;
    }
}