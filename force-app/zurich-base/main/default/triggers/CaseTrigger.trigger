trigger CaseTrigger on Case(after insert, before insert, after update, before update, after delete, before delete) {
  TriggerFactory.createHandler(Case.sObjectType);

}