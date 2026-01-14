@isTest
public class GenerateAllReportsTest {
    @testSetup
    static void setup() {
        // Create a dummy custom object record for ParentId reference
        SA_Audit__OWD_Sharing_Report__c owd = new SA_Audit__OWD_Sharing_Report__c();
        owd.SA_Audit__Type__c = 'TestType';
        insert owd;
    }

    

    @isTest
    static void testGetExportFile() {
        // Test each option for getExportFile
        List<String> options = new List<String>{
            'option3', 'option4', 'option5', 'option6', 'option7', 'option8', 'option9', 'option10',
            'option13', 'option14', 'option15', 'option16', 'option17', 'option18', 'option19',
            'option21', 'option27', 'option29', 'option30', 'option31', 'option32', 'option33'
        };
        for (String opt : options) {
            Attachment att = GenerateAllReports.getExportFile(opt);
            System.assertNotEquals(null, att, 'Attachment should not be null for ' + opt);
            System.assert(att.Name.endsWith('.xls'), 'Attachment name should end with .xls');
            System.assertNotEquals(null, att.Body, 'Attachment body should not be null');
        }
    }

    @isTest
    static void testStartAndExecute() {
        List<String> ids = new List<String>{'a00xx0000000001'};
        List<String> options = new List<String>{'option3', 'option4'};
        GenerateAllReports batch = new GenerateAllReports(ids, options);

        // Test start
        Iterable<String> iter = batch.start(null);
        List<String> result = new List<String>();
        for (String s : iter) result.add(s);
        System.assertEquals(options, result, 'Start should return the selected options');

        // Test execute
        batch.execute(null, options);
        System.assert(batch.attachmentList.size() == options.size(), 'Should create one attachment per option');
    }
}