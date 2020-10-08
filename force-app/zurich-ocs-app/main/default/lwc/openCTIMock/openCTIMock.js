import { LightningElement, api, track } from "lwc";

const translations = {
  call: "Llamada",
  email: "Correo electrónico",
  sms: "SMS"
};

export default class OpenCTIMock extends LightningElement {
  @track interactions = [];
  eventTwice = 0;

  get lines() {
    return this.interactions.map((interaction) => {
      return {
        index: interaction.id,
        cssClass: interaction.isActive
          ? "slds-is-active slds-item"
          : "slds-item",
        number: interaction.from,
        type: translations[interaction.type]
      };
    });
  }

  @api doScreenPop;
  @api doCreateTask;

  /**
   * @description Inserta en la lista de interacciones una llamada o un email, aleatoriamente
   *                Llama a opencti para abrir una tarea
   * @author nescudero
   * @date 07/10/2020
   */
  handleCall(numero) {
    var chosenValue = Math.random() <= 0.5 ? true : false;
    var thisInPromise = this;

    if (chosenValue) {
      this.interactions.push({
        id: `id-${this.interactions.length}`,
        type: "call",
        isActive: true,
        from: "916484394",
        to: "nescudero@nts-solutions.com"
      });
    } else {
      this.interactions.push({
        id: `id-${this.interactions.length}`,
        type: "email",
        isActive: true,
        from: "nescudero@nts-solutions.com",
        to: "916484394"
      });
    }

    this.doScreenPop(numero).then(function (resul) {
      thisInPromise.doCreateTask(Object.keys(resul)[0]);
    });
  }

  /**
   * @description Cuando se pulsa un 1 en un input, llama a handleCall
   *              En Chrome existe un bug que lanza 2 veces seguidas el evento onkeyup
   * @author nescudero
   * @date 06/10/2020
   */
  handleKeyPress({ code }) {
    this.eventTwice = (this.eventTwice + 1) % 2;
    if (this.eventTwice === 0) return;

    if ("Digit1" === code) {
      this.handleCall("916484394");
    }
  }

  @api handleClickToDial(event) {
    this.handleCall(event);
  }

  connectedCallback() {
    this.addEventListener("keyup", this.handleKeyPress.bind(this));
  }
  disconnectedCallback() {
    this.removeEventListener("keyup", this.handleKeyPress.bind(this));
  }
}
