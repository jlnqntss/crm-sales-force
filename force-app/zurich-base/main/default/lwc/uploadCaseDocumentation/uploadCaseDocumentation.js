import { LightningElement, api, track } from "lwc";
import saveFile from "@salesforce/apex/UploadCaseDocumentationController.saveFile";
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
import getUrlToUploadFiles from "@salesforce/apex/UploadCaseDocumentationController.getUrlToUploadFiles";
import createContentDocumentLink from "@salesforce/apex/UploadCaseDocumentationController.createContentDocumentLink";

export default class UploadCaseDocumentation extends LightningElement {
  /**
   * @desciption File MAX SIZE
   * @type {Integer}
   */
  MAX_FILE_SIZE = 25000000;

  /**
   * @desciption Uploaded Files
   * @type {Array<File>}
   */
  filesUploaded = [];

  /**
   * @desciption Items to be showed to pills
   * @type {Array<PillElement>}
   */
  @track filesToPill = [];

  /**
   * @desciption Actual File size
   * @type {String}
   */
  actualFilesSize = 0;

  labels = {
    solicitudDocumentacionCaso,
    fechaCreacionCaso,
    estadoActualCaso,
    tamanoMaximoSubidaDocumentacion,
    errorDocumentacionCasoCerrado,
    errorCargandoCaso,
    documentacionAdjuntadaCorrectamente,
    errorSubiendoDocumentacion
  };

  zurichLogoUrl = ZURICH_LOGO;
  @api hash;
  @track disableFileInput;
  @track currentCase;
  @track caseError;
  @track isLoading;
  @track showCase;
  @track caseStatusStyle = "slds-theme_success";

  @track messageContent;

  connectedCallback() {
    const param = "Hash";
    const paramValue = this.getUrlParamValue(window.location.href, param);
    var that = this;
    this.isLoading = true;
    this.showCase = false;
    getCase({
      hashId: paramValue
    })
      .then(function (caseResult) {
        console.log(caseResult);
        that.showCase = true;
        that.isLoading = false;
        that.currentCase = caseResult;

        if (caseResult.Status === "Cerrado") {
          that.caseStatusStyle = "slds-theme_error";
          that.disableFileInput = true;
          that.showToast(
            that,
            that.labels.errorDocumentacionCasoCerrado,
            "warning",
            false
          );
        }
      })
      .catch(function (err) {
        console.log(err);

        that.isLoading = false;
        that.disableFileInput = true;

        that.error = err;
        that.showToast(that, that.labels.errorCargandoCaso, "error", false);
      });
  }

  getUrlParamValue(url, key) {
    return new URL(url).searchParams.get(key);
  }

  handleFilesChangeStandard() {
    createContentDocumentLink({
      guestHash: this.currentCase.Id
    })
      .then(function (resp) {
        console.log("Success: " + resp[0]);
      })
      .catch(function (err) {
        console.log("Error: " + err[0]);
      });
  }

  /**
   * @description Gestiona eliminar un fichero de subida
   * @author jbarcelo
   * @date 13/07/2020
   * @param {ChangeEvent} event - Evento con informacion del fichero eliminado
   */
  handlePillRemove(event) {
    const index = event.detail.index;
    this.actualFilesSize =
      this.actualFilesSize - this.filesUploaded[index].size;
    this.filesUploaded.splice(index, 1);
    this.generatePills(this.filesUploaded);
  }

  get hasFiles() {
    return this.filesToPill != null && this.filesToPill.length > 0
      ? true
      : false;
  }

  handleFileUpload(event) {
    var formatAccepted = ["png", "jpeg", "jpg", "pdf"];
    var currentFilesSize = this.actualFilesSize;
    var allValidFormats = true;

    for (var i = 0; i < event.target.files.length; i++) {
      let name = event.target.files[i].name;
      let format = name.slice(((name.lastIndexOf(".") - 1) >>> 0) + 2);
      // Si no es un archivo permitido pasamos de el
      if (formatAccepted.includes(format.toLowerCase())) {
        currentFilesSize += event.target.files[i].size;
      } else {
        allValidFormats = false;
      }
    }

    // Si se pasa de tamaño no continuar
    /*if(!allValidFormats){
            window.alert(ErrorFormatFilesMessage);
        }*/

    if (currentFilesSize > this.MAX_FILE_SIZE) {
      //window.alert(ErrorSizeFilesMessage /*currentFilesSize*/);
      return;
    } else {
      this.actualFilesSize = currentFilesSize;
      for (var i = 0; i < event.target.files.length; i++) {
        let name = event.target.files[i].name;
        let format = name.slice(((name.lastIndexOf(".") - 1) >>> 0) + 2);
        // Solo metemos los que hemos permitido
        if (formatAccepted.includes(format.toLowerCase())) {
          this.filesUploaded.push(event.target.files[i]);
        }
      }
    }

    // Generamos la vista
    this.generatePills(this.filesUploaded);
  }

