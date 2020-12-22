({
  /**
   * Redirige a un registro de Salesforce
   * @author jmartinezpisson
   * @param {Id} recordId Id. de registro de Salesforce
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
  },
  /**
   * Abre una subpestaña con el Id. de registro identificado
   * @author jmartinezpisson
   * @param {Id} recordId Id. de registro de Salesforce
   */
  openAsSubtab: function (recordId, workspaceAPI) {
    var helper = this;

    return workspaceAPI
      .getFocusedTabInfo()
      .then(function (response) {
        var focusedTabId = response.tabId;

        return workspaceAPI.openSubtab({
          parentTabId: focusedTabId,
          recordId: recordId
        });
      })
      .catch(function (error) {
        console.log(error);
        return helper.redirectTo(recordId);
      });
  }
});
