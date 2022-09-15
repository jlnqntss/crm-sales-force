import { api, LightningElement, wire } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from "lightning/flowSupport";
import getProductsForSIC from "@salesforce/apex/RiskAppetiteController.getProductsForSIC";

export default class BunchChoser extends LightningElement 
{
    // Variable to return the nextPage that should be opened
    @api nextPage;
    @api sicCode;
    @api value;
    @api chosenValue;
    @api label;

    @wire (getProductsForSIC, {sicCode : '$sicCode'}) optionsList;

    get options() {

        let options = [];
        if(this.optionsList.data)
        {
            this.optionsList.data.forEach(ele =>{
                options.push({label:ele.label , value:ele.label, id:ele.label.split(" - ")[0],
                badgeLabel:ele.buttonLabel, badgeClass:ele.buttonClass, productLink:ele.sharepoint,
                dyoLink:ele.dyoSharepoint, ciberLink:ele.ciberSharepoint});
            }); 
            return options;
        }
    }

    // Function that makes the flow move to the next step
    handleNext()
    {
        this.nextPage = 0;
        this.handleChange("nextPage", this.nextPage);
        this.moveForward();
    }

    handleChange(variableName, value)
    {
        const attributeChangeEvent = new FlowAttributeChangeEvent(variableName, value);
        this.dispatchEvent(attributeChangeEvent);  
    }

    moveForward()
    {
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    handleSIC()
    {
        this.nextPage = 1;
        this.handleChange("nextPage", this.nextPage);
        this.moveForward();
    }

    parseSelection(labelSelected)
    {
        return (labelSelected.split(" - "))[0];
    }

    handleClick(evt) {
        
        const position = evt.target.id.indexOf("-");
        this.chosenValue = evt.target.id.substring(0, position);

        this.options.forEach( option =>{
            if( option.label.includes(this.chosenValue))
            {
                this.value = option.label;
            }
        });
        this.handleNext();
    }

    goToDoc(event){
        const URL = event.target.value;
        window.open(URL, '_blank').focus();
    }
}