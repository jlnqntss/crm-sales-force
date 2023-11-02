import { LightningElement, api, track, wire } from "lwc";
import { publish, MessageContext } from "lightning/messageService";

import getCampaigns from "@salesforce/apex/CampaignZRMCustomPageController.getCampaigns";

import cardTitle from "@salesforce/label/c.ZRM_IntermediaryCampaignList_CardTitle";
import cardIconText from "@salesforce/label/c.ZRM_IntermediaryCampaignList_CardIconText";
import comboboxStatus from "@salesforce/label/c.ZRM_IntermediaryCampaignList_ComboboxStatus";
import comboboxActiveLabel from "@salesforce/label/c.ZRM_IntermediaryCampaignList_ComboboxActiveLabel";
import comboboxInactiveLabel from "@salesforce/label/c.ZRM_IntermediaryCampaignList_ComboboxInactiveLabel";
import tableAriaLabel from "@salesforce/label/c.ZRM_IntermediaryCampaignList_TableAriaLabel";
import thCampaign from "@salesforce/label/c.ZRM_IntermediaryCampaignList_TableHeaderCampaign";
import thStartDate from "@salesforce/label/c.ZRM_IntermediaryCampaignList_TableHeaderStartDate";
import thEndDate from "@salesforce/label/c.ZRM_IntermediaryCampaignList_TableHeaderEndDate";
import thType from "@salesforce/label/c.ZRM_IntermediaryCampaignList_TableHeaderType";
import thBranch from "@salesforce/label/c.ZRM_IntermediaryCampaignList_TableHeaderBranch";
import thAssignedCustomers from "@salesforce/label/c.ZRM_IntermediaryCampaignList_TableHeaderAssignedCustomers";
import thAssignedCustomersCC from "@salesforce/label/c.ZRM_IntermediaryCampaignList_TableHeaderAssignedCustomersCC";
import notRecordsToDisplay from "@salesforce/label/c.DataTable_NoRecords";
import loading from "@salesforce/label/c.LightningSpinnerText";

import INTERMEDIARY_CAMPAIGN_MEMBER_CHANNEL from "@salesforce/messageChannel/IntermediaryCampaignMembers__c";

const comboboxActiveValue = "active";
const comboboxInactiveValue = "inactive";
const comboboxStatusOptions = [
  { label: comboboxActiveLabel, value: comboboxActiveValue },
  { label: comboboxInactiveLabel, value: comboboxInactiveValue }
];

export default class IntermediaryCampaignList extends LightningElement {
  // #region Properties

  @api sendMessage;
  labels = {
    cardTitle,
    cardIconText,
    comboboxStatus,
    comboboxActiveLabel,
    comboboxInactiveLabel,
    tableAriaLabel,
    thCampaign,
    thStartDate,
    thEndDate,
    thType,
    thBranch,
    thAssignedCustomers,
    thAssignedCustomersCC,
    notRecordsToDisplay,
    loading
  };
  comboboxStatusOptions = comboboxStatusOptions;
  comboboxValue = comboboxActiveValue;
  @track campaignsData = {
    isLoading: true,
    [comboboxActiveValue]: undefined,
    [comboboxInactiveValue]: undefined,
    errorFetched: undefined
  };

  get campaigns() {
    return this.campaignsData[this.comboboxValue];
  }

  get isLoading() {
    return this.campaignsData.isLoading;
  }

  get notCampaignsToDisplay() {
    return (
      !this.campaignsData[this.comboboxValue]?.length &&
      !this.campaignsData.isLoading &&
      !this.campaignsData.errorFetched
    );
  }

  @wire(MessageContext)
  messageContext;

  // #endregion

  // #region Lifecyle Hooks

  /**
   * Añade los event listener a cada fila de la tabla si se requiere que el componente
   * se comunique con otros componentes a través de LMS.
   *
   * @author amiranda
   * @date 31/10/2023
   */
  renderedCallback() {
    if (
      this.sendMessage &&
      (this.campaignsData[comboboxActiveValue] ||
        this.campaignsData[comboboxInactiveValue])
    ) {
      this.template
        .querySelectorAll("tbody > tr")
        .forEach((row) =>
          row.addEventListener("click", this.handleRowSelection)
        );
    }
  }

  /**
   * Elimina el event listener de las filas de la tabla
   *
   * @author amiranda
   * @date 31/10/2023
   */
  disconnectedCallback() {
    this.template
      .querySelectorAll("tbody > tr")
      .forEach((row) => row.removeEventListener("click"));
  }

  // #endregion

  // #region Wire methods

  @wire(getCampaigns)
  wiredCampaigns({ data, error }) {
    if (data) {
      this.campaignsData = {
        isLoading: false,
        [comboboxActiveValue]: data.filter((campaign) => campaign.isActive),
        [comboboxInactiveValue]: data.filter((campaign) => !campaign.isActive)
      };
    } else if (error) {
      this.campaignsData = {
        isLoading: false,
        errorFetched: error
      };
    }
  }

  // #endregion

  // #region Event handlers

  /**
   * Función que se encarga de controlar el evento que se produce al cambiar el
   * valor del filtro de estado de la tabla.
   *
   * @author amiranda
   * @date 31/10/2023
   */
  handleStatusChange(event) {
    this.showSpinner();

    if (this.sendMessage) {
      publish(this.messageContext, INTERMEDIARY_CAMPAIGN_MEMBER_CHANNEL, {
        statusRefreshed: true
      });
    }

    // El cambio del filtro de estado es instantáneo. De esta forma emulamos la carga de datos
    setTimeout(() => {
      this.comboboxValue = event.detail.value;
      this.hideSpinner();
    }, 800);
  }

  /**
   * Función que se encarga de controlar el evento que se produce al pulsar sobre
   * una fila de la tabla. Se desmarca la fila que se había marcado previamente
   * (en el caso de que se hubiese marcado) y se comunica al componente que muestra
   * los miembros de campaña relacionaddos con esta tanto al pulsar
   * el botón 'Cancelar' como el botón de cierre de la venta modal. Cierra la ventana
   * modal y limpia las filas seleccionadas de la tabla.
   *
   * @author amiranda
   * @date 18/10/2023
   */
  handleRowSelection = (event) => {
    this.unselectPreviousRow();
    event.currentTarget.setAttribute("data-row-selected", "true");

    /* Se gestiona la comunicación con el componente que muestra los miembros
     * de campaña de una campañá
     */
    let campaignId = event.currentTarget.getAttribute("data-id");
    const message = { statusRefreshed: false, campaignId };
    publish(this.messageContext, INTERMEDIARY_CAMPAIGN_MEMBER_CHANNEL, message);
  };

  // #endregion

  // #region Utility functions

  /**
   * Función que se encarga de desmarcar la fila que se encontraba marcada.
   *
   * @author amiranda
   * @date 31/10/2023
   */
  unselectPreviousRow() {
    let previousSelectedRow = this.template.querySelector(
      "tr[data-row-selected='true'"
    );
    if (previousSelectedRow) {
      previousSelectedRow.setAttribute("data-row-selected", "false");
    }
  }

  // Funciones para controlar la visualización del spinner de carga
  showSpinner = () => (this.campaignsData.isLoading = true);
  hideSpinner = () => (this.campaignsData.isLoading = false);

  // #endregion
}
