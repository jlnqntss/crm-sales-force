import { LightningElement, api, track } from "lwc";
import {
  createRecord,
  deleteRecord,
  updateRecord
} from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";

import userId from "@salesforce/user/Id";
import CONTENTVERSION_OBJECT from "@salesforce/schema/ContentVersion";
import CONTENTVERSION_ID from "@salesforce/schema/ContentVersion.Id";
import CONTENTVERSION_CONTENTURL from "@salesforce/schema/ContentVersion.ContentUrl";
import CONTENTVERSION_FIRSTPUBLISHLOCATIONID from "@salesforce/schema/ContentVersion.FirstPublishLocationId";
import CONTENTVERSION_TITLE from "@salesforce/schema/ContentVersion.Title";
import CONTENTDOCUMENT_ID from "@salesforce/schema/ContentDocument.Id";
import CONTENTDOCUMENT_OWNER_ID from "@salesforce/schema/ContentDocument.OwnerId";

import getLibraryId from "@salesforce/apex/UsefulLinksController.getLibraryId";
import getLinks from "@salesforce/apex/UsefulLinksController.getLinks";
import getPermissionType from "@salesforce/apex/UsefulLinksController.getContentWorkspacePermissionType";

import titleCard from "@salesforce/label/c.SDM_LinksInteres_Title";
import viewAll from "@salesforce/label/c.SDM_LinksInteres_ViewAll";
import newLinkButton from "@salesforce/label/c.SDM_LinksInteres_NewLink";
import editLinkButton from "@salesforce/label/c.SDM_LinksInteres_EditLinkButton";
import deleteLinkButton from "@salesforce/label/c.SDM_LinksInteres_DeleteButton";
import newLinkButtonTitle from "@salesforce/label/c.SDM_LinksInteres_NewLinkButtonTitle";
import newLinkModalHeader from "@salesforce/label/c.SDM_LinksInteres_NewLinkModalHeader";
import editLinkModalHeader from "@salesforce/label/c.SDM_LinksInteres_EditLinkModalHeader";
import inputText from "@salesforce/label/c.SDM_LinksInteres_InputText";
import inputTextPlaceholder from "@salesforce/label/c.SDM_LinksInteres_InputTextPlaceholder";
import inputUrl from "@salesforce/label/c.SDM_LinksInteres_InputUrl";
import inputUrlPlaceholder from "@salesforce/label/c.SDM_LinksInteres_InputUrlPlaceHolder";
import saveButton from "@salesforce/label/c.SDM_LinksInteres_ButtonSave";
import saveButtonTitle from "@salesforce/label/c.SDM_LinksInteres_SaveButtonTitle";
import cancelButton from "@salesforce/label/c.SDM_LinksInteres_ButtonCancel";
import cancelButtonTitle from "@salesforce/label/c.SDM_LinksInteres_CancelButtonTitle";
import confirmDeletionMessage from "@salesforce/label/c.SDM_LinksInteres_ConfirmDeletionMessage";
import confirmDeletionLabel from "@salesforce/label/c.SDM_LinksInteres_ConfirmDeletionLabel";
import toastSuccessTitle from "@salesforce/label/c.SDM_LinksInteres_ToastSuccessTitle";
import toastErrorTitle from "@salesforce/label/c.SDM_LinksInteres_ToastErrorTitle";
import toastSuccessCreateMessage from "@salesforce/label/c.SDM_LinksInteres_ToastSuccessCreateMessage";
import toastSuccessUpdateMessage from "@salesforce/label/c.SDM_LinksInteres_ToastSuccessUpdateMessage";
import toastSuccessDeleteMessage from "@salesforce/label/c.SDM_LinksInteres_ToastSuccessDeleteMessage";
import toastErrorCreateMessage from "@salesforce/label/c.SDM_LinksInteres_ToastErrorCreateMessage";
import toastErrorUpdateMessage from "@salesforce/label/c.SDM_LinksInteres_ToastErrorUpdateMessage";
import toastErrorDeleteMessage from "@salesforce/label/c.SDM_LinksInteres_ToastErrorDeleteMessage";
import errorLoadingDataText from "@salesforce/label/c.SDM_LinksInteres_ErrorLoadingDataText";
import noDataToDisplayText from "@salesforce/label/c.SDM_LinksInteres_NoDataToDisplayText";
import loadingText from "@salesforce/label/c.SDM_LinksInteres_Loading";
import lightningIconLinkAlternativeText from "@salesforce/label/c.SDM_LinksInteres_LightningIconLinkAlternativeText";

const ERROR_VARIANT = "error";
const SUCCESS_VARIANT = "success";
const ContentWorkspacePerm = {
  Viewer: "Viewer",
  Author: "Author",
  Admin: "Admin"
};

