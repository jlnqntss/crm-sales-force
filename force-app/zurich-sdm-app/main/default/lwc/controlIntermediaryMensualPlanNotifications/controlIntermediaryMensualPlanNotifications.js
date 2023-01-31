import { LightningElement, wire } from "lwc";

import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

import userId from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import UserFirstNameFld from "@salesforce/schema/User.FirstName";
import UserLastNameFld from "@salesforce/schema/User.LastName";

// Custom Labels
import SDM_ControlIntermediaryNotifiaction_Title from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_Title";
import SDM_ControlIntermediaryNotifiaction_Loading from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_Loading";
import SDM_ControlIntermediaryNotifiaction_MultipicklistTitle from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_MultipicklistTitle";
import SDM_ControlIntermediaryNotifiaction_Active from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_Active";
import SDM_ControlIntermediaryNotifiaction_Inactive from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_Inactive";
import SDM_ControlIntermediaryNotifiaction_Intermediary from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_Intermediary";
import SDM_ControlIntermediaryNotifiaction_IntermediaryPlaceholder from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_IntermediaryPlaceholder";
import SDM_ControlIntermediaryNotifiaction_ButtonSave from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_ButtonSave";
import SDM_ControlIntermediaryNotifiaction_ButtonCancel from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_ButtonCancel";
import SDM_ControlIntermediaryNotifiaction_ActiveAll from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_ActiveAll";
import SDM_ControlIntermediaryNotifiaction_InactiveAll from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_InactiveAll";
import SDM_ControlIntermediaryNotifiaction_SuccessToastTitle from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_SuccessToastTitle";
import SDM_ControlIntermediaryNotifiaction_SuccessToastMessage from "@salesforce/label/c.SDM_ControlIntermediaryNotifiaction_SuccessToastMessage";

// controller
import getRecords from "@salesforce/apex/IntermediaryNotificationsController.getRecords";
import updateIntermediaryNotificationFlag from "@salesforce/apex/IntermediaryNotificationsController.updateIntermediaryNotificationFlag";

export default class ControlIntermediaryMensualPlanNotifications extends LightningElement {
  labels = {
    SDM_ControlIntermediaryNotifiaction_Title,
    SDM_ControlIntermediaryNotifiaction_Loading,
    SDM_ControlIntermediaryNotifiaction_MultipicklistTitle,
    SDM_ControlIntermediaryNotifiaction_Active,
    SDM_ControlIntermediaryNotifiaction_Inactive,
    SDM_ControlIntermediaryNotifiaction_Intermediary,
    SDM_ControlIntermediaryNotifiaction_IntermediaryPlaceholder,
    SDM_ControlIntermediaryNotifiaction_ButtonSave,
    SDM_ControlIntermediaryNotifiaction_ButtonCancel,
    SDM_ControlIntermediaryNotifiaction_ActiveAll,
    SDM_ControlIntermediaryNotifiaction_InactiveAll,
    SDM_ControlIntermediaryNotifiaction_SuccessToastTitle,
    SDM_ControlIntermediaryNotifiaction_SuccessToastMessage
  };

  copyData;
  isLoading = true;
  isLoadingSearch = false;
  currentUserName = "";
  resetOptions = [];
  resetValues = [];
  options = [];
  values = []; // lista de valores activos a mostrar en el picklist
  valuesToActive = []; // lista de ids activados a enviar al controlador para guardar
  hasChange = false;
  queryTerm = "";
  lastQueryTerm = "";
  showSaveSpinner = false; // mostrar spinner al pulsar el boton guardar
  disableInactiveAll = false; // inactivar el botón Desactivar All
  disableActiveAll = false; // inactivar el botón Activar All

