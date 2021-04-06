import { LightningElement, track } from "lwc";
import genesysCloud from "c/genesysCloudService";

export default class TestGenesysCloudService extends LightningElement {
  @track logs = [];

  connectedCallback() {
    this.logs = genesysCloud
      .addListener(this.logMessage.bind(this))
      .map((message, index) => {
        return {
          id: index,
          message: JSON.stringify(message, null, 2)
        };
      });
  }

  consult() {
    genesysCloud.conference(
      this.template.querySelector("lightning-input").value
    );
  }

  transfer() {
    genesysCloud.transfer(this.template.querySelector("lightning-input").value);
  }

  conference() {
    genesysCloud.conference(
      this.template.querySelector("lightning-input").value,
      "Mi llamada"
    );
  }

  logMessage(message) {
    this.logs.push({
      id: this.logs.length,
      message: JSON.stringify(message, null, 2)
    });
  }

  clearLog() {
    this.logs.length = 0;
  }

  authorize() {
    genesysCloud.authorize();
  }
}
