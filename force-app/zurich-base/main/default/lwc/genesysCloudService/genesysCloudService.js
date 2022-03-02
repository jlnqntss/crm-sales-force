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
import cancelCallBack from "@salesforce/apex/GenesysCloudLightningController.cancelCallBack";

// #region Estado interno de la librería

/**
 * Contexto del Lightning Message Service
 */
const messageContext = createMessageContext();

/**
 * Estado interno. Variables y atributos requeridos por el funcionamiento de la librería
 *
 * @author jmartinezpisson
 */
const state = {
  logs: [],
  listeners: [],
  currentInteractionId: null,
  interactions: {},
  isEmail: null
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
      state.isEmail = message.data.isEmail;
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
  setInteractionID(id) {
    state.currentInteractionId = id;
  },

  getState() {
    return state;
  },

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
