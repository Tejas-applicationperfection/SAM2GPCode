/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class UserTerritoryExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public List<HierarchyService.ParentChildren> parentChildren{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    public UserTerritoryExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        Type objName = Type.forName('','Territory');
        if(objName != null){
            parentChildren = HierarchyService.getOldParentChildrenList(HierarchyService.getOldUserTerritoryList(),'User');
        }
        else{
            parentChildren = HierarchyService.getParentChildrenList(HierarchyService.getUserTerritoryList(),'User');
        }
        reportInfos = Utils.getReportsInfos();
    }
}