public with sharing class PageLayoutAssignmentClass {
    
      @AuraEnabled
    public static String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    
    @AuraEnabled
    public static String getSessionId() {
        return UserInfo.getSessionId();
       //return 'callout:SA_Audit__Tooling_API_Creds' ;
    }
    
    
    public PageLayoutAssignmentClass(){
         xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
    }

    public class ProfileLayoutAssignment {
        @AuraEnabled
        public String objectSelected { get; set; }
        @AuraEnabled
        public String profileName { get; set; }
        @AuraEnabled
        public Map<String, Map<String, Set<String>>> profileData { get; set; }
    }
    
    private static Map<Id, String> fetchRecordTypeNames(List<String> objectName) {
        Map<Id, String> recordTypeNames = new Map<Id, String>();
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType = :objectName]) {
            recordTypeNames.put(rt.Id, rt.Name);
        }
         system.debug('recordTypeNames'+recordTypeNames);
        return recordTypeNames;
    }
    
    @AuraEnabled
    public static ProfileLayoutAssignment readProfileLayoutAssignmentsForObject(List<String> objectName) {
        system.debug('objectName'+objectName);
        //string Objectnames = string.valueof(objectName);
        //system.debug('Objectnames'+Objectnames);
        Map<String, String> profileNames = getAllProfileNames();
        Map<Id, String> recordTypeNames = fetchRecordTypeNames(objectName); 
         system.debug('recordTypeNames22'+recordTypeNames);
        Map<String, Map<String, Set<String>>> resData = new Map<String, Map<String, Set<String>>>();
        ProfileLayoutAssignment profileAssignment = new ProfileLayoutAssignment();
        
       // String query = 'SELECT Id, ProfileId, Layout.Name, RecordTypeId, RecordType.Name FROM ProfileLayout WHERE TableEnumOrId =: \'' + objectName + '\' ORDER BY ProfileId';
        String objectNameStr = '\'' + String.join(objectName, '\',\'') + '\'';
        String query = 'SELECT Id, ProfileId, Layout.Name, RecordTypeId, RecordType.Name FROM ProfileLayout WHERE TableEnumOrId IN (' + objectNameStr + ') ORDER BY ProfileId';
        System.debug('Query: ' + query);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v54.0/tooling/query/?q=' + EncodingUtil.urlEncode(query, 'UTF-8'));
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + getSessionId());
        request.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> records = (List<Object>) result.get('records');
            
            if (records != null && !records.isEmpty()) {
                for (Object record : records) {
                    Map<String, Object> recordMap = (Map<String, Object>) record;
                    String profileId = (String) recordMap.get('ProfileId');
                    String profileName = profileNames.get(profileId);
                    String layoutName = (String) ((Map<String, Object>) recordMap.get('Layout')).get('Name');
                    String recordTypeId = (String) recordMap.get('RecordTypeId');
                    String recordTypeName = recordTypeNames.get(recordTypeId);
                    
                    if (profileName != null) {
                        if (!resData.containsKey(profileName)) {
                            resData.put(profileName, new Map<String, Set<String>>());
                        }
                        if (!resData.get(profileName).containsKey(recordTypeName)) {
                            resData.get(profileName).put(recordTypeName, new Set<String>());
                        }
                        resData.get(profileName).get(recordTypeName).add(layoutName);
                    }
                }
            } else {
                System.debug('No profile layout assignments found for object ' + objectName);
            }
        } else {
            System.debug('Failed to retrieve profile layout assignments for object ' + objectName + '. HTTP status code: ' + response.getStatusCode());
        }
        
        // Populate the profileAssignment instance with data
         profileAssignment.objectSelected = String.valueof(objectName);
        profileAssignment.profileName = 'Profile Layout Assignments';
        profileAssignment.profileData = resData;
        
        // Return the populated ProfileLayoutAssignment instance
        system.debug('profileAssignment=='+profileAssignment);
        return profileAssignment;
    }
    
    // Helper method to fetch all profile names in bulk
   
    private static Map<String, String> getAllProfileNames() {
        Map<String, String> profileNames = new Map<String, String>();
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/data/v54.0/query/?q=SELECT+Id,Name+FROM+Profile');
        request.setMethod('GET');
        request.setHeader('Authorization', 'Bearer ' + getSessionId());
        request.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse response = http.send(request);
        
        if (response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> records = (List<Object>) result.get('records');
            
            if (records != null && !records.isEmpty()) {
                for (Object record : records) {
                    Map<String, Object> recordMap = (Map<String, Object>) record;
                    String profileId = (String) recordMap.get('Id');
                    String profileName = (String) recordMap.get('Name');
                    profileNames.put(profileId, profileName);
                }
            }
        } else {
            System.debug('Failed to retrieve profile names. HTTP status code: ' + response.getStatusCode());
        }
        
        return profileNames;
   
  }
}