({
  /**
   * Redirige a un registro de Salesforce
   * @author jmartinezpisson
   */
  redirectTo: function (recordId) {
    var redirectEvent = $A.get("e.force:navigateToSObject");

    if (redirectEvent) {
      redirectEvent
        .setParams({
          recordId: recordId
        })
        .fire();
    } else {
      sforce.one.navigateToSObject(recordId);
    }
  }
});
