import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getData from '@salesforce/apex/ZrmRecibosController.getData';

// The rest of the relative imports
import labels from "./labels";
import columns from "./columns";

export default class ZrmRecibos extends LightningElement {

    
    @api antiguedadRecibo;
    
    labels = labels;
    columns = columns;
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