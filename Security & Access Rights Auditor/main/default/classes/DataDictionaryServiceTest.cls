@IsTest
public class DataDictionaryServiceTest {

    @TestSetup
    static void setupTestData() {
        // Setup any test data if required
    }


    

    @IsTest
    static void testCustomFieldConstructor() {
        MetadataService.CustomField customField = new MetadataService.CustomField();
        customField.fullName = 'TestField__c';
        customField.label = 'Test Field Label';

        DataDictionaryService.CustomField testField = new DataDictionaryService.CustomField(customField);
        System.assertEquals('TestField__c', testField.fullName, 'Field fullName should match');
        System.assertEquals('Test Field Label', testField.label, 'Field label should match');
    }

    @IsTest
    static void testValueSetConstructor() {
        MetadataService.ValueSet valueSet = new MetadataService.ValueSet();
        valueSet.controllingField = 'ControllingField__c';
        valueSet.restricted = true;
        valueSet.valueSetName = 'ValueSet1';

        DataDictionaryService.ValueSet testValueSet = new DataDictionaryService.ValueSet(valueSet);
        System.assertEquals('ControllingField__c', testValueSet.controllingField, 'Controlling field should match');
        System.assertEquals(true, testValueSet.restricted, 'Restricted value should match');
        System.assertEquals('ValueSet1', testValueSet.valueSetName, 'ValueSet name should match');
    }

    @IsTest
    static void testValueSetValuesDefinitionConstructor() {
        MetadataService.ValueSetValuesDefinition valueSetDef = new MetadataService.ValueSetValuesDefinition();
        valueSetDef.sorted = true;

        MetadataService.CustomValue customValue = new MetadataService.CustomValue();
        customValue.fullName = 'TestValue';

        valueSetDef.value = new MetadataService.CustomValue[] { customValue };

        DataDictionaryService.ValueSetValuesDefinition testDef = new DataDictionaryService.ValueSetValuesDefinition(valueSetDef);
        System.assertEquals(true, testDef.sorted, 'Sorted value should match');
        System.assertEquals(1, testDef.value.size(), 'There should be one custom value');
        System.assertEquals('TestValue', testDef.value[0].fullName, 'Custom value fullName should match');
    }

    @IsTest
    static void testCustomValueConstructor() {
        MetadataService.CustomValue customValue = new MetadataService.CustomValue();
        customValue.fullName = 'TestCustomValue';

        DataDictionaryService.CustomValue testCustomValue = new DataDictionaryService.CustomValue(customValue);
        System.assertEquals('TestCustomValue', testCustomValue.fullName, 'Custom value fullName should match');
    }

    // Cleanup
    @IsTest
    static void testCleanup() {
        // Ensure objMap is cleared out
        DataDictionaryService.objMap = null;
        System.assertEquals(null, DataDictionaryService.objMap, 'objMap should be null after cleanup');
    }
}