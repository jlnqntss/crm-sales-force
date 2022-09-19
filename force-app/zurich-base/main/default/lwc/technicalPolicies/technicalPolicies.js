/**
 * Librería para manejar los saltos entre step y step de un screen flow desde cualquier LWC
 *
 * @author jjuaristi
 */

import { api, LightningElement, wire, track } from "lwc";
import {
  FlowNavigationNextEvent,
  FlowAttributeChangeEvent
} from "lightning/flowSupport";
import getTechPoliciesForActivities from "@salesforce/apex/RiskAppetiteController.getTechPoliciesForActivities";
import getFields from "@salesforce/apex/RiskAppetiteController.getFields";

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
  @api productCode;
  @api activityCode;
  @api size;
  sizeTrack;
  @api currentCounter;
  currentCounterTrack = 1;
  @api currentRecord;
  currentRecordTrack;
  policies;
  filtersVisible;
  idsInPolicies = [];

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

  @wire(getTechPoliciesForActivities, {
    sicCode: "$sicCode",
    productCode: "$productCode",
    activityCode: "$activityCode"
  })
  optionsList;

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
    } else if (this.optionsList.data) {
      return this.optionsList.data.length;
    }
    return this.sizeTrack;
  }

  get currentId() {
    let currentId;
    if (this.optionsList.data) {
      if (!this.policies) {
        // el array policies solo va a estar undefined al principio, así en las n ejecuciones de este getter no se vuelve a lanzar
        this.policies = this.optionsList.data;
        this.policies.forEach((ele) => {
          this.idsInPolicies.push(ele.Id);
        });
      }
      currentId = this.loadFields();
      return currentId;
    }
    return "";
  }

  handleChange(variableName, value) {
    const attributeChangeEvent = new FlowAttributeChangeEvent(
      variableName,
      value
    );
    this.dispatchEvent(attributeChangeEvent);
  }

  moveForward() {
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
  }

  handleSIC() {
    this.nextPageTrack = 1;
    this.handleChange("nextPage", this.nextPage);
    this.moveForward();
  }

  handleBunch() {
    this.nextPageTrack = 2;
    this.handleChange("nextPage", this.nextPage);
    this.moveForward();
  }

  handleCommercial() {
    this.nextPageTrack = 3;
    this.handleChange("nextPage", this.nextPage);
    this.moveForward();
  }

  moveRight() {
    if (this.currentCounterTrack !== this.sizeTrack) {
      this.currentCounterTrack++;
    }
    this.loadFields();
  }

  moveLeft() {
    if (this.currentCounterTrack !== 1) {
      this.currentCounterTrack--;
    }
    this.loadFields();
  }

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

  connectedCallback() {
    getFields({ productCode: this.productCode }).then((result) => {
      result.forEach((field) => {
        if (
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
  }

  renderedCallback() {
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

  gridFields() {
    const size = this.countObjects(this.fieldsToShow);

    const half = size / 2;

    for (let i = 0; i < half; i++) {
      this.firstColumnFields.push(this.fieldsToShow[i]);
    }
    for (let j = half; j < size; j++) {
      this.secondColumnFields.push(this.fieldsToShow[j]);
    }
  }

  gridFieldsFranquicia() {
    const size = this.countObjects(this.fieldsInAccordion);

    if (size === 0) {
      this.showAccordion = false;
    } else {
      this.showAccordion = true;
      const half = size / 2;

      for (let i = 0; i < size; i++) {
        if (i < half) {
          this.firstColumnAccordionFields.push(this.fieldsInAccordion[i]);
        } else {
          this.secondColumnAccordionFields.push(this.fieldsInAccordion[i]);
        }
      }
    }
  }

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

  countObjects(object) {
    let size = 0;

    object.forEach((field) => {
      console.log(field);
      size++;
    });

    return size;
  }

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

  uncheckField(field) {
    console.log(this.sizeTrack);
    if (this.optionsList.data) {
      this.optionsList.data.forEach((ele) => {
        if (!ele[field] && this.checkPreviousButtons(ele)) {
          console.log(ele);
          if (!this.idsInPolicies.includes(ele.Id)) {
            console.log("Elemento añadido");
            this.policies.push(ele);
            this.idsInPolicies.push(ele.Id);
          }
        }
      });
      console.log(this.sizeTrack);
      this.showCheckboxes = true;
    }
  }

  checkPreviousButtons(element) {
    let correct = true;
    this.buttonsClicked.forEach((position) => {
      if (!element[fieldsToFilter[position]]) {
        correct = false;
      }
    });
    return correct;
  }

  loadFields() {
    this.currentRecordTrack = this.policies[this.currentCounterTrack - 1];
    if (this.currentRecordTrack) {
      this.sizeTrack = this.policies.length;
      return this.currentRecordTrack.Id;
    }
    return "";
  }
}
