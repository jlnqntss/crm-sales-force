
trigger AccountRelationshipTrigger on AccountRelationship__c (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(AccountRelationship__c.sObjectType);
}