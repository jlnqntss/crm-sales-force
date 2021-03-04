import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendSurveyLabel from "@salesforce/label/c.sendSurveyButtonLabel";
import sendSurveyToastTitleSuccess from "@salesforce/label/c.sendSurveyToastTitleSuccess";
import sendSurveyToastMessageSuccess from "@salesforce/label/c.sendSurveyToastMessageSuccess";

export default class SendSurveyButton extends LightningElement {
  label = {
    sendSurveyLabel,
    sendSurveyToastTitleSuccess,
    sendSurveyToastMessageSuccess
  };

  sendSurvey() {
    const event = new ShowToastEvent({
      title: this.label.sendSurveyToastTitleSuccess,
      message: this.label.sendSurveyToastMessageSuccess,
      variant: "success"
    });
    this.dispatchEvent(event);
  }
}
