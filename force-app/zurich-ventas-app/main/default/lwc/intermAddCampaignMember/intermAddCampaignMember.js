// Bare module imports
import { LightningElement, api, wire } from "lwc";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// "@salesforce/*" imports grouped by type
import { refreshApex } from "@salesforce/apex";
import getContacts from "@salesforce/apex/IntermAddCampaignMemberController.getContacts";
import insertCampaignMembers from "@salesforce/apex/IntermAddCampaignMemberController.insertCampaignMembers";

import CAMPAIGN_NAME from "@salesforce/schema/Campaign.Name";
import CAMPAIGN_TYPE from "@salesforce/schema/Campaign.Type";
import CAMPAIGN_ISACTIVE from "@salesforce/schema/Campaign.IsActive";
import CAMPAIGN_ENDDATE from "@salesforce/schema/Campaign.EndDate";

// The rest of the reelative imports
import labels from "./labels";

const CAMPAIGN_FIELDS = [
  CAMPAIGN_NAME,
  CAMPAIGN_TYPE,
  CAMPAIGN_ISACTIVE,
  CAMPAIGN_ENDDATE
];
const ERROR_VARIANT = "error";
const SUCCESS_VARIANT = "success";
const VALID_CAMPAIGN_TYPE = "Cross Selling";
const columns = [
  { label: "Nombre", fieldName: "AccountName" },
  { label: "Código de Filiación", fieldName: "IntermediaryCode" },
  { label: "Documento de Identidad", fieldName: "NationalId" },
  { label: "Tipo de Registro de Cuenta", fieldName: "RecordTypeName" }
];

/**
 * Componente para añádir nuevos miembros de campañana a una campaña desde
 * la comunidad ZRM.
 *
 * @author amiranda
 **/
export default class IntermAddCampaignMember extends LightningElement {
  // #region Exposed properties using the @api decorator
  @api campaignId;
  @api intermediaryCode;

  // #endregion

  // #region Other properties
  label = labels;
  columns = columns;
  campaign;
  userInfo;
  _wiredContacts;
  error;
  selectedRows = [];
  isLoading = true;
  showModal;
  queryTerm;
  filteredAccounts;
  accounts;

  get addCampaignMembersButtonDisabled() {
    return !this.selectedRows?.length;
  }

  get campaignName() {
    return getFieldValue(this.campaign, CAMPAIGN_NAME);
  }

  get campaignType() {
    return getFieldValue(this.campaign, CAMPAIGN_TYPE);
  }

  get campaignIsActive() {
    return getFieldValue(this.campaign, CAMPAIGN_ISACTIVE);
  }

  get campaignEndDate() {
    let campaignEndDate = getFieldValue(this.campaign, CAMPAIGN_ENDDATE);

    if (campaignEndDate) {
      campaignEndDate = new Date(
        new Date(
          campaignEndDate.slice(0, 4),
          campaignEndDate.slice(5, 7) - 1,
          campaignEndDate.slice(8, 10)
        ).toDateString()
      );
    }

    return campaignEndDate;
  }

  get recordsToDisplay() {
    return !this.filteredAccounts?.length;
  }

  get wiredErrors() {
    return this.error;
  }

  // Devuelve un array de Ids de las filas seleccionadas
  get selectedRowIds() {
    return this.selectedRows.map((row) => row.Id);
  }

  @api
  getFilteredAccounts() {
    return this.filteredAccounts;
  }

  // #endregion

  // #region Wire functions

  @wire(getRecord, {
    recordId: "$campaignId",
    fields: CAMPAIGN_FIELDS
  })
  wiredCampaign({ data, error }) {
    if (data) {
      this.campaign = data;
    } else if (error) {
      this.error = error;
    }
  }

  @wire(getContacts, { campaignId: "$campaignId" })
  wiredContacts(result) {
    this._wiredContacts = result;
    const { data, error } = result;
    if (data) {
      this.accounts = data.map((field) => ({
        Id: field.Id,
        AccountName: field.Account.Name,
        IntermediaryCode: field.Account.INFOCustomerNumber__c,
        NationalId: field.Account.NationalId__c,
        RecordTypeName: field.Account.RecordType__c
      }));
      this.filteredAccounts = this.accounts;
      this.hideSpinner();
    } else if (error) {
      this.error = error;
      this.hideSpinner();
    }
  }

  // #endregion

  // #region Event handlers

  /**
   * Función que se encarga de controlar el evento del botón 'Añadir miembro'.
   * Antes de abrir la ventana modal, comprueba que no se ha producido ningún error
   * al recuperar registros de la base de dtos y que la campaña es valida según los
   * criterios fijados para poder añadir nuevos miembros de campaña.
   *
   * @author amiranda
   * @date 18/10/2023
   */
  handleAddMembers() {
    if (this.wiredErrors) {
      this.showError(
        this.label.toastGeneriErrorTitle,
        this.label.toastGenericErrorMessage
      );
    } else if (!this.isValidCampaign()) {
      this.showError(
        this.label.notAllowedActionToastTitle,
        this.label.notValidCampaignToastMessage
      );
    } else {
      this.openModal();
    }
  }

