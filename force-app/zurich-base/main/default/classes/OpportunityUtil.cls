public class OpportunityUtil
{
    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para Ofertas que provengan de INFO
     *
     * @author adelgado
     * @date 07/12/2020
     */
    public static void generateScope(List<Opportunity> newList)
    {
        List<Opportunity> optysToGenerateScope = new List<Opportunity>();

        for(Opportunity opty : newList)
        {
            if( String.isNotBlank(opty.InfoQuoteNumber__c) && opty.ScopeId__c == null
                && opty.AccountId != null)
            {
                optysToGenerateScope.add(opty);
            }
        }

        if( !optysToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('AccountId', 'BusinessCode__c', optysToGenerateScope);
        }
    }

    /**
     * Evitar modificar la etapa de la oferta de INFO cuando se actualiza a través de la integración
     *
     * @author adelgado
     * @date 26/01/2021
     */
    //20210225 sustituido por before insert
    /*public static void detectOpportunityStageChange(List<Opportunity> newList, Map<Id, Opportunity> oldMap)
    {
        for(Opportunity opty : newList)
        {
            if(opty.StageName != oldMap.get(opty.Id).StageName && String.isNotBlank(opty.InfoQuoteNumber__c) && UserInfo.getName() == 'Integrator')
            {
                opty.StageName = oldMap.get(opty.Id).StageName;
            }
        }

    }*/

    /**
     * Detect a change in the AccountId field of the offer
     * In a batch we will check if the old account is a lead and if so we will merge the lead with the client that is
     * coming from INFO (ocs-920)
     *
     * @author nts (agonzalezisasi)
     * @date 03/02/2021
     * @trigger beforeUpdate
     */
    public static void detectOpportunityAccountChange(List<Opportunity> newList, Map<Id, Opportunity> oldMap)
    {
        for(Integer i=0,j=newList.size();i<j;i++) {
            Opportunity o = newList[i];

            if( o.AccountId != oldMap.get(o.Id).AccountId ) {
                o.OldAccountId__c = oldMap.get(o.Id).AccountId;
            }
        }
    }

    /**BEFOREINSERT
     * Desde info no se rellena el campo obligatorio StageName, en ese caso hay que poner Open
     * @date 25/02/2021
     */
    public static void setStageNameOpen(List<Opportunity> newList)
    {
        for(Opportunity opty : newList)
        {
            if(String.isBlank(opty.StageName))
            {
                opty.StageName = 'Open';
            }
        }
    }

    /**BEFOREUPDATE
     * Si por cualquier motivo se pretende actualizar el Stage a null, se evita
     * @date 25/02/2021
     */
    public static void revertStageNameNull(List<Opportunity> newList, Map<Id, Opportunity> oldMap)
    {
        for(Opportunity opty : newList)
        {
            if(String.isBlank(opty.StageName))
            {
                Opportunity oldOffer = oldMap.get(opty.Id);
                opty.StageName = oldOffer.StageName;
            }
        }
    }
}