import {
  APPLICATION_SCOPE,
  createMessageContext,
  publish,
  subscribe
} from "lightning/messageService";
import genesysCloudChannel from "@salesforce/messageChannel/purecloud__ClientEvent__c";
import conferenceTo from "@salesforce/apex/GenesysCloudLightningController.conferenceTo";
import isAuthorized from "@salesforce/apex/GenesysCloudLightningController.isAuthorized";
import authorize from "@salesforce/apex/GenesysCloudLightningController.authorize";
import getActiveCalls from "@salesforce/apex/GenesysCloudLightningController.getActiveCalls";

const messageContext = createMessageContext();
const state = {
  logs: [],
  listeners: [],
  currentInteractionId: null
};

subscribe(
  messageContext,
  genesysCloudChannel,
  (message) => {
    console.log(message);
    state.logs.push(message);
    if (message.type === "Interaction" && message.data.id) {
      state.currentInteractionId = message.data.id;
    }
    if (state.listeners.length) {
      state.listeners.forEach((listener) => {
        listener(message);
      });
    }
  },
  { scope: APPLICATION_SCOPE }
);

function publishMessage(payload) {
  return publish(messageContext, genesysCloudChannel, payload);
}

export default {
  addListener(listener) {
    state.listeners.push(listener);

    return state.logs;
  },
  transfer(phoneNumber) {
    return publishMessage({
      type: "PureCloud.Interaction.updateState",
      data: {
        action: "blindTransfer",
        id: state.currentInteractionId,
        participantContext: {
          transferTarget: encodeURIComponent(phoneNumber),
          transferTargetType: "address"
        }
      }
    });
  },
  consult(phoneNumber) {
    return publishMessage({
      type: "PureCloud.Interaction.updateState",
      data: {
        action: "consultTransfer",
        id: state.currentInteractionId,
        participantContext: {
          transferTarget: encodeURIComponent(phoneNumber),
          transferTargetType: "address"
        }
      }
    });
  },
  conference(phoneNumber, attributesByName, fallbackToUUI) {
    return conferenceTo({
      toAddress: phoneNumber,
      attributesByName: attributesByName,
      fallbackToUUI: fallbackToUUI
    });
  },
  getActiveCalls() {
    return getActiveCalls();
  },
  isAuthorized() {
    return isAuthorized();
  },
  async authorize() {
    var authorizeURL = await authorize();

    window.open(authorizeURL);
  }
};
