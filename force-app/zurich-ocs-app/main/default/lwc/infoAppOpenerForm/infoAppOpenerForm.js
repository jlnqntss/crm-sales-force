import { LightningElement, track } from "lwc";

/**
 * Componente de depuración de apertura de URLs para INFO
 *
 * @author jmartinezpisson
 */
export default class InfoAppOpenerForm extends LightningElement {
  //#region Properties
  @track
  baseUrl = "";

  @track
  path = "";

  @track
  parameters = [];

  get url() {
    let url = this.baseUrl;

    if (this.path) {
      url += "/" + this.path;
    }

    if (this.parameters.length) {
      url +=
        "?" +
        this.parameters
          .map((parameter) => {
            return `${parameter.name}=${encodeURIComponent(parameter.value)}`;
          })
          .join("&");
    }

    return url;
  }

  get isInvalidUrl() {
    let isValid = this.baseUrl ? this.baseUrl.includes(":") : false;

    this.parameters.forEach((parameter) => {
      if (!parameter.name) {
        isValid = false;
      }
    });

    return !isValid;
  }

  get urlCssClass() {
    return this.isInvalidUrl
      ? "slds-text-color_error"
      : "slds-text-color_success";
  }

  //#endregion

  //#region Event Handlers

  /**
   * Añade un nuevo parámetro identificado
   *
   * @author jmartinezpisson
   * @param {CustomEvent} event
   * @param {string} event.index Identificador único del parámetro a eliminar
   */
  addParameter() {
    this.parameters.push({
      index: `param-${this.parameters.length}`,
      name: "",
      value: ""
    });
  }

  /**
   * Elimina el parámetro identificado
   *
   * @author jmartinezpisson
   * @param {CustomEvent} event
   * @param {string} event.index Identificador único del parámetro a eliminar
   */
  removeParameter(event) {
    const index = event.detail.index;
    this.parameters = this.parameters.filter((parameter) => {
      return parameter.index !== index;
    });
  }

  /**
   * Actualiza la URL en base a las modificaciones del formulario
   *
   * @author jmartinezpisson
   * @param {ChangeEvent} event Evento change estándar del DOM
   */
  updateUrl(event) {
    const name = event.target.name;
    const value = event.target.value;

    if (name === "base-url") {
      this.baseUrl = value;
    } else if (name === "action-path") {
      this.path = value;
    }
  }

  /**
   * Actualiza los parámetros de la URL en base a las modificaciones del formulario
   *
   * @author jmartinezpisson
   * @param {CustomEvent} event Evneto Change personalizado emitido por infoAppOpenerFormParameter
   * @param {string} event.index Identificador único del parámetro a modificar
   * @param {string} event.name Nombre del parámetro GET
   * @param {string} event.value Valor del parámetro GET
   */
  updateParameter(event) {
    const { index, name, value } = event.detail;
    const changedParameter = this.parameters.find((parameter) => {
      return parameter.index === index;
    });

    if (changedParameter) {
      changedParameter[name] = value;
    }
  }

  /**
   * Abre la URL generada en el navegador. Se utiliza un <a> oculto para
   * evitar la limitación de SF de aperturas de otros protocolos bajo demanda
   *
   * @author jmartinezpisson
   */
  openUrl() {
    this.template.querySelector(".custom-url").click();
  }

  //#endregion
}
