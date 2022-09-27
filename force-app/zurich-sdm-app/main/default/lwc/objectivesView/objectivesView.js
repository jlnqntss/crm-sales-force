/* eslint-disable guard-for-in */
import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { getRecordNotifyChange } from "lightning/uiRecordApi";

// Custom Labels
import SDM_Objetivos_Title from "@salesforce/label/c.SDM_Objetivos_Title";
import SDM_Objetivos_Year from "@salesforce/label/c.SDM_Objetivos_Year";
import SDM_Objetivos_Indicator from "@salesforce/label/c.SDM_Objetivos_Indicator";
import SDM_Objetivos_Segment from "@salesforce/label/c.SDM_Objetivos_Segment";
import SDM_Objetivos_Product from "@salesforce/label/c.SDM_Objetivos_Product";
import SDM_Objetivos_January from "@salesforce/label/c.SDM_Objetivos_January";
import SDM_Objetivos_February from "@salesforce/label/c.SDM_Objetivos_February";
import SDM_Objetivos_March from "@salesforce/label/c.SDM_Objetivos_March";
import SDM_Objetivos_April from "@salesforce/label/c.SDM_Objetivos_April";
import SDM_Objetivos_May from "@salesforce/label/c.SDM_Objetivos_May";
import SDM_Objetivos_June from "@salesforce/label/c.SDM_Objetivos_June";
import SDM_Objetivos_July from "@salesforce/label/c.SDM_Objetivos_July";
import SDM_Objetivos_August from "@salesforce/label/c.SDM_Objetivos_August";
import SDM_Objetivos_September from "@salesforce/label/c.SDM_Objetivos_September";
import SDM_Objetivos_October from "@salesforce/label/c.SDM_Objetivos_October";
import SDM_Objetivos_November from "@salesforce/label/c.SDM_Objetivos_November";
import SDM_Objetivos_December from "@salesforce/label/c.SDM_Objetivos_December";
import SDM_Objetivos_ButtonNew from "@salesforce/label/c.SDM_Objetivos_ButtonNew";
import SDM_Objetivos_ButtonClone from "@salesforce/label/c.SDM_Objetivos_ButtonClone";
import SDM_Objetivos_Create_Title from "@salesforce/label/c.SDM_Objetivos_Create_Title";
import SDM_Objetivos_ButtonClose from "@salesforce/label/c.SDM_Objetivos_ButtonClose";
import SDM_Objetivos_ButtonEdit from "@salesforce/label/c.SDM_Objetivos_ButtonEdit";
import SDM_Objetivos_Active from "@salesforce/label/c.SDM_Objetivos_Active";
import SDM_Objetivos_Success from "@salesforce/label/c.SDM_Objetivos_Success";
import SDM_Objetivos_ToastNewRecord from "@salesforce/label/c.SDM_Objetivos_ToastNewRecord";
import SDM_Objetivos_ToastEditRecord from "@salesforce/label/c.SDM_Objetivos_ToastEditRecord";
import SDM_Objetivos_Warning from "@salesforce/label/c.SDM_Objetivos_Warning";
import SDM_Objetivos_Error from "@salesforce/label/c.SDM_Objetivos_Error";
import SDM_Objetivos_ToastCloneNotSelected from "@salesforce/label/c.SDM_Objetivos_ToastCloneNotSelected";
import SDM_Objetivos_RowErrorTitle from "@salesforce/label/c.SDM_Objetivos_RowErrorTitle";
import SDM_Objetivos_DuplicateRecordsRowError from "@salesforce/label/c.SDM_Objetivos_DuplicateRecordsRowError";
import SDM_Objetivos_Edit_Title from "@salesforce/label/c.SDM_Objetivos_Edit_Title";
import SDM_Objetivos_Clone_Title from "@salesforce/label/c.SDM_Objetivos_Clone_Title";
import SDM_Objetivos_ButtonSave from "@salesforce/label/c.SDM_Objetivos_ButtonSave";
import SDM_Objetivos_ButtonCancel from "@salesforce/label/c.SDM_Objetivos_ButtonCancel";
import SDM_Objetivos_ToastDuplicateError from "@salesforce/label/c.SDM_Objetivos_ToastDuplicateError";

