/*
Author       : Himanshu Kr. Varshney
Description  : Apex Controller for Intel Tab(For Option 15)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class PermissionSetWithNoUsers{
    @AuraEnabled
    public String xmlheader{ get; set; } 
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<PermissionSetsWithNoUsersBatchApex.WrapperData> permissionSetsList{ get; set; }
    public PermissionSetWithNoUsers(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        permissionSetsList = getPermissionSetsDetails();
        reportInfos = Utils.getReportsInfos(); 
    }
/*
Author  : Himanshu Kr. Varshney
Purpose : Below Method will Give Us Data related to Option 15
*/  
    @AuraEnabled
    @RemoteAction
    public static List<PermissionSetsWithNoUsersBatchApex.WrapperData> getPermissionSetsDetails(){
        List<PermissionSetsWithNoUsersBatchApex.WrapperData> wrapperDataList = IntelController.fetchTableDataOption15();
        return wrapperDataList;
    }
}