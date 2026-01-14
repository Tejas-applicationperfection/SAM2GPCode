/*
Author     : Himanshu Kr. Varshney
Description: Lightning component Helper for Intel Tab.
*/
({
    //It will fetch the all Standard and Custom Objects Data
    getObjectNames: function(component, event, helper){
        var action = component.get("c.getAllObjectNames");
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS")
                               {
                                   var listData = [];
                                   for(var i = 0; i < response.getReturnValue().length; i++)
                                   {
                                       if(response.getReturnValue()[i].label    != undefined 
                                          && response.getReturnValue()[i].value != undefined)
                                       {
                                           listData.push({
                                               'label'        :   response.getReturnValue()[i].label,
                                               'value'        :   response.getReturnValue()[i].value,
                                               'type'         :   response.getReturnValue()[i].type,
                                               'pluralName'   :   response.getReturnValue()[i].pluralName,
                                           });
                                       }
                                   }
                                   listData.sort(function(a, b) {
                                       var labelA = a.label.toLowerCase();
                                       var labelB = b.label.toLowerCase();
                                       if (labelA < labelB) return -1;
                                       if (labelA > labelB) return 1;
                                       return 0;
                                   });
                                   //console.log('listdata'+listData);
                                   component.set("v.optionsDualList", listData);
                                   component.set("v.errorMsgBool", false);
                                   component.set("v.titleOfErr", "");
                                   component.set("v.severityErr", "");
                                   component.set("v.errMsgSecond", "");
                                   //this.getListOfIDs(component, event, helper);
                               }
                               else
                               {
                                   var errorMessage = '';
                                   if(state === "INCOMPLETE")
                                   {
                                       errorMessage = 'Some Error is Occured, Please Try Again Later';
                                   }
                                   else if(state === "ERROR")
                                   {
                                       errorMessage = action.getError()[0].message;
                                   } 
                                   component.set("v.errorMsgBool", true);
                                   component.set("v.titleOfErr", "Error");
                                   component.set("v.severityErr", "error");
                                   component.set("v.errMsgSecond", errorMessage);
                               }
                           } 
                          );
        
        $A.enqueueAction(action);
    },
    getUserNames : function(component, event, helper){
        console.log('entry getProfilesList');
        var action = component.get("c.getUserList");
        action.setCallback(this, function(response)
                           {
                               //console.log('entry64'+' response.getReturnValue()'+ response.getReturnValue());
                               var state = response.getState();
                               console.log('entry66'); 
                               console.log('state'+ state);
                               // console.log(' response.getReturnValue===='+ JSON.stringify(response.getReturnValue()));
                               // console.log('response.getReturnValue====' + response.getReturnValue());
                               if(state === "SUCCESS")
                               {
                                   console.log('success'+ state);
                                   component.set("v.UserDualList",response.getReturnValue());
                                   //console.log('UserDualList'+component.get("v.UserDualList"));
                                   
                                   component.set("v.errorMsgBool", false);
                                   component.set("v.titleOfErr", "");
                                   component.set("v.severityErr", "");
                                   component.set("v.errMsgSecond", "");
                                   
                               }
                               else
                               {
                                   var errorMessage = '';
                                   if(state === "INCOMPLETE")
                                   {
                                       errorMessage = 'Some Error is Occured, Please Try Again Later';
                                   }
                                   else if(state === "ERROR")
                                   {
                                       errorMessage = action.getError()[0].message;
                                   } 
                                   component.set("v.errorMsgBool", true);
                                   component.set("v.titleOfErr", "Error");
                                   component.set("v.severityErr", "error");
                                   component.set("v.errMsgSecond", errorMessage);
                               }
                           } 
                          );
        
        $A.enqueueAction(action);
        
    },
    
    getProfileNames : function(component, event, helper){
        console.log('entry getProfilesList');
        var action = component.get("c.getProfilesList");
        action.setCallback(this, function(response)
                           {
                               //console.log('entry64'+' response.getReturnValue()'+ response.getReturnValue());
                               var state = response.getState();
                               console.log('entry66'); 
                               console.log('state'+ state);
                               // console.log(' response.getReturnValue===='+ JSON.stringify(response.getReturnValue()));
                               // console.log('response.getReturnValue====' + response.getReturnValue());
                               if(state === "SUCCESS")
                               {
                                   console.log('success'+ state);
                                   component.set("v.ProfileDualList",response.getReturnValue());
                                   //console.log('ProfileDualList'+component.get("v.ProfileDualList"));
                                   
                                   component.set("v.errorMsgBool", false);
                                   component.set("v.titleOfErr", "");
                                   component.set("v.severityErr", "");
                                   component.set("v.errMsgSecond", "");
                                   
                               }
                               else
                               {
                                   var errorMessage = '';
                                   if(state === "INCOMPLETE")
                                   {
                                       errorMessage = 'Some Error is Occured, Please Try Again Later';
                                   }
                                   else if(state === "ERROR")
                                   {
                                       errorMessage = action.getError()[0].message;
                                   } 
                                   component.set("v.errorMsgBool", true);
                                   component.set("v.titleOfErr", "Error");
                                   component.set("v.severityErr", "error");
                                   component.set("v.errMsgSecond", errorMessage);
                               }
                           } 
                          );
        
        $A.enqueueAction(action);
        
        /* action.setCallback(this, function(response)
                           {
                               console.log('state entry');
                               var state = response.getState();
                               console.log('state'+state);
                               if(state === "SUCCESS")
                               {
                                  console.log('response.getReturnValue()'+response.getReturnValue());
                                   component.set("v.ProfileDualList", response.getReturnValue());
                                   
                                   component.set("v.errorMsgBool", false);
                                   component.set("v.titleOfErr", "");
                                   component.set("v.severityErr", "");
                                   component.set("v.errMsgSecond", "");
                                   //this.getListOfIDs(component, event, helper);
                               }
                               else
                               {
                                   var errorMessage = '';
                                   if(state === "INCOMPLETE")
                                   {
                                       errorMessage = 'Some Error is Occured, Please Try Again Later';
                                   }
                                   else if(state === "ERROR")
                                   {
                                       errorMessage = action.getError()[0].message;
                                   } 
                                   component.set("v.errorMsgBool", true);
                                   component.set("v.titleOfErr", "Error");
                                   component.set("v.severityErr", "error");
                                   component.set("v.errMsgSecond", errorMessage);
                               }
                           } 
                          );
        
        $A.enqueueAction(action);*/
    },
    //sync data button
    DeleteRecordsCall: function(component, event, helper){
        
        var action = component.get("c.fetchDeleteRecords"); 
        action.setCallback(this, function(response){
            var state = response.getState();
            console.log('Filtered state' + state);
            if(state === "SUCCESS"){
                console.log('Delete op.Complete'+state);
                component.set("v.showSpinner", false);
                component.set("v.titleOfsucBool", true);
                component.set("v.severityErr", "CONFIRM");
                component.set("v.titleOfsuc", "Sync Data Complete !!");
                
                
                
            }
            else{
                component.set("v.showSpinner", false);
                var errorMessage = '';
                if(state === "INCOMPLETE"){
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR"){
                    errorMessage = action.getError()[0].message;
                    console.log('Filtererrormessage>>>' + errorMessage);
                } 
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "");
                component.set("v.severityErr", "");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        $A.enqueueAction(action);
    },
    
    /* 
    getAllObjectDetails: function(component, event, helper){
        var selectedOptions = component.get("v.selectedOptions");
        var action          = component.get("c.getAllObjectDetails");
        action.setParams({
            objectNames: selectedOptions
        })
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS")
                               {
                                   var jsonData = response.getReturnValue();
                                   //console.log('jsonData>>>>>' + JSON.stringify(jsonData));
                                   var dataJSON = {};
                                   var layoutJSONData = {};
                                   var dataJSON1 = [];
                                   for(let i = 0; i < jsonData.length; i++)
                                   {
                                       var dataJSON = {};
                                       dataJSON["objectName"] = jsonData[i].objectName;
                                       var data = [];
                                       var firstColumn = [];
                                       firstColumn.push("Object Name");
                                       firstColumn.push("Field Name");
                                       firstColumn.push("API Name");
                                       firstColumn.push("Page Layout Name");
                                       data.push(firstColumn);
                                       var secondColumn = [];
                                       secondColumn.push(jsonData[i].objectName);
                                       secondColumn.push('');
                                       secondColumn.push('');
                                       var dummyCells = jsonData[i].layoutDatas.length;
                                       for(let h = 0; h < dummyCells; h++)
                                       {
                                           secondColumn.push(jsonData[i].layoutDatas[h].layoutName);
                                       }
                                       data.push(secondColumn);
                                       for(let j = 0; j < jsonData[i].allFieldInfos.length; j++)
                                       {
                                           var thirdColumn = [];
                                           thirdColumn.push('');
                                           thirdColumn.push(jsonData[i].allFieldInfos[j].label);
                                           thirdColumn.push(jsonData[i].allFieldInfos[j].apiName);
                                           var fieldApiName = jsonData[i].allFieldInfos[j].apiName;
                                           for(let k = 0; k < jsonData[i].layoutDatas.length; k++)
                                           {
                                               var fieldInfoList = jsonData[i].layoutDatas[k].fieldInfos;
                                               if(fieldInfoList.indexOf(fieldApiName) >= 0)
                                               {
                                                   thirdColumn.push("Yes");
                                               }
                                               else{
                                                   thirdColumn.push("No");
                                               }
                                           }
                                           data.push(thirdColumn);
                                       }
                                       dataJSON["fieldInfo"] = data;
                                       dataJSON1.push(dataJSON);
                                   }
                                   component.set("v.showSpinner", false);
                                   component.set("v.jsonData", dataJSON1);
                                   component.set("v.isModalOpen", false);
                                   component.set("v.errorMsgBool", false);
                                   component.set("v.readyToDownload", true);
                                   component.set("v.titleOfErr", "");
                                   component.set("v.severityErr", "");
                                   component.set("v.errMsgSecond", "");
                                   //component.set("v.readyToDownload", true); 
                               }
                               else
                               {
                                   component.set("v.showSpinner", false);
                                   component.set("v.isModalOpen", false);
                                   component.set("v.readyToDownload", false);
                                   var errorMessage = '';
                                   if(state === "INCOMPLETE")
                                   {
                                       errorMessage = 'Some Error is Occured.';
                                   }
                                   else if(state === "ERROR")
                                   {
                                       errorMessage = action.getError()[0].message;
                                   } 
                                   component.set("v.errorMsgBool", true);
                                   component.set("v.titleOfErr", "Error");
                                   component.set("v.severityErr", "error");
                                   component.set("v.errMsgSecond", errorMessage);
                               }
                           } 
                          );
        $A.enqueueAction(action);
    },*/
    getAllObjectDetails: function(component, event, helper) {
        // alert('hellohelper');
        var selectedOptions = component.get("v.selectedOptions");
        var action = component.get("c.getAllObjectDetails");
        
        // Check if there are selected options
        if (selectedOptions.length === 0) {
            console.log('select something');
            return;
        }
        
        action.setParams({
            objectNames: selectedOptions
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var jsonData = response.getReturnValue();
                if (jsonData && jsonData.length > 0) {
                    var dataJSON1 = [];
                    for (var i = 0; i < jsonData.length; i++) {
                        var dataJSON = {};
                        dataJSON["objectName"] = jsonData[i].objectName;
                        var data = [];
                        var firstColumn = ["Object Name", "Field Name", "API Name", "Page Layout Name"];
                        data.push(firstColumn);
                        
                        var secondColumn = [jsonData[i].objectName, '', ''];
                        for (var h = 0; h < jsonData[i].layoutDatas.length; h++) {
                            secondColumn.push(jsonData[i].layoutDatas[h].layoutName);
                        }
                        data.push(secondColumn);
                        
                        for (var j = 0; j < jsonData[i].allFieldInfos.length; j++) {
                            var thirdColumn = ['', jsonData[i].allFieldInfos[j].label, jsonData[i].allFieldInfos[j].apiName];
                            var fieldApiName = jsonData[i].allFieldInfos[j].apiName;
                            for (var k = 0; k < jsonData[i].layoutDatas.length; k++) {
                                var fieldInfoList = jsonData[i].layoutDatas[k].fieldInfos;
                                thirdColumn.push(fieldInfoList.includes(fieldApiName) ? "Yes" : "No");
                            }
                            data.push(thirdColumn);
                        }
                        dataJSON["fieldInfo"] = data;
                        dataJSON1.push(dataJSON);
                    }
                    component.set("v.showSpinner", false);
                    component.set("v.jsonData", dataJSON1);
                    component.set("v.isModalOpen", false);
                    component.set("v.errorMsgBool", false);
                    component.set("v.readyToDownload", true);
                    component.set("v.titleOfErr", "");
                    component.set("v.severityErr", "");
                    component.set("v.errMsgSecond", "");
                } else {
                    // Handle the case where jsonData is empty
                    component.set("v.showSpinner", false);
                    component.set("v.isModalOpen", false);
                    component.set("v.readyToDownload", false);
                    component.set("v.errorMsgBool", true);
                    component.set("v.titleOfErr", "Error");
                    component.set("v.severityErr", "error");
                    component.set("v.errMsgSecond", "No data available.");
                }
            } else {
                // Handle the case where the server call was not successful
                component.set("v.showSpinner", false);
                component.set("v.isModalOpen", false);
                component.set("v.readyToDownload", false);
                var errorMessage = '';
                if (state === "INCOMPLETE") {
                    errorMessage = 'Some Error is Occured.';
                } else if (state === "ERROR") {
                    errorMessage = action.getError()[0].message;
                }
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
                component.set("v.errMsgSecond", errorMessage);
            }
        });
        
        $A.enqueueAction(action);
    },
    downloadExcel: function(component, event, helper){
        var selectedValue = component.get("v.value");
        var listOfIDs = component.get("v.listOfBatchIDs");
        var url = "https://" + window.location.hostname;
        if(selectedValue == 'option12'){
            var selectedOptions = component.get("v.selectedOptions");
            url += "/apex/SA_Audit__multipleExcelGenerator?recordId=" + selectedOptions; 
            console.log(' entry JSON'+selectedOptions);
        }
        else if(selectedValue == 'option35'){	
            var selectedOptions2 = component.get("v.selectedOptions");
            url += "/apex/SA_Audit__retrievePicklistValueExcel?selectedOptions=" + selectedOptions2;
            console.log(' entry JSON'+selectedOptions2);
        }	
            else if(selectedValue == 'option11'){
                component.set("v.showSpinner", true);
                this.getStatusOfAsyncProcess(component, event, helper);
            }
                else if(selectedValue == 'option10'){
                    url += "/apex/SA_Audit__PermissionSetsWithUsersExcel";      
                }
                    else if(selectedValue == 'option9'){
                        url += "/apex/SA_Audit__UserPermissionSetExcel";          
                    }
                        else if(selectedValue == 'option30'){
                            url += "/apex/SA_Audit__UserPermissionSetGroupAccess";          
                        }
                            else if(selectedValue == 'option31'){
                                url += "/apex/SA_Audit__InactiveUserPermissionSetExcel";          
                            }
                                else if(selectedValue == 'option33'){
                                    url += "/apex/SA_Audit__PermissionsetGroupAndPermissionSets";          
                                }
                                    else if(selectedValue == 'option8'){
                                        url += "/apex/SA_Audit__UserTerritoryExcel";            
                                    }
                                        else if(selectedValue == 'option7'){
                                            url += "/apex/SA_Audit__TerritoriesExcel";                
                                        }
                                            else if(selectedValue == 'option6'){
                                                url += "/apex/SA_Audit__UserProfileExcel";                 
                                            }
                                                else if(selectedValue == 'option5'){
                                                    url += "/apex/SA_Audit__UserProfileAndRoleExcel";                         
                                                }
                                                    else if(selectedValue == 'option4'){
                                                        url += "/apex/SA_Audit__UserRoleExcel";
                                                    } 
                                                        else if(selectedValue == 'option3'){
                                                            url += "/apex/SA_Audit__RolesExcel";                                
                                                        }
        
                                                            else if(selectedValue == 'option32'){
                                                                url += "/apex/SA_Audit__ExternalRolesExcel";                                
                                                            }
        
                                                                else if(selectedValue == 'option2'){
                                                                    component.set("v.showSpinner", true);
                                                                    this.getStatusOfAsyncProcess(component, event, helper);
                                                                }
                                                                    else if(selectedValue == 'option1'){
                                                                        component.set("v.showSpinner", true);
                                                                        this.getStatusOfAsyncProcess(component, event, helper);
                                                                    }
                                                                        else if(selectedValue == 'option22'){
                                                                            component.set("v.showSpinner", true);
                                                                            this.getStatusOfAsyncProcess(component, event, helper);
                                                                        }
                                                                            else if(selectedValue == 'option13'){
                                                                                url += "/apex/SA_Audit__SharingRulesExcel";
                                                                            }
                                                                                else if(selectedValue == 'option14'){
                                                                                    url += "/apex/SA_Audit__OWDReportExcel";
                                                                                }
                                                                                    else if(selectedValue == 'option15'){
                                                                                        url += "/apex/SA_Audit__PermissionSetWithNoUsersExcel";
                                                                                    }
                                                                                        else if(selectedValue == 'option16'){
                                                                                            url += "/apex/SA_Audit__ProfilesWithNoUserExcel";
                                                                                        }
                                                                                            else if(selectedValue == 'option17'){
                                                                                                url += "/apex/SA_Audit__ApexTriggersAndApexClassesExcel";
                                                                                            }
                                                                                                else if(selectedValue == 'option18'){
                                                                                                    url += "/apex/SA_Audit__PublicGroupExcel";
                                                                                                }
                                                                                                    else if(selectedValue == 'option19'){
                                                                                                        url += "/apex/SA_Audit__ManagedPackageLicenseExcel";
                                                                                                    }
                                                                                                        else if(selectedValue == 'option21'){
                                                                                                            url += "/apex/SA_Audit__DashboardReportExcel";
                                                                                                        }
                                                                                                            else if(selectedValue == 'option23'){
                                                                                                                url += "/apex/SA_Audit__ScheduledReportsExcel";
                                                                                                            }
                                                                                                                else if(selectedValue == 'option24'){
                                                                                                                    url += "/apex/SA_Audit__FilterReportsExcel";
                                                                                                                }
                                                                                                                    else if(selectedValue == 'option25'){
                                                                                                                        url += "/apex/SA_Audit__EmptyReportsExcel";
                                                                                                                    }
                                                                                                                        else if(selectedValue == 'option26'){
                                                                                                                            url += "/apex/SA_Audit__customAppExcel";
                                                                                                                        }
                                                                                                                            else if(selectedValue == 'option27'){
                                                                                                                                url += "/apex/SA_Audit__PublicGroupMembersExcel";
                                                                                                                            }
                                                                                                                                else if(selectedValue == 'option39'){
                                                                                                                                    url += "/apex/SA_Audit__Permissionsetnotassignedvf";
                                                                                                                                }
                                                                                                                                else if(selectedValue == 'option28'){
                                                                                                                                    var sPro = component.get("v.selectedProfile");
                                                                                                                                    
                                                                                                                                    console.log('spro'+sPro);
                                                                                                                                    url += "/apex/SA_Audit__profileconfigExcel?selectedprofile=" + JSON.stringify(sPro);
                                                                                                                                    console.log('sporJSON'+JSON.stringify(sPro));
                                                                                                                                    
                                                                                                                                }
                                                                                                                                    else if(selectedValue == 'option29'){	
                                                                                                                                        url += "/apex/SA_Audit__UserLicenseExcel";	
                                                                                                                                        
                                                                                                                                    }
                                                                                                                                        else if(selectedValue == 'option20'){
                                                                                                                                            //url += "/apex/SA_Audit__ManagedPackageLicenseExcel";
                                                                                                                                            component.set("v.showSpinner", true);
                                                                                                                                            this.getStatusOfAsyncProcess(component, event, helper);
                                                                                                                                        }
                                                                                                                                            else if(selectedValue == 'option34'){	
                                                                                                                                                var sPro2 = component.get("v.selectedProfile");
                                                                                                                                                url += "/apex/SA_Audit__RecordTypeAssignmentExcel?selectedprofile=" + JSON.stringify(sPro2);
                                                                                                                                                console.log('sporJSON'+JSON.stringify(sPro2));
                                                                                                                                                
                                                                                                                                            }
                                                                                                                                                else if(selectedValue == 'option36'){
                                                                                                                                                    var selectedOptions3 = component.get("v.selectedOptions");
                                                                                                                                                    console.log('selectedOptions3--',JSON.stringify(selectedOptions3));
                                                                                                                                                    url += "/apex/SA_Audit__pagelayoutAssignmentExcel?selectedOptions=" + selectedOptions3;
                                                                                                                                                    console.log(' entry JSON'+selectedOptions3);
                                                                                                                                                    
                                                                                                                                                }	
         																															else if(selectedValue == 'option37'){
                                                                                                                                                    var selectedUsers = component.get("v.selectedUsers");
                                                                                                                                                    console.log('selectedUsers--',JSON.stringify(selectedUsers));
                                                                                                                                                    url += "/apex/SA_Audit__UserAccessCompareExcel?selectedUsers=" + selectedUsers;
                                                                                                                                                    console.log(' entry JSON'+selectedOptions4);
                                                                                                                                                    
                                                                                                                                                }        																																		 else if(selectedValue == 'option38'){
                                                                                                                                                    var selectedOptions4 = component.get("v.selectedOptions");
                                                                                                                                                    console.log('selectedOptions3--',JSON.stringify(selectedOptions4));
                                                                                                                                                    url += "/apex/SA_Audit__TrackfieldExportExcel?selectedOptions=" + selectedOptions4;
                                                                                                                                                    console.log(' entry JSON'+selectedOptions4);
                                                                                                                                                    
                                                                                                                                                }	
        
        
        if(selectedValue != 'option1' && selectedValue != 'option2' && selectedValue != 'option11' && selectedValue != 'option20' && selectedValue != 'option22'){
            window.open(url);
        }
        component.set("v.showSpinner", false);
    },
    fetchUserData: function(component, pageNumber, pageSize) {
        console.log('pageNumber=',pageNumber,'pageSize=',pageSize);
        var action = component.get("c.fetchTableDataOption4");
        action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var wrapper = response.getReturnValue();
                console.log('Data received:', JSON.stringify(wrapper)); 
                component.set("v.jsonData", wrapper.dataa);
                component.set("v.TotalRecords", wrapper.totalRecordss);
                component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                component.set("v.RecordEnd", Math.min(pageNumber * pageSize, wrapper.totalRecordss));
                component.set("v.TotalPages1", Math.ceil(wrapper.totalRecordss / pageSize)); 
                component.set("v.PageNumber", pageNumber);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", true);
                component.set("v.errorMsgBool", false);
                component.set("v.titleOfErr", "");
                component.set("v.severityErr", "");
                component.set("v.errMsgSecond", "");      
            } else {
                console.error("Failed with state: " + state);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", false);
                var errorMessage = '';
                if(state === "INCOMPLETE")
                {
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR")
                {
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
            }
            //console.log('wrapper=',JSON.stringify(wrapper.dataa));
        });
        $A.enqueueAction(action);
    }, 
    fetchUserLicenseData: function(component, pageNumber, pageSize) {
        console.log('pageNumber=',pageNumber,'pageSize=',pageSize);
        var action = component.get("c.fetchTableDataOption29");
        action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var wrapper = response.getReturnValue();
                console.log('Data received:', JSON.stringify(wrapper)); 
                component.set("v.jsonData", wrapper.dataa);
                component.set("v.TotalRecords", wrapper.totalRecordss);
                component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                component.set("v.RecordEnd", Math.min(pageNumber * pageSize, wrapper.totalRecordss));
                component.set("v.TotalPages1", Math.ceil(wrapper.totalRecordss / pageSize)); 
                component.set("v.PageNumber", pageNumber);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", true);
                component.set("v.errorMsgBool", false);
                component.set("v.titleOfErr", "");
                component.set("v.severityErr", "");
                component.set("v.errMsgSecond", "");      
            } else {
                console.error("Failed with state: " + state);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", false);
                var errorMessage = '';
                if(state === "INCOMPLETE")
                {
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR")
                {
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
            }
            //console.log('wrapper=',JSON.stringify(wrapper.dataa));
        });
        $A.enqueueAction(action);
    },
    fetchUserProfileData: function(component, pageNumber, pageSize) {
        console.log('pageNumber=',pageNumber,'pageSize=',pageSize);
        var action = component.get("c.fetchTableDataOption5");
        action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var wrapper = response.getReturnValue();
                console.log('Data received:', JSON.stringify(wrapper)); 
                component.set("v.jsonData", wrapper.dataa);
                component.set("v.TotalRecords", wrapper.totalRecordss);
                component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                component.set("v.RecordEnd", Math.min(pageNumber * pageSize, wrapper.totalRecordss));
                component.set("v.TotalPages1", Math.ceil(wrapper.totalRecordss / pageSize)); 
                component.set("v.PageNumber", pageNumber);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", true);
                component.set("v.errorMsgBool", false);
                component.set("v.titleOfErr", "");
                component.set("v.severityErr", "");
                component.set("v.errMsgSecond", "");      
            } else {
                console.error("Failed with state: " + state);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", false);
                var errorMessage = '';
                if(state === "INCOMPLETE")
                {
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR")
                {
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
            }
            //console.log('wrapper=',JSON.stringify(wrapper.dataa));
        });
        $A.enqueueAction(action);
    },
    fetchUserAccessData: function(component, pageNumber, pageSize) {
        var action = component.get("c.fetchTableDataOption37");
        
    },
    
    
    
    fetchUserProfile: function(component, pageNumber, pageSize) {
        console.log('pageNumber=',pageNumber,'pageSize=',pageSize);
        var action = component.get("c.fetchTableDataOption5");
        action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var wrapper = response.getReturnValue();
                console.log('Data received:', JSON.stringify(wrapper)); 
                component.set("v.jsonData", wrapper.dataa);
                component.set("v.TotalRecords", wrapper.totalRecordss);
                component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                component.set("v.RecordEnd", Math.min(pageNumber * pageSize, wrapper.totalRecordss));
                component.set("v.TotalPages1", Math.ceil(wrapper.totalRecordss / pageSize)); 
                component.set("v.PageNumber", pageNumber);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", true);
                component.set("v.errorMsgBool", false);
                component.set("v.titleOfErr", "");
                component.set("v.severityErr", "");
                component.set("v.errMsgSecond", "");      
            } else {
                console.error("Failed with state: " + state);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", false);
                var errorMessage = '';
                if(state === "INCOMPLETE")
                {
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR")
                {
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
            }
            //console.log('wrapper=',JSON.stringify(wrapper.dataa));
        });
        $A.enqueueAction(action);
    },
   /* fetchData: function(component, pageNumber, pageSize) {
        console.log('pageNumber=',pageNumber,'pageSize=',pageSize);
        var action = component.get("c.fetchTableDataOption10");
        action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var wrapper = response.getReturnValue();
                component.set("v.jsonData", wrapper.data);
                component.set("v.TotalRecords", wrapper.totalRecords);
                component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                component.set("v.RecordEnd", Math.min(pageNumber * pageSize, wrapper.totalRecords));
                component.set("v.TotalPages1", Math.ceil(wrapper.totalRecords / pageSize)); 
                component.set("v.PageNumber", pageNumber);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", true);
                component.set("v.errorMsgBool", false);
                component.set("v.titleOfErr", "");
                component.set("v.severityErr", "");
                component.set("v.errMsgSecond", ""); 
            } else {
                console.error("Failed with state: " + state);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", false);
                var errorMessage = '';
                if(state === "INCOMPLETE")
                {
                    errorMessage = 'Some Error is Occured.';
                }
                else if(state === "ERROR")
                {
                    errorMessage = action.getError()[0].message;
                } 
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
            }
            console.log('wrapper=',JSON.stringify(wrapper.data));
        });
        $A.enqueueAction(action);
    },*/
 fetchData: function(component, pageNumber, pageSize) {
    console.log('pageNumber=', pageNumber, 'pageSize=', pageSize);

    // Validate input parameters
    if (pageNumber < 1 || pageSize < 1) {
        console.error("Invalid pageNumber or pageSize.");
        component.set("v.errorMsgBool", true);
        component.set("v.titleOfErr", "Error");
        component.set("v.severityErr", "error");
        component.set("v.errMsgSecond", "Invalid page number or page size.");
        return;
    }

    // Call the Apex method
    var action = component.get("c.fetchTableDataOption10");
    action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            var data = response.getReturnValue(); // Directly get the list of records
            if (data && data.length > 0) { // Check if data is not empty
                component.set("v.jsonData", data); // Set the data to a component attribute

                // Calculate pagination details
                var totalRecords = component.get("v.TotalRecords"); // Assuming totalRecords is already set
                component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                component.set("v.RecordEnd", Math.min(pageNumber * pageSize, totalRecords));
                component.set("v.TotalPages1", Math.ceil(totalRecords / pageSize));
                component.set("v.PageNumber", pageNumber);
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", true);
                component.set("v.errorMsgBool", false);
                component.set("v.titleOfErr", "");
                component.set("v.severityErr", "");
                component.set("v.errMsgSecond", "");
            } else {
                console.error("No data returned from server.");
                component.set("v.showSpinner", false);
                component.set("v.readyToDownload", false);
                component.set("v.readyToDownloadSecond", false);
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
                component.set("v.errMsgSecond", "No data returned from server.");
            }
        } else {
            console.error("Failed with state: " + state);
            component.set("v.showSpinner", false);
            component.set("v.readyToDownload", false);
            component.set("v.readyToDownloadSecond", false);
            var errorMessage = '';
            if (state === "INCOMPLETE") {
                errorMessage = 'Some Error Occurred.';
            } else if (state === "ERROR") {
                errorMessage = action.getError()[0].message;
            }
            component.set("v.errorMsgBool", true);
            component.set("v.titleOfErr", "Error");
            component.set("v.severityErr", "error");
            component.set("v.errMsgSecond", errorMessage);
        }
        console.log('data=', JSON.stringify(data));
    });
    $A.enqueueAction(action);
},
    fetchActivePsetData: function(component, pageNumber, pageSize) {
        console.log('pageNumber=', pageNumber, 'pageSize=', pageSize);
        var action = component.get("c.fetchTableDataOption9");
        action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var wrapper = response.getReturnValue();
                if (wrapper) { // Check if wrapper is not undefined
                    component.set("v.jsonData", wrapper.data);
                    component.set("v.TotalRecords", wrapper.totalRecords);
                    component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                    component.set("v.RecordEnd", Math.min(pageNumber * pageSize, wrapper.totalRecords));
                    component.set("v.TotalPages1", Math.ceil(wrapper.totalRecords / pageSize));
                    component.set("v.PageNumber", pageNumber);
                    component.set("v.showSpinner", false);
                    component.set("v.readyToDownload", false);
                    component.set("v.readyToDownloadSecond", true);
                    component.set("v.errorMsgBool", false);
                    component.set("v.titleOfErr", "");
                    component.set("v.severityErr", "");
                    component.set("v.errMsgSecond", "");
                } else {
                    console.error("No data returned from the server.");
                }
            } else {
                console.error("Failed with state: " + state);
                var errorMessage = '';
                if (state === "INCOMPLETE") {
                    errorMessage = 'Some Error Occurred.';
                } else if (state === "ERROR") {
                    var errors = action.getError();
                    if (errors && errors[0] && errors[0].message) {
                        errorMessage = errors[0].message;
                    } else {
                        errorMessage = "Unknown error";
                    }
                }
                console.error(errorMessage);
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
            }
            console.log('wrapper=', JSON.stringify(wrapper));
        });
        $A.enqueueAction(action);
    } ,
    fetchInActivePsetData: function(component, pageNumber, pageSize) {
        console.log('pageNumber=', pageNumber, 'pageSize=', pageSize);
        var action = component.get("c.fetchTableDataOption31");
        action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var wrapper = response.getReturnValue();
                if (wrapper) { // Check if wrapper is not undefined
                    component.set("v.jsonData", wrapper.data);
                    component.set("v.TotalRecords", wrapper.totalRecords);
                    component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                    component.set("v.RecordEnd", Math.min(pageNumber * pageSize, wrapper.totalRecords));
                    component.set("v.TotalPages1", Math.ceil(wrapper.totalRecords / pageSize));
                    component.set("v.PageNumber", pageNumber);
                    component.set("v.showSpinner", false);
                    component.set("v.readyToDownload", false);
                    component.set("v.readyToDownloadSecond", true);
                    component.set("v.errorMsgBool", false);
                    component.set("v.titleOfErr", "");
                    component.set("v.severityErr", "");
                    component.set("v.errMsgSecond", "");
                } else {
                    console.error("No data returned from the server.");
                }
            } else {
                console.error("Failed with state: " + state);
                var errorMessage = '';
                if (state === "INCOMPLETE") {
                    errorMessage = 'Some Error Occurred.';
                } else if (state === "ERROR") {
                    var errors = action.getError();
                    if (errors && errors[0] && errors[0].message) {
                        errorMessage = errors[0].message;
                    } else {
                        errorMessage = "Unknown error";
                    }
                }
                console.error(errorMessage);
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
            }
            console.log('wrapper=', JSON.stringify(wrapper));
        });
        $A.enqueueAction(action);
    },
    fetchUserPermissionGrpAccess: function(component, pageNumber, pageSize) {
        console.log('pageNumber=', pageNumber, 'pageSize=', pageSize);
        var action = component.get("c.fetchTableDataOption30");
        action.setParams({ pageNumber: pageNumber, pageSize: pageSize });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var wrapper = response.getReturnValue();
                if (wrapper && wrapper.data) { // Check if wrapper is not undefined
                    component.set("v.jsonData", wrapper.data);
                    component.set("v.TotalRecords", wrapper.totalRecords);
                    component.set("v.RecordStart", (pageNumber - 1) * pageSize + 1);
                    component.set("v.RecordEnd", Math.min(pageNumber * pageSize, wrapper.totalRecords));
                    component.set("v.TotalPages1", Math.ceil(wrapper.totalRecords / pageSize));
                    component.set("v.PageNumber", pageNumber);
                    component.set("v.showSpinner", false);
                    component.set("v.readyToDownload", false);
                    component.set("v.readyToDownloadSecond", true);
                    component.set("v.errorMsgBool", false);
                    component.set("v.titleOfErr", "");
                    component.set("v.severityErr", "");
                    component.set("v.errMsgSecond", "");
                } else {
                    console.error("No data returned from the server.");
                }
            } else {
                console.error("Failed with state: " + state);
                var errorMessage = '';
                if (state === "INCOMPLETE") {
                    errorMessage = 'Some Error Occurred.';
                } else if (state === "ERROR") {
                    var errors = action.getError();
                    if (errors && errors[0] && errors[0].message) {
                        errorMessage = errors[0].message;
                    } else {
                        errorMessage = "Unknown error";
                    }
                }
                console.error(errorMessage);
                component.set("v.errorMsgBool", true);
                component.set("v.titleOfErr", "Error");
                component.set("v.severityErr", "error");
            }
            console.log('wrapper=', JSON.stringify(wrapper));
        });
        $A.enqueueAction(action);
    },
    
    generateTable: function(component, event, helper){
        var selectedValue = component.get("v.value");
        var listOfIDs = component.get("v.listOfBatchIDs");
        if(selectedValue == 'option2'){
            var action = component.get("c.checkBatchApexProgress");
            action.setParams({
                jobId: listOfIDs[1]
            })        
        }
        if(selectedValue == 'option1'){
            var action = component.get("c.checkBatchApexProgress");
            action.setParams({
                jobId: listOfIDs[0]
            })
        }
        if(selectedValue == 'option11'){
            var action = component.get("c.checkBatchApexProgress");
            action.setParams({
                jobId: listOfIDs[2]
            })
        }
        if(selectedValue == 'option20'){
            var action = component.get("c.checkBatchApexProgress");
            action.setParams({
                jobId: listOfIDs[3]
            })
        }
        if(selectedValue == 'option22'){
            var action = component.get("c.checkBatchApexProgress");
            action.setParams({
                jobId: listOfIDs[4]
            })
        }
        if(selectedValue == 'option3' || selectedValue == 'option32')
        {
            var action = component.get("c.fetchTableDataOption3");
            action.setParams({
                selectedVal: component.get("v.value")
            })
        }
        /*if(selectedValue == 'option4'){
            var action = component.get("c.fetchTableDataOption4");
        }
        if(selectedValue == 'option5'){
            var action = component.get("c.fetchTableDataOption5");
        }*/
        if(selectedValue == 'option6'){
            var action = component.get("c.fetchTableDataOption6");
        }
        if(selectedValue == 'option7'){
            var action = component.get("c.fetchTableDataOption7"); 
        }
        if(selectedValue == 'option8'){
            var action = component.get("c.fetchTableDataOption8"); 
        }/*
        if(selectedValue == 'option9' || selectedValue == 'option31'){
            var action = component.get("c.fetchTableDataOption9");
            action.setParams({
                selectedVal: component.get("v.value")
            })
        }
        if(selectedValue == 'option10'){
            var action = component.get("c.fetchTableDataOption10"); 
                
        }
        if(selectedValue == 'option10'){
            var pageNumber = component.get("v.PageNumber");
            console.log('pageNumber='+pageNumber);
            var pageSize = component.get("v.pageSize");
             console.log('pageSize='+pageSize);
            var action = component.get("c.fetchTableDataOption10");
            action.setParams({
                "pageNumber": pageNumber,
                "pageSize": pageSize
            });
            
        }*/
        
        if(selectedValue == 'option13'){
            var action = component.get("c.fetchTableDataOption13"); 
        }
        if(selectedValue == 'option14'){
            var action = component.get("c.fetchTableDataOption14"); 
            console.log('-action--'+ action);
            
        }
        if(selectedValue == 'option15'){
            var action = component.get("c.fetchTableDataOption15");
        }
        if(selectedValue == 'option16'){
            var action = component.get("c.fetchTableDataOption16");
        }
        if(selectedValue == 'option17'){
            var action = component.get("c.fetchTableDataOption17");  
        }
        if(selectedValue == 'option18'){
            var action = component.get("c.fetchTableDataOption18");  
        }
        if(selectedValue == 'option19'){
            var action = component.get("c.fetchTableDataOption19");  
        }
        if(selectedValue == 'option21'){
            var action = component.get("c.fetchTableDataOption21");  
        }
        if(selectedValue == 'option23'){
            var action = component.get("c.fetchTableDataOption23");  
        }
        if(selectedValue == 'option24'){
            var action = component.get("c.fetchTableDataOption24");  
        }
        if(selectedValue == 'option25'){
            var action = component.get("c.fetchTableDataOption25");   
        }
        if(selectedValue == 'option26'){
            var action = component.get("c.fetchTableDataOption26");   
        }
        
        
        if(selectedValue == 'option27'){
            var action = component.get("c.fetchTableDataOption27");   
        }
        if (selectedValue == 'option28') {
            var action = component.get("c.fetchTableDataOption28");   
            action.setParams({ Selectedpro: component.get("v.selectedProfile") });
            
            console.log('Intelhelper432 - selected value: ' + selectedValue);
             component.set("v.isLoading", false);
          component.set("v.showSpinner", false);
             
            // Step 1: Show the modal first
            component.set("v.showoption28Modal", true);     
        }

        if(selectedValue == 'option37'){
            var action = component.get("c.fetchTableDataOption37");   
            action.setParams({SelectedUsers : component.get("v.selectedUsers")})
            
            
        }
        /*if(selectedValue == 'option29'){	
            var action = component.get("c.fetchTableDataOption29");  	
        }*/	
        if(selectedValue == 'option39'){	
            var action = component.get("c.fetchTableDataOption39"); 	
        }
        if(selectedValue == 'option33'){
            var action = component.get("c.fetchTableDataOption33");   
        }
        if(selectedValue == 'option34'){
            var action = component.get("c.fetchTableDataOption34");  
            action.setParams({Selectedpro : component.get("v.selectedProfile")})
            console.log('Entry in 34');
            console.log('-action.setParams--'+ action.setParams);
        }
        if(selectedValue == 'option35'){
            var action = component.get("c.fetchTableDataOption35");  
            action.setParams({selectedOptions : component.get("v.selectedOptions")})
            
        }
        if(selectedValue == 'option38'){
            var action = component.get("c.fetchTableDataOption38");  
            action.setParams({selectedOptions : component.get("v.selectedOptions")})
            
        }
        if(selectedValue == 'option36'){
            var action = component.get("c.fetchTableDataOption36");  
            var selectedOptions = component.get("v.selectedOptions");
            action.setParams({ selectedOptions: selectedOptions });
            //  action.setParams({selectedOptions : component.get("v.selectedOptions")})
            console.log('selectedOptionss='+component.get("v.selectedOptions"));
            console.log('-action.setParams--'+ action.setParams);
        }
        
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS"){
                                   if(selectedValue == 'option14'){
                                       component.set("v.jsonData", response.getReturnValue());
                                       var finalList = [];
                                       var strList = [];
                                       strList = response.getReturnValue().split('|');
                                       console.log('strList'+strList)
                                       for(var i = 0; i < strList.length; i++){
                                           var secondList = [];
                                           secondList = strList[i].split('?');
                                           finalList.push(secondList);
                                           
                                       }
                                       
                                       console.log('finalList' + finalList);
                                       component.set("v.jsonData", finalList);
                                       console.log('jsonData in Option14???' + JSON.stringify(component.get("v.jsonData")));
                                       component.set("v.showSpinner", false);
                                       component.set("v.readyToDownload", false);
                                       component.set("v.readyToDownloadSecond", true);
                                       component.set("v.errorMsgBool", false);
                                       component.set("v.titleOfErr", "");
                                       component.set("v.severityErr", "");
                                       component.set("v.errMsgSecond", "");
                                   } 
                                   else if(selectedValue == 'option26'){
                                       component.set("v.header",response.getReturnValue().header);
                                       component.set("v.allData",response.getReturnValue().body);
                                       component.set('v.filteredData', response.getReturnValue().body);
                                       this.preparePagination(component, response.getReturnValue().body);
                                       component.set("v.showSpinner", false);
                                       component.set("v.readyToDownload", false);
                                       component.set("v.readyToDownloadSecond", true);
                                       component.set("v.errorMsgBool", false);
                                       component.set("v.titleOfErr", "");
                                       component.set("v.severityErr", "");
                                       component.set("v.errMsgSecond", "");
                                   } 
                                    else if(selectedValue == 'option39'){
                                     var Returnvalue = response.getReturnValue();
                                           console.log('Returnvalue:', Returnvalue);
                                      
                                       component.set("v.showSpinner", false);
                                       component.set("v.readyToDownload", false);
                                       component.set("v.readyToDownloadSecond", true);
                                       component.set("v.errorMsgBool", false);
                                       component.set("v.titleOfErr", "");
                                       component.set("v.severityErr", "");
                                       component.set("v.errMsgSecond", "");
                                   }  
                                   
                                       else if (selectedValue == 'option37') {
                                           var Returnvalue = response.getReturnValue();
                                           console.log('Returnvalue:', Returnvalue);
                                           
                                           let tableData = [];
                                           let userNames = [];
                                           
                                           // Check if Returnvalue has the fields and values we need
                                           if (Returnvalue && Returnvalue.fields && Returnvalue.fieldValues1 && Returnvalue.fieldValues2) {
                                               let fields = Returnvalue.fields;
                                               
                                               // Extract dynamic user names from the response
                                               let users = Returnvalue.userName.split(' vs '); // Assuming userName format is 'User1 vs User2'
                                               userNames = users; // Set the dynamic user names
                                               
                                               fields.forEach(function (fieldName, fieldIndex) {
                                                   let fieldData = {
                                                       fieldName: fieldName,
                                                       values: [
                                                           Returnvalue.fieldValues1[fieldIndex],
                                                           Returnvalue.fieldValues2[fieldIndex]
                                                       ]
                                                   };
                                                   tableData.push(fieldData);
                                               });
                                           }
                                           
                                           // Set the prepared data to component attributes
                                           component.set("v.tableUserData", tableData);
                                           component.set("v.userNames", userNames);
                                           
                                           // Log the result for debugging
                                           console.log('ReturnvalueNewVal: ' + JSON.stringify(tableData));
                                           console.log('User Names: ' + JSON.stringify(userNames));
                                           
                                           // Update component attributes
                                           component.set("v.showSpinner", false);
                                           component.set("v.readyToDownload", false);
                                           component.set("v.readyToDownloadSecond", true);
                                           component.set("v.errorMsgBool", false);
                                           component.set("v.titleOfErr", "");
                                           component.set("v.severityErr", "");
                                           component.set("v.errMsgSecond", "");
                                       }
                                  
                                       else if(selectedValue == 'option1' || selectedValue == 'option2' || selectedValue == 'option11' || selectedValue == 'option20' || selectedValue == 'option22'){
                                           var status = response.getReturnValue();
                                           component.set("v.errorMsgBool", true);
                                           component.set("v.titleOfErr", "Warning");
                                           component.set("v.severityErr", "Warning");
                                           component.set("v.errMsgSecond", status);
                                           component.set("v.showSpinner", false);
                                           if(status == 'Completed'){
                                               component.set("v.showSpinner", true);
                                               this.viewDataForManaged(component, event, helper);
                                           }
                                       }
                                         else if(selectedValue == 'option32'){
                                               var Returnvalue = response.getReturnValue();
                                               var newList = [];
                                               for(var i = 0; i < Returnvalue.length; i++){
                                                   if(Returnvalue[i].objItem.PortalType != 'None'){
                                                       
                                                       newList.push(Returnvalue[i]);
                                                       //console.log('newList'+JSON.stringify(newList));
                                                   }
                                               }
                                               
                                               component.set("v.jsonData", newList);
                                               console.log('ReturnvalueNewVAl'+JSON.stringify(newList));
                                               component.set("v.showSpinner", false);
                                               component.set("v.readyToDownload", false);
                                               component.set("v.readyToDownloadSecond", true);
                                               component.set("v.errorMsgBool", false);
                                               component.set("v.titleOfErr", "");
                                               component.set("v.severityErr", "");
                                               component.set("v.errMsgSecond", "");     
                                           }   
                                             else if(selectedValue == 'option15'){
                                                 console.log('IN OPTION15');
                                                 console.log('ResponseFromServer', response.getReturnValue());  // Log without stringifying to see structure
                                                 
                                                 var returnValue = response.getReturnValue();
                                                 
                                                 // Check if it's an empty array or object
                                                 if (Array.isArray(returnValue) && returnValue.length === 0 || 
                                                     (typeof returnValue === 'object' && Object.keys(returnValue).length === 0)) {
                                                     
                                                     // If response is empty array or object
                                                     component.set("v.showSpinner", false);
                                                     component.set("v.readyToDownload", false);
                                                     component.set("v.readyToDownloadSecond", false);
                                                     component.set("v.errorMsgBool", true);
                                                     component.set("v.titleOfErr", "    Wait !!");
                                                     component.set("v.severityErr", "info");
                                                 component.set("v.errMsgSecond", "Batch is initializing. Please press 'View Data' again to check the status.");

                                                 } else {
                                                     // If response contains data
                                                     component.set("v.jsonData", returnValue);
                                                     component.set("v.showSpinner", false);
                                                     component.set("v.readyToDownload", false);
                                                     component.set("v.readyToDownloadSecond", true);
                                                     component.set("v.errorMsgBool", false);
                                                     component.set("v.titleOfErr", "");
                                                     component.set("v.severityErr", "");
                                                     component.set("v.errMsgSecond", "");
                                                 }
                                             }
               
                                           /*  else if(selectedValue == 'option28' ){ 
                                                    
                                                     var ReturnDatavalue = response.getReturnValue(); 
                                                     const wrapperToChangeDataFromFuncToSuitableForTable = () => { 
                                                         const newStructureForData = [JSON.parse(JSON.stringify(ReturnDatavalue[0]))]; 
                                                         const objToKeepTrackOfPositionOfElementInArray = {};
                                                     if(ReturnDatavalue.length > 0) {
                                                         ReturnDatavalue.forEach((data, index) => {
                                                             if (index === 0) {
                                                             newStructureForData[0].ProfileNamm = [data.ProfileNamm]; 
                                                         }else{
                                                                                 newStructureForData[0].ProfileNamm.push(data.ProfileNamm);
                                                     }                                              
                                                     data.subvar.forEach((innerData, index1) => { 
                                                         if (index === 0) {
                                                         objToKeepTrackOfPositionOfElementInArray[`${innerData.tabName}`] = index1;
                                                                         newStructureForData[0].subvar[index1].tabVisibility = [innerData.tabVisibility];
                                                                         } else {
                                                                         const pos = objToKeepTrackOfPositionOfElementInArray[`${innerData.tabName}`];
                                                                         if (newStructureForData[0].subvar[index1]) {
                                                         newStructureForData[0].subvar[index1].tabVisibility.push(innerData.tabVisibility);
                                                     }
                                                 }
                                                                                   })
                                                                               })
                                                        }
                                                        return (newStructureForData);
                                                    }  
                                                     console.log('IN  Option28 CAll=='+ JSON.stringify(wrapperToChangeDataFromFuncToSuitableForTable()));
                                                    component.set("v.jsonData", wrapperToChangeDataFromFuncToSuitableForTable()); 
                                                        component.set("v.showoption28Modal", false);
                                                            component.set("v.readyToDownload", false);
                                                            component.set("v.readyToDownloadSecond", true);
                                                            component.set("v.errorMsgBool", false);
                                                            component.set("v.titleOfErr", "");
                                                            component.set("v.severityErr", "");
                                                            component.set("v.errMsgSecond", "");
                                                            }   */
                                   else if (selectedValue == 'option28') {
    console.log("Debug: Selected Value is 'option28'");

    // Retrieve the response data
    var ReturnDatavalue = response.getReturnValue();
    console.log("Debug: Response Data Retrieved:", JSON.stringify(ReturnDatavalue));

    // Validate that ReturnDatavalue is defined and is an array
    if (!ReturnDatavalue || !Array.isArray(ReturnDatavalue) || ReturnDatavalue.length === 0) {
        console.error("Debug: Invalid or empty response data");
        return;
    }

    // Function to transform data into the desired structure
    const wrapperToChangeDataFromFuncToSuitableForTable = () => {
        try {
            console.log("Debug: Transforming data into a new structure...");

            // Initialize the new structure for data
            const newStructureForData = [JSON.parse(JSON.stringify(ReturnDatavalue[0]))];
            console.log("Debug: Initial New Structure For Data:", JSON.stringify(newStructureForData));

            // Object to keep track of positions in the array
            const objToKeepTrackOfPositionOfElementInArray = {};
            console.log("Debug: Initialized tracking object:", JSON.stringify(objToKeepTrackOfPositionOfElementInArray));

            // Iterate through the data
            ReturnDatavalue.forEach((data, index) => {
                console.log(`Debug: Processing data at index ${index}:`, JSON.stringify(data));

                if (index === 0) {
                    // Initialize ProfileNamm as an array
                    newStructureForData[0].ProfileNamm = data.ProfileNamm ? [data.ProfileNamm] : [];
                    console.log(`Debug: Initialized ProfileNamm for index 0:`, JSON.stringify(newStructureForData[0].ProfileNamm));
                } else {
                    // Push ProfileNamm if it exists
                    if (data.ProfileNamm) {
                        newStructureForData[0].ProfileNamm.push(data.ProfileNamm);
                        console.log(`Debug: Appended ProfileNamm for index ${index}:`, JSON.stringify(newStructureForData[0].ProfileNamm));
                    }
                }

                // Process subvar data
                if (data.subvar && Array.isArray(data.subvar)) {
                    console.log(`Debug: Processing subvar data for index ${index}:`, JSON.stringify(data.subvar));

                    data.subvar.forEach((innerData, index1) => {
                        console.log(`Debug: Processing innerData at index ${index1}:`, JSON.stringify(innerData));

                        if (index === 0) {
                            // Initialize tracking object and tabVisibility array
                            objToKeepTrackOfPositionOfElementInArray[`${innerData.tabName}`] = index1;
                            console.log(`Debug: Updated tracking object for tabName '${innerData.tabName}':`, JSON.stringify(objToKeepTrackOfPositionOfElementInArray));

                            if (newStructureForData[0].subvar && newStructureForData[0].subvar[index1]) {
                                newStructureForData[0].subvar[index1].tabVisibility = innerData.tabVisibility
                                    ? [innerData.tabVisibility]
                                    : [];
                                console.log(`Debug: Initialized tabVisibility for index1 ${index1}:`, JSON.stringify(newStructureForData[0].subvar[index1].tabVisibility));
                            }
                        } else {
                            // Append to existing tabVisibility array
                            const pos = objToKeepTrackOfPositionOfElementInArray[`${innerData.tabName}`];
                            console.log(`Debug: Retrieved position for tabName '${innerData.tabName}':`, pos);

                            if (
                                newStructureForData[0].subvar &&
                                newStructureForData[0].subvar[pos] &&
                                newStructureForData[0].subvar[pos].tabVisibility
                            ) {
                                newStructureForData[0].subvar[pos].tabVisibility.push(innerData.tabVisibility);
                                console.log(`Debug: Appended tabVisibility for position ${pos}:`, JSON.stringify(newStructureForData[0].subvar[pos].tabVisibility));
                            }
                        }
                    });
                } else {
                    console.warn(`Debug: subvar is undefined or not an array for index ${index}`);
                }
            });

            console.log("Debug: Final Transformed Data:", JSON.stringify(newStructureForData));
            return newStructureForData;
        } catch (error) {
            console.error("Debug: Error transforming data:", error);
            return [];
        }
    };

    // Log the transformed data
    const transformedData = wrapperToChangeDataFromFuncToSuitableForTable();
    console.log("Debug: Transformed Data After Function Call:", JSON.stringify(transformedData));

    // Update component attributes
    component.set("v.jsonData", transformedData);
    console.log("Debug: Updated v.jsonData attribute:", JSON.stringify(transformedData));

    component.set("v.showoption28Modal", false);
    console.log("Debug: Updated v.showoption28Modal attribute to false");

    component.set("v.readyToDownload", false);
    console.log("Debug: Updated v.readyToDownload attribute to false");

    component.set("v.readyToDownloadSecond", true);
    console.log("Debug: Updated v.readyToDownloadSecond attribute to true");

    component.set("v.errorMsgBool", false);
    console.log("Debug: Updated v.errorMsgBool attribute to false");

    component.set("v.titleOfErr", "");
    console.log("Debug: Updated v.titleOfErr attribute to ''");

    component.set("v.severityErr", "");
    console.log("Debug: Updated v.severityErr attribute to ''");

    component.set("v.errMsgSecond", "");
    console.log("Debug: Updated v.errMsgSecond attribute to ''");
}
                                   
                                                    else if(selectedValue == 'option36') {
                                                            var Returnvalue = response.getReturnValue();
                                                                var finalist2 = [];
                                                            
                                                            // Check if profileData exists in the response
                                                            if (!Returnvalue.profileData) return {};
                                                            
                                                            // Iterate over each profile in the profileData
                                                            Object.entries(Returnvalue.profileData).forEach(([profileName, recordTypes]) => {
                                                                var profileObject = { "ProfileName": profileName, "RecordTypes": [] };
                                                                                                            
                                                                                                            // Iterate over each record type for the current profile
                                                                                                            Object.entries(recordTypes).forEach(([recordType, layoutNames]) => {
                                                                var recordTypeObject = { "RecordTypeName": recordType, "Layouts": [] };
                                                                                                                                                
                                                                                                                                                // Iterate over each layout name for the current record type
                                                                                                                                                layoutNames.forEach((layoutName) => {
                                                                var layoutObject = { "LayoutName": layoutName };
                                                            recordTypeObject.Layouts.push(layoutObject);
                                                        });
                                                        
                                                        profileObject.RecordTypes.push(recordTypeObject);
                                                        });
                                                        
                                                        finalist2.push(profileObject);
                                                        });
                                                        
                                                        finalist2.sort((a, b) => a.ProfileName.localeCompare(b.ProfileName));
                                                        
                                                        component.set("v.jsonData", finalist2);
                                                        
                                                        // Log the jsonData for debugging
                                                        //console.log('ResponseFromServer==' + JSON.stringify(component.get("v.jsonData")));
                                                        
                                                        // Additional component attribute settings
                                                        component.set("v.showSpinner", false);
                                                        component.set("v.readyToDownload", false);
                                                        component.set("v.readyToDownloadSecond", true);
                                                        component.set("v.errorMsgBool", false);
                                                        component.set("v.titleOfErr", "");
                                                        component.set("v.severityErr", "");
                                                        component.set("v.errMsgSecond", "");
 }
 											   else{
                                                                    console.log('IN  CAll')
                                                                    console.log('ResponseFromServer' + JSON.stringify(response.getReturnValue()));
                                                                    component.set("v.jsonData", response.getReturnValue());
                                                                    component.set("v.showSpinner", false);
                                                                    component.set("v.readyToDownload", false);
                                                                    component.set("v.readyToDownloadSecond", true);
                                                                    component.set("v.errorMsgBool", false);
                                                                    component.set("v.titleOfErr", "");
                                                                    component.set("v.severityErr", "");
                                                                    component.set("v.errMsgSecond", "");
                                                                    
                                                                    
                                                                }
 												}
												else{
    component.set("v.showSpinner", false);
    component.set("v.readyToDownload", false);
    component.set("v.readyToDownloadSecond", false);
    var errorMessage = '';
    if(state === "INCOMPLETE")
    {
        errorMessage = 'Some Error is Occured.';
    }
    else if(state === "ERROR")
    {
        errorMessage = action.getError()[0].message;
    } 
    component.set("v.errorMsgBool", true);
    component.set("v.titleOfErr", "Error");
    component.set("v.severityErr", "error");
    if((selectedValue == 'option8' || selectedValue == 'option7') && errorMessage.includes('If you are attempting to use a custom object, be sure to append the ')){
        component.set("v.errMsgSecond", "Territory management is not enabled for your org.");
    }
    else{
        component.set("v.errMsgSecond", errorMessage);
    }
}
                                   });
                                    $A.enqueueAction(action);
                               },
    getPermissionList: function(component, pageNumber, pageSize) {
        
        var action = component.get("c.fetchPermissionSet1");
        action.setParams({
            "pageNumber": pageNumber,
            "pageSize": pageSize
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                if (resultData) {
                    component.set("v.jsonData", resultData.PsetList);
                    component.set("v.PageNumber", resultData.pageNumber);
                    component.set("v.TotalRecords", resultData.totalRecords);
                    component.set("v.RecordStart", resultData.recordStart);
                    component.set("v.RecordEnd", resultData.recordEnd);
                    component.set("v.TotalPages1", Math.ceil(resultData.totalRecords / pageSize));
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    for (var i = 0; i < errors.length; i++) {
                        console.error("Error message: " + errors[i].message);
                    }
                } else {
                    console.error("Unknown error occurred");
                }
            }
        });
        $A.enqueueAction(action);
    }
