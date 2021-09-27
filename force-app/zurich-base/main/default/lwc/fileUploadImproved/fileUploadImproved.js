import { LightningElement, track, api, wire } from 'lwc';
import deleteDocumentWithVersion from '@salesforce/apex/UploadCaseDocumentationController.deleteDocumentWithVersion';
import getKey from '@salesforce/apex/FileUploadImprovedHelper.getKey';
import encrypt from '@salesforce/apex/FileUploadImprovedHelper.encrypt';
import createContentDocLink from '@salesforce/apex/FileUploadImprovedHelper.createContentDocLink';
import getCase from "@salesforce/apex/UploadCaseDocumentationController.getCase";
import ZURICH_LOGO from "@salesforce/resourceUrl/zurich_ze_logo";
import solicitudDocumentacionCaso from "@salesforce/label/c.solicitudDocumentacionCaso";
import fechaCreacionCaso from "@salesforce/label/c.fechaCreacionCaso";
import estadoActualCaso from "@salesforce/label/c.estadoActualCaso";
import tamanoMaximoSubidaDocumentacion from "@salesforce/label/c.tamanoMaximoSubidaDocumentacion";
import errorDocumentacionCasoCerrado from "@salesforce/label/c.errorDocumentacionCasoCerrado";
import errorCargandoCaso from "@salesforce/label/c.errorCargandoCaso";
import documentacionAdjuntadaCorrectamente from "@salesforce/label/c.documentacionAdjuntadaCorrectamente";
import errorSubiendoDocumentacion from "@salesforce/label/c.errorSubiendoDocumentacion";
import adjuntaDocumento from "@salesforce/label/c.adjuntaDocumento";
import proteccionDatosTitle from "@salesforce/label/c.proteccionDatosTitle";
import proteccionDatosValue from "@salesforce/label/c.proteccionDatosValue";
import avisoLegalTitle from "@salesforce/label/c.avisoLegalTitle";
import avisoLegalValue from "@salesforce/label/c.avisoLegalValue";
import accesibilidadTitle from "@salesforce/label/c.accesibilidadTitle";
import accesibilidadValue from "@salesforce/label/c.accesibilidadValue";
import zurichSegurosDerechosReservados from "@salesforce/label/c.zurichSegurosDerechosReservados";

import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class FileUpload extends LightningElement {
    @api recordId;
    @api label;
    @api icon;
    @api uploadedlabel;
    @api contentDocumentIds;
    @api contentVersionIds;
    @api uploadedFileNames;
    @api allowMultiple;
    @api acceptedFormats;
    @api required;
    @api requiredMessage;
    @api community;
    @track objFiles = [];
     docIds;
     versIds;
     fileNames;
    
    labels = {
        solicitudDocumentacionCaso,
        fechaCreacionCaso,
        estadoActualCaso,
        tamanoMaximoSubidaDocumentacion,
        errorDocumentacionCasoCerrado,
        errorCargandoCaso,
        documentacionAdjuntadaCorrectamente,
        errorSubiendoDocumentacion,
        adjuntaDocumento,
        proteccionDatosTitle,
        proteccionDatosValue,
        avisoLegalTitle,
        avisoLegalValue,
        accesibilidadTitle,
        accesibilidadValue,
        zurichSegurosDerechosReservados
      };

    zurichLogoUrl = ZURICH_LOGO;
    @track hash;
    @track disableFileInput;
    @track currentCase;
    @track isLoading;
    @track showCase;

    connectedCallback() {
        const param = "Hash";
        this.hash = this.getUrlParamValue(window.location.href, param);
        this.isLoading = true;
        this.showCase = false;
        getCase({
          hashId: this.hash
        })
          .then((caseResult) => {
            this.showCase = true;
            this.isLoading = false;
            this.currentCase = caseResult;
    
            if (caseResult.Status === "Cerrado") {
              this.disableFileInput = true;
    
              const event = new ShowToastEvent({
                message: this.labels.errorDocumentacionCasoCerrado,
                variant: "warning",
                mode: "sticky"
              });
              this.dispatchEvent(event);
            }
          })
          .catch(() => {
            this.isLoading = false;
            this.disableFileInput = true;
    
            const event = new ShowToastEvent({
              message: this.labels.errorCargandoCaso,
              variant: "error",
              mode: "sticky"
            });
            this.dispatchEvent(event);
          });
      }

    uploadedLabelToUse;
    @api
    get uploadedLabel(){
        if(this.uploadedlabel == null){
            this.uploadedLabelToUse = 'Uploaded Files:';
        }
        else{
            this.uploadedLabelToUse = this.uploadedlabel;
        }
        return this.uploadedLabelToUse;
    }

    key;
    @wire(getKey) key;

    value = '';
    @wire(encrypt,{recordId: '$recordId', encodedKey: '$key.data'})
    wiredEncryption({ data }) {
        if(this.community === true){
            this.value = data;
        }
    }

    recordIdToUse = '';
    @api
    get communityDetails(){
        if(this.community !== true){
            this.recordIdToUse = this.recordId;
        }
        return this.recordIdToUse;
    }
    
    handleUploadFinished(event) {
        // Get the list of uploaded files

        const files = event.detail.files;

        var objFile;

        files.forEach(file => {

            var filetype;
            if(this.icon == null){
                filetype = getIconSpecs(file.name.split('.').pop());
            }
            else{
                filetype = this.icon;
            }
            objFile = {
                name: file.name,
                filetype: filetype,
                id: file.contentVersionId
                
            };
            this.objFiles.push(objFile);
            this.docIds.push(file.documentId);
            this.versIds.push(file.contentVersionId);
            this.fileNames.push(file.name);
        });

        if(this.community === true){
            createContentDocLink({versIds: this.versIds, encodedKey: this.key.data});
        }
        
        function getIconSpecs(docType){
            switch(docType){
                case 'csv':
                    return 'doctype:csv';
                case 'pdf':
                    return 'doctype:pdf';
                case 'pps':
                case 'ppt':
                case 'pptx':
                    return 'doctype:ppt';
                case 'xls':
                case 'xlsx':
                    return 'doctype:excel';
                case 'doc':
                case 'docx':
                    return 'doctype:word';
                case 'txt':
                    return 'doctype:txt';
                case 'png':
                case 'jpeg':
                case 'jpg':
                case 'gif':
                    return 'doctype:image';
                default:
                    return 'doctype:unknown';
            }
        }
    }
    
    deleteDocument(event){
        const recordId = event.target.dataset.recordid;
        
        deleteDocumentWithVersion({Id : recordId});

        
        let objFiles = this.objFiles;
        let removeIndex;
        for(let i=0; i<objFiles.length; i++){
            if(recordId === objFiles[i].id){
                removeIndex = i;
            }
        }

        this.objFiles.splice(removeIndex,1);
        this.docIds.splice(removeIndex,1);
        this.versIds.splice(removeIndex,1);
        this.fileNames.splice(removeIndex,1);
    }

    getUrlParamValue(url, key) {
        return new URL(url).searchParams.get(key);
    }
}