import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import { refreshApex } from "@salesforce/apex";
import PERSON_CONTACT_ID from "@salesforce/schema/Account.PersonContactId";
import CONTACT_REQUEST_ID from "@salesforce/schema/ContactRequest.Id";
import CONTACT_REQUEST_STATUS from "@salesforce/schema/ContactRequest.Status";

import getContactRequestsByCustomerId from "@salesforce/apex/CallMeBackListController.getContactRequestsByCustomerId";
// import statusToCancelled from "@salesforce/apex/CallMeBackListController.statusToCancelled";
import genesysCloud from "c/genesysCloudService";

const ERROR_TITLE = "Error";
const ERROR_VARIANT = "error";
const NO_RECORDS_FOUND = "No se han encontrado Contact Request.";
export default class CallMeBackList extends LightningElement {
  /**
   * Identificador del registro donde se ha cargado este componente.
   * @see callMeBackList.js-meta.xml
   * @type {String}
   */
  @api recordId;
  /**
   * Definición con las columnas a mostrar en el componente de tabla.
   */
  @api columns;

  callMeBacks;
  error;
  isLoading = false;

  // Consulta de contact person Id
  @wire(getRecord, { recordId: "$recordId", fields: [PERSON_CONTACT_ID] })
  getAccount({ error, data }) {
    if (data) {
      console.log(
        "🚀 ~ file: callMeBackList.js ~ line 36 ~ CallMeBackList ~ getAccount ~ data.fields.personContactId",
        data.fields.PersonContactId.value
      );
      this.isLoading = true;
      getContactRequestsByCustomerId({
        whoId: data.fields.PersonContactId.value
      }).then(this.resolve.bind(this), this.reject.bind(this));
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.callMeBacks = undefined;
      this.isLoading = true;
    }
  }

  /**
   * Método ejecutado cuando el método getContactRequestsByCustomerId() retorna un los datos.
   * @author rpolvera@nts-solutions.com
   * @date 18/11/2021
   * @param {Object} data Lista de Contact Request.
   */
  resolve(data) {
    this.callMeBacks = [];
    data.forEach((element) => {
      let callMeBack = Object.assign({}, element);
      callMeBack.url = window.location.hostname + "/" + callMeBack.Id;
      this.callMeBacks.push(callMeBack);
    });
    this.isLoading = false;
  }

  /**
   * Método ejecutado cuando el método getContactRequestsByCustomerId() retorna un error, muestra una alerta.
   * @author rpolvera@nts-solutions.com
   * @date 18/11/2021
   * @param {String} error error.
   */
  reject(error) {
    this.isLoading = false;
    this.showMessage(ERROR_TITLE, NO_RECORDS_FOUND, ERROR_VARIANT);
    console.error(error.body.message);
  }

  /**
   * Maneja el evento que ocurre al pulsar en el botón de cada fila de la tabla, y se encarga de recoger el InteractionId del
   * contactRequest y lo plasma dentro de un Toast
   **
   * @author jjuaristi
   * @date 28/10/2021
   */
  async handleRowAction(event) {
    const row = event.detail.row;

    // Si el usuario no está autorizado será redireccionado.
    if (!(await this.isAuthorized())) {
      this.showMessage(
        this.labels.errorTitle,
        this.labels.callRecordingAuthError,
        "warning"
      );
      this.authorize();
    } else {
      const fields = {};
      fields[CONTACT_REQUEST_ID.fieldApiName] = row.Id;
      fields[CONTACT_REQUEST_STATUS.fieldApiName] = "Cancelled";
      const recordInput = { fields };
      updateRecord(recordInput)
        .then((result) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Contact updated",
              variant: "success"
            })
          );
          // otra función
          this.callMeBacks = this.callMeBacks.filter(
            (element) => element.Id !== row.Id
          );
          console.log(result);
          genesysCloud.cancelCallBack(row.GenesysInteractionId__c, result);
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error creating record",
              message: error.body.message,
              variant: "error"
            })
          );
        });
    }
    // Display fresh data in the form
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
   * Comprueba si existen registros de Contact Request cargados en el componente.
   * @author rpolvera@nts-solutions.com
   * @date 17/11/2021
   * @return verdadero si no hay registros cargados, falso de lo contrario.
   */
  get isEmpty() {
    return this.callMeBacks && this.callMeBacks.length === 0;
  }

  /**
   * Parseo de la definición de columnas.
   * @author rpolvera@nts-solutions.com
   * @date 17/11/2021
   * @return JSON de deficnión de columnas para el componente data-table.
   */
  get columnsDefinition() {
    return JSON.parse(this.columns);
  }
}