  async clickSubmit() {
    console.log("upload documents");
    console.log(this.filesUploaded);
    var mapFiles = [];
    if (this.filesUploaded.length > 0) {
      //Leer Archivos almacenados
      await this.readmultifiles(this.filesUploaded, mapFiles);

      //Conseguir url dependiente de la organizacion
      var url = await this.getUrlToUploadFilesHandled(true);

      for (let i = 0; i < mapFiles.length; i++) {
        //Insertar archivo
        let resultInsertFile = await this.insertFilesToCase(
          this.currentCase.Id,
          mapFiles[i].name,
          mapFiles[i].content,
          url
        );

        // Si va mal borrar caso
        if (!resultInsertFile) {
          //this.showNotificationToast('Error', ErrorInsertFilesMessage, 'error');
          //this.showNotificationFunction('Error', ErrorInsertFilesMessage, 'error');
          break;
        }
      }
    }
  }

  /**
   * @description Inserta archivos en binario usando un servicio Rest de SF
   * @author jbarcelo
   * @date 13/07/2020
   * @param {String} caseId - Id caso
   * @param {String} fileName - Nombre del archivo a insertar
   * @param {Blob} fileName - Contenido en binario del archivo a insertar
   * @param {String} url - Url de la instancia a la que se tiene que mandar
   */
  async insertFilesToCase(caseId, fileName, fileContent, url) {
    var isCorrect = false;
    console.log("CaseId: " + caseId);
    console.log("URL: " + url);
    console.log(
      "URL COMPLETA: " +
        url +
        "/services/apexrest/cases/" +
        caseId +
        "/filename/" +
        fileName
    );
    await fetch(
      "https://devc-zurich.cs89.force.com/uploadcasedocs/s" +
        "/services/apexrest/cases/" +
        caseId +
        "/filename/" +
        fileName,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/octet-stream"
        },
        mode: "cors",
        cache: "default",
        body: fileContent
      }
    )
      .then((response) => {
        console.log("response: " + response);
        return response.text();
      })
      .then((response) => {
        console.log("response 2: " + response);
        if (response.includes("Error")) {
          isCorrect = false;
        } else {
          isCorrect = true;
        }

        // console.log(response);
      })
      .catch((error) => {
        console.log("Error: " + error.message);
        isCorrect = false;
      });

    return isCorrect;
  }

  /**
   * @description Lee archivos en binario
   * @author jbarcelo
   * @date 13/07/2020
   * @param {Array<FileReader>} files - Lista de archivos a leer
   * @param {Array<File>} mapFiles - Mapa de archivos leidos en binario con su nombre y el contenido
   */
  async readmultifiles(files, mapFiles) {
    function readFile(files, mapFiles, index) {
      return new Promise((resolve, reject) => {
        var reader = new FileReader();
        var file = files[index];
        reader.onload = function (e) {
          var actualFile = {};
          // get file content
          actualFile.name = file.name;

          var fileContents = e.target.result;

          actualFile.content = fileContents;

          mapFiles.push(actualFile);

          resolve();
        };
        reader.readAsArrayBuffer(file);
      });
    }

    for (var i = 0; i < files.length; i++) {
      await readFile(files, mapFiles, i);
    }
  }

  /**
   * @description Recupera url para la subida de archivos
   * @author jbarcelo
   * @date 13/07/2020
   * @param {Boolan} isCommunity - Indica si se hace desde una comunidad
   */
  async getUrlToUploadFilesHandled(isCommunity) {
    var url = "";
    await getUrlToUploadFiles({ community: isCommunity })
      .then((result) => {
        url = result;
      })
      .catch((error) => {
        url = "";
      });

    return url;
  }

  /**
   * @description Genera las pill de los archivos insertados
   * @author jbarcelo
   * @date 13/07/2020
   * @param {String} files - Archivos a representar
   */
  generatePills(files) {
    this.filesToPill = [];

    if (files) {
      var index = 1;
      files.forEach((f) => {
        let pill = {};
        pill.type = "avatar";
        pill.variant = "circle";
        pill.fallbackIconName = "standard:contract";
        pill.alternativeText = f.name;
        pill.label = f.name;
        pill.name = f.name + index;
        index++;
        this.filesToPill.push(pill);
      });
    }
  }

  showToast(context, message, type, transition) {
    context.messageContent = {
      class: "slds-theme_" + type,
      icon: "utility:" + type,
      title: type,
      message: message,
      transition: transition
    };
  }

  get toastClassName() {
    var that = this;
    if (this.messageContent != null) {
      if (this.messageContent.transition) {
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(function () {
          that.messageContent = undefined;
        }, 6000);
      }
      return this.messageContent.transition ? "show" : "";
    }

    return "notshow";
  }
}
