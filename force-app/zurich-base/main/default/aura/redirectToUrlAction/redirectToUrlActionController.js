({
  invoke: function (component, event, helper) {
    return helper.redirectTo(
      component.get("v.url"),
      component.get("v.isRedirect")
    );
  }
});
