/*
Author      : Naveen Varshney
Description : This Class is Controller for the SubscribedReportsExcel.vfp VF Page
Dependencies: It is being used in SubscribedReportsExcel.vfp
*/
public with sharing class SubscribedReportsExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utility.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<ReportManagerController.CustomSubscribedReport> reportsList{ get; set; }
    public SubscribedReportsExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utility.getReportsInfos();
        if(!test.isRunningTest()){
           reportsList = ReportManagerController.viewTheSubscribedReports();  
}
       
    }
}