// campos SF
import OBJECTIVE_YEAR_FIELD from "@salesforce/schema/Objective__c.Year__c";
import OBJECTIVE_INDICATOR_FIELD from "@salesforce/schema/Objective__c.Indicator__c";
import OBJECTIVE_SEGMENT_FIELD from "@salesforce/schema/Objective__c.Segment__c";
import OBJECTIVE_PRODUCT_FIELD from "@salesforce/schema/Objective__c.Product__c";
import OBJECTIVE_JANUARY_FIELD from "@salesforce/schema/Objective__c.January__c";
import OBJECTIVE_FEBRUARY_FIELD from "@salesforce/schema/Objective__c.February__c";
import OBJECTIVE_MARCH_FIELD from "@salesforce/schema/Objective__c.March__c";
import OBJECTIVE_APRIL_FIELD from "@salesforce/schema/Objective__c.April__c";
import OBJECTIVE_MAY_FIELD from "@salesforce/schema/Objective__c.May__c";
import OBJECTIVE_JUNE_FIELD from "@salesforce/schema/Objective__c.June__c";
import OBJECTIVE_JULY_FIELD from "@salesforce/schema/Objective__c.July__c";
import OBJECTIVE_AUGUST_FIELD from "@salesforce/schema/Objective__c.August__c";
import OBJECTIVE_SEPTEMBER_FIELD from "@salesforce/schema/Objective__c.September__c";
import OBJECTIVE_OCTOBER_FIELD from "@salesforce/schema/Objective__c.October__c";
import OBJECTIVE_NOVEMBER_FIELD from "@salesforce/schema/Objective__c.November__c";
import OBJECTIVE_DECEMBER_FIELD from "@salesforce/schema/Objective__c.December__c";
import OBJECTIVE_ACTIVE_FIELD from "@salesforce/schema/Objective__c.Active__c";

// controller
import getObjetives from "@salesforce/apex/ObjectivesViewController.getObjetives";
import getSelectorYearList from "@salesforce/apex/ObjectivesViewController.getSelectorYearList";
import cloneRecords from "@salesforce/apex/ObjectivesViewController.cloneRecords";
import updateObjectives from "@salesforce/apex/ObjectivesViewController.updateObjectives";

const actions = [
  { label: SDM_Objetivos_ButtonEdit, name: "edit" },
  { label: SDM_Objetivos_ButtonClone, name: "clone" }
];

export default class ObjectivesView extends LightningElement {
  labels = {
    SDM_Objetivos_Title,
    SDM_Objetivos_Year,
    SDM_Objetivos_Indicator,
    SDM_Objetivos_Segment,
    SDM_Objetivos_Product,
    SDM_Objetivos_January,
    SDM_Objetivos_February,
    SDM_Objetivos_March,
    SDM_Objetivos_April,
    SDM_Objetivos_May,
    SDM_Objetivos_June,
    SDM_Objetivos_July,
    SDM_Objetivos_August,
    SDM_Objetivos_September,
    SDM_Objetivos_October,
    SDM_Objetivos_November,
    SDM_Objetivos_December,
    SDM_Objetivos_ButtonNew,
    SDM_Objetivos_ButtonClone,
    SDM_Objetivos_Create_Title,
    SDM_Objetivos_ButtonClose,
    SDM_Objetivos_ButtonEdit,
    SDM_Objetivos_Active,
    SDM_Objetivos_Success,
    SDM_Objetivos_ToastNewRecord,
    SDM_Objetivos_ToastEditRecord,
    SDM_Objetivos_Warning,
    SDM_Objetivos_Error,
    SDM_Objetivos_ToastCloneNotSelected,
    SDM_Objetivos_RowErrorTitle,
    SDM_Objetivos_DuplicateRecordsRowError,
    SDM_Objetivos_Edit_Title,
    SDM_Objetivos_Clone_Title,
    SDM_Objetivos_ButtonSave,
    SDM_Objetivos_ButtonCancel,
    SDM_Objetivos_ToastDuplicateError
  };

