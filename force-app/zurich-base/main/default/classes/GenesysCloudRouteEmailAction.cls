public class GenesysCloudRouteEmailAction
{

    /**
     * La acción se diseña como un Invocable Action que recoge los datos de email a enrutar de forma amigable en el Flow y los envía a Genesys mediante el API Apex de GenesysCloud
     *Acción invocable que enruta un email, definido por RouteEmailRequest, en Genesys Cloud informado del usuario destino deseado
     * y el id con el que realizar un ScreenPop. devolviendo el Id. de interacción enrutado.
     *Delega la ejecución a GenesysCloud.RoutingService.route
     @param requests Petición de enrutamiento. Formato lista para permitir el bulkificado del flow
     @return Devuelve los identificadores de interacción dados por Genesys Cloud.
     */
    @InvocableMethod(
        label='Route Email to Genesys Cloud'
        description='Allows to route an email through Genesys Cloud'
        category= 'Other'
    )
    public static List<RouteEmailResult> execute(List<RouteEmailRequest> requests)
    {
        GenesysCloud.Email email;
        List<RouteEmailResult> results = new List<RouteEmailResult>();
        RouteEmailResult result;

        if(requests.size() == 1)
        {
            for(RouteEmailRequest request : requests)
            {
                email = new GenesysCloud.Email();
                email = (GenesysCloud.Email) GenesysCloud.RoutingService.route(request.toEmail());
                //Añadir a la lista de resultados, el id de interacción recibido de Genesys
                result = new RouteEmailResult();
                result.interactionId = email.interactionId;
                results.add(result);
            }
        }
        return results;
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

            return email;
        }
    }
}