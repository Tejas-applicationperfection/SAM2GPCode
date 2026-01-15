/*
Author       : Himanshu Kr. Varshney
Description  : It will generate the data, Old Territories(For Option option7)
Dependencies : Called from IntelController.apxc Class
*/
public with sharing class OldTerritoryExcelController{
	public String xmlheader { get; set; }
    public List<HierarchyService.HierarchyItem> hierarchyItemList { get; set; }
    public Utils.ReportInfos reportInfos { get; set; }
    public OldTerritoryExcelController(){
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        if(!Test.isRunningTest()){
            hierarchyItemList = HierarchyService.getOldTerritoriesHierarchyList();
        }
        reportInfos = Utils.getReportsInfos();
    }
}