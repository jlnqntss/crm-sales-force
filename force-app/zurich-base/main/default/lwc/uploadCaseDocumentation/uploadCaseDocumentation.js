import { LightningElement, api, track, wire } from "lwc";
import saveFile from "@salesforce/apex/UploadCaseDocumentationController.saveFile";
import getCase from "@salesforce/apex/UploadCaseDocumentationController.getCase";
import publishErrorEvent from "@salesforce/apex/UploadCaseDocumentationController.publishErrorEvent";
import ZURICH_LOGO from "@salesforce/resourceUrl/zurich_ze_logo";
export default class FileUploadExample extends LightningElement {
  zurichLogoUrl = ZURICH_LOGO;
  @api hash;
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
    getCase({
      hashId: this.hash
    })
      .then(function (caseResult) {
        console.log(caseResult);
        that.showCase = true;
        that.isLoading = false;
        that.currentCase = caseResult;

        if (caseResult.Status == "Cerrado") {
          that.caseStatusStyle = "slds-theme_error";
          that.disableFileInput = true;
          that.showToast(
            that,
            "No se puede adjuntar documentación en un caso cerrado.",
            "warning",
            false
          );
        }
      })
      .catch(function (err) {
        console.log(err);

        that.isLoading = false;
        that.disableFileInput = true;

        that.error = err;
        that.showToast(
          that,
          "Ha habido un problema al cargar el caso.",
          "error",
          false
        );
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

    if (uploadedFiles[0].size >= 4194304) {
      that.isLoading = false;
      that.showToast(
        that,
        "El archivo tiene un tamaño superior al máximo permitido",
        "error",
        true
      );
      //TODO: Publicar un error event con el problema
      console.log("Size: " + uploadedFiles[0].size);
      //publishErrorEvent('El archivo tiene un tamaño superior al máximo permitido. Bytes: ' + uploadedFiles[0].size, 'handleFilesChange', that.currentCase.Id);
    } else {
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
              that.showToast(
                that,
                "Documentación adjuntada correctamente.",
                "success",
                true
              );
            })
            .catch(function (err) {
              console.log(err);
              that.isLoading = false;

              that.showToast(
                that,
                "Ha habido un problema al subir el archivo",
                "error",
                true
              );
            });
        })
        .catch(function (err) {
          console.log(err);
          that.isLoading = false;
        });
    }
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

  showToast(context, message, type, transition) {
    context.messageContent = {
      class: "slds-theme_" + type,
      icon: "utility:" + type,
      title: type,
      message: message,
      transition: transition
    };
  }

  get toastClassName() {
    if (this.messageContent != null) {
      if (this.messageContent.transition) {
        var that = this;
        setTimeout(function () {
          that.messageContent = undefined;
        }, 6000);
      }
      return this.messageContent.transition ? "show" : "";
    } else {
      return "notshow";
    }
  }
}
