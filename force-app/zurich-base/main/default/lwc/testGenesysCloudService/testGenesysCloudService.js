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
    genesysCloud.consult(this.template.querySelector("lightning-input").value);
  }

  transfer() {
    genesysCloud.transfer(this.template.querySelector("lightning-input").value);
  }

  async startRecording() {
    var activeCalls = await genesysCloud.getActiveCalls();

    if (activeCalls.length) {
      genesysCloud.conference(
        this.template.querySelector("lightning-input").value,
        {
          parentConversationId: activeCalls[0].id
        },
        true
      );
    }
  }

  conference() {
    genesysCloud.conference(
      this.template.querySelector("lightning-input").value
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
