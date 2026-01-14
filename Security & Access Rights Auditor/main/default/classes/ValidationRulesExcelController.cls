/*
Author       : Himanshu Kr. Varshney
Description  : It will generate the data(For Option 20)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class ValidationRulesExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; } 
    @AuraEnabled
    public List<ValidationRulesBatch.FinalClass> finalList{ get; set; }
    public ValidationRulesExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
        if(!test.isRunningTest()){
        finalList = IntelController.fetchTableDataOption20();
        }
    }
}