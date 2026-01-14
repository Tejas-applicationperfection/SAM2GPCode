/*
Author      : Himanshu Kr. Varshney
Description : This Class is Controller for the ReportsExcel.vfp VF Page
Dependencies: It is being used in ReportsExcel.vfp
*/
public with sharing class ReportsExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utility.ReportInfos reportInfos{ get; set; } 
    @AuraEnabled
    public List<List<ReportManagerController.ReportRecords>> reportsList{ get; set; }
    public ReportsExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utility.getReportsInfos(); 
        String flag = ApexPages.currentPage().getParameters().get('flag');
        if(flag.equals('true')){
            Date selectedDate = Date.valueOf(ApexPages.currentPage().getParameters().get('selectedDate'));
            reportsList = ReportManagerController.getReportRecordsBasedOnDate(selectedDate);
        }
        else{
            Integer selectedOption = Integer.valueof(ApexPages.currentPage().getParameters().get('selectedOption'));
            reportsList = ReportManagerController.getReportRecordsBasedOnMonths(selectedOption);
        }
    }
}