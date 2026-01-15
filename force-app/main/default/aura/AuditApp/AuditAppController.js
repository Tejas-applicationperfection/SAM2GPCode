({
    
    init: function(component, event, helper) {
        helper.accessCheck(component,event,helper);
        
        component.set('v.index', 0);    
        component.set("v.TemplateValue", ""); 
        var currenttemplate =  localStorage.getItem("selectedTemplate");
        
        var lastClick = 0;      
        var insertAction = component.get("c.getAuditSteps");
        insertAction.setCallback(this, function(insertResponse) {
            
            var insertState = insertResponse.getState();
            if (insertState === "SUCCESS") {
                
                // After inserting default records, retrieve and set the data
                // helper.loadAuditSteps(component, 'Default');
                var retrieveAction = component.get("c.getExistingRecords");
                if(currenttemplate !== null){ 
                    // console.log('23AuditSJ if');
                    retrieveAction.setParams({ templateValue: currenttemplate});         
                }else{
                    //console.log('26AuditSJ else');
                    retrieveAction.setParams({ templateValue: 'Default'});        
                    
                }
                
                retrieveAction.setCallback(this, function(retrieveResponse) {
                    // alert('inresopnse');
                    var retrieveState = retrieveResponse.getState();
                    if (retrieveState === "SUCCESS") {
                        var existingList = retrieveResponse.getReturnValue();
                        console.log('existingSteptemp='+JSON.stringify(existingList));
                        var defaultList = [];  
                        
                        if (existingList.length === 0) {
                            // No existing steps found, add default steps
                            // console.log('no existing step found');
                            defaultList = insertResponse.getReturnValue();
                            //  alert('inif');
                        } else { 
                            // alert('inelse');
                            // console.log('inelse');
                            // Process existing steps and update defaultList
                            for (var i = 0; i < existingList.length; i++) {
                                var existingStep = existingList[i];
                                
                                var matchedStep = defaultList.find(function(step) {
                                    return step.Name === existingStep.Name;
                                });
                                if (matchedStep) { 
                                    console.log('matchedStep'+matchedStep);
                                    matchedStep.stepOrder = existingStep.SA_Audit__OrderIndex__c;
                                    matchedStep.Id = existingStep.Id;
                                    matchedStep.ReviewDate = existingStep.SA_Audit__ReviewDatee__c;
                                    matchedStep.Comments = existingStep.SA_Audit__Comments__c;
                                    matchedStep.Template = existingStep.SA_Audit__Template__c;
                                    matchedStep.Owner = existingStep.SA_Audit__OwnerAssined__c;
                                     matchedStep.duedate = existingStep.SA_Audit__DueDate__c;
                                } else {
                                    // Adding new step to defaultList
                                    defaultList.push({
                                        Id:existingStep.Id,
                                        stepOrder: existingStep.SA_Audit__OrderIndex__c,
                                        Name: existingStep.Name,
                                        ReviewDate: existingStep.SA_Audit__ReviewDatee__c,
                                        Comments: existingStep.SA_Audit__Comments__c,
                                        Template: existingStep.SA_Audit__Template__c,
                                        Owner: existingStep.SA_Audit__OwnerAssined__c,
                                        duedate: existingStep.SA_Audit__DueDate__c
                                    });
                                    console.log('defaultList----'+JSON.stringify(defaultList));
                                    
                                }
                                
                            }
                        }
                        console.log('defaultList.push='+JSON.stringify(defaultList));
                        component.set("v.modifiedList", defaultList);
                        
                    } else if (retrieveState === "ERROR") {
                        var errors = retrieveResponse.getError();
                        if (errors && errors[0] && errors[0].message) {
                            console.error("Error retrieving existing records: " + errors[0].message);
                        } else {
                            console.error("Unknown error occurred while retrieving existing records.");
                        }
                    }
                });
                $A.enqueueAction(retrieveAction);
            } else if (insertState === "ERROR") {
                var errors = insertResponse.getError();
                if (errors && errors[0] && errors[0].message) {
                    console.error("Error inserting default records: " + errors[0].message);
                } else {
                    console.error("Unknown error occurred while inserting default records.");
                }
            }
        });
        $A.enqueueAction(insertAction);
         helper.searchUsers(component, '');
        helper.initializeTemplates(component);
          helper.getPermissionReviewData(component, event, helper);
         helper.getPicklistData(component, event, helper);
         helper.getOBJPicklistData(component, event, helper);
        helper.getPermPicklistData(component, event, helper);
        helper.getExistingDates(component, name);
        
    },
    
    toggleDateInput: function(component, event, helper) {
        // Get references to the formatted text and input divs
        const formattedDate = document.getElementById('formattedDate');
        const editDate = document.getElementById('editDate');
        
        // Toggle visibility
        if (formattedDate.style.display === 'block') {
            formattedDate.style.display = 'none';
            editDate.style.display = 'block';
        } else {
            formattedDate.style.display = 'block';
            editDate.style.display = 'none';
        }
    },
	 syncDashboard: function(component, event, helper) {
        // Set loading state
        
        // Call the Apex method
        var action = component.get("c.executeDashboardDataBatch");
        
         
        
        // Set callback
        action.setCallback(this, function(response) {
            
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                
                // Show success toast
                helper.showToast("Success", "Dashboard Sync Executed Successfully!", "success");
                
            } else if (state === "ERROR") {
                var errors = response.getError();
                var errorMessage = "Unknown error";
                
                if (errors && errors[0] && errors[0].message) {
                    errorMessage = errors[0].message;
                }
                
                // Show error toast
                helper.showToast("Error", errorMessage, "error");
                
                console.log("Error: " + errorMessage);
            }
        });
        
        // Enqueue the action
        $A.enqueueAction(action);
    },   
    saveDate: function(component, event, helper) {
     // Use `component.find` to get the input component
     const dueDateInput = component.find('duedateInput');
     
     // Ensure the component is available before accessing the value
     if (dueDateInput) {
         const newDate = dueDateInput.get('v.value');
         console.log('New Date: ', newDate);
         
         // Save logic (add your Apex call or logic here)
         
         // Set the input field to disabled after saving the date
         component.set("v.isDateInputDisabled", true);

         // Optionally, reset the visibility logic (this may depend on your implementation)
         const formattedDate = document.getElementById('formattedDate');
         const editDate = document.getElementById('editDate');
         formattedDate.style.display = 'block';
         editDate.style.display = 'none';
     } else {
         console.error('Due date input component not found.');
     }
}
,
    
    showPermissions: function (component, event, helper) {
        component.set("v.selectedSection", "table2");
    },

    // Handler for "Object Permissions" button
    showObjectPermissions: function (component, event, helper) {
        component.set("v.selectedSection", "ObjectTable");
    },
    
     // Handler for "ProfilePset PErmission" button
    showObjectPermissions: function (component, event, helper) {
        component.set("v.selectedSection", "ProfilePsetTable");
    },
    
    redirectToSafeUrl: function (component, event, helper) {
        var recordId = event.target.getAttribute("data-record-id");

        if (recordId) {
            // Use the Lightning Navigation API to navigate to the record page
            var navService = component.find("navigationService");
            var pageReference = {
                type: "standard__recordPage",
                attributes: {
                    recordId: recordId,
                    objectApiName: "SA_Audit__Audit_Step__c", // Replace with the correct API name
                    actionName: "view"
                }
            };
            navService.navigate(pageReference);
        }
    }, 
     /*toggleDropdown: function (component, event, helper) {
        var showDropdown = component.get("v.showDropdown");
        component.set("v.showDropdown", !showDropdown);
    },*/
      toggleDropdown: function (component, event, helper) {
        var showDropdown = component.get("v.showDropdown");
        component.set("v.showDropdown", !showDropdown);

        // Add or remove the global click listener based on dropdown state
        if (!showDropdown) {
            document.addEventListener("click", function (event) {
                helper.closeDropdown(component, event);
            });
        } else {
            document.removeEventListener("click", function (event) {
                helper.closeDropdown(component, event);
            });
        }
    },

    // Handle selection of a schedule option
    handleScheduleOption: function (component, event, helper) {
        // Get the selected option
        var selectedOption = event.target.dataset.value;
        component.set("v.selectedTimeFrame", selectedOption);
        console.log('selectedOption', selectedOption);

        // Call Apex to schedule based on the selected option
        var action = component.get("c.scheduleReview");
        action.setParams({ timeFrame: selectedOption });

        action.setCallback(this, function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var notificationDate = response.getReturnValue();  // Get the returned notification date
                component.set("v.showScheduleSuccessMessage", true);
                component.set("v.notificationDate", notificationDate);  // Set the notification date on the component

                // Optionally, set a message that shows the scheduled time and notification date
                component.set("v.scheduleSuccessMessage", 'Your review is scheduled for ' + selectedOption + '. You will be notified on ' + notificationDate + '.');

                // Hide success message after 5 seconds
                setTimeout(function () {
                    component.set("v.showScheduleSuccessMessage", false);
                }, 5000);
            } else {
                component.set("v.showScheduleErrorMessage", true);
                setTimeout(function () {
                    component.set("v.showScheduleErrorMessage", false);
                }, 5000);
            }

            // Close the dropdown after selecting an option
            component.set("v.showDropdown", false);
        });

        $A.enqueueAction(action);
    },
    changeOwner : function(component, event, helper) {
        //var index = event.target.getAttribute("data-index");
        var index = event.currentTarget.getAttribute("data-index");
       
        console.log('index',index);
        // component.set("v.currentIndex", index);
         localStorage.removeItem('changedOnIndex');
        localStorage.setItem('changedOnIndex', index);
        console.log( 'local',localStorage.getItem('changedOnIndex'));
        component.set('v.showchangelookup', true); 
    }, 
     changeCmpltnDate: function (component, event, helper) {
    // Get the index of the clicked button from the data-index attribute
    var index = event.currentTarget.getAttribute("data-index");
        localStorage.setItem("DueDateIndex", index);

    // Dynamically construct the IDs of the elements
    var formattedDateId = 'formattedDate-' + index;
        localStorage.setItem("formattedDateId", formattedDateId);
    var editDateId = 'editDate-' + index;
      localStorage.setItem("editDateId", editDateId);
    // Get the elements by their dynamic IDs
    var formattedDate = document.getElementById(formattedDateId);
         localStorage.setItem("formattedDate", formattedDate);
    var editDate = document.getElementById(editDateId);
         localStorage.setItem("editDate", editDate);
	 
    // Toggle the visibility of the elements
    if (formattedDate.style.display === 'block') {
        formattedDate.style.display = 'none';
        editDate.style.display = 'block';
    } else {
        formattedDate.style.display = 'block';
        editDate.style.display = 'none';
    } 
},
     
    
    handleOwnerModalNo: function(component, event, helper) {
        console.log('No');
        component.set('v.showchangelookup', false);
    },
    
    showInfo: function(component, event, helper) {
        var dataId = event.currentTarget.getAttribute('data-id');
        component.set("v.showMessageId", dataId);
    },
    
    hideInfo: function(component, event, helper) {
        component.set("v.showMessageId", "");
    },    
    
    notifyAssignee: function(component, event, helper) {
        let checkbox = event.target;
        let index =  localStorage.getItem('changedOnIndex'); 
        let isChecked = checkbox.checked;
        let retrievedRecordId = localStorage.getItem('selectedRecordName');
        
        // Log the values for debugging
        console.log('Checkbox index:', index);
        console.log('Checkbox checked status:', isChecked);
        helper.notifyUser(component, index, isChecked,retrievedRecordId);
    },    
    
    /*  handleSelection: function(component, event, helper) {
        const selectedUserId = event.getParam("value");
        const index = event.getSource().get("v.label"); // Get the index of the selected combobox
       console.log('index---',index);
        // Retrieve the modifiedList from the component
        let modifiedList = component.get("v.modifiedList");

        // Update the Owner field in the modifiedList
        modifiedList[index].Owner = selectedUserId;
       
        // Update the modifiedList attribute in the component
        component.set("v.modifiedList", modifiedList);
          
       console.log('modifiedList[index]',modifiedList[index]);
        // Optionally, you can save the updated step with the new Owner value
        helper.saveStepOwner(component, modifiedList[index],modifiedList[index].Owner);
    },*/
    handleSelection: function(component, event, helper) {
        
        var retrievedRecordId = localStorage.getItem('selectedRecordName');
         console.log('retrievedRecordId---',retrievedRecordId);
        // var retrievedRecordLabel = localStorage.getItem('selectedRecordLable');
        var retrievedTemplate = localStorage.getItem('selectedTemplate');
        var retrievedIndex = localStorage.getItem('changedOnIndex');
         
        const selectedUserId = retrievedRecordId;
        const index = retrievedIndex; // Get the index of the selected combobox
        console.log('index---',index);
        // Retrieve the modifiedList from the component
        let modifiedList = component.get("v.modifiedList");
        
        // Update the Owner field in the modifiedList
        modifiedList[index].Owner = retrievedRecordId;
        console.log('modified Owner',modifiedList[index].Owner);
        // Update the modifiedList attribute in the component
        component.set("v.modifiedList", modifiedList);
        
        console.log('modifiedList[index]',modifiedList[index]);
        // Optionally, you can save the updated step with the new Owner value
        helper.saveStepOwner(component, modifiedList[index],modifiedList[index].Owner);
    },
    
    
    selectUser : function(component, event, helper) {
        const userId = event.getSource().get("v.value");
        component.set("v.userId", userId);
        alert("Selected User ID: " + userId);
    },
    
    exportToExcel: function(component, event, helper) {
        
        component.set("v.showSpinner", true);
        helper.convertArrayOfObjectsToCSV(component); 
    },
    
    exportToExcel_II: function(component, event, helper) {
        component.set("v.showSpinner", true);
        helper.convertArrayOfObjectsToCSV_II(component); 
    },
    
    
    //method handles the selectoption and fetch data acoording to the selected template
    handleTemplateChange: function(component, event, helper) {
        
        // Get the selected template value
        var selectedTemplate = component.find("templateSelect").get("v.value");
        console.log('selectedTemplate=' + selectedTemplate);
        component.set("v.selectedTemplate", selectedTemplate);
        
        // Store the selected template in localStorage
        localStorage.setItem("selectedTemplate", selectedTemplate);
        // Call the Apex method with the selected template value
        var action = component.get("c.getExistingRecords");
        action.setParams({ templateValue: selectedTemplate });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var existingList = response.getReturnValue();
                var defaultList = [];  
                for (var i = 0; i < existingList.length; i++) {
                    var existingStep = existingList[i];
                    var matchedStep = defaultList.find(function(step) {
                        return step.Name === existingStep.Name;
                    });
                    if (matchedStep) { 
                        console.log('eee'+existingStep.OrderIndex__c);
                        matchedStep.stepOrder = existingStep.SA_Audit__OrderIndex__c;
                        matchedStep.Id = existingStep.Id;
                        matchedStep.ReviewDate = existingStep.SA_Audit__ReviewDatee__c;
                        matchedStep.Comments = existingStep.SA_Audit__Comments__c;
                        matchedStep.Owner = existingStep.SA_Audit__OwnerAssined__c;
                        matchedStep.duedate = existingStep.SA_Audit__DueDate__c;
                    } else {
                        // Adding new step to defaultList
                        defaultList.push({
                            Id : existingStep.Id,
                            stepOrder: existingStep.SA_Audit__OrderIndex__c,
                            Name: existingStep.Name,
                            ReviewDate: existingStep.SA_Audit__ReviewDatee__c,
                            Comments: existingStep.SA_Audit__Comments__c,
                            Owner : existingStep.SA_Audit__OwnerAssined__c,
                             duedate: existingStep.SA_Audit__DueDate__c
                        });
                        console.log('defaultListpush=='+JSON.stringify(defaultList ));
                    }
                }
                // console.log('defaultList=138' + defaultList);
                component.set("v.modifiedList", defaultList);
                var EditTable = component.get("v.EditTable");
                component.set("v.EditTable", !EditTable);
                
            } else {
                console.error("Error retrieving audit steps: " + response.getError());
            }
        });
        
        $A.enqueueAction(action);
        
    },
    //this method shows the inputbox for entering the New Template name
    AddTemplate : function(component, event, helper) {
        var isTemplate = component.get("v.isTemplate");
        component.set("v.isTemplate", !isTemplate);
        
        component.set("v.isRemoveTemplate", true);
        
        component.set("v.isAddTemplate", false);
        
        
        
    },
    RemoveTemplate : function(component, event, helper) {
        component.set("v.isRemoveTemplate", false);
        component.set("v.editTemplate",true);
        component.set("v.isAddTemplate", true);
        component.set("v.isTemplate", false);
        var showdupesavebutton = component.get("v.showdupesavebutton");
        component.set("v.showdupesavebutton", !showdupesavebutton);
        $A.get('e.force:refreshView').fire();
        helper.handleTemplateChange(component, event, helper);
        
    },
    
    // Define lastClick outside of your DeleteTemplate method, possibly at the top level of your component's controller.
    
    
    handleDeleteTemplate: function(component, event, helper) { 
        
        var lastClick = component.get("v.lastClickCount");
        // alert('called;'+ lastClick);
        if (lastClick === 1) {
            console.log('DeleteTemplate has already been executed.'); 
            // component.set("v.lastClickCount", 0);
            return;
        }
        component.set('v.showConfirmDialog', true); 
    },
    handleConfirmDialogYes : function(component, event, helper) {
        console.log('Yes');
        component.set('v.showConfirmDialog', false);
        var deleteButton = component.find("deleteButton");
        var selectedTemplate = component.get("v.selectedTemplate");
        console.log('temp=' + selectedTemplate);
        if(selectedTemplate != '' ){
            var action = component.get("c.DeleteTemplateApex");
            action.setParams({ templ: selectedTemplate });
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log('state-'+state); 
                if (state === "SUCCESS") {   
                    var isDeleted = response.getReturnValue(); 
                    console.log('isDeleted=' + isDeleted); 
                    localStorage.removeItem("selectedTemplate");  
                    component.set("v.isRemoveTemplate", false);
                    component.set("v.isAddTemplate", true);
                    component.set("v.isTemplate", false);  
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Success',
                        message: 'Template Deleted Successfully!!',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'success',
                        mode: 'pester'
                    });
                    toastEvent.fire();
                    
                    // Reload the page
                    window.location.reload(true);
                    
                } else { 
                    console.error("Error occurred: " + response.getError());
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Info',
                        message: 'Server Error.',
                        duration:' 5000',
                        key: 'info_alt',
                        type: 'info',
                        mode: 'dismissible'
                    });
                    toastEvent.fire();
                    
                }
            }); }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Warning',
                    message: 'Reselect the template to Delete!.',
                    duration:' 5000',
                    key: 'info_alt',
                    type: 'warning',
                    mode: 'dismissible'
                });
                toastEvent.fire();
            }
        $A.enqueueAction(action);
    },
    
    handleConfirmDialogNo : function(component, event, helper) {
        console.log('No');
        component.set('v.showConfirmDialog', false);
    },
    
    
    //this fundtion handles the empty modifiedList when the save button besides the new add template is clicked
    SaveTemplate : function(component, event, helper){
        
        var selectedTemplate = component.find("Newtemplate").get("v.value");
        if(selectedTemplate != null && selectedTemplate != ''){
            component.set("v.modifiedList", []); 
            localStorage.setItem("selectedTemplate", selectedTemplate); 
            console.log('selectedTemplate'+selectedTemplate);
            var showdupesavebutton = component.get("v.showdupesavebutton");
            component.set("v.showdupesavebutton", !showdupesavebutton);
            component.set("v.showTempMessage",true);
            //component.set("v.showTempMessage",true);
            component.set("v.TemplateValue",selectedTemplate);
            var editTemplate = component.get("v.editTemplate");
            component.set("v.editTemplate",!editTemplate);
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Success',
                message: ' A new template has been successfully created. !!!',
                duration:' 7000',
                key: 'info_alt',
                type: 'success',
                mode: 'pester'
            });
            toastEvent.fire();
            
            
            component.set("v.Addplus", false);
            component.set("v.showTempMessage",false);
            component.set("v.editTemplate",false);
            helper.addnewStep(component);
        } else{
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title : 'Warning',
                message: 'Enter Valid Template Name.',
                duration:' 5000',
                key: 'info_alt',
                type: 'warning',
                mode: 'dismissible'
            });
            toastEvent.fire();
            
        }        
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
    
    editReorderStep: function(component, event, helper) { 
        
        let selectedTemplate = component.find("templateSelect").get("v.value");
        console.log('Selected Template = ' + selectedTemplate);
        
        // Toggle various component attributes to control the UI state
        // helper.toggleIsEdit(component);
        
        // Toggle the visibility of the buttons and input fields
        helper.toggleAttribute(component, "v.showbutton");
        helper.toggleAttribute(component, "v.ShowRenameButton");
        helper.toggleAttribute(component, "v.isReorder");
        helper.toggleAttribute(component, "v.Addplus");
        helper.toggleAttribute(component, "v.editTemplate");
        helper.toggleAttribute(component, "v.showCancelEdit");
        helper.toggleAttribute(component, "v.isAddTemplate");
        helper.toggleAttribute(component, "v.isEdit");
        if(selectedTemplate !== 'Default'){
            helper.toggleAttribute(component, "v.showDeleteTempBtn");
            
        }
        
    },
    
    
    
    afterRender: function (component, helper) {
        this.superAfterRender();
        // Check if the component is rendered and the value is set
        let selectedValue = component.find("templateSelect").get("v.value");
        console.log('Selected value after render:', selectedValue);
    },
    //show/Hide the section one i.e table          
    toggleTable: function(component, event, helper) {
        var showTable = component.get("v.showTable");
        component.set("v.showTable", !showTable);
    },
    //Show/Hide the section two
    toggleTable2: function(component, event, helper) {
        var showTable2 = component.get("v.showTable2");
        component.set("v.showTable2", !showTable2);
    },   
    // Work To edit the default steps and replace it with new steps.
    EditTable: function(component,event,helper){
        
        var editTable = component.get("v.EditTable");
        component.set("v.EditTable", true);
        component.set("v.displayTable", true);
    },   
    handleLinkClick: function(component, event, helper) {
        /* var clickedElement = event.currentTarget;
    
    // Retrieve the data-label attribute value of the clicked element
    var labelValue = clickedElement.getAttribute("data-label");
    console.log("Label Value: " + labelValue); 
    
    // Store the previous tab and navigation option in localStorage
    localStorage.setItem('previousTab', 'AuditNavigation');  
    
    switch(labelValue) {
        case 'Profile Link':
            localStorage.setItem('RedirectToOption', 'option16'); //option16
            break;
        case 'Pset Link':
            localStorage.setItem('RedirectToOption', 'option10'); //option10
            break;
        case 'PsetGroup Link':
            localStorage.setItem('RedirectToOption', 'option30'); //option30
            break;
        case 'Roles Link':
            localStorage.setItem('RedirectToOption', 'option4'); //option4
            break;
        case 'PublicGroup Link':
            localStorage.setItem('RedirectToOption', 'option18'); //option18
            break;
        case 'Internal Link':
            localStorage.setItem('RedirectToOption', 'option3'); //option3
            break;
        case 'External Link':
            localStorage.setItem('RedirectToOption', 'option32'); //option32
            break;
        default:
            console.log('Unknown label');
    }
 console.log('Set RedirectToOption to:', localStorage.getItem('RedirectToOption')); // Debugging
  */
       // Construct the new URL and open it in a new tab
       var urlString = window.location.href;
       var baseURL = urlString.substring(0, urlString.indexOf("/l"));
       var newurl = baseURL + '/lightning/n/SA_Audit__Intel/';
       //var newurl = baseURL + '/lightning/n/SA_Audit__Intel?c__parameterName=' + encodeURIComponent(labelValue);
       
       console.log('newurl=' + newurl);
       window.open(newurl, '_blank');  
   },
    // addStep is used to add a new input row for new step on ui                
    addStep: function(component, event, helper) {
        component.set("v.Addplus", false);
        component.set("v.showTempMessage",false);
        component.set("v.editTemplate",false);
        helper.addnewStep(component);
    },
    CancelEdit: function(component, event, helper) {
        
        var isEdit = component.get("v.isEdit");
        component.set("v.isEdit", !isEdit);
        var showbutton = component.get("v.showbutton");
        component.set("v.showbutton", !showbutton);
        var ShowRenameButton = component.get("v.ShowRenameButton");
        component.set("v.ShowRenameButton", !ShowRenameButton);
        var isReorder = component.get("v.isReorder");
        component.set("v.isReorder", !isReorder);
        var Addplus = component.get("v.Addplus");
        component.set("v.Addplus", !Addplus);
        var editTemplate = component.get("v.editTemplate");
        component.set("v.editTemplate", !editTemplate);
        var showCancelEdit = component.get("v.showCancelEdit");
        component.set("v.showCancelEdit", !showCancelEdit);
        component.set("v.showDeleteTempBtn",false);
        var isAddTemplate = component.get("v.isAddTemplate");
        component.set("v.isAddTemplate", !isAddTemplate);
        
    },
    //use to save or *Rename the steps.....
    renameItems: function(component, event, helper) {
        console.log('renameItems');
        component.set("v.isReorder", false);
        component.set("v.Addplus", true);
        
        //var showDeleteTempBtn = component.get("v.showDeleteTempBtn");
        component.set("v.showDeleteTempBtn", false);
        
        helper.toggleAttribute(component, "v.isAddTemplate");
        helper.toggleAttribute(component, "v.showCancelEdit");
        helper.toggleAttribute(component, "v.editTemplate");
        var renameAuditItems = [];
        var modifiedList = component.get("v.modifiedList");
        
        if (modifiedList.length === 1) {
            // Handle the case with only one step
            var step = modifiedList[0];
            var orderIndex = step.stepOrder;
            var stepInput = component.find("StepInput").get("v.value"); 
            var Newtemplate = component.find("templateSelect").get("v.value");
            if (!Newtemplate) {
                // Retrieve value from local storage
                var currenttemplate = localStorage.getItem("selectedTemplate");
                console.log('ccc=' + currenttemplate);
                
                // Check if value exists in local storage
                if (currenttemplate) {
                    Newtemplate = currenttemplate;
                } else {
                    Newtemplate = 'Default';
                }
            }
            
            if (stepInput != null) {
                console.log('rename step=' + stepInput + '---orderIndex=' + orderIndex);
                var renameAuditItem = {
                    "name": stepInput,
                    "orderIndex": orderIndex,
                    "Newtemplate" : Newtemplate
                };
                renameAuditItems.push(renameAuditItem);
                // console.log('renameAuditItem=' + JSON.stringify(renameAuditItem));
            }
        } else {
            // Handle the case with multiple steps
            for (var i = 0; i < modifiedList.length; i++) {
                // console.log('inloop');
                var step = modifiedList[i];
                // console.log('step=' + JSON.stringify(step));
                var orderIndex = step.stepOrder;
                var stepInput = component.find("StepInput")[i].get("v.value");
                var Newtemplate = component.find("templateSelect").get("v.value");
                if (!Newtemplate) {
                    // Retrieve value from local storage
                    var currenttemplate = localStorage.getItem("selectedTemplate");
                    // console.log('ccc=' + currenttemplate);
                    
                    // Check if value exists in local storage
                    if (currenttemplate) {
                        Newtemplate = currenttemplate;
                    } else {
                        Newtemplate = 'Default';
                    }
                }
                if (stepInput != null) {
                    console.log('rename step=' + stepInput + '---orderIndex=' + orderIndex);
                    var renameAuditItem = {
                        "name": stepInput,
                        "orderIndex": orderIndex,
                        "Newtemplate": Newtemplate
                    };
                    renameAuditItems.push(renameAuditItem);
                    // console.log('renameAuditItem=' + JSON.stringify(renameAuditItem));
                }
            }
        }
        
        // console.log('renameA =' + JSON.stringify(renameAuditItems));
        var action = component.get("c.renameRecords"); //line202 on controller apex
        //console.log("Action formed:", action);
        action.setParams({ renameAuditItemsd: renameAuditItems });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log("Audit step order updated successfully.");
                component.set("v.showSpinner", false);
                component.set("v.showSaveMessage", true);
                setTimeout(function() {
                    component.set("v.showSaveMessage", false);
                }, 3000);
                helper.toggleIsEdit(component);
                helper.toggleRenameButton(component);
                helper.toggleshowButton(component);
            } else {
                console.error("Error updating audit step order: " + response.getError());
                component.set("v.showSpinner", false);
            }
            
            console.log("renameAuditItemsd:", renameAuditItems);
        });
        
        component.set("v.showSpinner", true);
        $A.enqueueAction(action);
    },
    
    
    /* saveTemplateItems: function(component, event, helper) {
           component.set("v.isReorder", false);
           component.set("v.Addplus", true);
        var auditItems = [];
           var Newtemplate = component.find("Newtemplate").get("v.value");
         var inputValue = component.get("v.inputValue");  console.log('inputValues=='+inputValue)
            var reviewDate = component.get("v.reviewDate");console.log('reviewDates=='+reviewDate)
            var comments = component.get("v.comments");console.log('commentss=='+comments)
            
            console.log('Newtemplate=='+Newtemplate)
            if((inputValue &&(reviewDate || comments)) || Newtemplate) {
                c('in')
                console.log('hello='+Newtemplate);
                var newAuditItem = {
                    "name": inputValue,
                    "datee": reviewDate,
                    "comment": comments,
                    "template": Newtemplate
                };
                
                auditItems.push(newAuditItem);
                 console.log('auditItems=' + JSON.stringify(auditItems));
                helper.passNewtempDataToApex(component, inputValue, reviewDate, comments, Newtemplate);
            }
    },
  
    // SaveAuditItems is used to save the data on Click of Save button. For new steps as well as Old steps                                    
saveAuditItems: function(component, event, helper) {
            alert('hello');
            component.set("v.isReorder", false);
            component.set("v.Addplus", true);
            var auditItems = [];
            var modifiedList = component.get("v.modifiedList");
            for (var i = 0; i < modifiedList.length; i++) {
                var step = modifiedList[i];
                var name = step.Name; //component.find("StepInput")[i].get("v.value"); 
                var dateInput = component.find("dateInput")[i].get("v.value");
                var commentInput = component.find("commentInput")[i].get("v.value");                                      
                if (name && (dateInput || commentInput)) {
                    var auditItem = {
                        "name": name,
                        "datee": dateInput,
                        "comment": commentInput
                    };                                   
                     
                     
                    auditItems.push(auditItem);
                    console.log('auditItemsjs='+ JSON.stringify(auditItems));
                }
            }
            component.set("v.showSpinner", true);
            // Save the steps
            helper.saveDefaultSteps(component, auditItems);
            // Save the new steps
            var inputValue = component.get("v.inputValue");
            var reviewDate = component.get("v.reviewDate");
            var comments = component.get("v.comments");
            if (inputValue &&(reviewDate || comments)) {
                console.log('hello');
                var newAuditItem = {
                    "name": inputValue,
                    "datee": reviewDate,
                    "comment": comments
                };
                
                auditItems.push(newAuditItem);
                
                helper.passNewStepDataToApex(component, inputValue, reviewDate, comments);
            }
            console.log('auditItems=' + JSON.stringify(auditItems));
            var action = component.get("c.createAuditRecords");                               
            action.setCallback(this, function(response) {
                component.set("v.displayTable", true);
                //$A.get('e.force:refreshView').fire();
                if ($A.get('e.force:refreshView')) {
                // Running in Lightning Experience
                $A.get('e.force:refreshView').fire();
            } else {
                               // Running in Visualforce
                               window.location.reload();
        }
            });               
            $A.enqueueAction(action);
        },   */
    //when new template is created this function is used to save new steps in the new template
      saveTemplateItems: function(component, event, helper) {
        component.set("v.isReorder", false);
        component.set("v.Addplus", true);
         component.set("v.isTemplate",true);
        var auditItems = [];
        var Newtemplate = component.find("Newtemplate").get("v.value");
        var inputValue = component.get("v.inputValue");  console.log('inputValues=='+inputValue)
        var reviewDate = component.get("v.reviewDate");console.log('reviewDates=='+reviewDate)
        var comments = component.get("v.comments");console.log('commentss=='+comments)
        
        //console.log('Newtemplate=='+Newtemplate)
        if(inputValue == ''){
            
            component.set("v.showInputMessage", true);
            setTimeout(function() {
                component.set("v.showInputMessage", false);
            }, 3000);
        } 
        if((inputValue != '' ) && Newtemplate) { //&&(reviewDate || comments)
            //console.log('in')
           // console.log('hello='+Newtemplate);
            var newAuditItem = {
                "name": inputValue,
                "datee": reviewDate,
                "comment": comments,
                "template": Newtemplate
            };
            
            auditItems.push(newAuditItem);
           // console.log('auditItems=' + JSON.stringify(auditItems));
            
            helper.passNewtempDataToApex(component, inputValue, reviewDate, comments, Newtemplate);
            
        }
    },
   /* saveTemplateItems: function(component, event, helper) {
        component.set("v.isReorder", false);
        component.set("v.Addplus", true);
        component.set("v.isTemplate",true);
        var auditItems = [];
        var Newtemplate = component.find("Newtemplate").get("v.value");
        console.log('inputValues=='+inputValue);
        var inputValue = component.get("v.inputValue");  console.log('inputValues=='+inputValue);
        var reviewDate = component.get("v.reviewDate");console.log('reviewDates=='+reviewDate);
        var comments = component.get("v.comments");console.log('commentss=='+comments);
         var duedateComponent = component.get("v.reviewdueDate");
       
         console.log('Newtemplate=='+Newtemplate)
        if(inputValue == ''){
            
            component.set("v.showInputMessage", true);
            setTimeout(function() {
                component.set("v.showInputMessage", false);
            }, 3000);
        } 
        if((inputValue != '' ) && Newtemplate) { //&&(reviewDate || comments)
            //console.log('in')
          console.log('hello='+Newtemplate);
            var newAuditItem = {
                "name": inputValue,
                "datee": reviewDate,
                "comment": comments,
                "template": Newtemplate,
                "duedate":duedateComponent
            };
            
            auditItems.push(newAuditItem);
            // console.log('auditItems=' + JSON.stringify(auditItems));
            
            helper.passNewtempDataToApex(component, inputValue, reviewDate, comments, Newtemplate,duedateComponent);
            
        }
    },*/
    
     //used to save default values and new values as well
    saveAuditItems: function(component, event, helper) {
        try{
            /*defaultsave process */
            //console.log('saveAuditItems');
            component.set("v.isReorder", false);
            component.set("v.Addplus", true);
            component.set("v.editTemplate",true);
            var auditItems = [];
            var modifiedList = component.get("v.modifiedList");
            
            console.log('modifiedList.length=' + modifiedList.length);
            // Loop through modifiedList items
            for (var i = 0; i < modifiedList.length; i++) {
                var step = modifiedList[i];
                var name = step.Name;
                
                console.log('name=', name, '---step---', step);
                
                // Check if templateSelect exists and retrieve its value
                var templateSelect = component.find("templateSelect");
                var Newtemplate;
                if (templateSelect) {
                    Newtemplate = templateSelect.get("v.value");
                    console.log('templateSelect=' + Newtemplate);
                } else {
                    console.error("templateSelect component not found.");
                    continue; // Skip to the next iteration if templateSelect is missing
                } 
                
                // Check if dateInput exists
                var dateInputComponent = component.find("dateInput");
                var duedate = component.find("duedateInput");
                var duedateinput;
                var dateInput;
                if (Array.isArray(dateInputComponent)) {
                    // Multiple components case
                    if (dateInputComponent[i]) {
                        dateInput = dateInputComponent[i].get("v.value");
                    } else {
                        console.error("dateInputComponent[" + i + "] is undefined.");
                    }
                } else {
                    // Single component case
                    if (dateInputComponent) {
                        dateInput = dateInputComponent.get("v.value");
                    } else {
                        console.error("dateInputComponent is undefined.");
                    }
                }
                
                 if (Array.isArray(duedate)) {
                    // Multiple components case
                    if (duedate[i]) {
                        duedateinput = duedate[i].get("v.value");
                    } else {
                        console.error("duedate[" + i + "] is undefined.");
                    }
                } else {
                    // Single component case
                    if (duedate) {
                        duedateinput = duedate.get("v.value");
                    } else {
                        console.error("duedate is undefined.");
                    }
                }
                console.log('duedateinput=', duedateinput);
                
                // Check if commentInput exists
                var commentInputComponent = component.find("commentInput");
                var commentInput;
                if (Array.isArray(commentInputComponent)) {
                    // Multiple components case
                    if (commentInputComponent[i]) {
                        commentInput = commentInputComponent[i].get("v.value");
                    } else {
                        console.error("commentInputComponent[" + i + "] is undefined.");
                    }
                } else {
                    // Single component case
                    if (commentInputComponent) {
                        commentInput = commentInputComponent.get("v.value");
                    } else {
                        console.error("commentInputComponent is undefined.");
                    }
                }
                console.log('commentInput=', commentInput);
                
                // Logging and fallback for Newtemplate
                if (!Newtemplate) {
                    var currenttemplate = localStorage.getItem("selectedTemplate");
                    console.log('LocalStorage template:', currenttemplate);
                    Newtemplate = currenttemplate || 'Default'; // Use fallback if no template is found
                }
                
                // Proceed if name and either dateInput or commentInput exist
                 //if (name && (dateInput || commentInput || duedateinput)) {
             if (name && (dateInput || commentInput || duedateinput )) {

                    console.log('dateInput or commentInput exist');
                      console.log('name ,dateInput ,commentInput , duedateinput= G',name ,dateInput ,commentInput , duedateinput);
                     var auditItem = {
                         "name": name,
                         "datee": dateInput || null,  // if dateInput is undefined, assign null
                         "comment": commentInput || null,  // if commentInput is undefined, assign null
                         "duedate": duedateinput || null,  // ensure duedateinput is included
                         "template": Newtemplate
                     };
                    
                    auditItems.push(auditItem);
                    console.log('auditItems=', JSON.stringify(auditItems));
                }
               
            }
            component.set("v.showSpinner", true);  
            
            helper.saveDefaultSteps(component, auditItems,step);
            
            /*end for default */
            
            // Save the new steps \|/
            var inputValue = component.get("v.inputValue");           // console.log('inputValue='+inputValue)
            
            var reviewDate = component.get("v.reviewDate");    // console.log('reviewDate='+reviewDate)
            var comments = component.get("v.comments");      //console.log('comments='+comments)
            var Newtemplate = component.find("templateSelect").get("v.value");
            var currenttemplate = localStorage.getItem("selectedTemplate");
            if (!Newtemplate) {
                // Retrieve value from local storage
                var currenttemplate = localStorage.getItem("selectedTemplate");
                console.log('ccc=' + currenttemplate);
                
                // Check if value exists in local storage
                if (currenttemplate) {
                    Newtemplate = currenttemplate;
                } else {
                    // If no value in local storage, you might want to handle this case
                    Newtemplate = 'Default';
                }
            }
            if(inputValue){
                if((inputValue ) || Newtemplate) {
                    //console.log('610line=');
                    var newAuditItem = {
                        "name": inputValue,
                        "datee": reviewDate,
                        "comment": comments,
                        "template":Newtemplate
                    };
                    
                    auditItems.push(newAuditItem);
                    
                    helper.passNewStepDataToApex(component, inputValue, reviewDate, comments,Newtemplate ); //Newtemplate
                }
            }
            // console.log('auditItems=' + JSON.stringify(auditItems));
            var action = component.get("c.createAuditRecords");                               
            action.setCallback(this, function(response) {
                component.set("v.displayTable", true);
                component.set("v.showSaveMessage", true);
                setTimeout(function() {
                    component.set("v.showSaveMessage", false);
                }, 3000);
                // Refresh the table only
                //  helper.refreshTable(component);
            });    
        } catch (error) {
            console.error('Error occurred:', error);
             var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        title : 'Error',
                        message: 'Error Occurred: Server Issue!!',
                        duration:' 5000',
                        key: 'Error_alt',
                        type: 'Error',
                        mode: 'pester'
                    });
                    toastEvent.fire();
            $A.get('e.force:refreshView').fire();
        }
        $A.enqueueAction(action);
    },
   
    // removestep to delete the newly added step on ui first section.
    removeStep: function(component, event, helper) {
        //   var index = event.target.dataset.index;
        var index = event.currentTarget.dataset.index;
        console.log('index='+index);
        component.set("v.Addplus", true);
        component.set("v.inputValue", "");
        component.set("v.reviewDate", "");
        component.set("v.comments", "");
        component.set("v.editTemplate",true);
        helper.removeStep(component, index);
    },  
    //remove step permanently
    removeExistingStep: function(component, event, helper) {
        //   var index = event.target.dataset.index;
        var index = event.currentTarget.dataset.index;
        console.log('index='+index);
        var stepname = event.currentTarget.dataset.stepname;
        console.log('stepname='+stepname); 
        component.set("v.showSpinner", true);
        component.set("v.editTemplate",true);
        helper.removeExistingStep(component, index,stepname);
    },
    
    
    //-------------------------------second section For the Permission review-----------------------------------------------------------------------
    fetchObjectPermission : function(component,event,helper){
        component.set("v.selectedSection", "ObjectTable");
         component.set("v.showSpinnerObjPerm", true);
      helper.getObjPermReviewData(component, event, helper);  
    },
    
    //for profile pset desc count section~~ method: getProPsetReviewData~~
     fetchProfilePsetPermission : function(component,event,helper){
        component.set("v.selectedSection", "ProfilePsetTable");
         component.set("v.showSpinnerObjPerm", true);
      helper.getProPsetReviewData(component, event, helper);  
    },
    
    
    handleDateChange: function(component, event, helper) {
        var dateName = event.getSource().get("v.name");
        var selectedDate = event.getSource().get("v.value");
        if (selectedDate != null ) {
            // Show the popup message
            component.set("v.showPopupMessage", true);
            
            // Automatically hide the popup after 1 second
            setTimeout(function() {
                component.set("v.showPopupMessage", false);
            }, 5000);
        } else {
            // Hide the popup message if "No" is selected
            component.set("v.showPopupMessage", false);
        }
        // Update the corresponding value in the dateData array
        var dateData = component.get("v.dateData");
        for (var i = 0; i < dateData.length; i++) {
            if (dateData[i].name === dateName) {
                dateData[i].value = selectedDate;
                break;
            }
        }
        
        component.set("v.dateData", dateData);
        
        // Save the record automatically
        var action = component.get("c.saveReviewDateRecord");
        action.setParams({
            dateName: dateName,
            selectedDate: selectedDate
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Record saved successfully
                // Perform any additional actions if needed
            } else {
                // Handle error if needed
                console.error("Error saving record: " + response.getError());
            }
        });
        
        $A.enqueueAction(action);
        
        
    }, 
    /* handleSelectionChange: function(component, event, helper) {
                             
                             var picklistName = event.getSource().get("v.name");
                             console.log('picklistName='+picklistName);
                             
                             var selectedValue = event.getSource().get("v.value");
                             console.log('selectedValue='+selectedValue);
                             if (selectedValue === "Yes") {
                                 // Show the popup message
                                 component.set("v.showPopupMessage", true);
                                 
                                 // Automatically hide the popup after 1 second
                                 setTimeout(function() {
                                     component.set("v.showPopupMessage", false);
                                 }, 1500);
                             } else {
                                 // Hide the popup message if "No" is selected
                                 component.set("v.showPopupMessage", false);
                             }
                             // Save the values in local storage
                             switch (picklistName) {
                                     
                                 case "relevantForReview1":
                                     component.set("v.relevantForReview1", selectedValue);
                                     console.log('entry1='+selectedValue);
                                     localStorage.setItem('relevantForReview1', selectedValue);
                                     break;
                                 case "relevantForReview2":
                                     component.set("v.relevantForReview2", selectedValue);
                                     console.log('entry2='+selectedValue);
                                     localStorage.setItem('relevantForReview2', selectedValue);
                                     break;
                                 case "relevantForReview3":
                                     component.set("v.relevantForReview3", selectedValue);
                                     console.log('entry3='+selectedValue);
                                     localStorage.setItem('relevantForReview3', selectedValue);
                                     break;
                                 case "relevantForReview4":
                                     component.set("v.relevantForReview4", selectedValue);
                                     console.log('entry4='+selectedValue);
                                     localStorage.setItem('relevantForReview4', selectedValue);
                                     break;
                                 case "relevantForReview5":
                                     component.set("v.relevantForReview5", selectedValue);
                                     console.log('entry4='+selectedValue);
                                     localStorage.setItem('relevantForReview5', selectedValue);
                                     break;
                                 case "relevantForReview6":
                                     component.set("v.relevantForReview6", selectedValue);
                                     console.log('entry4='+selectedValue);
                                     localStorage.setItem('relevantForReview6', selectedValue);
                                     break;
                                 case "relevantForReview7":
                                     component.set("v.relevantForReview7", selectedValue);
                                     console.log('entry4='+selectedValue);
                                     localStorage.setItem('relevantForReview7', selectedValue);
                                     break;
                                 case "relevantForReview8":
                                     component.set("v.relevantForReview8", selectedValue);
                                     console.log('entry4='+selectedValue);
                                     localStorage.setItem('relevantForReview8', selectedValue);
                                     break;
                                 default:
                                     
                                     break;
                             }
                         }*/
    handleSelectionChange: function(component, event, helper) {
        var picklistName = event.getSource().get("v.name");
        var selectedValue = event.getSource().get("v.value");
        if (selectedValue === "Yes") {
            // Show the popup message
            component.set("v.showPopupMessage", true);
            
            // Automatically hide the popup after 1 second
            setTimeout(function() {
                component.set("v.showPopupMessage", false);
            }, 1500);
        } else {
            // Hide the popup message if "No" is selected
            component.set("v.showPopupMessage", false);
        }
        // Update the corresponding value in the picklistData array
        var picklistData = component.get("v.picklistData");
        for (var i = 0; i < picklistData.length; i++) {
            if (picklistData[i].SA_Audit__PicklistSelection__c === picklistName) {
                picklistData[i].SA_Audit__Selection_value__c = selectedValue;
                break;
            }
        }
        
        component.set("v.picklistData", picklistData);
        
        // Save the record automatically
        var action = component.get("c.saveReviewSelectionRecord");
        action.setParams({
            picklistName: picklistName,
            selectedValue: selectedValue
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Record saved successfully
                // Perform any additional actions if needed
            } else {
                // Handle error if needed
                console.error("Error saving record: " + response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
      handleOBJSelectionChange: function(component, event, helper) {
        var picklistName = event.getSource().get("v.name");
        var selectedValue = event.getSource().get("v.value");
        if (selectedValue === "Yes") {
            // Show the popup message
            component.set("v.showPopupMessage", true);
            
            // Automatically hide the popup after 1 second
            setTimeout(function() {
                component.set("v.showPopupMessage", false);
            }, 1500);
        } else {
            // Hide the popup message if "No" is selected
            component.set("v.showPopupMessage", false);
        }
        // Update the corresponding value in the picklistData array
        var picklistData = component.get("v.ObjpicklistData");
        for (var i = 0; i < picklistData.length; i++) {
            if (picklistData[i].SA_Audit__PicklistSelection__c === picklistName) {
                picklistData[i].SA_Audit__Selection_value__c = selectedValue;
                break;
            }
        }
        
        component.set("v.ObjpicklistData", picklistData);
        
        // Save the record automatically
        var action = component.get("c.saveReviewSelectionRecord");
        action.setParams({
            picklistName: picklistName,
            selectedValue: selectedValue
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Record saved successfully
                // Perform any additional actions if needed
            } else {
                // Handle error if needed
                console.error("Error saving record: " + response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
  handleOBJSelectionChange: function(component, event, helper) {
        var picklistName = event.getSource().get("v.name");
        var selectedValue = event.getSource().get("v.value");
        if (selectedValue === "Yes") {
            // Show the popup message
            component.set("v.showPopupMessage", true);
            
            // Automatically hide the popup after 1 second
            setTimeout(function() {
                component.set("v.showPopupMessage", false);
            }, 1500);
        } else {
            // Hide the popup message if "No" is selected
            component.set("v.showPopupMessage", false);
        }
        // Update the corresponding value in the picklistData array
        var picklistData = component.get("v.Pro_Pset_Desc_picklistData");
        for (var i = 0; i < picklistData.length; i++) {
            if (picklistData[i].SA_Audit__PicklistSelection__c === picklistName) {
                picklistData[i].SA_Audit__Selection_value__c = selectedValue;
                break;
            }
        }
        
        component.set("v.Pro_Pset_Desc_picklistData", picklistData);
        
        // Save the record automatically
        var action = component.get("c.saveReviewSelectionRecord");
        action.setParams({
            picklistName: picklistName,
            selectedValue: selectedValue
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Record saved successfully
                // Perform any additional actions if needed
            } else {
                // Handle error if needed
                console.error("Error saving record: " + response.getError());
            }
        });
        
        $A.enqueueAction(action);
    },
  
    //code to send emails on click of link
    handlelink: function (component, event, helper){
        var option = event.currentTarget.dataset.option;
        console.log('option=' + option);
        var selectedOption = 'option' + option;  
        
        
        if (selectedOption === '') {
            
        } else {
            console.log('option');
        }
        
        console.log('selectedOptionjs=' + selectedOption);
        helper.batchApexExecutionToSendAnEmail(component, event, selectedOption);
    }
    ,
    
    
    //code to open dashboard on click of link
    handleDashlink: function (component, event, helper){
        var option = event.currentTarget.dataset.option;
        console.log('option=' + option);
        var selectedOption = option;  
        
        
        if (selectedOption === '16') {
            selectedOption = 'Auditdashboard';
        }
        if (selectedOption === '10') {
            selectedOption = 'Auditdashboard';
        }
        if (selectedOption === '33') {
            selectedOption = 'Auditdashboard';
        }
        if (selectedOption === '4') {
            selectedOption = 'Auditdashboard';
        }
        if (selectedOption === '18') {
            selectedOption = 'Auditdashboard';
        }
        if (selectedOption === '3') {
            selectedOption = 'Auditdashboard';
        }
        if (selectedOption === '32') {
            selectedOption = 'Auditdashboard';
        }
        else {
            console.log('option');
        }
        
        console.log('selectedOptionjs=' + selectedOption);
        helper.DashboardCall(component, event, selectedOption);
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
})