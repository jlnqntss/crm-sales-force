import { LightningElement, api, track, wire } from "lwc";

import FORM_FACTOR from "@salesforce/client/formFactor";

import { getRecord } from "lightning/uiRecordApi";
import ISOWNEDBYHOMEOFFICE_FIELD from "@salesforce/schema/PlanComercial__c.IsOwnedByHomeOffice__c";
import RECORDTYPEDEVELOPERNAME_FIELD from "@salesforce/schema/PlanComercial__c.RecordType.DeveloperName";

import SDM_PlanAnual_RecordPage_Cancel from "@salesforce/label/c.SDM_PlanAnual_RecordPage_Cancel";
import SDM_PlanAnual_RecordPage_Save from "@salesforce/label/c.SDM_PlanAnual_RecordPage_Save";
import SDM_PlanAnual_RecordPage_Edit from "@salesforce/label/c.SDM_PlanAnual_RecordPage_Edit";
import SDM_PlanAnual_RecordPage_GeneralInformation from "@salesforce/label/c.SDM_PlanAnual_RecordPage_GeneralInformation";
import SDM_PlanAnual_RecordPage_TimePeriod from "@salesforce/label/c.SDM_PlanAnual_RecordPage_TimePeriod";
import SDM_PlanAnual_RecordPage_KPI from "@salesforce/label/c.SDM_PlanAnual_RecordPage_KPI";

export default class AnnualPlanRecordPage extends LightningElement {
  labels = {
    SDM_PlanAnual_RecordPage_Cancel,
    SDM_PlanAnual_RecordPage_Save,
    SDM_PlanAnual_RecordPage_Edit,
    SDM_PlanAnual_RecordPage_GeneralInformation,
    SDM_PlanAnual_RecordPage_TimePeriod,
    SDM_PlanAnual_RecordPage_KPI
  };

  @api recordId;
  @api objectApiName = "PlanComercial__c";

  // Indica si se esta editando el formulario o no
  @track isEditable = false;

  // Representa las clases de las secciones
  @track secA = "slds-section slds-is-open";
  @track secB = "slds-section slds-is-open";
  @track secC = "slds-section slds-is-open";

  // ocultar campos en caso de que el registro sea propio de un home office, se usa para Ratio Retención y Siniestralidad
  planComercialQuery;
  isOwnedByHomeOffice;
  isVisibleKPI = false;
  isVisibleSendNotification = true;

  // query para obtener el la información del campo isOwnedByHomeOffice__c
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [ISOWNEDBYHOMEOFFICE_FIELD, RECORDTYPEDEVELOPERNAME_FIELD]
  })
  getPlanData(data, error) {
    if (error) {
      let message = "Unknown error";
      if (Array.isArray(error.body)) {
        message = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        message = error.body.message;
      }
      console.log("Error " + message);
    } else if (data) {
      try {
        let jsonParse = JSON.parse(JSON.stringify(data));
        let isOwnedByHomeOffice =
          jsonParse.data.fields.IsOwnedByHomeOffice__c.value;
        let rtName = jsonParse.data.fields.RecordType.displayValue;

        if (isOwnedByHomeOffice && "Mensual Plan" === rtName) {
          // si es un plan mensual y el owner es un home office muestro los campos
          this.isVisibleKPI = true;
          this.isVisibleSendNotification = false;
        } else if (isOwnedByHomeOffice === false) {
          // si no es un plan de home office muestro siempre
          this.isVisibleKPI = true;
        } else {
          this.isVisibleKPI = false;
        }
      } catch (e) {
        console.log(JSON.stringify(e));
      }
    }
  }

  // Estructura que representa las diferentes secciones expand/collapse
  Sections = {
    secA: {
      Id: "sectionA",
      Name: "secA",
      Title: this.labels.SDM_PlanAnual_RecordPage_GeneralInformation,
      ControlName: "contentA"
    },
    secB: {
      Id: "sectionB",
      Name: "secB",
      Title: this.labels.SDM_PlanAnual_RecordPage_TimePeriod,
      ControlName: "contentB"
    },
    secC: {
      Id: "sectionC",
      Name: "secC",
      Title: this.labels.SDM_PlanAnual_RecordPage_KPI,
      ControlName: "contentC"
    }
  };

  // Evento: gestiona cuando el usuario hace clic en los controles expand/collapse
  sectionToggle(event) {
    try {
      // recuperamos el nombre del control
      let tagName = event.target.name;
      // Buscamos el id del div principal
      let secId = this.Sections[tagName].Id;
      // Recuperamos el objeto html que se corresponde al div princpal
      let divblock = this.template.querySelector('[data-id="' + secId + '"]');
      // Añadimos o quitamos la clase sdls-is-open
      divblock.classList.toggle("slds-is-open");
    } catch (error) {
      console.error(error);
    }
  }

  // Evento: gestiona el clic en los botones de edicion de los campos
  toggleEdit() {
    this.isEditable = !this.isEditable;
  }

  // Evento: se lanza cuando se ha guardado el formulario
  handleSuccess() {
    this.isEditable = false;
  }

  // Propiedad: indica si el formulario se esta ejecutando en una pantalla grande
  get isDesktop() {
    return FORM_FACTOR === "Large";
  }

  // Propiedad: indica si el formulario se esta ejecutando en una pantalla pequeña
  get isPhone() {
    return FORM_FACTOR === "Small";
  }
}
