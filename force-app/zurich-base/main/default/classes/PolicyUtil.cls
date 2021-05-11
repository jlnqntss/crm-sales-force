public class PolicyUtil
{
    private static final string CLASS_NAME = 'PolicyUtil';

    /**
     * Método que controla la generación del scope correspondiente
     * Actualmente solo se generá scope para pólizas que provengan de INFO
     *
     * @author adelgado
     * @date 08/01/2021
     *
     * @change 10/05/2021 - nts (agonzalezisasi) - OCS-1798 - Se incluye el calculo de la cuenta Partner de la poliza 
     *         como evento.
     */
    public static void generateScope(List<Policy__c> newList)
    {
        List<Policy__c> polToGenerateScope = new List<Policy__c>();
        List<Policy__c> polToGeneratePartner = new List<Policy__c>();

        for(Policy__c policy : newList)
        {
            if( String.isNotBlank(policy.InfoPolicyNumber__c) && policy.ScopeId__c == null && policy.PolicyHolder__c != null)
            {
                polToGenerateScope.add(policy);
            }

            if( String.isNotBlank(policy.BusinessCode__c) && policy.Partner__c == null ) {
                polToGeneratePartner.add(policy);
            }
        }

        if( !polToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('PolicyHolder__c', 'BusinessCode__c', polToGenerateScope);
        }

        if( !polToGeneratePartner.isEmpty() ) {
            GenerateScopeUtil.generatePartnerEvents(
                Policy__c.BusinessCode__c.getDescribe().getName(), 
                Policy__c.Partner__c.getDescribe().getName(), 
                Account.getSObjectType().getDescribe().getName(), 
                Account.INFOBusinessCode__c.getDescribe().getName(), 
                polToGeneratePartner
            );
        }
    }
}
