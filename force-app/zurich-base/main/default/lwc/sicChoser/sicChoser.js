import { api, LightningElement, wire } from "lwc";
import { FlowNavigationNextEvent } from "lightning/flowSupport";
import getAvailableSics from "@salesforce/apex/RiskAppetiteController.getAvailableSICs";

export default class SicChoser extends LightningElement {
  // Variable to return the nextPage that should be opened
  @api nextPage;
  @api value = "";
  valueTrack;
  @api chosenValue;
  chosenValueTrack;
  @api label = "Escoge un SIC";
  initialized = false;

  @wire(getAvailableSics) optionsList;

  get chosenValue() {
    if (this.chosenValueTrack) {
      return this.chosenValueTrack;
    }
    return "";
  }

  get value() {
    if (this.valueTrack) {
      return this.valueTrack;
    }
    return "";
  }

  get options() {
    let options = [];
    if (this.optionsList.data) {
      this.optionsList.data.forEach((ele) => {
        options.push({ label: ele, value: ele });
      });
      return options;
    }
    return options;
  }

  renderedCallback() {
    if (this.initialized) {
      return;
    }
    this.initialized = true;
    let listId = this.template.querySelector("datalist").id;
    this.template.querySelector("input").setAttribute("list", listId);
  }

  // Function that makes the flow move to the next step
  handleNext() {
    this.chosenValueTrack = this.parseSelection(this.valueTrack);
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
  }

  parseSelection(labelSelected) {
    return labelSelected.split(" - ")[0];
  }

  handleChange(evt) {
    this.valueTrack = evt.target.value;
  }
}
