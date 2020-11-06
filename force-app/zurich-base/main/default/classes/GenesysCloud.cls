public class GenesysCloud
{
    @TestVisible
    private class RoutingServiceException extends Exception {}

    @TestVisible
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

    @TestVisible
    private class RoutingService
    {
        @TestVisible
        private final String STATUS_CODE_NO_200 = 'response code is not 200';

        public void route(purecloud.Email routingEmail){}

        public void remove(purecloud.Email routingEmail){}

        public void transfer(purecloud.Email routingEmail){}

        public RoutingWork route (RoutingWork work){
            //Setear el mock para que funcionen los tests
            if (Test.isRunningTest()){
                Test.setMock(HttpCalloutMock.class, new GenesysCloudMocks());
            }

            //POST
            HttpResponse response = purecloud.sdk.Rest.post('/api/v2/conversations/' + work.endpoint, work.toJSON()); //TODO pasar endpoint a label/constante
            work.interactionId = getIdFromResponse(response);
            return work;
        }

        public RoutingWork[] route(RoutingWork[] works){ return works; }

        public String getIdFromResponse(HttpResponse response){
            //Si la respuesta no es un 200 -> Error
            if(response.getStatusCode() != 200){
                throw new GenesysCloud.RoutingServiceException(STATUS_CODE_NO_200);
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

    @TestVisible
    private virtual class RoutingWork
    {
        @TestVisible
        protected String interactionId {get;set;}           //Id. de la interacción enrutada en Genesys
        @TestVisible
        private String provider{get;}                       //VIRTUAL - Sólo lectura. Devolverá una constante con el tipo de elemento a enrutar
        @TestVisible
        protected String queueId{get;set{                   //Cola sore la que se enrutará el trabajo. Cuando se setea debe poner a null flowId
                if(String.isNotEmpty(value))
                {
                    flowId = null;
                }
                queueId = value;
            }
        }
        @TestVisible
        protected String flowId{get;set{                    //Flow sobre el que se enrutará el trabajo. Cuando se setea, debe poner a null queueId
                if(String.isNotEmpty(value))
                {
                    queueId = null;
                }
                flowId = value;
            }
        }
        @TestVisible
        protected transient String endpoint {get;}          //VIRTUAL - Sólo lectura. Devolverá una constante con el endpoint de enrutamiento a enrutar
        @TestVisible
        protected String[] skillIds {get;set;}              //Listado de skills para utilizar en el enrutamiento
        @TestVisible
        protected Integer priority {get;set;}               //The priority to assign to the conversation for routing
        @TestVisible
        protected Map<String,String> attributes {get;set;}  //Atributos personalizados para enrutar
        @TestVisible
        private String direction {get{                      //Sólo lectura. Devolverá siempre el valor INBOUND
                return 'INBOUND';
            }
        }

        @TestVisible
        protected String toJSON()
        {
            return JSON.serialize(this);
        }
    }

    public class Email extends RoutingWork
    {
        @TestVisible
        private String provider{get{                            //Sólo lectura. Devolverá una constante con el valor 'Salesforce Email'
             return 'Salesforce Email';
            }
        }
        @TestVisible
        private transient String endpoint{get{                  //Sólo lectura. Devolverá una constante con el valor 'emails'
                return 'emails';
            }
        }
        public transient String screenPopRecordId{get;set{      //Propiedad que al setearse incluye en el mapa attributes el valor SF_URLPop con el valor asignado
                attributes.put('SF_URLPop',value);
            }
        }
        public String subject{get;set;}                         //Asunto del email
        public String toName{get;set;}                          //Nombre del destino
        public String toAddress{get;set;}                       //Dirección de correo electrónico del destino
        public String fromName{get;set;}                        //Nombre del remitente
        public String fromAddress{get;set;}                     //Dirección de correo electrónico del remitente
    }

    public class Task extends RoutingWork
    {
        @TestVisible
        private String provider{get{                            //Sólo lectura. Devolverá una constante con el valor 'Salesforce Task'
             return 'Salesforce Task';
            }
        }
        public transient String screenPopRecordId{get;set{      //Propiedad que al setearse incluye en el mapa attributes el valor SF_URLPop con el valor asignado
                attributes.put('SF_URLPop',value);
            }
        }
    }

}
