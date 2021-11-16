({
  doInit: function (component) {
    component.set("v.isClicked", true);
    const flow = component.find("flowData");
    flow.startFlow("ZECreateLead");
  }
});