export default class UsefulLinks extends NavigationMixin(LightningElement) {
  //#region Variables
  label = {
    titleCard,
    viewAll,
    newLinkButton,
    editLinkButton,
    deleteLinkButton,
    newLinkButtonTitle,
    newLinkModalHeader,
    editLinkModalHeader,
    inputText,
    inputTextPlaceholder,
    inputUrl,
    inputUrlPlaceholder,
    saveButton,
    saveButtonTitle,
    cancelButton,
    cancelButtonTitle,
    confirmDeletionMessage,
    confirmDeletionLabel,
    toastSuccessTitle,
    toastErrorTitle,
    toastSuccessCreateMessage,
    toastSuccessUpdateMessage,
    toastSuccessDeleteMessage,
    toastErrorCreateMessage,
    toastErrorUpdateMessage,
    toastErrorDeleteMessage,
    errorLoadingDataText,
    noDataToDisplayText,
    loadingText,
    lightningIconLinkAlternativeText
  };

  @api libraryName;
  libraryId;
  @api linksLimitToShow;
  @track links = [];
  @track linksById = {};
  allViewUrl;
  linkId;
  errorLoadingData;
  isLoading = true;
  showModal;
  saveButtonStatus;
  inputTitulo;
  inputUrl;
  inputTextValidated;
  inputUrlValidated;
  isEdit;
  isNew;
  userPermissionType = "";

  get linksToShow() {
    return !this.isLoading && !this.errorLoadingData && !this.links.length;
  }

  get saveButtonDisabled() {
    return !this.inputTextValidated || !this.inputUrlValidated;
  }

  get isViewer() {
    return this.userPermissionType === ContentWorkspacePerm.Viewer;
  }

  get isAdmin() {
    return this.userPermissionType === ContentWorkspacePerm.Admin;
  }

  get isAuthorOrAdmin() {
    return (
      this.userPermissionType === ContentWorkspacePerm.Author ||
      this.userPermissionType === ContentWorkspacePerm.Admin
    );
  }

  //#endregion

  //#region Lifecycle functions

  async connectedCallback() {
    this.generateAllViewUrl();

    try {
      // Se recupera el Id de la librería
      this.libraryId = await getLibraryId({
        contentWorkspaceName: this.libraryName
      });

      this.userPermissionType = await getPermissionType({
        contentWorkspaceId: this.libraryId,
        userId: userId
      });
    } catch (error) {
      this.errorLoadingData = true;
    }

    // Si el usuario tiene acceso a la biblioteca se cargan los enlaces
    if (this.isViewer || this.isAuthorOrAdmin) {
      this.getData();
    } else {
      this.isLoading = false;
    }
  }

  //#endregion

  //#region Handle functions
  handleInputTextChange(evt) {
    this.inputTextValidated = evt.target.reportValidity();
  }

  handleInputUrlChange(evt) {
    this.inputUrlValidated = evt.target.reportValidity();
  }

  handleNew() {
    // Indica que está en modo de creación de registro
    this.isNew = true;

    // Se abre la ventana modal
    this.openModal();
  }

  handleEdit(evt) {
    // Lo datos que se muestran en el "lightning-input" están validados
    this.inputTextValidated = true;
    this.inputUrlValidated = true;

    // Indica que está en modo actualización de registro
    this.isEdit = true;

    // Se recupera el elemento 'div', padre del elemento que contiene el botón de edición
    let parentDiv = evt.target.closest("div");
    // Se recupera el Id del link que se va a editar
    this.linkId = parentDiv.getAttribute("data-id");
    // Se recupera el título del link de interés
    this.inputTitulo = this.linksById[this.linkId].title;
    // Se recupera la URL del enlace de interés
    this.inputUrl = this.linksById[this.linkId].url;

    // Se abre la ventana modal
    this.openModal();
  }

  async handleSalve() {
    // Se recupera el título y la url editados
    let title = this.template.querySelector(
      'lightning-input[data-field="titulo"]'
    ).value;
    let url = this.template.querySelector(
      'lightning-input[data-field="url"]'
    ).value;

    if (this.isEdit) {
      this.updateLink(title, url);
    } else if (this.isNew) {
      this.createNewLink(title, url);
    }

    // Se cierra la ventana modal
    this.closeModal();
  }

  handleCancel() {
    // Se cierra la ventana modal
    this.closeModal();
  }

