public with sharing class TrackFieldHistoryController {
     @AuraEnabled
    public static String xmlheader{ get; set; }
    @AuraEnabled
    public Utils.ReportInfos reportInfos{ get; set; }
    @AuraEnabled
    public static List<FieldData> fieldsWithHistoryTracking { get; set; }
    
    public TrackFieldHistoryController(){
         xmlheader = '<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>';
        reportInfos = Utils.getReportsInfos(); 
        String objects1 ;
        List<String> objectNames =  new List<String>();
        if(!test.isRunningTest()){

        objects1 = ApexPages.currentPage().getParameters().get('selectedOptions');
        
            objectNames = objects1.split(',');
        }else{
            objects1 = '["Force.com - App Subscription User"]';
            objectNames = objects1.split(',');
        }
        fieldsWithHistoryTracking = getFieldHistoryTrackingStatus(objectNames);
        
    }
    
    // Method to get the fields and their IsFieldHistoryTracked status for a given object API name
    @AuraEnabled
    public static List<FieldData> getFieldHistoryTrackingStatus(List<String> objectApiName) {
        // List to store the fields with their history tracking status
        fieldsWithHistoryTracking = new List<FieldData>();
        
        // Query to get all fields and their IsFieldHistoryTracked status for the given object
        List<FieldDefinition> fieldDefinitions = [
            SELECT QualifiedApiName, Label, IsFieldHistoryTracked 
            FROM FieldDefinition 
            WHERE EntityDefinition.QualifiedApiName = :objectApiName
        ];
        
        // Loop through the fields and populate the list of field data
        for(FieldDefinition fieldDef : fieldDefinitions) {
            fieldsWithHistoryTracking.add(new FieldData(
                fieldDef.QualifiedApiName, 
                fieldDef.Label, 
                fieldDef.IsFieldHistoryTracked
            ));
        }
        return fieldsWithHistoryTracking;
    }

    // Inner class to hold field data
    public class FieldData {
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public Boolean isHistoryTracked { get; set; }

        // Constructor
        public FieldData(String apiName, String label, Boolean isHistoryTracked) {
            this.apiName = apiName;
            this.label = label;
            this.isHistoryTracked = isHistoryTracked;
        }
    }
}