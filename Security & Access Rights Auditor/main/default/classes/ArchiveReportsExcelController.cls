/*
Author      : Himanshu Kr. Varshney
Description : This Class is Controller for the ArchivedReportsExcel.vfp VF Page
Dependencies: It is being used in ArchivedReportsExcel.vfp
*/
public with sharing class ArchiveReportsExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utility.ReportInfos reportInfos{ get; set; } 
    @AuraEnabled
    public List<ReportManagerController.ReportRecords> reportsList{ get; set; }
    public ArchiveReportsExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utility.getReportsInfos(); 
        reportsList = ReportManagerController.getArchivedFolderReports();
    }
}