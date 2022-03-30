import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import sendSurveyLabel from "@salesforce/label/c.sendSurveyButtonLabel";
import sendSurveyToastTitleSuccess from "@salesforce/label/c.sendSurveyToastTitleSuccess";
import sendSurveyToastMessageSuccess from "@salesforce/label/c.sendSurveyToastMessageSuccess";
import sendSurveyToastTitleError from "@salesforce/label/c.sendSurveyToastTitleError";
import sendSurveyToastMessageError from "@salesforce/label/c.sendSurveyToastMessageError";
import sendErrorInteractionTypeTitle from "@salesforce/label/c.sendSurveyShowToastEvent";
import sendErrorInteractionTypeMessage from "@salesforce/label/c.sendSurveyShowToastEventMessage";

import genesysCloud from "c/genesysCloudService";
import getPollPhoneNumber from "@salesforce/apex/SendSurveyButtonController.getTransferPollPhoneNumber";

 // jgarciamartinez - 29/03/2022
import getGenesysCloudQueues from "@salesforce/apex/SendSurveyButtonController.getGenesysCloudQueues";
export default class SendSurveyButton extends LightningElement {
  // #region Propiedades y atributos internos
  label = {
    sendSurveyLabel,
    sendSurveyToastTitleSuccess,
    sendSurveyToastMessageSuccess,
    sendSurveyToastTitleError,
    sendSurveyToastMessageError,
    sendErrorInteractionTypeTitle,
    sendErrorInteractionTypeMessage
  };

  @track
  pollPhoneNumber;

  @track
  isOnCall = false;

  // arcortazar - 24/02/22
  hasBeenTranfered = false;
  isEmail = false;
  transferedID;

  // jgarciamartinez - 28/03/2022
  @wire(getGenesysCloudQueues) getQueueList;
  isSurveyable = false;

  /**
   * Variable interna para poder realizar un bind del handler handleCTIMessage
   */
  ctiMessageHandler = null;

  /**
   * 
   * @author jgarciamartinez@nts-solutions.com
   * @date 29/03/2022
   * @param (name) - nombre de la cola que he
   * @return 
   */
  colaEsEncuestable(name) {
    for (const element of this.getQueueList.data) 
    {
      if (name === element.Name && element.IsSurveyable__c === true)
      {
        this.isSurveyable = true;
        break;
      }
      else
      {
        this.isSurveyable = false;
      }
    }
  }

  get isDisabled() {
    return !this.pollPhoneNumber || !this.isOnCall || !this.isSurveyable ;
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

    if (!this.isEmail) {
      if (
        genesysCloud.getState().currentInteractionId !== null &&
        genesysCloud.getState().currentInteractionId !== undefined &&
        this.pollPhoneNumber !== undefined &&
        this.pollPhoneNumber !== null
      ) {
        // Guardamos el ID De la interaction que se está transfiriendo
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
        const eventError = new ShowToastEvent({
          title: this.label.sendSurveyToastTitleError,
          message: this.label.sendSurveyToastMessageError,
          variant: "error"
        });
        this.dispatchEvent(eventError);
      }
    } else {
      const eventError = new ShowToastEvent({
        title: this.label.sendErrorInteractionTypeTitle,
        message: this.label.sendErrorInteractionTypeMessage,
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
    if (message.data.queueName !== undefined && message.data.queueName !== '')
    {
      this.colaEsEncuestable(message.data.queueName);
    }

    if (message.type === "Interaction" && !message.data.isEmail) {

      if (message.category === "connect" && !this.isEmail) {
        this.isOnCall = genesysCloud.isOnCall(); // arcortazar (nts) - 17/03/2022: Hacemos que el botón se habilite al iniciar la interacción, siempre y cuando no sea un email
      } else if (message.category === 'change' && message.isConnected === true) {
        this.colaEsEncuestable(message.data.new.queueName);
        this.isOnCall = genesysCloud.isOnCall();

      } else if (message.category === "disconnect") {
        if (this.transferedID === genesysCloud.getState().currentInteractionId && this.hasBeenTranfered) 
        {
          // Inicializamos los campos de comprobación
          this.hasBeenTranfered = false;
          this.transferedID = "";

          // Lanzamos el toast
          const event = new ShowToastEvent({
            title: this.label.sendSurveyToastTitleSuccess,
            message: this.label.sendSurveyToastMessageSuccess,
            variant: "success"
          });
          this.dispatchEvent(event);
        }

        this.isOnCall = false; // arcortazar (nts) - 17/03/2022: Hacemos que el botón se deshabilite al terminar la interacción
      }
    }
  }

  //#endregion
}
