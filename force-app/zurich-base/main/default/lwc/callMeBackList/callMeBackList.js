import { LightningElement, api, track } from 'lwc';
import getContactRequestsById from '@salesforce/apex/CallMeBackListController.getContactRequestsById';
import statusToCancelled from '@salesforce/apex/CallMeBackListController.statusToCancelled';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import genesysCloud from "c/genesysCloudService";
/**
* Componente que muestra una lista de contactRequests del cliente cuya ficha se encuentre
**
* @author Kevin Rueda
* @date 02/09/2021
*/

export default class CallMeBackList extends LightningElement {
    
    @api recordId;
    @api firstColumnAsRecordHyperLink;
    @api fieldSetName;
    @track record = {};
    @track columns;
    @track tableData;
    @track completeTableData;
    @track maxRows = 7;
    isModalOpen = false;
    showTable;
    loadMoreVisible;
    noRecords;
    title;

    /**
    * Realiza una llamada al método preparado en la clase ContactRequestUtil para recuperar los campos y registros a mostrar,
    * y hace la carga inicial de la tabla
    **
    * @author Kevin Rueda
    * @date 02/09/2021
    */
    connectedCallback(){
        let firstTimeEntry = false;
        let firstFieldAPI;

        getContactRequestsById({strfieldSetName: this.fieldSetName, criteriaFieldValue: this.recordId})
        .then(data=>{        

            //Recoger el mapa
            let objStr = JSON.parse(data);
            
            // Comprobar si hay registros, de lo contrario no queremos mostrar la tabla
            this.checkRecords(objStr);
            this.makeTitle();
            // Recoger los campos
            let listOfFields= JSON.parse(Object.values(objStr)[1]);

            //Recoger los registros del mapa
            let listOfRecords = JSON.parse(Object.values(objStr)[0]);
            let items = []; //Array que incluirá las columnas
            listOfFields.map(element=>
            {
                //Sólo pasa en la primera columna
                if(this.firstColumnAsRecordHyperLink !=null && this.firstColumnAsRecordHyperLink==='Yes' && firstTimeEntry===false)
                {
                    firstFieldAPI  = element.fieldPath; 
                    //Declaración de la primera columna como Hyperlink para el registro correspondiente                                     
                    items = [...items ,
                                {
                                    label: element.label, 
                                    fieldName: 'URLField',
                                    type: 'url', 
                                    typeAttributes: { 
                                        label: {
                                            fieldName: element.fieldPath
                                        },
                                        tooltip: 'Acceder al registro',
                                        target: '_self'
                                    },
                                    hideDefaultActions: true
                                }
                    ];
                    firstTimeEntry = true;
                } else
                {
                    items = [...items ,{label: element.label, fieldName: element.fieldPath, hideDefaultActions: true}];
                }   
            });
            items = [...items , { initialWidth: 80, type: 'button-icon', typeAttributes:
            {
                iconName: 'utility:clear',
                name: 'cancelConReq', 
                title: 'Cancelar Call me back', 
                variant: 'container'
            }}];
                            //Asignación de columnas y datos de la tabla
            this.columns = items;
            this.tableData = listOfRecords;
                            //Preparar el primer campo de tabla como link al registro correspondiente del objeto 
            if(this.firstColumnAsRecordHyperLink !=null && this.firstColumnAsRecordHyperLink==='Yes')
            {
                let diplayedRows;
                if(listOfRecords.length > this.maxRows)
                {
                    diplayedRows = listOfRecords.slice(0,this.maxRows);
                    this.loadMoreVisible = 'slds-show';
                }else{
                    diplayedRows = listOfRecords;
                    this.loadMoreVisible = 'slds-hide';
                }
                let URLField;
                //Rellenado de las horas de contacto
                this.tableData = diplayedRows.map(item=>{
                    URLField = '/lightning/r/ContactRequest/' + item.Id + '/view';
                    return {...item,URLField};                     
                });
                this.tableData = this.tableData.filter(item => item.fieldPath  !== firstFieldAPI);
                //Rellenado del estado del CallMeBack
                this.completeTableData = listOfRecords.map(item=>{
                    URLField = '/lightning/r/ContactRequest/' + item.Id + '/view';
                    return {...item,URLField};                
                });
                this.completeTableData = this.completeTableData.filter(item => item.fieldPath  !== firstFieldAPI);
            }
            this.error = undefined;
        })
        .catch(error =>{
            this.error = error;
            console.log('error',error);
            this.tableData = undefined;
        })        
    }
    