  /**
   * Función que se encarga de controlar el evento teclear en el campo input de búsqueda.
   * Coteja el texto incluido con el nombre de cuenta y el documento de identidad.
   *
   * @author jlnavarroq
   * @date 05/11/2024
   */
  handleSearchChange(evt) {
    this.queryTerm = evt.target.value.toLowerCase();
    this.filteredAccounts = this.accounts.filter((account) =>
      (account.AccountName + account.NationalId)
        .toLowerCase()
        .includes(this.queryTerm)
    );
  }

  /**
   * Función que se encarga de controlar el evento al pulsar el check de cualquier
   * fila de la tabla. Al pulsar una fila, se actualiza la propiedad que contiene
   * las filas seleccionadas de la tabla.
   *
   * @author amiranda
   * @date 18/10/2023
   */
  handleRowSelection(event) {
    const selectedRowsInView = event.detail.selectedRows;
    const selectedRowsMap = new Map(
      this.selectedRows.map((row) => [row.Id, row])
    );
    const selectedIdsInView = new Set(selectedRowsInView.map((row) => row.Id));

    this.filteredAccounts.forEach((row) => {
      if (selectedIdsInView.has(row.Id)) {
        selectedRowsMap.set(row.Id, row); // Mantener seleccionadas
      } else {
        selectedRowsMap.delete(row.Id); // Quitar desmarcadas
      }
    });

    this.selectedRows = Array.from(selectedRowsMap.values());
  }

  async handleAddCampaignMembers() {
    // Si se ha seleccionado alguna cuenta
    if (this.selectedRows?.length) {
      this.showSpinner();
      const campaignMembers = [];

      /*
       * El elemento que contendrán las filas de la tabla que se muestra en el
       * LWC no será una cuenta, sino un contacto. Por lo tanto, cuando el usuario
       * seleccioneel registro, a pesar de que aparentemente parezca una cuenta
       * estará seleccionando el contacto con el que se relacionará el miembro de campaña.
       */
      this.selectedRows.forEach((selectedRow) => {
        const campaignMember = {
          CampaignId: this.campaignId,
          ContactId: selectedRow.Id,
          Status: "Gestión Mediador",
          OfferAssignedType__c: "M",
          OfferAssignedCode__c: this.intermediaryCode
        };

        campaignMembers.push(campaignMember);
      });

      await insertCampaignMembers({ campaignMembers })
        .then(() => {
          this.showSuccess(
            this.campaignName + " " + this.label.addCampMembToastSuccessTitle,
            this.label.addCampMembToastSuccessMessage + " " + this.campaignName
          );

          /*
           * Se refresca la cache de las cuentas para que en la siguiente pulsación
           * del botón que carga la ventana modal con la tabla muestre los datos actualizados.
           */
          refreshApex(this._wiredContacts);

          /*
           * Se 'lanza' un evento para que sea capturado por el componente padre.
           * Se utiliza para refrescar la cache de los datos provisionados por 'Apex @wire'
           */
          this.dispatchEvent(new CustomEvent("update"));
        })
        .catch(() =>
          this.showError(
            this.label.addCampMembToastErrorTitle,
            this.label.addCampMembToastErrorMessage
          )
        );

      this.hideSpinner();
    }

    this.closeModal();
  }

  /**
   * Función que se encarga de controlar el evento que se produce tanto al pulsar
   * el botón 'Cancelar' como el botón de cierre de la venta modal. Cierra la ventana
   * modal y limpia las filas seleccionadas de la tabla.
   *
   * @author amiranda
   * @date 18/10/2023
   */
  handleCancel() {
    this.closeModal();
    this.clearSearch();
  }

  // #endregion

  // #region Utility functions

  /**
   * Función que retorna si una campaña es válida en funión a los siguientes criterios:
   * 1. Esté activa
   * 2. La fecha de finalización en la campaña esté informada
   * 2. La fecha de finalización sea posterior al día de hoy
   * 3. El tipo de campaña sea 'Cross Selling'
   *
   * @author amiranda
   * @date 18/10/2023
   */
  isValidCampaign() {
    return (
      this.campaignIsActive &&
      this.campaignEndDate &&
      new Date(new Date().toDateString()) < this.campaignEndDate &&
      this.campaignType === VALID_CAMPAIGN_TYPE
    );
  }

  showSpinner() {
    this.isLoading = true;
  }

  hideSpinner() {
    this.isLoading = false;
  }

  openModal() {
    this.showModal = true;
  }

  closeModal() {
    this.showModal = false;
    this.selectedRows = [];
  }

  clearSearch() {
    this.queryTerm = "";
    this.selectedRows = [];
    this.filteredAccounts = this.accounts;
  }

  showError(title, message) {
    this.showMessage(title, message, ERROR_VARIANT);
  }

  showSuccess(title, message) {
    this.showMessage(title, message, SUCCESS_VARIANT);
  }

  showMessage(title, text, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: text,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  // #endregion
}
