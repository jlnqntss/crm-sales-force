trigger PlanComercialTrigger on PlanComercial__c (after insert, before insert, after update, before update, after delete, before delete) {
    TriggerFactory.createHandler(PlanComercial__c.sObjectType);
}