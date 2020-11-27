trigger ContactPointEmailTrigger on ContactPointEmail(after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(ContactPointEmail.sObjectType);
}