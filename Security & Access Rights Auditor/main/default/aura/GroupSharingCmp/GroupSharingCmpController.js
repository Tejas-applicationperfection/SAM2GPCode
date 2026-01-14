({
	doInit : function(component, event, helper) {
        var params = event.getParam('arguments');
        console.log('params::' + JSON.stringify(params));
          
        var userID = params.userID;
         console.log('GRPuserID::' + userID);
        var objectAPI = params.objectID;
         console.log('GRpobjectAPI::' + objectAPI);
        console.log('profile::' + objectAPI);
        var callback;
        if (params) {
			callback = params.callback;
        }
        
        
        var action = component.get("c.GroupAsigned");
        action.setParams({
            'userIdRemote': userID,
            'ObjectID': objectAPI,
        });
        /*action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                if (callback) callback(storeResponse);
                   console.log('response---',JSON.stringify(storeResponse));
              
                console.log('GroupShr:', JSON.stringify(component.get("v.GroupShr")));
                    console.log('response---',JSON.stringify(storeResponse));
                    component.set("v.GroupShr", storeResponse);
                  console.log('GroupShrafter:', JSON.stringify(component.get("v.GroupShr")));
                
            }
        });*/
       action.setCallback(this, function(response) {
    var state = response.getState();
    if (state === "SUCCESS") {
        var storeResponse = response.getReturnValue();
        
        if (callback) callback(storeResponse);

        console.log('response---', JSON.stringify(storeResponse));

        // Extract the shrGroupMap keys and values dynamically
        var shrGroupMap = storeResponse.shrGroupMap;
        var groupEntries = [];

        for (var key in shrGroupMap) {
            if (shrGroupMap.hasOwnProperty(key)) {
                let groupData = shrGroupMap[key];

                // Dynamically find the access level field (e.g., AccountAccessLevel, OpportunityAccessLevel, etc.)
                let accessLevelKey = Object.keys(groupData).find(k => k.includes('AccessLevel'));

                groupEntries.push({
                    key: key,
                    details: groupData,
                    accessLevelField: accessLevelKey,  // Store the dynamic key
                    accessLevelValue: groupData[accessLevelKey]  // Store the value dynamically
                });
            }
        }

        console.log('Extracted Group Entries:', JSON.stringify(groupEntries));

        // Store the data in component attributes
        component.set("v.GroupShr", storeResponse);
        component.set("v.GroupShrDetails", groupEntries);

        console.log('GroupShr after:', JSON.stringify(component.get("v.GroupShr")));
        console.log('GroupShrDetails:', JSON.stringify(component.get("v.GroupShrDetails")));
    }
});

        $A.enqueueAction(action);
	},
})