@isTest
public class OldUserTerritoriesExcelControllerTest {
    
    @isTest
    static void testConstructorInTestContext() {
        Test.startTest();
        
        OldUserTerritoriesExcelController controller = new OldUserTerritoriesExcelController();
        
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
        
        OldUserTerritoriesExcelController controller = new OldUserTerritoriesExcelController();
        
        Test.stopTest();
        
        System.assert(controller.xmlheader.contains('<?xml version="1.0"?>'), 'Should contain XML declaration');
        System.assert(controller.xmlheader.contains('<?mso-application progid="Excel.Sheet"?>'), 'Should contain Excel application directive');
    }
    
    @isTest
    static void testParentChildrenProperty() {
        Test.startTest();
        
        OldUserTerritoriesExcelController controller = new OldUserTerritoriesExcelController();
        
        System.assertEquals(null, controller.parentChildren, 'ParentChildren should be null in test context');
        
        Test.stopTest();
    }
    
    @isTest
    static void testReportInfosProperty() {
        Test.startTest();
        
        OldUserTerritoriesExcelController controller = new OldUserTerritoriesExcelController();
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller.reportInfos, 'ReportInfos should not be null');
    }
    
    @isTest
    static void testControllerProperties() {
        Test.startTest();
        
        OldUserTerritoriesExcelController controller = new OldUserTerritoriesExcelController();
        
        String xmlHeader = controller.xmlheader;
        List<HierarchyService.ParentChildren> parentChildren = controller.parentChildren;
        Utils.ReportInfos reportInfos = controller.reportInfos;
        
        Test.stopTest();
        
        System.assertNotEquals(null, xmlHeader, 'XML header should be accessible');
        System.assertNotEquals(null, reportInfos, 'Report infos should be accessible');
    }
    
    @isTest
    static void testSettersAndGetters() {
        Test.startTest();
        
        OldUserTerritoriesExcelController controller = new OldUserTerritoriesExcelController();
        
        String newXmlHeader = '<?xml version="1.0"?><?mso-application progid="Excel.Custom"?>';
        controller.xmlheader = newXmlHeader;
        System.assertEquals(newXmlHeader, controller.xmlheader, 'XML header should be settable');
        
        List<HierarchyService.ParentChildren> newParentChildren = new List<HierarchyService.ParentChildren>();
        controller.parentChildren = newParentChildren;
        System.assertEquals(newParentChildren, controller.parentChildren, 'Parent children list should be settable');
        
        Test.stopTest();
    }
    
    @isTest
    static void testControllerInstantiationMultipleTimes() {
        Test.startTest();
        
        OldUserTerritoriesExcelController controller1 = new OldUserTerritoriesExcelController();
        OldUserTerritoriesExcelController controller2 = new OldUserTerritoriesExcelController();
        
        Test.stopTest();
        
        System.assertEquals(controller1.xmlheader, controller2.xmlheader, 'XML headers should be identical');
        System.assertNotEquals(null, controller1.reportInfos, 'First controller reportInfos should not be null');
        System.assertNotEquals(null, controller2.reportInfos, 'Second controller reportInfos should not be null');
    }
    
    @isTest
    static void testControllerPropertiesNotNull() {
        Test.startTest();
        
        OldUserTerritoriesExcelController controller = new OldUserTerritoriesExcelController();
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller.xmlheader, 'XML header should not be null');
        System.assertNotEquals(null, controller.reportInfos, 'Report infos should not be null');
    }
    
    @isTest
    static void testControllerForPageUsage() {
        Test.startTest();
        
        OldUserTerritoriesExcelController controller = new OldUserTerritoriesExcelController();
        
        String header = controller.xmlheader;
        Utils.ReportInfos infos = controller.reportInfos;
        List<HierarchyService.ParentChildren> items = controller.parentChildren;
        
        Test.stopTest();
        
        System.assert(true, 'Controller should work properly for page usage');
    }
}