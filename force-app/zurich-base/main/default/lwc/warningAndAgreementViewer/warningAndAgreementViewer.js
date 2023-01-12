import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getFields from "@salesforce/apex/WarningAndAgreementViewerController.getFields";
import getWarnings from "@salesforce/apex/WarningAndAgreementViewerController.getWarnings";
import getAgreements from "@salesforce/apex/WarningAndAgreementViewerController.getAgreements";
import getAccountById from "@salesforce/apex/WarningAndAgreementViewerController.getAccountById";
import cancelAgreements from "@salesforce/apex/WarningAndAgreementViewerController.cancelAgreements";
import cancelWarnings from "@salesforce/apex/WarningAndAgreementViewerController.cancelWarnings";
import checkPermission from "@salesforce/apex/WarningAndAgreementViewerController.checkPermission";
import createRelatedAccount from "@salesforce/apex/WarningAndAgreementViewerController.createRelatedAccount";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import WARNING_OBJECT from "@salesforce/schema/CustomerWarning__c";
import AGREEMENT_OBJECT from "@salesforce/schema/Special_Condition__c";

export default class WarningAndAgreementViewer extends LightningElement {
  @api
  salesforceObject;
  @api
  accountType;
  @api
  recordId;
  @api
  title;

  // fields = [NAME_FIELD, ];

  recordsToShow = [];
  showedSize = 0;
  allRecords = [];
  fullListSize = 0;
  account;

  warning;
  hideManagement = true;
  hideTable = false;
  hideShowAll = false;
  showAll;
  warningCreation = false;

  // @wire(getRecord, { recordId: '$recordId', fields: [NATIONAL_ID_FIELD, INTERMEDIARY_CODE_FIELD]})
  // @wire(getWarnings, {record: '$account', salesforceObject: '$salesforceObject', recordType: '$recordId'})
  @wire(getFields, { salesforceObject: "$salesforceObject" })
  columns;
  @wire(getObjectInfo, { objectApiName: WARNING_OBJECT })
  warningInfo;
  @wire(getObjectInfo, { objectApiName: AGREEMENT_OBJECT })
  agreementInfo;

  get iconName() {
    let icon;
    if (this.warning && this.warningInfo.data) {
      icon = this.warningInfo.data.themeInfo;
    } else if (this.agreementInfo.data) {
      icon = this.agreementInfo.data.themeInfo;
    }
    if (icon) {
      const startPosition = icon.iconUrl.indexOf("custom/") + 7;
      let url = "custom:" + icon.iconUrl.substring(startPosition);
      const separation = url.indexOf("_");
      url = url.substring(0, separation);
      return url;
    }
    return undefined;
  }

  get compTitle() {
    if (this.recordsToShow) {
      return this.title + " (" + this.showedSize + ")";
    }
    this.hideTable = true;
    return this.title + " (0)";
  }

  get showAllLabel() {
    if (this.fullListSize !== 0) {
      return "Ver Todos (" + this.fullListSize + ")";
    }
    return "Ver Todos";
  }

  async connectedCallback() {
    this.checkObject();
    let permission = await checkPermission();
    if (permission === true) {
      this.hideManagement = false;
    } else {
      this.hideManagement = true;
    }
    if (this.recordId) {
      this.account = await getAccountById({ accountId: this.recordId });
    }

    if (this.account && this.warning) {
      this.allRecords = await getWarnings({
        record: this.account,
        salesforceObject: this.salesforceObject,
        recordType: this.accountType
      });
    } else if (this.account) {
      this.allRecords = await getAgreements({
        record: this.account,
        salesforceObject: this.salesforceObject
      });
    }

    if (this.allRecords) {
      this.fullListSize = this.allRecords.length;
      if (this.fullListSize === 0) {
        this.hideShowAll = true;
      }

      this.filterActiveRecords();
    }
  }

  checkObject() {
    if (this.salesforceObject === "CustomerWarning__c") {
      this.warning = true;
    } else {
      this.warning = false;
    }
  }

  // renderedCallback() {
  //   console.log("Rendered callback");
  //   this.loadRecords();
  // }

  /**
   * Método que comprueba el icono. Se hace desde el renderedCallback porque
   * en el connectedCallback las variables wire no tienen valor
   * @author jjuaristi@seidor.es
   * @date 11/01/2023
   */
  checkIcon() {
    if (this.warning && this.warningInfo.data) {
      return this.warningInfo.data.themeInfo;
    } else if (this.agreementInfo.data) {
      return this.agreementInfo.data.themeInfo;
    }
    return "icon";
  }

  /**
   * Función que define las columnas a mostrar en el modal
   * @author jjuaristi@seidor.es
   * @date 26/12/2022
   */
  defineColumns(result) {
    result.forEach((field) => {
      this.columns.push({
        label: field.label,
        fieldName: field.fieldName
      });
    });
  }

  /**
   * Método que cancela acuerdos
   * @author jjuaristi@seidor.es
   * @date 10/01/2023
   */
  async disableAgreements() {
    var selectedRecords = this.template
      .querySelector("lightning-datatable")
      .getSelectedRows();
    await cancelAgreements({ agreements: selectedRecords });
    refreshApex(this.connectedCallback());
  }

  /**
   * Método que cancela avisos
   * @author jjuaristi@seidor.es
   * @date 10/01/2023
   */
  async disableWarnings() {
    var selectedRecords = this.template
      .querySelector("lightning-datatable")
      .getSelectedRows();
    await cancelWarnings({ warnings: selectedRecords });
    refreshApex(this.connectedCallback());
  }

  showExpired() {
    this.showAll = true;
  }

  closeModal() {
    this.showAll = false;
    this.warningCreation = false;
  }

  createWarning() {
    this.warningCreation = true;
  }

  async handleCreation(event) {
    const fields = event.detail.fields;
    await createRelatedAccount({
      record: this.account,
      warningNumber: fields.WarningNumber__c.value,
      recordType: this.accountType
    });
    refreshApex(this.connectedCallback());
  }

  filterActiveRecords() {
    let filteredList = [];
    for (let i = 0; i < this.allRecords.length; i++) {
      if (this.allRecords[i].IsActive__c === true) {
        filteredList.push(this.allRecords[i]);
      }
    }
    if (filteredList.length !== 0) {
      this.recordsToShow = filteredList;
      this.showedSize = this.recordsToShow.length;
    } else {
      this.showedSize = 0;
      this.hideTable = true;
    }
  }
}
