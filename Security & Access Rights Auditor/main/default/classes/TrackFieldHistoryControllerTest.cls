@isTest
public class TrackFieldHistoryControllerTest {

    @isTest
    static void testConstructor() {
        Test.startTest();
        
        // Test non-test context
        ApexPages.currentPage().getParameters().put('selectedOptions', 'Account,Contact');
        TrackFieldHistoryController controller = new TrackFieldHistoryController();
        
        // Verify static and instance fields
        System.assertNotEquals(null, TrackFieldHistoryController.xmlheader, 'XML header should be initialized.');
        System.assertNotEquals(null, TrackFieldHistoryController.fieldsWithHistoryTracking, 'Fields with history tracking should be initialized.');
        System.assertNotEquals(null, controller.reportInfos, 'ReportInfos should be initialized.');
        
        Test.stopTest();
    }

 

    @isTest
    static void testFieldData() {
        Test.startTest();
        
        TrackFieldHistoryController.FieldData fieldData = new TrackFieldHistoryController.FieldData(
            'Name',
            'Name',
            true
        );
        
        // Verify field data initialization
        System.assertEquals('Name', fieldData.apiName, 'API name should match.');
        System.assertEquals('Name', fieldData.label, 'Label should match.');
        System.assertEquals(true, fieldData.isHistoryTracked, 'History tracked status should match.');
        
        Test.stopTest();
    }
    
    @isTest
    static void testConstructorWithEmptyParameters() {
        Test.startTest();
        
        // Simulate empty `selectedOptions` parameter
        ApexPages.currentPage().getParameters().put('selectedOptions', '');
        TrackFieldHistoryController controller = new TrackFieldHistoryController();
        
        // Verify that fieldsWithHistoryTracking is handled correctly
        System.assertNotEquals(null, TrackFieldHistoryController.fieldsWithHistoryTracking, 'Fields with history tracking should be initialized.');
        
        Test.stopTest();
    }

    @isTest
    static void testGetFieldHistoryTrackingStatusEmptyObjectList() {
        Test.startTest();
        
        // Test with an empty object list
        List<String> objectApiNames = new List<String>{};
        List<TrackFieldHistoryController.FieldData> result = TrackFieldHistoryController.getFieldHistoryTrackingStatus(objectApiNames);
        
        Test.stopTest();
        
        // Validate the results
        System.assertNotEquals(null, result, 'Result should not be null.');
        System.assert(result.isEmpty(), 'Result should be empty for no objects.');
    }
}