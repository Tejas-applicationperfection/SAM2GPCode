({
	doInit : function(component, event, helper) {
        var params = event.getParam('arguments');
        console.log('params::' + params);
        var objectName = params.objectName;
        var objectLabel = params.objectLabel;
        console.log('OWD::' + objectName);
        var callback;
        if (params) {
			callback = params.callback;
        }
        if(objectName === undefined) {
            objectName = 'null';
        }
        
        var action = component.get("c.OWD");
        action.setParams({
            'objectName': objectName,
            'objectLabel': objectLabel,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                if (callback) callback(storeResponse);
                console.log('intra::' + storeResponse.organizationName);
                if(storeResponse.errorMSG !== 'false') {
                    component.find('notifLib').showNotice({
                        "variant": "error",
                        "header": "Something has gone wrong!",
                        "message": storeResponse.errorMSG
                    });
                } else {
                    component.set("v.organization", storeResponse);
                }
            }
        });
        $A.enqueueAction(action);
	},
})