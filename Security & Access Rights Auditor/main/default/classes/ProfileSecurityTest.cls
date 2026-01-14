@isTest
private class ProfileSecurityTest { 
    static testMethod void ProfileSecurityTest() {
        ObjectAccess objAcc = new ObjectAccess();
        Test.startTest();
        ProfileSecurity ctrl = new ProfileSecurity(objAcc);
        system.assertEquals(ctrl.isOk, true);
        Test.stopTest();
    }
}