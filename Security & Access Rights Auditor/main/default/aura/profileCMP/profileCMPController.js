({
	doInit : function(component, event, helper) {
        var params = event.getParam('arguments');
        console.log('params::' + params);
        var userID = params.userID;
        var objectAPI = params.objectAPI;
        console.log('profile::' + objectAPI);
        var callback;
        if (params) {
			callback = params.callback;
        }
        if(objectAPI === undefined) {
            objectAPI = 'null';
        }
        
        var action = component.get("c.Profile");
        action.setParams({
            'userID': userID,
            'objectAPI': objectAPI,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                if (callback) callback(storeResponse);
                if(storeResponse.errorMSG !== 'false') {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Something has gone wrong!",
                        "message": storeResponse.errorMSG
                    });
                } else {
                    component.set("v.profile", storeResponse);
                }
            }
        });
        $A.enqueueAction(action);
	},
})