import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedFilesByRecordId from '@salesforce/apex/ZRMFilesController.getRelatedFilesByRecordId';
import { refreshApex } from '@salesforce/apex';

// labels
import ZRM_FilesTitle from "@salesforce/label/c.ZRM_FilesTitle";
import ZRM_NewFile from "@salesforce/label/c.ZRM_NewFile";
import ZRM_DownloadFile from "@salesforce/label/c.ZRM_DownloadFile";
import ZRM_Success from "@salesforce/label/c.ZRM_Success";
import ZRM_Refresh from "@salesforce/label/c.ZRM_Refresh";
import ZRM_UploadSuccess from "@salesforce/label/c.ZRM_UploadSuccess";

export default class ZRMFiles extends LightningElement {

    // labels
    label = {
        ZRM_FilesTitle,
        ZRM_NewFile,
        ZRM_DownloadFile,
        ZRM_Success,
        ZRM_Refresh,
        ZRM_UploadSuccess
    };

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
        this.showToast(this.label.ZRM_Success, uploadedFiles.length + this.label.ZRM_UploadSuccess, 'success');
    }

    refreshComponent() {
        refreshApex(this.filesList);
        this.showToast(this.label.ZRM_Success, this.label.ZRM_Refresh, 'success');
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