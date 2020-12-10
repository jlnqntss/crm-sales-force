trigger ContactPointAddressTrigger on ContactPointAddress (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(ContactPointAddress.sObjectType);
}