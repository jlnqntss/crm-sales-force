trigger OpportunityTrigger on Opportunity (after insert, before insert, after update, before update, after delete, before delete)
{
    TriggerFactory.createHandler(Opportunity.sObjectType);
}