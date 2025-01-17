import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import PERSON_CONTACT_ID from "@salesforce/schema/Account.PersonContactId";
import PERSON_CONTACT_NAME from "@salesforce/schema/Account.Name";
import CONTACT_REQUEST_ID from "@salesforce/schema/ContactRequest.Id";
import CONTACT_REQUEST_STATUS from "@salesforce/schema/ContactRequest.Status";

import getContactRequestsByCustomerId from "@salesforce/apex/CallMeBackListController.getContactRequestsByCustomerId";
import genesysCloud from "c/genesysCloudService";

const ERROR_TITLE = "Error";
const SUCCESS_TITLE = "Cancelado";
const ERROR_VARIANT = "error";
const SUCCESS_VARIANT = "Success";
const NO_RECORDS_FOUND = "No se han encontrado Contact Request.";
const ERROR_CANCELED = "No es posible cancelar el Contact Request.";
const SUCCESS_CANCELED = "Contact Request cancelado con éxito";
const STATUS_CANCELLED = "Cancelled";

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
  fullListCallMeBacks; // arcortazar - 20/01/2022: Fix del componente CallMeBack. Lista de todos los CMB que se corresponden a una cuenta.
  error;
  isLoading = false;
  isLong = false; // arcortazar - 20/01/2022: Fix del componente CallMeBack. Flag utilizado para habilitar el boton que lanza la ventana modal

  @track showModal = false; // arcortazar - 20/01/2022: Fix del componente CallMeBack. Flag que hace que se visualice o no la ventana modal

  // Consulta de contact person Id
  // arcortazar - 20/02/2022: fix del componente callMeBack. Añadimos tambien el ContactName a la lista de atributos a recuperar
  @wire(getRecord, { recordId: "$recordId", fields: [PERSON_CONTACT_ID, PERSON_CONTACT_NAME] })
  getAccount({ error, data }) {
    if (data) {
      this.isLoading = true;
      getContactRequestsByCustomerId({
        whoId: data.fields.PersonContactId.value,
        name: data.fields.Name.value
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
   * 
   * @last modified on  : 20/01/2022
   * @last modified by  : arcortazar
   */
  resolve(data) {
    this.callMeBacks = [];
    this.fullListCallMeBacks = [];
    data.forEach((element) => {
      let callMeBack = Object.assign({}, element);
      callMeBack.url = window.location.hostname + "/" + callMeBack.Id;
      this.fullListCallMeBacks.push(callMeBack);
    });

    // arcortazar - 20/01/2022: 
    // Fix del componente CallMeBack. Visualizamos un máximo de 4 elementos en el componente, y si son más, 
    // habilitamos un boton que permita desplegar una ventana modal con toda la información
    let cargaTemp;
    if(this.fullListCallMeBacks.length > 3)
    {
      cargaTemp = this.fullListCallMeBacks.slice(0, 4);
      this.isLong = true;
    }
    else
    {
      cargaTemp = this.fullListCallMeBacks;
      this.isLong = false;
    }
    this.callMeBacks = cargaTemp;
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
      this.showMessage(ERROR_TITLE, ERROR_CANCELED, "warning");
      this.authorize();
    } else {
      try {
        await genesysCloud.cancelCallBack(row.GenesysInteractionId__c, row.Id);
        this.setCancelStatus(row);
      } catch (error) {
        this.showMessage(ERROR_TITLE, ERROR_CANCELED, ERROR_VARIANT);
        console.error(error);
      }
    }
    // Display fresh data in the form
  }

  /**
   * Maneja el evento que ocurre al pulsar en el botón 'View all' del componente. Pone a true el valor showModal, haciendo que se abra la ventana modal con 
   * todos los CallMeBacks
   **
   * @author arcortazar
   * @date 20/01/2022
   */
  openModal() {
    // Setting boolean variable to true, this will show the Modal
    this.showModal = true;
  }

  /**
   * Maneja el evento que ocurre al pulsar en el botón 'Close' de la ventana modal. Pone a false el valor showModal haciendo que esta se cierre, volviendo 
   * a la ficha del account.
   **
   * @author arcortazar
   * @date 20/01/2022
   */
  closeModal() {
    // Setting boolean variable to false, this will hide the Modal
    this.showModal = false;
  }

  /**
   * Se actualiza el estado del registro de Contact Request a Cancelado.
   * @date 02/11/2021
   * @author rpolvera
   */
  setCancelStatus(record) {
    const fields = {};
    fields[CONTACT_REQUEST_ID.fieldApiName] = record.Id;
    fields[CONTACT_REQUEST_STATUS.fieldApiName] = STATUS_CANCELLED;
    const recordInput = { fields };
    updateRecord(recordInput)
      .then(() => {
        this.showMessage(SUCCESS_TITLE, SUCCESS_CANCELED, SUCCESS_VARIANT);
        this.callMeBacks = this.callMeBacks.filter(
          (element) => element.Id !== record.Id
        );
      })
      .catch((error) => {
        this.showMessage(ERROR_TITLE, ERROR_CANCELED, ERROR_VARIANT);
        console.error(error);
      });
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
      console.error("Exception: callMeBackList.isAuthorized()", error);
      this.showMessage(ERROR_TITLE, ERROR_CANCELED, "error");
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
      console.error("Exception: callMeBackList.authorize()", error);
      this.showMessage(ERROR_TITLE, ERROR_CANCELED, "error");
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
    return this.columns && this.columns !== ""
      ? JSON.parse(this.columns)
      : undefined;
  }

  /**
   * Título de la tabla.
   * @author jjuaristi
   * @date 18/11/2021
   * @return String que contiene el título.
   */
  get title() {
    let title = "Call Me Backs";
    if (this.isEmpty) {
      title = title + " (0)";
    }
    return title;
  }
}
