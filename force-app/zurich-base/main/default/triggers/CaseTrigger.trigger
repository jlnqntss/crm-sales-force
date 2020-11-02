trigger CaseTrigger on Case(after insert, before insert)
{
    TriggerFactory.createHandler(Case.sObjectType);

}