  columns = [
    {
      label: this.labels.SDM_Objetivos_Indicator,
      fieldName: OBJECTIVE_INDICATOR_FIELD.fieldApiName
    },
    {
      label: this.labels.SDM_Objetivos_Segment,
      fieldName: OBJECTIVE_SEGMENT_FIELD.fieldApiName
    },
    {
      label: this.labels.SDM_Objetivos_Product,
      fieldName: OBJECTIVE_PRODUCT_FIELD.fieldApiName
    },
    {
      label: this.labels.SDM_Objetivos_January,
      fieldName: OBJECTIVE_JANUARY_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_February,
      fieldName: OBJECTIVE_FEBRUARY_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_March,
      fieldName: OBJECTIVE_MARCH_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_April,
      fieldName: OBJECTIVE_APRIL_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_May,
      fieldName: OBJECTIVE_MAY_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_June,
      fieldName: OBJECTIVE_JUNE_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_July,
      fieldName: OBJECTIVE_JULY_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_August,
      fieldName: OBJECTIVE_AUGUST_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_September,
      fieldName: OBJECTIVE_SEPTEMBER_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_October,
      fieldName: OBJECTIVE_OCTOBER_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_November,
      fieldName: OBJECTIVE_NOVEMBER_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_December,
      fieldName: OBJECTIVE_DECEMBER_FIELD.fieldApiName,
      editable: true,
      type: "percent",
      typeAttributes: {
        step: "0.01",
        minimumFractionDigits: "0",
        maximumFractionDigits: "2"
      }
    },
    {
      label: this.labels.SDM_Objetivos_Active,
      fieldName: OBJECTIVE_ACTIVE_FIELD.fieldApiName,
      editable: true,
      type: "boolean",
      cellAttributes: { alignment: "center" }
    },
    {
      type: "action",
      typeAttributes: { rowActions: actions, menuAlignment: "auto" }
    }
  ];

  // variables tabla
  errors;
  columns = this.columns;
  rowOffset = 0;
  draftValues = [];
  cloneValues = [];
  recordIdSelected = ""; // edit button action
  recordSelected; // clone button action
  editFormModal = false;
  cloneFormModal = false;
  newEditFormModal = false; // dado que new y edit comparten formulario, creo esta variable para la visibilidad del modal, editFormModal y newFormModal sirven para el título del modal y los campos si son read only o no

  // variables selector
  currentYear = new Date().getFullYear();
  selectedYear = new Date().getFullYear(); // lo inicializo por defecto al año actual para la query cuando cargue
  yearSelectorValues = [];

  // variables new button
  isShowModal = false;
  newFormModal = false;
  fields = [
    OBJECTIVE_YEAR_FIELD,
    OBJECTIVE_INDICATOR_FIELD,
    OBJECTIVE_SEGMENT_FIELD,
    OBJECTIVE_PRODUCT_FIELD,
    OBJECTIVE_JANUARY_FIELD,
    OBJECTIVE_FEBRUARY_FIELD,
    OBJECTIVE_MARCH_FIELD,
    OBJECTIVE_APRIL_FIELD,
    OBJECTIVE_MAY_FIELD,
    OBJECTIVE_JUNE_FIELD,
    OBJECTIVE_JULY_FIELD,
    OBJECTIVE_AUGUST_FIELD,
    OBJECTIVE_SEPTEMBER_FIELD,
    OBJECTIVE_OCTOBER_FIELD,
    OBJECTIVE_NOVEMBER_FIELD,
    OBJECTIVE_DECEMBER_FIELD,
    OBJECTIVE_ACTIVE_FIELD
  ];

  /******* lightning-datatable *******************************************************************************************************/
  @wire(getObjetives, { year: "$selectedYear" })
  objectivesData;

