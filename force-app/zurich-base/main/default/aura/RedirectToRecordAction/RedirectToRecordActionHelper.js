({
  /**
   * Redirige a un registro de Salesforce
   * @author jmartinezpisson
   * @param {Id} recordId Id. de registro de Salesforce
   */
  redirectTo: function (recordId) {
    var redirectEvent = $A.get("e.force:navigateToSObject");

    if (window.sforce && window.sforce.one) {
      sforce.one.navigateToSObject(recordId);
    } else if (redirectEvent) {
      redirectEvent
        .setParams({
          recordId: recordId
        })
        .fire();
    }

    return Promise.resolve();
  },
  /**
   * Abre una subpestaña con el Id. de registro identificado
   * @author jmartinezpisson
   * @param {Id} recordId Id. de registro de Salesforce
   */
  openAsSubtab: function (recordId, workspaceAPI) {
    var helper = this;

    if (window.sforce && window.sforce.one) {
      sforce.one.navigateToSObject(recordId);
    }

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
        return helper.redirectTo(recordId);
      });
  }
});
