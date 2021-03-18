import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendSurveyLabel from "@salesforce/label/c.sendSurveyButtonLabel";
import sendSurveyToastTitleSuccess from "@salesforce/label/c.sendSurveyToastTitleSuccess";
import sendSurveyToastMessageSuccess from "@salesforce/label/c.sendSurveyToastMessageSuccess";
import genesysCloud from "c/genesysCloudService";
import getPollPhoneNumber from "@salesforce/apex/SendSurveyButtonController.getTransferPollPhoneNumber";

export default class SendSurveyButton extends LightningElement {
  label = {
    sendSurveyLabel,
    sendSurveyToastTitleSuccess,
    sendSurveyToastMessageSuccess
  };

  @track isDisabled = true;
  pollPhoneNumber;

  @track logs = [];
  connectedCallback() {
    getPollPhoneNumber().then((result) => {
      if (result) {
        this.isDisabled = false;
      }

      this.pollPhoneNumber = result;
    });
  }

  sendSurvey() {
    genesysCloud.transfer(this.pollPhoneNumber);
    const event = new ShowToastEvent({
      title: this.label.sendSurveyToastTitleSuccess,
      message: this.label.sendSurveyToastMessageSuccess,
      variant: "success"
    });
    this.dispatchEvent(event);
  }
}
