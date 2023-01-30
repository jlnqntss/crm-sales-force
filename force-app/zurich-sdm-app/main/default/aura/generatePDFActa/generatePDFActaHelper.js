({
  checkActaExists: function (component) {
    let action = component.get("c.checkActaExists"); // calls an apex method
    action.setParams({
      eventId: component.get("v.recordId")
    });
    return new Promise(
      $A.getCallback(function (resolve, reject) {
        action.setCallback(this, function (response) {
          let state = response.getState();
          if (state === "SUCCESS") {
            let apexResponse = response.getReturnValue();
            resolve(apexResponse);
          } else {
            // control errores
            let errors = response.getError();
            let messageError;
            if (errors) {
              if (errors[0] && errors[0].message) {
                // log the error passed in to AuraHandledException
                messageError = errors[0].message;
              }
            }
            reject(messageError);
          }
        });
        $A.enqueueAction(action);
      })
    );
  },
  previewActaTemplate: function (component, actaName) {
    let eventId = component.get("v.recordId");
    let workspaceAPI = component.find("workspace");
    workspaceAPI
      .openTab({
        url: "/apex/TemplateActaPDF?id=" + eventId,
        focus: true
      })
      .then(function (response) {
        console.log("entro en primer then " + JSON.stringify(response));
        // el codigo comentado set label y set icon funciona bien cuando es previsualizar
        workspaceAPI
          .setTabLabel({
            tabId: response,
            label: actaName
          })
          .then(function () {
            workspaceAPI.setTabIcon({
              tabId: response,
              icon: "doctype:pdf",
              iconAlt: "PDF"
            });
          });
      })
      .catch(function (error) {
        console.log(error);
      });
  },

  showToastMessage: function (toastTitle, toastMessage, toastMode) {
    let toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: toastTitle,
      message: toastMessage,
      type: toastMode
    });
    toastEvent.fire();
  }
});
