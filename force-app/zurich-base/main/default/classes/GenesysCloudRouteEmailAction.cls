public class GenesysCloudRouteEmailAction
{

    /**
     * La acción se diseña como un Invocable Action que recoge los datos de email a enrutar de forma amigable en el Flow y los envía a Genesys mediante el API Apex de GenesysCloud
     * Acción invocable que enruta un email, definido por RouteEmailRequest, en Genesys Cloud informado del usuario destino deseado
     * y el id con el que realizar un ScreenPop. devolviendo el Id. de interacción enrutado.
     * Delega la ejecución a GenesysCloud.RoutingService.route
       @param requests Petición de enrutamiento. Formato lista para permitir el bulkificado del flow
       @return Devuelve los identificadores de interacción dados por Genesys Cloud.
     */
    @InvocableMethod(
        label='Route Email to Genesys Cloud'
               description='Allows to route an email through Genesys Cloud'
                            category= 'Other'
        )
    public static void execute(List<RouteEmailRequest> requests)
    {
        //Construir mapa con las colas de Genesys <-> Nombre
        Map<String,String> mapGenesysQueueNameId = new Map<String,String>();
        List<purecloud__PureCloud_Queue__c> genesysQueues = new List<purecloud__PureCloud_Queue__c>();
        genesysQueues = [SELECT Id, Name, purecloud__PureCloud_Queue_ID__c FROM purecloud__PureCloud_Queue__c];
        for(purecloud__PureCloud_Queue__c gQueue: genesysQueues)
        {
            mapGenesysQueueNameId.put(gQueue.Name,gQueue.purecloud__PureCloud_Queue_ID__c);
        }

        Map<GenesysCloud.Email, String> emailMessageIdsByGenesysEmail = new Map<GenesysCloud.Email, String>();

        for(RouteEmailRequest request : requests)
        {
            //Si viene relleno queueId pero no existe
            if(request.queueId != null && !mapGenesysQueueNameId.containsKey(request.queueId))
            { //Lanzar excepción para que el Flow registre un error
                throw new GenesysRouteEmailActionException('The genesys queue '+ request.queueId +' does not exists.');
            }
            //Si viene relleno queueId y sí existe:
            else if(request.queueId != null && mapGenesysQueueNameId.containsKey(request.queueId))
            {
                //Sustituir el nombre de la cola por su ID
                String queueId = mapGenesysQueueNameId.get(request.queueId);
                request.queueId = queueId;
                emailMessageIdsByGenesysEmail.put(request.toEmail(), request.emailMessageId);
            }
            //Si no viene relleno queueId, enrutar normal, ya que es opcional si va relleno flowId
            else{
                emailMessageIdsByGenesysEmail.put(request.toEmail(), request.emailMessageId);
            }
        }

        GenesysCloud.RoutingService.route(new List<GenesysCloud.Email>(emailMessageIdsByGenesysEmail.keySet() ), new UpdateEmailMessageCallback(emailMessageIdsByGenesysEmail) );
    }

    /**
     * Devuelve los identificadores de interacción dados por Genesys Cloud
     */
    public class RouteEmailResult
    {
        @InvocableVariable(label='Id de interacción devuelto por Genesys')
        public String interactionId;
    }

    /**
     * La acción debe poder recoger un valor, ownerId , que será el identificador (email)
     * de usuario que debe gestionar el email. Este se pasará a Genesys Cloud como un atributo personalizado SF_OwnerId.
     */
    public class RouteEmailRequest
    {
        @InvocableVariable(label = 'Subject' description='Asunto del correo')
        public String subject;
        @InvocableVariable(label = 'To Name' description='Nombre a mostrar como destino')
        public String toName;
        @InvocableVariable(label = 'To Address' description='Correo electrónico destino')
        public String toAddress;
        @InvocableVariable(label = 'From Name' description='Nombre a mostrar')
        public String fromName;
        @InvocableVariable(label = 'From Address' description='Correo electrónico remitente')
        public String fromAddress;
        @InvocableVariable(label = 'Queue Id' description='Id de la cola de Genesys')
        public String queueId;
        @InvocableVariable(label = 'Flow Id' description='Id del flow de Genesys')
        public String flowId;
        @InvocableVariable(label = 'Skills' description='Skills de Genesys a aplicar')
        public String[] skillIds;
        @InvocableVariable(label = 'Priority' description='Prioridad de enrutamiento')
        public Integer priority;
        @InvocableVariable(label = 'Screen Pop Id' description='Id. de registro con el que realizar un ScreenPop. Se pasará a Genesys como el SF_URLPop')
        public String screenPopRecordId;
        @InvocableVariable(label = 'Owner Id' description='Id. de usuario en Genesys (Correo electrónico SF). Se pasará a Genesys como SF_OwnerId')
        public String ownerId;
        @InvocableVariable(label = 'Activity Id' description='Id. de la tarea asociada al Email')
        public String activityId;
        @InvocableVariable(label = 'Email Message Id' description='Id. del Email Message')
        public String emailMessageId;


        /**
         * @return Devuelve un correo en el formato GenesysCloud.Email utilizando los datos dados por el email
         */
        public GenesysCloud.Email toEmail()
        {
            GenesysCloud.Email email = new GenesysCloud.Email();

            email.subject = this.subject;
            email.toName = this.toName;
            email.toAddress = this.toAddress;
            email.fromName = this.fromName;
            email.fromAddress = this.fromAddress;
            email.queueId = this.queueId;
            email.flowId = this.flowId;
            email.skillIds = this.skillIds;
            email.priority = this.priority;
            email.screenPopRecordId = '' + this.screenPopRecordId;
            email.attributes.put('SF_OwnerId', '' + this.ownerId);
            email.attributes.put('SF_EmailURL', URL.getOrgDomainUrl().toExternalForm() + '/' + this.emailMessageId);

            return email;
        }
    }

    private class UpdateEmailMessageCallback implements GenesysCloud.IAPICallback
    {
        Map<GenesysCloud.Email, String> emailMessageIdsByGenesysEmail;

        public UpdateEmailMessageCallback(Map<GenesysCloud.Email, String> emailMessageIdsByGenesysEmail)
        {
            this.emailMessageIdsByGenesysEmail = emailMessageIdsByGenesysEmail;
        }

        public void onSuccess(List<Object> results, List<GenesysCloud.IAPIRequest> requests)
        {
            List<EmailMessage> emailMessages = new List<EmailMessage>();

            for(Object result : results)
            {
                GenesysCloud.Email email = (GenesysCloud.Email) result;
                Id relatedEmailMessageId = emailMessageIdsByGenesysEmail.get(email);

                if(String.isNotEmpty(relatedEmailMessageId) )
                {
                    emailMessages.add(new EmailMessage(
                                          Id = relatedEmailMessageId,
                                          GenesysInteractionId__c = email.interactionId
                                          ) );
                }
            }

            update emailMessages;
        }

        public void onError(Exception error)
        {
            ErrorLogUtil.commitError(error);
        }
    }

    @TestVisible
    class GenesysRouteEmailActionException extends Exception {}
}