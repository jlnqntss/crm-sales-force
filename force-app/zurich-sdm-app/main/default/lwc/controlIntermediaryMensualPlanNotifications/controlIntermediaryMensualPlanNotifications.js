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
  currentUserName = "";
  resetOptions = [];
  resetValues = [];
  options = [];
  values = []; // lista de valores activos a mostrar en el picklist
  valuesToActive = []; // lista de ids activados a enviar al controlador para guardar
  hasChange = false;
  queryTerm = "";
  lastQueryTerm = "";

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

      // 3 escenarios
      // no hay filtro ni antes ni despues el caso mas sencillo, simplemente los valores que se muestran son los que se activan
      if (this.lastQueryTerm === "" && this.queryTerm === "") {
        this.valuesToActive = [...eventValues];
      }

      // de no filtro pasa a filtro
      if (this.lastQueryTerm === "" && this.queryTerm !== "") {
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
    } catch (error) {
      console.log("error " + JSON.stringify(error));
    }
  }

  // meall de busqueda para los dos inputs
  handleKeyUp(event) {
    const isEnterKey = event.keyCode === 13;
    if (isEnterKey) {
      // actualizo lastQueryTerm
      this.lastQueryTerm = this.queryTerm;

      this.queryTerm = event.target.value;

      if (this.queryTerm !== "") {
        this.options = [];
        // recorrer options
        for (const opt of this.resetOptions) {
          if (opt.label.includes(this.queryTerm)) {
            this.options = [...this.options, opt];
          }
        }
      } else {
        this.options = [];
        this.values = [];
        this.options = [...this.resetOptions];
        this.values = [...this.valuesToActive];
        this.queryTerm = "";
      }
    }
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
      // si hay cambios actualizamos
      updateIntermediaryNotificationFlag({
        notificationsToActiveList: this.valuesToActive
      })
        .then(() => {
          this.queryTerm = ""; // resetear filtros
          this.lastQueryTerm = ""; // resetear filtros
          refreshApex(this.copyData); // refresco la variable donde hemos copiado el resultado del metodo getRecords para que así se vuelva a ejecutar el metodo get record

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
  }

  // control del botón Activar all, no separamos logica si hay filtro ya que se activan todos los campos que haya en opciones ya sean todos o los del filtro
  handleActiveAll() {
    for (const opt of this.options) {
      if (!this.valuesToActive.includes(opt.value)) {
        // incluyo en la lista de values los valores que no existen ya
        this.hasChange = true;
        this.valuesToActive = [...this.valuesToActive, opt.value];
        this.values = [...this.values, opt.value];
      }
    }
  }

  // control del botón Inactivar all
  handleInactiveAll() {
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
}
