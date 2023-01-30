({
  previewButton: function (component, event, helper) {
    let closeQuickActionEvent = $A.get("e.force:closeQuickAction");
    helper
      .checkActaExists(component)
      .then(function (result) {
        if (result) {
          // llamar a crear tab
          helper.previewActaTemplate(component, result);
        } else {
          closeQuickActionEvent.fire(); // lanzo el evento de cierre
          helper.showToastMessage(
            $A.get("$Label.c.SDM_Acta_WarningToastTitle"),
            $A.get("$Label.c.SDM_Acta_NoActaWarningToastMessage"),
            "warning"
          );
        }
      })
      .catch(function (error) {
        helper.showToastMessage(
          $A.get("$Label.c.SDM_Acta_ErrorToastTitle"),
          error,
          "error"
        );
      });
  },
  downloadButton: function (component, event, helper) {
    let closeQuickActionEvent = $A.get("e.force:closeQuickAction");
    helper
      .checkActaExists(component)
      .then(function (result) {
        if (result) {
          // descargar fichero
          let eventId = component.get("v.recordId");
          window.open("/apex/TemplateActaPDF?id=" + eventId + "&mode=download");
          closeQuickActionEvent.fire();
        } else {
          closeQuickActionEvent.fire(); // lanzo el evento de cierre
          // mostrar mensaje de error
          helper.showToastMessage(
            $A.get("$Label.c.SDM_Acta_WarningToastTitle"),
            $A.get("$Label.c.SDM_Acta_NoActaWarningToastMessage"),
            "warning"
          );
        }
        console.log("fin download button");
      })
      .catch(function (error) {
        helper.showToastMessage(
          $A.get("$Label.c.SDM_Acta_ErrorToastTitle"),
          error,
          "error"
        );
      });
  }
});
