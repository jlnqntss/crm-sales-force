({
  closeModal: function (component) {
    component.set("v.ismodalClicked", false);
    let cmpTarget = component.find("Modalbox");
    let cmpBack = component.find("Modalbackdrop");
    $A.util.removeClass(cmpBack, "slds-backdrop--open");
    $A.util.removeClass(cmpTarget, "slds-fade-in-open");
  },

  openmodal: function (component) {
    component.set("v.ismodalClicked", true);
    let cmpTarget = component.find("Modalbox");
    let cmpBack = component.find("Modalbackdrop");
    $A.util.addClass(cmpTarget, "slds-fade-in-open");
    $A.util.addClass(cmpBack, "slds-backdrop--open");
  },

  manualDeUsuario: function () {
    let urlval =
      "https://zurich-es.lightning.force.com/lightning/r/ContentDocument/0695I000005JaluQAC/view";
    window.open(urlval, "_blank","noopener");
  }
});
