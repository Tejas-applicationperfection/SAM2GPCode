/*
Author       : Himanshu Kr. Varshney
Description  : Apex Controller for the VF Page ListViewExcel.vfp
Dependencies : ListViewExcel.vfp
*/
public with sharing class ListViewExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; } 
    @AuraEnabled
    public List<ListViewBatchApex.FinalClass> finalList{ get; set; }
    public ListViewExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();  
        finalList = IntelController.fetchTableDataOption22();
    }
}