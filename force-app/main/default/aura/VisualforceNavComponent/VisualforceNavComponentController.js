({
    init: function(component, event, helper) {
         var action = component.get("c.PaidFeatureAccess");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.hasAccess", response.getReturnValue());
            } else {
                console.error("Failed to retrieve access information");
            }
        });   
        
        $A.enqueueAction(action);
        
    },
    
    
     toggleCard : function(component, event, helper) {
        var isExpanded = component.get("v.isExpanded");
        component.set("v.isExpanded", !isExpanded);
    },
    navigateToVf: function(component, event, helper) {
        var namespace = component.get("v.namespace");
        var buttonId = event.getSource().getLocalId();
        var currentPage = component.get("v.pageName");

        // Show spinner when navigating to a tab
        component.set("v.showSpinner", true);

        // Construct the VF page URL with namespace
        var vfPageUrl = '/apex/' + namespace + '__' + buttonId;
        
        // Detect if we're in Lightning Experience or Classic
        var isLightning = (typeof $A !== 'undefined');
        
        if (isLightning) {
            // In Lightning: Use iframe navigation (existing behavior)
            // Reload the Visualforce page if clicking on the current tab
            if (buttonId === currentPage) {
                component.set("v.visualforcePageUrl", ""); // Reset to force reload
                setTimeout(function() {
                    component.set("v.visualforcePageUrl", vfPageUrl);
                }, 100);
            } else {
                // Set new URL for a different tab
                component.set("v.visualforcePageUrl", vfPageUrl);
                component.set("v.pageName", buttonId);
            }
        } else {
            // In Classic: Open in new window/tab
            window.open(vfPageUrl, '_blank');
            component.set("v.showSpinner", false);
        }
    },

    hideSpinner: function(component, event, helper) {
        component.set("v.showSpinner", false); // Hide spinner once iframe has loaded
    },
    openContactUSLink: function(component, event, helper){
        var buttonLabel=event.getSource('').get('v.label');
        if(buttonLabel === 'Request a feature/support'){
            window.open('https://applicationperfection.com/contact/');
        }else if(buttonLabel === 'Help/Training'){
            window.open('https://applicationperfection.com/security-access-manager-help-training/');
        }else if(buttonLabel === "FAQ's"){
            window.open('https://applicationperfection.com/security-access-manager-faqs/');
        }else if(buttonLabel === 'Release Notes'){
            window.open('https://applicationperfection.com/security-access-manager-release-notes/');
        }
    },
})