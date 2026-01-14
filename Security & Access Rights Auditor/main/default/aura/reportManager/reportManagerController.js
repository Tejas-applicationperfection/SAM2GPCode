({
    changeDropdownValue: function(component, event, helper){
        var selectedOption = component.find('select').get('v.value');
        component.set("v.selectedDropdownValue", selectedOption);
        component.set("v.selectedDate", null);
        //console.log('selectedOption>>>>' + selectedOption);
    },
    doInit: function(component, event, helper){
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

        /*component.set("v.showSpinner", true);
        helper.getFoldersNames(component, event, helper);
        //helper.getOrgUserList(component, event, helper);
        helper.getDefaultFolderId(component, event, helper);
        helper.executeBatchApex(component, event, helper);
        helper.currentlyLoggedInUserId(component, event, helper);
        //helper.getIntialReportManagerObjectData(component, event, helper);
        var randomNumber = Math.floor(Math.random() * 5);
        console.log('randomNumber>>>' + randomNumber);
        component.set("v.advertisementImageNumber", randomNumber);*/
    },
    saveData: function(component, event, helper){
        var folderIds = component.get("v.folderIds");
        var userId = component.get("v.userId");
        var scheduleArchive = component.get("v.scheduleArchive");
        var norifyUser = component.get("v.norifyUser");
        var defaultFolderId = component.get("v.defaultFolderId");
        if(!scheduleArchive){
            component.set("v.showSpinner", false);
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select Schedule Archive Checkbox");
        }
        else if(folderIds == ''){
            component.set("v.showSpinner", false);
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select al least one Folder");
        }
        /*else if(norifyUser && userId == ''){
            component.set("v.showSpinner", false);
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select any User");    
        }*/
        else{
            component.set("v.showSpinner", true);
            component.set("v.errorMsgBoolean", false);
            component.set("v.titleOfError", "");
            component.set("v.severityError", "");
            component.set("v.errMsgSecond", "");
            var jsonToBeSaved = [];
            jsonToBeSaved.push({'scheduleArchive': scheduleArchive, 'folderIds': folderIds, 'norifyUser': norifyUser, 'archiveFolderId': defaultFolderId, 'userId': userId});
            component.set("v.jsonToBeSaved", jsonToBeSaved);
            //console.log('jsonToBeSaved>>>>' + JSON.stringify(jsonToBeSaved));
            helper.saveJSONData(component, event, helper);
        }
    },
    folderIdsChange: function(component, event, helper){
        var folderIds = event.getParam('value');
        component.set("v.selectAllFolders", false);
        console.log('folderIds>>>>' + folderIds);
        component.set("v.folderIds", folderIds);
    },
    deleteArchivedReports: function(component, event, helper){
        helper.deleteAllArchivedReports(component, event, helper);   
    },
    viewScheduledReports: function(component, event, helper){
        component.set("v.showSpinner", true);
        component.set("v.choice", "");
        helper.getAllScheduledReports(component, event, helper);   
    },
    viewEmptyFolders: function(component, event, helper){
        component.set("v.choice", "");
        component.set("v.showSpinner", true);
        helper.getBatchApexProgress(component, event, helper);
    },
    viewFilteredReports: function(component, event, helper){
        component.set("v.choice", "");
        component.set("v.showSpinner", true);
        helper.viewAllFilteredReports(component, event, helper);
    },
    viewSubscribedReports: function(component, event, helper){
        component.set("v.choice", "");
        component.set("v.showSpinner", true);
        helper.viewAllSubscribedReports(component, event, helper);
    },
    deleteEmptyFolders: function(component, event, helper){
        component.set("v.showSpinner", true);
        helper.getBatchApexProgress1(component, event, helper);
    },
    openAccessManagerApp: function(component, event, helper){
        window.open('https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000Ei6FwUAJ');
    },
    exportScheduledReports: function(component, event, helper){
        component.set("v.showSpinner", true);
        var vfPageURL = "https://" + window.location.hostname;
        vfPageURL += "/apex/SA_Audit__ScheduledReportsExcel";    
        window.open(vfPageURL);
        component.set("v.showSpinner", false);
        //helper.exportAllScheduledReports(component, event, helper);   
    },
    exportFilteredReports: function(component, event, helper){
        component.set("v.showSpinner", true);
        var vfPageURL = "https://" + window.location.hostname;
        vfPageURL += "/apex/SA_Audit__FilteredReportsExcel";    
        window.open(vfPageURL);
        component.set("v.showSpinner", false);
        //helper.exportAllScheduledReports(component, event, helper);   
    },
    exportSubscribedReports: function(component, event, helper){
        component.set("v.showSpinner", true);
        var vfPageURL = "https://" + window.location.hostname;
        vfPageURL += "/apex/SA_Audit__SubscribedReportsExcel";
        window.open(vfPageURL);
        component.set("v.showSpinner", false);
    },
    archiveNowReports: function(component, event, helper){
        var folderIds = component.get("v.folderIds");
        var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        //Display Error msg if none option ise selected
        if(selectedDate == null && selectedOption == ''){
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select either Date or month");
        } 
        else {
            if(folderIds == ''){
            component.set("v.showSpinner", false);
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select al least one Folder");
            }
            else{
                component.set("v.showSpinner", true);
                component.set("v.errorMsgBoolean", false);
                component.set("v.titleOfError", "");
                component.set("v.severityError", "");
                component.set("v.errMsgSecond", "");
                helper.archiveTheReports(component, event, helper);
            }
        }
    },
    selectAllFoldersChange: function(component, event, helper){
        var flag = component.get("v.selectAllFolders");
        var folderIds = [];
        if(flag){
            var folderList = component.get("v.folderList");
            for(var i = 0; i < folderList.length; i++){
                if(folderList[i].value != 'selectAll'){
                    folderIds.push(folderList[i].value);
                }
            }
        }
        component.set("v.folderIds", folderIds);
        console.log('flag>>>' + flag);
    },
    openContactUSLink: function(component, event, helper){
        window.open('https://applicationperfection.com/contact/');
    },
    openRealeaseNotesLink: function(component, event, helper){
        window.open('https://applicationperfection.com/reportmanagerpostinstallsteps/');
    },
    /*handleScheduleArchive: function(component, event, helper){
        var scheduleArchive = component.find("input2").get("v.checked");
        console.log('scheduleArchive>>>>' + scheduleArchive);
    },*/
    userIdChange: function(component, event, helper){
        var userId = event.getParam('value');
        //console.log('userId>>>>' + userId);
        component.set("v.userId", userId);
    },
    selectedDateChangeHandler: function(component, event, helper){
        //console.log('We are in selectedDateChangeHandler>>>>');
        var selectedDate = component.get("v.selectedDate");
        if(selectedDate != null){
            component.set("v.selectedDropdownValue", '');
            component.find('select').set('v.value', '');
        }
    },
    viewReports: function(component, event, helper){
        component.set("v.choice", "");
        var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        //Display Error msg if none option ise selected
        if(selectedDate == null && selectedOption == ''){
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select either Date or month");
        }
        else{
            component.set("v.showSpinner", true);
            helper.viewReportsData(component, event, helper);
            component.set("v.errorMsgBoolean", false);
            component.set("v.titleOfError", "");
            component.set("v.severityError", "");
            component.set("v.errMsgSecond", ""); 
        }
    },
    exportReports: function(component, event, helper){
        var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        //Display Error msg if none option ise selected
        if(selectedDate == null && selectedOption == ''){
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select either Date or month");
        }
        else{
            component.set("v.showSpinner", true);
            helper.exportExcelReports(component, event, helper);
            component.set("v.errorMsgBoolean", false);
            component.set("v.titleOfError", "");
            component.set("v.severityError", "");
            component.set("v.errMsgSecond", ""); 
        }
    },
    exportArchivedReports: function(component, event, helper){
        /*var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        //Display Error msg if none option ise selected
        if(selectedDate == null && selectedOption == ''){
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select either Date or month");
        }
        else{*/
        component.set("v.showSpinner", true);
        helper.exportArchivedReports(component, event, helper);
        component.set("v.errorMsgBoolean", false);
        component.set("v.titleOfError", "");
        component.set("v.severityError", "");
        component.set("v.errMsgSecond", ""); 
        //}
    },
    viewArchivedReports: function(component, event, helper){
        component.set("v.choice", "");
        /*var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        //Display Error msg if none option ise selected
        if(selectedDate == null && selectedOption == ''){
            component.set("v.errorMsgBoolean", true);
            component.set("v.titleOfError", "Error");
            component.set("v.severityError", "error");
            component.set("v.errMsgSecond", "Please select either Date or month");
        }
        else{*/
        component.set("v.showSpinner", true);
        helper.viewArchivedData(component, event, helper);
        component.set("v.errorMsgBoolean", false);
        component.set("v.titleOfError", "");
        component.set("v.severityError", "");
        component.set("v.errMsgSecond", "");    
        //}
    },
    selectAllReportsChange: function(component, event, helper){
        var flag = component.get("v.selectAllCheckbox");
        component.set("v.showSpinner", true);
        //var booleanData = component.get("v.readyToUnarchived");
        if(flag){
                var jsonData = component.get("v.jsonData");
                for(var i = 0; i < jsonData.length; i++){
                    jsonData[i].checked = true;
                }
            component.set("v.jsonData", jsonData);
            component.set("v.readyToUnarchived", true);
        }
        else{
            var jsonData = component.get("v.jsonData");
            for(var i = 0; i < jsonData.length; i++){
                jsonData[i].checked = false;
            }
            component.set("v.jsonData", jsonData);
            component.set("v.readyToUnarchived", false);
        }
        component.set("v.showSpinner", false);
    },
    selectOneCheckbox: function(component, event, helper){
        if(event.getParam('checked')){
            component.set("v.readyToUnarchived", true);
        }
    },
    unarchivedSelectedReports: function(component, event, helper){
        component.set("v.showSpinner", true);
        helper.unarchivedToOriginalFolders(component, event, helper);
    },
   /* downloadCsv: function(component, event, helper){
        // get the Records [report] list from 'jsonData' attribute 
        var reportData = component.get("v.jsonData");
        
        // call the helper function which "return" the CSV data as a String   
        var csv = helper.convertArrayOfObjectsToCSV(component,reportData);   
        if (csv == null){return;}
        var selectedOption = component.get("v.selectedDropdownValue");
        var selectedDate = component.get("v.selectedDate");
        var fileName;
        var choice = component.get("v.choice");
        var fileName =  choice + '_exportData.csv';
		let csvData = new Blob([csv], {
            type: "data:application/vnd.ms-excel;charset=utf-8,\uFEFF"
        });
        var csvUrl = URL.createObjectURL(csvData);        
        // ####--code for create a temp. <a> html tag [link tag] for download the CSV file--####     
        var hiddenElement = document.createElement('a');
        // hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
        // hiddenElement.target = '_self'; //
        hiddenElement.href = csvUrl; 
        hiddenElement.download = fileName;  // CSV file Name* you can change it.[only name not .csv] 
        document.body.appendChild(hiddenElement); // Required for FireFox browser
        hiddenElement.click(); // using click() js function to download csv file
    },*/
})