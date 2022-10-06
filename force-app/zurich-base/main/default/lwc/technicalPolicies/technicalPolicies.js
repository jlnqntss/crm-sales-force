/**
 * Librería para manejar los saltos entre step y step de un screen flow desde cualquier LWC
 *
 * @author jjuaristi
 */

import { api, LightningElement, track } from "lwc";
import {
  FlowNavigationNextEvent,
  FlowAttributeChangeEvent
} from "lightning/flowSupport";
import getTechPoliciesForActivities from "@salesforce/apex/RiskAppetiteController.getTechPoliciesForActivities";
import getFields from "@salesforce/apex/RiskAppetiteController.getFields";
import setTechPolicy from "@salesforce/apex/RiskAppetiteController.holdTechPolicy";
import unsetTechPolicy from "@salesforce/apex/RiskAppetiteController.unsetTechPolicy";
import getSetTechPolicies from "@salesforce/apex/RiskAppetiteController.getSetTechPolicies";
import getCaseById from "@salesforce/apex/RiskAppetiteController.getCaseById";

const fieldsToFilter = [
  "UsoExplosivos__c",
  "Espumosos__c",
  "ConAspiracionAutomatica__c",
  "ConRecubrimiento__c",
  "ConPlanchasCombustibles__c",
  "ConFabricacionDeEnvases__c",
  "ConDestilacion__c",
  "ConExistenciaLiquidosInflamables__c",
  "ConFoamizado__c",
  "ConMateriasPlasticasEspumosas__c",
  "ConNitratos__c",
  "ConTapizados__c",
  "ConSecaderoMadera__c"
];

export default class TechnicalPolicies extends LightningElement {
  // Variable to return the nextPage that should be opened
  @api recordId;
  caseRecord;
  labelSetTechPolicyButton = "Fijar Política técnica";
  caseQuery;
  @api desfijadoInput;
  desfijadoTrack;
  booleanMaestroFijado = false;
  maestroFijado;
  @api nextPage = 0;
  nextPageTrack;
  @api value;
  valueTrack;
  @api chosenValue;
  chosenValueTrack;
  @api bunchLabel;
  @api sicLabel;
  @api activityLabel;
  @api sicCode;
  sicCodeTrack = undefined;
  @api productCode;
  productCodeTrack = undefined;
  @api activityCode;
  activityCodeTrack = undefined;

  @api size;
  sizeTrack;
  @api currentCounter;
  currentCounterTrack = 1;
  @api currentRecord;
  currentRecordTrack;
  policies;
  filtersVisible;
  idsInPolicies = [];
  optionsList;

  @track showCheckboxes;
  showExplosives;
  showEspumosos;
  showAspiration;
  showCover;
  showCombustible;
  showContainer;
  showDistillation;
  showFlammable;
  showFoaming;
  showPlasticFoaming;
  showNitrates;
  showUpholstered;
  showWood;

  buttonsClicked = [];

  fieldsToShow = [];
  firstColumnFields = [];
  secondColumnFields = [];

  showAccordion;
  fieldsInAccordion = [];
  firstColumnAccordionFields = [];
  secondColumnAccordionFields = [];

  showModal = false;
  columns = [];

  @api get sicCodeOutput() {
    if (this.sicCodeTrack) {
      return this.sicCodeTrack;
    }
    return this.sicCode;
  }

  @api get bunchCodeOutput() {
    if (this.productCodeTrack) {
      return this.productCodeTrack;
    }
    return this.bunchCode;
  }

  @api get activityCodeOutput() {
    if (this.activityCodeTrack) {
      return this.activityCodeTrack;
    }
    return this.activityCode;
  }

  @api get sicLabelOutput() {
    return this.sicCodeTrack;
  }

  @api get bunchLabelOutput() {
    return this.productCodeTrack;
  }

  @api get activityLabelOutput() {
    return this.activityLabelTrack;
  }

  get sicLabelTrack() {
    if (this.sicCodeTrack) {
      return "SIC: " + this.sicCodeTrack;
    }
    return this.sicLabel;
  }
  get bunchLabelTrack() {
    if (this.productCodeTrack) {
      return "Ramo: " + this.productCodeTrack;
    }
    return this.bunchLabel;
  }
  get activityLabelTrack() {
    if (this.maestroFijado) {
      return (
        "Act. Comercial: " +
        this.activityCodeTrack +
        " - " +
        this.maestroFijado.ObservacionesActividad__c
      );
    }
    return this.activityLabel;
  }

  @api get desfijado() {
    return this.desfijadoTrack;
  }

