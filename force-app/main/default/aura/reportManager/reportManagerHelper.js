({
    viewReportsData: function(component, event, helper){
        var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        if(selectedDate != null){
            var action = component.get("c.getReportRecordsBasedOnDate"); 
            action.setParams({
                selectedDate: selectedDate
            })    
        }
        else{
            var action = component.get("c.getReportRecordsBasedOnMonths"); 
            action.setParams({
                months: parseInt(selectedOption)
            })    
        }
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                var data = response.getReturnValue();
                var count = 0;
                data.forEach(function(d) {
                    count+=d.length
                });
                component.set("v.reportCount", count);
                component.set("v.jsonData", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.isDataReady", true);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
                component.set("v.choice", "Reports");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.isDataReady", false);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    exportExcelReports: function(component, event, helper){
        var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        var vfPageURL = "https://" + window.location.hostname;
        var flag;
        if(selectedDate != null){
            flag = true;
            vfPageURL += "/apex/SA_Audit__ReportsExcel?selectedDate=" + selectedDate + '&flag=' + flag;    
        }
        else{
            flag = false;
            vfPageURL += "/apex/SA_Audit__ReportsExcel?selectedOption=" + parseInt(selectedOption) + '&flag=' + flag;    
        }
        window.open(vfPageURL);
        component.set("v.showSpinner", false);
    },
    exportArchivedReports: function(component, event, helper){
        var vfPageURL = "https://" + window.location.hostname;
        vfPageURL += "/apex/SA_Audit__ArchivedReportsExcel";    
        window.open(vfPageURL);
        component.set("v.showSpinner", false);
    },
    getFoldersNames: function(component, event, helper){
        var action = component.get("c.getFolderNames"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                var folderList = [];
                var returnedData = response.getReturnValue();
                //folderList.push({ 'label': "Select all Folders", 'value': 'selectAll'});
                for(var i = 0; i < returnedData.length; i++){
                    folderList.push({ 'label' : returnedData[i].DeveloperName, 'value': returnedData[i].Name});
                }
                folderList.push({ 'label' : 'My Personal Custom Reports', 'value': 'Private Reports'});
                folderList.push({ 'label' : 'Unfiled Public Reports', 'value': 'Public Reports'});
                console.log('folderList>>>>' + JSON.stringify(folderList));
                component.set("v.folderList", folderList);
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    getOrgUserList: function(component, event, helper){
        var action = component.get("c.getUsersList"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                var userList = [];
                var returnedData = response.getReturnValue();
                for(var i = 0; i < returnedData.length; i++){
                    userList.push({ 'label' : returnedData[i].Name, 'value': returnedData[i].Id});
                }
                console.log('folderList>>>>' + JSON.stringify(userList));
                component.set("v.userList", userList);
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    getDefaultFolderId: function(component, event, helper){
        var action = component.get("c.getDefaultFolderId"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.defaultFolderId", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    currentlyLoggedInUserId: function(component, event, helper){
        var action = component.get("c.currentlyLoggedInUserId"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.userId", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    saveJSONData: function(component, event, helper){
        var action = component.get("c.saveJSONDataInObject"); 
        action.setParams({
            jsonData: JSON.stringify(component.get("v.jsonToBeSaved"))
        })
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", true);
                component.set("v.titleOfError", "Confirmation");
                component.set("v.severityError", "confirm");
                component.set("v.errMsgSecond", "Data is saved Successfully.");
                this.scheduleBatchApex(component, event, helper);
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    deleteAllArchivedReports: function(component, event, helper){
        var action = component.get("c.deleteReports"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", true);
                component.set("v.titleOfError", "Confirmation");
                component.set("v.severityError", "confirm");
                component.set("v.errMsgSecond", "Your request to delete Archived reports is in progress. You will receive an confirmation email once job is done....");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    archiveTheReports: function(component, event, helper){
        var folderIds = component.get("v.folderIds");
        var userId = component.get("v.userId");
        var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        var defaultFolderId = component.get("v.defaultFolderId");
        var action = component.get("c.archiveReportsNow"); 
        action.setParams({
            archiveFolderId: defaultFolderId,
            userId: userId,
            folderIds: folderIds,
            selectedDate: selectedDate,
            selectedMonth: parseInt(selectedOption)
        })
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", true);
                component.set("v.titleOfError", "Confirmation");
                component.set("v.severityError", "confirm");
                component.set("v.errMsgSecond", "Your request to move the reports to Archived folder is in progress. You will receive an confirmation email once job is done....");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    viewArchivedData: function(component, event, helper){
        var action = component.get("c.getArchivedFolderReports"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.jsonData", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.isDataReady", true);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
                component.set("v.choice", "Archived");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    deleteAllEmptyFolders: function(component, event, helper){
        var action = component.get("c.deleteTheEmptyFolders"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", true);
                component.set("v.titleOfError", "Confirmation");
                component.set("v.severityError", "confirm");
                component.set("v.isDataReady", false);
                component.set("v.errMsgSecond", "All Empty Folders have been deleted.");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    getBatchApexProgress1: function(component, event, helper){
        var action = component.get("c.checkBatchApexProgress"); 
        var batchJobsIds = component.get('v.batchApexId');
        action.setParams({
            "jobId" : batchJobsIds[0]
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                if(response.getReturnValue() == 'Completed'){
                    this.deleteAllEmptyFolders(component, event, helper);
                }
                component.set("v.showSpinner", false);
                component.set("v.choice", "Folders");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
   /* scheduleBatchApex: function(component, event, helper){
        var action = component.get("c.scheduleBatchClass"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.jsonData", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", true);
                component.set("v.titleOfError", "Confirmation");
                component.set("v.severityError", "confirm");
                component.set("v.errMsgSecond", "Your Archive Job is scheduled. Successfully !!");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },*/
    getAllScheduledReports: function(component, event, helper){
        var action = component.get("c.getScheduledReports"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.jsonData", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.isDataReady", true);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
                component.set("v.choice", "Scheduled");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    viewAllFilteredReports: function(component, event, helper){
        var action = component.get("c.viewTheFilteredReports"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.jsonData", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.isDataReady", true);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
                component.set("v.choice", "Filtered");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    viewAllSubscribedReports: function(component, event, helper){
        var action = component.get("c.viewTheSubscribedReports"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.jsonData", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.isDataReady", true);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
                component.set("v.choice", "Subscribed");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    getAllEmptyFolders: function(component, event, helper){
        var action = component.get("c.getFoldersData"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.jsonData", response.getReturnValue());
                component.set("v.showSpinner", false);
                component.set("v.isDataReady", true);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
                component.set("v.choice", "Folders");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    getBatchApexProgress: function(component, event, helper){
        var action = component.get("c.checkBatchApexProgress"); 
        var batchJobsIds = component.get('v.batchApexId');
        action.setParams({
            "jobId" : batchJobsIds[0]
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                if(response.getReturnValue() == 'Completed'){
                    this.getAllEmptyFolders(component, event, helper);
                }
                component.set("v.showSpinner", false);
                component.set("v.choice", "Folders");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    unarchivedToOriginalFolders: function(component, event, helper){
        var action = component.get("c.unarchivedTheSelectedReports"); 
        action.setParams({
            reportRecordsList: component.get("v.jsonData")
        })    
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", true);
                component.set("v.titleOfError", "Confirmation");
                component.set("v.severityError", "confirm");
                component.set("v.errMsgSecond", "Your request to move the reports to Original folder is in progress.");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    getIntialReportManagerObjectData: function(component, event, helper){
        var action = component.get("c.getUserPreference"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                console.log('getIntialReportManagerObjectData>>>>>' + JSON.stringify(response.getReturnValue()));
                if(response.getReturnValue().length > 0){
                    //component.set("v.jsonToBeSaved", response.getReturnValue());
                    component.set("v.folderIds", response.getReturnValue()[0].folderIds);
                    component.set("v.userId", response.getReturnValue()[0].userId);
                    component.set("v.scheduleArchive", response.getReturnValue()[0].scheduleArchive);
                    component.set("v.norifyUser", response.getReturnValue()[0].norifyUser);
                    component.set("v.defaultFolderId", response.getReturnValue()[0].archiveFolderId);
                }
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    executeBatchApex: function(component, event, helper){
        var action = component.get("c.executeAllTheBatchApex"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                component.set("v.batchApexId", response.getReturnValue());
                console.log('batch Job Apex Ids>>>>>' + JSON.stringify(response.getReturnValue()));
                component.set("v.showSpinner", false);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBoolen", true);
                component.set("v.titleOfError", "Error");
                component.set("v.severityError", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    convertArrayOfObjectsToCSV : function(component,objectRecords){
        // declare variables
        var counter, keys, columnDivider, lineDivider;
        // check if "objectRecords" parameter is null, then return from function
        if (objectRecords == null || !objectRecords.length) {
            return null;
        }
        var csvStringResult = '';
        // store ,[comma] in columnDivider variabel for sparate CSV values and 
        // for start next line use '\n' [new line] in lineDivider varaible  
        columnDivider = ',';
        lineDivider =  '\n';
        console.log("<<<<<< download csv -- " + objectRecords);
        
        // in the keys valirable store fields API Names as a key 
        // this labels use in CSV file header  
        keys = Object.keys(objectRecords[0][0]);
        console.log("<<<<<< keys -- " + keys);
        csvStringResult += keys.join(columnDivider);
        csvStringResult += lineDivider;
        objectRecords.forEach(function(objectRecord, index) {
            objectRecord.forEach(function(item, item_index) {
                keys.forEach(function(key, key_index) {
                    if(key_index > 0){ 
                          csvStringResult += columnDivider; 
                    }
                    csvStringResult += item[key]; 
                });
                csvStringResult += lineDivider; 
                
            });       
        });
       // return the CSV formate String 
       return csvStringResult;        
    },
})