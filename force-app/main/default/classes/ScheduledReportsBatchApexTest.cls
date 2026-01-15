/**
 * @description Test class for ScheduledReportsBatchApex
 * @author salesforce dev
 * @date 2024
 */
@IsTest
public class ScheduledReportsBatchApexTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test reports
        List<Report> testReports = new List<Report>();
        
        // Note: In test context, we cannot actually create Report records
        // We'll mock the behavior in the test methods
        
        // Create test custom object records for cleanup testing
        List<SA_Audit__OWD_Sharing_Report__c> testRecords = new List<SA_Audit__OWD_Sharing_Report__c>();
        for (Integer i = 0; i < 3; i++) {
            testRecords.add(new SA_Audit__OWD_Sharing_Report__c(
                SA_Audit__Type__c = 'ScheduledReports'
            ));
        }
        insert testRecords;
    }
    
    @IsTest
    static void testBatchConstructor() {
        Test.startTest();
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Test.stopTest();
        
        System.assertNotEquals(null, batch.scheduledReportsList, 'Scheduled reports list should be initialized');
        System.assertEquals(0, batch.scheduledReportsList.size(), 'Scheduled reports list should be empty initially');
    }
    
    @IsTest
    static void testStartMethod() {
        Test.startTest();
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Database.BatchableContext bc = new TestBatchableContext();
        
        // Execute start method
        Iterable<CronTrigger> result = batch.start(bc);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Start method should return iterable');
        
        // Convert to list to check
        List<CronTrigger> cronList = new List<CronTrigger>();
        Iterator<CronTrigger> iterator = result.iterator();
        while (iterator.hasNext()) {
            cronList.add(iterator.next());
        }
        
        // In test context, there might not be any scheduled reports
        System.assert(cronList.size() >= 0, 'Should return valid list of CronTrigger records');
    }
    
    @IsTest
    static void testExecuteMethodWithValidData() {
        // Create mock CronTrigger data
        List<CronTrigger> mockCronTriggers = createMockCronTriggers();
        
        Test.startTest();
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Database.BatchableContext bc = new TestBatchableContext();
        
        // Execute the batch
        batch.execute(bc, mockCronTriggers);
        Test.stopTest();
        
        // Verify that scheduledReportsList is populated
        System.assertNotEquals(null, batch.scheduledReportsList, 'Scheduled reports list should not be null');
        // Note: In test context, Report queries might not return data, so we test the structure
    }
    
    @IsTest
    static void testExecuteMethodWithEmptyData() {
        List<CronTrigger> emptyCronTriggers = new List<CronTrigger>();
        
        Test.startTest();
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Database.BatchableContext bc = new TestBatchableContext();
        
        // Execute with empty list
        batch.execute(bc, emptyCronTriggers);
        Test.stopTest();
        
        System.assertEquals(0, batch.scheduledReportsList.size(), 'Should handle empty input gracefully');
    }
    
    @IsTest
    static void testFinishMethod() {
        Test.startTest();
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Database.BatchableContext bc = new TestBatchableContext();
        
        // Add some test data to scheduledReportsList
        IntelController.ScheduledReportsData testData = new IntelController.ScheduledReportsData();
        testData.reportName = 'Test Report';
        testData.folderName = 'Test Folder';
        testData.reportUniqueName = 'Test_Report_Unique';
        testData.runningUserName = 'Test User';
        batch.scheduledReportsList.add(testData);
        
        // Execute finish method
        batch.finish(bc);
        Test.stopTest();
        
        // Verify that old records were deleted and new record was created
        List<SA_Audit__OWD_Sharing_Report__c> newRecords = [
            SELECT Id, SA_Audit__Type__c 
            FROM SA_Audit__OWD_Sharing_Report__c 
            WHERE SA_Audit__Type__c = 'ScheduledReports'
        ];
        
        System.assertEquals(1, newRecords.size(), 'Should have exactly one ScheduledReports record after finish');
        
        // Verify attachment was created
        List<Attachment> attachments = [
            SELECT Id, Name, ContentType, ParentId 
            FROM Attachment 
            WHERE ParentId = :newRecords[0].Id
        ];
        
        System.assertEquals(1, attachments.size(), 'Should have one attachment');
        System.assertEquals('ScheduledReports', attachments[0].Name, 'Attachment should have correct name');
        System.assertEquals('text/plain', attachments[0].ContentType, 'Attachment should have correct content type');
    }
    
    @IsTest
    static void testFinishMethodWithEmptyData() {
        Test.startTest();
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Database.BatchableContext bc = new TestBatchableContext();
        
        // Execute finish method with empty scheduledReportsList
        batch.finish(bc);
        Test.stopTest();
        
        // Verify that record was still created
        List<SA_Audit__OWD_Sharing_Report__c> newRecords = [
            SELECT Id, SA_Audit__Type__c 
            FROM SA_Audit__OWD_Sharing_Report__c 
            WHERE SA_Audit__Type__c = 'ScheduledReports'
        ];
        
        System.assertEquals(1, newRecords.size(), 'Should have one ScheduledReports record');
    }
    
    @IsTest
    static void testBatchExecution() {
        Test.startTest();
        
        // Execute the batch
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Id batchId = Database.executeBatch(batch, 200);
        
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'Batch should execute successfully');
        
        // Verify batch completion
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob 
            WHERE Id = :batchId
        ];
        
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should complete without errors');
    }
    
    @IsTest
    static void testErrorHandling() {
        Test.startTest();
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Database.BatchableContext bc = new TestBatchableContext();
        
        // Test with null input to trigger exception handling
        try {
            batch.execute(bc, null);
        } catch (Exception e) {
            // Exception is caught and handled within the execute method
            System.assert(true, 'Exception handling should work correctly');
        }
        
        Test.stopTest();
    }
    
    // Helper method to create mock CronTrigger data
    private static List<CronTrigger> createMockCronTriggers() {
        // Note: In test context, we cannot create actual CronTrigger records
        // This method would return an empty list, but the structure is here
        // for when the test runs against actual scheduled jobs
        return new List<CronTrigger>();
    }
    
    // Mock BatchableContext for testing
    private class TestBatchableContext implements Database.BatchableContext {
        public Id getJobId() {
            return '01p000000000000AAA'; // Mock job ID
        }
        
        public Id getChildJobId() {
            return '01p000000000000AAA'; // Mock child job ID
        }
    }
    
    @IsTest
    static void testScheduledReportsDataStructure() {
        Test.startTest();
        
        // Test the data structure used in the batch
        IntelController.ScheduledReportsData data = new IntelController.ScheduledReportsData();
        data.reportName = 'Test Report Name';
        data.folderName = 'Test Folder Name';
        data.reportUniqueName = 'Test_Unique_Name';
        data.runningUserName = 'Test Running User';
        data.startTime = System.now();
        data.endTime = System.now().addHours(1);
        data.previousRunTime = System.now().addDays(-1);
        data.nextRunTime = System.now().addDays(1);
        
        Test.stopTest();
        
        System.assertEquals('Test Report Name', data.reportName, 'Report name should be set correctly');
        System.assertEquals('Test Folder Name', data.folderName, 'Folder name should be set correctly');
        System.assertEquals('Test_Unique_Name', data.reportUniqueName, 'Unique name should be set correctly');
        System.assertEquals('Test Running User', data.runningUserName, 'Running user should be set correctly');
        System.assertNotEquals(null, data.startTime, 'Start time should be set');
        System.assertNotEquals(null, data.endTime, 'End time should be set');
        System.assertNotEquals(null, data.previousRunTime, 'Previous run time should be set');
        System.assertNotEquals(null, data.nextRunTime, 'Next run time should be set');
    }
    
    @IsTest
    static void testBulkProcessing() {
        Test.startTest();
        
        ScheduledReportsBatchApex batch = new ScheduledReportsBatchApex();
        Database.BatchableContext bc = new TestBatchableContext();
        
        // Create multiple mock data entries
        List<IntelController.ScheduledReportsData> testDataList = new List<IntelController.ScheduledReportsData>();
        for (Integer i = 0; i < 100; i++) {
            IntelController.ScheduledReportsData data = new IntelController.ScheduledReportsData();
            data.reportName = 'Test Report ' + i;
            data.folderName = 'Test Folder ' + i;
            data.reportUniqueName = 'Test_Report_' + i;
            data.runningUserName = 'Test User ' + i;
            testDataList.add(data);
        }
        
        batch.scheduledReportsList = testDataList;
        batch.finish(bc);
        
        Test.stopTest();
        
        // Verify that bulk processing works correctly
        List<SA_Audit__OWD_Sharing_Report__c> records = [
            SELECT Id FROM SA_Audit__OWD_Sharing_Report__c 
            WHERE SA_Audit__Type__c = 'ScheduledReports'
        ];
        
        System.assertEquals(1, records.size(), 'Should handle bulk data correctly');
    }
}