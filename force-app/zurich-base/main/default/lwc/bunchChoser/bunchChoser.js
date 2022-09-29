import { api, LightningElement, wire } from "lwc";
import {
  FlowNavigationNextEvent,
  FlowAttributeChangeEvent
} from "lightning/flowSupport";
import getProductsForSIC from "@salesforce/apex/RiskAppetiteController.getProductsForSIC";
import getOtherProducts from "@salesforce/apex/RiskAppetiteController.getOtherProducts";

const columns = [
  {
    label: "Ramo",
    type: "String",
    fieldName: "MasterLabel"
  },
  {
    label: "Código del ramo",
    type: "String",
    fieldName: "ProductCode__c"
  },
  {
    label: "Enlace a sharepoint",
    type: "url",
    typeAttributes: { label: "Abrir Sharepoint" },
    fieldName: "SharepointLink__c"
  }
];

export default class BunchChoser extends LightningElement {
  // Variable to return the nextPage that should be opened
  @api nextPage;
  nextPageTrack;
  @api sicCode;
  @api value;
  valueTrack;
  @api chosenValue;
  chosenValueTrack;
  @api label;

  showModal = false;
  otherProductList;
  columns = columns;

  @wire(getProductsForSIC, { sicCode: "$sicCode" }) optionsList;
  @wire(getOtherProducts) otherProductList;

  get chosenValue() {
    return this.chosenValueTrack;
  }

  get value() {
    return this.valueTrack;
  }

  get nextPage() {
    return this.nextPageTrack;
  }

  get options() {
    let options = [];
    if (this.optionsList.data) {
      this.optionsList.data.forEach((ele) => {
        options.push({
          label: ele.label,
          value: ele.label,
          id: ele.label.split(" - ")[0],
          badgeLabel: ele.buttonLabel,
          badgeClass: ele.buttonClass,
          productLink: ele.sharepoint,
          dyoLink: ele.dyoSharepoint,
          ciberLink: ele.ciberSharepoint
        });
      });
      return options;
    }
    return options;
  }

  // Function that makes the flow move to the next step
  handleNext() {
    this.nextPageTrack = 0;
    this.handleChange("nextPage", this.nextPage);
    this.moveForward();
  }

  handleChange(variableName, value) {
    const attributeChangeEvent = new FlowAttributeChangeEvent(
      variableName,
      value
    );
    this.dispatchEvent(attributeChangeEvent);
  }

  moveForward() {
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
  }

  handleSIC() {
    this.nextPageTrack = 1;
    this.handleChange("nextPage", this.nextPage);
    this.moveForward();
  }

  parseSelection(labelSelected) {
    return labelSelected.split(" - ")[0];
  }

  handleClick(evt) {
    const position = evt.target.id.indexOf("-");
    this.chosenValueTrack = evt.target.id.substring(0, position);

    this.options.forEach((option) => {
      if (option.label.includes(this.chosenValueTrack)) {
        this.valueTrack = option.label;
      }
    });
    this.handleNext();
  }

  goToDoc(event) {
    const URL = event.target.value;
    window.open(URL, "_blank").focus();
  }

  openModal() {
    // getOtherProducts().then(result => {
    //   console.log("****** result: ");
    //   console.log(result);
    //   this.otherProductList = result;
    //   console.log(this.otherProductList);
    // }).catch(error=>{
    //   console.log("****** error: ");
    //   console.log(error);
    // })

    console.log(columns);
    // Setting boolean variable to true, this will show the Modal
    this.showModal = true;
  }
  closeModal() {
    // Setting boolean variable to false, this will hide the Modal
    this.showModal = false;
  }
}
