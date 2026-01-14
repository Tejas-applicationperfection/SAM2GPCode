public with sharing class PermissionSetTabsExcelController {
    public String xmlheader { get; set; }
    public List<PermissionSetTabSetting> permisionSetTabs { get; set; }    
    public Utils.ReportInfos reportInfos { get; set; }
    
    public PermissionSetTabsExcelController() {
        permisionSetTabs = new List<PermissionSetTabSetting>();
        for(PermissionSetTabSetting pst : [select id, Name, Visibility, ParentId, Parent.name, Parent.IsCustom, Parent.IsOwnedByProfile, Parent.Label, Parent.PermissionsModifyAllData from PermissionSetTabSetting WHERE (Not Parent.Name Like 'X00%') AND Parent.Name != null ]) {
            permisionSetTabs.add(pst);
        }
    }
}