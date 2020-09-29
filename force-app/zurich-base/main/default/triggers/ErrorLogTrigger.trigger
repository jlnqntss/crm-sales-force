/**
 * Trigger de registro de errores
 **
 * @author nts
 * @date 02/04/2020
 */
trigger ErrorLogTrigger on Error_Log__c(
  after delete,
  after insert,
  after undelete,
  after update,
  before delete,
  before insert,
  before update
) {
  TriggerFactory.createHandler(Error_Log__c.sObjectType);
}
