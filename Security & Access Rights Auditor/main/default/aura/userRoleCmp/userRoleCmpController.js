({
	doInit : function(component, event, helper) {
        var params = event.getParam('arguments');
        console.log('params user role::' + params);
        var userID = params.userID;
        var objectID = params.objectID;
        var callback;
        if (params) {
			callback = params.callback;
        }
        
        if(objectID === undefined) {
            objectID = 'null';
        }
        console.log('user role objectID::' + objectID);
        var action = component.get("c.sharingHierarchyRole");
        action.setParams({
            'userId': userID,
            'ObjectID': objectID,
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('state:;' + state);
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                if (callback) callback(storeResponse);
                console.log('aswe:;' + storeResponse);
                component.set("v.userRoleWrapper", storeResponse);
               
            }
        });
        $A.enqueueAction(action);
    },
})