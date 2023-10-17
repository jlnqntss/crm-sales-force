trigger CampaignTrigger on Campaign (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(Campaign.sObjectType);
}