trigger AccountTrigger on Account (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(Account.sObjectType);
}