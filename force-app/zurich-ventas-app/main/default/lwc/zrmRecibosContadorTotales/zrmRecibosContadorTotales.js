import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getData from '@salesforce/apex/ZrmRecibosContadorTotalesController.getData';

import labels from "./labels";

export default class ZrmRecibosContadorTotales extends LightningElement {
    @api antiguedadRecibo;

    labels = labels;
    totalRecibos = 0;
    isLoading = false;

    // Metodo que se ejecuta cuando se abre el componente
    connectedCallback() {
        this.isLoading = true;
        this.loadData(1); // inicializamos con 1 para facilitar la cuenta del numero de pagina y habilitar y deshabilitar botones, en el controlador al invocar al WS se resta 1 pues empieza en 0
    }

    // control de caché y obtener datos del servicio web
    loadData() {
        // Verifica si los datos ya están en la caché
        if (this.cache) {
            this.updateData(this.cache);
        } else {
            // Llama al método Apex solo si los datos no están en la caché
            getData({ invocationType: this.antiguedadRecibo })
                .then(result => {
                    // Almacena el resultado en la caché                    
                    this.cache = result;
                    this.updateData(result);
                })
                .catch(error => {
                    this.isLoading = false;
                    this.showToast('Error', error.body.message, 'error');
                });
        }
    }

    // actualizar variables
    updateData(result) {
        this.isLoading = false;
        this.totalRecibos = result;
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