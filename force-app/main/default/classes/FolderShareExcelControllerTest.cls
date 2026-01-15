@isTest
private class FolderShareExcelControllerTest {
    @testSetup
    static void setup() {
        SA_Audit__Helper__c helper = new SA_Audit__Helper__c();
        helper.SA_Audit__JobId__c = 'TEST_JOB_ID';
        helper.SA_Audit__ResultBody_1__c = 'Folder1~#~Read~#~User~#~UserA/nFolder2~#~Write~#~Group~#~GroupA';
        insert helper;
    }

    @isTest
    static void testControllerWithHelperRecord() {
        ApexPages.currentPage().getParameters().put('jobId', 'TEST_JOB_ID');
        Test.startTest();
        FolderShareExcelController ctrl = new FolderShareExcelController();
        Test.stopTest();

        System.assertEquals('<?xml version="1.0"?><?mso-application progid="Excel.Sheet"?>', ctrl.xmlheader);
        System.assertEquals('TEST_JOB_ID', ctrl.jobId);
        System.assertNotEquals(null, ctrl.reportInfos);
        System.assertNotEquals(null, ctrl.allFolderList);
        System.assert(ctrl.allFolderList.size() > 0, 'allFolderList should not be empty');
        System.assert(ctrl.allFolderList[0].size() == 2, 'Should parse two folders from the result body');

        FolderShareExcelController.Folder folder1 = ctrl.allFolderList[0][0];
        System.assertEquals('Folder1', folder1.name);
        System.assertEquals('Read', folder1.accessType);
        System.assertEquals('User', folder1.shareType);
        System.assertEquals('UserA', folder1.sharedWith);

        FolderShareExcelController.Folder folder2 = ctrl.allFolderList[0][1];
        System.assertEquals('Folder2', folder2.name);
        System.assertEquals('Write', folder2.accessType);
        System.assertEquals('Group', folder2.shareType);
        System.assertEquals('GroupA', folder2.sharedWith);
    }

    @isTest
    static void testControllerWithNoHelperRecord() {
        ApexPages.currentPage().getParameters().put('jobId', 'NO_RECORD');
        Test.startTest();
        FolderShareExcelController ctrl = new FolderShareExcelController();
        Test.stopTest();
        System.assertNotEquals(null, ctrl.allFolderList);
    }
}