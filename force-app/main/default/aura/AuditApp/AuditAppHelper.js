//helper
({
    accessCheck : function(component,event,helper){
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
    
    
    searchUsers : function(component, searchTerm) {
        const action = component.get("c.findUsers");
        action.setParams({ searchTerm: '' });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                const users = response.getReturnValue();
                const options = users.map(user => {
                    return { label: user.Name, value: user.Id };
                                          });
                component.set("v.options", options);
                
            }
        });
        
        $A.enqueueAction(action);
    },
      closeDropdown: function (component, event) {
        // Find the dropdown container and check if the click is outside of it
        var dropdownContainer = document.querySelector(".dropdown-container");
        if (dropdownContainer && !dropdownContainer.contains(event.target)) {
            component.set("v.showDropdown", false);

            // Remove the global click listener
            document.removeEventListener("click", function (event) {
                this.closeDropdown(component, event);
            }.bind(this));
        }
    },

    // Utility function to get the component instance
    getComponent: function () {
        return this.component;
    },
 
    notifyUser: function (component, index, isChecked,retrievedRecordId) {
        
        // Example: Call an Apex method to handle the notification server-side (if needed)
        let action = component.get("c.sendNotification");
        action.setParams({
            userIndex: index ,
            retrievedRecordId : retrievedRecordId
        });

        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                // Handle success logic
                console.log('Notification sent successfully.');
            } else if (state === "ERROR") {
                // Handle error logic
                let errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    console.error('Error message: ' + errors[0].message);
                } else {
                    console.error('Unknown error');
                }
            }
        });

        // Queue the server-side action
        $A.enqueueAction(action);
    },
    showToast: function(title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                title: title,
                message: message,
                type: type,
                duration: 3000
            });
            toastEvent.fire();
        } else {
            // Fallback for environments without toast
            alert(title + ": " + message);
        }
    },
 

     saveStepOwner: function(component, step,Owner) {
        const action = component.get("c.updateStepOwner");
        let currentTemplateId = localStorage.getItem('selectedTemplate');
        if(currentTemplateId === null && currentTemplateId == undefined){
            currentTemplateId = 'Default'
        }
        console.log("step",step);
        console.log("Owner",Owner);
        console.log("currentTemplateId",currentTemplateId);
        action.setParams({
            "step": step,
             "OwnerAs": Owner ? Owner.toString() : null,
            "currentTemplateId" : currentTemplateId
        });
        
        action.setCallback(this, function(response) {
            const state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.showchangelookup", false);
                console.log("Step owner updated successfully");
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Success',
                    message: 'Owner Assigned Succesfully ',
                    duration:' 7000',
                    key: 'info_alt',
                    type: 'success',
                    mode: 'pester'
                });
                toastEvent.fire();
                // localStorage.removeItem('selectedRecordName');
                // localStorage.removeItem('selectedOwnerTemplate');
                localStorage.removeItem('changedOnIndex');
                
            } else {
                component.set("v.showchangelookup", false);
                console.error("Failed to update step owner");
            }
        });
        
        $A.enqueueAction(action);
    },
     
    getPermissionReviewData: function(component) {
        var action = component.get("c.getPermissionReviewData");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var permissionReviewData = response.getReturnValue();
                component.set("v.permissionReviewData", permissionReviewData);
            } else {
                console.log("Error retrieving permission review data");
            }
        });
        $A.enqueueAction(action);
    },
    
    getObjPermReviewData: function(component) {
        var action = component.get("c.getObjPermReviewData");
       action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 component.set("v.showSpinnerObjPerm", false);
                var permissionReviewData = response.getReturnValue();
                // Derive counts exactly like ObjectDescriptions without introducing extra fields
                if (permissionReviewData && permissionReviewData.length) {
                    permissionReviewData = permissionReviewData.map(function(item){
                        // Total Objects equals count of custom objects
                        item.TotalObjects = item.TotalCustomObjects;
                        // Objects with description not populated (custom only)
                        item.DescNotPopulated = Math.max((item.TotalObjects || 0) - (item.DescPopulatedObjects || 0), 0);
                        // Editable objects = custom non-managed = TotalCustomObjects - TotalManagedObjects
                        item.EditableObjects = Math.max((item.TotalCustomObjects || 0) - (item.TotalManagedObjects || 0), 0);
                        // Editable described = DescPopulatedObjects - ManagedObjDesc
                        var editableDescribed = Math.max((item.DescPopulatedObjects || 0) - (item.ManagedObjDesc || 0), 0);
                        // Blank editable description = EditableObjects - Editable described
                        item.BlankEditableDesc = Math.max((item.EditableObjects || 0) - editableDescribed, 0);
                        // Uneditable description blank = Managed custom with blank description
                        item.UneditableBlank = Math.max((item.TotalManagedObjects || 0) - (item.ManagedObjDesc || 0), 0);
                        return item;
                    });
                }
                component.set("v.ObjPermReviewData", permissionReviewData);
                 
            } else {
                console.log("Error retrieving permission review data");
            }
        });
        $A.enqueueAction(action);
    },
    
    
     getProPsetReviewData: function(component) {
        var action = component.get("c.getProPsetReviewData");
       action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 component.set("v.showSpinnerObjPerm", false);
                var permissionReviewData = response.getReturnValue();
                component.set("v.ProPsetReviewData", permissionReviewData);
                 console.log(JSON.stringify(permissionReviewData));
            } else {
                console.log("Error retrieving permission review data");
            }
        });
        $A.enqueueAction(action);
    },
    
    getPicklistData: function(component) {
        var action = component.get("c.getReviewSelectionRecords");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var existingValues = response.getReturnValue();
                var picklistData = component.get("v.picklistData");
                //console.log('picklistData='+JSON.stringify(picklistData));
                // Update existing values if present
                if (existingValues && existingValues.length > 0) {
                    for (var i = 0; i < picklistData.length; i++) {
                        for (var j = 0; j < existingValues.length; j++) {
                            if (picklistData[i].SA_Audit__PicklistSelection__c === existingValues[j].SA_Audit__PicklistSelection__c) {
                                picklistData[i].SA_Audit__Selection_value__c = existingValues[j].SA_Audit__Selection_value__c;
                                break;
                            }
                        }
                    }
                }
                
                component.set("v.picklistData", picklistData);
            } else {
                console.log("Error retrieving existing values");
            }
        });
        $A.enqueueAction(action);
    },
    getOBJPicklistData: function(component) {
        var action = component.get("c.getReviewSelectionRecords");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var existingValues = response.getReturnValue();
                var picklistData = component.get("v.ObjpicklistData");
                //console.log('picklistData='+JSON.stringify(picklistData));
                // Update existing values if present
                if (existingValues && existingValues.length > 0) {
                    for (var i = 0; i < picklistData.length; i++) {
                        for (var j = 0; j < existingValues.length; j++) {
                            if (picklistData[i].SA_Audit__PicklistSelection__c === existingValues[j].SA_Audit__PicklistSelection__c) {
                                picklistData[i].SA_Audit__Selection_value__c = existingValues[j].SA_Audit__Selection_value__c;
                                break;
                            }
                        }
                    }
                }
                
                component.set("v.ObjpicklistData", picklistData);
            } else {
                console.log("Error retrieving existing values");
            }
        });
        $A.enqueueAction(action);
    },
    getPermPicklistData: function(component) {
        var action = component.get("c.getReviewSelectionRecords");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var existingValues = response.getReturnValue();
                var picklistData = component.get("v.Pro_Pset_Desc_picklistData");
                //console.log('picklistData='+JSON.stringify(picklistData));
                // Update existing values if present
                if (existingValues && existingValues.length > 0) {
                    for (var i = 0; i < picklistData.length; i++) {
                        for (var j = 0; j < existingValues.length; j++) {
                            if (picklistData[i].SA_Audit__PicklistSelection__c === existingValues[j].SA_Audit__PicklistSelection__c) {
                                picklistData[i].SA_Audit__Selection_value__c = existingValues[j].SA_Audit__Selection_value__c;
                                break;
                            }
                        }
                    }
                }
                
                component.set("v.Pro_Pset_Desc_picklistData", picklistData);
            } else {
                console.log("Error retrieving existing values");
            }
        });
        $A.enqueueAction(action);
    },
    getExistingDates: function(component) {
        var dateData = component.get("v.dateData");
        dateData.forEach(function(item) {
            var action = component.get("c.getExistingDatesFromServer");
            action.setParams({
                recordName: item.name
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var existingDate = response.getReturnValue();
                    item.value = existingDate;
                    component.set("v.dateData", dateData);
                }
            });
            
            $A.enqueueAction(action);
        }); 
    },
     handleTemplateChange: function(component, event, helper) {
      
        // Get the selected template value
        var selectedTemplate = component.find("templateSelect").get("v.value");
        console.log('selectedTemplate=' + selectedTemplate);
        component.set("v.selectedTemplate", selectedTemplate);
        
        // Store the selected template in localStorage
        localStorage.setItem("selectedTemplate", "Default");
        // Call the Apex method with the selected template value
        var action = component.get("c.getExistingRecords");
        action.setParams({ templateValue: "Default" });
        
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
                        
                    } else {
                        // Adding new step to defaultList
                        defaultList.push({
                            Id : existingStep.Id,
                            stepOrder: existingStep.SA_Audit__OrderIndex__c,
                            Name: existingStep.Name,
                            ReviewDate: existingStep.SA_Audit__ReviewDatee__c,
                            Comments: existingStep.SA_Audit__Comments__c,
                            Owner : existingStep.SA_Audit__OwnerAssined__c
                        });
                        console.log('defaultListpush=='+JSON.stringify(defaultList ));
                    }
                }
                // console.log('defaultList=138' + defaultList);
                component.set("v.modifiedList", defaultList);
                var EditTable = component.get("v.EditTable");
                component.set("v.EditTable", !EditTable);
                component.set("v.TemplateValue","Default");
            } else {
                console.error("Error retrieving audit steps: " + response.getError());
            }
        });
        
        $A.enqueueAction(action);
        
    },
    addnewStep: function(component) {
        var modifiedList = component.get("v.modifiedList");
        modifiedList.push({
            Name: '',
            ReviewDate: '',
            Comments: '', 
            // Template:'', 
            isEditing: true, 
        });
        
        // console.log('modifiedList'+JSON.stringify(modifiedList)); 
        component.set("v.modifiedList", modifiedList);
    },  
    removeStep: function(component, index) {
        var modifiedList = component.get("v.modifiedList");
        modifiedList.splice(index, 1);
        component.set("v.modifiedList", modifiedList);
    },   
    removeExistingStep: function(component, index, stepname) {
        var stepToRemove = stepname;
        console.log('index1=' + stepToRemove);
        
        var action = component.get("c.deleteStepRecord");
        action.setParams({
            "stepToRemove": stepToRemove
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Handle the success scenario if needed
                console.log('Step deleted successfully');
                
                // Fetch updated steps after successful deletion
                //this.fetchAuditSteps(component);
                
                $A.get('e.force:refreshView').fire();
            } else if (state === "ERROR") {
                console.log('Step not deleted');
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.error('Error message: ' + errors[0].message);
                    }
                } else {
                    console.error('Unknown error');
                }
                component.set("v.showSpinner", false);
            }
        });
        
        $A.enqueueAction(action);
    },
    convertArrayOfObjectsToCSV: function(component) {
        var vfPageURL = "https://" + window.location.hostname;
        vfPageURL += "/apex/SA_Audit__AuditObjectiveExportToExcel";    
        window.open(vfPageURL);
        component.set("v.showSpinner", false);
    },
    convertArrayOfObjectsToCSV_II: function(component) {
        var vfPageURL = "https://" + window.location.hostname;
        vfPageURL += "/apex/SA_Audit__AuditObjectiveExportToExcelII";    
        window.open(vfPageURL);
        component.set("v.showSpinner", false);
    }, 
    
     /*saveDefaultSteps: function(component, auditItems,step) { 
       //  alert('saveDefaultSteps');
        console.log('auditItems@@@@='+auditItems,'step+'+step);
        var action = component.get("c.createAuditRecords");  
        action.setParams({
            "auditItemsd": auditItems,      
        });  
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Handle successful response from Apex controller
                var result = response.getReturnValue();
                 console.log('response.getReturnValue===',JSON.stringify(response.getReturnValue()));
                component.set("v.showSpinner", false);    
                let index = localStorage.getItem('index');
                console.log('index-', index);
                
                // Dynamically construct the IDs
                let formattedDateId = localStorage.getItem('formattedDateId');
                console.log('formattedDateId-', formattedDateId);
                let editDateId = localStorage.getItem('editDateId');
                console.log('editDateId-', editDateId);
                
                // Retrieve the actual DOM elements by their IDs
                let formattedDate = document.getElementById(formattedDateId);
                console.log('formattedDate-', formattedDate);
                let editDate = document.getElementById(editDateId);
                console.log('editDate-', editDate);
                
                // Ensure elements exist before manipulating
                if (formattedDate && editDate) {
                    // Toggle the visibility of the elements
                    if (formattedDate.style.display === 'block') {
                        formattedDate.style.display = 'none';
                        editDate.style.display = 'block';
                    } else {
                        formattedDate.style.display = 'block';
                        editDate.style.display = 'none';
                    }
                } else {
                    console.error('Elements not found. Check your IDs or localStorage values.');
                }
               
            } else {
                // Handle error or incomplete response
                console.log("Error occurred: " + state);
            }
        });
        
        $A.enqueueAction(action);
    } , */
    saveDefaultSteps: function(component, auditItems, step) {  
    // Debug: Log auditItems and the current step
    console.log('auditItems@@@@=' + JSON.stringify(auditItems), 'step=' + step);
  
    // Call Apex method to save the audit records
    var action = component.get("c.createAuditRecords");  
    action.setParams({
        "auditItemsd": auditItems,      
    });  

    action.setCallback(this, function(response) {
        var state = response.getState();

        if (state === "SUCCESS") {
            // Handle successful response from Apex controller
            var result = response.getReturnValue();
            console.log('response.getReturnValue===', JSON.stringify(result));

            component.set("v.showSpinner", false);    

            // Loop through all audit items (steps) and toggle visibility
            auditItems.forEach(function(step, index) {
                // Dynamically construct the IDs based on index
                let formattedDateId = 'formattedDate-' + index;
                let editDateId = 'editDate-' + index;

                // Debug: Log the IDs being used for each step
                console.log('Toggling visibility for step:', step.name);
                console.log('Formatted Date ID:', formattedDateId);
                console.log('Edit Date ID:', editDateId);

                // Retrieve the actual DOM elements by their IDs
                let formattedDate = document.getElementById(formattedDateId);
                let editDate = document.getElementById(editDateId);

                // Ensure elements exist before manipulating
                if (formattedDate && editDate) {
                    // Always hide all editDate elements and show all formattedDate elements
                    formattedDate.style.display = 'block'; // Show formatted date
                    editDate.style.display = 'none'; // Hide the edit input
                } else {
                    console.error('Elements not found for index:', index);
                }
            });

        } else {
            // Handle error or incomplete response
            console.log("Error occurred: " + state);
        }
    });

    // Enqueue the action to send it to Apex
    $A.enqueueAction(action);
},

    
    initializeTemplates: function(component) {
        // Call the Apex method to get distinct template names
        var action = component.get("c.getUniqueTemplateNames");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Set the retrieved templates in the component attribute
                var templates = response.getReturnValue();
                component.set("v.templates", templates);
                
                // Set the first template as currentTemplate if it doesn't exist in templates
                var currentTemplate = localStorage.getItem("selectedTemplate");
                if (currentTemplate) {
                    // Reorder templates to make currentTemplate the first item
                    var index = templates.indexOf(currentTemplate);
                    if (index !== -1) {
                        templates.splice(index, 1); // Remove currentTemplate from templates
                        templates.unshift(currentTemplate); // Add currentTemplate to the beginning
                        component.set("v.templates", templates); // Update templates attribute
                    } else {
                        console.warn("Current template not found in templates array.");
                    }
                } else {
                    console.warn("Current template not found in local storage.");
                }
            } else {
                console.error("Error retrieving template names: " + response.getError());
            }
        });
        $A.enqueueAction(action);
    }, 
      //to save the New template added data
   passNewtempDataToApex: function(component, inputValue, reviewDate, comments, Newtemplate) {
        // alert('inhelper')
        var action = component.get("c.addNewProcesstemp");  
        action.setParams({ 
            "inputParam": inputValue,
            "reviewDateParam": reviewDate,
            "commentsParam": comments,
            "templateParam": Newtemplate
            
        }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // Handle response from Apex controller
                var result = response.getReturnValue();
                
                localStorage.setItem("selectedTemplate", Newtemplate);
                
                $A.get('e.force:refreshView').fire();
                //helper.initializeTemplates(component);
                
            } else {
                // Handle error
                console.log("Error occurred: " + state);
            }
        });
        
        $A.enqueueAction(action);
    },
    //to save the new step added data
    passNewStepDataToApex: function(component, inputValue, reviewDate, comments, Newtemplate) {
        //console.log('inputValue===='+ inputValue +'---' + reviewDate  +'---' + comments +'---' + Newtemplate);
        
        var action = component.get("c.addNewProcess");  
        action.setParams({ 
            "inputParam": inputValue,
            "reviewDateParam": reviewDate,
            "commentsParam": comments,
            "templateParam": Newtemplate
            
        }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                // alert(state);
                var result = response.getReturnValue();
                // if ($A.get('e.force:refreshView')) {
                // // Running in Lightning Experience
                $A.get('e.force:refreshView').fire();
                // } 
            } else {
                // Handle error
                console.log("Error occurred: " + state);
            }
        });
        
        $A.enqueueAction(action);
    }, 
     toggleAttribute: function(component, attributeName) {
        let currentValue = component.get(attributeName);
        component.set(attributeName, !currentValue);
    },
    toggleIsEdit: function(component) {
         let selectedTemplate = component.find("templateSelect").get("v.value");
          console.log('selectedTemplatec=' + selectedTemplate);
        var isEdit = component.get("v.isEdit");
        component.set("v.isEdit", !isEdit);
          
    },
    toggleRenameButton: function(component) {
        var ShowRenameButton = component.get("v.ShowRenameButton");
        component.set("v.ShowRenameButton", !ShowRenameButton);
    },
    toggleshowButton: function(component) {
       var showbutton = component.get("v.showbutton");
        component.set("v.showbutton", !showbutton);
    },   
    batchApexExecutionToSendAnEmail: function(component, event, selectedOption) {
        //var selectedOption = component.get("v.selectedValues");
        console.log('selectedOptionHelpr='+selectedOption) 
        var action = component.get("c.batchApexExecutionToSendAnEmail");
        action.setParams({
            selectedOption: selectedOption
            
        }); 
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS"){
                                   console.log('>>>>>' + JSON.stringify(response.getReturnValue())); 
                                   component.set("v.showEmailMessage",true);
                                   setTimeout(function() {
                                       component.set("v.showEmailMessage", false);
                                   }, 7000);
                               }
                               else{
                                   
                                   var errorMessage = '';
                                   if(state === "INCOMPLETE")
                                   {
                                       errorMessage = 'Some Error is Occured.';
                                   }
                                   else if(state === "ERROR")
                                   {
                                       errorMessage = action.getError()[0].message;
                                   } 
                                   
                                   // component.set("v.errMsgSecond", errorMessage);
                               }
                           } 
                          );
        $A.enqueueAction(action);
    }, 
    DashboardCall: function(component, event, selectedOption) {
        
        console.log('selectedOptionHelpr='+selectedOption) 
        var action = component.get("c.getDashboardIdByName");
        action.setParams({
            selectedOption: selectedOption
        }); 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var dashboardId = response.getReturnValue();
                if (dashboardId) {
                    var urlString = window.location.href;
                    var baseURL = urlString.substring(0, urlString.indexOf("/s"));
                    var dashboardURL = baseURL + '/lightning/r/SA_Audit__Dashboard/' + dashboardId + '/view';
                    window.open(dashboardURL, '_blank');
                } else {
                    console.log("Dashboard not found");
                }
            } else {
                console.log("Error in getting dashboard ID");
            }
        });
        $A.enqueueAction(action);
    }   
     
   
})