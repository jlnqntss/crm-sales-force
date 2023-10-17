trigger CampaignMemberTrigger on CampaignMember (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(CampaignMember.sObjectType);
}