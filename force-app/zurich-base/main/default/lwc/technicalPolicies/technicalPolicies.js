/**
 * Librería para manejar los saltos entre step y step de un screen flow desde cualquier LWC
 *
 * @author jjuaristi
 */

import { api, LightningElement, wire } from 'lwc';
import { FlowNavigationNextEvent, FlowAttributeChangeEvent } from "lightning/flowSupport";
import getTechPoliciesForActivities from "@salesforce/apex/RiskAppetiteController.getTechPoliciesForActivities";
import getFields from "@salesforce/apex/RiskAppetiteController.getFields";


const fieldsToFilter = [
    "UsoExplosivos__c",
    "Espumosos__c",
    "ConAspiracionAutomatica__c",
    "ConRecubrimiento__c",
    "ConPlanchasCombustibles__c",
    "ConFabricacionDeEnvases__c",
    "ConDestilacion__c",
    "ConExistenciaLiquidosInflamables__c",
    "ConFoamizado__c",
    "ConMateriasPlasticasEspumosas__c",
    "ConNitratos__c",
    "ConTapizados__c",
    "ConSecaderoMadera__c"
];

export default class TechnicalPolicies extends LightningElement 
{

    // Variable to return the nextPage that should be opened
    @api nextPage = 0;
    @api chosenValue;
    @api value;
    @api bunchLabel;
    @api sicLabel;
    @api activityLabel;
    @api sicCode;
    @api productCode;
    @api activityCode;
    @api size;
    @api currentCounter = 1;
    @api currentRecord;
    @api policies;
    @api filtersVisible;
    idsInPolicies = [];

    @api showExplosives;
    @api showEspumosos;
    @api showAspiration;
    @api showCover;
    @api showCombustible;
    @api showContainer;
    @api showDistillation;
    @api showFlammable;
    @api showFoaming;
    @api showPlasticFoaming;
    @api showNitrates;
    @api showUpholstered;
    @api showWood;

    @api buttonsClicked = [];

    @wire (getTechPoliciesForActivities, {SICCode : '$sicCode', productCode: '$productCode', activityCode: '$activityCode'}) optionsList;


    get size()
    {
        if(this.policies)
        {
            return this.policies.length;
        }
        else if (this.optionsList.data)
        {
            return this.optionsList.data.length;
        }
    }

    get currentId()
    {
        var currentId;
        if(this.optionsList.data)
        {  
            if(!this.policies){
                // el array policies solo va a estar undefined al principio, así en las n ejecuciones de este getter no se vuelve a lanzar
                this.policies = this.optionsList.data;
                this.policies.forEach(ele=>{
                    this.idsInPolicies.push(ele.Id);
                })
            }
            currentId = this.loadFields();
            return currentId;
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

    handleCommercial()
    {
        this.nextPage = 3;
        this.handleChange("nextPage", this.nextPage);
        this.moveForward();
    }

    moveRight()
    {
        if(this.currentCounter != this.size){
            this.currentCounter++;
        }
        this.loadFields();
    }

    moveLeft()
    {
        if(this.currentCounter != 1){
            this.currentCounter--;
        }
        this.loadFields();
    }

    handleFilter(){
        if(!this.filtersVisible){
            this.filtersVisible = true;
            this.loadFilters();
        }else{
            this.filtersVisible = false;
        }
    }

    loadFilters(){
        // TODO : La idea es pasar todo esto a un array de variables haciendo destructuring, de momento no he conseguido que funcione
        this.showExplosives = this.checkShowField(fieldsToFilter[0]);
        this.showEspumosos = this.checkShowField(fieldsToFilter[1]);
        this.showAspiration = this.checkShowField(fieldsToFilter[2]);
        this.showCover = this.checkShowField(fieldsToFilter[3]);
        this.showCombustible = this.checkShowField(fieldsToFilter[4]);
        this.showContainer = this.checkShowField(fieldsToFilter[5]);
        this.showDistillation = this.checkShowField(fieldsToFilter[6]);
        this.showFlammable = this.checkShowField(fieldsToFilter[7]);
        this.showFoaming = this.checkShowField(fieldsToFilter[8]);
        this.showPlasticFoaming = this.checkShowField(fieldsToFilter[9]);
        this.showNitrates = this.checkShowField(fieldsToFilter[10]);
        this.showUpholstered = this.checkShowField(fieldsToFilter[11]);
        this.showWood = this.checkShowField(fieldsToFilter[12]);
    }

    checkShowField(field){
        var show = false;
        if(this.policies)
        {
            this.policies.some(ele =>{
                if(ele[field]){
                    show = true;
                }
            })
        }
        return show;
    }

    filterPolicies(event)
    {
        var position = event.target.id.split("-")[1];
        this.currentCounter = 1;
        
        console.log(event.target.checked);
        if(event.target.checked){
            this.buttonsClicked.push(position);
            this.checkField(fieldsToFilter[position]);
        }else{
            this.removePosition(position);
            this.uncheckField(fieldsToFilter[position]);
        }
        this.loadFields();
        this.loadFilters();
    }

    removePosition(positionClicked){
        var auxPositions = this.buttonsClicked;
        this.buttonsClicked = [];
        auxPositions.forEach(pos=>{
            if(pos != positionClicked)
            {
                this.buttonsClicked.push(pos);
            }
        })
    }

    checkField(field){
        if(this.policies)
        {
            var auxiliarArray = this.policies;
            this.policies = [];
            this.idsInPolicies = [];

            auxiliarArray.forEach(ele =>{
                if(ele[field]){
                    console.log(ele);
                    if(!this.idsInPolicies.includes(ele.Id))
                    {
                        this.policies.push(ele);
                        this.idsInPolicies.push(ele.Id);
                    }
                }
            })
        }
    }

    uncheckField(field){
        if(this.optionsList.data)
        {
            this.optionsList.data.forEach(ele =>{
                if(!ele[field] && this.checkPreviousButtons(ele)){
                    if(!this.idsInPolicies.includes(ele.Id))
                    {
                        this.policies.push(ele);
                        this.idsInPolicies.push(ele.Id);
                    }
                }
            }); 
        }
    }

    checkPreviousButtons(element){
        var correct = true;
        this.buttonsClicked.forEach(position =>{
            if(!element[fieldsToFilter[position]]){
                correct = false;
            }
        })
        return correct;
    }

    loadFields()
    {
        var fieldsRetrieved =  [];
        console.log(this.policies);
        this.currentRecord = this.policies[this.currentCounter-1];
        if(this.currentRecord){
            this.size = this.policies.length;
            // TODO aquí se recoge el fieldSet, debido a que hay que hacerlo con apex, pasamos el registro y toda la lógica la dejamos en el controlador
            // el controlador va a devolver un array de strings que van a ser los campos, y aquí lo dividimos en dos (si lo quieren a la derecha igual mejor dejar en 1) 
            // para que luego en el grid quede bien faltaría estudiar cómo hacer que salga la traducción

            // Imperative apex RiskAppetiteController.getFields(this.currentRecord)
            getFields({ record: this.currentRecord })
            .then((result) => {
                fieldsRetrieved = result;
            });

            // Para pintar estos campos solo hay que hacer un for each en el html recorriendo la lista y se irán mostrando

            // TODO crear una lista a parte que contenga los campos de franquicia para que luego vayan en el acordeón solos, necesitarán una variable "showFranquicias"
            // porque hay en ramos en los que estos campos no deben aparecer.
            return this.currentRecord.Id;
        }
    }
}