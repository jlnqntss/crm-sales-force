public class GenesysCloud
{
    @TestVisible
    private static final String ERROR_IN_RESPONSE = 'response is null';
    @TestVisible
    private static final String ERROR_RESPONSE_SDK = 'response from genesys cloud SDK: ';


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
     * Comprueba si la respuesta ha sido un 200, sino lanza Exception
     * @param response HttpResponse del SDK
     */
    private static void validateResponse(HttpResponse response)
    {
        if(response == null || response.getStatusCode() != 200)
        {
            throw new GenesysCloud.RoutingServiceException(response);
        }
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

            validateResponse(response);
            work.interactionId = getIdFromResponse(response);
            return work;
        }

        /**
         * Método público que realiza una solicitud al SDK para enrutar un listado de RoutingWork de forma asíncrona
         *
         * @author jmartinezpisson
         * @param {RoutingWork[]} works Trabajos a enrutar en Genesys como enails o tareas de BackOffice
         */
        public void route(RoutingWork[] works)
        {
            route(works, null);
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

            //Devolver el ID solamente si el body lo contiene
            String responseBody = response.getBody();
            if(responseBody != null && responseBody.contains('\"id\"') )
            {
                Map<String, Object> deserializedBody = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                if(deserializedBody.containsKey('id') )
                {
                    return (String) deserializedBody.get('id');
                }
            }

            //Si no se encuentra el id no se puede devolver
            return '';
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
            if(response == null)
            {
                this.setMessage(ERROR_IN_RESPONSE);
            }
            else
            {
                this.setMessage(ERROR_RESPONSE_SDK + response.getStatus() );
                this.statusCode = response.getStatusCode();
            }
        }
    }

    //#endregion
}