import { LightningElement, api, track, wire } from "lwc";
import getLabels from "@salesforce/apex/PreferenceCentreZEController.getLabels";
import processRequest from "@salesforce/apex/PreferenceCentreZEController.processRequest";
import getLogoUrl from "@salesforce/apex/PreferenceCentreZEController.getLogoUrl";

export default class preferenceCentre extends LightningElement {
  // expose the static resource url for use in the template
  @track zurichLogoUrl = "";
  @api hash;
  @track scope;
  @track scopeHash;
  @track _isCheckedHasOptedOutOfEmail = false;
  @track clickedButtonLabel;

  @track label = {
    PreferenceCentreTitleLabel: "",
    PreferenceCentreSubtitleLabel: "",
    CampaignCheckboxLabel: "",
    EmailOptOutCheckboxLabel: "",
    EmailOptOutTextLabel: "",
    EmailOptOutButtonLabel: "",
    PreferenceCentreSaveLabel: "",
    PreferenceCentreRedirect: ""
  };

  // Get the logo url by the scope parameter
  /*@wire(getLogoUrl, { scope: this.scope }) wiredLogoResult(result) {
    if (result.data) {
      this.zurichLogoUrl = result.data;
    }
  }*/

  @wire(getLabels)
  getLabels({ error, data }) {
    if (data) {
      this.label = JSON.parse(data);
    } else if (error) {
      console.error("Error recuperando etiquetas: " + JSON.stringify(error));
    }
  }

  connectedCallback() {
    var that = this;

    this.scopeHash = this.getUrlParamValue(window.location.href, "Hash");
    this.scope = this.getUrlParamValue(window.location.href, "scope");

    getLogoUrl({
      scope: this.scope
    })
      .then(function (result) {
        that.zurichLogoUrl = result;
      })
      .catch(function (err) {
        console.log(err);
      });
  }

  /*
    Event: user clicks Out of Email checkbox
  */
  handleChange(event) {
    this._isCheckedHasOptedOutOfEmail = event.target.checked;
  }

  /*
    Event: user clicks save changes button
  */
  handleClick(event) {
    this.clickedButtonLabel = event.target.label;

    try {
      processRequest({
        hashedId: this.scopeHash,
        hasOptedOutOfEmail: this._isCheckedHasOptedOutOfEmail
      });

      if (this.label.PreferenceCentreRedirect !== "") {
        window.location.replace(this.label.PreferenceCentreRedirect);
      }
    } catch (error) {
      console.error(error);
    }
  }

  getUrlParamValue(url, key) {
    return new URL(url).searchParams.get(key);
  }
}
