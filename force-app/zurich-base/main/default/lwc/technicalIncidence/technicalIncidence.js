import { api, LightningElement, wire } from 'lwc';
import getScope from '@salesforce/apex/TechnicalIncidenceController.getScope';

export default class TechnicalIncidence extends LightningElement {

    @api recordId;

    showMessage = false;
    @wire(getScope,{record : '$recordId'}) showMessage;

}