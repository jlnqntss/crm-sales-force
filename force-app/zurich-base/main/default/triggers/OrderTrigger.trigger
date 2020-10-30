trigger OrderTrigger on Order(after insert, after update, after delete)
{
    TriggerFactory.createHandler(Order.sObjectType);

}