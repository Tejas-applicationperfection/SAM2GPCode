/*
Author       : Himanshu Kr. Varshney
Description  : This class will generate the Data(For Option 21) 
Dependencies : Called from DashboardReportExcel.vfp
*/
public with sharing class DashboardReportExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<IntelController.DashboardClass> finalList { get; set; }
    public DashboardReportExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
        finalList = IntelController.fetchTableDataOption21();    
    }
}