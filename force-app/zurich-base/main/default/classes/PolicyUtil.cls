public class PolicyUtil
{
    private static final string CLASS_NAME = 'PolicyUtil';
    private static final string AGENTEVENTA_PROFILE = 'Agente Ventas';
    private static final string AGENTEVENTAAGR_PROFILE = 'Agente Ventas - AGR';

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

            if( String.isNotBlank(policy.BusinessCode__c) && policy.Partner__c == null )
            {
                polToGeneratePartner.add(policy);
            }
        }

        if( !polToGenerateScope.isEmpty() )
        {
            GenerateScopeUtil.generateScopeEvents('PolicyHolder__c', 'BusinessCode__c', polToGenerateScope);
        }

        if( !polToGeneratePartner.isEmpty() )
        {
            GenerateScopeUtil.generatePartnerEvents(
                Policy__c.BusinessCode__c.getDescribe().getName(),
                Policy__c.Partner__c.getDescribe().getName(),
                Account.getSObjectType().getDescribe().getName(),
                Account.INFOBusinessCode__c.getDescribe().getName(),
                polToGeneratePartner
                );
        }
    }

    /**
     * Informa los siguientes campos para pólizas en las que se haya cambiado el mediador o cliente
     *
     * @author fpalomo
     * @date 08/04/2024
     */
    public static void handlePolicyHolderOrIntermediaryChange(List<Policy__c> newList, Map<Id, Policy__c> oldMap)
    {
        for(Policy__c policyNew : newList)
        {   
            if (String.isNotEmpty(policy.IntermediaryId__c) && String.isNotEmpty(policy.PolicyHolder__c) &&
                    ( 'A'.equals(policy.PolicyStatus__c) || 'V'.equals(policy.PolicyStatus__c) )
                    && !policy.Blocked__c && !policy.Anonymized__c) // solo procesamos cambios sobre polizas no bloqueadas y en vigor o anuladas que tengan mediador y cliente
            {
                Policy__c policyOld = oldMap.get(policyNew.Id);
    
                // AccountId
                if (policyNew.PolicyHolder__c != policyOld.PolicyHolder__c)
                {
                    policyNew.ZRMMovementType__c = Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_CLIENTE;
                    policyNew.LastAccountId__c = policyOld.PolicyHolder__c;
                }
    
                // Mediador
                else if (policyOld.IntermediaryId__c != policyNew.IntermediaryId__c)
                {
                    policyNew.ZRMMovementType__c = Batch_IntermediaryOrAccountChangeUtil.MOVEMENT_TYPE_CAMBIO_MEDIADOR;
                    policyNew.LastAccountId__c = policyOld.IntermediaryId__c;
                }
    
                // Estos dos campos se rellenan de la misma forma para cualquiera de los dos casos posibles
                if (policyOld.LastAccountId__c != policyNew.LastAccountId__c)
                {
                    policyNew.LastDateIntermediaryOrAccountChange__c = System.today();
                    policyNew.VisibilityRetry__c = 0;
                }                
            }
        }
    }
    
    
    /******************************* Métodos principales Visibilidad ZRM ******************************************************/

    /**
     * Metodo que genera atm cuando llega una nueva poliza en vigor o anulada para los usuarios ZRM
     *
     *
     * @author dmunoz
     * @date 12/02/2024
     */
    public static void zrmVisibilityNewPolicy(List<Policy__c> newList)
    {

        try
        {
            // 1º obtener los mediadores y clientes de las polizas en vigor <IntermdiaryId__c, List<PolicyHolder__c>>
            Map<String, Set<String> > policyHoldersByIntermediaryMap = ZRMPolicyVisibilityUtil.getPolicyHoldersByIntermediaryMap(newList);

            if ( policyHoldersByIntermediaryMap != null && !policyHoldersByIntermediaryMap.isEmpty() )
            {
                // 2º Obtener las agrupaciones de los mediadores para obtener los usuarios agr de esos mediadores <IntermdiaryId__c, IntermediaryGroup__c>
                Map<String, String> intermediaryWithIntermediariesGroupsIdMap = ZRMPolicyVisibilityUtil.getIntermediaryGroupIdMap( policyHoldersByIntermediaryMap.keySet() );

                // 3º Obtener los usuarios de los mediadores <IntermediaryId, List<UserId>
                Map<String, List<String> > intermediariesWithUsers = ZRMPolicyVisibilityUtil.getIntermediariesUsers(policyHoldersByIntermediaryMap.keySet(), intermediaryWithIntermediariesGroupsIdMap);

                // 4º Insertar atm y activar registros de competencia y cuentas relacionadas
                ZRMPolicyVisibilityUtil.newPolicyInsertATMs(policyHoldersByIntermediaryMap, intermediariesWithUsers);
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }

    }
}