  get chosenValue() {
    return this.chosenValueTrack;
  }

  get value() {
    return this.valueTrack;
  }

  get nextPage() {
    return this.nextPageTrack;
  }

  get currentCounter() {
    return this.currentCounterTrack;
  }

  get currentRecord() {
    return this.currentRecordTrack;
  }

  get size() {
    if (this.policies) {
      return this.policies.length;
    } else if (this.optionsList) {
      return this.optionsList.length;
    }
    return this.sizeTrack;
  }

  get currentId() {
    let currentId;
    if (this.optionsList) {
      if (!this.policies) {
        // el array policies solo va a estar undefined al principio, así en las n ejecuciones de este getter no se vuelve a lanzar
        this.policies = this.optionsList;
        this.policies.forEach((ele) => {
          this.idsInPolicies.push(ele.Id);
        });
      }
      currentId = this.loadFields();
      return currentId;
    }
    return "";
  }

  /**
   * Función que notifica al flow de que un elemento ha cambiado su valor
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  handleChange(variableName, value) {
    const attributeChangeEvent = new FlowAttributeChangeEvent(
      variableName,
      value
    );
    this.dispatchEvent(attributeChangeEvent);
  }

  /**
   * Función que notifica al flow de que debe avanzar al siguiente elemento
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  moveForward() {
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
  }

  handleSIC() {
    // Si hay una política fijada, no podemos cambiar de página
    if (this.booleanMaestroFijado !== true) {
      this.nextPageTrack = 1;
      this.handleChange("nextPage", this.nextPage);
      this.moveForward();
    }
  }

  handleBunch() {
    // Si hay una política fijada, no podemos cambiar de página
    if (this.booleanMaestroFijado !== true) {
      this.nextPageTrack = 2;
      this.handleChange("nextPage", this.nextPage);
      this.moveForward();
    }
  }

  handleCommercial() {
    // Si hay una política fijada, no podemos cambiar de página
    if (this.booleanMaestroFijado !== true) {
      this.nextPageTrack = 3;
      this.handleChange("nextPage", this.nextPage);
      this.moveForward();
    }
  }

  /**
   * Función que muestra el siguiente elemento en la lista de políticas técnicas
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  moveRight() {
    // Si hemos llegado al último no debe hacer nada
    if (this.currentCounterTrack !== this.sizeTrack) {
      this.currentCounterTrack++;
    }
    this.loadFields();
  }

  /**
   * Función que muestra el anterior elemento en la lista de políticas técnicas
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  moveLeft() {
    // Si estamos en el primero no debe hacer nada
    if (this.currentCounterTrack !== 1) {
      this.currentCounterTrack--;
    }
    this.loadFields();
  }

  /**
   * Función que muestra los filtros
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  handleFilter() {
    if (!this.filtersVisible) {
      this.filtersVisible = true;
      this.loadFilters();
    } else {
      this.filtersVisible = false;
    }
  }

  openModal() {
    // Setting boolean variable to true, this will show the Modal
    this.showModal = true;
  }
  closeModal() {
    // Setting boolean variable to false, this will hide the Modal
    this.showModal = false;
  }

  /**
   * Función que se lanza al llegar al componente, solo una vez
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  async connectedCallback() {
    let currentCase;
    if (this.recordId) {
      // Si tenemos un id recogemos el registro
      currentCase = await getCaseById({ caseId: this.recordId });
    }
    if (currentCase) {
      // Si hemos recogido un caso, cogemos el campo query
      this.caseQuery = currentCase.Query__c;
    }
    if (this.caseQuery && this.desfijadoInput === false) {
      // Si el campo está relleno, y además no se ha borrado en esta misma ejecución, mostramos solo esta política técnica
      this.maestroFijado = await getSetTechPolicies({
        caseQuery: this.caseQuery
      });
      this.sicCodeTrack = this.maestroFijado.SIC__c;
      this.productCodeTrack = this.maestroFijado.CodigoProducto__c;
      this.activityCodeTrack = this.maestroFijado.CodigoActividad__c;
      // Solo mostramos una política, pero debemos recoger el resto de posibles opciones
      // para el mismo sic, ramo y actividad comercial
      this.optionsList = await getTechPoliciesForActivities({
        sicCode: this.sicCodeTrack,
        productCode: this.productCodeTrack,
        activityCode: this.activityCodeTrack
      });
    } else {
      // En cualquier otro caso, mostramos todas las políticas posibles
      this.optionsList = await getTechPoliciesForActivities({
        sicCode: this.sicCode,
        productCode: this.productCode,
        activityCode: this.activityCode
      });
    }

    if (!this.productCodeTrack) {
      this.productCodeTrack = this.productCode;
    }
    // Recogemos los campos a mostrar en función del ramo
    await getFields({ productCode: this.productCodeTrack }).then((result) => {
      result.forEach((field) => {
        if (
          // Separamos los campos de franquicia en el acordeón en caso de existir
          field.fieldName.includes("Franquicia") &&
          !this.fieldsInAccordion.includes(field.fieldName)
        ) {
          this.fieldsInAccordion.push(field.fieldName);
        } else if (
          !this.fieldsToShow.includes(field.fieldName) &&
          !fieldsToFilter.includes(field.fieldName)
        ) {
          this.fieldsToShow.push(field.fieldName);
        }
      });
      this.gridFields();
      this.gridFieldsFranquicia();
      this.checkProductCode();
      this.defineColumns(result);
    });
    if (this.maestroFijado) {
      // Solo se muestra una política, no queremos mostrar filtros ni botones para cambiar de pantalla
      this.booleanMaestroFijado = true;
      this.filtersVisible = false;
      this.policies = [];
      this.policies.push(this.maestroFijado);
      this.showCheckboxes = false;
      this.currentCounterTrack = 1;
    }
  }

  renderedCallback() {
    this.checkPage();
    if (this.productCode === "00516" && this.sizeTrack > 1) {
      this.showCheckboxes = true;
    } else {
      this.showCheckboxes = false;
    }
  }

  checkProductCode() {
    // Para que se muestren los botones de navegación y los filtros, tiene que tener el ramo 516
    if (this.productCode === "00516") {
      this.showCheckboxes = true;
    } else {
      this.showCheckboxes = false;
    }
  }

  checkPage() {
    // Método que muestra o no el botón de fijar/desfijar política técnica
    if (this.recordId) {
      if (this.recordId.startsWith("500")) {
        // Si el id empieza por 500 quiere decir que es un caso
        if (this.caseQuery && this.desfijadoInput === false) {
          this.labelSetTechPolicyButton = "Desfijar Política Técnica";
        } else {
          this.labelSetTechPolicyButton = "Fijar Política Técnica";
        }
        this.caseRecord = true;
      } else {
        this.caseRecord = false;
      }
    }
  }

  /**
   * Función que separa los campos en dos columnas del mismo tamaño
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  gridFields() {
    const size = this.countObjects(this.fieldsToShow);

    let half = size / 2;
    half = half - (half % 1);

    for (let i = 0; i < half; i++) {
      this.firstColumnFields.push(this.fieldsToShow[i]);
    }
    for (let j = half; j < size; j++) {
      this.secondColumnFields.push(this.fieldsToShow[j]);
    }
  }

  /**
   * Función que separa los campos de franquicia en dos columnas del mismo tamaño
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  gridFieldsFranquicia() {
    const size = this.countObjects(this.fieldsInAccordion);

    if (size === 0) {
      this.showAccordion = false;
    } else {
      this.showAccordion = true;
      let half = size / 2;
      half = half - (half % 1);

      for (let i = 0; i < size; i++) {
        if (i < half) {
          this.firstColumnAccordionFields.push(this.fieldsInAccordion[i]);
        } else {
          this.secondColumnAccordionFields.push(this.fieldsInAccordion[i]);
        }
      }
    }
  }

  /**
   * Función que define las columnas a mostrar en el modal
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  defineColumns(result) {
    result.forEach((field) => {
      this.columns.push({
        label: field.label,
        fieldName: field.fieldName,
        type: field.type,
        initialWidth: field.initialWidth,
        wrapText: true
      });
    });
  }

  /**
   * Función que cuenta los elementos de un array de objetos, javascript no permite hacerlo de manera estandar
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  countObjects(object) {
    let size = 0;

    object.forEach((field) => {
      if (field) {
        size++;
      }
    });

    return size;
  }

  /**
   * Función que comprueba qué filtros hay que mostrar
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  loadFilters() {
    // TODO : La idea es pasar todo esto a un array de variables haciendo destructuring, de momento no he conseguido que funcione
    this.showExplosives = this.checkShowField(fieldsToFilter[0]);
    this.showEspumosos = this.checkShowField(fieldsToFilter[1]);
    this.showAspiration = this.checkShowField(fieldsToFilter[2]);
    this.showCover = this.checkShowField(fieldsToFilter[3]);
    this.showCombustible = this.checkShowField(fieldsToFilter[4]);
    this.showContainer = this.checkShowField(fieldsToFilter[5]);
    this.showDistillation = this.checkShowField(fieldsToFilter[6]);
    this.showFlammable = this.checkShowField(fieldsToFilter[7]);
    this.showFoaming = this.checkShowField(fieldsToFilter[8]);
    this.showPlasticFoaming = this.checkShowField(fieldsToFilter[9]);
    this.showNitrates = this.checkShowField(fieldsToFilter[10]);
    this.showUpholstered = this.checkShowField(fieldsToFilter[11]);
    this.showWood = this.checkShowField(fieldsToFilter[12]);
  }

  /**
   * Función que comprueba si se tiene que mostrar un filtro o no
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  checkShowField(field) {
    let show = false;
    if (this.policies) {
      this.policies.forEach((ele) => {
        if (ele[field]) {
          show = true;
        }
      });
    }
    return show;
  }

  /**
   * Función que filtra el array de políticas técnicas en función de lo que ha clickado el usuario
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  filterPolicies(event) {
    const position = event.target.id.split("-")[1];
    this.currentCounterTrack = 1;

    if (event.target.checked) {
      this.buttonsClicked.push(position);
      this.checkField(fieldsToFilter[position]);
    } else {
      this.removePosition(position);
      this.uncheckField(fieldsToFilter[position]);
    }
    this.loadFields();
    this.loadFilters();
  }

  removePosition(positionClicked) {
    const auxPositions = this.buttonsClicked;
    this.buttonsClicked = [];
    auxPositions.forEach((pos) => {
      if (pos !== positionClicked) {
        this.buttonsClicked.push(pos);
      }
    });
  }

  /**
   * Función que se lanza al clickar un filtro, filtra el array que el usuario ve
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  checkField(field) {
    if (this.policies) {
      const auxiliarArray = this.policies;
      this.policies = [];
      this.idsInPolicies = [];

      auxiliarArray.forEach((ele) => {
        if (ele[field]) {
          if (!this.idsInPolicies.includes(ele.Id)) {
            this.policies.push(ele);
            this.idsInPolicies.push(ele.Id);
          }
        }
      });
    }
  }

  /**
   * Función que se lanza al desclickar un filtro, filtra el array que el usuario ve
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  uncheckField(field) {
    if (this.optionsList) {
      this.optionsList.forEach((ele) => {
        if (!ele[field] && this.checkPreviousButtons(ele)) {
          if (!this.idsInPolicies.includes(ele.Id)) {
            this.policies.push(ele);
            this.idsInPolicies.push(ele.Id);
          }
        }
      });
      this.showCheckboxes = true;
    }
  }

  /**
   * Función que comprueba si un botón ya había sido clickado (por posibles errores visuales)
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  checkPreviousButtons(element) {
    let correct = true;
    this.buttonsClicked.forEach((position) => {
      if (!element[fieldsToFilter[position]]) {
        correct = false;
      }
    });
    return correct;
  }

  /**
   * Función que carga la política que se va a mostrar en pantalla
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  loadFields() {
    this.currentRecordTrack = this.policies[this.currentCounterTrack - 1];
    if (this.currentRecordTrack) {
      this.sizeTrack = this.policies.length;
      return this.currentRecordTrack.Id;
    }
    return "";
  }

  /**
   * Función que se lanza al fijar/desfijar una política
   * @author jjuaristi@seidor.es
   * @date 05/10/2022
   */
  holdTechPolicy() {
    if (this.caseQuery && this.desfijadoInput === false) {
      // Desfijar
      unsetTechPolicy({
        caseIdToUpdate: this.recordId
      });
      this.policies = this.optionsList;
      this.sizeTrack = this.policies.length;
      this.caseQuery = undefined;
      this.showCheckboxes = true;
      this.desfijadoTrack = true;
      this.booleanMaestroFijado = false;
    } else {
      // Fijar
      setTechPolicy({
        caseIdToUpdate: this.recordId,
        technicalPolicy: this.currentRecordTrack,
        sicCode: this.sicCode,
        productCode: this.productCode,
        activityCode: this.activityCode,
        fields: fieldsToFilter
      });

      this.filtersVisible = false;
      const auxPolicies = this.policies;
      this.policies = [];

      auxPolicies.forEach((policy) => {
        if (policy.Id === this.currentRecordTrack.Id) {
          this.policies.push(policy);
        }
      });
      this.booleanMaestroFijado = true;
      this.showCheckboxes = false;
      this.caseQuery = "set";
      this.currentCounterTrack = 1;
      this.desfijadoTrack = false;
    }
    this.checkPage();
  }
}
