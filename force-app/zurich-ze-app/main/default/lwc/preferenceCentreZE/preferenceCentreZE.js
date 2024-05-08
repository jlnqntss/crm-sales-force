import { LightningElement, api, track, wire } from "lwc";
import getLabels from "@salesforce/apex/PreferenceCentreZEController.getLabels";
import processRequest from "@salesforce/apex/PreferenceCentreZEController.processRequest";
import getLogoUrl from "@salesforce/apex/PreferenceCentreZEController.getLogoUrl";

export default class preferenceCentre extends LightningElement {
  // expose the static resource url for use in the template
  @track zurichLogoUrl = "";
  @api hash;
  @api scope;
  @track scopeHash;
  @track currentScope;
  @track _isCheckedHasOptedOutOfEmail = false;
  @track clickedButtonLabel;

  isLoading = false;

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

  @wire(getLabels)
  getLabels({ error, data }) {
    if (data) {
      this.label = JSON.parse(data);
    } else if (error) {
      console.error("Error recuperando etiquetas: " + JSON.stringify(error));
    }
  }

  connectedCallback() {
    if (this.hash != null) {
      //Visualforce
      this.scopeHash = this.hash;
      this.currentScope = this.scope;
    } else {
      //Community
      this.scopeHash = this.getUrlParamValue(window.location.href, "Hash");
      this.currentScope = this.getUrlParamValue(window.location.href, "scope");
    }

    getLogoUrl({
      scope: this.currentScope
    })
      .then((result) => {
        this.zurichLogoUrl = result;
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
    this.isLoading = true;

    processRequest({
      hashedId: this.scopeHash,
      hasOptedOutOfEmail: this._isCheckedHasOptedOutOfEmail
    })
      .then(() => {
        if (this.label.PreferenceCentreRedirect) {
          const trustedDomains = [
            "zurich-es--qa.sandbox.my.salesforce-sites.com",
            "zurich-es--qa.sandbox.my.site.com",
            "zurich-es.my.salesforce-sites.com",
            "zurich-es.my.site.com"
          ];

          const preferenceCentreRedirectURL =
            this.label.PreferenceCentreRedirect;

          if (
            preferenceCentreRedirectURL.origin === window.location.origin &&
            trustedDomains.includes(preferenceCentreRedirectURL)
          ) {
            window.location.replace(preferenceCentreRedirectURL);
          }
        }
      })
      .catch((error) => {
        console.error(error);
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  getUrlParamValue(url, key) {
    return new URL(url).searchParams.get(key);
  }
}
