({
	doInit : function(component, event, helper) {
        var params = event.getParam('arguments');
        console.log('params permission set::' + params);
        var userID = params.userID;
        var objectAPI = params.objectAPI;
        var callback;
        if (params) {
			callback = params.callback;
        }
        if(objectAPI === undefined) {
            objectAPI = 'null';
        }
        
        var action = component.get("c.permissionSetAssigned");
        action.setParams({
            'userID': userID,
            'objectAPI': objectAPI,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                if (callback) callback(storeResponse);
                console.log('intra permission set::' + storeResponse.length);
                let permSetList = new Array();
                let existPermSet = false;
                if(storeResponse.length > 0) {
                    console.log('11243:;' + storeResponse[0].create);
                    for(let i = 0; i < storeResponse.length; i++) {
                        let wrapper = {'modifyAllData' : storeResponse[i].modifyAllData,
                                       'profileName' : storeResponse[i].profileName,
                                       'create' : storeResponse[i].create,
                                       'read' : storeResponse[i].read,
                                       'edit' : storeResponse[i].edit,
                                       'del' : storeResponse[i].del,
                                       'viewAllRecords' : storeResponse[i].viewAllRecords,
                                       'modifyAllRecords' : storeResponse[i].modifyAllRecords,
                                       'errorMSG' : storeResponse[i].errorMSG
									};
                        permSetList.push(wrapper);
                    }
                    console.log('array12::' + permSetList[0].viewAllRecords);
                    existPermSet = true;
                }
                component.set("v.permSetList", permSetList);
                component.set("v.existPermSet", existPermSet);
            }
        });
        $A.enqueueAction(action);
	},
})