/*
Author/Modified Code By : Pradeep
*/
public with sharing class PermissionsetGroupCmpController {
    @AuraEnabled
    public String xmlheader{ get; set; }
    @AuraEnabled
    public String reportBody{ get; set; }
    @AuraEnabled
    public String jobId{ get; set; }
   // @AuraEnabled
   // public List<PermissionSetGroupComponent> permissionSetGroupCmpList { get; set; }
     @AuraEnabled
    public MAP<ID,PermissionSetGroupComponent> permissionSetGroupCmpMap { get; set; }
    
    //public List<HierarchyService.ParentChildren> parentChildren{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<List<HierarchyService.ParentChildren>> allParentChildrens{ get; set; }
    public PermissionsetGroupCmpController(){
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        List<HierarchyService.ParentChildren> parentChildren = HierarchyService.getParentChildrenList(HierarchyService.getUserPermissionSetList('option9'), 'PermissionSet');
        reportInfos = Utils.getReportsInfos();
        Integer i = 0;
       // permissionSetGroupCmpList =  new List<PermissionSetGroupComponent>();       
       // permissionSetGroupCmpList = [SELECT PermissionSetGroupId, CreatedBy.Name, CreatedDate, PermissionSetGroup.DeveloperName, PermissionSetId, PermissionSet.Name, PermissionSet.Label FROM PermissionSetGroupComponent Where PermissionSet.Name != Null];
         
         
        permissionSetGroupCmpMap = new Map<ID, PermissionSetGroupComponent>([SELECT PermissionSetGroupId, CreatedBy.Name, CreatedDate, PermissionSetGroup.DeveloperName, PermissionSetId, PermissionSet.Name, PermissionSet.Label FROM PermissionSetGroupComponent Where PermissionSet.Name != Null]);
        
        /*
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
        System.debug('allParentChildrens===' + allParentChildrens);*/
    }
}