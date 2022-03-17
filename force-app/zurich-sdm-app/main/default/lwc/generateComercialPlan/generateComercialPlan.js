import { LightningElement, track } from "lwc";

import FORM_FACTOR from '@salesforce/client/formFactor';

import SDM_PlanAnual_KPICompare from "@salesforce/label/c.SDM_PlanAnual_KPICompare";
import SDM_PlanAnual_Title from "@salesforce/label/c.SDM_PlanAnual_Title";
import SDM_PlanAnual_ButtonCancel from "@salesforce/label/c.SDM_PlanAnual_ButtonCancel";
import SDM_PlanAnual_ButtonDelete from "@salesforce/label/c.SDM_PlanAnual_ButtonDelete";
import SDM_PlanAnual_ButtonEdit from "@salesforce/label/c.SDM_PlanAnual_ButtonEdit";
import SDM_PlanAnual_SavingError from "@salesforce/label/c.SDM_PlanAnual_SavingError";
import SDM_PlanAnual_FieldLock from "@salesforce/label/c.SDM_PlanAnual_FieldLock";
import SDM_PlanAnual_RowIndicator from "@salesforce/label/c.SDM_PlanAnual_RowIndicator";
import SDM_PlanAnual_Loading from "@salesforce/label/c.SDM_PlanAnual_Loading";
import SDM_PlanAnual_ButtonNew from "@salesforce/label/c.SDM_PlanAnual_ButtonNew";
import SDM_PlanAnual_NewPlan from "@salesforce/label/c.SDM_PlanAnual_NewPlan";
import SDM_PlanAnual_KPINoData from "@salesforce/label/c.SDM_PlanAnual_KPINoData";
import SDM_PlanAnual_OriginalValue from "@salesforce/label/c.SDM_PlanAnual_OriginalValue";
import SDM_PlanAnual_PlanName from "@salesforce/label/c.SDM_PlanAnual_PlanName";
import SDM_PlanAnual_PlansToDelete from "@salesforce/label/c.SDM_PlanAnual_PlansToDelete";
import SDM_PlanAnual_KPIReal from "@salesforce/label/c.SDM_PlanAnual_KPIReal";
import SDM_PlanAnual_ButtonSave from "@salesforce/label/c.SDM_PlanAnual_ButtonSave";
import SDM_PlanAnual_ButtonSaving from "@salesforce/label/c.SDM_PlanAnual_ButtonSaving";
import SDM_PlanAnual_YearPlaceholder from "@salesforce/label/c.SDM_PlanAnual_YearPlaceholder";
import SDM_PlanAnual_SavingSuccess from "@salesforce/label/c.SDM_PlanAnual_SavingSuccess";
import SDM_PlanAnual_Summary from "@salesforce/label/c.SDM_PlanAnual_Summary";
import SDM_PlanAnual_SavingSuccessMessage from "@salesforce/label/c.SDM_PlanAnual_SavingSuccessMessage";
import SDM_PlanAnual_NoPlan from "@salesforce/label/c.SDM_PlanAnual_NoPlan";
import SDM_PlanAnual_SavingErrorMessage from "@salesforce/label/c.SDM_PlanAnual_SavingErrorMessage";
import SDM_PlanAnual_ButtonUndo from "@salesforce/label/c.SDM_PlanAnual_ButtonUndo";
import SDM_PlanAnual_PlanYears from "@salesforce/label/c.SDM_PlanAnual_PlanYears";
import SDM_PlanAnual_ValidationTitle from "@salesforce/label/c.SDM_PlanAnual_ValidationTitle";
import SDM_PlanAnual_ValidationMessage from "@salesforce/label/c.SDM_PlanAnual_ValidationMessage";
import SDM_PlanAnual_ButtonRefresh from "@salesforce/label/c.SDM_PlanAnual_ButtonRefresh";
import SDM_PlanAnual_Legend from "@salesforce/label/c.SDM_PlanAnual_Legend";
import SDM_PlanAnual_WarningCero from "@salesforce/label/c.SDM_PlanAnual_WarningCero";

