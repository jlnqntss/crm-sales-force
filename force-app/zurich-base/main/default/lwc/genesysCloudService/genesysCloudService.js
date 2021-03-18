import {
  APPLICATION_SCOPE,
  createMessageContext,
  publish,
  subscribe
} from "lightning/messageService";
import genesysCloudChannel from "@salesforce/messageChannel/purecloud__ClientEvent__c";

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
    console.log("state.currentInteractionId: " + state.currentInteractionId);
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
  conference(phoneNumber) {
    publishMessage({
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

    return publishMessage({
      type: "PureCloud.Interaction.updateState",
      data: {
        action: "pickup",
        id: state.currentInteractionId
      }
    });
  }
};
