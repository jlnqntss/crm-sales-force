import { LightningElement, api, track, wire } from 'lwc';
import {FlowAttributeChangeEvent} from 'lightning/flowSupport';
import { getRecord } from 'lightning/uiRecordApi';
import getAccountsInfo from '@salesforce/apex/LWCCaseSelectCustomerController.getAccountsInfo';

const FIELDS = ['Account.Name'];
const OPTIONAL_FIELDS = ['Account.RecordType.Name'];

export default class FlowCaseSelectCustomer extends LightningElement {

    @track options = [];

    //Importante: esta función va primero porque si no sale error de no estar definida
    //Llama al Apex que hace una query para recupera datos de las cuentas
    //y va rellenando las options con ello
    handleGetAccountsInfo(idsList){
        //Apex
        getAccountsInfo({ idsToFind: idsList })
            .then((result) => {
                if(result != undefined){ //1º comprobar que no es undefined
                    for(var account of result){
                        var option = {
                            label: account.Name +' ('+account.RecordType.Name+')',
                            value: account.Id
                        };
                        this.options.push(option);
                    }
                }
            })
            .catch((error) => {
                let message = 'Error desconocido';
                if (Array.isArray(error.body)) {
                    message = error.body.map(e => e.message).join(', ');
                } else if (typeof error.body.message === 'string') {
                    message = error.body.message;
                }
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error obteniendo información de cuenta',
                        message,
                        variant: 'error',
                    }),
                );
            });
    }


    _accountIdsList = ['placeholder'];
    @api
    get accountIdsList(){
        return this._accountIdsList;
    };
    set accountIdsList(value){
        this._accountIdsList = value;
        //Actualizar las opciones cada vez que se actualiza la lista recibida:
        this.handleGetAccountsInfo(value);

    }
    @api accountIdSelected = ''; //Salida que se manda al flow

    //Hook to Flow's Validation engine
    @api
    validate() {
        if(this.accountIdSelected != '') {
            return { isValid: true };
            }

        //If the component is invalid, return the isValid parameter as false and return an error message.
        return {
            isValid: false,
            errorMessage:  'Por favor, selecciona una cuenta.'
            };
    }

    //Sirve para borrar lo que seleccionó el usuario, y al retroceder en el flow al darle a 'NO', que tenga que seleccionar algo de nuevo
    connectedCallback(){
        this.accountIdSelected = '';
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedAccountId', '');
        this.dispatchEvent(attributeChangeEvent);
    }

    //Cada vez que se cambia la selección, se envía al Flow el Id de cuenta seleccionado
    handleChange(event) {
        this.accountIdSelected = event.detail.value; //Id de la cuenta
        //Devolver el valor al flow
        const attributeChangeEvent = new FlowAttributeChangeEvent('selectedAccountId', this.accountIdSelected);
        this.dispatchEvent(attributeChangeEvent);
    }

}