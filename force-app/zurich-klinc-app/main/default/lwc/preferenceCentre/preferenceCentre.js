import { LightningElement, api, track, wire } from "lwc";
import getLogoUrl from "@salesforce/apex/PreferenceCentreController.getLogoUrl";
import getAllCampaigns from "@salesforce/apex/PreferenceCentreController.getAllCampaigns";
import getLabelTranslation from "@salesforce/apex/PreferenceCentreController.getLabelTranslation";
import processRequest from "@salesforce/apex/PreferenceCentreController.processRequest";

export default class preferenceCentre extends LightningElement {
  @api hash;
  @api language;
  @track contactHash;
  @track sObjData = [];
  @track campaigns = [];
  @track _isCheckedHasOptedOutOfEmail = false;
  @track _isCheckedCampaign = false;
  @track clickedButtonLabel;

  @track label = {
    PreferenceCentreTitleLabel: "",
    PreferenceCentreSubtitleLabel: "",
    CampaignCheckboxLabel: "",
    EmailOptOutCheckboxLabel: "",
    EmailOptOutTextLabel: "",
    EmailOptOutButtonLabel: "",
    PreferenceCentreSaveLabel: ""
  };

  // Default value for when no logo static resources are found
  @track zurichLogoUrl = "";

  // Get the logo url by contact country
  @wire(getLogoUrl, { hashedId: "$hash" }) wiredLogoResult(result) {
    if (result.data) {
      this.zurichLogoUrl = result.data;
    }
  }

  @wire(getAllCampaigns, { hashedId: "$hash", language: "$language" })
  wiredResult(result) {
    if (result.data) {
      this.sObjData = result.data;
    }
  }

  @wire(getLabelTranslation, { language: "$language" })
  wiredLabelTranslations({ error, data }) {
    if (data) {
      for (let label of JSON.parse(data)) {
        switch (label.masterLabel) {
          case "PreferenceCentreTitle":
            this.label.PreferenceCentreTitleLabel = label.value
              ? label.value
              : label.defaultValue;
            break;
          case "PreferenceCentreSubtitle":
            this.label.PreferenceCentreSubtitleLabel = label.value
              ? label.value
              : label.defaultValue;
            break;
          case "CampaignCheckbox":
            this.label.CampaignCheckboxLabel = label.value
              ? label.value
              : label.defaultValue;
            break;
          case "EmailOptOutCheckbox":
            this.label.EmailOptOutCheckboxLabel = label.value
              ? label.value
              : label.defaultValue;
            break;
          case "EmailOptOutText":
            this.label.EmailOptOutTextLabel = label.value
              ? label.value
              : label.defaultValue;
            break;
          case "EmailOptOutButton":
            this.label.EmailOptOutButtonLabel = label.value
              ? label.value
              : label.defaultValue;
            break;
          case "PreferenceCentreSave":
            this.label.PreferenceCentreSaveLabel = label.value
              ? label.value
              : label.defaultValue;
            break;
          default:
            break;
        }
      }
    } else if (error) {
      window.console.error(
        "Error retrieving label translations: " + JSON.stringify(error)
      );
    }
  }
  connectedCallback() {
    this.contactHash = this.hash;
  }

  handleChange(event) {
    this._isCheckedHasOptedOutOfEmail = event.target.checked;
  }

  handleCheckboxChange(event) {
    this._isCheckedCampaign = event.target.checked;

    let campaign = event.target.name;
    let str = JSON.stringify(this.sObjData);
    let copy = JSON.parse(str);

    for (let i = 0; i < copy.length; i++) {
      if (copy[i].idCampaign === campaign) {
        copy[i].contactSubscribed = this._isCheckedCampaign;
      }
    }

    this.sObjData = copy;
  }

  handleClick(event) {
    this.clickedButtonLabel = event.target.label;

    processRequest({
      hashedId: this.contactHash,
      hasOptedOutOfEmail: this._isCheckedHasOptedOutOfEmail,
      campaigns: this.sObjData
    });

    window.location.replace("https://klinc.com/");
  }
}
