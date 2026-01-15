/*
Author/Modified Code By : Himanshu Kr. Varshney
*/
public with sharing class PermissionSetsWithUsersExcelController {
    @AuraEnabled public String xmlheader { get; set; }
    @AuraEnabled public Utils.ReportInfos reportInfos { get; set; }
    @AuraEnabled public List<PermissionSetExcelWrapper> excelData { get; set; } // Use wrapper instead of raw SObjects

    public PermissionSetsWithUsersExcelController() {
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
        excelData = fetchTableDataOption10(1, 2000);
    }

    // Wrapper class to structure data for Excel
    public class PermissionSetExcelWrapper {
        @AuraEnabled public String permissionSetName { get; set; }
        @AuraEnabled public String permissionSetLicense { get; set; }
        @AuraEnabled public Boolean isCustom { get; set; }
        @AuraEnabled public String userName { get; set; }
        @AuraEnabled public String userId { get; set; }
        @AuraEnabled public String profileName { get; set; }
        @AuraEnabled public String roleName { get; set; }
        @AuraEnabled public DateTime lastLoginDate { get; set; }
    }

    // Fetch data and map it to the wrapper
    @AuraEnabled
    public static List<PermissionSetExcelWrapper> fetchTableDataOption10(Integer pageNumber, Integer pageSize) {
        List<PermissionSetAssignment> assignments = [
            SELECT 
                Assignee.Profile.Name, Assignee.UserRole.Name, Assignee.Name, Assignee.Title, 
                Assignee.Department, Assignee.LastLoginDate, AssigneeId,
                PermissionSet.Label, PermissionSet.License.Name, PermissionSet.IsCustom
            FROM PermissionSetAssignment 
            WHERE Assignee.IsActive = true AND (NOT PermissionSet.Name LIKE 'X00%') 
            LIMIT :pageSize OFFSET :((pageNumber - 1) * pageSize)
        ];

        // Map the SObjects to the wrapper
        List<PermissionSetExcelWrapper> wrappers = new List<PermissionSetExcelWrapper>();
        for (PermissionSetAssignment psa : assignments) {
            PermissionSetExcelWrapper wrapper = new PermissionSetExcelWrapper();
            wrapper.permissionSetName = psa.PermissionSet.Label;
            wrapper.permissionSetLicense = psa.PermissionSet.License?.Name; // Handle null License
            wrapper.isCustom = psa.PermissionSet.IsCustom;
            wrapper.userName = psa.Assignee.Name;
            wrapper.userId = psa.AssigneeId;
            wrapper.profileName = psa.Assignee.Profile?.Name; // Handle null Profile
            wrapper.roleName = psa.Assignee.UserRole?.Name; // Handle null UserRole
            wrapper.lastLoginDate = psa.Assignee.LastLoginDate;
            wrappers.add(wrapper);
        }

        return wrappers;
    }
}
/*    List<HierarchyService.ParentChildren> parentChildren = HierarchyService.getParentChildrenList(HierarchyService.getUserPermissionSetList('option9'), 'PermissionSet');
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
        System.debug('allParentChildrens===' + allParentChildrens);*/