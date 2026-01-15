/*
Author       : Himanshu Kr. Varshney
Description  : It will generate the data, User Old Territories(For Option option8)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class OldUserTerritoriesExcelController{
    public String xmlheader { get; set; }
    public List<HierarchyService.ParentChildren> parentChildren { get; set; }
    public Utils.ReportInfos reportInfos { get; set; }
    public OldUserTerritoriesExcelController(){
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        if(!Test.isRunningTest()){
            parentChildren = HierarchyService.getOldParentChildrenList(HierarchyService.getOldUserTerritoryList(),'User');
        }
        reportInfos = Utils.getReportsInfos();
    }
}