import { LightningElement, track } from "lwc";
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
    this.isLoading = true;
    this.showCase = false;
    getCase({
      hashId: this.hash
    })
      .then((caseResult) => {
        console.log(caseResult);
        this.showCase = true;
        this.isLoading = false;
        this.currentCase = caseResult;

        if (caseResult.Status === "Cerrado") {
          this.disableFileInput = true;

          const event = new ShowToastEvent({
            message: this.labels.errorDocumentacionCasoCerrado,
            variant: "warning",
            mode: "sticky"
          });
          this.dispatchEvent(event);
        }
      })
      .catch(() => {
        this.isLoading = false;
        this.disableFileInput = true;

        const event = new ShowToastEvent({
          message: this.labels.errorCargandoCaso,
          variant: "error",
          mode: "sticky"
        });
        this.dispatchEvent(event);
      });
  }

  getUrlParamValue(url, key) {
    return new URL(url).searchParams.get(key);
  }

  handleFilesChangeStandard() {
    //Mostrar otra notificación de confirmación?
  }
}
