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
            List<MessageResult> responses = new List<MessageResult>();
            for (MessageRequest request : requests)
            {
                MessageResult response = new MessageResult();
                response.interactionId = GenesysCloud.RoutingService.route(request.toEmail()).interactionId;
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
        @InvocableVariable(label = 'Screen Pop Id' description='Id. de registro con el que realizar un ScreenPop. Se pasará a Genesys como el SF_URLPop')
        public String screenPopRecordId;
        @InvocableVariable(label = 'Owner Id' description='Id. de usuario en Genesys (Correo electrónico SF). Se pasará a Genesys como SF_OwnerId')
        public String[] ownerId;
        @InvocableVariable(label = 'Attribute Queue Id' description='Id. de la cola como atributo')
        public String queueIdAttribute;
        @InvocableVariable(label = 'Specialization Type' description='Tipo de especialización del caso')
        public String industrySpecializationType;
        @InvocableVariable(label = 'SLA' description='SLA restante de la interacción')
        public Integer caseSla;

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
            email.screenPopRecordId = '' + this.screenPopRecordId;
            email.attributes.put('SF_OwnerId', '' + this.ownerId);
            email.attributes.put('Genesys_QueueId', '' + this.queueIdAttribute);
            email.attributes.put('SF_Sla', '' + this.caseSla);

            return email;
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