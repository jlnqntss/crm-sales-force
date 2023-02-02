public with sharing class CustomerDataService
{

    public static Set<String> currentReceivedFields = new Set<String>(); // Campos que nos envían desde el JSON
    public static Set<String> requiredFieldsMetadataSet = new Set<String>(); // Campos obligatorios

    public static final String INVALID_FIELD_STATUSCODE = 'INVALID_FIELD';
    public static final String EMPTY_FIELD_STATUSCODE = 'EMPTY_FIELD';

    public CustomerDataService()
    {}

    public static SearchResult processIntermediaryData(Client receivedData)
    {

        PoliciesSelector policiesSelector = new PoliciesSelector();

        SearchResult resultado = new SearchResult();

        resultado.listPolicies = policiesSelector.selectByPhoneNumber(receivedData.senderAddress);

        return resultado;
    }


    //#region Métodos auxiliares
    /**
     * Método que carga el set de campos que hemos recibido desde el JSON
     *
     * @author Olalla Iglesias
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
     * @author Olalla Iglesias
     * @date 01/02/23
     */
    public static void validateReceivedInformation(Client receivedData)
    {

        List<String> fieldsNotFound = new List<String>();

        // Comprobamos que entre los recibidos están los mandatorios
        if ( !currentReceivedFields.contains( receivedData.senderAddress ) )
        {
            fieldsNotFound.add( receivedData.senderAddress );
        }

        // Si no están, lanzamos excepción
        if( !fieldsNotFound.isEmpty() )
        {
            throw new CustomerDataException(
                      INVALID_FIELD_STATUSCODE,
                      'The following fields are missing: ' +
                      fieldsNotFound.toString()
                      );
        }
    }

    //#endregion


    //#region Inner Classes
    /**
     * Representa la información del cliente que llega desde AWS
     *
     * @author Olalla Iglesias
     * @created date: 1/2/2023
     */
    public class Client
    {
        public Client()
        {}

        public String senderAddress {
            get;
            set {
                setCurrentFields('senderAddress');
                senderAddress = value;
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
     * @author Olalla Iglesias
     * @created date: 1/2/2023
     */
    public class SearchResult
    {

        public List<Policy__c> listPolicies;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    //#endregion

    //#region Excepciones

    @TestVisible
    public class CustomerDataException extends Exception
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
         * @author Olalla Iglesias
         * @created date: 1/2/2023
         */
        public CustomerDataException(String statusCode, String message)
        {
            this.setMessage(message);
            this.statusCode = statusCode;
        }
    }

    //#endregion
}
