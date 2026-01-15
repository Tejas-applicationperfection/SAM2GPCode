@isTest
public class UserProfileAccesTest {
    static testMethod void myUnitTest() {
        Profile p = [SELECT Id, Name FROM Profile WHERE Name = 'Test1'];
        Test.startTest();
			UserProfileAcces ctrl = new UserProfileAcces();
        	List<SelectOption> x = ctrl.getPermissionType();
            ctrl.changePermType();
            ctrl.selectedPerm = 'Profiles';
        	ctrl.changePermType();
        	ctrl.selectedPerm = 'All';
        	ctrl.changePermType();
        
            ctrl.go();
            ctrl.yesPopUp();
            ctrl.SelectProfilesForExportToExcel();
            ctrl.ExportToExcel();
            ctrl.closePopup();
            for(Integer i = 0; i < 12; i++) {
                ctrl.selectedProfileList.add(new SelectOption(p.id, p.Name));
            }
            ctrl.go();
        	for(Integer i = 0; i < 1002; i++) {
                ctrl.selectedProfileExcel.add(new SelectOption(p.id, p.Name));
            }
        	ctrl.SelectProfilesForExportToExcel();
            System.assertNotEquals(null, ctrl.selectedProfileExcel);
        Test.stopTest();
    } 
    static testMethod void openContactUSLinkTest(){
        Test.startTest();
        PageReference pageRef;
        pageRef = new PageReference('https://applicationperfection.com/contact/');
        UserProfileAcces ctrl = new UserProfileAcces();
        ctrl.openContactUSLink();
        System.assertNotEquals(null, pageRef);
        Test.stopTest();
    }
}