public class BusinessInsuranceCallbackService
{
    public static final String REQUIRED_FIELD_MISSING = 'Required field is missing';
    public static final String REQUIRED_FIELD_MISSING_STATUSCODE = 'REQUIRED_FIELD_MISSING';
    public static final String FAIL_INSERT_CALLMEBACK_STATUSCODE = 'FAIL_INSERT_CALLMEBACK';
    public static final String QUEUE_NAME = 'Voz_ZurichEmpresas';
    //public static final String QUEUE_NOT_EXISTS = 'There is no queue ZurichEmpresas in Genesys Cloud';
    //public static final String QUEUE_NOT_EXISTS_STATUSCODE = 'QUEUE_NO_EXISTS';

    /**
     * Comprueba los datos de la solicitud, si el teléfono o el correo electrónico se encuentra identificado como inválido retorna verdadero.
     * Estos datos son generados a partir de un bot que lanza diariamente una serie de pruebas para comprobar
     * que la web del tarificador de Zurich Empresas funciona correctamente y sin errores.
     * Datos inválidos:
     * --Teléfono: 
     *              655004026
     * --Correo:
     *              test@zurichtest.com
     * @author rpolvera@nts-solutions.com
     * @date 17/08/2021
     * @param request Clase contenedora de la información de la soliitud -> BusinessInsuranceRaterService.Request
     * @return Verdadero si la solicitud ha sido generada por el bot de pruebas, de lo contrario retorna falso.
     */
    public static Boolean isBotTestingExecution(BusinessInsuranceCallbackService.CallMeBack request)
    {
        List<String> fakePhones = [SELECT Value__c FROM AdminSetupParameter__mdt WHERE DeveloperName = 'BusinessInsurancePhonesToIgnore']?.Value__c?.split(',');
        return fakePhones != null && fakePhones.contains(request.phone);
    }

    /**
     * valida campos obligatorios, de momento Phone
     * @param CallMeBack request que ha llegado con el formato esperado de CallMeBack
     */
    public static void validateRequiredFields(CallMeBack callMeBack)
    {
        if( callMeBack.phone == null || String.isBlank(callMeBack.phone) )
        {
            throw new BusinessInsuranceCallbackServiceException(REQUIRED_FIELD_MISSING_STATUSCODE, REQUIRED_FIELD_MISSING);
        }
    }

    /**
     * Inserta un registro de ContactRequest, necesita una cola de Genesys
     * @param requestCallMeBack request que ha llegado con el formato esperado de CallMeBack
     * @return el Id de SF del ContactRequest
     */
    public static String insertCallMeBack(CallMeBack requestCallMeBack)
    {
        String callMeBackId = '';

        //OPCIONAL - puede que no requiera funcionar con genesys
        List<purecloud__PureCloud_Queue__c> genesysQueue = new List<purecloud__PureCloud_Queue__c>();
        genesysQueue = [SELECT Id, purecloud__PureCloud_Queue_ID__c FROM purecloud__PureCloud_Queue__c WHERE Name = :QUEUE_NAME];

        List<Account> customers = AccountSearchService.findCustomersByPhoneNumber(new List<String> {requestCallMeBack.phone}, RecordsSelector.Scope.ZE, RecordsSelector.LegalEntity.ALL);

        try
        {
            ContactRequest callMeBack = new ContactRequest();
            callMeBack.PreferredContactDatetime__c = BusinessInsuranceUtil.getPreferredContactDatetime(requestCallMeBack.bestTimeFrom);
            callMeBack.PreferredPhone = requestCallMeBack.phone;
            callMeBack.WebName__c = requestCallMeBack.name;
            if( !genesysQueue.isEmpty() )
            {   //Cola de Genesys OPCIONAL, si no se rellena, no entrará al ProcessBuilder que rellena el id de interacción
                callMeBack.GenesysCloudQueueId__c = genesysQueue[0].Id;
            }
            if( !customers.isEmpty() )
            {
                callMeBack.WhoId = customers.get(0).PersonContactId;
            }
            insert callMeBack;
            callMeBackId = String.valueOf(callMeBack.Id);
        }
        catch(Exception e)
        {
            throw new BusinessInsuranceCallbackServiceException( FAIL_INSERT_CALLMEBACK_STATUSCODE, e.getMessage() + ' ' + e.getStackTraceString() );
        }

        return callMeBackId;
    }

    /**
     * Clase interna que representa una solicitud de Call Me Back
     * llegado desde el formulario web de Zurich Empresas
     */
    public class CallMeBack
    {
        public String name {get; set;}
        public String phone {get; set;}
        public Datetime bestTimeFrom {get; set;}
        public Datetime bestTimeUntil {get; set;}
    }

    /**
     * Clase interna para representar un error que se produzca dentro de BusinessInsuranceCallbackService
     */
    public class BusinessInsuranceCallbackServiceException extends Exception
    {
        public String statusCode;
        public String message
        {
            get
            {
                return this.getMessage();
            }
        }

        public BusinessInsuranceCallbackServiceException(String statusCode, String message)
        {
            this.setMessage(message);
            this.statusCode = statusCode;
        }
    }
}