/*
Author      : Himanshu Kr. Varshney
Description : This Class is Controller for the ScheduleReportsExcel.vfp VF Page
Dependencies: It is being used in ScheduleReportsExcel.vfp
*/
public with sharing class ScheduleReportsExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utility.ReportInfos reportInfos{ get; set; } 
    @AuraEnabled
    public List<IntelController.ScheduledReportsData> reportsList{ get; set; }
    public ScheduleReportsExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utility.getReportsInfos(); 
        reportsList = IntelController.fetchTableDataOption23();
    }
}