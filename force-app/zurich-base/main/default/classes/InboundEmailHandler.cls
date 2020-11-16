global class InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope)
    {
        Messaging.InboundEmailResult emailResult = new Messaging.InboundEmailResult();

        EmailToOpportunityService.searchRelatedEmailAndOpportunity(email, envelope);

        emailResult.success = true;
        return emailResult;
    }
}