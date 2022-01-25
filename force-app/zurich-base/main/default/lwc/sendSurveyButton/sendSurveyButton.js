import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendSurveyLabel from "@salesforce/label/c.sendSurveyButtonLabel";
import sendSurveyToastTitleSuccess from "@salesforce/label/c.sendSurveyToastTitleSuccess";
import sendSurveyToastMessageSuccess from "@salesforce/label/c.sendSurveyToastMessageSuccess";
import genesysCloud from "c/genesysCloudService";
import getPollPhoneNumber from "@salesforce/apex/SendSurveyButtonController.getTransferPollPhoneNumber";

export default class SendSurveyButton extends LightningElement {
  // #region Propiedades y atributos internos
  label = {
    sendSurveyLabel,
    sendSurveyToastTitleSuccess,
    sendSurveyToastMessageSuccess
  };

  @track
  pollPhoneNumber;

  @track
  isOnCall = false;

  @track
  isOtherButton = false;

  /**
   * Variable interna para poder realizar un bind del handler handleCTIMessage
   */
  ctiMessageHandler = null;

  get isDisabled() {
    return !this.pollPhoneNumber || !this.isOnCall || this.isOtherButton;
  }

  /**
   * Función pública para deshabilitar este botón.
   * @author rpolvera
   * @date 02/11/2021
   * @param {Boolean} value
   */
  @api
  disable(value) {
    this.isOtherButton = value;
  }

  //#endregion

  //#region Handlers del Ciclo de Vida LWC

  /**
   * Obtiene el número de teléfono a encuestar
   * Configura el API de Genesys Cloud para escuchar cambios en la telefonía
   *
   * @author rlopez
   * @modified jmartinezpisson
   */
  async connectedCallback() {
    getPollPhoneNumber().then((result) => {
      this.pollPhoneNumber = result || "1000";
    });

    this.ctiMessageHandler = this.handleCTIMessage.bind(this);
    genesysCloud.addListener(this.ctiMessageHandler);

    // Para los casos en los que se refresca la ventana o se desacopla el panel
    this.isOnCall = await genesysCloud.isConnected();
  }

  /**
   * Elimina el listener sobre el API de Genesys Cloud
   *
   * @author jmartinezpisson
   */
  disconnectedCallback() {
    genesysCloud.removeListener(this.ctiMessageHandler);
    this.ctiMessageHandler = null;
  }

  //#endregion

  //#region Métodos privados

  /**
   * Gestiona los mensajes CTI emitidos por el API JS GenesysCloudService
   * Con cada cambio sobre el estado de las llamadas, se verifica si el conector
   * tiene llamadas activas
   *
   * @author jmartinezpisson
   * @param {*} message Mensajes en el formato del Embedded Framework de Genesys
   */
  sendSurvey() {
    genesysCloud.transfer(this.pollPhoneNumber);
    const navigateToCall = new CustomEvent("redirect", {
      bubbles: true,
      composed: true,
      detail: {
        utilityBarIcon: "call"
      }
    });
    this.dispatchEvent(navigateToCall);
    const event = new ShowToastEvent({
      title: this.label.sendSurveyToastTitleSuccess,
      message: this.label.sendSurveyToastMessageSuccess,
      variant: "success"
    });
    this.dispatchEvent(event);
  }

  /**
   * Gestiona los mensajes CTI emitidos por el API JS GenesysCloudService
   * Con cada cambio sobre el estado de las llamadas, se verifica si el conector
   * tiene llamadas activas
   *
   * @author jmartinezpisson
   * @param {*} message Mensajes
   */
  async handleCTIMessage(message) {
    if (message.type === "Interaction") {
      this.isOnCall = await genesysCloud.isConnected();
    }
  }

  /**
   * Metodo que vuelve a comprobar el estado de la llamada y si ya esta en grabacion o no.
   * Es necesario para los casos en los que el agente por lo que sea refresca la ventana o
   * desacopla el panel
   *
   * @date 13/01/2022
   * @author nts (agonzalezisasi)
   */
  @api
  async refresh(activeCalls) {
    this.isOnCall = await genesysCloud.isCallConnected(activeCalls);
  }

  //#endregion
}
