/**
 * @description       : 
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 08-01-2023
 * @last modified by  : aberuete
**/
trigger TaskTrigger on Task (after insert, before insert, after update, before update, after delete, before delete) 
{
    TriggerFactory.createHandler(Task.sObjectType);
}