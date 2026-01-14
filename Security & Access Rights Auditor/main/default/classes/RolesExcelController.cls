/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class RolesExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public List<HierarchyService.HierarchyItem> hierarchyItemList{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    public RolesExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        hierarchyItemList = HierarchyService.getRolesHierarchyList('option3');        
        reportInfos = Utils.getReportsInfos();
    }
}