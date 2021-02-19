trigger ClaimTrigger on Claim__c (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(Claim__c.sObjectType);
}