  @wire(getRecord, {
    recordId: userId,
    fields: [UserFirstNameFld, UserLastNameFld]
  })
  userDetails({ error, data }) {
    if (data) {
      this.currentUserName =
        data.fields.LastName.value + ", " + data.fields.FirstName.value;
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getRecords)
  getIntermediaryRecords(output) {
    // Hold on to the provisioned value so we can refresh it later.
    this.copyData = output;
    // Destructure the provisioned value
    const { data, error } = output;
    if (data) {
      this.options = []; // reseteo el valor de options para cuando se refresque la vista no duplique valores.
      this.values = []; // reseteo el valor de values para cuando se refresque la vista no duplique los valores a mostrar.
      this.valuesToActive = []; // reseteo de la variable por refrescos
      this.resetOptions = []; // reseteo de la variable por refrescos
      this.resetValues = []; // reseteo de la variable por refrescos

      // añadir los elementos activados
      for (const [key, value] of Object.entries(data.ActiveIntermediary)) {
        const activeOption = {
          label: value,
          value: key
        };
        this.options = [...this.options, activeOption]; // añadir opciones a la lista
        this.values = [...this.values, key]; // añadir opciones activas a la lista (por funcionamiento del componente se añaden las keys unicamente)
        this.resetValues = [...this.resetValues, key]; // lista opciones marcadas para cancelar
        this.valuesToActive = [...this.valuesToActive, key]; // lista opciones marcadas para actualizar contiene el resultado de todas las operaciones realizadas sobre el multipicklist
      }

      // añadir los elementos desactivados
      for (const [key, value] of Object.entries(data.NonActiveIntermediary)) {
        const nonActiveOption = {
          label: value,
          value: key
        };
        this.options = [...this.options, nonActiveOption]; // añadir opciones a la lista
      }

      // al cargar si no hay registros en values desactivo el boton desactivar todos
      this.handleInactiveActiveButtons();

      this.resetOptions = [...this.options];
      this.isLoading = false;
    } else if (error) {
      console.log("Error " + JSON.stringify(error));
    }
  }

  handleOnChangeMultipicklist(event) {
    try {
      this.hasChange = true;
      let eventValues = event.detail.value;

      // 4 escenarios
      // no hay filtro ni antes ni despues el caso mas sencillo, simplemente los valores que se muestran son los que se activan
      if (this.lastQueryTerm === "" && this.queryTerm === "") {
        this.valuesToActive = [...eventValues];
      }

      // de no filtro pasa a filtro; // debido al nuevo evento onchange del input search debemos controlar el caso en que se actualiza el filtro añadiendo mas informacion
      if (
        (this.lastQueryTerm === "" && this.queryTerm !== "") ||
        (this.lastQueryTerm !== "" && this.queryTerm !== "")
      ) {
        // borro de valuesToActive los elementos que cumplan el filtro activo
        let index = -1;
        for (const opt of this.options) {
          // recorro options y elimino de valuesToActive los que coincidan
          index = this.valuesToActive.indexOf(opt.value);
          if (index >= 0) {
            // si lo encuentra
            this.valuesToActive.splice(index, 1);
          }
          index = -1; // reseteo la variable
        }

        // una vez eliminados los elementos de la lista activo que concuerdan con el filtro los vuelvo a añadir de event values pero es posible que haya duplicados hay que eliminarlos
        let concatValues = this.valuesToActive.concat(eventValues);

        this.valuesToActive = concatValues.filter((c, i) => {
          return concatValues.indexOf(c) === i;
        });
      }

      // de filtro pasa a NO filtro
      if (this.lastQueryTerm !== "" && this.queryTerm === "") {
        this.valuesToActive = [...eventValues];
      }

      this.values = [...eventValues];
      // vuelvo a activar los botones en caso de hacer algun pase de algunos registros
      // al cargar si no hay registros en values desactivo el boton desactivar todos
      this.handleInactiveActiveButtons();
    } catch (error) {
      console.log("error " + JSON.stringify(error));
    }
  }

  // meall de busqueda para los dos inputs
  handleFilterOnChange(event) {
    this.isLoadingSearch = true;
    // actualizo lastQueryTerm
    this.lastQueryTerm = this.queryTerm;
    this.queryTerm = event.target.value;

    if (this.queryTerm !== "") {
      this.options = [];
      // recorrer options
      for (const opt of this.resetOptions) {
        if (opt.label.toLowerCase().includes(this.queryTerm.toLowerCase())) {
          this.options = [...this.options, opt];
          // aqui no actualizamos la variable values como en el resto de casuisticas cuando cambian los elementos de izq a derecha o viceversa
          // porque con el filtro se ocultan los valores y si existen va a ser siempre mayor que el numero de opciones por lo que se calcula correctamente
        }
      }
    } else {
      console.log("entro en no hay filtro");
      this.options = [];
      this.values = [];
      this.options = [...this.resetOptions];
      this.values = [...this.valuesToActive];
      this.queryTerm = "";
      // al cargar si no hay registros en values desactivo el boton desactivar todos
    }
    this.handleInactiveActiveButtons();
    this.isLoadingSearch = false;
  }

  handleSave() {
    // debido a que en caso de que las modificaciones de activacion y desactivacion resulte en lo mismo que habia cuando se cargó el componente no hacemos nada
    let orderedValuesToActive = [...this.valuesToActive].sort();
    let orderedResetValues = [...this.resetValues].sort();

    if (
      JSON.stringify(orderedValuesToActive) ===
      JSON.stringify(orderedResetValues)
    ) {
      this.handleCancel();
      const event = new ShowToastEvent({
        title:
          this.labels.SDM_ControlIntermediaryNotifiaction_SuccessToastTitle,
        message:
          this.labels.SDM_ControlIntermediaryNotifiaction_SuccessToastMessage,
        variant: "success"
      });
      this.dispatchEvent(event);
    } else {
      this.showSaveSpinner = true;
      // si hay cambios actualizamos
      updateIntermediaryNotificationFlag({
        notificationsToActiveList: this.valuesToActive
      })
        .then(() => {
          this.showSaveSpinner = false;
          this.queryTerm = ""; // resetear filtros
          this.lastQueryTerm = ""; // resetear filtros
          refreshApex(this.copyData); // refresco la variable donde hemos copiado el resultado del metodo getRecords para que así se vuelva a ejecutar el metodo get record y se calcula la activacion/desactivacion de los botones

          this.template.querySelector("lightning-input").value = null; // reseteo el valor en el input del buscador

          const event = new ShowToastEvent({
            title:
              this.labels.SDM_ControlIntermediaryNotifiaction_SuccessToastTitle,
            message:
              this.labels
                .SDM_ControlIntermediaryNotifiaction_SuccessToastMessage,
            variant: "success"
          });
          this.dispatchEvent(event);
          this.hasChange = false;
        })
        .catch((error) => {
          this.showSaveSpinner = false;
          const event = new ShowToastEvent({
            title: "Error",
            message: error.body.message,
            variant: "error"
          });
          this.dispatchEvent(event);
        });
    }
  }

  // resetear picklist
  handleCancel() {
    this.options = [];
    this.values = [];
    this.options = [...this.resetOptions];
    this.values = [...this.resetValues];
    this.valuesToActive = [...this.resetValues];
    this.hasChange = false;
    this.queryTerm = "";
    this.lastQueryTerm = "";
    this.template.querySelector("lightning-input").value = null; // reseteo el valor en el input del buscador

    // al resetear si no hay registros en values desactivo el boton desactivar todos
    this.handleInactiveActiveButtons();
  }

  // control del botón Activar all, no separamos logica si hay filtro ya que se activan todos los campos que haya en opciones ya sean todos o los del filtro
  handleActiveAll() {
    this.disableActiveAll = true; // deshabilito el boton activar All
    this.disableInactiveAll = false; // habilito el boton desactivar All
    for (const opt of this.options) {
      if (!this.valuesToActive.includes(opt.value)) {
        // incluyo en la lista de values los valores que no existen ya
        this.hasChange = true;
        this.valuesToActive = [...this.valuesToActive, opt.value];
      }
      this.values = [...this.values, opt.value]; // añado siempre el valor a value
    }
  }

  // control del botón Inactivar all
  handleInactiveAll() {
    this.disableInactiveAll = true; // deshabilito el boton desactivar All
    this.disableActiveAll = false; // habilito el boton activar All
    if (this.queryTerm !== "") {
      // si hay filtro
      let index;
      for (const opt of this.options) {
        index = this.valuesToActive.indexOf(opt.value); // busco si existe en la lista de valores a activar la opción a desactivar para borrar este elemento de la lista
        if (index > -1) {
          // only splice array when item is found
          this.valuesToActive.splice(index, 1); // 2nd parameter means remove one item only
          this.hasChange = true;
        }
      }
      this.values = [];

      // eliminar duplicados de values to active, se puede dar en casos raros
      this.valuesToActive = this.valuesToActive.filter((c, i) => {
        return this.valuesToActive.indexOf(c) === i;
      });
    } else {
      // si no hay filtro
      if (this.valuesToActive.length > 0) {
        this.hasChange = true; // solo muestro el boton guardar si habia valores activos al pulsarlo
      }
      this.valuesToActive = [];
      this.values = [];
    }
  }

  handleInactiveActiveButtons() {
    this.disableInactiveAll = false; // reset desactivar botones
    this.disableActiveAll = false; // reset desactivar botones
    // recorrer values
    let numOptions = this.options.length;
    let numValues = 0;
    for (const optFiltered of this.options) {
      if (this.values.indexOf(optFiltered.value) >= 0) {
        numValues++;
      }
    }

    if (numOptions === 0) {
      this.disableInactiveAll = true;
      this.disableActiveAll = true;
    } else if (numValues === 0) {
      // si el numero de elementos en la lista values es 0 inactivamos el boton desactivar todos
      this.disableInactiveAll = true;
    } else if (numOptions === numValues) {
      // si el numero de elementos en la lista values es igual al numero de opciones inactivamos el boton activar todos
      this.disableActiveAll = true;
    }
  }
}
