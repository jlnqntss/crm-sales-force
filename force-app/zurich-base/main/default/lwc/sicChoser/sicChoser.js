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

  // Wire para recuperar todos los registros
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

  /**
   * Function that makes the flow move to the next step
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  handleNext() {
    this.chosenValueTrack = this.parseSelection(this.valueTrack);
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
  }

  /**
   * Función que parsea el elemento escogido
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  parseSelection(labelSelected) {
    return labelSelected.split(" - ")[0];
  }

  /**
   * Función que guarda el valor clickado
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  handleChange(evt) {
    this.valueTrack = evt.target.value;
  }
}
