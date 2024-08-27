global class InboundEmailHandler implements Messaging.InboundEmailHandler
{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope)
    {

        System.debug('[ocs-9429] eamil: ' + email);
        System.debug('[ocs-9429] envelope: ' + envelope);
        Messaging.InboundEmailResult emailResult = new Messaging.InboundEmailResult();

        EmailToOpportunityService.searchRelatedEmailAndOpportunity(email, envelope);

        emailResult.success = true;
        return emailResult;
    }
}