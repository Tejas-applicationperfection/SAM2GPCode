/*
Author      : Himanshu Kr. Varshney
Description : This Class is Controller for the FilterReportsExcel.vfp VF Page
Dependencies: It is being used in FilterReportsExcel.vfp
*/
public with sharing class FilterReportsExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utility.ReportInfos reportInfos{ get; set; } 
    @AuraEnabled
    public List<IntelController.FilteredReportsData> reportsList{ get; set; }
    public FilterReportsExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utility.getReportsInfos(); 
        reportsList = IntelController.fetchTableDataOption24();
    }
}