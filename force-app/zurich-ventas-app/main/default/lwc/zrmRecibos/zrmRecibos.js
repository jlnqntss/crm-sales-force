import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getData from '@salesforce/apex/ZrmRecibosController.getData';

// Custom Labels
import ZRM_Recibos_Previous from "@salesforce/label/c.ZRM_Recibos_Previous";
import ZRM_Recibos_Next from "@salesforce/label/c.ZRM_Recibos_Next";
import ZRM_Recibos_Column_Receipt from "@salesforce/label/c.ZRM_Recibos_Column_Receipt";
import ZRM_Recibos_Column_EffectiveDate from "@salesforce/label/c.ZRM_Recibos_Column_EffectiveDate";
import ZRM_Recibos_Column_Policy from "@salesforce/label/c.ZRM_Recibos_Column_Policy";
import ZRM_Recibos_Column_Company from "@salesforce/label/c.ZRM_Recibos_Column_Company";
import ZRM_Recibos_Column_Holder from "@salesforce/label/c.ZRM_Recibos_Column_Holder";
import ZRM_Recibos_Column_Phone from "@salesforce/label/c.ZRM_Recibos_Column_Phone";
import ZRM_Recibos_Column_Amount from "@salesforce/label/c.ZRM_Recibos_Column_Amount";
import ZRM_Recibos_Column_PaymentMethod from "@salesforce/label/c.ZRM_Recibos_Column_PaymentMethod";
import ZRM_Recibos_Column_NumberOfReturns from "@salesforce/label/c.ZRM_Recibos_Column_NumberOfReturns";
import ZRM_Recibos_Column_DocumentDescriptionReceipt from "@salesforce/label/c.ZRM_Recibos_Column_DocumentDescriptionReceipt";
import ZRM_Recibos_Column_LastReturnDate from "@salesforce/label/c.ZRM_Recibos_Column_LastReturnDate";
import ZRM_Recibos_Column_BankShipmentDate from "@salesforce/label/c.ZRM_Recibos_Column_BankShipmentDate";
import ZRM_Recibos_Column_Intermediary from "@salesforce/label/c.ZRM_Recibos_Column_Intermediary";

export default class ZrmRecibos extends LightningElement {

    // Variables js
    labels = {
        ZRM_Recibos_Previous,
        ZRM_Recibos_Next,
        ZRM_Recibos_Column_Receipt,
        ZRM_Recibos_Column_EffectiveDate,
        ZRM_Recibos_Column_Policy,
        ZRM_Recibos_Column_Company,
        ZRM_Recibos_Column_Holder,
        ZRM_Recibos_Column_Phone,
        ZRM_Recibos_Column_Amount,
        ZRM_Recibos_Column_PaymentMethod,
        ZRM_Recibos_Column_NumberOfReturns,
        ZRM_Recibos_Column_DocumentDescriptionReceipt,
        ZRM_Recibos_Column_LastReturnDate,
        ZRM_Recibos_Column_BankShipmentDate,
        ZRM_Recibos_Column_Intermediary
    }

    // columnas de la tabla
    columns = [
        { label: this.labels.ZRM_Recibos_Column_Receipt, fieldName: 'codigoRecibo', wrapText: true },
        {   label: this.labels.ZRM_Recibos_Column_EffectiveDate, 
            fieldName: 'fechaEfectoMovimiento', 
            type: 'date',
            typeAttributes: {
                day: "2-digit",
                month: "2-digit",
                year: "numeric"
            },
            wrapText: true
        },
        { label: this.labels.ZRM_Recibos_Column_Policy, fieldName: 'codigoPoliza', wrapText: true },
        { label: this.labels.ZRM_Recibos_Column_Company, fieldName: 'descripcionAgrupacionCompania', wrapText: true },
        { label: this.labels.ZRM_Recibos_Column_Holder, fieldName: 'nombreTomador', wrapText: true },
        { label: this.labels.ZRM_Recibos_Column_Phone, fieldName: 'telefonoTomador', wrapText: true },
        {   label: this.labels.ZRM_Recibos_Column_Amount, 
            fieldName: 'importeTotalRecibo', 
            type: 'currency',
            typeAttributes: { 
                currencyCode: 'EUR', 
                step: '0.001' 
            },
            wrapText: true
        },
        { label: this.labels.ZRM_Recibos_Column_PaymentMethod, fieldName: 'descripcionFormaPago', wrapText: true },
        { label: this.labels.ZRM_Recibos_Column_NumberOfReturns, fieldName: 'numeroDevolucionesRecibo', wrapText: true },
        { label: this.labels.ZRM_Recibos_Column_DocumentDescriptionReceipt, fieldName: 'descripcionDocumentoReclamacion', wrapText: true },
        { 
            label: this.labels.ZRM_Recibos_Column_LastReturnDate, 
            fieldName: 'fechaUltimaDevolucionRecibo', 
            type: 'date',
            typeAttributes: {
                day: "2-digit",
                month: "2-digit",
                year: "numeric"
            },
            wrapText: true
        },
        {   label: this.labels.ZRM_Recibos_Column_BankShipmentDate, 
            fieldName: 'fechaEnvioBancoRecibo', 
            type: 'date',
            typeAttributes:{
                day: "2-digit",
                month: "2-digit",
                year: "numeric"
            },
            wrapText: true
        },
        { label: this.labels.ZRM_Recibos_Column_Intermediary, fieldName: 'codigoIntermediario', wrapText: true }
    ];
    
    @api antiguedadRecibo;

    data = [];
    disablePreviousButton = true; 
    disableNextButton = true;
    currentPage = 1;
    pageSize = 2;
    cache = {};
    isLoading = false;

    // Métodos LWC

    // Metodo que se ejecuta cuando se abre el componente
    connectedCallback() {
        this.isLoading = true;
        this.loadData(1);
    }

    // control botón previous
    handlePrevious() {
        if (this.currentPage > 1) {
            this.isLoading = true;
            this.loadData(this.currentPage - 1);
        }
    }

    // control botón next
    handleNext() {
        this.isLoading = true;
        this.loadData(this.currentPage + 1);
    }

    // control de caché y obtener datos del servicio web
    loadData(pageNumber) {
        
        // Verifica si los datos ya están en la caché
        if (this.cache[pageNumber]) {
            console.log('Entro en cache');
            this.updateData(this.cache[pageNumber], pageNumber);
        } else {
            // Llama al método Apex solo si los datos no están en la caché
            getData({ pageNumber: pageNumber, pageSize: this.pageSize, invocationType: this.antiguedadRecibo })
                .then(result => {
                    // Almacena el resultado en la caché                    
                    this.cache[pageNumber] = result;
                    this.updateData(result, pageNumber);
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showToast('Error', error.body.message, 'error');
                });
        }
    }

    // actualizar variables
    updateData(result, pageNumber) {
        this.isLoading = false;
        this.data = result.records;
        this.disablePreviousButton = result.disablePreviousButton;
        this.disableNextButton = result.disableNextButton;
        this.currentPage = pageNumber;
    }

    // Función para mostrar mensajes toast
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
    
}