import { api, LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import genesysCloud from "c/genesysCloudService";

// #region Etiquetas personalizadas
import startRecording from "@salesforce/label/c.callRecordingButtonStart";
import stopRecording from "@salesforce/label/c.callRecordingButtonStop";
import errorTitle from "@salesforce/label/c.Error";
import recordingException from "@salesforce/label/c.callRecordingButtonError";
import callRecordingAuthError from "@salesforce/label/c.callRecordingButtonAuthError";
// #endregion

export default class CallRecordingButton extends LightningElement {
  CALL_TAB_NAME = "call";
  SURVEY_BUTTON_NAME = "survey";

  /**
   * Etiquetas personalizadas donde se encuentran los mensajes mostrados en la interfaz de usuario.
   *
   * @author rpolvera
   * @type {Object}
   */
  labels = {
    errorTitle,
    recordingException,
    startRecording,
    stopRecording,
    callRecordingAuthError
  };

  /**
   * Controla el comportamiento del botón de grabación contractual.
   * En caso de
   */
  isActive;

  /**
   * Gestiona el mensaje que el CTI publica cuando se realiza una interacción con GenesysCloud.
   * @type {Object}
   */
  ctiMessageHandler = null;

  /**
   * Controla el estado de la llamada (interacción) con GenesysCloud.
   * @type {Boolean} Verdadero cuando se está en una llamada en curso. Falso si es lo contrario.
   */
  isOnCall;

  /**
   * Metodo del ciclo de vida de los componentes LWC que es ejecutado antes de renderizarse el componente en el DOM.
   * @date 26/10/2021
   */
  async connectedCallback() {
    this.ctiMessageHandler = this.handleCTIMessage.bind(this);
    genesysCloud.addListener(this.ctiMessageHandler);

    // Para los casos en los que se refresca la ventana o se desacopla el panel
    this.isOnCall = await genesysCloud.isConnected();
    this.checkRecording();
  }

  /**
   * Metodo del ciclo de vida de los componentes LWC que es ejecutado tras eliminar el componente del DOM.
   * @date 26/10/2021
   */
  disconnectedCallback() {
    genesysCloud.removeListener(this.ctiMessageHandler);
    this.ctiMessageHandler = null;
  }

  async handleClick() {
    // Si el usuario no está autorizado será redireccionado.
    if (!(await this.isAuthorized())) {
      this.showMessage(
        this.labels.errorTitle,
        this.labels.callRecordingAuthError,
        "warning"
      );
      this.authorize();
    } else {
      this.isActive = !this.isActive;

      if (this.isActive) {
        //Acción: Se ha iniciado la grabación.
        await this.startRecording();
      } else {
        //Acción: Se detiene la grabación.
        await this.stopRecording();
      }
    }
  }

  /**
   * Inicia la grabación contractual de la conversación actual.
   *
   * @date 26/10/2021
   * @author rpolvera
   */
  async startRecording() {
    try {
      // Se bloquea el botón de denvío de dencuestas.
      this.disableOthers(this.SURVEY_BUTTON_NAME, true);

      // 1. Se recupera el identificador de la llamada activa actual
      let activeCalls = await genesysCloud.getActiveCalls();
      let conversationId = activeCalls[0].id;
      await genesysCloud.startRecording(conversationId);
    } catch (error) {
      console.log("Exception: CallRecordingButton.startRecording()", error);
      this.isActive = false;
      // Se bloquea el botón de denvío de dencuestas.
      this.disableOthers(this.SURVEY_BUTTON_NAME, false);
      if (error !== undefined && error.body !== undefined) {
        let errorMessage = error.body.message;
        if (
          errorMessage !== undefined &&
          errorMessage.includes("401: Unauthorized")
        ) {
          this.authorize();
        }
      } else {
        this.showMessage(
          this.labels.errorTitle,
          this.labels.recordingException,
          "error"
        );
      }
    }
  }

  /**
   * Finaliza la grabación contractual de la conversación actual.
   *
   * @date 26/10/2021
   * @author rpolvera
   */
  async stopRecording() {
    try {
      // 1. Se recupera el identificador de la llamada activa actual
      let activeConversationId = (await genesysCloud.getActiveCalls())[0].id;
      await genesysCloud.stopRecording(activeConversationId);

      // Se desbloquea el botón de denvío de dencuestas.
      this.disableOthers(this.SURVEY_BUTTON_NAME, false);
    } catch (error) {
      console.log("Exception: CallRecordingButton.stopRecording()", error);
      this.isActive = true;
      this.showMessage(
        this.labels.errorTitle,
        this.labels.recordingException,
        "error"
      );
    }
  }

  /**
   * Se comprueba si el usuario actual se ha autorizado en el sistema externo utilizando sus credenciales con nombre.
   * Esta configuración se encuentra a nivel de usuario.
   * Es necesaria este tipo de autorización para consumir las APIs de Conversaciones de GenesysCloud ya que se efectuan en contexto de usuario.
   *
   * @date 02/11/2021
   * @author rpolvera
   * @returns Verdadero si está autorizado, falso si no está autorizado.
   */
  async isAuthorized() {
    try {
      return await genesysCloud.isAuthorized();
    } catch (error) {
      console.log("Exception: CallRecordingButton.isAuthorized()", error);
      this.showMessage(
        this.labels.errorTitle,
        this.labels.recordingException,
        "error"
      );
      return false;
    }
  }

  /**
   * Se redirecciona al usaurio a la pantalla de autorización con GenesysCloud.
   *
   * @date 02/11/2021
   * @author rpolvera
   */
  async authorize() {
    try {
      await genesysCloud.authorize();
    } catch (error) {
      console.log("Exception: CallRecordingButton.authorize()", error);
      this.showMessage(
        this.labels.errorTitle,
        this.labels.recordingException,
        "error"
      );
    }
  }

  /**
   * Actualiza la variable listener del estado de la llamada.
   *
   * @author jmartinezpisson
   * @param {Object} message
   */
  async handleCTIMessage(message) {
    if (message.type === "Interaction") {
      this.isOnCall = await genesysCloud.isConnected();
      this.checkRecording();
    }
  }

  /**
   * Metodo que comprueba si el participante de grabacion esta aun en la conversacion
   *
   * @date 04/01/2022
   * @author nts (agonzalezisasi)
   * @returns Si aun esta grabando (true) o no (false)
   */
  async checkRecording() {
    if (this.isOnCall) {
      this.isActive = await genesysCloud.isRecording();
    }

    // Se bloquea/desbloquea el botón de denvío de encuestas segun este activa la grabacion o no
    this.disableOthers(this.SURVEY_BUTTON_NAME, this.isActive);
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
    this.isActive = await genesysCloud.isRecording(activeCalls);
  }

  /**
   * Redirecciona al usuario a la pestaña de la barra de utilidad indicada como parámetro.
   * @param {String} tabName Nombre del icono del la barra de utilidad que se desaea abrir.
   */
  utilityBarRedirect(tabName) {
    const navigateToCall = new CustomEvent("redirect", {
      bubbles: true,
      composed: true,
      detail: {
        utilityBarIcon: tabName
      }
    });
    this.dispatchEvent(navigateToCall);
  }

  /**
   * Muestra una notoificación en forma de mensaje emergente en la interfaz de usuario.
   *
   * @param {String} title Título del error presentado.
   * @param {String} text Mensaje a mostrar.
   * @param {String} variant Variación del aspecto de la alerta, los posibles valores son: (warning, success, error)
   */
  showMessage(title, text, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: text,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  /**
   * Gestiona el comportamiento de otros botones, este evento notifica si otro botón debe ser bloqueado o desbloqueado.
   * @param buttonName Nombre del botón controlado, disponibles: survey
   * @param isDisabled Indica si el botón será deshabilidato o no. posibles valores: true o false.
   * @author rpolvera
   * @date 02/11/2021
   */
  disableOthers(buttonName, isDisabled) {
    const event = new CustomEvent("disablebuttons", {
      detail: {
        name: buttonName,
        disabled: isDisabled
      }
    });
    this.dispatchEvent(event);
  }

  // #region Getters y Setters
  /**
   * Controla el estado del botón de grabación contractual.
   * Siempre que el botón se encuentre deshabilitado significará que el botón de grabación no está activo.
   * @author rpolvera
   * @date 26/10/2021
   * @return verdadero (Deshabilitado) cuando no se ha configurado AdminSetupParameter__mdt - GenesysRecordingNumber
   *         o en caso de no existir una llamada en curso, de lo contrario falo (Habilitado).
   */
  get isDisabled() {
    return !this.isOnCall;
  }

  /**
   * Controla el texto del botón de grabación contractual.
   * @author rpolvera
   * @date 26/10/2021
   * @return Si el botón no está activo (grabando) entonces mostrará el mensaje para iniciar grabación
   *         por el contrario mostrará el mensaje para detener la grabación
   */
  get label() {
    return !this.isActive
      ? this.labels.startRecording
      : this.labels.stopRecording;
  }

  /**
   * Controla el aspecto del botón de grabación modificando su tema entre brand y destructive.
   * @author rpolvera
   * @date 26/10/2021
   * @return Muestra un aspecto neutral (Brand) para el botón inactivo y un aspecto (Destructive) para el botón cuando está activo.
   *         Esto permite gestionar el estado del botón.
   */
  get variant() {
    return !this.isActive
      ? "slds-button slds-button_brand fixedSize"
      : "slds-button slds-button_destructive fixedSize";
  }

  /**
   * Controla el icono mostrado en el botón de grabación.
   * @author rpolvera
   * @date 26/10/2021
   * @return Si el botón se encuentra activo (grabando) entonces mostrará el icono de stop, en caso contrario mostrará el botón
   *         para iniciar la grabación.
   */
  get icon() {
    return !this.isActive ? "utility:record" : "utility:stop";
  }

  get customClass() {
    return "";
  }
  // #endregion
}
