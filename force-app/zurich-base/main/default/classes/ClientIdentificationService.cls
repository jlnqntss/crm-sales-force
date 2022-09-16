public with sharing class ClientIdentificationService
{

    public static Set<String> currentReceivedFields = new Set<String>(); // Campos que nos envían desde el JSON
    public static Set<String> requiredFieldsMetadataSet = new Set<String>(); // Campos obligatorios

    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';
    public static final String EMPTY_FIELD_STATUSCODE = 'EMPTY_FIELD';

    public ClientIdentificationService()
    {}

    public static SearchResult processData(Client receivedData)
    {
        if ( String.isBlank(receivedData.nationalID) || String.isBlank(receivedData.policyNumber) )
        {
            throw new ClientIdentificationException(
                      EMPTY_FIELD_STATUSCODE,
                      'A required field is empty'
                      );
        }

        AccountsSelector accountsSelector = new AccountsSelector();
        PoliciesSelector policiesSelector = new PoliciesSelector();
        AssetsSelector assetsSelector = new AssetsSelector();

        SearchResult resultado = new SearchResult();
        resultado.isValidPolicy = false;

        // jgarciamartinez - 18/08/2022 - campos nuevos añadidos a petición de cliente
        resultado.existsNationalID = false;
        resultado.existsPolicy = false;

        // Comprobamos si existe una poliza asignada al DNI que nos envían:
        // 1.- Obtenemos el ID del Account
        List<Account> cuentasEncontradas = accountsSelector.findByNationalId(new List<String> { receivedData.nationalID }, 'N');
        List<Policy__c> polizaEncontrada = new List<Policy__c>();

        if( !cuentasEncontradas.isEmpty() )
        {
            resultado.existsNationalID = true;
            polizaEncontrada = policiesSelector.selectByHolderAndNumber(cuentasEncontradas[0].id, new Set<String> {receivedData.policyNumber});
        }
        else
        {
            resultado.existsNationalID = false;
            polizaEncontrada = policiesSelector.selectByNumber(receivedData.policyNumber);
        }

        if( !polizaEncontrada.isEmpty() )
        {
            resultado.existsPolicy = true;
            if(polizaEncontrada[0].PolicyStatus__c == 'V')
            {
                resultado.isValidPolicy = true;
            }
        }

        // Tan solo si los tres flags son true les vamos a pasar los valores
        if (resultado.existsNationalID && resultado.existsPolicy && resultado.isValidPolicy)
        {
            resultado.policyEndDate = polizaEncontrada[0].EndDate__c;
            resultado.policyStartDate = polizaEncontrada[0].MovementStartDate__c;
            resultado.policyVersion = polizaEncontrada[0].policyVersion__c;
            
            List<Asset> obtainedAssets = assetsSelector.selectByPolicyID(polizaEncontrada[0].id);
            if(!obtainedAssets.isEmpty())
            {
                resultado.policyInfoInsuredObject = obtainedAssets[0].INFOInsuredObjectCode__c;
            }
        } 

        return resultado;
    }


    //#region Métodos auxiliares
    /**
     * Método que carga el set de campos que hemos recibido desde el JSON
     *
     * @author arcortazar
     * @date 09/06/2022
     */
    public static void setCurrentFields(String field)
    {
        currentReceivedFields.add(field.toLowerCase());
    }

    /**
     * Método que valida que no falte ninguno de los campos requeridos
     *
     * @return List<String> fieldsNotFound listado de campos no encontrado en el JSON
     * @author rlopez
     * @date 21/10/2020
     */
    public static void validateReceivedInformation(Client receivedData)
    {
        // Obtenemos los campos que son mandatorios
        List<Client_Identification__mdt> requiredFieldsMetadataSet = Client_Identification__mdt.getAll().values();

        // Comprobamos que entre los recibidos están los mandatorios
        List<String> fieldsNotFound = new List<String>();
        for (Client_Identification__mdt field : requiredFieldsMetadataSet)
        {
            if ( !currentReceivedFields.contains( field.Label.toLowercase() ) )
            {
                fieldsNotFound.add( field.Label.toLowercase() );
            }
        }

        // Si no están, lanzamos excepción
        if( !fieldsNotFound.isEmpty() )
        {
            throw new ClientIdentificationException(
                      INVALID_FIELD_STATUSCODE,
                      'The following fields are missing: ' +
                      fieldsNotFound.toString()
                      );
        }
    }

    //#endregion


    //#region Inner Classes
    /**
     * Representa la información del cliente que llega desde Thunder
     *
     * @author arcortazar
     * @created date: 09/06/2022
     */
    public class Client
    {
        public Client()
        {}

        public String fullName {
            get;
            set {
                setCurrentFields('fullName');
                fullName = value;
            }
        }

        public String nationalID {
            get;
            set {
                setCurrentFields('nationalID');
                nationalID = value;
            }
        }
        public String policyNumber {
            get;
            set {
                setCurrentFields('policyNumber');
                policyNumber = value;
            }
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa los resultados de búsqueda del CRM
     *
     * @author arcortazar
     * @created date: 09/06/2022
     */
    public class SearchResult
    {
        public Boolean isValidPolicy;
        // jgarciamartinez - 18/08/2022 - campos nuevos añadidos a petición de cliente
        public Boolean existsNationalID;
        public Boolean existsPolicy;
        public Date policyEndDate;
        public Date policyStartDate;
        public String policyVersion;
        public String policyInfoInsuredObject;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    //#endregion

    //#region Excepciones

    @TestVisible
    public class ClientIdentificationException extends Exception
    {
        public String statusCode;
        public String message
        {
            get
            {
                return this.getMessage();
            }
        }

        /**
         * Constructor por defecto
         * @author arcortazar
         * @created date: 09/06/2022
         */
        public ClientIdentificationException(String statusCode, String message)
        {
            this.setMessage(message);
            this.statusCode = statusCode;
        }
    }

    //#endregion
}
