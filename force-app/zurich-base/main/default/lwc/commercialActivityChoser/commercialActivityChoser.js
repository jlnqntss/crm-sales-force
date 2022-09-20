import { api, LightningElement, wire } from "lwc";
import {
  FlowNavigationNextEvent,
  FlowAttributeChangeEvent
} from "lightning/flowSupport";
import getCommercialActivitiesForProducts from "@salesforce/apex/RiskAppetiteController.getCommercialActivitiesForProducts";

export default class CommercialActivityChoser extends LightningElement {
  // Variable to return the nextPage that should be opened
  @api nextPage = 0;
  nextPageTrack;
  @api value;
  valueTrack;
  @api chosenValue;
  chosenValueTrack;
  @api bunchLabel;
  @api sicLabel;
  @api sicCode;
  @api productCode;

  @wire(getCommercialActivitiesForProducts, {
    sicCode: "$sicCode",
    productCode: "$productCode"
  })
  optionsList;

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
          id: ele.label.replaceAll(" ", ""),
          riskAppetite: ele.riskAppetite,
          dyo: ele.dyo,
          ciber: ele.ciber,
          riskAppetiteBadge: ele.riskAppetiteBadge,
          dyoBadge: ele.dyoBadge,
          ciberBadge: ele.ciberBadge
        });
      });
      return options;
    }
    return options;
  }

  handleChange(variableName, value) {
    const attributeChangeEvent = new FlowAttributeChangeEvent(
      variableName,
      value
    );
    this.dispatchEvent(attributeChangeEvent);
  }

  moveForward() {
    this.handleChange("nextPage", this.nextPage);
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
  }

  handleSIC() {
    this.nextPageTrack = 1;
    this.moveForward();
  }

  handleBunch() {
    this.nextPageTrack = 2;
    this.moveForward();
  }

  parseSelection(labelSelected) {
    return labelSelected.split(" - ")[0];
  }

  handleClick(evt) {
    let position = evt.target.id.indexOf("-");
    this.chosenValueTrack = evt.target.id.substring(0, position);

    this.options.forEach((option) => {
      if (option.label.includes(this.chosenValueTrack)) {
        this.valueTrack = option.label;
      }
    });
    this.moveForward();
  }
}
