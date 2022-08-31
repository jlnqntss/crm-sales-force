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
        if ( String.isBlank(receivedData.dniNiePasaporte) || String.isBlank(receivedData.codigoPoliza) )
        {
            throw new ClientIdentificationException(
                      EMPTY_FIELD_STATUSCODE,
                      'A required field is empty'
                      );
        }

        AccountsSelector accountsSelector = new AccountsSelector();
        PoliciesSelector policiesSelector = new PoliciesSelector();

        SearchResult resultado = new SearchResult();
        resultado.polizaValida = false;

        // jgarciamartinez - 18/08/2022 - campos nuevos añadidos a petición de cliente
        resultado.existeDNI = false;
        resultado.existePoliza = false;

        // Comprobamos si existe una poliza asignada al DNI que nos envían:
        // 1.- Obtenemos el ID del Account
        List<Account> cuentasEncontradas = accountsSelector.findByNationalId(new List<String> { receivedData.dniNiePasaporte }, 'N');
        List<Policy__c> polizaEncontrada = new List<Policy__c>();

        if( !cuentasEncontradas.isEmpty() )
        {
            resultado.existeDNI = true;
            polizaEncontrada = policiesSelector.selectByHolderAndNumber(cuentasEncontradas[0].id, new Set<String> {receivedData.codigoPoliza});
        }
        else
        {
            resultado.existeDNI = false;
            polizaEncontrada = policiesSelector.selectByNumber(receivedData.codigoPoliza);
        }

        if( !polizaEncontrada.isEmpty() )
        {
            resultado.existePoliza = true;
            if(polizaEncontrada[0].PolicyStatus__c == 'V')
            {
                resultado.polizaValida = true;
            }
        }

        // Tan solo si los tres flags son true les vamos a pasar los valores
        if (resultado.existeDni && resultado.existePoliza && resultado.polizaValida)
        {
            resultado.fechaFinPoliza = polizaEncontrada[0].EndDate__c;
            resultado.fechaInicioPoliza = polizaEncontrada[0].MovementStartDate__c;
            resultado.versionPoliza = polizaEncontrada[0].policyVersion__c;
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

        public String nombreCompleto {
            get;
            set {
                setCurrentFields('nombreCompleto');
                nombreCompleto = value;
            }
        }

        public String dniNiePasaporte {
            get;
            set {
                setCurrentFields('dniNiePasaporte');
                dniNiePasaporte = value;
            }
        }
        public String codigoPoliza {
            get;
            set {
                setCurrentFields('codigoPoliza');
                codigoPoliza = value;
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
        public Boolean polizaValida;
        // jgarciamartinez - 18/08/2022 - campos nuevos añadidos a petición de cliente
        public Boolean existeDni;
        public Boolean existePoliza;
        public Date fechaFinPoliza;
        public Date fechaInicioPoliza;
        public String versionPoliza;

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
