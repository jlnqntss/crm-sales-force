// Bare module imports
import { LightningElement, api, track, wire } from "lwc";
import { publish, MessageContext } from "lightning/messageService";

// "@salesforce/*" imports grouped by type
import getCampaigns from "@salesforce/apex/CampaignZRMCustomPageController.getCampaigns";

import INTERMEDIARY_CAMPAIGN_MEMBER_CHANNEL from "@salesforce/messageChannel/IntermediaryCampaignMembers__c";

// The rest of the relative imports
import labels from "./labels";

const comboboxActiveValue = "active";
const comboboxInactiveValue = "inactive";
const comboboxStatusOptions = [
  { label: labels.comboboxActiveLabel, value: comboboxActiveValue },
  { label: labels.comboboxInactiveLabel, value: comboboxInactiveValue }
];

export default class IntermediaryCampaignList extends LightningElement {
  // #region Exposed properties using the @api decorator

  @api sendMessage;

  // #endregion

  // #region Reactive field using @track decorator

  @track campaignsData = {
    isLoading: true,
    [comboboxActiveValue]: undefined,
    [comboboxInactiveValue]: undefined,
    errorFetched: undefined
  };

  // #endregion

  // #region Other properties
  labels = labels;
  comboboxStatusOptions = comboboxStatusOptions;
  comboboxValue = comboboxActiveValue;

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

  // #endregion

  // #region LWC lifecycle hooks

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

  // #region Wire field

  @wire(MessageContext)
  messageContext;

  // #endregion

  // #region Wire functions

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
    this.comboboxValue = event.detail.value;

    if (this.sendMessage) {
      publish(this.messageContext, INTERMEDIARY_CAMPAIGN_MEMBER_CHANNEL, {
        statusRefreshed: true,
        campaignStatus: this.comboboxValue
      });
    }

    // El cambio del filtro de estado es instantáneo. De esta forma emulamos la carga de datos
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setTimeout(() => {
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
    let campaignStartDate = event.currentTarget.querySelector(
      `td[data-labels="${this.labels.thStartDate}"] > div`
    ).textContent;
    let campaignType = event.currentTarget.querySelector(
      `td[data-labels="${this.labels.thType}"] > div`
    ).textContent;
    const message = {
      statusRefreshed: false,
      campaignStatus: this.comboboxValue,
      campaignId,
      campaignStartDate,
      campaignType
    };
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
