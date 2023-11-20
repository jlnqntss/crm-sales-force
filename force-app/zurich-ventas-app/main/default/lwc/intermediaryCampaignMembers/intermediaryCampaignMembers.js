// Bare module imports
import { LightningElement, wire, track } from "lwc";
import { deleteRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import {
  subscribe,
  unsubscribe,
  MessageContext
} from "lightning/messageService";

// "@salesforce/*" imports grouped by type
import INTERMEDIARY_CAMPAIGN_MEMBER_CHANNEL from "@salesforce/messageChannel/IntermediaryCampaignMembers__c";

import { refreshApex } from "@salesforce/apex";
import getCampaignMembers from "@salesforce/apex/CampaignZRMCustomPageController.getCampaignMembers";

// The rest of the relative imports
import labels from "./labels";
import columns from "./columns";

const ERROR_VARIANT = "error";
const SUCCESS_VARIANT = "success";
const campaignStatusFilterActiveValue = "active";
const filterDefaultValue = "all";
const rowActions = {
  remove: "remove"
};

export default class DatatableWithRowActions extends LightningElement {
  // #region Reactive field using @track decorator

  @track campaignMembersRawData;
  @track campaignMembersData = {
    isLoading: false,
    data: undefined,
    errorFetched: undefined
  };
  @track campaignData = {
    campaignFilter: undefined,
    campaignType: undefined,
    campaignStartDate: undefined,
    campaignStatushRefreshed: undefined
  };
  @track columns = columns;

  // #endregion

  // #region Other properties
  labels = labels;
  subscription;
  campaignId;
  _wiredCampaignsMembers;
  campaignStartDate;
  headersFilters = {
    cmStatus: filterDefaultValue,
    offerStage: filterDefaultValue
  };

  get showAddCampaignMemberButton() {
    return (
      this.campaignId &&
      this.campaignData.campaignFilter === campaignStatusFilterActiveValue
    );
  }

  get noRecordsToDisplay() {
    return !this.campaignMembersData.data?.length;
  }

  get noCampaignSelected() {
    return !this.campaignId;
  }

  get messageToDisplay() {
    return (
      !this.campaignData.isLoading &&
      (this.noRecordsToDisplay || this.noCampaignSelected)
    );
  }

  // #endregion

  // #region LWC lifecycle hooks

  connectedCallback() {
    this.subscribeToMessageChannel();
    this.columns = [...columns].filter(
      (col) => col.fieldName !== "offerSalesLossReasonLabel"
    );
  }

  disconnectedCallback() {
    this.unsubscribeToMessageChannel();
  }

  // #endregion

  // #region Wire fields

  @wire(MessageContext)
  messageContext;

  // #endregion

  // #region Wire functions

  @wire(getCampaignMembers, { campaignId: "$campaignId" })
  wiredCampaignMembers(result) {
    this._wiredCampaignsMembers = result;
    const { data, error } = result;

    if (data) {
      this.campaignMembersRawData = data;
      this.campaignMembersData = {
        isLoading: false,
        data
      };
      if (this.campaignMembersRawData?.length) {
        this.enableHeaderActions();
      }
    } else if (error) {
      this.campaignMembersData = {
        isLoading: false,
        errorFetched: error
      };
    }
  }

  // #endregion

  // #region Event handlers

  /**
   * Función que se encarga de controlar el evento que se produce al pulsar sobre
   * algunas de las acciones que se muestran en un desplegable en la última columna
   * de la tabla.
   *
   * @author amiranda
   * @date 20/11/2023
   */
  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    if (actionName === rowActions.remove) {
      this.deleteCampaignMember(row);
    }
  }

  /**
   * Función que se encarga de controlar el evento que se produce al pulsar sobre
   * algún elemento de la lista desplegable que se muestra en aquellos encabezados
   * de la tabla que la tienen habilitada. Estos elementos se utilizan para filtrar
   * los dtos que se muestran en la tabla.
   *
   * @author amiranda
   * @date 20/11/2023
   */
  handleHeaderAction(event) {
    // Se recoge la información sobre la columna que se está filtrando
    const colDef = event.detail.columnDefinition;
    const actionName = event.detail.action.name;
    const selectedHeader = colDef.fieldName;

    if (actionName !== this.headersFilters[selectedHeader]) {
      this.checkHeaderAction(selectedHeader, actionName);

      // Se actualiza el filtro
      this.headersFilters[selectedHeader] = actionName;
      this.filterCampaignMembers();
    }
  }

  /**
   * Función que se encarga de controlar el evento que se lanza en el componente
   * hijo 'IntermAddCampaignMember' para 'avisar' de que se ha añadido un nuevo
   * miembro de campaña. De este modo, se refresca la caché para que se actualicen
   * los datos que se han de mostrar en la tabla.
   *
   * @author amiranda
   * @date 20/11/2023
   */
  handleAddingCampaingMembers() {
    return refreshApex(this._wiredCampaignsMembers);
  }

  // #endregion

  handleMessage(message) {
    this.campaignId = message.campaignId;
    this.campaignData.campaignFilter = message.campaignStatus;
    this.campaignData.campaignStartDate = message.campaignStartDate;
    this.campaignData.campaignType = message.campaignType;

    // Al seleccionar una campaña se debe mostrar el spinner
    if (this.campaignId) this.showSpinner();

    let today = new Date();
    let cols = this.columns;

    if (this.campaignData.campaignFilter === campaignStatusFilterActiveValue) {
      // Se elimina la columna que no debe mostrarse para los miembros de campaña relacionados con campañas activas
      cols = [
        ...columns.filter(
          (col) => col.fieldName !== "offerSalesLossReasonLabel"
        )
      ];
      if (today < new Date(this.campaignData.campaignStartDate)) {
        cols = [
          ...cols,
          {
            type: "action",
            typeAttributes: { rowActions: this.getRowActions }
          }
        ];
      }
    } else {
      cols = [...columns];
    }

    this.columns = JSON.parse(JSON.stringify(cols));

    /* Si se ha cambiado el filtro de estado entra campañas activas/inactivas
     * se vacía el contenido de la tabla para que no se muestre ningún dato
     * hasta seleccionar una nueva campaña
     */
    if (message.statusRefreshed) this.emptyTableData();
  }

  /**
   * Función que se encarga de marcar visualmente en el encabezado que corresponda
   * el filtro que se ha seleccionado.
   *
   * @author amiranda
   * @date 20/11/2023
   */
  checkHeaderAction(selectedHeader, actionName) {
    let cols = this.columns;
    cols.forEach((col) => {
      if (col.fieldName === selectedHeader) {
        col.actions.forEach(
          (action) => (action.checked = action.name === actionName)
        );
      }
    });

    this.reconfigureTableCols(cols);
  }

  /**
   * Función que se encarga de habilitar las acciones (en este caso son filtros)
   * a nivel de encabezados de la tabla.
   *
   * @author amiranda
   * @date 20/11/2023
   */
  enableHeaderActions() {
    let cols = this.columns;
    cols.forEach((col) => {
      col.actions?.forEach((action) => {
        action.checked = action.name === "all";
        action.disabled = false;
      });
    });

    this.reconfigureTableCols(cols);
  }

  /**
   * Función que se encarga de eliminar y volver a añadir la columna de acciones.
   * Es necesario llevar a cabo este proceso por un problema que existe que se
   * encuentra documentado en GitHub -> https://github.com/salesforce/lwc/issues/1616
   *
   * @author amiranda
   * @date 20/11/2023
   */
  reconfigureTableCols(cols) {
    if (cols.some((col) => col.type === "action")) {
      cols = [
        ...cols.filter((col) => col.type !== "action"),
        {
          type: "action",
          typeAttributes: { rowActions: this.getRowActions }
        }
      ];

      this.columns = cols;
    } else {
      this.columns = JSON.parse(JSON.stringify(cols));
    }
  }

  // #region Utility functions

  async deleteCampaignMember(row) {
    this.showSpinner();
    try {
      if (this.campaignData.campaignType !== "Venta Cruzada") {
        this.showError(
          labels.toastGenericErrorTitle,
          labels.toastOngoingCampaignErrorMessage
        );
      } else {
        await deleteRecord(row.cmId);
        this.deleteRow(row);
        this.showSuccess(
          labels.toastDeleteRowActionTitle,
          row.cmName + " " + labels.toastDeleteRowActionMessage
        );
      }
    } catch (error) {
      this.showError(
        labels.toastGenericErrorTitle,
        labels.toastGenericErrorMessage
      );
    } finally {
      this.hideSpinner();
    }
  }

  deleteRow(row) {
    const { id } = row;
    const index = this.findRowIndexById(id);
    if (index !== -1) {
      this.campaignMembersRawData = this.campaignMembersRawData
        .slice(0, index)
        .concat(this.campaignMembersRawData.slice(index + 1));
    }

    /*
     * Después de eliminar el miembro de campaña del array que contiene los datos
     * en bruto es necesario volver a aplicar los filtros
     */
    this.filterCampaignMembers();
  }

  findRowIndexById(id) {
    let ret = -1;
    this.campaignMembersRawData.some((row, index) => {
      if (row.id === id) {
        ret = index;
        return true;
      }
      return false;
    });
    return ret;
  }

  /**
   * Función que se encarga de filtrar los miembros de campaña a mostrar en la tabla
   * en función de los filtros seleccionados.
   *
   * @author amiranda
   * @date 20/11/2023
   */
  filterCampaignMembers() {
    let filteredCampaigns = this.campaignMembersRawData;

    for (const [field, activeFilter] of Object.entries(this.headersFilters)) {
      if (activeFilter !== "all") {
        filteredCampaigns = filteredCampaigns.filter(
          (campaign) => campaign[field] === activeFilter
        );
      }
    }

    this.campaignMembersData.data = filteredCampaigns;
  }

  /**
   * Función que vacía los datos de la tabla.
   *
   * @author amiranda
   * @date 16/11/2023
   */
  emptyTableData() {
    this.campaignMembersData.data = null;
  }

  getRowActions = (row, doneCallBack) => {
    const actions = [
      { label: labels.removeRowAction, name: rowActions.remove }
    ];

    doneCallBack(actions);
  };

  // Encapsulate logic for Lightning message service subscribe and unsubsubscribe
  subscribeToMessageChannel() {
    if (!this.subscription) {
      this.subscription = subscribe(
        this.messageContext,
        INTERMEDIARY_CAMPAIGN_MEMBER_CHANNEL,
        (message) => this.handleMessage(message)
      );
    }
  }

  unsubscribeToMessageChannel() {
    unsubscribe(this.subscription);
    this.subscription = null;
  }

  showSpinner = () => (this.campaignMembersData.isLoading = true);

  hideSpinner = () => (this.campaignMembersData.isLoading = false);

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
