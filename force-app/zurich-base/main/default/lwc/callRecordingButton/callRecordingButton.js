import { LightningElement, track } from "lwc";
import callRecordingStart from "@salesforce/label/c.callRecordingButtonStart";
import callRecordingStop from "@salesforce/label/c.callRecordingButtonStop";

export default class CallRecordingButton extends LightningElement {
  label = {
    callRecordingStart,
    callRecordingStop
  };

  isSelected = false;
  @track timeVal = "00:00";
  timeIntervalInstance;
  totalMilliseconds = 0;

  handleClick() {
    var parentThis = this;
    this.isSelected = !this.isSelected;
    this.template.querySelector(`[data-id="record-button"]`).blur();

    if (this.isSelected) {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      this.timeIntervalInstance = setInterval(function () {
        // Time calculations for hours, minutes, seconds and milliseconds
        var minutes = Math.floor(
          (parentThis.totalMilliseconds % (1000 * 60 * 60)) / (1000 * 60)
        );
        var seconds = Math.floor(
          (parentThis.totalMilliseconds % (1000 * 60)) / 1000
        );

        // Output the result in the timeVal variable
        parentThis.timeVal =
          (minutes + "").padStart(2, "0") +
          ":" +
          (seconds + "").padStart(2, "0");

        parentThis.totalMilliseconds += 100;
      }, 100);
    } else {
      this.timeVal = "00:00";
      this.totalMilliseconds = 0;
      clearInterval(this.timeIntervalInstance);
    }
  }
}
