public class GenesysCloud
{
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

    public class RoutingWork
    {
        public String flowId { get; set; }
        public String queueId { get; set; }
        public String provider { get; set; }
        //TODO: Falta definir qué atributos tiene

        public RoutingWork(String flowId, String queueId, String provider){
            this.flowId = flowId;
            this.queueId = queueId;
            this.provider = provider;
        }
    }


    class RoutingService
    {
        /**
         * Forma un Payload con los datos rellenos del purecloud.Email
         * Y utiliza el POST del sdk de genesys.
         * Parámetros del purecloud.Email: https://help.mypurecloud.com/articles/use-the-sdk-to-route-salesforce-emails
         * Payload: https://developer.mypurecloud.com/api/rest/v2/conversations/#request-json-post-api-v2-conversations-emails
         * @author nescudero
         * @date 05/11/2020
         */
        public void route(purecloud.Email routingEmail)
        {
            Map<String, Object> payload = new Map<String, Object>();
            //payload.put('queueId', routingEmail.queue); //Solo se puede enviar o flowId o queueId a la vez
            payload.put('flowId', routingEmail.flow); //Solo se puede enviar o flowId o queueId a la vez
            payload.put('provider', 'Salesforce'); //Obligatorio
            if(routingEmail.skills != null && !routingEmail.skills.isEmpty()){
                payload.put('skillIds', new List<String>(routingEmail.skills));
            }
            payload.put('languageId', routingEmail.language);
            //payload.put('priority', 0); //TODO: ¿Esto de dónde se obtiene?
            if(routingEmail.attributes != null && routingEmail.attributes.containskey('SF_URLPop') && routingEmail.attributes.containskey('SF_SearchValue')){
                payload.put('attributes', new Map<String, String>{ 'SF_URLPop' => (String)routingEmail.attributes.get('SF_URLPop'), 'SF_SearchValue' => (String)routingEmail.attributes.get('SF_SearchValue')});
            }
            //payload.put('toAddress', routingEmail.); //TODO: ¿De dónde se obtiene esto?
            //payload.put('toName', routingEmail.);  //TODO: ¿De dónde se obtiene esto?
            payload.put('fromAddress', routingEmail.fromAddress);
            payload.put('fromName', routingEmail.fromName);
            payload.put('subject', routingEmail.subject);
            //payload.put('direction', routingEmail.);  //TODO: ¿De dónde se obtiene esto?
            //payload.put('htmlBody', routingEmail.);  //TODO: ¿De dónde se obtiene esto?
            //payload.put('textBody', routingEmail.);  //TODO: ¿De dónde se obtiene esto?
            if (Test.isRunningTest()) Test.setMock(HttpCalloutMock.class, new GenesysCloudMocks());
            else{
                HttpResponse response = purecloud.SDK.Rest.post('/platform/api/v2/conversations/emails', JSON.serialize(payload)); //TODO pasar endpoint a label/constante
            }
            //TODO: ¿Guardar algo de la response? https://developer.mypurecloud.com/api/rest/v2/conversations/#response-json-post-api-v2-conversations-emails-200
        }

        public void remove(purecloud.Email routingEmail)
        {
            //purecloud.Email: https://help.mypurecloud.com/articles/use-the-sdk-to-route-salesforce-emails
            //TODO: falta definir qué atributos se necesitan y no están en el purecloud.Email para incluirlos como custom attributes en el mapa del routingEmail.attributes
            //POST: https://developer.mypurecloud.com/api/rest/v2/conversations/#request-json-post-api-v2-conversations-emails--conversationId--participants--participantId--replace
            //TODO: falta definir de dónde se obtiene {conversationId}
            //TODO: falta definir de dónde se obtiene {participantId}
            //purecloud.SDK.Rest.post('/platform/api/v2/conversations/emails/{conversationId}/participants/{participantId}/replace', JSON.serialize(payload))
            //La respuesta status 200 no tiene body
        }

        public void transfer(purecloud.Email routingEmail)
        {
            //ATENCIÓN: SOLO FUNCIONA CON WINTER'21 debido al patch
            //Como se utiliza PATCH, no está implementado en el SDK de purecloud, hay que utilizar una Named Credential
            //La url contenida en el Named Credential será https://api.mypurecloud.com
            //TODO: conseguir username y contraseña para registrar la Named credential
            //Se forma un payload con los parámetros del purecloud.Email: https://help.mypurecloud.com/articles/use-the-sdk-to-route-salesforce-emails
            //Atributos que necesita el PATCH https://developer.mypurecloud.com/api/rest/v2/conversations/#request-json-patch-api-v2-conversations-emails--conversationId-
            //TODO: falta definir de dónde se obtiene {conversationId}
            //Enviar una HttpRequest con:
            //- Endpoint callout:GenesysCloudNamedCredential/platform/api/v2/conversations/emails/{conversationId}
            //- Method PATCH
            //- Headers: req.setHeader('Authorization', 'OAuth {!$Credential.OAuthToken}'), Content-Type: application/json
            //- Body: req.setBody(JSON.serialize(payload));
            //TODO: ¿Guardar algo de la response? https://developer.mypurecloud.com/api/rest/v2/conversations/#response-json-patch-api-v2-conversations-emails--conversationId--200
        }

        public void route(RoutingWork routingWork)
        {
            //TODO: falta definir qué endpoint se va a utilizar (equivalente al que existe para emails) y qué atributos se necesitan recibir/enviar
        }
    }
}
