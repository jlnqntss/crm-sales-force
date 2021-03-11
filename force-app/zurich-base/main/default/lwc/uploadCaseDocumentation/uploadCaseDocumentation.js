import { LightningElement, api, track } from "lwc";
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
import adjuntaDocumento from "@salesforce/label/c.adjuntaDocumento";
import proteccionDatosTitle from "@salesforce/label/c.proteccionDatosTitle";
import proteccionDatosValue from "@salesforce/label/c.proteccionDatosValue";
import avisoLegalTitle from "@salesforce/label/c.avisoLegalTitle";
import avisoLegalValue from "@salesforce/label/c.avisoLegalValue";
import accesibilidadTitle from "@salesforce/label/c.accesibilidadTitle";
import accesibilidadValue from "@salesforce/label/c.accesibilidadValue";
import zurichSegurosDerechosReservados from "@salesforce/label/c.zurichSegurosDerechosReservados";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class UploadCaseDocumentation extends LightningElement {
  labels = {
    solicitudDocumentacionCaso,
    fechaCreacionCaso,
    estadoActualCaso,
    tamanoMaximoSubidaDocumentacion,
    errorDocumentacionCasoCerrado,
    errorCargandoCaso,
    documentacionAdjuntadaCorrectamente,
    errorSubiendoDocumentacion,
    adjuntaDocumento,
    proteccionDatosTitle,
    proteccionDatosValue,
    avisoLegalTitle,
    avisoLegalValue,
    accesibilidadTitle,
    accesibilidadValue,
    zurichSegurosDerechosReservados
  };

  zurichLogoUrl = ZURICH_LOGO;
  @track hash;
  @track disableFileInput;
  @track currentCase;
  @track isLoading;
  @track showCase;

  connectedCallback() {
    const param = "Hash";
    this.hash = this.getUrlParamValue(window.location.href, param);
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

        if (caseResult.Status === "Cerrado") {
          that.disableFileInput = true;

          const event = new ShowToastEvent({
            message: that.labels.errorDocumentacionCasoCerrado,
            variant: "warning",
            mode: "sticky"
          });
          that.dispatchEvent(event);
        }
      })
      .catch(function (err) {
        that.isLoading = false;
        that.disableFileInput = true;

        //that.showToast(that, that.labels.errorCargandoCaso, "error", false);
        const event = new ShowToastEvent({
          message: that.labels.errorCargandoCaso,
          variant: "error",
          mode: "sticky"
        });
        that.dispatchEvent(event);
      });
  }

  getUrlParamValue(url, key) {
    return new URL(url).searchParams.get(key);
  }

  handleFilesChangeStandard() {
    //Mostrar otra notificación de confirmación?
  }
}
