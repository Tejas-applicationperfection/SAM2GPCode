/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class UserPermissionSetExcelController{
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public String reportBody{ get; set; }
    @AuraEnabled
    public String jobId{ get; set; }
    @AuraEnabled
    public string value { get; set;}
    //public List<HierarchyService.ParentChildren> parentChildren{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<List<HierarchyService.ParentChildren>> allParentChildrens{ get; set; }
    public UserPermissionSetExcelController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
       // List<HierarchyService.ParentChildren> parentChildren = HierarchyService.getParentChildrenList(HierarchyService.getUserPermissionSetList('option9'), 'Assignee');
       List<HierarchyService.ParentChildren> parentChildren = HierarchyService.getParentChildrenList(HierarchyService.getActiveUserPermission(1, 4000), 'Assignee');
        reportInfos = Utils.getReportsInfos();
        Integer i = 0;
        allParentChildrens = new List<List<HierarchyService.ParentChildren>>();
        List<HierarchyService.ParentChildren> tempParentChildren = new List<HierarchyService.ParentChildren>();
        for(HierarchyService.ParentChildren pc : parentChildren){
            if(i < 1000){                
                tempParentChildren.add(pc);
                i++;
            } 
            else{
                allParentChildrens.add(tempParentChildren);
                i = 1;
                tempParentChildren = new List<HierarchyService.ParentChildren>();
                tempParentChildren.add(pc);
            }
        }
        if(tempParentChildren.size() > 0){
            allParentChildrens.add(tempParentChildren);
        }
        System.debug('allParentChildrens===' + allParentChildrens);
    }
}