({
  handleNavigation: function (component, event, helper) {
    event.preventDefault();
    let target = event.getParam("utilityBarIcon");
    let utilityAPI = component.find("utilitybar");
    utilityAPI
      .getAllUtilityInfo()
      .then(function (response) {
        let myUtilityInfo = response.find(
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
