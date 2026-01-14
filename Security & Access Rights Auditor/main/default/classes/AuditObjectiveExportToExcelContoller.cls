public with sharing class AuditObjectiveExportToExcelContoller {

    public String xmlheader { get; set; }
    public String endfile { get; set; }

    public Map<String, List<SA_Audit__Audit_Step__c>> auditStepsMap { get; set; }

    public AuditObjectiveExportToExcelContoller() {
        xmlheader ='<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        endfile = '</Workbook>';
        List<Map<String, Object>> auditReportsData = AuditObjectiveController.getAuditReports();
        auditStepsMap = convertDataToAuditStepMap(auditReportsData);
    }

    public Map<String, List<SA_Audit__Audit_Step__c>> convertDataToAuditStepMap(List<Map<String, Object>> auditReportsData) {
        Map<String, List<SA_Audit__Audit_Step__c>> templateToStepsMap = new Map<String, List<SA_Audit__Audit_Step__c>>();

        for (Map<String, Object> reportData : auditReportsData) {
            // Retrieve the user ID from the report data
            String ownerId = String.valueOf(reportData.get('OwnerAssined__c'));

            // Query the user name based on the user ID
            String ownerName = getUserNameById(ownerId);

            SA_Audit__Audit_Step__c auditStep = new SA_Audit__Audit_Step__c(
                Name = String.valueOf(reportData.get('Name')),
                Template__c = String.valueOf(reportData.get('SA_Audit__Template__c')),
                ReviewDatee__c = String.valueOf(reportData.get('ReviewDatee__c')),
                Comments__c = String.valueOf(reportData.get('Comments__c')),
                OwnerAssined__c = String.valueOf(reportData.get('OwnerAssined__c')),
                OwnerExcel__c = ownerName  // Use the user name instead of the user ID
            );

            if(auditStep.Template__c != null){
                if (!templateToStepsMap.containsKey(auditStep.Template__c)) {
                    templateToStepsMap.put(auditStep.Template__c, new List<SA_Audit__Audit_Step__c>());
                }
                templateToStepsMap.get(auditStep.Template__c).add(auditStep);
            }
        }

        system.debug('templateToStepsMap: ' + templateToStepsMap);
        return templateToStepsMap;
    }

    // Helper method to get the user name by user ID
    private String getUserNameById(String userId) {
        system.debug('userId==' + userId);
        List<User> users = [SELECT Name FROM User WHERE Id = :userId LIMIT 1];
        if (!users.isEmpty()) {
            return users[0].Name;
        } else {
            return 'No User Assigned'; // Handle the case where no user is found
        }
    }
}