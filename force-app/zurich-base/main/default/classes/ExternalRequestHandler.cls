public class ExternalRequestHandler implements ITrigger
{
    public ExternalRequestHandler()
    {}

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore(List<SObject> newList, Map<Id, SObject> oldMap)
    {}

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter(List<SObject> newList, Map<Id, SObject> oldMap)
    {}

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(List<SObject> newList)
    {}

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap)
    {}

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(Map<Id, SObject> oldMap)
    {}

    /**
     * afterInsert
     *
     * This method is called iteratively for each record inserted during an AFTER
     * trigger. Always put field validation in the 'After' methods in case another trigger
     * has modified any values. The record is 'read only' by this point.
     */
    public void afterInsert(List<SObject> newList)
    {}

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap)
    {}

    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public void afterDelete(Map<Id, SObject> oldMap)
    {}

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally(Map<Id, SObject> oldMap, Map<Id, SObject> newMap)
    {
        // Check if there are any External Request of Origin INFO (not Priority) and if any of type priority (NOTE)
        Boolean anyPriorityEntities = false;
        Boolean anyInfoNotPriority = false;

        List<ExternalRequest__c> newRequest = (List<ExternalRequest__c>)newMap.values();
        Integer i = 0;
        Integer j = newRequest.size();
        while( i<j && (!anyInfoNotPriority || !anyPriorityEntities) ) {
            if( newRequest[i].Origin__c == Transformer.ORIGIN_NAME_INFO ) {
                if( INFOHandler.PRIORITY_ENTITIES.contains(newRequest[i].Entity__c)) {
                    anyPriorityEntities = true;
                } else {
                    anyInfoNotPriority = true;
                }
            }
            i++;
        }
            
        if( anyInfoNotPriority && !Test.isRunningTest() )
            ExternalJobQueueBatchController.checkExternalJobQueueBatch();

        if( anyPriorityEntities && !Test.isRunningTest() )
            ExternalJobQueueBatchController.checkExternalJobPriorityQueueBatch();
    
    }
}