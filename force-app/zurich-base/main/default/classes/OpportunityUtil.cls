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
    public static void detectOpportunityStageChange(List<Opportunity> newList, Map<Id, Opportunity> oldMap)
    {
        for(Opportunity opty : newList)
        {   
            if(opty.StageName != oldMap.get(opty.Id).StageName && String.isNotBlank(opty.InfoQuoteNumber__c) && UserInfo.getName() == 'Integrator')
            {
                opty.StageName = oldMap.get(opty.Id).StageName;
            }
        }

    }
}