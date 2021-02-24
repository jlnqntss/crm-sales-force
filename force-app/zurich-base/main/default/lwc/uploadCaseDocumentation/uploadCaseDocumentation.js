import { LightningElement, api, track, wire } from "lwc";
import saveFile from "@salesforce/apex/UploadCaseDocumentationController.saveFile";
import getCase from "@salesforce/apex/UploadCaseDocumentationController.getCase";
import ZURICH_LOGO from "@salesforce/resourceUrl/zurich_ze_logo";
export default class FileUploadExample extends LightningElement {
  zurichLogoUrl = ZURICH_LOGO;
  @api hash;
  @track myRecordId;
  @track disableFileInput;
  @track currentCase;
  @track caseError;
  @track isLoading;
  @track showCase;
  @track caseStatusStyle = "slds-theme_success";

  @track messageContent;

  connectedCallback() {
    var that = this;
    this.isLoading = true;
    this.showCase = false;
    this.myRecordId = this.hash;
    console.log("this.myRecordId: " + this.myRecordId);
    getCase({
      hashId: this.myRecordId
    })
      .then(function (caseResult) {
        console.log(caseResult);
        that.showCase = true;
        that.isLoading = false;
        that.currentCase = caseResult;

        if (caseResult.Status == "Cerrado") {
          that.caseStatusStyle = "slds-theme_error";
          that.disableFileInput = true;
          that.messageContent = {
            class: "slds-theme_warning",
            icon: "utility:warning",
            title: "Warning",
            message: "No se puede adjuntar documentación en un caso cerrado."
          };
        }
      })
      .catch(function (err) {
        console.log(err);

        that.isLoading = false;
        that.disableFileInput = true;

        that.error = err;
        that.messageContent = {
          class: "slds-theme_error",
          icon: "utility:error",
          title: "Error",
          message: "Ha habido un problema al cargar el caso."
        };
      });
  }

  get acceptedFormats() {
    return [".pdf", ".png"];
  }

  handleFilesChange(event) {
    this.isLoading = true;
    var that = this;
    console.log("handleUploadFinished");
    // Get the list of uploaded files
    const uploadedFiles = event.detail.files;
    var currentCaseId = this.currentCase.Id;

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
            that.isLoading = false;

            that.messageContent = {
              class: "slds-theme_success",
              icon: "utility:success",
              title: "Success",
              message: "Documentación adjuntada correctamente."
            };

            setTimeout(function () {
              that.messageContent = undefined;
            }, 6000);

            // Get the snackbar DIV
            /*var divblock = that.template.querySelector('[data-id="snackbar"]');
            if (divblock) {
              divblock.className = "show";
              setTimeout(function () {
                divblock.className = "notshow";
              }, 3000);
            }*/
          })
          .catch(function (err) {
            console.log(err);
            that.isLoading = false;
          });
      })
      .catch(function (err) {
        console.log(err);
        that.isLoading = false;
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

  get toastClassName() {
    if (this.messageContent != null) {
      if (this.messageContent.class.indexOf("success") > -1) {
        return "show";
      } else {
        return "";
      }
    } else {
      return "notshow";
    }
    //return this.messageContent != null ? 'show': 'notshow';
  }
}
