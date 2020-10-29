({
    invoke : function(component, event, helper) {
      return helper.redirectTo(component.get("v.recordId"));
    }
})