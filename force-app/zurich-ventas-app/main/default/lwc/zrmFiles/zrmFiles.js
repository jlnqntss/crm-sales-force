import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedFilesByRecordId from '@salesforce/apex/ZRMFilesController.getRelatedFilesByRecordId';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord } from "lightning/uiRecordApi";
import LightningConfirm from 'lightning/confirm';

// labels
import ZRM_FilesTitle from "@salesforce/label/c.ZRM_FilesTitle";
import ZRM_Files_NewFile from "@salesforce/label/c.ZRM_Files_NewFile";
import ZRM_Files_DownloadFile from "@salesforce/label/c.ZRM_Files_DownloadFile";
import ZRM_Files_Success from "@salesforce/label/c.ZRM_Files_Success";
import ZRM_Files_Refresh from "@salesforce/label/c.ZRM_Files_Refresh";
import ZRM_Files_UploadSuccess from "@salesforce/label/c.ZRM_Files_UploadSuccess";
import ZRM_Files_DeleteConfirmMessage from "@salesforce/label/c.ZRM_Files_DeleteConfirmMessage";
import ZRM_Files_DeleteConfirmLabel from "@salesforce/label/c.ZRM_Files_DeleteConfirmLabel";
import ZRM_Files_DeleteConfirmSuccess from "@salesforce/label/c.ZRM_Files_DeleteConfirmSuccess";

export default class ZRMFiles extends LightningElement {

    // labels
    label = {
        ZRM_FilesTitle,
        ZRM_Files_NewFile,
        ZRM_Files_DownloadFile,
        ZRM_Files_Success,
        ZRM_Files_Refresh,
        ZRM_Files_UploadSuccess,
        ZRM_Files_DeleteConfirmMessage,
        ZRM_Files_DeleteConfirmLabel,
        ZRM_Files_DeleteConfirmSuccess
    };

    @api recordId;
    @track showFileUploader = false;
    @track isLoading = false;

    @wire(getRelatedFilesByRecordId, {recordId: '$recordId'})  
    filesList;

    handleUploadClick() {
        this.showFileUploader = !this.showFileUploader;
    }

    handleUploadFinished(event) {
        this.isLoading = true;
        refreshApex(this.filesList)
            .then(() => {
                this.isLoading = false;
                const uploadedFiles = event.detail.files;
                this.showToast(this.label.ZRM_Files_Success, uploadedFiles.length + ' ' + this.label.ZRM_Files_UploadSuccess, 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    async handleDelete(event) {
        this.isLoading = true;
        const recordId = event.target.dataset.id;
        
        const result = await LightningConfirm.open({
            message: this.label.ZRM_Files_DeleteConfirmMessage,
            variant: 'header',
            label: this.label.ZRM_Files_DeleteConfirmLabel,
            theme: 'warning'
        });
        if (result) {
            try {
                await deleteRecord(recordId);
                this.showToast(this.label.ZRM_Files_Success, this.label.ZRM_Files_DeleteConfirmSuccess, 'success');
                await refreshApex(this.filesList);
            } catch (error) {                
                this.showToast('Error', error.body.message, 'error');
            } finally {
                this.isLoading = false;
            }
        } else {
            this.isLoading = false;
        }
    }

    refreshComponent() {
        this.isLoading = true;
        refreshApex(this.filesList)
            .then(() => {
                this.isLoading = false;
                this.showToast(this.label.ZRM_Files_Success, this.label.ZRM_Files_Refresh, 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}
