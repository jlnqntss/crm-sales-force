trigger ContactPointPhoneTrigger on ContactPointPhone(after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(ContactPointPhone.sObjectType);
}