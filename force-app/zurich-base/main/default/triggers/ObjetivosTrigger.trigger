trigger ObjetivosTrigger on Objective__c (after insert, before insert, after update, before update, after delete, before delete) {
    TriggerFactory.createHandler(Objective__c.sObjectType);
}