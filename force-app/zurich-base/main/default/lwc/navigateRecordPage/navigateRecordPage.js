import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class HyperlinkedString extends NavigationMixin(LightningElement) {
  @api recordId;
  @api textToDisplay;
  @api sObject;

  navigateToRecord() {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: this.recordId,
        objectApiName: this.sObject,
        actionName: "view"
      }
    });
  }
}
