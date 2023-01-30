/**
 * Clase de Apex con la función de enrutamiento de comunidados que no se enrutan siguiendo el flujo de email.
 * @author rpolvera@nts-solutions.com
 * @date 04/11/2021
 */
public with sharing class GenesysCloudRouteMessageAction
{
    /**
     * La acción se diseña como un Invocable Action que recoge los datos del mensaje a enrutar desde un Flow de Salesforce.
     * Enviará esta información a Genesys mediante el API Apex de GenesysCloud en el endpoint de enrutado de emails.
     * IMPORTANTE: Aunque para Salesforce se trate de una entidad definida en Apex, esta se enviará al endpoint de emails de Genesys Cloud y será tratada de la misma manera.
     * VER: https://developer.genesys.cloud/api/rest/v2/conversations/
     * @author rpolvera@nts-solutions.com
     * @date 04/11/2021
     * @param requests Comunicado a enrutar. Formato lista para permitir el bulkificado del flow
     * @return Devuelve los identificadores de interacción dados por Genesys Cloud.
     */
    @InvocableMethod(
        label='Enrutador de mensajes a la API de Emails de Genesys Cloud'
        description='Acción para enrutar mensajes a la API de Emails de Genesys Cloud, soporta el parámetro de entrada MessageRequest definido por Apex.'
        category= 'Genesys Cloud'
        callout=true
    )
    public static List<MessageResult> execute(List<MessageRequest> requests)
    {
        try
        {
            //Construir mapa con las colas de Genesys <-> Nombre
            Map<String,String> mapGenesysQueueNameId = new Map<String,String>();
            List<purecloud__PureCloud_Queue__c> genesysQueues = new List<purecloud__PureCloud_Queue__c>();
            genesysQueues = [SELECT Id, Name, purecloud__PureCloud_Queue_ID__c FROM purecloud__PureCloud_Queue__c];
            for(purecloud__PureCloud_Queue__c gQueue: genesysQueues)
            {
                mapGenesysQueueNameId.put(gQueue.Name,gQueue.purecloud__PureCloud_Queue_ID__c);
            }
            List<MessageResult> responses = new List<MessageResult>();
            for (MessageRequest request : requests)
            {

                //Si viene relleno queueId pero no existe
                if(request.queueId != null && !mapGenesysQueueNameId.containsKey(request.queueId))
                { //Lanzar excepción para que el Flow registre un error
                    throw new GenesysCloudRouteMessageActionException('The genesys queue '+ request.queueId +' does not exists.');
                }
                //Si viene relleno queueId y sí existe:
                else if(request.queueId != null && mapGenesysQueueNameId.containsKey(request.queueId))
                {
                    //Sustituir el nombre de la cola por su ID
                    String queueId = mapGenesysQueueNameId.get(request.queueId);
                    request.queueId = queueId;
                }
                MessageResult response = new MessageResult();
                response.interactionId = GenesysCloud.RoutingService.route(request).interactionId;
                responses.add(response);
            }

            return responses;
        }
        catch (Exception e)
        {
            throw new GenesysCloudRouteMessageActionException(e.getMessage());
        }
    }

    /**
     * Clase POJO estructural para agrupar la información a enviar a GenesysCloud.
     * Extiende de GenesysCloud.RoutingWork que proporcionará a la clase la habilidad para ser enrutada en GenesysCloud.
     * @author rpolvera@nts-solutions.com
     * @date 04/11/2021
     */
    public class MessageRequest extends GenesysCloud.RoutingWork
    {
        @InvocableVariable(required=true label = 'Subject' description='Asunto del mensaje.')
        public String subject;
        @InvocableVariable(label = 'To Name' description='Nombre del detinatario a mostrar.')
        public String toName;
        @InvocableVariable(label = 'To Address' description='Correo electrónico de destino.')
        public String toAddress;
        @InvocableVariable(label = 'From Name' description='Nombre del remitente a mostrar.')
        public String fromName;
        @InvocableVariable(label = 'From Address' description='Correo electrónico del remitente.')
        public String fromAddress;
        @InvocableVariable(label = 'Queue Id' description='Id de la cola de GenesysCloud.')
        public String queueId;
        @InvocableVariable(label = 'Screen Pop Record Id' description='Identificador de Salesforce del registro con el que realizar un ScreenPop.')
        public String screenPopRecordId;
        @InvocableVariable(label = 'Owner Id' description='Identificador de Salesforce de usuario en Genesys (Correo electrónico SF).')
        public String ownerId;
        @InvocableVariable(label = 'Attribute Queue Id' description='Id. de la cola como atributo')
        public String queueIdAttribute;
        @InvocableVariable(label = 'SLA' description='SLA restante de la interacción')
        public Integer caseSla;
        @InvocableVariable(label = 'Flow Id' description='Id del flow de Genesys')
        public String flowId;
        // Se define el proveedor para la petición a Genesys Cloud
        private String provider
        {
            get
            {
                return 'Salesforce Email';
            }
        }
        // Se define el endpoint donde se enrutará el mensaje.
        private String endpoint
        {
            get
            {
                return this.getEndpoint();
            }
        }
        // Se asignan atributos a la llamada de Genesys Cloud que permitirán el popup del registro.
        private Map<String, String> attributes
        {
            get
            {
                return new Map<String, String>
                {
                    'SF_URLPop' => this.screenPopRecordId,
                    'SF_OwnerId'=> this.ownerId
                };
            }
        }
        // Se sobrescribe el endpoint del API de Genesys Cloud a consumir, este mensaje se tratará como una email.
        private String getEndpoint()
        {
            return 'emails';
        }
    }

    /**
     * Clase POJO estructual para el guardado de la respuesta de GenesysCloud.
     * @author rpolvera@nts-solutions.com
     * @date 04/11/2021
     */
    public class MessageResult
    {
        @InvocableVariable(label='Id de interacción generada en GenesysCloud.')
        public String interactionId;
    }

    /**
     * Excepción personalizada del enrutamiento de mensajes a Genesys Cloud.
     * @author rpolvera@nts-solutions.com
     * @date 04/11/2021
     */
    @TestVisible
    class GenesysCloudRouteMessageActionException extends Exception {}
}