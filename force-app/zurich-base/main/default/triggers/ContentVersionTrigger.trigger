trigger ContentVersionTrigger on ContentVersion(after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(ContentVersion.sObjectType);
}