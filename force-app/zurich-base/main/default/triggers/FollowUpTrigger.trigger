/**
 * @description       : Trigger del objeto FollowUp__c
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-08-2023
 * @last modified by  : aberuete
**/
trigger FollowUpTrigger on FollowUp__c (after insert, before insert, after update, before update,after delete, before delete) 
{
    TriggerFactory.createHandler(FollowUp__c.sObjectType);
}