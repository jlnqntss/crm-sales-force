/**
 * @description       : Trigger del objeto FollowUp__c
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-06-2023
 * @last modified by  : aberuete
**/
trigger FollowUpTrigger on FollowUp__c (after insert) 
{
    TriggerFactory.createHandler(FollowUp__c.sObjectType);
}