  /** el objeto errors tiene la siguiente forma:
   * {"rows":{"a1O5E000001g7ZPUAY":{"title":"We found an error","messages":["Test error","Enero: value outside of valid range on numeric field: 1500.0"]},"a1O5E000001g7YWUAY":{"title":"We found an error","messages":["La suma de los pesos debe ser 100%"]}}}
   * siendo el id del registro la key del atributo "key-field" del datatable*/
  async handleSave(event) {
    const updatedFields = this.setMonthPercentValues(event.detail.draftValues);
    console.log("updatedFields " + JSON.stringify(updatedFields));

    // Prepare the record IDs for getRecordNotifyChange()
    const notifyChangeIds = updatedFields.map((row) => {
      return { recordId: row.Id };
    });

    try {
      this.errors = ""; // reseteo la variable de error antes de guardar

      // Pass edited fields to the updateObjectives Apex controller
      const result = await updateObjectives({
        data: JSON.stringify(updatedFields)
      });
      console.log("Apex update result: " + JSON.stringify(result));

      if (result.variant !== "success") {
        const idsErrorArray = result.errorIds.split(",");
        const messageErrorsUpdate = result.errorMessage.split("|");

        let errors = {};
        errors.rows = {};
        for (let rowId in idsErrorArray) {
          errors.rows[idsErrorArray[rowId]] = {
            title: this.labels.SDM_Objetivos_RowErrorTitle,
            messages: messageErrorsUpdate[rowId].split(",")
          };
        }

        // ... etc
        this.errors = errors;
        console.log("errors " + JSON.stringify(errors));
      }

      const evt = new ShowToastEvent({
        title: result.title,
        message: result.toastMessage,
        variant: result.variant
      });
      this.dispatchEvent(evt);

      // Refresh LDS cache and wires
      getRecordNotifyChange(notifyChangeIds);

      // Display fresh data in the datatable
      await refreshApex(this.objectivesData);

      // Clear all draft values in the datatable
      this.draftValues = [];
    } catch (error) {
      console.log("error " + JSON.stringify(error));
      const evt = new ShowToastEvent({
        title: "Error",
        message: error.body.message,
        variant: "error"
      });
      this.dispatchEvent(evt);
    }
  }

