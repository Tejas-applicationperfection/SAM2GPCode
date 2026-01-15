public with sharing class AuditObjectiveExportToExcelContoller2 {
    public String xmlheader { get; set; }
    public String endfile { get; set; }
     
    public List<Map<String, Object>> permissionReviewDataMap { get; set; }

    public AuditObjectiveExportToExcelContoller2() {
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
       endfile = '</Workbook>';
        permissionReviewDataMap = convertPermissionReviewDataToMap(AuditObjectiveController.getPermissionReviewData());
        system.debug('result='+permissionReviewDataMap);
    }

    public List<Map<String, Object>> convertPermissionReviewDataToMap(List<SA_Audit.AuditObjectiveController.PermissionReviewItem> permissionReviewData) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();

        for (SA_Audit.AuditObjectiveController.PermissionReviewItem item : permissionReviewData) {
            Map<String, Object> itemMap = new Map<String, Object>();
            itemMap.put('Index', item.index);
            itemMap.put('Type', item.type);
            itemMap.put('ProfileCount', item.Profilecount);
            itemMap.put('PermissionCount', item.Permissioncount);
            itemMap.put('PermissionGroupCount', item.PermissionGroupcount);
            itemMap.put('RolesCount', item.Rolescount);
            itemMap.put('PublicGroupcount', item.PublicGroupcount);
            itemMap.put('InternalRolescount', item.InternalRolescount);
            itemMap.put('ExternalRolescount', item.ExternalRolescount); 
            itemMap.put('unusedProfilesCount', item.unusedProfilesCount);
            itemMap.put('unusedPermissionCount', item.unusedPermissionCount);
           itemMap.put('unusedPermissionGroupCount', item.unusedPermissionGroupCount);
            itemMap.put('unusedRolesCanDelete', item.unusedRolesCanDelete);
            itemMap.put('unusedPublicGroupCanDelete', item.unusedPublicGroupCanDelete);
            itemMap.put('unusedInternalRolesCanDelete', item.unusedInternalRolesCanDelete);
            itemMap.put('unusedExternalRolesCanDelete', item.unusedExternalRolesCanDelete);
            
              itemMap.put('percentageUnusedProfiles', item.percentageUnusedProfiles);
              itemMap.put('percentageUnusedPermissions', item.percentageUnusedPermissions);
              itemMap.put('percentageUnusedPsetGroup', item.percentageUnusedPsetGroup);
              itemMap.put('percentageUnusedRoles', item.percentageUnusedRoles);
              itemMap.put('percentageUnusedPublicGroup', item.percentageUnusedPublicGroup);
              itemMap.put('percentageUnusedInternalRoles', item.percentageUnusedInternalRoles);
             itemMap.put('percentageUnusedExternalRoles', item.percentageUnusedExternalRoles);
            result.add(itemMap);
        }
		system.debug('result='+result);
        return result;
        
    }
}