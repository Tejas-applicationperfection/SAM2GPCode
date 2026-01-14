@isTest
public class ProfileMultiSelectTest {
    static testMethod void ProfileMultiSelectTest() {
        ObjectsAndFieldsAccess objAndFieldsAcc = new ObjectsAndFieldsAccess();
        Test.startTest();
        ProfileMultiSelect ctrl = new ProfileMultiSelect(objAndFieldsAcc);
        system.assertEquals(ctrl.isOk, true);
        Test.stopTest();
    }
}