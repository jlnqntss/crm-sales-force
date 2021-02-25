({
  invoke: function (component, event, helper) {
    return new Promise(function (resolve, reject) {
      if ($A.util.isEmpty(component.get("v.recordId"))) {
        return resolve();
      }
      if (component.get("v.openAsSubtab")) {
        helper.openAsSubtab(
          component.get("v.recordId"),
          component.find("workspace"),
          component.get("v.focus")
        );

        return resolve();
      }

      return resolve(
        helper.redirectTo(
          component.get("v.recordId"),
          component.find("workspace"),
          component.get("v.focus")
        )
      );
    });
  }
});
