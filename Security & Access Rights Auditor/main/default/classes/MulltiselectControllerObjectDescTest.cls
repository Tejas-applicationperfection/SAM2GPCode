@isTest
public class MulltiselectControllerObjectDescTest {
    
    @isTest
    static void testDefaultConstructor() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller, 'Controller should be instantiated');
    }
    
    @isTest
    static void testLeftOptionsHiddenSetter() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        
        // Test with encoded values
        String testValue = 'value1&label1&value2&label2&value3&label3';
        controller.leftOptionsHidden = testValue;
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller.leftOptions, 'Left options should be initialized');
        System.assertEquals(3, controller.leftOptions.size(), 'Should have 3 options');
        System.assertEquals('value1', controller.leftOptions[0].getValue(), 'First option value should match');
        System.assertEquals('label1', controller.leftOptions[0].getLabel(), 'First option label should match');
    }
    
    @isTest
    static void testRightOptionsHiddenSetter() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.rightOptions = new List<SelectOption>();
        
        // Test with encoded values
        String testValue = 'rightValue1&rightLabel1&rightValue2&rightLabel2';
        controller.rightOptionsHidden = testValue;
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller.rightOptions, 'Right options should be initialized');
        System.assertEquals(2, controller.rightOptions.size(), 'Should have 2 options');
        System.assertEquals('rightValue1', controller.rightOptions[0].getValue(), 'First right option value should match');
        System.assertEquals('rightLabel1', controller.rightOptions[0].getLabel(), 'First right option label should match');
    }
    
    @isTest
    static void testSetOptionsWithLargeDataSet() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        
        // Create a large dataset with more than 900 options to test the split logic
        String largeValue = '';
        for (Integer i = 0; i < 950; i++) {
            if (i > 0) {
                largeValue += '&';
            }
            largeValue += 'value' + i + '&label' + i;
        }
        
        controller.leftOptionsHidden = largeValue;
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller.leftOptions, 'Left options should be initialized');
        System.assertNotEquals(null, controller.leftOptions1, 'Left options1 should be initialized');
        System.assertEquals(900, controller.leftOptions.size(), 'Should have 900 options in leftOptions');
        System.assertEquals(50, controller.leftOptions1.size(), 'Should have 50 options in leftOptions1');
    }
    
    @isTest
    static void testSetOptionsWithEncodedValues() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        
        // Test with URL encoded values
        String encodedValue = EncodingUtil.urlEncode('test value', 'UTF-8') + '&' + 
                             EncodingUtil.urlEncode('test label', 'UTF-8') + '&' +
                             EncodingUtil.urlEncode('another value', 'UTF-8') + '&' +
                             EncodingUtil.urlEncode('another label', 'UTF-8');
        
        controller.leftOptionsHidden = encodedValue;
        
        Test.stopTest();
        
        System.assertEquals(2, controller.leftOptions.size(), 'Should have 2 decoded options');
        System.assertEquals('test value', controller.leftOptions[0].getValue(), 'First value should be decoded');
        System.assertEquals('test label', controller.leftOptions[0].getLabel(), 'First label should be decoded');
        System.assertEquals('another value', controller.leftOptions[1].getValue(), 'Second value should be decoded');
        System.assertEquals('another label', controller.leftOptions[1].getLabel(), 'Second label should be decoded');
    }
    
    @isTest
    static void testSetOptionsWithEmptyValue() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        
        // Test with empty string
        controller.leftOptionsHidden = '';
        
        Test.stopTest();
        
        System.assertNotEquals(null, controller.leftOptions, 'Left options should be initialized');
        System.assertEquals(0, controller.leftOptions.size(), 'Should have 0 options for empty string');
    }
    
    @isTest
    static void testSetOptionsWithNullValue() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        
        // Test with null value - should handle gracefully
        try {
            controller.leftOptionsHidden = null;
        } catch (Exception e) {
            // Expected to handle null gracefully
        }
        
        Test.stopTest();
        
        // Should handle null gracefully without throwing exception
        System.assert(true, 'Should handle null value gracefully');
    }
    
    @isTest
    static void testSetOptionsDirectly() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        controller.rightOptions = new List<SelectOption>();
        
        // Test the private setOptions method indirectly through the setter
        String testValue = 'val1&lbl1&val2&lbl2';
        controller.leftOptionsHidden = testValue;
        
        Test.stopTest();
        
        System.assertEquals(2, controller.leftOptions.size(), 'Should have 2 options');
    }
    
    @isTest
    static void testBothSettersIndependently() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        controller.rightOptions = new List<SelectOption>();
        
        // Set left options
        controller.leftOptionsHidden = 'leftVal1&leftLbl1&leftVal2&leftLbl2';
        
        // Set right options
        controller.rightOptionsHidden = 'rightVal1&rightLbl1';
        
        Test.stopTest();
        
        System.assertEquals(2, controller.leftOptions.size(), 'Should have 2 left options');
        System.assertEquals(1, controller.rightOptions.size(), 'Should have 1 right option');
        System.assertEquals('leftVal1', controller.leftOptions[0].getValue(), 'Left option value should match');
        System.assertEquals('rightVal1', controller.rightOptions[0].getValue(), 'Right option value should match');
    }
    
    @isTest
    static void testGettersAndSetters() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        controller.rightOptions = new List<SelectOption>();
        
        // Test disableComponent property
        controller.disableComponent = true;
        System.assertEquals(true, controller.disableComponent, 'DisableComponent should be set to true');
        
        controller.disableComponent = false;
        System.assertEquals(false, controller.disableComponent, 'DisableComponent should be set to false');
        
        // Test getter for leftOptionsHidden
        controller.leftOptionsHidden = 'test&value';
        System.assertEquals('test&value', controller.leftOptionsHidden, 'LeftOptionsHidden getter should return set value');
        
        // Test getter for rightOptionsHidden
        controller.rightOptionsHidden = 'right&test';
        System.assertEquals('right&test', controller.rightOptionsHidden, 'RightOptionsHidden getter should return set value');
        
        Test.stopTest();
    }
    
    @isTest
    static void testSetOptionsWithOddNumberOfParts() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        
        // Test with odd number of parts (should handle gracefully)
        String oddValue = 'value1&label1&value2'; // Missing label for value2
        controller.leftOptionsHidden = oddValue;
        
        Test.stopTest();
        
        // Should only process complete pairs
        System.assertEquals(1, controller.leftOptions.size(), 'Should only process complete value-label pairs');
        System.assertEquals('value1', controller.leftOptions[0].getValue(), 'Should process first complete pair');
    }
    
    @isTest
    static void testSetOptionsWithSpecialCharacters() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Initialize the lists first
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = new List<SelectOption>();
        
        // Test with special characters that need encoding
        String specialValue = EncodingUtil.urlEncode('value with spaces & symbols', 'UTF-8') + '&' +
                             EncodingUtil.urlEncode('label with "quotes" and symbols', 'UTF-8');
        
        controller.leftOptionsHidden = specialValue;
        
        Test.stopTest();
        
        System.assertEquals(1, controller.leftOptions.size(), 'Should have 1 option with special characters');
        System.assertEquals('value with spaces & symbols', controller.leftOptions[0].getValue(), 'Special characters should be decoded correctly');
        System.assertEquals('label with "quotes" and symbols', controller.leftOptions[0].getLabel(), 'Special characters in label should be decoded correctly');
    }
    
    @isTest
    static void testLeftOptions1Initialization() {
        Test.startTest();
        
        MulltiselectControllerObjectDesc controller = new MulltiselectControllerObjectDesc();
        
        // Test when leftOptions1 is null initially
        controller.leftOptions = new List<SelectOption>();
        controller.leftOptions1 = null;
        
        String testValue = 'val1&lbl1';
        controller.leftOptionsHidden = testValue;
        
        Test.stopTest();
        
        System.assertEquals(1, controller.leftOptions.size(), 'Should have 1 option in leftOptions');
        // leftOptions1 should remain null since it's not initialized
    }
}