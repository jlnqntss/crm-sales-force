public class OpportunityHandler implements ITrigger
{

    public OpportunityHandler()
    {}

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        // arcortazar - 11/03/2022: ZE-1327, cargamos un listado de perfiles que tienen permitido efectuar modificaciones en las ofertas cerradas ganadas
        OpportunityUtil.initMapOfProfiles();
        // jfherrero - 21/09/2023: CV-458, cargamos un mapa de Accounts con sus record types para informar un campo en las ofertas creadas
        OpportunityUtil.initMapOfAccountRecordTypes(newList);
        if ( oldMap != null && !oldMap.isEmpty() )
        {
            OpportunityUtil.initMapOfAccountRecordTypesTriggerOld( oldMap.values() );
        }
        // arcortazar - 22/12/2023: CV-1182, cargamos el mapa que relaciona los Business Code con los scopes
        OpportunityUtil.fillMapBusinessCode();
    }

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
    {
        OpportunityUtil.setStageNameOpen(newList);
        OpportunityUtil.setSalesProcess(newList);
        OpportunityUtil.identifyPotentialMatches(newList);
    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        OpportunityUtil.preventNullUpdates( (List<Opportunity>) newList, (Map<Id, Opportunity>) oldMap );
        OpportunityUtil.detectOpportunityAccountChange( (List<Opportunity>) newList, (Map<Id, Opportunity>) oldMap );

        // fpalomo - 08/04/2024 - Nuevo método "handleAccountOrIntermediaryChange" para rellenar los campos solicitados en CV-2058
        OpportunityUtil.handleAccountOrIntermediaryChange( (List<Opportunity>) newList, (Map<Id, Opportunity>) oldMap );

        // arcortazar - 09/03/2022: Validamos si puede llevarse a cabo el cambio que se presenta
        OpportunityUtil.validateOfferStage( (List<Opportunity>) newList, (Map<Id, Opportunity>) oldMap );
        // jpereztirado - 23/12/2022: Validamos que el Old Owner y New Owner no sean ambos ZE Advisors
        OpportunityUtil.validateChangeOwner( (List<Opportunity>) newList, (Map<Id, Opportunity>) oldMap );
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
        OpportunityUtil.generateScope(newList);
        OpportunityUtil.zrmVisibilityNewOffer(newList);
    }

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        OpportunityUtil.generateScope(newList);
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
    {}
}