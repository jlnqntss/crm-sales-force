trigger AssetTrigger on Asset (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(Asset.sObjectType);
}