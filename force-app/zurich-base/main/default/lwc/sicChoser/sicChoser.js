import { api, LightningElement, wire, track } from 'lwc';
import { FlowNavigationNextEvent } from "lightning/flowSupport";
import getAvailableSics from "@salesforce/apex/RiskAppetiteController.getAvailableSICs";


export default class SicChoser extends LightningElement 
{
    // Variable to return the nextPage that should be opened
    @api nextPage;
    @api value = "";
    @api chosenValue;
    @api label = "Escoge un SIC";
    initialized = false;

    // @track optionsList;
    @wire (getAvailableSics) optionsList;

    get options() {

        let options = [];
        if(this.optionsList.data)
        {
            this.optionsList.data.forEach(ele =>{
                options.push({label:ele , value:ele});
            }); 
            return options;
        }
    }

    renderedCallback() {
        if (this.initialized) {
            return;
        }
        this.initialized = true;
        let listId = this.template.querySelector('datalist').id;
        this.template.querySelector("input").setAttribute("list", listId);
    }
    
    // Function that makes the flow move to the next step
    handleNext()
    {
        this.chosenValue = this.parseSelection(this.value);
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    parseSelection(labelSelected)
    {
        return (labelSelected.split(" - "))[0];
    }

    handleChange(evt) {
        this.value = evt.target.value;
    }
}