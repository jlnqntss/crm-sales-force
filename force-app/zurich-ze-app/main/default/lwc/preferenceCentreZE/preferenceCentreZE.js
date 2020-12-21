import { LightningElement, api, track, wire } from "lwc";
import getLabels from "@salesforce/apex/PreferenceCentreZEController.getLabels";
import processRequest from "@salesforce/apex/PreferenceCentreZEController.processRequest";
import ZURICH_LOGO from '@salesforce/resourceUrl/zurich_ze_logo';
 
export default class preferenceCentre extends LightningElement {
  // expose the static resource url for use in the template
  zurichLogoUrl = ZURICH_LOGO;

  @api hash;
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

  @wire(getLabels) 
  getLabels({ error, data }) {
      if (data) {
          this.label = JSON.parse(data);
      } else if (error) {
          console.error("Error recuperando etiquetas: " + JSON.stringify(error));
      }
  }

  connectedCallback() {
      this.scopeHash = this.hash;
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

        if( this.label.PreferenceCentreRedirect != '' ) {
            window.location.replace(this.label.PreferenceCentreRedirect);
        }
        
      } catch(error) {
          console.error(error);
      }
  }
}