import { LightningElement, track } from "lwc";
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

  // arcortazar - 24/02/22
  hasBeenTranfered = false;
  isEmail = false;
  transferedID;

  /**
   * Variable interna para poder realizar un bind del handler handleCTIMessage
   */
  ctiMessageHandler = null;

  get isDisabled() {
    return !this.pollPhoneNumber || !this.isOnCall;
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
  connectedCallback() {
    getPollPhoneNumber().then((result) => {
      this.pollPhoneNumber = result || "1000";
    });

    this.ctiMessageHandler = this.handleCTIMessage.bind(this);
    genesysCloud.addListener(this.ctiMessageHandler);
  }

  renderedCallback() {
    getPollPhoneNumber().then((result) => {
      this.pollPhoneNumber = result || "1000";
    });

    this.isOnCall = genesysCloud.isOnCall();
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
    // Aqui podríamos comprobar si tenemos el InteractionID

    console.log("MENSAJE SURVEY");
    if (!this.isEmail) {
      console.log("MENSAJE no es email");

      if (
        genesysCloud.getState().currentInteractionId !== null &&
        genesysCloud.getState().currentInteractionId !== undefined &&
        this.pollPhoneNumber !== undefined &&
        this.pollPhoneNumber !== null
      ) {
        console.log("MENSAJE transferimos");
        this.hasBeenTranfered = true;
        this.transferedID = genesysCloud.getState().currentInteractionId;

        genesysCloud.transfer(this.pollPhoneNumber);
        const navigateToCall = new CustomEvent("redirect", {
          bubbles: true,
          composed: true,
          detail: {
            utilityBarIcon: "call"
          }
        });
        this.dispatchEvent(navigateToCall);
      } else {
        console.log("MENSAJE algo falla");
        const eventError = new ShowToastEvent({
          title: "Error",
          message:
            "No se ha recuperado el identificador de la llamada, por favor, refresque la página o ancle esta ventana a la barra de tareas",
          variant: "error"
        });
        this.dispatchEvent(eventError);
      }
    } else {
      console.log("MENAJE es email");
      const eventError = new ShowToastEvent({
        title: "Error",
        message:
          "No puede redireccionarse una encuesta en este tipo de interaccion",
        variant: "error"
      });
      this.dispatchEvent(eventError);
    }
  }

  /**
   * Gestiona los mensajes CTI emitidos por el API JS GenesysCloudService
   * Con cada cambio sobre el estado de las llamadas, se verifica si el conector
   * tiene llamadas activas
   *
   * @author jmartinezpisson
   * @param {*} message Mensajes
   */
  handleCTIMessage(message) {
    if (message.type === "Interaction" && !message.data.isEmail) {
      this.isOnCall = genesysCloud.isOnCall();

      console.log(
        "MENSAJE " +
          message.category +
          "; Interactoin ID " +
          genesysCloud.getState().currentInteractionId
      );
      if (message.category === "blindTransfer") {
        console.log("MENSAJE blind transfer");
      } else if (message.category === "change" && this.hasBeenTranfered) {
        console.log("MENSAJE change + blindtransfer");
      } else if (message.category === "disconnect" && this.hasBeenTranfered) {
        if (
          this.transferedID === genesysCloud.getState().currentInteractionId
        ) {
          this.hasBeenTranfered = false;
          const event = new ShowToastEvent({
            title: this.label.sendSurveyToastTitleSuccess,
            message: this.label.sendSurveyToastMessageSuccess,
            variant: "success"
          });
          this.dispatchEvent(event);
        }
      }
    }
  }

  //#endregion
}