  async handleDelete(evt) {
    let parentDiv = evt.target.closest("div");
    let linkId = parentDiv.getAttribute("data-id");
    let linkToRemove = this.linksById[linkId].contentDocumentId;

    const confirmDeletion = await LightningConfirm.open({
      message: this.label.confirmDeletionMessage,
      theme: "warning",
      label: this.label.confirmDeletionLabel
    });

    if (confirmDeletion) {
      let idOwner = this.linksById[linkId].ownerId;

      /* Si el usuario que ejecuta la acción de eliminar el link no es propietario del mismo,
       * se actualiza el link para que el usuario sea el propietario. Una vez que se actualiza,
       * se elimina el enlace.
       */
      if (userId !== idOwner) {
        const fields = {};

        fields[CONTENTDOCUMENT_ID.fieldApiName] = linkToRemove;
        fields[CONTENTDOCUMENT_OWNER_ID.fieldApiName] = idOwner;

        const recordInput = {
          fields
        };

        updateRecord(recordInput)
          .then(() => {
            this.deleteLink(linkToRemove);
          })
          .catch(() => {
            this.showError(
              this.label.toastErrorTitle,
              this.label.toastErrorDeleteMessage
            );
          });
      } else {
        this.deleteLink(linkToRemove);
      }
    }
  }

  //#endregion

  //#region Auxiliar functions

  getData() {
    // Flag que indica que los datos se están cargando
    this.isLoading = true;

    getLinks({
      contentWorkspaceId: this.libraryId,
      recordsLimit: this.linksLimitToShow
    })
      .then((result) => {
        this.links = result;
        this.links.forEach((link) => {
          const linkById = {
            [link.Id]: {
              title: link.Title,
              url: link.ContentUrl,
              contentDocumentId: link.ContentDocumentId,
              ownerId: link.OwnerId
            }
          };
          this.linksById = { ...this.linksById, ...linkById };
        });
      })
      .catch(() => {
        this.errorLoadingData = true;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }

  updateLink(title, url) {
    const fields = {};

    fields[CONTENTVERSION_ID.fieldApiName] = this.linkId;
    fields[CONTENTVERSION_TITLE.fieldApiName] = title;
    fields[CONTENTVERSION_CONTENTURL.fieldApiName] = url;

    const recordInput = {
      fields
    };

    updateRecord(recordInput)
      .then(() => {
        this.getData();
        this.showSuccess(
          this.label.toastSuccessTitle,
          this.label.toastSuccessUpdateMessage
        );
      })
      .catch(() => {
        this.showError(
          this.label.toastErrorTitle,
          this.label.toastErrorUpdateMessage
        );
      });
  }

  createNewLink(title, url) {
    const fields = {};

    fields[CONTENTVERSION_CONTENTURL.fieldApiName] = url;
    fields[CONTENTVERSION_FIRSTPUBLISHLOCATIONID.fieldApiName] = this.libraryId;
    fields[CONTENTVERSION_TITLE.fieldApiName] = title;

    const recordInput = {
      apiName: CONTENTVERSION_OBJECT.objectApiName,
      fields
    };

    createRecord(recordInput)
      .then(() => {
        this.getData();
        this.showSuccess(
          this.label.toastSuccessTitle,
          this.label.toastSuccessCreateMessage
        );
      })
      .catch(() => {
        this.showError(
          this.label.toastErrorTitle,
          this.label.toastErrorCreateMessage
        );
      });
  }

  deleteLink(linkToRemove) {
    deleteRecord(linkToRemove)
      .then(() => {
        this.getData();
        this.showSuccess(
          this.label.toastSuccessTitle,
          this.label.toastSuccessDeleteMessage
        );
      })
      .catch(() => {
        this.showError(
          this.label.toastErrorTitle,
          this.label.toastErrorDeleteMessage
        );
      });
  }

  generateAllViewUrl() {
    this.contentDocumentHomePage = {
      type: "standard__objectPage",
      attributes: {
        objectApiName: "ContentDocument",
        actionName: "home"
      }
    };

    this[NavigationMixin.GenerateUrl](this.contentDocumentHomePage).then(
      (url) => {
        this.allViewUrl = url;
      }
    );
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

  //#endregion

  //#region Modal window functions
  openModal() {
    // Se setea la variable a 'true' para mostrar la ventana Modal
    this.showModal = true;
  }

  closeModal() {
    // Se resetea la validación de los elementos "lighting-input"
    this.inputTextValidated = false;
    this.inputUrlValidated = false;

    // Se resetea la acción a realizar
    this.isEdit = false;
    this.isNew = false;

    // Se resetean los campos de tipo 'lightning-input'
    this.inputTitulo = "";
    this.inputUrl = "";

    // Se setea la variable a 'false' para ocultar la ventana Modal
    this.showModal = false;
  }

  //#endregion
}