import saveData from "@salesforce/apex/generateComercialPlanController.saveData";
import getRecords from "@salesforce/apex/generateComercialPlanController.getRecords";
import { NavigationMixin } from "lightning/navigation";
import { CloseActionScreenEvent } from "lightning/actions";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class GenerateComercialPlan extends NavigationMixin(
  LightningElement
) {
  labels = {
    SDM_PlanAnual_Title,
    SDM_PlanAnual_ButtonNew,
    SDM_PlanAnual_ButtonCancel,
    SDM_PlanAnual_ButtonDelete,
    SDM_PlanAnual_ButtonEdit,
    SDM_PlanAnual_ButtonSave,
    SDM_PlanAnual_ButtonSaving,
    SDM_PlanAnual_ButtonUndo,
    SDM_PlanAnual_FieldLock,
    SDM_PlanAnual_RowIndicator,
    SDM_PlanAnual_Loading,
    SDM_PlanAnual_OriginalValue,
    SDM_PlanAnual_KPIReal,
    SDM_PlanAnual_KPINoData,
    SDM_PlanAnual_KPICompare,
    SDM_PlanAnual_YearPlaceholder,
    SDM_PlanAnual_SavingSuccess,
    SDM_PlanAnual_SavingSuccessMessage,
    SDM_PlanAnual_SavingError,
    SDM_PlanAnual_SavingErrorMessage,
    SDM_PlanAnual_NoPlan,
    SDM_PlanAnual_PlanName,
    SDM_PlanAnual_Summary,
    SDM_PlanAnual_PlansToDelete,
    SDM_PlanAnual_NewPlan,
    SDM_PlanAnual_PlanYears,
    SDM_PlanAnual_ValidationTitle,
    SDM_PlanAnual_ValidationMessage,
    SDM_PlanAnual_ButtonRefresh,
    SDM_PlanAnual_Legend,
    SDM_PlanAnual_WarningCero
  };

  @track isEdited = false;
  @track canCreate = false;
  @track canSave = false;
  @track toggleSaveLabel = this.labels.SDM_PlanAnual_ButtonSave;
  @track tabledata;
  @track titleName;

  @track yearValue = new Date().getFullYear();

  newKey = 0;
  numActivePlans = 0;
  thereArePlans = false;
  deletedPlans = 0;

  Indicator = {
    type_percent: "type_percent",
    type_number: "type_number",
    type_currency: "type_currency"
  };

  SEPARATOR = "#";
  CATEGORY_INDICATOR = "indicador";
  SLDS_CELL_EDITED_HTML_CLASS = "slds-is-edited";
  // Fila a partir de la cual hay valores que pueden ser numericos, decimal o moneda
  ROWS_FROM_VALUE = 4; // Plan DT, RN/Mediador
  // Fila a partir de la cual hay que considerar el sumatorio de valores
  ROWS_FROM_SUM = 5; // Primer RN/Mediador

  @track isLoading;

  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

  /*-------------------- METODOS DE GESTION DE EVENTOS --------------------*/

  // Evento: inicializacion de la pantalla
  connectedCallback() {
    this.getDataRecords(this.yearValue);
  }

  // Evento: Gestiona el cambio en los campos de cabecera de la tabla. Nombre del plan
  handleChangeHeader(event) {
    try {
      // busca la celda modificada
      let elementFound = this.tabledata.headers.Cells.find(
        (ele) => ele.Name === event.target.name
      );

      // Gestiona el cambio en la celda
      this.handleChangeElement(elementFound, event.target);
    } catch (error) {
      console.error(error);
    }
  }

  // Evento: Gestiona el cambio en los campos de resto de filas de la tabla.
  handleChange(event) {
    try {
      // Buscamos la celda en cada una de las celdas de cada fila
      let elementFound;
      let colIndex = event.target.dataset.colindex;
      let rowIndex = event.target.dataset.rowindex;
      let row = this.tabledata.rows[rowIndex];
      let cell = row.Cells[colIndex];
      if (cell !== undefined) {
        elementFound = cell;
      }

      // Gestiona el cambio en la celda
      this.handleChangeElement(elementFound, event.target);
    } catch (error) {
      console.error(error);
    }
  }

  // Evento: Gestiona el deshacer un cambio en la celda de cabecera
  revertChangeHeader(event) {
    try {
      // Buscamos el elemento modificado
      let elementFound = this.tabledata.headers.Cells.find(
        (ele) => ele.Name === event.target.name
      );

      // Gestionamos el deshacer
      this.revertChangeElement(elementFound, event.target);
    } catch (error) {
      console.error(error);
    }
  }

  // Evento: Gestiona el deshacer un cambio en la celda del resto de filas de la tabla
  revertChange(event) {
    try {
      // Buscamos el elemento modificado
      let elementFound;
      this.tabledata.rows.forEach((row) => {
        let element = row.Cells.find((ele) => ele.Name === event.target.name);
        if (element !== undefined) elementFound = element;
      });

      // Gestionamos el cambio
      this.revertChangeElement(elementFound, event.target);
    } catch (error) {
      console.error(error);
    }
  }

  // Evento: Añade una nueva columna (nuevo plan)
  handleAddNew() {
    try {
      // Añadimos una celda nueva a la cabecera
      let lastElementHeader = this.tabledata.headersNew.Cells[0];
      if (lastElementHeader !== undefined) {
        let newElementHeader = JSON.parse(JSON.stringify(lastElementHeader));
        newElementHeader.Name =
          newElementHeader.Category + this.SEPARATOR + this.newKey;
        newElementHeader.Key = newElementHeader.Name;
        newElementHeader.Id = undefined;
        newElementHeader.isNew = true;
        this.tabledata.headers.Cells.push(newElementHeader);
      }

      // Añadimos una celda nueva a cada fila, clonando la celda vacia que hay preparada
      let rowPos = 0;
      this.tabledata.rows.forEach((row) => {
        let element = this.tabledata.rowsNew[rowPos].Cells[0];
        if (element !== undefined) {
          let newElement = JSON.parse(JSON.stringify(element));
          newElement.Name = newElement.Category + this.SEPARATOR + this.newKey;
          newElement.Key = newElement.Name;
          newElement.hasComparing = false;
          newElement.Id = undefined;
          newElement.isNew = true;
          if (newElement.isNewEditable) newElement.isLocked = false;

          row.Cells.push(newElement);

          rowPos++;
        }
      });

      // Añadimos una celda nueva a al pie (sumatorio)
      let lastElementFooter = this.tabledata.footersNew.Cells[0];
      if (lastElementFooter !== undefined) {
        let newElementFooter = JSON.parse(JSON.stringify(lastElementFooter));
        newElementFooter.Name =
          newElementFooter.Category + this.SEPARATOR + this.newKey;
        newElementFooter.Key = newElementFooter.Name;
        newElementFooter.Id = undefined;
        newElementFooter.isNew = true;
        this.tabledata.footers.Cells.push(newElementFooter);
      }

      // Actualizamos el contador de nuevos planes
      this.newKey++;
      // Actualizamos el contador de planes activos
      this.numActivePlans++;
      // Actualizamos que hay planes
      this.thereArePlans = true;
    } catch (error) {
      console.error(error);
    }
  }

  // Evento: Gestiona la eliminacion de un plan
  handleRemove(event) {
    try {
      // Buscamos el elemento a eliminar
      let found = false;
      let pos = 0;
      while (!found && pos < this.tabledata.headers.Cells.length) {
        if (this.tabledata.headers.Cells[pos].Name === event.target.name) {
          found = true;
        } else {
          pos++;
        }
      }

      // Si lo hemos encontrado...
      if (found) {
        // Si es columna nueva => borrar
        if (this.tabledata.headers.Cells[pos].isNew) {
          this.tabledata.headers.Cells.splice(pos, 1);
          this.tabledata.rows.forEach((row) => {
            row.Cells.splice(pos, 1);
          });
          this.tabledata.footers.Cells.splice(pos, 1);
        } else {
          // Si es columna existente => marcar para borrar cabecera y filas
          this.deletedPlans++;
          this.tabledata.headers.Cells[pos].isDeleted = true;
          this.tabledata.rows.forEach((row) => {
            row.Cells[pos].isDeleted = true;
          });
          this.tabledata.footers.Cells[pos].isDeleted = true;
        }
        // Restamos en uno los planes activos
        this.numActivePlans--;
        // Y comprobamos si queda alguno activo
        if (this.numActivePlans === 0) this.thereArePlans = false;
      }
    } catch (error) {
      console.error(error);
    }
  }

  // Evento: Gestiona la accion de guardado del usuario
  handleSave() {
    if (!this.checkValues()) return;

    this.toggleSaveLabel = this.labels.SDM_PlanAnual_ButtonSaving;

    // Convertirmos el objeto tabledata en string para pasarselo al controller
    let toTabledata = JSON.stringify(this.tabledata);

    saveData({ tabledata: toTabledata })
      .then(() => {
        // Si ha ido bien el proceso de guardado
        this.showSuccess(
          this.labels.SDM_PlanAnual_SavingSuccess,
          this.labels.SDM_PlanAnual_SavingSuccessMessage
        );
        this.getDataRecords(this.yearValue);
        this.error = undefined;
      })
      .catch((error) => {
        // Si ha habido un error
        this.error = error;

        let errorMessage = this.labels.SDM_PlanAnual_SavingErrorMessage;

        if (this.error.body.pageErrors === undefined) {
          errorMessage = this.error.body.message;
        } else if (this.error.body.pageErrors.length > 0) {
          errorMessage = this.error.body.pageErrors[0].message;
        }

        this.showError(this.labels.SDM_PlanAnual_SavingError, errorMessage);
      })
      .finally(() => {
        this.toggleSaveLabel = this.labels.SDM_PlanAnual_ButtonSave;
      });
  }

  // Evento: Gesiona la accion del usuario de hacer click en un enlace para abrir el detalle
  gotoLink(event) {
    try {
      // Recuperamos el Id
      const recId = event.currentTarget.dataset.id;

      // Generamos una URL a la pagina del registro
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: recId,
          actionName: "view"
        }
      });
    } catch (error) {
      console.error(error);
    }
  }

  // Evento: Gestiona el desplegable de cambio de año
  handleChangeYear(event) {
    this.getDataRecords(event.detail.value);
  }

  // Evento: Edita la tabla al hacer doble click en la cabecera o las columnas
  onDoubleClickEdit() {
    this.isEdited = true;
  }

  // Evento: Gestiona la concelacion de los cambios
  handleCancel() {
    // Marcamos como no edicion
    this.isEdited = false;

    // Deshacemos las columnas eliminadas
    this.tabledata.headers.Cells.forEach((cell) => {
      cell.isDeleted = false;
    });

    // Para cada celda de cada fila restauramos los valores originales si fueron modificadas
    this.tabledata.rows.forEach((row) => {
      row.Cells.forEach((cell) => {
        cell.isDeleted = false;
        if (cell.isModified) {
          cell.stringValue = cell.stringValueOld;
          cell.decimalValue = cell.decimalValueOld;
          cell.dateValue = cell.dateValueOld;
          cell.isModified = false;
          cell.HtmlClass = "";
        }
      });
    });
  }

  // Evento: Gestiona la edicion para el boton Editar
  handleEdit() {
    this.isEdited = true;
  }

  // Evento: refresh
  handleRefresh() {
    this.getDataRecords(this.yearValue);
  }

  /*-------------------- RESTO DE METODOS --------------------*/

  // Gestiona los eventos de modificacion de valores y de cambio del tipo de indicador
  // para las celdas con los valores de los planes
  handleChangeElement(elementFound, newElement) {
    try {
      // Si hemos encontrado el elemento
      if (elementFound !== undefined) {
        // Nuevo valor de la celda
        let newValue = newElement.value;

        // Si no es nueva celda, se mira el cambio de valor
        if (!elementFound.isNew) {
          // Valor original
          let actualValueOld = elementFound.stringValueOld;
          if (
            elementFound.isNumber ||
            elementFound.isCurrency ||
            elementFound.isPercent
          )
            actualValueOld = elementFound.decimalValueOld.toString();
          if (elementFound.isDate)
            actualValueOld = elementFound.dateValueOld.toString();
          // Comparamos el valor nuevo con el valor original, si hay cambio se marca como tal y si se ha
          // restaurado se quita la marca de cambio
          if (newValue !== actualValueOld) {
            elementFound.isModified = true;
            elementFound.HtmlClass = this.SLDS_CELL_EDITED_HTML_CLASS;
            let oldValueLabel = actualValueOld;
            if (elementFound.isCombobox) {
              let labelFound = elementFound.combo.options.find(
                (option) => option.value === actualValueOld
              );
              if (labelFound !== undefined) {
                oldValueLabel = labelFound.label;
              }
            }
            elementFound.originalValueDescription =
              this.labels.SDM_PlanAnual_OriginalValue + " " + oldValueLabel;
          } else {
            elementFound.isModified = false;
            elementFound.HtmlClass = "";
            elementFound.originalValueDescription = "";
          }
        }

        // Gestion del cambio de tipo de indicador
        let colindex = newElement.dataset.colindex;
        let rowindex = newElement.dataset.rowindex;

        if (elementFound.Category === this.CATEGORY_INDICATOR) {
          let oldIndicator = elementFound.stringValue;
          let newIndicator = newValue;
          this.handleIndicatorChange(oldIndicator, newIndicator, colindex);
        }

        // Aplicamos el nuevo valor
        if (elementFound.isString || elementFound.isCombobox)
          elementFound.stringValue = newValue;
        if (
          elementFound.isNumber ||
          elementFound.isCurrency ||
          elementFound.isPercent
        )
          elementFound.decimalValue = newValue;
        if (elementFound.isDate) elementFound.dateValue = newValue;

        // Se calcula el sumatorio se es necesario
        this.handleSummary(rowindex, colindex);

        // Se mira si el cambio de valor es en un desplegable controlador
        this.handleDependantChange(
          elementFound.Category,
          newValue,
          colindex,
          false
        );
      }
    } catch (error) {
      console.error(error);
    }
  }

  // Gestiona el deshacer un cambio de una celda
  revertChangeElement(elementFound, newElement) {
    // Si lo hemos encontrado..
    if (elementFound !== undefined) {
      // Gestionamos si es un cambio de tipo de indicador y por tanto de tipo de valores
      let colindex = newElement.dataset.colindex;
      let rowindex = newElement.dataset.rowindex;

      if (elementFound.Category === this.CATEGORY_INDICATOR) {
        let oldIndicator = elementFound.stringValue;
        let newIndicator = elementFound.stringValueOld;
        this.handleIndicatorChange(oldIndicator, newIndicator, colindex);
      }

      // Restauramos los valores originales
      elementFound.stringValue = elementFound.stringValueOld;
      elementFound.decimalValue = elementFound.decimalValueOld;
      elementFound.dateValue = elementFound.dateValueOld;
      elementFound.isModified = false;
      elementFound.HtmlClass = "";
      if (elementFound.isCombobox) {
        let valueFound = elementFound.combo.options.find(
          (option) => option.value === elementFound.stringValue
        );

        if (valueFound === undefined) {
          elementFound.stringValue = elementFound.stringValueDefault;
          elementFound.isModified = true;
          elementFound.HtmlClass = this.SLDS_CELL_EDITED_HTML_CLASS;
        }
      }

      // Se calcula el sumatorio se es necesario
      this.handleSummary(rowindex, colindex);

      // Se mira si el cambio de valor es en un desplegable controlador
      this.handleDependantChange(
        elementFound.Category,
        elementFound.stringValueOld,
        colindex,
        true
      );
    }
  }

  // Gestiona el cambio de tipos de campos de valores al cambiar el Indicador
  handleIndicatorChange(oldIndicator, newIndicator, colindex) {
    let oldType = this.tabledata.mapIndicatorType[oldIndicator];
    let newType = this.tabledata.mapIndicatorType[newIndicator];

    if (oldType !== newType) {
      // A partir de la fila 4 (Plan DT) en adelante
      for (
        let rowNum = this.ROWS_FROM_VALUE;
        rowNum < this.tabledata.rows.length;
        rowNum++
      ) {
        let cell = this.tabledata.rows[rowNum].Cells[colindex];

        cell.isNumber = newType === this.Indicator.type_number;
        cell.isCurrency = newType === this.Indicator.type_currency;
        cell.isPercent = newType === this.Indicator.type_percent;
      }

      // footer
      let cell = this.tabledata.footers.Cells[colindex];
      cell.isNumber = newType === this.Indicator.type_number;
      cell.isCurrency = newType === this.Indicator.type_currency;
      cell.isPercent = newType === this.Indicator.type_percent;
    }
  }

  // Gestiona el calculo del sumatorio si hay cambios en campos de valores
  handleSummary(rowindex, colindex) {
    // Si es una celda de una fila de planes, se informa el sumatorio
    // Filas de RN/Mediadores => sumatorio
    if (rowindex >= this.ROWS_FROM_SUM) {
      let sumValue = 0;
      // Si no se ha modificado la fila de sumatorio
      for (
        let rowNum = this.ROWS_FROM_SUM;
        rowNum < this.tabledata.rows.length;
        rowNum++
      ) {
        if (this.tabledata.rows[rowNum].Cells[colindex].decimalValue !== "") {
          sumValue += parseFloat(
            this.tabledata.rows[rowNum].Cells[colindex].decimalValue
          );
        }
      }
      this.tabledata.footers.Cells[colindex].decimalValue = sumValue;
    }
  }

  // Comprueba y gestiona el cambio de valor en un desplegable controlador
  handleDependantChange(elementCategory, newValue, colindex, isRevert) {
    // Para los desplegables dependientes, si hay cambio en el controlador..
    if (
      this.tabledata.mapDependants !== undefined &&
      this.tabledata.mapDependantCategories !== undefined
    ) {
      // Vemos si existe el campo dependiente del campo controlador
      let dependantCategory = this.tabledata.mapDependantCategories[
        elementCategory
      ];
      // Vemos si existen valores dependientes para el controlador
      let mapDependantValues = this.tabledata.mapDependants[elementCategory];
      // Si tenemos ambos..
      if (mapDependantValues !== undefined && dependantCategory !== undefined) {
        // Recuperamos valores dependientes para el valor controlador
        let mapComboValues = mapDependantValues[newValue];
        if (mapComboValues !== undefined) {
          // Para cada valor dependiente generamos un option de combobox
          let newOptions = [];
          let newKeys = Object.keys(mapComboValues);
          newKeys.forEach((key) => {
            newOptions.push({
              label: mapComboValues[key],
              value: key
            });
          });

          // Buscamos el campo dependiente en la misma columna
          let elementDependant;
          this.tabledata.rows.forEach((row) => {
            if (row.Cells[colindex].Category === dependantCategory) {
              elementDependant = row.Cells[colindex];
            }
          });
          if (elementDependant !== undefined) {
            // Si se ha encontrado el dependiente se actualizan las opciones del desplegable
            elementDependant.combo.options = newOptions;

            if (isRevert) {
              // Restauramos los valores originales tambien del elemento dependiente
              elementDependant.stringValue = elementDependant.stringValueOld;
              // Y las marcas de cambio
              elementDependant.isModified = false;
              elementDependant.HtmlClass = "";
            } else {
              // Si no es deshacer, ponemos el valor por defecto
              elementDependant.stringValue =
                elementDependant.stringValueDefault;
              if (!elementDependant.isNew) {
                // Y marcamos que hay cambio tambien en la dependiente
                elementDependant.isModified = true;
                elementDependant.HtmlClass = this.SLDS_CELL_EDITED_HTML_CLASS;
                // Y tomamos la etiqueta para indicar el valor original
                elementDependant.originalValueDescription =
                  this.labels.SDM_PlanAnual_OriginalValue +
                  " " +
                  elementDependant.stringValueOld;
              }
            }
          }
        }
      }
    }
  }

  // Propiedad: genera la lista de años
  get yearOptions() {
    // El deplegable de año tendra los 2 años anteriores, el año actual y el año siguiente
    let options = [];
    let actualYear = new Date().getFullYear();
    for (let i = actualYear - 2; i <= actualYear + 1; i++) {
      options.push({ label: i, value: i });
    }
    return options;
  }

  // Metodo: muestra un mensaje de error en pantalla
  showError(title, message) {
    this.showMessage("Error", title, message);
  }

  // Metodo: muestra un mensaje de exito en pantalla
  showSuccess(title, message) {
    this.showMessage("success", title, message);
  }

  // Metodo: muestra un mensaje de aviso en pantalla
  showWarning(title, message) {
    this.showMessage("warning", title, message);
  }

  // Metodo: muestra un mensaje en pantalla
  showMessage(variant, title, message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }

  // Metodo: recupera los registros para un año dado
  getDataRecords(year) {
    // Marcamos que se estan obteniendo los datos
    this.isLoading = true;

    // Llamamos al controller
    getRecords({ year: year })
      .then((result) => {
        // Si ha ido todo bien...

        // Convertimos la cadena de texto en un objeto
        this.tabledata = JSON.parse(result);

        // Indicamos si estamos en edicion
        this.isEdited = this.tabledata.isEdited;
        // Indicamos si se pueden crear nuevos
        this.canCreate = this.tabledata.canCreate;
        // Indicamos si se pueden salvar los cambios
        this.canSave = this.tabledata.canSave;
        // Vemos si se han recuperado planes
        this.numActivePlans = 0;
        if (this.tabledata.headers !== undefined) {
          this.numActivePlans = this.tabledata.headers.Cells.length;
          this.thereArePlans = this.tabledata.headers.Cells.length > 0;
        }
        // Por defecto no hay planes eliminados
        this.deletedPlans = 0;
        // Por defecto no hay nuevos planes
        this.newKey = 0;

        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        console.error(error);
      })
      .finally(() => {
        // Establecemos el año en cuestion
        this.yearValue = parseInt(year, 10);
        // Indicamos que se ha terminado de cargar
        this.isLoading = false;
      });
  }

  // Metodo: comprueba que todos los campos del plan se hayan rellenado
  checkValues() {
    // Inicialmente consideramos que todo esta bien
    let result = true;

    try {
      // Miramos si algun campo esta vacio
      let isEmpty = false;

      // Comprobamos las celdas de la fila de cabecera (nombre del plan)
      this.tabledata.headers.Cells.forEach((cell) => {
        if (!isEmpty && cell.stringValue === "") isEmpty = true;
      });

      // Comprobamos las celdas del resto de filas (diferentes parametros del plan)
      if (!isEmpty) {
        // por cada fila
        this.tabledata.rows.forEach((row) => {
          // por cada celda
          row.Cells.forEach((cell) => {
            if (!isEmpty && (cell.isModified || cell.isNew)) {
              if (cell.isString || cell.isCombobox) {
                if (cell.stringValue === "") isEmpty = true;
              } else if (cell.isNumber || cell.isCurrency || cell.isPercent) {
                if (cell.decimalValue === "") isEmpty = true;
              } else if (cell.isDate) {
                if (cell.dateValue === "") isEmpty = true;
              }
            }
          });
        });
      }

      // Si hay un campo vacio enviamos un mensaje de aviso
      if (isEmpty) {
        this.showWarning(
          this.labels.SDM_PlanAnual_ValidationTitle,
          this.labels.SDM_PlanAnual_ValidationMessage
        );
        result = false;
      }
    } catch (error) {
      console.log(error);
      result = false;
    }

    return result;
  }

  // Propiedad: indica si el formulario se esta ejecutando en una pantalla grande
  get isDesktop() {
    return FORM_FACTOR === 'Large';
  }

  // Propiedad: indica si el formulario se esta ejecutando en una pantalla pequeña
  get isPhone() {
      return FORM_FACTOR === 'Small';
  }
}
