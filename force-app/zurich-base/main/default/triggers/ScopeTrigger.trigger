/**
 * Scope__c object trigger
 *
 * @author nts (agonzalezisasi)
 * @date 30/11/2020
 */
trigger ScopeTrigger on Scope__c(before insert, after insert, before update, after update, before delete, after delete)
{
    TriggerFactory.createHandler(Scope__c.sObjectType);
}