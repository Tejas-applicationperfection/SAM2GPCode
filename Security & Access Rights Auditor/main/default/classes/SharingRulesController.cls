/*
Author       : Himanshu Kr. Varshney
Description  : Apex Controller for SharingRulesExcel VF Page(For Option 13)
Dependencies : Called from SharingRulesExcel VF Page
*/
public with sharing class SharingRulesController{
/*
Author  : Himanshu Kr. Varshney
Purpose : Below Method will Give Us Data related to Sharing Rules
*/  
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<SharingSettingsFutureController.SharingRulesData> sharingRulesListItmes{ get; set; }
    public SharingRulesController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        sharingRulesListItmes = IntelController.fetchTableDataOption13();
        reportInfos = Utils.getReportsInfos(); 
    }
}