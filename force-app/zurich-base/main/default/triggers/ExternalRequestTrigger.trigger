trigger ExternalRequestTrigger on ExternalRequest__c (after insert)
{
    TriggerFactory.createHandler(ExternalRequest__c.sObjectType);
}