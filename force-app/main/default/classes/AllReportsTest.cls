@isTest
public with sharing class AllReportsTest {
    public static testmethod void testRolesExcelController() {
    	RolesExcelController ctrl = new RolesExcelController();
    	system.assert(ctrl.reportInfos != null);
    }
    
    public static testmethod void testUserRoleExcelController() {
    	UserRoleExcelController ctrl = new UserRoleExcelController();
    	system.assert(ctrl.reportInfos != null);
    }
    
    
    public static testmethod void testUserTerritoryExcelController() {
    	UserTerritoryExcelController ctrl = new UserTerritoryExcelController();
    	system.assert(ctrl.reportInfos != null);
    }
    
    public static testmethod void testTerritoriesExcelController() {
    	TerritoriesExcelController ctrl = new TerritoriesExcelController();
    	system.assert(ctrl.reportInfos != null);
    }
    public static testmethod void testOldUserTerritoriesExcelController() {
    	OldUserTerritoriesExcelController ctrl = new OldUserTerritoriesExcelController();
    	system.assert(ctrl.reportInfos != null);
    }
    public static testmethod void testPermissionSetsWithUsersExcelController() {
    	PermissionSetsWithUsersExcelController ctrl = new PermissionSetsWithUsersExcelController();
    	system.assert(ctrl.reportInfos != null);
    }
    public static testmethod void testOldTerritoryExcelController() {
    	OldTerritoryExcelController ctrl = new OldTerritoryExcelController();
    	system.assert(ctrl.reportInfos != null);
    }
    public static testmethod void testUserProfileAndRoleExcelController(){
        Test.startTest();
    	UserProfileAndRoleExcelController ctrl = new UserProfileAndRoleExcelController();
    	System.assert(ctrl.reportInfos != null);
        Test.stopTest();
    }
    public static testmethod void testUserProfileExcelController(){
        Test.startTest();
    	UserProfileExcelController ctrl = new UserProfileExcelController();
    	System.assert(ctrl.reportInfos != null);
        Test.stopTest();
    }
    public static testmethod void testUserPermissionSetExcelController(){ 
        Test.startTest();
        UserPermissionSetExcelController ctrl = new UserPermissionSetExcelController();
        System.assert(ctrl.reportInfos != null);
        Test.stopTest();
    }
    public static testmethod void testProfileWrapper(){
        Test.startTest();
        ProfileWrapper ctrl = new ProfileWrapper();
        ctrl.profileName = 'Test1';
        ctrl.create = true;
        ctrl.read = true;
        ctrl.edit = true;
        ctrl.del = true;
        ctrl.modifyAllData = true;
        ctrl.modifyAllRecords = true;
        ctrl.viewAllRecords = true;
        ctrl.errorMSG = 'Do not have Access';
        System.assertEquals('Test1', ctrl.profileName);
        System.assertEquals(true, ctrl.create);
        System.assertEquals(true, ctrl.read);
        System.assertEquals(true, ctrl.edit);
        System.assertEquals(true, ctrl.del);
        System.assertEquals(true, ctrl.modifyAllData);
        System.assertEquals(true, ctrl.modifyAllRecords);
        System.assertEquals(true, ctrl.viewAllRecords);
        System.assertEquals('Do not have Access', ctrl.errorMSG);
        Test.stopTest();
    }
    public static testmethod void testUtilsOrgIsAccessibleMethod(){
        Test.startTest();
        Utils ctrl = new Utils();
        Utils.ReportInfos reportInfos = Utils.getReportsInfos();
        System.assertNotEquals(null, reportInfos);
        Test.stopTest();
    }
    
  
    
     
}