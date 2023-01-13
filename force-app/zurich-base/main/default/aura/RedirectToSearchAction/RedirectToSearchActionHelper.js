({
  /**
   * Redirige a un registro de Salesforce
   * @author jmartinezpisson
   */
  searchFor: function (searchFor) {
    let redirectEvent = $A.get("e.force:navigateToURL");
    let searchUrlHash = btoa(
      JSON.stringify({
        componentDef: "forceSearch:searchPageDesktop",
        attributes: {
          term: searchFor
        }
      })
    );

    if (window.sforce && window.sforce.one) {
      sforce.one.navigateToURL(
        "/one/one.app#" + encodeURIComponent(searchUrlHash),
        true
      );
    } else if (redirectEvent) {
      redirectEvent
        .setParams({
          url: "/one/one.app#" + encodeURIComponent(searchUrlHash),
          isRedirect: true
        })
        .fire();
    }

    return Promise.resolve();
  }
});
