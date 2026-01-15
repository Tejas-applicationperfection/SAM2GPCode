/*({
	 getPermissionReviewData: function(component) {
       var action = component.get("c.getPermissionReviewData");
       action.setCallback(this, function(response) {
           var state = response.getState();
           if (state === "SUCCESS") {
               var permissionReviewData = response.getReturnValue();
               component.set("v.permissionReviewData", permissionReviewData);
           } else {
               console.log("Error retrieving permission review data");
           }
       });
       $A.enqueueAction(action);
   },
     getExistingDates: function(component) {
          var dateData = component.get("v.dateData");
          dateData.forEach(function(item) {
            var action = component.get("c.getExistingDatesFromServer");
           action.setParams({
                recordName: item.name
            });
                action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var existingDate = response.getReturnValue();
                    item.value = existingDate;
                    component.set("v.dateData", dateData);
                }  else {
               console.log("Error retrieving permission review data");
           }
            });

            $A.enqueueAction(action);
        }); 
    },
})  */

({
    getPermissionReviewData: function(component) {
        var action = component.get("c.getPermissionReviewData");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var permissionReviewData = response.getReturnValue();
                component.set("v.permissionReviewData", permissionReviewData);
            } else {
                var errors = response.getError();
                if (errors && errors[0] && errors[0].message) {
                    console.error("Error retrieving permission review data: " + errors[0].message);
                } else {
                    console.error("Unknown error retrieving permission review data");
                }
            }
        });
        $A.enqueueAction(action);
    },

    getExistingDates: function(component) {
        var dateData = component.get("v.dateData");
        dateData.forEach(function(item) {
            var action = component.get("c.getExistingDatesFromServer");
            action.setParams({
                recordName: item.name
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var existingDate = response.getReturnValue();
                    item.value = existingDate;
                    component.set("v.dateData", dateData);
                } else {
                    var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        console.error("Error retrieving existing dates for " + item.name + ": " + errors[0].message);
                    } else {
                        console.error("Unknown error retrieving existing dates for " + item.name);
                    }
                }
            });
            $A.enqueueAction(action);
        }); 
    },
})