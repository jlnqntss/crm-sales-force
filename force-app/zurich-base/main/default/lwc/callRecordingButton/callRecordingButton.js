import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import callRecordingStart from "@salesforce/label/c.callRecordingButtonStart";
import callRecordingStop from "@salesforce/label/c.callRecordingButtonStop";
import genesysCloud from "c/genesysCloudService";
import getRecordingPhoneNumber from "@salesforce/apex/CallRecordingController.getRecordingPhoneNumber";

export default class CallRecordingButton extends LightningElement {
  BUTTON_VARIANT_NORMAL = "brand";
  BUTTON_VARIANT_RECORDING = "destructive";

  label = {
    callRecordingStart,
    callRecordingStop
  };

  ctiMessageHandler = null;

  isSelected = false;
  hideRecordButton = true;
  @track timeVal = "00:00";
  @track labelWhenOff = this.label.callRecordingStart;
  @track labelWhenHover = this.label.callRecordingStop;

  timeIntervalInstance;
  totalMilliseconds = 0;

  buttonColor = this.BUTTON_VARIANT_NORMAL;

  @track isOnCall = false;
  @track recordingPhoneNumber;

  get isDisabled() {
    return !this.recordingPhoneNumber || !this.isOnCall;
  }

  /**
   * Event. Starts the lwc
   */
  connectedCallback() {
    getRecordingPhoneNumber().then((result) => {
      this.recordingPhoneNumber = result;
    });

    this.ctiMessageHandler = this.handleCTIMessage.bind(this);
    genesysCloud.addListener(this.ctiMessageHandler);
  }

  disconnectedCallback() {
    genesysCloud.removeListener(this.ctiMessageHandler);
    this.ctiMessageHandler = null;
  }

  /**
   * Event. The user tries to start/stop the recording
   */
  async handleRecordingClick() {
    try {
      await this.startRecording();
    } catch (error) {
      this.showMessage(
        error.body ? error.body.message : error.message,
        "error"
      );
    }
  }

  /**
   * Starts the recording
   *
   * @author nts (rlopez)
   */
  async startRecording() {
    var activeCalls = await genesysCloud.getActiveCalls();

    if (!activeCalls.length) {
      return Promise.resolve();
    }

    return genesysCloud.conference(
      this.recordingPhoneNumber,
      {
        parentConversationId: activeCalls[0].id
      },
      true
    );
  }

  /**
   * Show a message to the user
   *
   * @param {*} text the text to show in the popup
   * @param {*} type the type of message (warning, success, error)
   */
  showMessage(text, type) {
    const event = new ShowToastEvent({
      title: "Encontramos un problema al iniciar la grabación",
      message: text,
      variant: type
    });
    this.dispatchEvent(event);
  }

  /**
   * Set all the ui elements to tell the user that is recording
   */
  uiRecordingState() {
    this.labelWhenHover = this.label.callRecordingStop;
    this.startTimer(this);
    this.buttonColor = this.BUTTON_VARIANT_RECORDING;
  }

  /**
   * Set all the ui elements to tell the user that is ready for a new recording
   */
  uiInitialState() {
    this.isSelected = false;
    this.stopTimer(this);
    this.labelWhenOff = this.label.callRecordingStart;
    this.buttonColor = this.BUTTON_VARIANT_NORMAL;
  }

  handleCTIMessage(message) {
    if (message.type === "Interaction") {
      this.isOnCall = genesysCloud.isOnCall();
    }
  }
}
