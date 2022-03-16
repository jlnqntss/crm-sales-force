public class GenesysCloud
{
    @TestVisible
    private static final String ERROR_IN_RESPONSE = 'response is null';
    @TestVisible
    private static final String ERROR_RESPONSE_SDK = 'response from genesys cloud SDK: ';
    @TestVisible
    private static final String ERROR_VALIDATE_RESPONSE = 'Service is a required parameter to validate a response';
    private static final String ASYNC_METHOD_SMS = 'sms';
    private static final String ASYNC_METHOD_CALLBACK_CANCEL = 'cancel';
    private static final String ASYNC_METHOD_DISCONNECTION = 'disconnect';
    public static final String SERVICE_ROUTING = 'RoutingService';
    public static final String SERVICE_CALLBACKS = 'CallbacksService';
    public static final String SERVICE_SMS = 'SMSService';
    public static final String SERVICE_DISCONNECTION = 'DisconnectionService';

    public enum GenesysCloudServices { SERVICE_ROUTING, SERVICE_CALLBACKS, SERVICE_SMS, SERVICE_DISCONNECTION }

    public class GenesysCloudException extends Exception
    {
        public GenesysCloudException(HttpResponse response)
        {
            this.setMessage(String.format('{0}: {1} \n{2}',new List<String>
            {
                response.getStatusCode() + '',
                response.getStatus(),
                response.getBody()
            }) );
        }
    }

    //#region Módulos

    /**
     * Getter de solo lectura que devuelve la instancia Singleton de RoutingService
     */
    public static GenesysCloud.RoutingService RoutingService
    {
        get
        {
            if(RoutingService == null)
            {
                RoutingService = new GenesysCloud.RoutingService();
            }

            return RoutingService;
        }
        private set;
    }
    /**
     * Getter de solo lectura que devuelve la instancia Singleton de CallbacksService
     */
    public static GenesysCloud.CallbacksService CallbacksService
    {
        get
        {
            if(CallbacksService == null)
            {
                CallbacksService = new GenesysCloud.CallbacksService();
            }

            return CallbacksService;
        }
        private set;
    }

    /**
     * Getter de solo lectura que devuelve la instancia Singleton de SMSService
     */
    public static GenesysCloud.SMSService SMSService
    {
        get
        {
            if(SMSService == null)
            {
                SMSService = new GenesysCloud.SMSService();
            }

            return SMSService;
        }
        private set;
    }

    /**
     * Getter de solo lectura que devuelve la instancia Singleton de CallbacksService
     */
    public static GenesysCloud.CallsService CallsService
    {
        get
        {
            if(CallsService == null)
            {
                CallsService = new GenesysCloud.CallsService();
            }

            return CallsService;
        }
        private set;
    }

    /**
     * Getter de solo lectura que devuelve la instancia Singleton de DisconnectService
     */
    public static GenesysCloud.DisconnectionService DisconnectionService
    {
        get
        {
            if(DisconnectionService == null)
            {
                DisconnectionService = new GenesysCloud.DisconnectionService();
            }

            return DisconnectionService;
        }
        private set;
    }

    public static GenesysCloud.StatusService StatusService
    {
        get
        {
            if (StatusService == null)
            {
                StatusService = new StatusService();
            }
            return StatusService;
        }
        private set;
    }

    public static GenesysCloud.PatchService PatchService
    {
        get
        {
            if (PatchService == null)
            {
                PatchService = new PatchService();
            }
            return PatchService;
        }
        private set;
    }

    //#endregion

    //#region Métodos y clases para la realización de invocaciones asíncronas

    /**
     * Realiza una petición asíncrona al API de Genesys Cloud controlando los límites de SF
     * Gestiona la finalización a través de un callout
     *
     * @param  String method  Nombre del método a ejecutar de forma asíncrona
     * @param  {IAPIRequest[]} requests Peticiones a procesar
     * @param  {IAPICallback} callback Callback de gestión de respuestas del API
     */
    private static void asynchronousCallout(String method, List<IAPIRequest> requests, IAPICallback callback)
    {
        Integer totalRequests = requests.size();
        List<IAPIRequest> batchRequests = new List<IAPIRequest>();

        while(totalRequests-- > 0)
        {
            batchRequests.add(requests.remove(totalRequests) );

            if(batchRequests.size() == 50)
            {
                System.enqueueJob(new AsynchronousCalloutJob(method, batchRequests, callback) );
                batchRequests.clear();
            }
        }

        if(!batchRequests.isEmpty() )
        {
            System.enqueueJob(new AsynchronousCalloutJob(method, batchRequests, callback) );
            batchRequests.clear();
        }
    }


    /**
     * Trabajo que procesa un subconjunto de 50 peticiones al API REST de Genesys Cloud
     *
     * @author jmartinezpisson
     */
    private class AsynchronousCalloutJob implements Queueable, Database.AllowsCallouts
    {
        String method;
        List<IAPIRequest> requests;
        IAPICallback callback;

        /**
         * Inicializa el trabajo encolado con los parámetros necesarios para la ecjución de los callouts
         *
         * @author jmartinezpisson
         * @param  String method  Nombre del método a ejecutar de forma asíncrona
         * @param  {IAPIRequest[]} requests PEticiones a procesar
         * @param  {IAPICallback} callback Callback de gestión de respuestas del API
         */
        public AsynchronousCalloutJob(String method, List<IAPIRequest> requests, IAPICallback callback)
        {
            this.method = method;
            this.requests = requests;
            this.callback = callback;
        }

        /**
         * Ejecuta la implementación síncrona por petición pasada especificada por method
         *
         * @author jmartinezpisson
         * @param  {QueueableContext} context Contexto del Job
         */
        public void execute(QueueableContext context)
        {
            try
            {
                List<Object> results = new List<Object>();

                if(this.method == 'route')
                {
                    for(IAPIRequest request : this.requests)
                    {
                        results.add(RoutingService.route( (RoutingWork) request ) );
                    }
                }
                else if(this.method == 'create')
                {
                    for(IAPIRequest request : this.requests)
                    {
                        results.add(CallbacksService.create( (Callback) request ) );
                    }
                }
                else if(this.method == ASYNC_METHOD_SMS )
                {
                    for(IAPIRequest request: this.requests)
                    {
                        results.add(SMSService.send( (SmsData) request ) );
                    }
                }
                else if(this.method == ASYNC_METHOD_CALLBACK_CANCEL )
                {
                    for(IAPIRequest request: this.requests)
                    {
                        results.add(CallbacksService.cancel( (CallbackCancel) request ) );
                    }
                }
                else if(this.method == ASYNC_METHOD_DISCONNECTION )
                {
                    for(IAPIRequest request: this.requests)
                    {
                        results.add(DisconnectionService.close( (InteractionCancel) request ) );
                    }
                }
                else
                {
                    throw new RoutingServiceException('No method defined');
                }

                if(this.callback != null)
                {
                    this.callback.onSuccess(results, this.requests);
                }
            }
            catch(Exception error)
            {
                if(this.callback != null)
                {
                    this.callback.onError(error);
                }
            }
        }
    }

    /**
     * Representa un elemento utilizado en un recurso REST de Genesys como una solicitud de enrutamiento
     */
    public interface IAPIRequest
    {
        //Método que devuelve una serialización a JSON de la propia instancia de la clase para su uso en las llamadas al SDK.
        String toJSON();
    }

    /**
     * Representa una función de callback del API de Genesys Cloud
     *
     * @author jmartinezpisson
     */
    public interface IAPICallback
    { 
        void onSuccess(List<Object> results, List<IAPIRequest> requests);
        void onError(Exception error);
    }
    //#endregion


    /**
     * Comprueba si la respuesta ha sido un 200 o 202, sino lanza Exception
     * @param response HttpResponse del SDK
     */
    @testvisible
    private static void validateResponse(HttpResponse response, GenesysCloudServices service)
    {
        if(service == null)
        {
            throw new GenesysCloud.GenesysCloudException(ERROR_VALIDATE_RESPONSE);
        }
        switch on service
        {
            when SERVICE_ROUTING {
                if(response == null || response.getStatusCode() != 200)
                {
                    throw new GenesysCloud.RoutingServiceException(response);
                }
            }
            when SERVICE_CALLBACKS {
                if(response == null || response.getStatusCode() != 202)
                {
                    throw new GenesysCloud.CallbacksServiceException(response);
                }
            }
            when SERVICE_SMS {
                if(response == null || response.getStatusCode() != 202)
                {
                    throw new GenesysCloud.SMSServiceException(response);
                }
            }
            when SERVICE_DISCONNECTION {
                if(response == null || response.getStatusCode() != 202)
                {
                    throw new GenesysCloud.DisconnectionServiceException(response);
                }
            }
        }
    }

    /**
     * Comprueba si la respuesta ha sido un 200 o 202, sino lanza Exception
     * @param response HttpResponse del SDK
     */
    private static HttpResponse validateResponse(HttpResponse responseToValidate)
    {

        // System.debug(responseToValidate);
        if(responseToValidate.getStatusCode() > 202)
        {
            throw new GenesysCloud.GenesysCloudException(responseToValidate);
        }

        return responseToValidate;
    }

    //#region Módulo RoutingService

    /**
     * RoutingService ofrece la capa de enrutamiento de Genesys Cloud, ofreciendo métodos de enrutamiento a través de una configuración de enrutamiento especificada antes de enrutar
     */
    public class RoutingService
    {
        public HttpCalloutMock mock = null;

        /**
         * Método público que realiza una solicitud al SDK para enruta una instancia de RoutingWork de forma síncrona.
         * @param work Elemento de trabajo a  enrutar como un email o una tarea de BackOffice
         * @return Devuelve el elemento enrutado con el identificador de interacción de Genesys Cloud.
         */
        public RoutingWork route(RoutingWork work)
        {
            HttpResponse response = null;

            //Setear el mock para que funcionen los tests
            if (Test.isRunningTest() && mock != null)
            {
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint('/api/v2/conversations/' + work.getEndpoint() );
                req.setBody(work.toJSON() );
                response = mock.respond(req);
            }
            else //POST
            {
                response = purecloud.sdk.Rest.post('/api/v2/conversations/' + work.getEndpoint(), work.toJSON() );
            }

            validateResponse(response, GenesysCloudServices.SERVICE_ROUTING);
            work.interactionId = getIdFromResponse(response);
            return work;
        }

        /**
         * Método público que realiza una solicitud al SDK para enrutar un listado de RoutingWork de forma asíncrona
         *
         * @author jmartinezpisson
         * @param {RoutingWork[]} works Trabajos a enrutar en Genesys como enails o tareas de BackOffice
         * @param callback Callback a ejecutar finalizados los callous
         */
        public void route(RoutingWork[] works, IAPICallback callback)
        {
            asynchronousCallout('route', works, callback);
        }

        /**
         * Devuelve el interacitionID si lo encuentra
         * @param response httpResponse del SDK
         * @return el Id o vacío
         */
        public String getIdFromResponse(HttpResponse response)
        {
            String result = '';
            //Devolver el ID solamente si el body lo contiene
            String responseBody = response.getBody();
            if(responseBody != null && responseBody.contains('\"id\"') )
            {
                Map<String, Object> deserializedBody = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if(deserializedBody.containsKey('id') )
                {
                    result = (String) deserializedBody.get('id');
                }
            }

            //Si no se encuentra el id no se puede devolver
            return result;
        }
    }

    /**
     * Clase virtual que representa un trabajo a enrutar.
     * Implemente la interfaz GenesysCloud.IAPIRequest.
     */
    public abstract class RoutingWork implements IAPIRequest
    {
        //Id. de la interacción enrutada en Genesys
        public transient String interactionId;
        //VIRTUAL - Sólo lectura. Devolverá una constante con el endpoint de enrutamiento a enrutar
        protected transient String endpoint
        {
            get
            {
                return this.getEndpoint();
            }
        }
        //VIRTUAL - Sólo lectura. Devolverá una constante con el tipo de elemento a enrutar.
        protected String provider
        {
            get
            {
                return this.getProvider();
            }
        }
        //Cola sore la que se enrutará el trabajo. Cuando se setea debe poner a null flowId
        public String queueId
        {
            get;
            set
            {
                if(String.isNotEmpty(value) )
                {
                    flowId = null;
                }
                queueId = value;
            }
        }
        //Flow sobre el que se enrutará el trabajo. Cuando se setea, debe poner a null queueId
        public String flowId
        {
            get;
            set
            {
                if(String.isNotEmpty(value) )
                {
                    this.queueId = null;
                }
                flowId = value;
            }
        }
        //Listado de skills para utilizar en el enrutamiento
        public String[] skillIds;
        //The priority to assign to the conversation for routing
        public Integer priority;
        //Atributos personalizados para enrutar
        public Map<String,String> attributes = new Map<String, String> ();
        //Sólo lectura. Devolverá siempre el valor INBOUND
        @TestVisible
        private String direction
        {
            get
            {
                return 'INBOUND';
            }
        }

        // Método público que devuelve una serialización a JSON de la propia instancia de la clase para su uso en las llamadas al SDK.
        public String toJSON()
        {
            return JSON.serialize(this);
        }

        public Integer hashCode()
        {
            return toJSON().hashCode();
        }

        //VIRTUAL - Sólo lectura. Devolverá una constante con el tipo de elemento a enrutar.
        private virtual String getProvider()
        {
            return null;
        }
        //VIRTUAL - Sólo lectura. Devolverá una constante con el endpoint de enrutamiento a enrutar
        private virtual String getEndpoint()
        {
            return '/emails';
        }
    }

    /**
     * Clase pública que extiende RoutingWork para representar un email a enrutar.
     */
    public class Email extends RoutingWork
    {
        //Propiedad que al setearse incluye en el mapa attributes el valor SF_URLPop con el valor asignado
        public transient String screenPopRecordId
        {
            get;
            set
            {
                this.attributes.put('SF_URLPop', value);
            }
        }
        //Asunto del email
        public String subject;
        //Nombre del destino
        public String toName;
        //Dirección de correo electrónico del destino
        public String toAddress;
        //Nombre del remitente
        public String fromName;
        //Dirección de correo electrónico del remitente
        public String fromAddress;
        //Sólo lectura. Devolverá una constante con el valor 'Salesforce Email'
        private override String getProvider()
        {
            return 'Salesforce Email';
        }

        private override String getEndpoint()
        {
            return 'emails';
        }
    }

    /**
     * Clase Exception específica para los errores del RoutingService que vengan de la respuesta del SDK
     */
    public class RoutingServiceException extends Exception
    {
        public Integer statusCode;
        public RoutingServiceException(HttpResponse response)
        {
            String message = ERROR_IN_RESPONSE;
            if(response != null)
            {
                message = ERROR_RESPONSE_SDK + response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody();
                this.statusCode = response.getStatusCode();
            }
            this.setMessage(message);
        }
    }

    //#endregion

    //#region Módulo CallbacksService

    /**
     * CallbacksService ofrece los métodos de creación y cancelación de callbacks/llamadas programadas dentro de los flujos de
     *  Genesys Cloud a través de una configuración de enrutamiento especificada antes de enrutar.
     */
    public class CallbacksService
    {
        public HttpCalloutMock mock = null;

        /**
         * Método que crea un callback en Genesys Cloud.
         * Rellena el genesysId con lo que haya en conversation.id si la respuesta ha sido 200.
         *  Para ello usará las funciones validateResponse y getIdFromResponse
         * @param callback callback a crear
         * @return Devuelve el callback creado con el identificador de interacción de Genesys Cloud.
         */
        public Callback create(Callback callback)
        {
            HttpResponse response = null;

            //Setear el mock para que funcionen los tests
            if (Test.isRunningTest() && mock != null)
            {
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint('/api/v2/conversations/callbacks');
                req.setBody(callback.toJSON() );
                response = mock.respond(req);
            }
            else //POST
            {
                response = purecloud.sdk.Rest.post('/api/v2/conversations/callbacks', callback.toJSON() );
            }

            validateResponse(response, GenesysCloudServices.SERVICE_CALLBACKS);
            callback.genesysId = getIdFromResponse(response);
            return callback;
        }

        /**
         * Método público que realiza una solicitud al SDK para crear un listado de Callbacks de forma asíncrona
         *
         * @author jmartinezpisson
         * @param {Callback[]} callbacks tareas a crear en Genesys
         * @param callback Apex Callback a ejecutar finalizados los callouts
         */
        public void create(Callback[] callbacks, IAPICallback apexCallback)
        {
            asynchronousCallout('create', callbacks, apexCallback);
        }

        /**
         * Metodo publico que realiza una solicitud de tipo PATCH a genesys para cancelar un callback de forma 
         * asincrona
         * 
         * @author nts (agonzalezisasi)
         * @param {CallbackCancel} callback objeto con el id de gensys del callback a cancelar
         * @return Devuelve el calback creado con el identificador de interaccion de Genesys Cloud
         */
        public CallbackCancel cancel(CallbackCancel callback)
        {
            HttpResponse response = new GenesysCloud.GenesysCloudNamedUserAPI().patch(
                '/api/v2/conversations/callbacks/' + callback.genesysId, callback.toJSON()
            );
            return callback;
        }

        /**
         * Método público que realiza una solicitud de tipo PATCH a genesys para crear un 
         * listado de Callbacks de forma asíncrona
         *
         * @author nts (agonzalezisasi)
         * @param {CallbackCancel[]} callbacks tareas a crear en Genesys
         * @param callback Apex Callback a ejecutar finalizados los callouts
         */
        public void cancel(CallbackCancel[] callbacks, IAPICallback apexCallback)
        {
            asynchronousCallout(ASYNC_METHOD_CALLBACK_CANCEL, callbacks, apexCallback);
        }

        /**
         * Devuelve el interacitionID si lo encuentra
         * @param response httpResponse del SDK
         * @return el Id o vacío
         */
        public String getIdFromResponse(HttpResponse response)
        {
            String result = '';
            //Devolver el ID solamente si el body lo contiene
            String responseBody = response.getBody();
            if(responseBody != null && String.isNotBlank(responseBody) )
            {
                Map<String, Object> deserializedBody = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                Map<String, Object> deserializedConversation = (Map<String, Object>) deserializedBody.get('conversation');
                result = (String) deserializedConversation.get('id');
            }

            //Si no se encuentra el id no se puede devolver
            return result;
        }
    }

    /**
     * Clase que representa una cancelacion de callback de Genesys Cloud
     * Implemente la interfaz GenesysCloud.IAPIRequest.
     */
    public class CallbackCancel implements IAPIRequest
    {
        //Identificador del callback en Genesys Cloud
        public String genesysId;
        public string state = 'disconnected';

        // Método público que devuelve una serialización a JSON de la propia instancia de la clase para su uso en las llamadas al SDK.
        public String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Clase que representa un Callback de Genesys Cloud.
     * Implemente la interfaz GenesysCloud.IAPIRequest.
     */
    public class Callback implements IAPIRequest
    {
        //Identificador del callback en Genesys Cloud
        public transient String genesysId;
        //Identificador del script a utilizar en el callback
        public String scriptId;
        //Cola en la que enrutar el callback. Solo se puede especificar routingData o queueId.
        public String queueId
        {
            get;
            set
            {
                if(String.isNotEmpty(value) )
                {
                    routingData = null;
                }
                queueId = value;
            }
        }
        //Información de enrutamiento adicional. Solo se puede especificar routingData o queueId. queueId es REQUERIDO dentro de routingData.
        public CallbackRoutingData routingData
        {
            get;
            set
            {
                if(value != null)
                {
                    queueId = null;
                }
                routingData = value;
            }
        }
        //Nombre de la persona sobre la que se está programando la llamada
        public String callbackUserName;
        //REQUERIDO Listado de números a llamar
        public String[] callbackNumbers;
        //Fecha/hora de la programación. ISO-8601 string (yyyy-MM-ddTHH:mm:ss.SSSZ) Ej: 2016-09-26T15:30:00.000Z
        public Datetime callbackScheduledTime;
        //Validar los números pasados
        public Boolean validateCallbackNumbers;
        //Código del país. Utilizado en el formateo
        public String countryCode;
        //Propiedad que al setearse incluye en el mapa data el valor SF_URLPop con el valor asignado
        public transient String screenPopRecordId
        {
            get;
            set
            {
                this.data.put('SF_URLPop', value);
            }
        }
        //Información adicional a incluir en el callback
        public Map<String,String> data = new Map<String, String> ();

        // Método público que devuelve una serialización a JSON de la propia instancia de la clase para su uso en las llamadas al SDK.
        public String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Clase que representa la configuración de enrutamiento de un callback de Genesys Cloud
     */
    public class CallbackRoutingData
    {
        //Cola en la que enrutar el callback REQUERIDO
        public String queueId;
        //Idioma
        public String languageId;
        //Prioridad 0-99 a aplicar al callback
        public Integer priority;
        //skills necesarios para el enrutamiento
        public String[] skillIds;
        //IDs de agentes preferidos
        public String[] preferredAgentIds;
    }

    /**
     * Clase Exception específica para los errores del RoutingService que vengan de la respuesta del SDK
     */
    public class CallbacksServiceException extends Exception
    {
        public Integer statusCode;
        public CallbacksServiceException(HttpResponse response)
        {
            String message = ERROR_IN_RESPONSE;
            if(response != null)
            {
                message = ERROR_RESPONSE_SDK + response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody();
                this.statusCode = response.getStatusCode();
            }
            this.setMessage(message);
        }
    }

    //#endregion

    //#region Módulo DisconnectService

    /**
     * DisconnectService ofrece el método de cierre de interacciones programadas dentro de los flujos de
     *  Genesys Cloud a través de una configuración de enrutamiento especificada antes de enrutar.
     */
    public class DisconnectionService
    {
        public HttpCalloutMock mock = null;

        /**
         * Metodo publico que realiza una solicitud de tipo PATCH a genesys para cancelar una interaccion de forma 
         * asincrona
         * 
         * @author nts (arcortazar)
         * @date 16/02/2022
         * @param {InteractionCancel} objeto con el id de Genesys de la interacción a cancelar
         * @return Devuelve la interaccion
         */
        public String close(InteractionCancel interaction)
        {
            String retorno = '';

            HttpResponse response = null;
            //Setear el mock para que funcionen los tests
            if (Test.isRunningTest() && mock != null)
            {

                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint('/api/v2/conversations/'+interaction.conversationId +'/disconnect');
                req.setBody(interaction.toJSON() );
                response = mock.respond(req);
                retorno = interaction.conversationId;
            }
            else //POST
            {
                response = purecloud.sdk.Rest.post('/api/v2/conversations/'+interaction.conversationId +'/disconnect', interaction.toJSON());
                retorno = getFieldFromResponse(response, 'conversationId');
            }

            return retorno;
        }

        /**
         * Método público que realiza una solicitud de tipo PATCH a genesys para crear un 
         * listado de Callbacks de forma asíncrona
         *
         * @author nts (arcotazar)
         * @date 16/02/2022
         * @param {InteractionCancel[]} interacciones a desconectar en Genesys
         * @param callback Apex Callback a ejecutar finalizadas las desconexiones
         */
        public void close(InteractionCancel[] interactions, IAPICallback apexCallback)
        {
            asynchronousCallout(ASYNC_METHOD_DISCONNECTION, interactions, apexCallback);
        }

        /**
         * Devuelve el interacitionID si lo encuentra
         * @param response httpResponse del SDK
         * @return el Id o vacío
         */
        public String getFieldFromResponse(HttpResponse response, string field)
        {
            String result = '';
            //Devolver el ID solamente si el body lo contiene
            String responseBody = response.getBody();
            if(responseBody != null && responseBody.contains('\"' + field + '\"') )
            {
                Map<String, Object> deserializedBody = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if(deserializedBody.containsKey(field) )
                {
                    result = (String) deserializedBody.get(field);
                }
            }

            //Si no se encuentra el id no se puede devolver
            return result;
        }
    }

    /**
     * StatusService ofrece el método de consulta de estado para integrar con cierre de interacciones 
     *  programadas dentro de los flujos de
     *  Genesys Cloud a través de una configuración de enrutamiento especificada antes de enrutar.
     */ 
    public class StatusService 
    {
        public HttpCalloutMock mock = null;

        /**
         * Metodo publico que realiza una solicitud de tipo GET a Genesys para 
         * recuperar el estado de las interacciones
         * 
         * @author nts (jgarciamartinez)
         * @date 22/02/2022
         * @param {InteractionStatus} objeto con el id de Genesys de la interacción a comprobar
         * @return Devuelve la interaccion
         */

         public HttpResponse status(InteractionStatus interaction)
         {
            //  String retorno = '';

             HttpResponse response = null;

             if(Test.isRunningTest() && mock != null)
             {
                 HttpRequest req = new HttpRequest();
                 req.setMethod('GET');
                 req.setEndpoint('/api/v2/conversations/emails/' + interaction.conversationId);
                 req.setBody(interaction.toJSON());
                 response = mock.respond(req);
             }
             else 
             {
                response = purecloud.SDK.Rest.get('/api/v2/conversations/emails/' + interaction.conversationId);
             }
            
             return response;
             
         }

         public void status(InteractionStatus[] interactions, IAPICallback apexCallback)
         {
             asynchronousCallout(ASYNC_METHOD_DISCONNECTION, interactions, apexCallback);
         }

    }

    /**
     * PatchService ofrece el método de desconexión de estado para poder cerrar correctamente
     * las interacciones. Para ello, necesitamos el conversationId así como el participantId
     * (ya sea acd o agent)
     * 
     *  Metodo publico que realiza una solicitud de tipo PATCH a Genesys para 
     * desconectar la interacción en caso de Agent.
     * 
     * @author nts (jgarciamartinez)
     * @date 06/03/2022
     * @param {InteractionStatus} string concatenado con conversationId, participantId y un estado
     *          inventado 'working' para el Agent.
     * @return Devuelve el resultado de la interacción como ok o nok
     */ 
    public class PatchService
    {
        public HttpCalloutMock mock = null;

        public String patchForService(InteractionStatus interaction)
        {
            String retorno = '';

            AdminSetupParameter__mdt codigoWrapup = [SELECT KeyName__c, Value__c FROM AdminSetupParameter__mdt WHERE KeyName__c = 'WrapupValid' LIMIT 1];

            HttpResponse response = null;

            if(Test.isRunningTest() && mock != null)
            {
                HttpRequest req = new HttpRequest();
                req.setMethod('PATCH');
                req.setEndpoint('/api/v2/conversations/emails/' + interaction.conversationId + '/participants/' + interaction.participants);
                req.setBody(interaction.toJSON());
                response = mock.respond(req);
                retorno = interaction.conversationId;
            }
            else 
            {
                Map<String, Object> bodyPatch = new Map<String, Object>();
                bodyPatch.put('state', 'disconnected');

                if(interaction.purposeStatus.equalsIgnoreCase('acd'))
                {
                    Map<String, Object> bodyPatchWrapup = new Map<String,Object>();
                    bodyPatchWrapup.put('code', codigoWrapup.Value__c);
                    bodyPatchWrapup.put('name', 'válida');
                    bodyPatch.put('wrapup', bodyPatchWrapup);
                }
                response = purecloud.sdk.rest.patch('/api/v2/conversations/emails/' 
                                                    + interaction.conversationId + '/participants/' 
                                                    + interaction.participants, 
                                                    JSON.serialize(bodyPatch));
                //retorno = getFieldFromPatch(response, 'conversationId');
            }
            return response.getBody();
        }

        public void agentPatch(InteractionStatus[] interactions, IAPICallback apexCallback)
         {
             asynchronousCallout(ASYNC_METHOD_DISCONNECTION, interactions, apexCallback);
         }

         public String getFieldFromPatch(HttpResponse response, string field)
         {
             String result = '';
             String responseBody = response.getBody();
             if(responseBody != null && responseBody.contains('\"' + field + '\"'))
             {
                 Map<String, Object> deserializedBody = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                 if(deserializedBody.containsKey(field))
                 {
                     result = (String) deserializedBody.get(field);
                 }
             }
             return result;
         }
    }
    

    /**
     * Clase que representa una interaccion de Genesys Cloud
     * Implemente la interfaz GenesysCloud.IAPIRequest.
     */
    public class InteractionCancel implements IAPIRequest
    {
        //Identificador de la interacción en Genesys Cloud
        public String conversationId;

        // Método público que devuelve una serialización a JSON de la propia instancia de la clase para su uso en las llamadas al SDK.
        public String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    
    public class InteractionStatus implements IAPIRequest
    {
        public String conversationId;
        public String participants;

        //jgarciamartinez - 16/03/2022 - se añade este campo para poder leer el purpose
        public String purposeStatus;

        public String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Clase Exception específica para los errores del DisconnectionService que vengan de la respuesta del SDK
     */
    public class DisconnectionServiceException extends Exception
    {
        public Integer statusCode;
        public DisconnectionServiceException(HttpResponse response)
        {
            String message = ERROR_IN_RESPONSE;
            if(response != null)
            {
                message = ERROR_RESPONSE_SDK + response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody();
                this.statusCode = response.getStatusCode();
            }
            this.setMessage(message);
        }
    }

    //#endregion

    //#region Módulo SMSService

    /**
     * SMSService ofrece la capa de envio de mensajes SMS de Genesys Cloud.
     */
    public class SMSService
    {
        public HttpCalloutMock mock = null;

        /**
         * Método público que realiza una solicitud al SDK para enviar un mensaje sms forma síncrona.
         *
         * @param {SMSData} message Mensaje a enviar a traves de Genesys
         * @return Devuelve el mensaje enviado con el identificador de objeto de Genesys Cloud.
         */
        public SmsData send(SmsData message)
        {
            HttpResponse response = null;

            //Setear el mock para que funcionen los tests
            if (Test.isRunningTest() && mock != null)
            {
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint('/api/v2/conversations/messages/agentless' );
                req.setBody(message.toJSON() );
                response = mock.respond(req);
            }
            else //POST
            {
                response = purecloud.sdk.Rest.post('/api/v2/conversations/messages/agentless', message.toJSON() );
            }

            validateResponse(response, GenesysCloudServices.SERVICE_SMS);
            // Campos interesantes de la respuesta al envio del SMS
            //System.debug(response.getBody());
            message.smsId = getFieldFromResponse(response, 'id');
            message.conversationId = getFieldFromResponse(response, 'conversationId');
            return message;
        }

        /**
         * Método público que realiza una solicitud al SDK para enviar mensajes sms de forma asíncrona
         *
         * @author jmartinezpisson
         * @param {SmsData[]} dataList Mensajes sms a enviar desde Genesys
         * @param callback Callback a ejecutar finalizados los callouts
         */
        public void send(SmsData[] messages, IAPICallback callback)
        {
            asynchronousCallout(ASYNC_METHOD_SMS, messages, callback);
        }

        /**
         * Devuelve el interacitionID si lo encuentra
         * @param response httpResponse del SDK
         * @return el Id o vacío
         */
        public String getFieldFromResponse(HttpResponse response, string field)
        {
            String result = '';
            //Devolver el ID solamente si el body lo contiene
            String responseBody = response.getBody();
            if(responseBody != null && responseBody.contains('\"' + field + '\"') )
            {
                Map<String, Object> deserializedBody = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if(deserializedBody.containsKey(field) )
                {
                    result = (String) deserializedBody.get(field);
                }
            }

            //Si no se encuentra el id no se puede devolver
            return result;
        }
    }

    /**
     * Clase pública que representa un mensaje SMS a enviar.
     *
     * @author nts (agonzalezisasi)
     * @date 22/02/2021
     */
    public class SmsData implements IAPIRequest
    {
        // Identificador del mensaje en genesys
        public transient String smsId;
        // Identificador de la conversacion en genesys
        public transient String conversationId;
        // El dia y hora en el que el mensaje fue enviado. Representado en formato ISO-8601: yyyy-MM-ddTHH:mm:ss[.mmm]Z
        public transient String timestamp;

        // Numero de telefono movil al que se le envia la notificacion. E.164 format: +13175555555 o +34234234234.
        public String toAddress;
        // Numero de telefono movil desde el que se envia la notificacion (Zurich)
        public String fromAddress;
        // Tipo de mensaje. Actualmente (22/02/2021) SMS es el unico tipo soportado.
        // Valores validos: sms, facebook, twitter, line, whatsapp, webmessaging.
        public String toAddressMessengerType = 'sms';
        // El texto a enviar en el mensaje
        public String textBody;

        public String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Clase Exception específica para los errores del SMSService que vengan de la respuesta del SDK
     */
    public class SMSServiceException extends Exception
    {
        public Integer statusCode;
        public SMSServiceException(HttpResponse response)
        {
            String message = ERROR_IN_RESPONSE;
            if(response != null)
            {
                message = ERROR_RESPONSE_SDK + response.getStatusCode() + ' ' + response.getStatus() + ' ' + response.getBody();
                this.statusCode = response.getStatusCode();
            }
            this.setMessage(message);
        }
    }

    //#endregion

    //#region Módulo CallsService

    /**
     * Clase de servicio de llamadas de Genesys Cloud
     */
    public class CallsService
    {
        /**
         * @description getActive description
         * @return   return description
         */
        public Call[] getActive()
        {
            HttpResponse response = new GenesysCloudNamedUserAPI().get('/api/v2/conversations/calls');
            ActiveCalls activeCalls = (ActiveCalls) JSON.deserialize(response.getBody(), ActiveCalls.class);

            return activeCalls.entities;
        }

        /**
         * @description get description
         * @param  interactionId interactionId description
         * @return               return description
         */
        public Call get(String interactionId)
        {
            HttpResponse response = new GenesysCloudNamedUserAPI().get('/api/v2/conversations/calls/' + interactionId);

            return (Call) JSON.deserialize(response.getBody(), Call.class);
        }

        /**
         * @description consult description
         * @param  consult consult description
         */
        public void consult(ConsultTransfer consult)
        {
            HttpResponse response = new GenesysCloudNamedUserAPI().post('/api/v2/conversations/calls/' + consult.conversationId + '/participants/' + consult.participantId + '/consult', consult.toJSON() );
        }

        /**
         * @description setParticipantData description
         * @param  conversationId conversationId description
         * @param  participantId  participantId description
         * @param  attributes     attributes description
         */
        public void setParticipantData(String conversationId, String participantId, Map<String, String> attributes)
        {
            HttpResponse response = new GenesysCloudNamedUserAPI().patch('/api/v2/conversations/calls/' + conversationId + '/participants/' + participantId + '/attributes', JSON.serialize(new Map<String, Map<String, String> >
            {
                'attributes' => attributes
            }) );
        }

        /**
         * @description setUUIData description
         * @param  conversationId conversationId description
         * @param  participantId  participantId description
         * @param  uuiData        uuiData description
         */
        public void setUUIData(String conversationId, String participantId, String communicationId, String uuiData)
        {
            HttpResponse response = new GenesysCloudNamedUserAPI().put('/api/v2/conversations/calls/' + conversationId + '/participants/' + participantId + '/communications/' + communicationId + '/uuidata', JSON.serialize(new Map<String, String>
            {
                'uuiData' => uuiData
            }) );
        }

        /**
         * Conferencia la llamada activa del usuario actual al número identificado
         *
         * @author jmartinezpisson
         * @date 31/03/2021
         * @param {String} addressTo Número al que conferenciar
         * @param {Map<String, String>} attributeValuesByKey Mapa de clave-valor a transferir como información del partipante
         * @param {Boolean} fallbackToUUI Habilita el paso de los atributos como los valores separados por un pipe (|) utilizando el UUI
         */
        public void conferenceTo(String addressTo, Map<String, String> attributesByName, Boolean fallbackToUUI)
        {
            // 1 - Se obtiene la llamada activa y se elige el participante destino de la conferencia
            GenesysCloud.Call[] activeCalls = this.getActive();
            String currentConversationId = activeCalls[0].id;
            GenesysCloud.Participant targetParticipant = activeCalls[0].participants[1];

            // 2 - Preparamos la información a transferir. Utilizamos el participantData y el UUI para tener un fallback de los datos a enviar.
            if(attributesByName != null && !attributesByName.isEmpty())
            {
                this.setParticipantData(currentConversationId, targetParticipant.id, attributesByName);

                if(fallbackToUUI) {
                    this.setUUIData(currentConversationId, targetParticipant.id, targetParticipant.peer, String.join(attributesByName.values(), '|'));
                }
            }

            // 3 - Generamos la llamada de consulta
            GenesysCloud.ConsultTransfer consultTransfer = new GenesysCloud.ConsultTransfer();

            consultTransfer.conversationId = currentConversationId;
            consultTransfer.participantId = targetParticipant.id;
            consultTransfer.speakTo = 'BOTH';
            consultTransfer.destination = new GenesysCloud.ConsultTransferDestination();
            consultTransfer.destination.address = addressTo;

            this.consult(consultTransfer);
        }
    }


    /**
     * Representa la respuesta del servicio Web de llamadas activas
     * https://developer.mypurecloud.com/api/rest/v2/conversations/#get-api-v2-conversations-calls
     *
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    public class ActiveCalls
    {
        @auraEnabled
        public Call[] entities;
    }

    /**
     * Representa la estructura de llamada de Genesys Cloud
     * https://developer.mypurecloud.com/api/rest/v2/conversations/#get-api-v2-conversations-calls--conversationId
     *
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    public class Call implements IAPIRequest
    {
        @auraEnabled
        public String id;

        @auraEnabled
        public Participant[] participants;


        public String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa la estructura de un participante en una llamada en Genesys Cloud
     * https://developer.mypurecloud.com/api/rest/v2/conversations/#get-api-v2-conversations-calls--conversationId
     *
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    public class Participant
    {
        public transient String conversationId;
        
        @auraEnabled
        public String id;
        
        @auraEnabled
        public String address;

        @auraEnabled
        public UserParticipant user;

        @auraEnabled
        public String peer;

        @auraEnabled
        public Map<String, String> attributes;

        //añadimos más campos a participant
        @AuraEnabled
        public String purpose;

        @AuraEnabled
        public String state;

        public String toJSON()
        {
            return JSON.serialize(this, true);
        }
    }

    /**
     * Representa la estructura de un participante de tipo usuario en una llamada en Genesys Cloud
     * https://developer.mypurecloud.com/api/rest/v2/conversations/#get-api-v2-conversations-calls--conversationId
     *
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    public class UserParticipant
    {
        @auraEnabled
        public String id;

        @auraEnabled
        public String selfUri;

    }

    /**
     * Representa una petición al servicio de consulta sobre llamada de Genesys Cloud
     * https://developer.mypurecloud.com/api/rest/v2/conversations/#post-api-v2-conversations-calls--conversationId--participants--participantId--consult
     *
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    public class ConsultTransfer implements IAPIRequest
    {
        public transient String conversationId;
        public transient String participantId;
        public String speakTo;
        public ConsultTransferDestination destination;

        public String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa el destino de la petición al servicio de consulta sobre llamada de Genesys Cloud
     * https://developer.mypurecloud.com/api/rest/v2/conversations/#post-api-v2-conversations-calls--conversationId--participants--participantId--consult
     *
     * @author jmartinezpisson
     * @date 31/03/2021
     */
    public class ConsultTransferDestination
    {
        public String address;
        public String name;
        public String userId;
        public String queueId;

        public String toJSON()
        {
            return JSON.serialize(this, true);
        }
    }

    //#endregion

    private class GenesysCloudNamedUserAPI
    {
        HttpRequest request;

        private void prepare(String path,  String body, Map<String, String> headers)
        {
            request = new HttpRequest();

            request.setEndpoint('callout:GenesysCloud' + path);

            if(headers != null)
            {
                for(String key : headers.keySet() )
                {
                    request.setHeader(key, headers.get(key) );
                }
            }

            if(String.isNotBlank(body) )
            {
                request.setBody(body);
            }
        }

        private HttpResponse send()
        {
            return validateResponse(new Http().send(this.request) );
        }

        public HttpResponse get(String url)
        {
            return get(url, new Map<String, String>
            {
                'Content-Type' => 'application/json'
            });
        }

        public HttpResponse get(String url, Map<String, String> headers)
        {
            prepare(url, null, headers);
            request.setMethod('GET');

            return send();
        }

        public HttpResponse post(String url, String body)
        {
            return post(url, body, new Map<String, String>
            {
                'Content-Type' => 'application/json'
            });
        }

        public HttpResponse post(String url, String body, Map<String, String> headers)
        {
            prepare(url, body, headers);
            request.setMethod('POST');

            return send();
        }

        public HttpResponse patch(String url, String body)
        {
            return patch(url, body, new Map<String, String>
            {
                'Content-Type' => 'application/json'
            });
        }

        public HttpResponse patch(String url, String body, Map<String, String> headers)
        {
            prepare(url, body, headers);
            request.setMethod('PATCH');

            return send();
        }

        public HttpResponse put(String url, String body)
        {
            return put(url, body, new Map<String, String>
            {
                'Content-Type' => 'application/json'
            });
        }

        public HttpResponse put(String url, String body, Map<String, String> headers)
        {
            prepare(url, body, headers);
            request.setMethod('PUT');

            return send();
        }
    }
}