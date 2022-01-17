/**
 * Librería auxiliar para facilitar el uso del API de Genesys Cloud en componentes LWC
 * Utiliza el API del Emebedded Framework, y hace un fallback a métodos Apex para aquellas
 * acciones de Genesys no soportadas por este último.
 *
 * La librería se comporta como un servicio Singleton que comparte la conexión a Genesys Cloud.
 *
 * @author jmartinezpisson
 */
import {
  APPLICATION_SCOPE,
  createMessageContext,
  publish,
  subscribe
} from "lightning/messageService";
import genesysCloudChannel from "@salesforce/messageChannel/purecloud__ClientEvent__c";
import conferenceTo from "@salesforce/apex/GenesysCloudLightningController.conferenceTo";
import isAuthorized from "@salesforce/apex/GenesysCloudLightningController.isAuthorized";
import authorize from "@salesforce/apex/GenesysCloudLightningController.authorize";
import getActiveCalls from "@salesforce/apex/GenesysCloudLightningController.getActiveCalls";
import startRecording from "@salesforce/apex/GenesysCloudLightningController.startRecording";
import stopRecording from "@salesforce/apex/GenesysCloudLightningController.stopRecording";
import cancelCallBack from "@salesforce/apex/GenesysCloudLightningController.cancelCallBack";
import getRecordingNumber from "@salesforce/apex/CallRecordingController.getRecordingPhoneNumber";

// #region Estado interno de la librería

/**
 * Contexto del Lightning Message Service
 */
const messageContext = createMessageContext();

const PARTICIPANT_PURPOSE_CLIENT = "customer";
const PARTICIPANT_PURPOSE_EXTERNAL = "external";
const PARTICIPANT_STATE_CONNECTED = "connected";
const PARTICIPANT_STATE_DIALING = "dialing";

/**
 * Estado interno. Variables y atributos requeridos por el funcionamiento de la librería
 *
 * @author jmartinezpisson
 */
const state = {
  logs: [],
  listeners: [],
  currentInteractionId: null,
  interactions: {}
};

//#endregion

//#region Inicialización

/**
 * Inicializa la suscripción al Embedded Framework de Genesys Cloud, y realiza el control de los listener
 * personalizados que permite añadir la libería. Controla el Id. de la interacción en curso.
 *
 * @author jmartinezpisson
 */
subscribe(
  messageContext,
  genesysCloudChannel,
  (message) => {
    state.logs.push(message);
    if (message.type === "Interaction" && message.data.id) {
      state.currentInteractionId = message.data.id;
      state.interactions[message.data.id] = Object.assign(
        state.interactions[message.data.id] || {},
        message.data
      );
    }

    if (state.listeners.length) {
      state.listeners.forEach((listener) => {
        try {
          listener(message);
        } catch (error) {
          console.error(message);
        }
      });
    }
  },
  { scope: APPLICATION_SCOPE }
);

//#endregion

//#region Métodos auxiliares

/**
 * Publica un mensaje a través del Embedded Framework
 * Ver https://help.mypurecloud.com/articles/events-in-salesforce/
 * @author jmartinezpisson
 * @param {*} payload Mensaje a publicar en el Embedded Framework
 */
function publishMessage(payload) {
  return publish(messageContext, genesysCloudChannel, payload);
}

//#endregion

