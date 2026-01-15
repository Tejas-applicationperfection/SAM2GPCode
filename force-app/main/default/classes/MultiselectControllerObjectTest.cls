@isTest
public class MultiselectControllerObjectTest { 
    static testMethod void myUnitTest() {
        MulltiselectControllerObjectDesc ctrl = new MulltiselectControllerObjectDesc();
        ctrl.leftOptions = new List<SelectOption>();
        ctrl.rightOptions = new List<SelectOption>();
        
        ctrl.leftOptionsHidden = 'Account&AccountLabel';
        ctrl.rightOptionsHidden = 'Account&AccountLabel';
		system.assertequals(ctrl.rightOptions[0].getValue(), 'Account');
        system.assertequals(ctrl.rightOptions[0].getLabel(), 'AccountLabel');
        system.assertequals(ctrl.leftOptions[0].getValue(), 'Account');
        system.assertequals(ctrl.leftOptions[0].getLabel(), 'AccountLabel');
    }

}