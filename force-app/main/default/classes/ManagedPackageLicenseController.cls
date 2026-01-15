/*
Author       : Himanshu Kr. Varshney
Description  : It will generate the data(For Option 19)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class ManagedPackageLicenseController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<ManagedPackageLicenseFutureController.ManagedPackageDetailsClass> finalList { get; set; }
    public ManagedPackageLicenseController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
        finalList = IntelController.fetchTableDataOption19();    
    }
}