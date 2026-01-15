@isTest
public class ExternalRolesExcelControllerTest {
    @isTest
    static void testExternalRolesExcelController() {
        // Test data setup if needed
        // ...

        // Create an instance of the controller
        ExternalRolesExcelController controller = new ExternalRolesExcelController();

        // Test the constructor
        System.assertNotEquals(null, controller.xmlheader);
        System.assertNotEquals(null, controller.hierarchyItemList);
        System.assertNotEquals(null, controller.reportInfos);

        // Test the getter methods
        String xmlheaderValue = controller.xmlheader;
        List<HierarchyService.HierarchyItem> hierarchyItemListValue = getMockHierarchyItemList();
        Utils.ReportInfos reportInfosValue = controller.reportInfos;

        // Add assertions based on your specific requirements
        // ...

        // Test other methods if applicable
        // ...
    }

    private static List<HierarchyService.HierarchyItem> getMockHierarchyItemList() {
        // Implement the mock hierarchy list based on your requirements
        // ...

        return new List<HierarchyService.HierarchyItem>();
    }
}