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

  isSelected = false;
  hideRecordButton = true;
  @track timeVal = "00:00";
  @track labelWhenOff = this.label.callRecordingStart;
  @track labelWhenHover = this.label.callRecordingStop;

  timeIntervalInstance;
  totalMilliseconds = 0;

  buttonColor = this.BUTTON_VARIANT_NORMAL;

  isDisabled = true;
  recordingPhoneNumber;

  /**
   * Event. Starts the lwc
   */
  connectedCallback() {
    getRecordingPhoneNumber().then((result) => {
      if (result) {
        this.isDisabled = false;
      }

      this.recordingPhoneNumber = result;
    });
  }

  /**
   * Event. The user tries to start/stop the recording
   */
  handleRecordingClick() {
    try {
      genesysCloud.consult(this.recordingPhoneNumber);
      this.isDisabled = true;
      //console.log('start recording...');

      //this.isSelected = !this.isSelected;
      // this.template.querySelector(`[data-id="record-button"]`).blur();
      // if (this.isSelected) {
      //     //genesysCloud.consult(this.pollPhoneNumber);
      //     // ui change: Recording...
      //     this.uiRecordingState();
      // } else {
      //     this.uiInitialState();
      // }
    } catch (error) {
      // this.uiInitialState();
      this.isDisabled = false;
      console.error(error);
      this.showMessage(error, "error");
    }
  }

  /**
   * Starts the recording timer
   *
   * @author nts (rlopez)
   * @param {*} parentThis represents the lwc itself for global variable access
   */
  startTimer(parentThis) {
    parentThis.totalMilliseconds = 0;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    parentThis.timeIntervalInstance = setInterval(function () {
      // Time calculations for hours, minutes, seconds and milliseconds
      var minutes = Math.floor(
        (parentThis.totalMilliseconds % (1000 * 60 * 60)) / (1000 * 60)
      );
      var seconds = Math.floor(
        (parentThis.totalMilliseconds % (1000 * 60)) / 1000
      );

      // Output the result in the timeVal variable
      parentThis.timeVal =
        (minutes + "").padStart(2, "0") + ":" + (seconds + "").padStart(2, "0");

      parentThis.totalMilliseconds += 100;
    }, 100);
  }

  /**
   * Stops the recording timer
   *
   * @param {*} parentThis
   */
  stopTimer(parentThis) {
    parentThis.timeVal = "00:00";
    parentThis.totalMilliseconds = 0;
    clearInterval(parentThis.timeIntervalInstance);
  }

  /**
   * Show a message to the user
   *
   * @param {*} text the text to show in the popup
   * @param {*} type the type of message (warning, success, error)
   */
  showMessage(text, type) {
    const event = new ShowToastEvent({
      title: "Call Recording",
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
}
