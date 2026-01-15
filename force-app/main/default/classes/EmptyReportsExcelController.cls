/*
Author      : Himanshu Kr. Varshney
Description : This Class is Controller for the EmptyReportsExcel.vfp VF Page
Dependencies: It is being used in EmptyReportsExcel.vfp
*/
public with sharing class EmptyReportsExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; } 
    @AuraEnabled
    public List<IntelController.FoldersData> reportsList{ get; set; }
    public EmptyReportsExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
        reportsList = IntelController.fetchTableDataOption25();
    }
}