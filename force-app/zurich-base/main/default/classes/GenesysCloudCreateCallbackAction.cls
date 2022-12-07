public with sharing class GenesysCloudCreateCallbackAction
{
    /**
     * Acción invocable que crea una tarea de tipo call-me-back, definido por CreateCallbackRequest, en Genesys Cloud.
     *  Delega la ejecución a GenesysCloud.CallbacksService.create
     * Delega la ejecución a GenesysCloud.RoutingService.route
       @param requests Petición de enrutamiento. Formato lista para permitir el bulkificado del flow
     */
    @InvocableMethod(
        label='Create Callback in Genesys Cloud'
               description='Allows to create callbacks through Genesys Cloud'
                            category= 'Other'
        )
    public static void execute(List<CreateCallbackRequest> requests)
    {
        Map<GenesysCloud.Callback, String> contactRequestIdsByCallback = new Map<GenesysCloud.Callback, String>();

        for(CreateCallbackRequest request : requests)
        {
            contactRequestIdsByCallback.put(request.toCallback(), request.activityId);
        }

        GenesysCloud.CallbacksService.create( new List<GenesysCloud.Callback>( contactRequestIdsByCallback.keySet() ), new UpdateContactRequestsCallback(contactRequestIdsByCallback) );
    }

    /**
     * Se crea un CreateCallbackRequest desde el Flow y se transforma en un Callback
     */
    public class CreateCallbackRequest
    {
        @InvocableVariable(label = 'Contact Request Id' description='Id de SF de la tarea')
        public String activityId;
        @InvocableVariable(label = 'Script Id' description='Identificador del script a utilizar en el callback')
        public String scriptId;
        @InvocableVariable(label = 'Callback User Name' description='Nombre de la persona sobre la que se está programando la llamada')
        public String callbackUserName;
        @InvocableVariable(label = 'Callback Numbers' description='Listado de números a llamar' required=true)
        public String callbackNumbers;
        @InvocableVariable(label = 'Callback Scheduled Time' description='Fecha/hora de la programación')
        public Datetime callbackScheduledTime;
        @InvocableVariable(label = 'Validate Callback Numbers' description='Validar los números pasados')
        public Boolean validateCallbackNumbers;
        @InvocableVariable(label = 'Country Code' description='Código del país.')
        public String countryCode;
        @InvocableVariable(label = 'Screen Pop Record Id' description='Propiedad que al setearse incluye en el mapa data el valor SF_URLPop con el valor asignado')
        public String screenPopRecordId;
        @InvocableVariable(label = 'Queue Id' description='Cola en la que enrutar el callback. Solo se puede especificar routingData o queueId.' required=true)
        public String queueId;
        @InvocableVariable(label = 'Language Id' description='Idioma')
        public String languageId;
        @InvocableVariable(label = 'Priority' description='Prioridad (0-99) a aplicar al callback')
        public Integer priority;
        @InvocableVariable(label = 'Skills' description='Skills necesarios para el enrutamiento')
        public String[] skills;
        @InvocableVariable(label = 'Preferred Agent Ids' description='Ids de agentes preferidos')
        public String[] preferredAgentIds;

        /**
         * Hará uso tanto de GenesysCloud.Callback como de GenesysCloud.CallbackRoutingData para poder formar el callback por completo.
         * @return Devuelve una tarea en el formato GenesysCloud.Callback utilizando los datos dados por la tarea
         */
        public GenesysCloud.Callback toCallback()
        {
            GenesysCloud.Callback callback = new GenesysCloud.Callback();
            GenesysCloud.CallbackRoutingData callbackRoutingData = new GenesysCloud.CallbackRoutingData();

            callbackRoutingData.queueId = this.queueId;
            callbackRoutingData.languageId = this.languageId;
            callbackRoutingData.priority = this.priority;
            callbackRoutingData.skillIds = this.skills;
            callbackRoutingData.preferredAgentIds = this.preferredAgentIds;

            callback.routingData = callbackRoutingData;
            callback.scriptId = this.scriptId;
            callback.callbackUserName = this.callbackUserName;
            callback.callbackNumbers = new List<String> {this.callbackNumbers}; //ContactRequest.PreferredPhone is a single phone
            callback.callbackScheduledTime = this.callbackScheduledTime;//Dates must be specified as ISO-8601 strings. For example: yyyy-MM-ddTHH:mm:ss.SSSZ
            callback.validateCallbackNumbers = this.validateCallbackNumbers;
            callback.countryCode = this.countryCode;
            callback.screenPopRecordId = this.screenPopRecordId;

            return callback;
        }
    }

    /**
     * Apex Callback llamado UpdateContactRequestCallback que actualizará el campo GenesysId del ContactRequest con lo que se haya rellenado en Callback.genesysId.
     */
    private class UpdateContactRequestsCallback implements GenesysCloud.IAPICallback
    {
        Map<GenesysCloud.Callback, String> contactRequestIdsByCallback;

        public UpdateContactRequestsCallback(Map<GenesysCloud.Callback, String> contactRequestIdsByCallback)
        {
            this.contactRequestIdsByCallback = contactRequestIdsByCallback;
        }

        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            List<ContactRequest> contactRequests = new List<ContactRequest>();

            for(Object result : results)
            {
                GenesysCloud.Callback callback = (GenesysCloud.Callback) result;
                Id contactRequestId = contactRequestIdsByCallback.get(callback);

                if( String.isNotEmpty(contactRequestId) )
                {
                    contactRequests.add( new ContactRequest(
                                             Id = contactRequestId,
                                             GenesysInteractionId__c = callback.genesysId
                                             ) );
                }
            }

            update contactRequests;
        }

        public void onError(Exception error)
        {
            ErrorLogUtil.commitError(error);
        }
    }
}


