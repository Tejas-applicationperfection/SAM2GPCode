@isTest
private class WhyHavingRightsTest {
    static testMethod void WhyHavingRightsTest() {
        RecordAccess recAcc = new RecordAccess();
        Test.startTest();
        WhyHavingRights ctrl = new WhyHavingRights(recAcc);
        system.assertEquals(ctrl.isOk, true);
        Test.stopTest();
    }
}