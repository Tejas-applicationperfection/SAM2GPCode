public with sharing class Permissionsetnotassignedexcel {
   
    public String xmlheader{ get; set; }
 
    public String reportBody{ get; set; }
   
    public Utils.ReportInfos reportInfos{ get; set; }
    public List<PermissionSetWrapper> permissionSets { get; set; }
    
    public Permissionsetnotassignedexcel(){
         xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos();
        permissionSets = fetchTableDataOption39();
    }
    
    
      
    public static List<PermissionSetWrapper> fetchTableDataOption39() {
        try {
            Set<Id> assignedPermSetIds = new Set<Id>();
            for (PermissionSetGroupComponent psgc : [
                SELECT PermissionSetId FROM PermissionSetGroupComponent LIMIT 2000]) {
                assignedPermSetIds.add(psgc.PermissionSetId);
            }
            
            List<PermissionSetWrapper> wrapperList = new List<PermissionSetWrapper>();
            for (PermissionSet ps : [
                SELECT Id, Name, Label, CreatedBy.Name, CreatedDate 
                FROM PermissionSet
                WHERE Id NOT IN :assignedPermSetIds AND (NOT Name LIKE 'X00%') 
                ORDER BY Name Limit 2000
            ]) {
                wrapperList.add(new PermissionSetWrapper(ps.Id, ps.Name, ps.Label, ps.CreatedBy.Name, ps.CreatedDate));
            }
            return wrapperList;
        } catch (Exception e) {
            System.debug('Error in fetchTableDataOption39: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while fetching permission sets.');
        }
    }

    // Wrapper class to store permission set details
    public class PermissionSetWrapper {
        public String id { get; set; }
        public String name { get; set; }
        public String label { get; set; }
        public String createdBy { get; set; }
        public DateTime createdDate { get; set; }

        public PermissionSetWrapper(String id, String name, String label, String createdBy, DateTime createdDate) {
            this.id = id;
            this.name = name;
            this.label = label;
            this.createdBy = createdBy;
            this.createdDate = createdDate;
        }
    }
}