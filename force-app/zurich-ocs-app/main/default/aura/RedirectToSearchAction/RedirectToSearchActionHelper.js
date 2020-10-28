({
  /**
   * Redirige a un registro de Salesforce
   * @author jmartinezpisson
   */
  searchFor: function (searchFor) {
    var redirectEvent = $A.get("e.force:navigateToURL");
    var searchUrlHash = btoa(
      JSON.stringify({
        componentDef: "forceSearch:searchPageDesktop",
        attributes: {
          term: searchFor
        }
      })
    );

    if (redirectEvent) {
      redirectEvent
        .setParams({
          url: "/one/one.app#" + encodeURIComponent(searchUrlHash)
        })
        .fire();
    } else {
      sforce.one.navigateToURL(
        "/one/one.app#" + encodeURIComponent(searchUrlHash)
      );
    }
  }
});
