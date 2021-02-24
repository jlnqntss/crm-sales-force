({
  /**
   * Redirige a un registro de Salesforce
   * @author jmartinezpisson
   * @param {Id} recordId Id. de registro de Salesforce
   */
  redirectTo: function (recordId, workspaceAPI, focus) {
    var redirectEvent = $A.get("e.force:navigateToSObject");

    if (window.sforce && window.sforce.one) {
      sforce.one.navigateToSObject(recordId);
    } else if (redirectEvent) {
      return workspaceAPI
        .isConsoleNavigation()
        .then(function (isConsole) {
          if (!isConsole) {
            throw "Not in Console";
          }

          return workspaceAPI.openTab({
            focus: focus,
            recordId: recordId
          });
        })
        .catch(function (error) {
          redirectEvent
            .setParams({
              recordId: recordId,
              isredirect: focus
            })
            .fire();
        });
    }

    return Promise.resolve();
  },
  /**
   * Abre una subpestaña con el Id. de registro identificado
   * @author jmartinezpisson
   * @param {Id} recordId Id. de registro de Salesforce
   */
  openAsSubtab: function (recordId, workspaceAPI, focus) {
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
          focus: focus,
          recordId: recordId
        });
      })
      .catch(function (error) {
        return helper.redirectTo(recordId);
      });
  }
});
