/*
Author     : Himanshu Kr. Varshney
Description: Lightning component Controller for Intel Tab.
*/
({
    exportToExcel : function(component, event, helper){
        var selectedValue   = component.get("v.value");
        var selectedOptions = component.get("v.selectedOptions");
        //Condition if We Click Directly on Export to Excel Option
        if(selectedValue == ''){
            component.set("v.errorMsgBool", true);
            component.set("v.titleOfErr", "Error");
            component.set("v.severityErr", "error");
            component.set("v.errMsgSecond", "Please Select an Option");
        }
        //Condition if We Click Directly on Export to Excel Option without Selecting any Object
        else if(selectedOptions  == '' 
                && selectedValue == 'option12'){
            component.set("v.errorMsgBool", true);
            component.set("v.titleOfErr", "Error");
            component.set("v.severityErr", "error");
            component.set("v.errMsgSecond", "Please Select At least One Object");
        }
        else{
            component.set("v.errorMsgBool", false);
            component.set("v.titleOfErr", "");
            component.set("v.severityErr", "");
            component.set("v.errMsgSecond", "");
            component.set("v.showSpinner", true);
            helper.downloadExcel(component, event, helper);
        }
    },
    
    /*doInit: function(component, event, helper){  
        component.set("v.showSpinner", false);
        console.log('>>>??????' + ((typeof sforce != 'undefined') && sforce && (!!sforce.one)));
        //It will Call Helper Method to get all Standard and Custom Objects Data(Name etc.)
        helper.getObjectNames(component, event, helper);
        helper.getOWDData(component, event, helper);
         helper.getListOfIDs(component, event, helper); 
         helper.getManagedPackageLicenseData(component, event, helper);   
        helper.getProfileNames(component, event, helper);
        helper.getUserNames(component, event, helper);
        
        
    // Call the Apex method to check if the user has access
    var action = component.get("c.PaidFeatureAccess");
    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            component.set("v.hasAccess", response.getReturnValue());
        } else {
            console.error("Failed to retrieve access information: " + response.getError());
        }

        // Hide the spinner after all operations are complete
        component.set("v.showSpinner", false);
    });
    $A.enqueueAction(action);
        
    },*/
    doInit: function(component, event, helper) {
    // Show spinner while loading essential data
    component.set("v.showSpinner", true);

    console.log('>>>??????' + ((typeof sforce != 'undefined') && sforce && (!!sforce.one)));

    // Call the Apex method to check if the user has access (essential data)
    var action = component.get("c.PaidFeatureAccess");
    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            component.set("v.hasAccess", response.getReturnValue());
        } else {
            console.error("Failed to retrieve access information: " + response.getError());
        }

        // Hide spinner after this operation is complete
        component.set("v.showSpinner", false);

        // Lazy load non-essential data after initial loading
        setTimeout(function() {
            helper.getObjectNames(component, event, helper);
            helper.getOWDData(component, event, helper);
            helper.getListOfIDs(component, event, helper);
            helper.getManagedPackageLicenseData(component, event, helper);
            helper.getProfileNames(component, event, helper);
            helper.getUserNames(component, event, helper);
        }, 0);
    });
    $A.enqueueAction(action);
},
   

    
    handleLinkClick: function(component, event, helper) {
        console.log('hellp');
       var referrer = document.referrer;
       var anchorId = 'url';
        
        if(referrer.indexOf(anchorId) !== -1){
            console.log('hellp2');
            var div = document.getElementById('highlightedText');
            div.style.backgroundColor = 'yellow';
        }
          //  window.onload = handleLinkClick;
    },
   
    closeValuesModel: function(component, event, helper){
        //Set isModalOpen attribute to false  
        component.set("v.isSelectedValues", false);
        component.set("v.selectedValues", '');
    },
     handlSelectedValuesChange: function (component, event, helper){
        var selectedValue = event.getParam("value");
        component.set("v.selectedValues", selectedValue);
        console.log('selectedValues_JS'+component.set("v.selectedValues", selectedValue));

    },    
    //Export Details
     submitvaluesDetails: function (component, event, helper){
       var selectedOption = component.get("v.selectedValues");
        
        //If We click on Directly Save Button without Selecting any Object
        if(selectedOption == ''){
        }
        else{
            component.set("v.isSelectedValues", false);
        }
         console.log('selectedOptionjs='+selectedOption)
       helper.batchApexExecutionToSendAnEmail(component, event, helper);
    },
    closeModel: function(component, event, helper){
        //Set isModalOpen attribute to false  
        component.set("v.isModalOpen", false);
         component.set("v.isModalOpen2", false);
    },
    closeProfileModel: function(component, event, helper){
        //Set isModalOpen attribute to false  
        component.set("v.isProfileModal", false);
        component.set("v.selectedProfile", '');
    },
    closeUserModel: function(component, event, helper){
        //Set isModalOpen attribute to false  
        component.set("v.isUserModal", false);
        component.set("v.selectedUsers", '');
    },
    submitDetails: function(component, event, helper){
        var selectedOptions = component.get("v.selectedOptions");
        //If We click on Directly Save Button without Selecting any Object
        if(selectedOptions == ''){
        }
        else{
            component.set("v.isModalOpen", false);
            component.set("v.isModalOpen2", false);
        }
    },
    SyncData: function(component,event,helper){
        component.set("v.showSpinner", true);
     //   helper.deleteExistingReports(component, event, helper);
        helper.DeleteRecordsCall(component, event, helper);
         component.set("v.titleOfsucBool", true);
         component.set("v.titleOfsuc", "   Sync Data Complete !!"); 
    },
    // pagination
    handleNext: function(component, event, helper) {
        var pageNumber = component.get("v.PageNumber") + 1;
         console.log('pageNumber=',pageNumber);
        var pageSize = component.get("v.pageSize");
         console.log('pageSize=',pageSize);
         component.set("v.showSpinner", true);
         var selectedOptions = component.get("v.selectedOptions");
        var selectedValue = component.get("v.value");  
         console.log('selectedValue:', selectedValue);
         if( selectedValue == 'option10' ){
             
            helper.fetchData(component, pageNumber, pageSize);
        } 
        else if(selectedOptions == 'option9'){
          
            helper.fetchActivePsetData(component, pageNumber, pageSize);
        }  
        else if(selectedOptions == 'option31'){
             
            helper.fetchInActivePsetData(component, pageNumber, pageSize);
        } 
        else if(selectedOptions == 'option30'){
             
            helper.fetchUserPermissionGrpAccess(component, pageNumber, pageSize);
        } 
        else if(selectedValue == 'option4'){
           console.log('Fetching data for option4, page:', pageNumber);
             console.log('Selected Options:', selectedValue);
            helper.fetchUserData(component, pageNumber, pageSize);
        }
        else if(selectedValue == 'option5'){
           console.log('Fetching data for option5, page:', pageNumber);
             console.log('Selected Options:', selectedValue);
            helper.fetchUserProfileData(component, pageNumber, pageSize);
        }
        else if(selectedValue == 'option6'){
           console.log('Fetching data for option6, page:', pageNumber);
             console.log('Selected Options:', selectedValue);
            helper.fetchUserProfile(component, pageNumber, pageSize);
        }
            else if(selectedValue == 'option29'){
           console.log('Fetching data for option29, page:', pageNumber);
             console.log('Selected Options:', selectedValue);
            helper.fetchUserLicenseData(component, pageNumber, pageSize);
        }
        
        
    },
    
    handlePrev: function(component, event, helper) {
        var pageNumber = component.get("v.PageNumber") - 1;
        console.log('pageNumber=',pageNumber);
        var selectedOptions = component.get("v.selectedOptions");
         var selectedValue = component.get("v.value");  
         console.log('selectedValue:', selectedValue);
        if (pageNumber >= 1) {
            var pageSize = component.get("v.pageSize");
            component.set("v.showSpinner", true);
            
        if(selectedOptions == 'option10'){
            
            helper.fetchData(component, pageNumber, pageSize);
        } 
        else if(selectedOptions == 'option9'){
            
            helper.fetchActivePsetData(component, pageNumber, pageSize);
        }  
        else if(selectedOptions == 'option31'){
             
            helper.fetchInActivePsetData(component, pageNumber, pageSize);
        } 
        else if(selectedOptions == 'option30'){
            
            helper.fetchUserPermissionGrpAccess(component, pageNumber, pageSize);
        } 
        else if(selectedValue == 'option4'){
            console.log('Fetching data for option4, page:', pageNumber);
            helper.fetchUserData(component, pageNumber, pageSize);
        }
        else if(selectedValue == 'option5'){
           console.log('Fetching data for option5, page:', pageNumber);
             console.log('Selected Options:', selectedValue);
            helper.fetchUserProfileData(component, pageNumber, pageSize);
        }
        else if(selectedValue == 'option6'){
           console.log('Fetching data for option6, page:', pageNumber);
             console.log('Selected Options:', selectedValue);
            helper.fetchUserProfile(component, pageNumber, pageSize);
        }
         else if(selectedValue == 'option29'){
           console.log('Fetching data for option29, page:', pageNumber);
             console.log('Selected Options:', selectedValue);
            helper.fetchUserLicenseData(component, pageNumber, pageSize);
        }
        }
    },
    closeoption28Modal: function(component, event, helper) {
        component.set("v.showoption28Modal", false);
    },
    
    onSelectChange: function(component, event, helper) {
        var page = 1;
        var pageSize = component.find("pageSize").get("v.value");
        var selectedOptions = component.get("v.selectedOptions");
        if(selectedOptions = 'option10'){
            helper.fetchData(component, page, pageSize);
        }else if(selectedOptions = 'option9'){
            helper.fetchActivePsetData(component, page, pageSize);
        }  else if(selectedOptions = 'option31'){
            helper.fetchInActivePsetData(component, pageNumber, pageSize);
        }
        else if(selectedOptions = 'option30'){
            helper.fetchUserPermissionGrpAccess(component, pageNumber, pageSize);
        }
    },

 // end pagination    
    viewData: function(component, event, helper){
        var selectedValue   = component.get("v.value");
        
        
       
       //alert('========se;lectedValue====='+selectedValue)
        var selectedOptions = component.get("v.selectedOptions");
        var selectedOption = component.get("v.selectedProfile");
        //Condition if We Click Directly on View Data Button
        if(selectedValue == ''){
            component.set("v.errorMsgBool", true);
            component.set("v.titleOfErr", "Error");
            component.set("v.severityErr", "error");
            component.set("v.errMsgSecond", "Please Select an Option");
        } 
        
        //Condition if We Click Directly on Export to Excel Option without Selecting any Object
        else if(selectedOptions  == '' && selectedValue == 'option12'){
            component.set("v.errorMsgBool", true);
            component.set("v.titleOfErr", "Error");
            component.set("v.severityErr", "error");
            component.set("v.errMsgSecond", "Please Select At least One Object");
        }
        else if(selectedOption == '' && selectedValue == 'option28'){
            component.set("v.errorMsgBool", true);
            component.set("v.titleOfErr", "Error");
            component.set("v.severityErr", "error");
            component.set("v.errMsgSecond", "Please Select At least One Profile");
        }
          else if(selectedOption == '' && selectedValue == 'option34'){
            component.set("v.errorMsgBool", true);
            component.set("v.titleOfErr", "Error");
            component.set("v.severityErr", "error");
            component.set("v.errMsgSecond", "Please Select At least One Profile");
        }
         else if(selectedOption == '' && selectedValue == 'option35'){
             //var selectedOptionValue = event.getParam("value");
       		 component.set("v.showSpinner", true);
                component.set("v.readyToDownloadSecond", false);
                helper.generateTable(component, event, helper);
            
        }
         else if(selectedOption == '' 
                && selectedValue == 'option36'){
             //var selectedOptionValue = event.getParam("value");
       		 component.set("v.showSpinner", true);
                component.set("v.readyToDownloadSecond", false);
                helper.generateTable(component, event, helper);
            
        }
        else if(selectedOption == '' 
                && selectedValue == 'option37'){
                
                component.set("v.showSpinner", true);
                helper.generateTable(component, event, helper);
            }
        
        else if(selectedOption == '' 
                && selectedValue == 'option38'){
                
                component.set("v.showSpinner", true);
                helper.generateTable(component, event, helper);
            }
         else if(selectedOption == '' 
                && selectedValue == 'option39'){
                
                component.set("v.showSpinner", true);
                helper.fetchoption39(component, event, helper);
            }
        
        
         else if(selectedValue == 'option10'){
                var pageNumber = 1;
                var pageSize = 2000;
             component.set("v.showSpinner", true);
                helper.fetchData(component, pageNumber, pageSize);
            }
        else if(selectedValue == 'option9'){
                var pageNumber = 1;
                var pageSize = 2000;
             component.set("v.showSpinner", true);
                helper.fetchActivePsetData(component, pageNumber, pageSize);
            }
        else if(selectedValue == 'option31'){
                var pageNumber = 1;
                var pageSize = 2000;
             component.set("v.showSpinner", true);
                helper.fetchInActivePsetData(component, pageNumber, pageSize);
            }
        else if(selectedValue == 'option30'){
                var pageNumber = 1;
                var pageSize = 2000;
             component.set("v.showSpinner", true);
                helper.fetchUserPermissionGrpAccess(component, pageNumber, pageSize);
            }
         else if(selectedValue == 'option4'){
                var pageNumber = 1;
                var pageSize = 2000;
                component.set("v.showSpinner", true);
                helper.fetchUserData(component, pageNumber, pageSize);
            }
         else if(selectedValue == 'option5'){
                var pageNumber = 1;
                var pageSize = 2000;
                component.set("v.showSpinner", true);
                helper.fetchUserProfileData(component, pageNumber, pageSize);
            }
             else if(selectedValue == 'option6'){
                var pageNumber = 1;
                var pageSize = 2000;
                component.set("v.showSpinner", true);
                helper.fetchUserProfile(component, pageNumber, pageSize);
            }
        else if(selectedValue == 'option29'){
                var pageNumber = 1;
                var pageSize = 2000;
                component.set("v.showSpinner", true);
                helper.fetchUserLicenseData(component, pageNumber, pageSize);
            }
       
        else{
           /* if(selectedValue != 'option12' || selectedValue != 'option10' || selectedValue != 'option9'|| selectedValue != 'option31' || selectedValue != 'option30' || selectedValue != 'option4' || selectedValue != 'option5' || selectedValue != 'option29'){
                 alert('hellonot');
                component.set("v.showSpinner", true);
                component.set("v.readyToDownloadSecond", false);
                helper.generateTable(component, event, helper);
            } */
            if(selectedValue != 'option12' && selectedValue != 'option10' && selectedValue != 'option9' && selectedValue != 'option31' && selectedValue != 'option30' && selectedValue != 'option4' && selectedValue != 'option5' && selectedValue != 'option29') {
               // alert('hellonot');
                if(selectedValue == 'option28'){
                     component.set("v.showoption28Modal", true);
                }
                else{
                component.set("v.showSpinner", true);
                }
                component.set("v.readyToDownloadSecond", false);
                helper.generateTable(component, event, helper);
            }
            
            else{
               // alert('hello');
                component.set("v.showSpinner", true);
            	//Method to get All Data like Layouts etc. of Selected Objects
            	helper.getAllObjectDetails(component, event, helper);
            }
            component.set("v.errorMsgBool", false);
            component.set("v.titleOfErr", "");
            component.set("v.severityErr", "");
            component.set("v.errMsgSecond", "");
            component.set("v.titleOfsucBool", false);
            //Method to get All Data like Layouts etc. of Selected Objects
            //helper.getAllObjectDetails(component, event, helper);
        }
    },
    handleChange: function (component, event, helper){
        var selectedOptionValue = event.getParam("value");
        component.set("v.selectedOptions", selectedOptionValue);
         console.log('selectedOptions'+component.set("v.selectedOptions", selectedOptionValue));
    },
    handleChange1: function (component, event, helper){
        var selectedprofileValue = event.getParam("value");
        component.set("v.selectedProfile", selectedprofileValue);
        console.log('selectedProfile'+component.set("v.selectedProfile", selectedprofileValue));
    },
     handleChangeUser: function (component, event, helper){
        var selectedUserValue = event.getParam("value");
        component.set("v.selectedUsers", selectedUserValue);
        console.log('selectedUsers'+component.set("v.selectedUsers", selectedUserValue));
    },
    submitProfileDetails: function (component, event, helper){
       var selectedOption = component.get("v.selectedProfile");
        console.log('selectedproileoption'+selectedOption)
        //If We click on Directly Save Button without Selecting any Object
        if(selectedOption == ''){
        }
        else{
            component.set("v.isProfileModal", false);
        }
    },
     submitUserDetails: function (component, event, helper){
       var selectedOption = component.get("v.selectedUsers");
        console.log('selectedproileoption'+selectedOption)
        //If We click on Directly Save Button without Selecting any Object
        if(selectedOption == ''){
        }
        else{
            component.set("v.isUserModal", false);
        }
    },
    
    handlePsetClick : function(component, event, helper){
         var permissionSetUrl = '/lightning/r/PermissionSet/' + component.get("v.firstCol.Id") + '/view';
        component.set("v.permissionSetUrl", permissionSetUrl);
    },
    
    //Below function is being called whenever Radio Button is Being Selected
    valueChnage: function(component, event, helper){
        component.set("v.value", event.getSource().get('v.value'));
        
        var selectedValue = component.get("v.value");   
       // alert('=======selectedValue===='+selectedValue);
        if(selectedValue == 'option12'){
            component.set("v.isModalOpen", true);
        }
          if(selectedValue == 'option37'){
            component.set("v.isUserModal", true);
        }
        
         if(selectedValue == 'option38'){
            component.set("v.isModalOpen2", true);
        }
        
        console.log('entry'+'selectedValue'+selectedValue);
        if(selectedValue == 'option28'){
            //alert('dfdfd')
            component.set("v.isProfileModal", true);
        }
         if(selectedValue == 'option34'){
            //alert('dfdfd')
            component.set("v.isProfileModal", true);
        }
        if(selectedValue == 'option35'){
            //alert('dfdfd')
            component.set("v.isModalOpen", true);
        } 
        if(selectedValue == 'option36'){
            
            component.set("v.isModalOpen2", true);
        }
        /*if(selectedValue == 'option17'){
            component.set("v.errorMsgBool", true);
            component.set("v.titleOfErr", "Warning");
            component.set("v.severityErr", "warning");
            component.set("v.errMsg", "You can fetch Apex Triggers and Apex Classes upto 1000");
            component.set("v.errMsgSecond", "");
        }
        else{
            component.set("v.errorMsgBool", false);
            component.set("v.titleOfErr", "");
            component.set("v.severityErr", "");
            component.set("v.errMsg", "");

        }*/
        component.set("v.readyToDownload", false);
        component.set("v.readyToDownloadSecond", false);
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
    exportAllReports: function(component, event, helper){
           component.set("v.isSelectedValues", true);
        //helper.batchApexExecutionToSendAnEmail(component, event, helper);
    },
    /*listViewExportAll: function(component, event, helper){
        helper.listViewExport(component, event, helper);
    },
    previousPage: function(component, event, helper){
        component.set("v.showSpinner", true);
        var page = component.get("v.page");
        page -= 1;
        component.set("v.page", page);
        var offSetValue = component.get("v.offSetValue");
        offSetValue -= 50;
        component.set("v.offSetValue", offSetValue);
        console.log('page>>>>' + page);
        helper.generateTable(component, event, helper);
    },
    nextPage: function(component, event, helper){
        var offSetValue = component.get("v.offSetValue");
        offSetValue += 50;
        component.set("v.offSetValue", offSetValue);
        component.set("v.showSpinner", true);
        var page = component.get("v.page");
        page += 1;
        component.set("v.page", page);
        console.log('page>>>>' + page);
        helper.generateTable(component, event, helper);
    }*/

    downloadCsv: function(component, event, helper){
        // get the Records [report] list from 'jsonData' attribute 
        var reportData = component.get("v.jsonData");
        
        // call the helper function which "return" the CSV data as a String   
        var csv = helper.convertArrayOfObjectsToCSV(component,reportData);   
        if (csv == null){return;}
        var selectedValue = component.get("v.value");
        var fileName =  selectedValue + '_exportData.csv';
		var blob = new Blob([csv], {
            type: "data:application/vnd.ms-excel;charset=utf-8,\uFEFF"
        });   
        if (navigator.msSaveBlob) { // IE 10+
        	navigator.msSaveBlob(blob, exportedFilenmae);
    	} else {
            var link = document.createElement("a");
            if (link.download !== undefined) { // feature detection
                // Browsers that support HTML5 download attribute
                var url = URL.createObjectURL(blob);
                link.setAttribute("href", url);
                link.setAttribute("download", fileName);
                link.style.visibility = 'hidden';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
            }
    	}
    },
 
    onNext: function(component, event, helper) {        
        let pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber + 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onPrev: function(component, event, helper) {        
        let pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber - 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onFirst: function(component, event, helper) {        
        component.set("v.currentPageNumber", 1);
        helper.setPageDataAsPerPagination(component);
    },
     
    onLast: function(component, event, helper) {        
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.setPageDataAsPerPagination(component);
    },
 
    onPageSizeChange: function(component, event, helper) {        
        helper.preparePagination(component, component.get('v.filteredData'));
    },
    
})