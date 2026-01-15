({
    
    /* eslint-disable no-console */
    /* eslint-disable no-unused-vars */
    doInit : function(component, event, helper) {
        // Check feature access on component initialization
        var action = component.get("c.PaidFeatureAccess");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.hasAccess", response.getReturnValue());
            } else {
                // Default to no access if error
                component.set("v.hasAccess", false);
                console.error('Error checking feature access:', response.getError());
            }
            component.set("v.showSpinner", false);
        });
        $A.enqueueAction(action);
    },
    
    toggleComparisonMode : function(component) {
        var isComparisonMode = component.get("v.comparisonMode");
        console.log('Comparison mode toggled: ' + isComparisonMode);
        // Reset results when toggling mode
        component.set("v.showComparison", false);
    },
    
    handleClick : function(component, event, helper){
        var comparisonMode = component.get("v.comparisonMode");
        
        if (comparisonMode) {
            // Comparison mode - validate both scenarios
            var userID1 = component.get("v.selectedLookUpRecord.Id");
            var objectID1 = component.get("v.objectID");
            var userID2 = component.get("v.selectedLookUpRecord2.Id");
            var objectID2 = component.get("v.objectID2");
            
            console.log('Comparison mode - User1: ' + userID1 + ', Record1: ' + objectID1);
            console.log('Comparison mode - User2: ' + userID2 + ', Record2: ' + objectID2);
            
            if(!userID1 || !objectID1 || !userID2 || !objectID2) {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Missing Information!",
                    "message": "In comparison mode, you must enter both User Names and both Record IDs."
                });
            } else {
                component.set("v.showComparison", true);
                helper.loadComparisonData(component, userID1, objectID1, userID2, objectID2);
            }
        } else {
            // Single mode - original logic
            var userID = component.get("v.selectedLookUpRecord.Id");
            var objectID = component.get("v.objectID");
            console.log('Single mode - User: ' + userID + ', Record: ' + objectID);
            
            if(!userID || !objectID) {
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Something has gone wrong!",
                    "message": "You must enter an User Name and a Record Id."
                });
            } else {
                component.set("v.showComparison", false);
                helper.getObjectNameAndLabel(component, objectID);
            }
        }
    },
    
    /* eslint-disable no-unused-vars */
    printSinglePdf: function(component){
        // Single view PDF generation
        console.log('Generating single view PDF');
        
        // Add class to body to indicate single view printing
        var pageElement = component.find('pageForPrint').getElement();
        pageElement.classList.add('printing-single-view');
        pageElement.classList.remove('printing-comparison-view');
        
        // Wait for class to be applied, then print
        setTimeout(function() {
            window.print();
            // Remove class after printing
            setTimeout(function() {
                pageElement.classList.remove('printing-single-view');
            }, 500);
        }, 100);
    },
    /* eslint-enable no-unused-vars */
    
    /* eslint-disable no-unused-vars */
    printPdf: function(component){
        // Comparison view PDF generation
        console.log('Generating comparison view PDF');
        
        // Add class to body to indicate comparison view printing
        var pageElement = component.find('pageForPrint').getElement();
        pageElement.classList.add('printing-comparison-view');
        pageElement.classList.remove('printing-single-view');
        
        // Wait for class to be applied, then print
        setTimeout(function() {
            window.print();
            // Remove class after printing
            setTimeout(function() {
                pageElement.classList.remove('printing-comparison-view');
            }, 500);
        }, 100);
    }
    /* eslint-enable no-unused-vars */
   
})