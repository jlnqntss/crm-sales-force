import { LightningElement, api, track } from 'lwc';

const translations = {
    'call': 'Llamada',
    'email': 'Correo electrónico',
    'sms': 'SMS'
    }

export default class OpenCTIMock extends LightningElement {

    @track interactions = [];
    eventTwice = 0;

    get lines() {
        return this.interactions.map(interaction => {
          return {
            index: interaction.id,
            cssClass: interaction.isActive? 'slds-item slds-is-active':'slds-item',
            number: interaction.from,
            type: translations[interaction.type]
          }
        })
    }
    handleCall() {
        console.log(this.lines);
        //Siempre el mismo porque es un mock
        this.interactions.push({
            id: `id-${this.interactions.length}`,
            type: "call",
            isActive: true,
            from: "916484394",
            to: "nescudero@nts-solutions.com"
        });

        /*sforce.createTask({        })

        sforce.screenPop({        })*/
    }

    handleKeyPress({code}) {
        this.eventTwice = (this.eventTwice + 1) % 2;
        if (this.eventTwice == 0) return;

        if ('Digit1' == code) {
            this.handleCall();
        }
    }

    connectedCallback() {
        this.addEventListener('keyup', this.handleKeyPress.bind(this));
    }
    disconnectedCallback() {
        this.removeEventListener('keyup', this.handleKeyPress.bind(this));
    }

}