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
            if( String.isNotBlank(opty.InfoQuoteNumber__c) && opty.ScopeId__c == null && opty.AccountId != null)
            {
                optysToGenerateScope.add(opty);
            }
        }

        if( !optysToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('AccountId', 'BusinessCode__c', optysToGenerateScope);
        }
    }
}