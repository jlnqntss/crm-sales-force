({
  doInit: function (component) {
    let action;

    action = component.get("c.createActa");
    action.setParams({
      eventId: component.get("v.recordId")
    });

    action.setCallback(this, function (response) {
      let state = response.getState();
      console.log("State Contract: " + state);
      if (state === "SUCCESS") {
        component.set("v.isLoading", false); // terminar spinner

        $A.get("e.force:closeQuickAction").fire(); // cerrar quick action
        let actaIdResult = response.getReturnValue();

        // redirigir al registro acta
        let navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          recordId: actaIdResult,
          slideDevName: "related"
        });
        navEvt.fire();

        // refresco la vista de evento
        $A.get("e.force:refreshView").fire();
      } else {
        component.set("v.isLoading", false); // terminar spinner
        $A.get("e.force:closeQuickAction").fire(); // cerrar quick action

        // leer error y mostrar toast
        let errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
              title: "Error",
              message: errors[0].message,
              type: "error"
            });
            toastEvent.fire();
          }
        } else {
          component.set("v.isLoading", false);
          console.log("Unknown error");
        }
      }
    });

    $A.enqueueAction(action);
  }
});