// #Exports
export default {
  /**
   * Añade un listener para escuchar cambios producidos en la telefonía
   * Ver https://help.mypurecloud.com/articles/events-in-salesforce/
   *
   * @author jmartinezpisson
   * @param {*} listener Handler de gestión del mensaje
   * @return {List<*>}Lista de mensajes recibidos hasta el momento de la suscripción
   */
  addListener(listener) {
    state.listeners.push(listener);

    return state.logs;
  },
  /**
   * Eliminar un listener del API
   *
   * @author jmartinezpisson
   * @param {*} listenerToRemove Referencia al handler a eliminar
   */
  removeListener(listenerToRemove) {
    state.listeners = state.listeners.filter((listener) => {
      return listener !== listenerToRemove;
    });
  },

  /**
   * Transfiere a otro número utilizando el Embedded Framework
   *
   * @author jmartinezpisson
   * @param {String} phoneNumber Número de teléfono destino
   */
  transfer(phoneNumber) {
    return publishMessage({
      type: "PureCloud.Interaction.updateState",
      data: {
        action: "blindTransfer",
        id: state.currentInteractionId,
        participantContext: {
          transferTarget: encodeURIComponent(phoneNumber),
          transferTargetType: "address"
        }
      }
    });
  },
  /**
   * Consulta a otro número utilizando el Embedded Framework
   *
   * @author jmartinezpisson
   * @param {String} phoneNumber Número de teléfono destino
   */
  consult(phoneNumber) {
    return publishMessage({
      type: "PureCloud.Interaction.updateState",
      data: {
        action: "consultTransfer",
        id: state.currentInteractionId,
        participantContext: {
          transferTarget: encodeURIComponent(phoneNumber),
          transferTargetType: "address"
        }
      }
    });
  },

  /**
   * Conferencia a otro número enviando información asociada.
   * Requiere que el usuario actual se encuentre autorizado en la Named Credential
   * GenesysCloud
   *
   * @author jmartinezpisson
   * @param {String} phoneNumber Número de teléfono destino
   * @param {Object} attributesByName Mapa de clave-valor con la información a enviar.
   * @param {Boolean} fallbackToUUI Utiliza el UUI para enviar información (requiere que la operadora soporte UUI)
   * @return {Promise} Promesa resuelta con el resultado de la operación
   *
   */
  conference(phoneNumber, attributesByName, fallbackToUUI) {
    return conferenceTo({
      toAddress: phoneNumber,
      attributesByName: attributesByName,
      fallbackToUUI: fallbackToUUI
    });
  },
  /**
   * Determina si el usuario actual está al teléfono
   *
   * @author jmartinezpisson
   * @return {Boolean} Verdadero si la llamada actual está activa
   *
   */
  isOnCall() {
    let currentInteraction =
      state.interactions[state.currentInteractionId] || {};

    return currentInteraction.state !== "DISCONNECTED";
  },

  /**
   * Determina si el usuario actual está conectado
   *
   * @author nts (agonzalezisasi)
   * @return {Boolean} Verdadero si la llamada actual está conectada (true) o no (false)
   *
   */
  async isConnected() {
    let result = false;

    // Comprobamos si tenemos interaccion en el state
    if (state.currentInteractionId !== null) {
      let currentInteraction =
        state.interactions[state.currentInteractionId] || {};
      result = currentInteraction.state === "CONNECTED";
    } else {
      // Si no lo hay se debe muy probablemente a que el usuario a desacoplado el panel
      // Por ello lo vamos a buscar directamente en las llamadas activas del agente
      let activeCalls = await getActiveCalls();
      if (activeCalls !== undefined && activeCalls.length > 0) {
        result = true;
      }
    }

    return result;
  },

  /**
   * Inicia la grabación contractual si esta no había sido iniciada.
   * IMPORTANTE: Esta función utiliza el API Conversations/ de Genesys Cloud y por tanto se ejecuta bajo contexto de usuario.
   * Requiere que el usuario actual se encuentre autorizado en la Named Credential de GenesysCloud.
   * External Resources: https://developer.genesys.cloud/api/rest/v2/conversations/
   */
  startRecording(conversationId) {
    return startRecording({
      conversationId: conversationId
    });
  },

  /**
   * Finaliza la grabación contractual en curso.
   * IMPORTANTE: Esta función utiliza el API Conversations/ de Genesys Cloud y por tanto se ejecuta bajo contexto de usuario.
   * Requiere que el usuario actual se encuentre autorizado en la Named Credential de GenesysCloud.
   * External Resources: https://developer.genesys.cloud/api/rest/v2/conversations/
   */
  stopRecording(conversationId) {
    return stopRecording({
      conversationId: conversationId
    });
  },

  /**
   * Metodo asincrono oque comprueba si el agente tiene una llamada activa.
   *
   * @date 13/01/2022
   * @author nts (agonzalezisasi)
   */
  async isCallConnected(activeCalls) {
    // Si el parametro es nulo recuperamos las llamadas activas directamente
    if (activeCalls === null || activeCalls === undefined) {
      activeCalls = await this.getActiveCalls();
    }
    // Si el usuario no tiene vinculada ninguna llamada activa tampoco pordrá realizar la grabación.
    if (!activeCalls || !activeCalls[0]) {
      return false;
    }

    // Recuperamos el num de grabacion para descartarlo ya que aparece como cliente en el purpose
    let recordingNum = await getRecordingNumber();

    let isClientConnected = false;
    activeCalls[0].participants.forEach((participant) => {
      // Comprobamos tambien que hay un numero de cliente externo, esta conectado y no es el numero de grabacion
      if (
        (participant.purpose === PARTICIPANT_PURPOSE_CLIENT ||
          participant.purpose === PARTICIPANT_PURPOSE_EXTERNAL) &&
        participant.state === PARTICIPANT_STATE_CONNECTED &&
        !participant.address.includes(recordingNum)
      ) {
        isClientConnected = true;
      }
    });
    return isClientConnected;
  },

  /**
   * Comprueba si existe una grabación en curso.
   * External Resources: https://developer.genesys.cloud/api/rest/v2/conversations/
   * @returns Verdadero si el usaurio se encuentra en una llamada y con una grabación contractual en curso.
   */
  async isRecording(activeCalls) {
    // Si el parametro es nulo recuperamos las llamadas activas directamente
    if (activeCalls === null || activeCalls === undefined) {
      activeCalls = await this.getActiveCalls();
    }

    // Si el usuario no tiene vinculada ninguna llamada activa tampoco pordrá realizar la grabación.
    if (!activeCalls || !activeCalls[0]) {
      return false;
    }

    // Si los participantes no son mas de 2 (agente, cliente y grabacion)
    if (activeCalls[0].participants.length <= 2) {
      return false;
    }

    // Recuperamos el num de grabacion para identificarlo en la lista de participantes
    let recordingNum = await getRecordingNumber();

    // Miramos si el cliente y el participante de grabacion estan aun conectados
    let isRecorderConnected = false;
    let isClientConnected = false;
    activeCalls[0].participants.forEach((participant) => {
      // Comprobamos que hay un numero de cliente externo, esta conectado o en proceso de conectar (dialing) y que se corresponde con el numero de grabacion
      if (
        participant.purpose === PARTICIPANT_PURPOSE_CLIENT &&
        (participant.state === PARTICIPANT_STATE_CONNECTED ||
          participant.state === PARTICIPANT_STATE_DIALING) &&
        participant.address.includes(recordingNum)
      ) {
        // if( participant.purpose === PARTICIPANT_PURPOSE_IVR && (participant.state === PARTICIPANT_STATE_CONNECTED || participant.state === PARTICIPANT_STATE_DIALING) ) {
        isRecorderConnected = true;
      }
      // Comprobamos tambien que hay un numero de cliente externo, esta conectado y no es el numero de grabacion
      if (
        (participant.purpose === PARTICIPANT_PURPOSE_CLIENT ||
          participant.purpose === PARTICIPANT_PURPOSE_EXTERNAL) &&
        participant.state === PARTICIPANT_STATE_CONNECTED &&
        !participant.address.includes(recordingNum)
      ) {
        isClientConnected = true;
      }
    });

    return isRecorderConnected && isClientConnected;
  },

  /**
   * Devuelve las llamadas activas del usuario
   * Requiere que el usuario actual se encuentre autorizado en la Named Credential
   * GenesysCloud
   *
   * @author jmartinezpisson
   * @return {GenesysCloud.Calls[]} Listado de llamadas activas
   *
   */
  getActiveCalls() {
    return getActiveCalls();
  },

  /**
   * Determina si el usuario actual está autorizado en la Named Credential
   * GenesysCloud
   *
   * @author jmartinezpisson
   * @return {Boolean} Verdadero si el usuario actual está autorizado
   *
   */
  isAuthorized() {
    return isAuthorized();
  },

  /**
   * Inicia el proceso de autorización en la Named Credential
   * GenesysCloud
   *
   * @author jmartinezpisson
   */
  async authorize() {
    var authorizeURL = await authorize();

    window.open(authorizeURL);
  },

  /**
   * Cancela un CallBack de genesys
   * GenesysCloud
   *
   * @author jjuaristi
   */
  cancelCallBack(interactionID, ID) {
    return cancelCallBack({
      interactionID: interactionID,
      contactRequestId: ID
    });
  }
};

//#endregion
