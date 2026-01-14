/*
Author      : Himanshu Kr. Varshney
Description : This Class is Controller for the FilteredReportsExcel.vfp VF Page
Dependencies: It is being used in FilteredReportsExcel.vfp
*/
public with sharing class FilteredReportsExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utility.ReportInfos reportInfos{ get; set; } 
    @AuraEnabled
    public List<ReportManagerController.FilteredReportsData> reportsList{ get; set; }
    public FilteredReportsExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utility.getReportsInfos(); 
        reportsList = ReportManagerController.viewTheFilteredReports();
    }
}