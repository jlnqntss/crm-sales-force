import { LightningElement } from "lwc";
import extraButtonsTitle from "@salesforce/label/c.CTIExtraButtonsTitle";
import extraButtonsWarning from "@salesforce/label/c.CTIExtraButtonsWarning";
import extraButtonsAuthButton from "@salesforce/label/c.CTIExtraButtonsAuthButton";
import genesysCloud from "c/genesysCloudService";

export default class CTIExtraButtons extends LightningElement {
  label = {
    extraButtonsTitle,
    extraButtonsWarning,
    extraButtonsAuthButton
  };

  isUserAuthorized = false;

  activeCalls = null;

  /**
   * Controla el estado del botón de envío de encuesta.
   *
   * @author rpolvera
   * @date 02/11/2021
   * @param {CustomEvent} event detalle del evento y su información.
   */
  handleDisableButtons(event) {
    let buttonName = event.detail.name;
    let isDidabled = event.detail.disabled;

    if (buttonName === "survey") {
      this.template.querySelector("c-send-survey-button").disable(isDidabled);
    }
  }

  async connectedCallback() {
    this.isAuthorized();
  }

  /**
   * Comprueba si el agente esta autorizado, es decir que tiene dado de alta el named
   * credential y si ademas ese named credential tiene permisos de acceso a las llamadas.
   *
   * @date 12/01/2022
   * @author nts (agonzalezisasi)
   */
  async isAuthorized() {
    try {
      // Comprobamos si tiene el named credential creado
      this.isUserAuthorized = await genesysCloud.isAuthorized();
      // Comprobamos si con el named credential existente tiene permisos para recuperar informacion
      if (this.isUserAuthorized) {
        // Si no tiene permisos generara una excepcion, si lo esta nos da las llamadas activas
        this.activeCalls = await genesysCloud.getActiveCalls();
      }
    } catch (error) {
      console.log("Exception: cTIExtraButtons.isAuthorized()", error);
      this.isUserAuthorized = false;
      this.activeCalls = null;
    }
  }

  /**
   * Evento del boton de refrescar por si hubiera algun problema con los botones.
   * Comprueba si el agente esta autorizado y luego si tiene que refrescar los botones
   * de grabacion y envio a encuesta
   *
   * @date 12/01/2022
   * @author nts (agonzalezisasi)
   */
  async handleRefresh() {
    await this.isAuthorized();
    this.template
      .querySelector("c-call-recording-button")
      .refresh(this.activeCalls);
    this.template
      .querySelector("c-send-survey-button")
      .refresh(this.activeCalls);
  }

  /**
   * Evento del boton de ir al named credential del agente para autorizar el acceso
   * a genesys
   *
   * @date 11/01/2022
   * @author nts (agonzalezisasi)
   */
  async handleClick() {
    try {
      await genesysCloud.authorize();
    } catch (error) {
      console.log("Exception: cTIExtraButtons.authorize()", error);
      this.showMessage(
        this.labels.errorTitle,
        this.labels.recordingException,
        "error"
      );
    }
  }
}
