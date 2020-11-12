public with sharing class GenesysCloudRouteEmailAction
{

    @InvocableMethod(
        label='Route Email to Genesys Cloud' 
        description='Allows to route an email through Genesys Cloud' 
        category= 'Other'
    )
    public static void execute(List<RouteEmailRequest> requests)
    {
        List<GenesysCloud.Email> emails = new List<GenesysCloud.Email> ();


        if(requests.size() == 1) 
        {
            for(RouteEmailRequest request : requests)
            {
                GenesysCloud.RoutingService.route(request.toEmail());
            }
        }
    }


    public class RouteEmailRequest
    {
        @InvocableVariable(label = 'Asunto')
        public String subject;
        @InvocableVariable(label = 'To Name')
        public String toName;
        @InvocableVariable(label = 'To Address')
        public String toAddress;
        @InvocableVariable(label = 'From Name')
        public String fromName;
        @InvocableVariable(label = 'From Address')
        public String fromAddress;
        @InvocableVariable(label = 'Queue Id')
        public String queueId;
        @InvocableVariable(label = 'Flow Id')
        public String flowId;
        @InvocableVariable(label = 'Skills')
        public String[] skillIds;
        @InvocableVariable(label = 'Priority')
        public Integer priority;
        @InvocableVariable(label = 'Screen Pop Id')
        public String screenPopRecordId;

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

            return email;
        }
    }
}