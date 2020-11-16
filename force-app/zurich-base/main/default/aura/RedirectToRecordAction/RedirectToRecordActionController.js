({
  invoke: function (component, event, helper) {
    if (component.get("v.openAsSubtab")) {
      return helper.openAsSubtab(
        component.get("v.recordId"),
        component.find("workspace")
      );
    }

    return helper.redirectTo(component.get("v.recordId"));
  }
});
