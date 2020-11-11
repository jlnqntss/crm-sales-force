public class GenesysCloud
{
    /**
     * Representa un elemento utilizado en un recurso REST de Genesys como una solicitud de enrutamiento
     */
    public interface IAPIRequest
    {
        //Método que devuelve una serialización a JSON de la propia instancia de la clase para su uso en las llamadas al SDK.
        String toJSON();
    }

    @TestVisible
    private class RoutingServiceException extends Exception {}

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
     * RoutingService ofrece la capa de enrutamiento de Genesys Cloud, ofreciendo métodos de enrutamiento a través de una configuración de enrutamiento especificada antes de enrutar
     */
    @TestVisible
    public class RoutingService
    {
        @TestVisible
        private final String STATUS_CODE_NO_200 = 'response code is not 200: ';
        @TestVisible
        private final String ERROR_IN_RESPONSE = 'response is null';
        public HttpCalloutMock mock = null;

        /**
         * Método público que realiza una solicitud al SDK para enruta una instancia de RoutingWork de forma síncrona.
         * @param work Elemento de trabajo a  enrutar como un email o una tarea de BackOffice
         * @return Devuelve el elemento enrutado con el identificador de interacción de Genesys Cloud.
         */
        public RoutingWork route(RoutingWork work){
            HttpResponse response = null;

            //Setear el mock para que funcionen los tests
            if (Test.isRunningTest() && mock != null){
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint('/api/v2/conversations/' + work.getEndpoint());
                req.setBody(work.toJSON());
                response = mock.respond(req);
            }
            else{//POST
                response = purecloud.sdk.Rest.post('/api/v2/conversations/' + work.getEndpoint(), work.toJSON());
            }

            work.interactionId = getIdFromResponse(response);
            return work;
        }

        public String getIdFromResponse(HttpResponse response){

            if(response == null){
                throw new GenesysCloud.RoutingServiceException(ERROR_IN_RESPONSE);
            }

            //Si la respuesta no es un 200 -> Error
            if(response.getStatusCode() != 200){
                throw new GenesysCloud.RoutingServiceException(STATUS_CODE_NO_200 + response.getStatusCode());
            }

            //Devolver el ID solamente si el body lo contiene
            String responseBody = response.getBody();
            if(responseBody != null && responseBody.contains('\"id\"')){
                Map<String, Object> deserializedBody = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                if(deserializedBody.containsKey('id')){
                    return (String)deserializedBody.get('id');
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
    public abstract class RoutingWork
    {
        //Id. de la interacción enrutada en Genesys
        @TestVisible
        protected String interactionId;
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
        @TestVisible
        public String queueId
        {
            get;
            set
            {
                if(String.isNotEmpty(value))
                {
                    flowId = null;
                }
                queueId = value;
            }
        }
        //Flow sobre el que se enrutará el trabajo. Cuando se setea, debe poner a null queueId
        @TestVisible
        public String flowId
        {
            get;
            set
            {
                if(String.isNotEmpty(value))
                {
                    this.queueId = null;
                }
                flowId = value;
            }
        }
        //Listado de skills para utilizar en el enrutamiento
        @TestVisible
        public String[] skillIds;
        //The priority to assign to the conversation for routing
        @TestVisible
        public Integer priority;
        //Atributos personalizados para enrutar
        protected Map<String,String> attributes = new Map<String, String> ();
        //Sólo lectura. Devolverá siempre el valor INBOUND
        public String direction
        {
            get
            {
                return 'INBOUND';
            }
        }

        // Método protegido que devuelve una serialización a JSON de la propia instancia de la clase para su uso en las llamadas al SDK.
        public String toJSON()
        {
            return JSON.serialize(this);
        }
        //VIRTUAL - Sólo lectura. Devolverá una constante con el tipo de elemento a enrutar.
        private virtual String getProvider() { return null; }
        //VIRTUAL - Sólo lectura. Devolverá una constante con el endpoint de enrutamiento a enrutar
        private virtual String getEndpoint() { return '/emails';}
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
}
