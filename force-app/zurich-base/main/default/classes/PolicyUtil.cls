public class PolicyUtil
{
    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para pólizas que provengan de INFO
     *
     * @author adelgado
     * @date 08/01/2021
     */
    public static void generateScope(List<Policy__c> newList)
    {
        List<Policy__c> polToGenerateScope = new List<Policy__c>();

        for(Policy__c policy : newList)
        {
            if( String.isNotBlank(policy.InfoPolicyNumber__c) && policy.ScopeId__c == null)
            {
                polToGenerateScope.add(policy);
            }
        }

        if( !polToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('PolicyHolder__c', 'BusinessCode__c', polToGenerateScope);
        }
    }
}
