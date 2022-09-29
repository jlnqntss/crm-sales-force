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
  sicCodeTrack;
  @api productCode;
  productCodeTrack;
  @api activityCode;
  activityCodeTrack;

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
    if (this.caseQuery && this.sicCodeTrack) {
      return this.sicCodeTrack;
    }
    return this.sicCode;
  }

  @api get bunchCodeOutput() {
    if (this.caseQuery && this.productCodeTrack) {
      return this.productCodeTrack;
    }
    return this.bunchCode;
  }

  @api get activityCodeOutput() {
    if (this.caseQuery && this.activityCodeTrack) {
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
    if (this.caseQuery && this.sicCodeTrack) {
      return "SIC: " + this.sicCodeTrack;
    }
    return this.sicLabel;
  }
  get bunchLabelTrack() {
    if (this.caseQuery && this.productCodeTrack) {
      return "Ramo: " + this.productCodeTrack;
    }
    return this.bunchLabel;
  }
  get activityLabelTrack() {
    if (this.caseQuery && this.maestroFijado) {
      return (
        "Act. Comercial: " +
        this.activityCodeTrack +
        " - " +
        this.maestroFijado.ObservacionesActividad__c
      );
    }
    return this.activityLabel;
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

  async connectedCallback() {
    console.log("ConnectedCallback");
    let currentCase;
    if (this.recordId) {
      currentCase = await getCaseById({ caseId: this.recordId });
    }
    if (currentCase) {
      this.caseQuery = currentCase.Query__c;
    }
    if (this.caseQuery) {
      this.maestroFijado = await getSetTechPolicies({
        caseQuery: this.caseQuery
      });
      this.sicCodeTrack = this.maestroFijado.SIC__c;
      this.productCodeTrack = this.maestroFijado.CodigoProducto__c;
      this.activityCodeTrack = this.maestroFijado.CodigoActividad__c;
      this.optionsList = await getTechPoliciesForActivities({
        sicCode: this.sicCodeTrack,
        productCode: this.productCodeTrack,
        activityCode: this.activityCodeTrack
      });
    } else {
      console.log("Entramos a cargar optionsList en el else");
      this.optionsList = await getTechPoliciesForActivities({
        sicCode: this.sicCode,
        productCode: this.productCode,
        activityCode: this.activityCode
      });
      console.log(this.optionsList);
    }

    await getFields({ productCode: this.productCode }).then((result) => {
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
    if (this.maestroFijado) {
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
    if (this.recordId) {
      if (this.recordId.startsWith("500")) {
        if (this.caseQuery) {
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
      //console.log(field);
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

  holdTechPolicy() {
    if (this.caseQuery) {
      unsetTechPolicy({
        caseIdToUpdate: this.recordId
      });
      this.policies = this.optionsList;
      this.sizeTrack = this.policies.length;
      this.caseQuery = undefined;
      this.showCheckboxes = true;
    } else {
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
        if (policy.Id == this.currentRecordTrack.Id) {
          this.policies.push(policy);
        }
      });
      this.showCheckboxes = false;
      this.caseQuery = "set";
      this.currentCounterTrack = 1;
    }
    this.checkPage();
  }
}
