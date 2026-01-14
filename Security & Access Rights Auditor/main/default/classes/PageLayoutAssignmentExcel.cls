public with sharing class PageLayoutAssignmentExcel {
    
    @AuraEnabled 
    public List<layoutWrapper> layoutWrapperWrapperList { get; set; }
    @AuraEnabled
    public static String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public List<String> objectNames{ get; set; }
    @AuraEnabled
    public static String getSessionId() {
       return UserInfo.getSessionId();
        //return 'callout:SA_Audit__Tooling_API_Creds' ;
    }
    
    public class layoutWrapper {
        @AuraEnabled 
        public string profileName { get; set; }
        @AuraEnabled 
        public string layoutName { get; set; }
        @AuraEnabled 
        public string recordTypeName { get; set; }
        
        public layoutWrapper(string profileName, string layoutName, string rtName) {
            this.profileName = profileName;
            this.layoutName = layoutName;
            this.recordTypeName = rtName;
        }
    }
    
    public PageLayoutAssignmentExcel(){
        layoutWrapperWrapperList = new List<layoutWrapper>();
        xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
        
        String objects1 = ApexPages.currentPage().getParameters().get('selectedOptions');
        objectNames = objects1.split(',');
        layoutWrapperWrapperList = readProfileLayoutAssignmentsForObject(objectNames);
    }
  
    
    private static Map<Id, String> fetchRecordTypeNames(List<String> objectName) {
        Map<Id, String> recordTypeNames = new Map<Id, String>();
        for (RecordType rt : [SELECT Id, Name FROM RecordType WHERE SObjectType IN :objectName]) {
            recordTypeNames.put(rt.Id, rt.Name);
        }
        System.debug('recordTypeNames'+recordTypeNames);
        return recordTypeNames;
    }
    
    @AuraEnabled
    public static List<layoutWrapper> readProfileLayoutAssignmentsForObject(List<String> objectName) {
        System.debug('objectName' + objectName);
        
        List<layoutWrapper> layoutWrapperWrapperList = new List<layoutWrapper>();
        Map<String, String> profileNames = getAllProfileNames();
        Map<Id, String> recordTypeNames = fetchRecordTypeNames(objectName); 
        System.debug('recordTypeNames' + recordTypeNames);
        
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
                        layoutWrapperWrapperList.add(new layoutWrapper(profileName, layoutName, recordTypeName));
                    }
                }
            } else {
                System.debug('No profile layout assignments found for object ' + objectName);
            }
        } else {
            System.debug('Failed to retrieve profile layout assignments for object ' + objectName + '. HTTP status code: ' + response.getStatusCode());
        }
        system.debug('layoutWrapperWrapperList='+layoutWrapperWrapperList);
        return layoutWrapperWrapperList;
    }
   
    private static Map<String, String> getAllProfileNames() {
    Map<String, String> profileNames = new Map<String, String>();

    // Perform SOQL query to fetch Profile names
    for (Profile profile : [SELECT Id, Name FROM Profile Limit 6000]) {
        profileNames.put(profile.Id, profile.Name);
    }

    return profileNames;
}

}