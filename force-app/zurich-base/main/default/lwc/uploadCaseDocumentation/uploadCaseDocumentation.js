import { LightningElement, api, track, wire } from "lwc";
import saveFile from "@salesforce/apex/UploadCaseDocumentationController.saveFile";
import getCase from "@salesforce/apex/UploadCaseDocumentationController.getCase";
import ZURICH_LOGO from "@salesforce/resourceUrl/zurich_ze_logo";
import solicitudDocumentacionCaso from "@salesforce/label/c.solicitudDocumentacionCaso";
import fechaCreacionCaso from "@salesforce/label/c.fechaCreacionCaso";
import estadoActualCaso from "@salesforce/label/c.estadoActualCaso";
import tamanoMaximoSubidaDocumentacion from "@salesforce/label/c.tamanoMaximoSubidaDocumentacion";
import errorDocumentacionCasoCerrado from "@salesforce/label/c.errorDocumentacionCasoCerrado";
import errorCargandoCaso from "@salesforce/label/c.errorCargandoCaso";
import documentacionAdjuntadaCorrectamente from "@salesforce/label/c.documentacionAdjuntadaCorrectamente";
import errorSubiendoDocumentacion from "@salesforce/label/c.errorSubiendoDocumentacion";

export default class UploadCaseDocumentation extends LightningElement {
  labels = {
    solicitudDocumentacionCaso,
    fechaCreacionCaso,
    estadoActualCaso,
    tamanoMaximoSubidaDocumentacion,
    errorDocumentacionCasoCerrado,
    errorCargandoCaso,
    documentacionAdjuntadaCorrectamente,
    errorSubiendoDocumentacion
  };

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
            that.labels.errorDocumentacionCasoCerrado,
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
        that.showToast(that, that.labels.errorCargandoCaso, "error", false);
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
        that.labels.tamanoMaximoSubidaDocumentacion,
        "error",
        true
      );
      //TODO: Publicar un error event con el problema
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
                that.labels.documentacionAdjuntadaCorrectamente,
                "success",
                true
              );
            })
            .catch(function (err) {
              console.log(err);
              that.isLoading = false;

              that.showToast(
                that,
                that.labels.errorSubiendoDocumentacion,
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
