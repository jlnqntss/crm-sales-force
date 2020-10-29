({
  invoke: function (component, event, helper) {
    return helper.searchFor(component.get("v.searchFor"));
  }
});
