trigger OrderTrigger on Order(
  before insert, after insert, 
  before update, after update, 
  before delete, after delete) {
  TriggerFactory.createHandler(Order.sObjectType);

}