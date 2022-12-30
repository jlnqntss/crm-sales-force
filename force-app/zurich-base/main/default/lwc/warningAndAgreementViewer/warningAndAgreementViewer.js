import { LightningElement, api, wire } from "lwc";
import getFields from "@salesforce/apex/WarningAndAgreementViewerController.getFields";
import getWarnings from "@salesforce/apex/WarningAndAgreementViewerController.getWarnings";
import getAccountById from "@salesforce/apex/WarningAndAgreementViewerController.getAccountById";

export default class WarningAndAgreementViewer extends LightningElement {
  @api
  salesforceObject;
  @api
  accountType;
  @api
  recordId;
  @api
  title;

  recordsToShow = [];
  account;

  // @wire(getRecord, { recordId: '$recordId', fields: [NATIONAL_ID_FIELD, INTERMEDIARY_CODE_FIELD]})
  // @wire(getWarnings, {record: '$account', salesforceObject: '$salesforceObject', recordType: '$recordId'})
  @wire(getFields, { salesforceObject: "$salesforceObject" })
  columns;

  async connectedCallback() {
    console.log("Connected callback");
    if (this.recordId) {
      console.log(this.recordId);
      this.account = await getAccountById({ accountId: this.recordId });
    }
    console.log(this.account);

    if (this.account && this.salesforceObject === "CustomerWarning__c") {
      console.log("Entramos al if");
      this.recordsToShow = await getWarnings({
        record: this.account,
        salesforceObject: this.salesforceObject,
        recordType: this.accountType
      });
    }
    // else{
    // Coger en this.recordsToShow los acuerdos para que se muestren los acuerdos
    // Columns se cambia solo con el parámetro salesforceObject
    // }

    console.log(this.recordsToShow);
  }

  renderedCallback() {
    // console.log("rendered callback");
    // console.log(this.account);
    // console.log(this.columns.data);
  }

  /**
   * Función que define las columnas a mostrar en el modal
   * @author jjuaristi@seidor.es
   * @date 26/12/2022
   */
  defineColumns(result) {
    console.log("Columnas");
    result.forEach((field) => {
      if (field.type !== "date") {
        this.columns.push({
          label: field.label,
          fieldName: field.fieldName
        });
      } else {
        console.log(field);
        this.columns.push({
          label: field.label,
          fieldName: field.fieldName
        });
      }
    });
  }
}