,
       fetchoption39: function (component, event, helper) {
        
            const action = component.get("c.fetchTableDataOption39");
            action.setCallback(this, function (response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                     component.set("v.permissionSets", response.getReturnValue());
                    component.set("v.showSpinner", false);
                    component.set("v.readyToDownload", false);
                    component.set("v.readyToDownloadSecond", true);
                    component.set("v.errorMsgBool", false);
                    component.set("v.titleOfErr", "");
                    component.set("v.severityErr", "");
                    component.set("v.errMsgSecond", "");
                    console.log('>>>>>###' + JSON.stringify(response.getReturnValue()));
                   
                } else if (state === "ERROR") {
                     component.set("v.showSpinner", false);
                                       component.set("v.readyToDownload", false);
                                       component.set("v.readyToDownloadSecond", false);
                                       var errorMessage = '';
                                       if(state === "INCOMPLETE")
                                       {
                                           errorMessage = 'Some Error is Occured.';
                                       }
                                       else if(state === "ERROR")
                                       {
                                           errorMessage = action.getError()[0].message;
                                       } 
                                       component.set("v.errorMsgBool", true);
                                       component.set("v.titleOfErr", "Error");
                                       component.set("v.severityErr", "error");
                                       component.set("v.errMsgSecond", errorMessage);
                }
                component.set("v.showSpinner", false);
            });
            $A.enqueueAction(action);
        
    },
    getOWDData: function(component, event, helper){
        var action = component.get("c.fetchOWDRelatedData"); 
        action.setCallback(this, function(response)
                           {
                               var state = response.getState();
                               if(state === "SUCCESS"){
                                   component.set("v.jsonData", response.getReturnValue());
                                   console.log('>>>>>###' + JSON.stringify(response.getReturnValue()));
                                   component.set("v.showSpinner", false);
                                   component.set("v.readyToDownload", false);
                                   component.set("v.readyToDownloadSecond", true);
                                   component.set("v.errorMsgBool", false);
                                   component.set("v.titleOfErr", "");
                                   component.set("v.severityErr", "");
                                   component.set("v.errMsgSecond", "");
                               }
                               else{
                                   component.set("v.showSpinner", false);
                                   component.set("v.readyToDownload", false);
                                   component.set("v.readyToDownloadSecond", false);
                                   var errorMessage = '';
                                   if(state === "INCOMPLETE")
                                   {
                                       errorMessage = 'Some Error is Occured.';
                                   }
                                   else if(state === "ERROR")
                                   {
                                       errorMessage = action.getError()[0].message;
                                   } 
                                   component.set("v.errorMsgBool", true);
                                   component.set("v.titleOfErr", "Error");
                                   component.set("v.severityErr", "error");
                                   component.set("v.errMsgSecond", errorMessage);
                               }
                           } 
                          );
        $A.enqueueAction(action);
    },
        getListOfIDs: function(component, event, helper){
            var action = component.get("c.getBatchApexJOBIds"); 
            action.setCallback(this, function(response)
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS"){
                                       console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                                       component.set("v.listOfBatchIDs", response.getReturnValue());
                                       component.set("v.showSpinner", false);
                                       component.set("v.readyToDownload", false);
                                       component.set("v.readyToDownloadSecond", true);
                                       component.set("v.errorMsgBool", false);
                                       component.set("v.titleOfErr", "");
                                       component.set("v.severityErr", "");
                                       component.set("v.errMsgSecond", "");
                                   }
                                   else{
                                       component.set("v.showSpinner", false);
                                       component.set("v.readyToDownload", false);
                                       component.set("v.readyToDownloadSecond", false);
                                       var errorMessage = '';
                                       if(state === "INCOMPLETE")
                                       {
                                           errorMessage = 'Some Error is Occured.';
                                       }
                                       else if(state === "ERROR")
                                       {
                                           errorMessage = action.getError()[0].message;
                                       } 
                                       component.set("v.errorMsgBool", true);
                                       component.set("v.titleOfErr", "Error");
                                       component.set("v.severityErr", "error");
                                       component.set("v.errMsgSecond", errorMessage);
                                   }
                               } 
                              );
            $A.enqueueAction(action);
        },
            viewDataForManaged: function(component, event, helper){
                var selectedValue = component.get("v.value");
                var listOfIDs = component.get("v.listOfBatchIDs");
                if(selectedValue == 'option11'){
                    var action = component.get("c.fetchTableDataOption11");
                    
                    action.setParams({
                        jobId: listOfIDs[2]
                    })  
                }
                else if(selectedValue == 'option1'){
                    var action = component.get("c.fetchTableDataOption1");
                    action.setParams({
                        jobId: listOfIDs[0]
                    })  
                }
                    else if(selectedValue == 'option2'){
                        var action = component.get("c.fetchTableDataOption2");
                        action.setParams({
                            jobId: listOfIDs[1]
                        })    
                    }
                        else if(selectedValue == 'option20'){
                            var action = component.get("c.fetchTableDataOption20");
                        }
                            else if(selectedValue == 'option22'){
                                var action = component.get("c.fetchTableDataOption22");
                            }
                action.setCallback(this, function(response)
                                   {
                                       var state = response.getState();
                                       if(state === "SUCCESS"){
                                           component.set("v.jsonData", response.getReturnValue());
                                           console.log('>>>>>@@@' + JSON.stringify(response.getReturnValue()));
                                           component.set("v.showSpinner", false);
                                           component.set("v.readyToDownload", false);
                                           component.set("v.readyToDownloadSecond", true);
                                           component.set("v.errorMsgBool", false);
                                           component.set("v.titleOfErr", "");
                                           component.set("v.severityErr", "");
                                           component.set("v.errMsgSecond", "");
                                       }
                                       else{
                                           component.set("v.showSpinner", false);
                                           component.set("v.readyToDownload", false);
                                           component.set("v.readyToDownloadSecond", false);
                                           var errorMessage = '';
                                           if(state === "INCOMPLETE")
                                           {
                                               errorMessage = 'Some Error is Occured.';
                                           }
                                           else if(state === "ERROR")
                                           {
                                               errorMessage = action.getError()[0].message;
                                           } 
                                           component.set("v.errorMsgBool", true);
                                           component.set("v.titleOfErr", "Error");
                                           component.set("v.severityErr", "error");
                                           component.set("v.errMsgSecond", errorMessage);
                                       }
                                   } 
                                  );
                $A.enqueueAction(action);
            },
                getStatusOfAsyncProcess: function(component, event, helper){
                    var selectedValue = component.get("v.value");
                    var listOfIDs = component.get("v.listOfBatchIDs");
                    if(selectedValue == 'option11'){
                        var action = component.get("c.checkBatchApexProgress");
                        action.setParams({
                            jobId: listOfIDs[2]
                        })  
                    }
                    else if(selectedValue == 'option1'){
                        var action = component.get("c.checkBatchApexProgress");
                        action.setParams({
                            jobId: listOfIDs[0]
                        })  
                    }
                        else if(selectedValue == 'option2'){
                            var action = component.get("c.checkBatchApexProgress");
                            action.setParams({
                                jobId: listOfIDs[1]
                            })    
                        }
                            else if(selectedValue == 'option20'){
                                var action = component.get("c.checkBatchApexProgress");
                                action.setParams({
                                    jobId: listOfIDs[3]
                                })    
                            }
                                else if(selectedValue == 'option22'){
                                    var action = component.get("c.checkBatchApexProgress");
                                    action.setParams({
                                        jobId: listOfIDs[4]
                                    })    
                                }
                    action.setCallback(this, function(response)
                                       {
                                           var state = response.getState();
                                           if(state === "SUCCESS"){
                                               console.log('>>>>>!!' + JSON.stringify(response.getReturnValue()));
                                               var status = response.getReturnValue();
                                               component.set("v.errorMsgBool", true);
                                               component.set("v.titleOfErr", "Waring");
                                               component.set("v.severityErr", "warning");
                                               component.set("v.errMsgSecond", status);
                                               component.set("v.showSpinner", false);
                                               if(status == 'Completed'){
                                                   var url;
                                                   if(selectedValue == 'option2'){
                                                       url += "/apex/SA_Audit__FolderSharesExcel?jobId=" + listOfIDs[1];
                                                   }
                                                   else if(selectedValue == 'option1'){
                                                       url += "/apex/SA_Audit__FolderSharesExcel?jobId=" + listOfIDs[0];
                                                   }
                                                       else if(selectedValue == 'option11'){
                                                           url += "/apex/SA_Audit__InstalledPackagesReportExcel?jobId=" + listOfIDs[2];   
                                                       }
                                                           else if(selectedValue == 'option20'){
                                                               url += "/apex/SA_Audit__ValidationRulesExcel";   
                                                           }
                                                               else if(selectedValue == 'option22'){
                                                                   url += "/apex/SA_Audit__ListViewExcel";   
                                                               }
                                                   window.open(url);
                                                   component.set("v.showSpinner", false);
                                                   component.set("v.readyToDownload", false);
                                                   component.set("v.errorMsgBool", false);
                                                   component.set("v.titleOfErr", "");
                                                   component.set("v.severityErr", "");
                                                   component.set("v.errMsgSecond", "");
                                               }
                                           }
                                           else{
                                               component.set("v.showSpinner", false);
                                               component.set("v.readyToDownload", false);
                                               component.set("v.readyToDownloadSecond", false);
                                               var errorMessage = '';
                                               if(state === "INCOMPLETE")
                                               {
                                                   errorMessage = 'Some Error is Occured.';
                                               }
                                               else if(state === "ERROR")
                                               {
                                                   errorMessage = action.getError()[0].message;
                                               } 
                                               component.set("v.errorMsgBool", true);
                                               component.set("v.titleOfErr", "Error");
                                               component.set("v.severityErr", "error");
                                               component.set("v.errMsgSecond", errorMessage);
                                           }
                                       } 
                                      );
                    $A.enqueueAction(action);
                },
                    getManagedPackageLicenseData: function(component, event, helper){
                        
                        var listOfIDs = component.get("v.listOfBatchIDs");
                        var action = component.get("c.fetchManagedPackageLicenseData"); 
                        action.setParams({
                            listOfIDs: listOfIDs
                        })   
                        action.setCallback(this, function(response)
                                           {
                                               var state = response.getState();
                                               if(state === "SUCCESS"){
                                                   console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                                                   component.set("v.showSpinner", false);
                                                   component.set("v.readyToDownload", false);
                                                   component.set("v.readyToDownloadSecond", false);
                                                   component.set("v.errorMsgBool", false);
                                                   component.set("v.titleOfErr", "");
                                                   component.set("v.severityErr", "");
                                                   component.set("v.errMsgSecond", "");
                                               }
                                               else{
                                                   component.set("v.showSpinner", false);
                                                   component.set("v.readyToDownload", false);
                                                   component.set("v.readyToDownloadSecond", false);
                                                   var errorMessage = 'No Data Available..';
                                                   if(state === "INCOMPLETE")
                                                   {
                                                       errorMessage = 'Some Error is Occured.';
                                                   }
                                                   else if(state === "ERROR")
                                                   {
                                                       errorMessage = action.getError()[0].message;
                                                   } 
                                                   component.set("v.errorMsgBool", true);
                                                   component.set("v.titleOfErr", "Error");
                                                   component.set("v.severityErr", "error");
                                                   component.set("v.errMsgSecond", errorMessage);
                                               }
                                           } 
                                          );
                        $A.enqueueAction(action);
                    },
                        batchApexExecutionToSendAnEmail: function(component, event, helper){
                            var selectedOption = component.get("v.selectedValues");
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
                                                       component.set("v.showSpinner", false);
                                                       component.set("v.readyToDownload", false);
                                                       component.set("v.readyToDownloadSecond", false);
                                                       component.set("v.errorMsgBool", true);
                                                       component.set("v.titleOfErr", "Warning");
                                                       component.set("v.severityErr", "warning");
                                                       component.set("v.errMsgSecond", "Please don't refresh the Page, Your Email execution is in Progress. Please check your Email...");
                                                   }
                                                   else{
                                                       component.set("v.showSpinner", false);
                                                       component.set("v.readyToDownload", false);
                                                       component.set("v.readyToDownloadSecond", false);
                                                       var errorMessage = '';
                                                       if(state === "INCOMPLETE")
                                                       {
                                                           errorMessage = 'Some Error is Occured.';
                                                       }
                                                       else if(state === "ERROR")
                                                       {
                                                           errorMessage = action.getError()[0].message;
                                                       } 
                                                       component.set("v.errorMsgBool", true);
                                                       component.set("v.titleOfErr", "Error");
                                                       component.set("v.severityErr", "error");
                                                       component.set("v.errMsgSecond", errorMessage);
                                                   }
                                               } 
                                              );
                            $A.enqueueAction(action);
                        },
                            convertArrayOfObjectsToCSV : function(component,objectRecords){
                                // declare variables
                                var counter, keys, columnDivider, lineDivider;
                                // check if "objectRecords" parameter is null, then return from function
                                if (objectRecords == null || !objectRecords.length) {
                                    return null;
                                }
                                const items = objectRecords;
                                const replacer = (key, value) => value === null ? '' : value // specify how you want to handle null values here
                                var header = Object.keys(items[0]);
                                var selectedValue = component.get("v.value");
                                if(selectedValue == 'option4')
                                {
                                    header = ["Name", "UserRoleId", "LastLoginDate", "Id", "UserRole"];
                                }
                                var csv = [
                                    header.join(','), // header row first
                                    ...items.map(row => header.map(fieldName => JSON.stringify(row[fieldName], replacer)).join(','))
                                    ];
                                if(selectedValue == 'option4')
                                {
                                    csv[0] = ["USER NAME","ROLE NAME","ROLE ID","LAST LOGIN DATE"];
                                }
                                
                                // return the CSV formate String
                                console.log(csv);
                                return csv.join('\r\n');        
                            },
                                listViewExport: function(component, event, helper){
                                    var action = component.get("c.listViewBatchExecution"); 
                                    action.setCallback(this, function(response)
                                                       {
                                                           var state = response.getState();
                                                           if(state === "SUCCESS"){
                                                               console.log('>>>>>' + JSON.stringify(response.getReturnValue()));
                                                               component.set("v.showSpinner", false);
                                                               component.set("v.readyToDownload", false);
                                                               component.set("v.readyToDownloadSecond", false);
                                                               component.set("v.errorMsgBool", true);
                                                               component.set("v.titleOfErr", "Warning");
                                                               component.set("v.severityErr", "warning");
                                                               component.set("v.errMsgSecond", "Please don't refresh the Page, Your Batch execution for List View Data is in Progress. You will receive an Email Shortly...");
                                                           }
                                                           else{
                                                               component.set("v.showSpinner", false);
                                                               component.set("v.readyToDownload", false);
                                                               component.set("v.readyToDownloadSecond", false);
                                                               var errorMessage = '';
                                                               if(state === "INCOMPLETE")
                                                               {
                                                                   errorMessage = 'Some Error is Occured.';
                                                               }
                                                               else if(state === "ERROR")
                                                               {
                                                                   errorMessage = action.getError()[0].message;
                                                               } 
                                                               component.set("v.errorMsgBool", true);
                                                               component.set("v.titleOfErr", "Error");
                                                               component.set("v.severityErr", "error");
                                                               component.set("v.errMsgSecond", errorMessage);
                                                           }
                                                       } 
                                                      );
                                    $A.enqueueAction(action);
                                },
                                    preparePagination: function (component, imagesRecords) {
                                        let countTotalPage = Math.ceil(imagesRecords.length/component.get("v.pageSize"));
                                        let totalPage = countTotalPage > 0 ? countTotalPage : 1;
                                        component.set("v.totalPages", totalPage);
                                        component.set("v.currentPageNumber", 1);
                                        this.setPageDataAsPerPagination(component);
                                    },
                                        
                                        setPageDataAsPerPagination: function(component) {
                                            let data = [];
                                            let pageNumber = component.get("v.currentPageNumber");
                                            let pageSize = component.get("v.pageSize");
                                            let filteredData = component.get('v.filteredData');
                                            let x = (pageNumber - 1) * pageSize;
                                            for (; x < (pageNumber) * pageSize; x++){
                                                if (filteredData[x]) {
                                                    data.push(filteredData[x]);
                                                }
                                            }
                                            component.set("v.tableData", data);
                                        },
                                            
                                            setPageDataAsPerPagination: function(component) {
                                                let data = [];
                                                let pageNumber = component.get("v.currentPageNumber");
                                                let pageSize = component.get("v.pageSize");
                                                let filteredData = component.get('v.filteredData');
                                                let x = (pageNumber - 1) * pageSize;
                                                for (; x < (pageNumber) * pageSize; x++){
                                                    if (filteredData[x]) {
                                                        data.push(filteredData[x]);
                                                    }
                                                }
                                                component.set("v.tableData", data);
                                            },
})