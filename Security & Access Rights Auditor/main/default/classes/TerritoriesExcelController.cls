/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class TerritoriesExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; } 
    @AuraEnabled
    public List<HierarchyService.HierarchyItem> hierarchyItemList{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    public TerritoriesExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        Type objName = Type.forName('','Territory');
        if(objName != null){
            hierarchyItemList = HierarchyService.getOldTerritoriesHierarchyList();
        }
        else{
            hierarchyItemList = HierarchyService.getTerritoriesHierarchyList();
        }
        reportInfos = Utils.getReportsInfos();
    }
}