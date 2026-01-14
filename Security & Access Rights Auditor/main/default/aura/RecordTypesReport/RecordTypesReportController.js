({
  openContactUSLink: function (component, event, helper) {
    var buttonLabel = event.getSource("").get("v.label");
    if (buttonLabel === "Request a feature/support") {
      window.open("https://applicationperfection.com/contact/");
    } else if (buttonLabel === "Help/Training") {
      window.open(
        "https://applicationperfection.com/security-access-manager-help-training/"
      );
    } else if (buttonLabel === "Release Notes") {
      window.open(
        "https://applicationperfection.com/security-access-manager-release-notes/"
      );
    }
  },

  doInit: function (component, event, helper) {
    var action = component.get("c.getAllTypeOfPermission");
    action.setCallback(this, function (response) {
      var state = response.getState();
	  component.set("v.allPermissionTypes", response.getReturnValue());
    });
    $A.enqueueAction(action);
  },

  handleChangeTypeofPermission: function (component, event, helper) {
   var action = component.get("c.getAllTypeOfPermission");
	action.setParams({
		selectedTypeOPermission : component.get("v.selectedTypeOPermission")
	})
    action.setCallback(this, function (response) {
      var state = response.getState();
	  component.set("v.allPermissionTypes", response.getReturnValue());
    });
    $A.enqueueAction(action);
  },
  
});