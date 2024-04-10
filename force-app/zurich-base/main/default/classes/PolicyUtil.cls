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
            Map<String, Set<String>> policyHoldersByIntermediaryMap = ZRMPolicyVisibilityUtil.getPolicyHoldersByIntermediaryMap(newList);

            if (policyHoldersByIntermediaryMap != null && !policyHoldersByIntermediaryMap.isEmpty()) 
            {
                // 2º Obtener las agrupaciones de los mediadores para obtener los usuarios agr de esos mediadores <IntermdiaryId__c, IntermediaryGroup__c>
                Map<String, String> intermediaryWithIntermediariesGroupsIdMap = ZRMPolicyVisibilityUtil.getIntermediaryGroupIdMap(policyHoldersByIntermediaryMap.keySet());
    
                // 3º Obtener los usuarios de los mediadores <IntermediaryId, List<UserId>
                Map<String, List<String>> intermediariesWithUsers = ZRMPolicyVisibilityUtil.getIntermediariesUsers(policyHoldersByIntermediaryMap.keySet(), intermediaryWithIntermediariesGroupsIdMap);
    
                // 4º Insertar atm y activar registros de competencia y cuentas relacionadas
                ZRMPolicyVisibilityUtil.newPolicyInsertATMs(policyHoldersByIntermediaryMap, intermediariesWithUsers);
            }            
        } 
        catch (Exception e) 
        {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
               
    }


    /**
     * Metodo que calcula atm para los escenarios de cambio de mediador o tomador
     * 
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    public static void zrmVisibilityUpdatePolicy(List<Policy__c> newList, Map<Id, Policy__c> oldMap) {

        // 1º Obtener polizas a procesar (cambio tomador o cambio mediador) <TipoCambio, List<Policy__c>>
        Map<String, List<Policy__c>> policiesToProcess = getPoliciesToProcessAfterUpdate(newList, oldMap);

        // 2º Proceso recalculo mediador
        ZRMPolicyVisibilityUtil.atmsIntermediaryChangeToProcess(policiesToProcess, oldMap); 

        // 3º Proceso recalculo tomador, borra e inserta atm y recalcula competencias y cuentas relacionadas
        ZRMPolicyVisibilityUtil.atmsPolicyHolderChangeToProcess(policiesToProcess, oldMap);
    }


    /**
     * Método que recorre los elementos del trigger y nos quedamos solo con los que queremos <TipoCambio, List<Policy__c>>
     * 
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    private static Map<String, List<Policy__c>> getPoliciesToProcessAfterUpdate(List<Policy__c> newList, Map<Id, Policy__c> oldMap) {
        Map<String, List<Policy__c>> result = new Map<String, List<Policy__c>>();
        List<Policy__c> policiesWithIntermediariesChanges = new List<Policy__c>();
        List<Policy__c> policiesWithPolicyHolderChanges = new List<Policy__c>();
        
        if (newList != null && !newList.isEmpty()) {
            for (Policy__c policy: newList) { 
                if (String.isNotEmpty(policy.IntermediaryId__c) && String.isNotEmpty(policy.PolicyHolder__c) &&
                ('A'.equals(policy.PolicyStatus__c) || 'V'.equals(policy.PolicyStatus__c)) 
                && !policy.Blocked__c && !policy.Anonymized__c) { // solo procesamos cambios sobre polizas no bloqueadas y en vigor o anuladas que tengan mediador y cliente
                    if (isPolicyHolderChanged(policy, oldMap)) {
                        policiesWithPolicyHolderChanges.add(policy);
                    } else if (isIntermediaryChanged(policy, oldMap)) {
                        policiesWithIntermediariesChanges.add(policy);
                    }
                }           
            }
        }

        result.put('PoliciesWithIntermediariesChanges', policiesWithIntermediariesChanges);
        result.put('PoliciesWithPolicyHolderChanges', policiesWithPolicyHolderChanges);

        return result;
    }


    /**
     * Comprobamos si la polizas ha sufrido un cambio de tomador
     * 
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    private static Boolean isPolicyHolderChanged(Policy__c policy, Map<Id, Policy__c> oldMap) {
        Boolean result = false;

        if (policy.PolicyHolder__c != null && !policy.PolicyHolder__c.equals(oldMap.get(policy.Id).PolicyHolder__c)) {
            result = true;
        }

        return result;
    }

    /**
     * Comprobamos si la polizas ha sufrido un cambio de mediador
     * 
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    private static Boolean isIntermediaryChanged(Policy__c policy, Map<Id, Policy__c> oldMap) {
        Boolean result = false;

        if (policy.IntermediaryId__c != null && !policy.IntermediaryId__c.equals(oldMap.get(policy.Id).IntermediaryId__c)) {
            result = true;
        }

        return result;
    }
}
