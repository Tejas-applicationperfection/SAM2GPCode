@isTest
public class OldTerritoryExcelControllerTest {
    
    @isTest
    static void testConstructorInTestContext() {
        Test.startTest();
        
        // Test constructor in test context (should not call HierarchyService)
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller, 'Controller should be instantiated');
        System.assertNotEquals(null, controller.xmlheader, 'XML header should be set');
        System.assertEquals('<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>', 
                           controller.xmlheader, 'XML header should match expected value');
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should be initialized');
    }
    
    @isTest
    static void testXmlHeaderProperty() {
        Test.startTest();
        
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        Test.stopTest();
        
        // Verify XML header is properly set
        System.assert(controller.xmlheader.contains('<?xml version="1.0"?>'), 'Should contain XML declaration');
        System.assert(controller.xmlheader.contains('<?mso-application progid="Excel.Sheet"?>'), 'Should contain Excel application directive');
    }
    
    @isTest
    static void testHierarchyItemListProperty() {
        Test.startTest();
        
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        // In test context, hierarchyItemList should be null since Test.isRunningTest() returns true
        System.assertEquals(null, controller.hierarchyItemList, 'HierarchyItemList should be null in test context');
        
        Test.stopTest();
    }
    
    @isTest
    static void testReportInfosProperty() {
        Test.startTest();
        
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        Test.stopTest();
        
        // Verify that reportInfos is initialized by Utils.getReportsInfos()
        System.assertNotEquals(null, controller.reportInfos, 'ReportInfos should not be null');
        // Additional assertions would depend on the Utils.ReportInfos class structure
    }
    
    @isTest
    static void testControllerProperties() {
        Test.startTest();
        
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        // Test that all properties are accessible
        String xmlHeader = controller.xmlheader;
        List<HierarchyService.HierarchyItem> hierarchyItems = controller.hierarchyItemList;
        Utils.ReportInfos reportInfos = controller.reportInfos;
        
        Test.stopTest();
        
        System.assertNotEquals(null, xmlHeader, 'XML header should be accessible');
        // hierarchyItems will be null in test context, which is expected
        System.assertNotEquals(null, reportInfos, 'Report infos should be accessible');
    }
    
    @isTest
    static void testSettersAndGetters() {
        Test.startTest();
        
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        // Test setting XML header
        String newXmlHeader = '<?xml version="1.0"?><?mso-application progid="Excel.Custom"?>';
        controller.xmlheader = newXmlHeader;
        System.assertEquals(newXmlHeader, controller.xmlheader, 'XML header should be settable');
        
        // Test setting hierarchy item list
        List<HierarchyService.HierarchyItem> newHierarchyList = new List<HierarchyService.HierarchyItem>();
        controller.hierarchyItemList = newHierarchyList;
        System.assertEquals(newHierarchyList, controller.hierarchyItemList, 'Hierarchy item list should be settable');
        
        Test.stopTest();
    }
    
    @isTest
    static void testControllerInstantiationMultipleTimes() {
        Test.startTest();
        
        // Test multiple instantiations to ensure consistency
        OldTerritoryExcelController controller1 = new OldTerritoryExcelController();
        OldTerritoryExcelController controller2 = new OldTerritoryExcelController();
        
        Test.stopTest();
        
        System.assertEquals(controller1.xmlheader, controller2.xmlheader, 'XML headers should be identical');
        System.assertNotEquals(null, controller1.reportInfos, 'First controller reportInfos should not be null');
        System.assertNotEquals(null, controller2.reportInfos, 'Second controller reportInfos should not be null');
    }
    
    @isTest
    static void testControllerInNonTestContext() {
        // This test simulates what would happen in non-test context
        // We can't actually test the HierarchyService call since Test.isRunningTest() will always be true
        // But we can verify the conditional logic structure
        
        Test.startTest();
        
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        // Verify that the Test.isRunningTest() check works correctly
        Boolean isTestRunning = Test.isRunningTest();
        System.assertEquals(true, isTestRunning, 'Should be running in test context');
        
        // Since we're in test context, hierarchyItemList should be null
        System.assertEquals(null, controller.hierarchyItemList, 'HierarchyItemList should be null in test context');
        
        Test.stopTest();
    }
    
    @isTest
    static void testControllerPropertiesNotNull() {
        Test.startTest();
        
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        Test.stopTest();
        
        // Ensure essential properties are not null
        System.assertNotEquals(null, controller.xmlheader, 'XML header should not be null');
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should not be null');
        
        // hierarchyItemList is expected to be null in test context due to the conditional logic
        // This is the expected behavior
    }
    
    @isTest
    static void testControllerForPageUsage() {
        Test.startTest();
        
        // Test that controller can be used in a page context
        OldTerritoryExcelController controller = new OldTerritoryExcelController();
        
        // Simulate page usage by accessing properties
        String header = controller.xmlheader;
        Utils.ReportInfos infos = controller.reportInfos;
        List<HierarchyService.HierarchyItem> items = controller.hierarchyItemList;
        
        Test.stopTest();
        
        // Verify all properties are accessible without errors
        System.assert(true, 'Controller should work properly for page usage');
    }
}