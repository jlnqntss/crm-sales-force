/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 08-03-2024
 * @last modified by  : aberuete
 **/
public without sharing class CaseHandler implements ITrigger
{
    public CaseHandler()
    {}

    /**
     * bulkBefore
     *
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        List<Case> listCasesFromZurich = new List<Case> ();
        if (Trigger.isInsert)
        {
            for (Case newCase : (List<Case>) newList)
            {
                if (newCase.Subject == 'Solicitud de ayuda al registro de MiZurich')
                {
                    listCasesFromZurich.add(newCase);
                }
            }

            if ( !listCasesFromZurich.isEmpty() )
            {
                CaseUtil.assignAccountAndContactFromDniSuppliedEmailAndPhone(listCasesFromZurich);
            }

            CaseUtil.getQueuesSprinklr();
        }

        //CV-1407
        //22-04-2024
        //Iván García
        CaseUtil.getZRMCasesRelatedToPolicy(newList);
        CaseUtil.loadMapCaseZDATypificationMetadata();

    }

    /**
     * bulkAfter
     *
     * This method is called prior to execution of an AFTER trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkAfter(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        CaseUtil.getSprinklrSocialPersonaToLinkContact( (List<Case>) newList, (Map<Id,Case>) oldMap );
        CaseUtil.getSprinklrSocialPersonaToDeleteContactRelated ( (List<Case>) newList, (Map<Id,Case>) oldMap );
    }

    /**
     * beforeInsert
     *
     * This method is called iteratively for each record to be inserted during a BEFORE
     * trigger. Never execute any SOQL/SOSL etc in this and other iterative methods.
     */
    public void beforeInsert(List<SObject> newList)
    {
        CaseUtil.assignContactToCase(newList);
        CaseUtil.assignAccountAndContactFromSuppliedEmail(newList);
        CaseUtil.updateTranscomCase(newList);
        CaseUtil.setSprinklrCaseTipification(newList);
        CaseUtil.setSprinklrCaseSubject(newList);
        CaseUtil.shortDescriptionNeeded(newList);
        CaseUtil.setSprinklrCaseCallCenterAndGroup(newList);
        CaseUtil.applyFormatToZDABody(newList);
        CaseUtil.relateCasesByTicketId(newList);
        CaseUtil.relateCaseToCustomerByNifCif(newList);
        CaseUtil.relateCasesWithMediatedAccount(newList);
        CaseUtil.checkIfPolicyHaveOpenZrmCase(newList);
        CaseUtil.casesZRMChangeStatus( (List<Case>) newList, null );
        CaseUtil.setEndDateZRMInquiry(newList);
        CaseUtil.setCaseZDATypification(newList);
        CaseUtil.setCaseZDAQueue(newList);
    }

    /**
     * beforeUpdate
     *
     * This method is called iteratively for each record to be updated during a BEFORE
     * trigger.
     */
    public void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        CaseUtil.markMilestonesCompletedWhenClose( (List<Case>) newList, (Map<Id,Case>) oldMap );
        CaseUtil.handleCaseStatusChangeZRM( (List<Case>) newList, (Map<Id,Case>) oldMap );
        CaseUtil.completeUSPMilestonesWhenClosedOrPending( (List<Case>) newList, (Map<Id,Case>) oldMap );
        CaseUtil.casesZRMChangeStatus( (List<Case>) newList, (Map<Id,Case>) oldMap );
        CaseUtil.setOwnerIdPrior( (List<Case>) newList, (Map<Id,Case>) oldMap );
        CaseUtil.preProcessReasonIdForZda( (List<Case>) newList, (Map<Id,Case>) oldMap );
    }

    /**
     * beforeDelete
     *
     * This method is called iteratively for each record to be deleted during a BEFORE
     * trigger.
     */
    public void beforeDelete(Map<Id, SObject> oldMap)
    {
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
        CaseUtil.SummaryTotalClaims( (List<Case>) newList );
        CaseUtil.updateInquiryCaseOwnerOnZRMCreation(newList);
    }

    /**
     * afterUpdate
     *
     * This method is called iteratively for each record updated during an AFTER
     * trigger.
     */
    public void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap)
    {
        CaseUtil.assignContactToCaseEmail( (List<Case>) newList );
        CaseUtil.postProcessReasonIdForZda( (List<Case>) newList, (Map<Id,Case>) oldMap );
    }

    /**
     * afterDelete
     *
     * This method is called iteratively for each record deleted during an AFTER
     * trigger.
     */
    public void afterDelete(Map<Id, SObject> oldMap)
    {
    }

    /**
     * andFinally
     *
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally(Map<Id, SObject> oldMap, Map<Id, SObject> newMap)
    {
        CaseUtil.updateSprSocialPersonaToLinkContact();
    }
}