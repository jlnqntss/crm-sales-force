import { LightningElement, api, track } from "lwc";
import saveFile from "@salesforce/apex/UploadCaseDocumentationController.saveFile";
import getCase from "@salesforce/apex/UploadCaseDocumentationController.getCase";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class FileUploadExample extends LightningElement {
  @api hash;
  @track myRecordId;
  @track isCaseClosed;

  connectedCallback() {
    var that = this;
    this.myRecordId = this.hash;
    console.log("this.myRecordId: " + this.myRecordId);
    getCase({
      caseId: this.myRecordId
    })
      .then(function (caseResult) {
        console.log(caseResult);
        that.isCaseClosed = caseResult.Status == "Cerrado";
      })
      .catch(function (err) {
        console.error(err);
      });
  }

  get acceptedFormats() {
    return [".pdf", ".png"];
  }

  handleFilesChange(event) {
    var that = this;
    console.log("handleUploadFinished");
    // Get the list of uploaded files
    const uploadedFiles = event.detail.files;
    var currentCaseId = this.myRecordId;

    this.getBase64(uploadedFiles[0])
      .then(function (result) {
        console.log("result: " + result);
        saveFile({
          parentId: currentCaseId,
          fileName: uploadedFiles[0].name,
          base64Data: result
        })
          .then(function () {
            console.log("Success");
            // Get the snackbar DIV
            var divblock = that.template.querySelector('[data-id="snackbar"]');
            if (divblock) {
              divblock.className = "show";
              setTimeout(function () {
                divblock.className = "notshow";
              }, 3000);
            }
          })
          .catch(function (err) {
            console.log(err);
            that.showToast("Error en la subida del documento", err);
          });
      })
      .catch(function (err) {
        console.log(err);
        that.showToast("Error en la subida del documento 2", err);
      });
  }

  getBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.readAsDataURL(file);
      reader.onload = () => {
        let encoded = reader.result.toString().replace(/^data:(.*,)?/, "");
        if (encoded.length % 4 > 0) {
          encoded += "=".repeat(4 - (encoded.length % 4));
        }
        resolve(encoded);
      };
      reader.onerror = (error) => reject(error);
    });
  }

  showToast(title, message) {
    const event = new ShowToastEvent({
      title: title,
      message: message
    });
    this.dispatchEvent(event);
  }
}
