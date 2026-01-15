@isTest
public class InactiveUserPSetExcelControllerTest {
    
    @isTest
    static void testInactiveUserPermissionSetExcelController() {
        // Start the test context
        Test.startTest();

        // Instantiate the controller
        InactiveUserPermissionSetExcelController controller = new InactiveUserPermissionSetExcelController();

        // Stop the test context
        Test.stopTest();
        
        // Step 1: Validate xmlheader initialization
        System.assertEquals('<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>', controller.xmlheader, 'The XML header should be correctly initialized.');

        // Step 2: Validate that reportInfos is initialized (assuming getReportsInfos returns non-null data)
        System.assertNotEquals(null, controller.reportInfos, 'The reportInfos should be initialized.');
        
        // Step 3: Validate other AuraEnabled properties for their default values
        System.assertEquals(null, controller.reportBody, 'The reportBody should initially be null.');
        System.assertEquals(null, controller.jobId, 'The jobId should initially be null.');
        System.assertEquals(null, controller.value, 'The value should initially be null.');
        
        // Step 4: Validate the allParentChildrens property is initialized
        System.assertNotEquals(null, controller.allParentChildrens, 'The allParentChildrens list should be initialized.');
        System.assert(controller.allParentChildrens.size() > 0, 'The allParentChildrens list should contain data.');

        // Step 5: Check if each sublist in allParentChildrens has the correct size
        for (List<HierarchyService.ParentChildren> parentChildrenList : controller.allParentChildrens) {
            System.assert(parentChildrenList.size() <= 1000, 'Each list in allParentChildrens should have a maximum of 1000 items.');
        }
        
        // Step 6: Validate batch handling in `allParentChildrens`
        Integer totalParentChildrenCount = 0;
        for (List<HierarchyService.ParentChildren> parentChildrenList : controller.allParentChildrens) {
            totalParentChildrenCount += parentChildrenList.size();
        }
        
        System.assert(totalParentChildrenCount > 0, 'The total count of ParentChildren items should be greater than 0.');
        
        // Step 7: Edge Case Check - Verify handling when fewer than 1000 ParentChildren records are available
        if (controller.allParentChildrens.size() == 1) {
            System.assert(controller.allParentChildrens[0].size() <= 1000, 'If only one list, its size should still be within limits.');
        }
    }
}