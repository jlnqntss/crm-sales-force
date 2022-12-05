import { LightningElement, wire } from "lwc";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

import userId from "@salesforce/user/Id";
import { getRecord } from "lightning/uiRecordApi";
import UserNameFld from "@salesforce/schema/User.Name";
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
    SDM_ControlIntermediaryNotifiaction_ButtonCancel
  };

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

  @wire(getRecord, { recordId: userId, fields: [UserNameFld, UserLastNameFld] })
  userDetails({ error, data }) {
    if (data) {
      this.currentUserName =
        data.fields.LastName.value + ", " + data.fields.Name.value;
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getRecords)
  getIntermediaryRecords({ error, data }) {
    if (data) {
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
      // no hay filtro ni antes ni despues el caso mas sencillo, simplemente
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

        this.valuesToActive = this.valuesToActive.concat(eventValues);
      }

      // de filtro pasa a NO filtro
      if (this.lastQueryTerm !== "" && this.queryTerm === "") {
        this.valuesToActive = [...eventValues];
      }
    } catch (error) {
      console.log("error " + JSON.stringify(error));
    }
  }

  // metodo de busqueda para los dos inputs
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
        console.log("no hay valor filtro");

        this.options = [];
        this.values = [];
        this.options = [...this.resetOptions];
        this.values = [...this.valuesToActive];
        this.queryTerm = "";
      }
    }
  }

  handleSave() {
    updateIntermediaryNotificationFlag({
      notificationsToActiveList: this.valuesToActive
    })
      .then(() => {
        this.options = [...this.resetOptions];
        this.values = [...this.valuesToActive];
        this.queryTerm = ""; // resetear filtros
        this.lastQueryTerm = ""; // resetear filtros

        this.template.querySelector("lightning-input").value = null; // reseteo el valor en el input del buscador

        const event = new ShowToastEvent({
          title: "Éxito",
          message:
            "Las preferencias de notificaciones para Mediador se han actualizado",
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
  }
}
