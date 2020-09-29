import { LightningElement, api } from "lwc";

/**
 * Componente de entrada de parámetro GET de URL
 *
 * @author jmartinezpisson
 */
export default class InfoAppOpenerFormParameter extends LightningElement {
  //#region Public properties
  @api
  index = "";

  @api
  name = "";

  @api
  value = "";
  //#endregion

  //#region Event dispatchers

  /**
   * Emite un custom event delete cuando se pulsa el botón de borrado del parámetro
   *
   * @author jmartinezpisson
   */
  dispatchDeleteEvent() {
    this.dispatchEvent(
      new CustomEvent("delete", {
        detail: {
          index: this.index
        },
        bubbles: false
      })
    );
  }

  /**
   * Emite un custom event change cuando se modifican los input del parámetro GET
   *
   * @author jmartinezpisson
   */
  dispatchChanges(event) {
    if (event.target.name) {
      const changeEvent = new CustomEvent("change", {
        detail: {
          index: this.index,
          name: event.target.name,
          value: event.target.value
        },
        bubbles: false
      });

      this.dispatchEvent(changeEvent);
    }
  }
  //#endregion
}
