import { api, LightningElement, wire } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from "lightning/flowSupport";
import getCommercialActivitiesForProducts from "@salesforce/apex/RiskAppetiteController.getCommercialActivitiesForProducts";

export default class CommercialActivityChoser extends LightningElement {

    // Variable to return the nextPage that should be opened
    @api nextPage = 0;
    @api chosenValue;
    @api value;
    @api bunchLabel;
    @api sicLabel;
    @api sicCode;
    @api productCode;

    @wire (getCommercialActivitiesForProducts, {SICCode : '$sicCode', productCode: '$productCode'}) optionsList;

    get options() {

        var options = [];
        if(this.optionsList.data)
        {
            console.log(this.optionsList.data);
            this.optionsList.data.forEach(ele =>{
                options.push({label:ele.label, value:ele.label, id:ele.label.replaceAll(" ", ""), 
                riskAppetite:ele.riskAppetite, dyo:ele.dyo, ciber:ele.ciber});
            }); 
            return options;
        }
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

    handleBunch()
    {
        this.nextPage = 2;
        this.handleChange("nextPage", this.nextPage);
        this.moveForward();
    }

    handleNext()
    {
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    parseSelection(labelSelected)
    {
        return (labelSelected.split(" - "))[0];
    }

    handleClick(evt) {
        // this.value = evt.target.id;
        // this.value = this.value.replace("-", " - ");
        // this.chosenValue = this.parseSelection(this.value);

        var position = evt.target.id.indexOf("-");
        this.chosenValue = evt.target.id.substring(0, position);

        this.options.forEach( option =>{
            if( option.label.includes(this.chosenValue))
            {
                this.value = option.label;
            }
        });
        this.moveForward();
    }
}