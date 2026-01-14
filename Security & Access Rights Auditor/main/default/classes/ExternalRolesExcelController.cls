/*Author/Modified Code By : Pradeep
*/

public with sharing class ExternalRolesExcelController {
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public List<HierarchyService.HierarchyItem> hierarchyItemList{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    public ExternalRolesExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        hierarchyItemList = HierarchyService.getRolesHierarchyList('option32');        
        reportInfos = Utils.getReportsInfos();
    }

}