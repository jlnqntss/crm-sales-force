trigger PolicyTrigger on Policy__c (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(Policy__c.sObjectType);
}