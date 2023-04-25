trigger ExternalRequestTrigger on ExternalRequest__c (before insert, after insert)
{
    TriggerFactory.createHandler(ExternalRequest__c.sObjectType);
}