import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedFilesByRecordId from '@salesforce/apex/ZRMFilesController.getRelatedFilesByRecordId';
import { refreshApex } from '@salesforce/apex';
import {NavigationMixin} from 'lightning/navigation';
export default class ZRMFiles extends NavigationMixin(LightningElement) {

    @api recordId;
    showFileUploader = false;

    @wire(getRelatedFilesByRecordId, {recordId: '$recordId'})  
    filesList;

    handleUploadClick() {
        this.showFileUploader = !this.showFileUploader;
    }

    // Manejador para la carga exitosa de archivos
    handleUploadFinished(event) {
        // Llamada a Apex para actualizar la lista de archivos
        refreshApex(this.filesList);
        // Mostrar mensaje toast
        const uploadedFiles = event.detail.files;
        this.showToast('Éxito', `${uploadedFiles.length} archivo(s) cargado(s) con éxito.`, 'success');
    }


    /*previewHandler(event){
        try {
            console.log(event.target.dataset.id);
            this[NavigationMixin.Navigate]({ 
                type:'standard__namedPage',
                attributes:{ 
                    pageName:'filePreview'
                },
                state:{ 
                    selectedRecordId: event.target.dataset.id
                }
            })

        } catch(error) {
            console.log(JSON.stringify(error));
        }
    }*/


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