    /**
    * Maneja el evento que ocurre al pulsar en el botón de cada fila de la tabla, y se encarga de recoger el InteractionId del
    * contactRequest y lo plasma dentro de un Toast
    **
    * @author jjuaristi
    * @date 28/10/2021
    */
    async handleRowAction(event)
    {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        
        // Si el usuario no está autorizado será redireccionado.
        if (!(await this.isAuthorized())) {
            this.showMessage(
            this.labels.errorTitle,
            this.labels.callRecordingAuthError,
            "warning"
            );
            this.authorize();
        } 
        else {
            statusToCancelled({genesysInteractionId : row.GenesysInteractionId__c})
            .then((result) => {
                console.log(result);
                genesysCloud.cancelCallBack(row.GenesysInteractionId__c, result);
            })
            
            switch (actionName)
            {
                case 'cancelConReq':
                    this.record = row;
                    this.showMessage( 'Éxito',
                                    // TODO Hardcodeado para pasarlo a hotfix, poner la label antes de hacer el commit
                                    'Se envió correctamente la solicitud de cancelación a Genesys',
                                    'success');
                    break;                      
                default:
            }
        }
    }

    /**
    * Controla la ventana modal
    **
    * @author jjuaristi
    * @date 27/10/2021
    */
    modalControl(){
        this.isModalOpen = !this.isModalOpen;
        return this.isModalOpen;
    }

      /**
   * Muestra una notoificación en forma de mensaje emergente en la interfaz de usuario.
   *
   * @param {String} title Título del error presentado.
   * @param {String} text Mensaje a mostrar.
   * @param {String} variant Variación del aspecto de la alerta, los posibles valores son: (warning, success, error)
   */
    showMessage(title, text, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: text,
            variant: variant
        });
        this.dispatchEvent(event);
  }

     /**
   * Se comprueba si el usuario actual se ha autorizado en el sistema externo utilizando sus credenciales con nombre.
   * Esta configuración se encuentra a nivel de usuario.
   * Es necesaria este tipo de autorización para consumir las APIs de Conversaciones de GenesysCloud ya que se efectuan en contexto de usuario.
   *
   * @date 02/11/2021
   * @author rpolvera
   * @returns Verdadero si está autorizado, falso si no está autorizado.
   */
  async isAuthorized() {
    try {
      return await genesysCloud.isAuthorized();
    } catch (error) {
      console.log("Exception: CallRecordingButton.isAuthorized()", error);
      this.showMessage(
        this.labels.errorTitle,
        this.labels.recordingException,
        "error"
      );
      return false;
    }
  }

  /**
   * Se redirecciona al usaurio a la pantalla de autorización con GenesysCloud.
   *
   * @date 02/11/2021
   * @author rpolvera
   */
  async authorize() {
    try {
      await genesysCloud.authorize();
    } catch (error) {
      console.log("Exception: CallRecordingButton.authorize()", error);
      this.showMessage(
        this.labels.errorTitle,
        this.labels.recordingException,
        "error"
      );
    }
  }

    checkRecords(objString){
        if(objString.RECORD_LIST === '[]'){
             this.noRecords = true;
        }else{
            this.noRecords = false;
        }
    }

    makeTitle(){
        this.title = "Call me backs";
        if(this.noRecords){
            this.title =this.title + " (0)";
        }
    }
}