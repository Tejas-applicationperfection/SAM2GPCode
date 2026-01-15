/* eslint-disable no-console, no-unused-vars, eqeqeq, no-mixed-spaces-and-tabs */
({
    searchHelper : function(component,event,getInputkeyWord) {
	  // call the apex class method 
     var action = component.get("c.fetchLookUpValues");
      // set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'ObjectName' : component.get("v.objectAPIName")
          });
      // set a callBack    
        action.setCallback(this, function(response) {
          $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log(state + 'state');
                var storeResponse = response.getReturnValue();
              // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", '');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
            }
 
        });
      // enqueue the Action  
        $A.enqueueAction(action);
    
	},
    
    getObjectNameAndLabel: function(component, objectID) {
        var action = component.get("c.getObjectNameAndLabel");
        action.setParams({
            'objectId': objectID,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse[0] === 'true') {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Something has gone wrong!",
                        "message": storeResponse[1]
                    });
                } else {
                    var myDiv = component.find("myDiv");                    
                   	$A.util.addClass(myDiv, 'divShow');
                    component.set("v.objectName", storeResponse[2]);
                    component.set("v.objectLabel", storeResponse[1]);
                    console.log('1111' + storeResponse[2]);
                    var owdCmp = component.find("OWDcmp");
                    owdCmp.doInit(storeResponse[1], storeResponse[2], function(result) {
                        console.log("result: " + result);
                    });
                    var owd = component.find("OWD");
                    $A.util.addClass(owd, 'divShow');
                    
                    var userID = component.get("v.selectedLookUpRecord.Id");
                    var profileCmp = component.find("profileCmp");
                    profileCmp.doInit(userID, storeResponse[1], function(result) { });
                    var profile = component.find("profile");
                    $A.util.addClass(profile, 'divShow');
                    
                    var userRoleCmp = component.find("userRoleCmp");
                    userRoleCmp.doInit(userID, objectID, function(result) { });
                    var userRole = component.find("userRole");
                    $A.util.addClass(userRole, 'divShow');
                    
                    var groupSharingCmp = component.find("groupSharingCmp");
                    groupSharingCmp.doInit(userID, objectID, function(result) {
                        console.log('group sharing result:' + result);
                        var groupSharing = component.find("groupSharing");
                        if(result && (result.groupList || result.shrGroupMap)) {
                            // Show only if there's actual group sharing data
                            var hasGroupData = (result.groupList && result.groupList.length > 0) || 
                                             (result.shrGroupMap && Object.keys(result.shrGroupMap).length > 0);
                            if(hasGroupData) {
                                $A.util.addClass(groupSharing, 'divShow');
                            } else {
                                $A.util.addClass(groupSharing, 'divHidden');
                            }
                        } else {
                            $A.util.addClass(groupSharing, 'divHidden');
                        }
                    });
                    
                    var permSetCmp = component.find("permSetCmp");
                    permSetCmp.doInit(userID, storeResponse[1], function(result) {
                        console.log('perm set result0:' + result);
                        var permSet = component.find("permSet");
                        if(result) {
                            console.log('perm set result:' + result);
                            $A.util.addClass(permSet, 'divShowPermSet');
                        } else {
                            $A.util.addClass(permSet, 'divHiddenPermSet');
                        }
                    });
                    
                    component.set('v.loaded', true);
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    getProfile: function(component, userID) {
        var action = component.get("c.Profile");
        action.setParams({
            'userID': userID,
        });
    },
    
    /* eslint-disable no-console */
    loadComparisonData: function(component, userID1, objectID1, userID2, objectID2) {
        component.set('v.loaded', false);
        
        // Load data for Scenario 1
        this.loadScenarioData(component, userID1, objectID1, '1');
        
        // Load data for Scenario 2
        this.loadScenarioData(component, userID2, objectID2, '2');
        
        component.set('v.loaded', true);
    },
    
    loadScenarioData: function(component, userID, objectID, suffix) {
        var action = component.get("c.getObjectNameAndLabel");
        action.setParams({
            'objectId': objectID,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                if (storeResponse[0] === 'true') {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Error in Scenario " + suffix,
                        "message": storeResponse[1]
                    });
                } else {
                    // Store object info
                    if (suffix === '1') {
                        component.set("v.objectName", storeResponse[2]);
                        component.set("v.objectLabel", storeResponse[1]);
                    }
                    
                    console.log('Loading scenario ' + suffix + ' - Object: ' + storeResponse[2]);
                    
                    // Load OWD
                    var owdCmp = component.find("OWDcmp" + suffix);
                    owdCmp.doInit(storeResponse[1], storeResponse[2], function(result) {
                        console.log("OWD result for scenario " + suffix + ": " + result);
                    });
                    var owd = component.find("OWD" + suffix);
                    $A.util.addClass(owd, 'divShow');
                    
                    // Load Profile
                    var profileCmp = component.find("profileCmp" + suffix);
                    profileCmp.doInit(userID, storeResponse[1], function(result) {
                        console.log("Profile result for scenario " + suffix + ": " + result);
                    });
                    var profile = component.find("profile" + suffix);
                    $A.util.addClass(profile, 'divShow');
                    
                    // Load User Role
                    var userRoleCmp = component.find("userRoleCmp" + suffix);
                    userRoleCmp.doInit(userID, objectID, function(result) {
                        console.log("Role result for scenario " + suffix + ": " + result);
                    });
                    var userRole = component.find("userRole" + suffix);
                    $A.util.addClass(userRole, 'divShow');
                    
                    // Load Group Sharing
                    var groupSharingCmp = component.find("groupSharingCmp" + suffix);
                    groupSharingCmp.doInit(userID, objectID, function(result) {
                        console.log("Group sharing result for scenario " + suffix + ": " + result);
                        var groupSharing = component.find("groupSharing" + suffix);
                        if(result && (result.groupList || result.shrGroupMap)) {
                            var hasGroupData = (result.groupList && result.groupList.length > 0) || 
                                             (result.shrGroupMap && Object.keys(result.shrGroupMap).length > 0);
                            if(hasGroupData) {
                                $A.util.addClass(groupSharing, 'divShow');
                            } else {
                                $A.util.addClass(groupSharing, 'divHidden');
                            }
                        } else {
                            $A.util.addClass(groupSharing, 'divHidden');
                        }
                    });
                    
                    // Load Permission Set
                    var permSetCmp = component.find("permSetCmp" + suffix);
                    permSetCmp.doInit(userID, storeResponse[1], function(result) {
                        console.log('Permission set result for scenario ' + suffix + ': ' + result);
                        var permSet = component.find("permSet" + suffix);
                        if(result) {
                            $A.util.addClass(permSet, 'divShowPermSet');
                        } else {
                            $A.util.addClass(permSet, 'divHiddenPermSet');
                        }
                    });
                }
            }
        });
        $A.enqueueAction(action);
    }
})