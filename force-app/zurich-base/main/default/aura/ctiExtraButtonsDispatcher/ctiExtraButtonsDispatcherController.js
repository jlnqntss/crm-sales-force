({
  handleNavigation: function (component, event, helper) {
    event.preventDefault();
    var target = event.getParam("utilityBarIcon");
    var utilityAPI = component.find("utilitybar");
    utilityAPI
      .getAllUtilityInfo()
      .then(function (response) {
        var myUtilityInfo = response.find(
          (utility) => utility.utilityIcon === target
        );
        utilityAPI.openUtility({
          utilityId: myUtilityInfo.id
        });
      })
      .catch(function (error) {
        console.log(error);
      });
  }
});
