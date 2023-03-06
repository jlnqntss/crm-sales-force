/**
 * @description       : 
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-05-2023
 * @last modified by  : aberuete
**/
public with sharing class FollowUpHandler implements ITrigger 
{
    @testvisible
    private static final String ERROR_TYPE = 'No puede cargar más de un tipo de seguimiento en una misma carga';

    public FollowUpHandler() {

    }

     /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore(List<SObject> newList, Map<Id, SObject> oldMap) {}

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter(List<SObject> newList, Map<Id, SObject> oldMap) {}

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(List<SObject> newList) 
    {
    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {}

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(Map<Id, SObject> oldMap) {
    }

    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public void afterInsert(List<SObject> newList) 
    {
        List<FollowUp__c> listFollowUps = (List<FollowUp__c>)newList;
        Set<String> typeOfFollowUp = new Set<String>() ;
        
        for (FollowUp__c followUp : listFollowUps)
        {
            typeOfFollowUp.add(followUp.Type__c);
        }

        if (typeOfFollowUp.size() > 1)
        {
            throw new FollowUpHandlerException(ERROR_TYPE);
        }
    }

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap) {
        
    }

    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public void afterDelete(Map<Id, SObject> oldMap) {
    }

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) 
    {
        List<AsyncApexJob> numberOfBatchProcessFollowUps = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'Batch_ProcessFollowUps'});
        List<FollowUp__c> listFollowUps = (List<FollowUp__c>)newMap.values();
        Set<String> typeOfFollowUp = new Set<String>() ;
        
        for (FollowUp__c followUp : listFollowUps)
        {
            typeOfFollowUp.add(followUp.Type__c);
        }
        if (typeOfFollowUp.size() == 1  && numberOfBatchProcessFollowUps.isEmpty() )
        {
            database.executeBatch(new Batch_ProcessFollowUps (new List<String>(typeOfFollowUp)[0]) , 200);
        }
    }

    private class FollowUpHandlerException extends Exception {}
}