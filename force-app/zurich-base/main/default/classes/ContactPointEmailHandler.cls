public without sharing class ContactPointEmailHandler implements ITrigger
{
    public ContactPointEmailHandler()
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
    {
        ContactPointEmailUtil.getRelatedPrimaryContactEmails( (List<ContactPointEmail>) newList, (Map<Id, ContactPointEmail>) oldMap );
    }

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(List<SObject> newList)
    {
        ContactPointEmailUtil.establishAsPrimary((List<ContactPointEmail>)newList, null);
    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        ContactPointEmailUtil.establishAsPrimary((List<ContactPointEmail>)newList, (Map<Id, ContactPointEmail>)oldMap);
    }

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
    {
        ContactPointEmailUtil.generateScope(newList);
        ContactPointEmailUtil.updateRelatedPrimaryContactPointEmails( (List<ContactPointEmail>) newList, null );
    }

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        ContactPointEmailUtil.generateScope(newList);
        ContactPointEmailUtil.updateRelatedPrimaryContactPointEmails( (List<ContactPointEmail>) newList, (Map<Id, ContactPointEmail>) oldMap );
    }

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
        ContactPointEmailUtil.updateRelatedContactPoints();
    }
}