  // mostrar boton editar al final de la linea
  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    let copyRow = JSON.parse(JSON.stringify(row)); // por alguna razon tengo que copiar el objeto para poder modificar los valores de porcentajes, parece que internamente es una constante
    let array = [];
    switch (actionName) {
      case "edit":
        console.log(JSON.stringify(row.Id));
        this.recordIdSelected = row.Id;
        this.recordSelected = row;
        this.isShowModal = true;
        this.newFormModal = false;
        this.editFormModal = true;
        this.newEditFormModal = true;
        this.cloneFormModal = false;
        break;
      case "clone":
        console.log("row " + JSON.stringify(copyRow));
        array = [...array, copyRow];
        this.recordSelected = this.setMonthPercentValues(array)[0];
        this.cloneFormModal = true;
        this.newFormModal = false;
        this.editFormModal = false;
        this.newEditFormModal = false;
        this.isShowModal = true;

        break;
      default:
    }
  }

  /**Actualizar los valores introducidos en la tabla x100 ya que en el inline son valores menores a 1 debido al problema de alineamiento entre el tipo percent y el objeto datatable.
   * Se han dividido /100 previamente en el controlador apex para tener una visualización correcta*/
  setMonthPercentValues(draftValuesInput) {
    console.log(
      "setMonthPercentValues input: " + JSON.stringify(draftValuesInput)
    );

    for (let objetivo of draftValuesInput) {
      for (let key in objetivo) {
        if (
          key !== "Id" &&
          key !== "Active__c" &&
          key !== "Year__c" &&
          key !== "Indicator__c" &&
          key !== "Segment__c" &&
          key !== "Product__c" &&
          key !== "ExternalId__c"
        ) {
          console.log(key);
          let monthValue = objetivo[key];
          objetivo[key] = (monthValue * 100).toFixed(2);
        }
      }
    }
    console.log(
      "result setMonthPercentValues " + JSON.stringify(draftValuesInput)
    );

    return draftValuesInput;
  }

  /************************************Selector ****************************************************************************/
  @wire(getSelectorYearList)
  comboboxYearOptions({ error, data }) {
    console.log("Data yearoptions" + JSON.stringify(data) + " Error " + error);
    if (data) {
      console.log("numero elementos selector " + data.length);
      if (0 !== data.length) {
        // controlo que venga al menos uno
        for (const list of data) {
          const option = {
            label: list,
            value: list
          };
          this.yearSelectorValues = [...this.yearSelectorValues, option]; // añadir opciones a la lista
        }
        this.selectedYear = new Date().getFullYear();
        console.log("selectedYear " + JSON.stringify(this.selectedYear));
      }
    } else if (error) {
      console.log("Error wire comboboxYearOptions " + JSON.stringify(error));
    }
  }

  handleChangeYear(event) {
    this.selectedYear = event.detail.value;
    this.errors = "";
    console.log("selectedYear handle change value: " + this.selectedYear);

    refreshApex(this.objectivesData);
  }

  /************** Button New ****************************************************************************************/
  handleNew() {
    this.recordIdSelected = "";
    this.isShowModal = true;
    this.newFormModal = true;
    this.newEditFormModal = true;
    this.editFormModal = false;
    this.cloneFormModal = false;
  }

  hideModalBox() {
    this.recordIdSelected = "";
    this.newFormModal = false;
    this.editFormModal = false;
    this.cloneFormModal = false;
    this.newEditFormModal = false;
    this.isShowModal = false;
  }

  // se llama tanto para editar como para el new/clone
  handleSuccess(event) {
    let messageToast;
    this.errors = [];

    // calculo el mensaje a mostrar según sea edición o nuevo registro
    if (this.recordIdSelected === "") {
      // nuevo registro
      messageToast = this.labels.SDM_Objetivos_ToastNewRecord;
    } else {
      // editar registro
      messageToast = this.labels.SDM_Objetivos_ToastEditRecord;
    }

    const evt = new ShowToastEvent({
      title: this.labels.SDM_Objetivos_Success,
      message: messageToast,
      variant: "success"
    });
    this.dispatchEvent(evt);

    // cerrar modal y actualizar variables para navegar y refrescar tabla
    this.isShowModal = false;
    let insertedYear = event.detail.fields.Year__c.value;
    this.selectedYear = insertedYear; // actualizo la variable
    this.recordIdSelected = "";

    console.log("selected year save " + this.selectedYear);
    refreshApex(this.objectivesData);
  }

  /************** Button Clone **************************************************************************************/
  async handleCloneNewYear() {
    const selectedRows = this.template
      .querySelector("lightning-datatable")
      .getSelectedRows();

    console.log("selected rows " + JSON.stringify(selectedRows));

    if (selectedRows.length > 0) {
      try {
        const result = await cloneRecords({
          data: JSON.stringify(selectedRows),
          year: this.selectedYear
        });
        console.log(
          JSON.stringify("Apex clone ejecutado " + JSON.stringify(result))
        );

        // si el toast es de error monto el objeto errors para marcar los registros duplicados
        if (result.variant === "error") {
          const idsErrorArray = result.duplicateIds.split(",");
          let errors = {};
          errors.rows = {};
          for (let rowId in idsErrorArray) {
            errors.rows[idsErrorArray[rowId]] = {
              title: this.labels.SDM_Objetivos_RowErrorTitle,
              messages: this.labels.SDM_Objetivos_DuplicateRecordsRowError
            };
            // ... etc
            this.errors = errors;
            console.log("errors " + JSON.stringify(errors));
          }
        }

        const evt = new ShowToastEvent({
          title: result.title,
          message: result.toastMessage,
          variant: result.variant
        });
        this.dispatchEvent(evt);

        await this.refreshSelectedValue(result.year);
        await refreshApex(this.objectivesData);
      } catch (error) {
        const evt = new ShowToastEvent({
          title: this.labels.SDM_Objetivos_Error,
          message: error.body.message,
          variant: "error"
        });
        this.dispatchEvent(evt);
      }
    } else {
      console.log("Selected vacio");
      const evt = new ShowToastEvent({
        title: this.labels.SDM_Objetivos_Warning,
        message: this.labels.SDM_Objetivos_ToastCloneNotSelected,
        variant: "warning"
      });
      this.dispatchEvent(evt);
    }
  }

  async refreshSelectedValue(year) {
    console.log("entro en refreshSelectedValue");
    this.selectedYear = year;
    console.log("async selected year: " + year);
  }

  /************************** Handle on Error New y Clone Form ***********************************************************/
  handleErrorForm(event) {
    console.log("entro en handleErrorClone");
    console.log("event " + JSON.stringify(event));

    let errorEvent = event.detail.output.errors[0];
    let toastMessage;

    if (errorEvent.errorCode === "DUPLICATE_VALUE") {
      toastMessage = this.labels.SDM_Objetivos_ToastDuplicateError;
    } else {
      toastMessage = errorEvent.message;
    }

    const evt = new ShowToastEvent({
      title: this.labels.SDM_Objetivos_Error,
      message: toastMessage,
      variant: "error"
    });
    this.dispatchEvent(evt);
  }
}
