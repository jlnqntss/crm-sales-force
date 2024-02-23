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
    public static void zrmVisibilityNewPolicy(List<Policy__c> newList) {

        // 1º obtener los mediadores y clientes de las polizas en vigor <IntermdiaryId__c, List<PolicyHolder__c>>
        Map<String, Set<String>> policyHoldersByIntermediaryMap = ZRMPolicyVisibilityUtil.getPolicyHoldersByIntermediaryMap(newList);
        System.debug('DMM 1 policyHoldersByIntermediaryMap ' + policyHoldersByIntermediaryMap);

        // 2º Obtener las agrupaciones de los mediadores para obtener los usuarios agr de esos mediadores <IntermdiaryId__c, IntermediaryGroup__c>
        Map<String, String> intermediaryWithIntermediariesGroupsIdMap = ZRMPolicyVisibilityUtil.getIntermediaryGroupIdMap(policyHoldersByIntermediaryMap.keySet());
        System.debug('DMM 2 intermediaryWithIntermediariesGroupsIdMap' + intermediaryWithIntermediariesGroupsIdMap);

        // 3º Obtener los usuarios de los mediadores <IntermediaryId, List<UserId>
        Map<String, List<String>> intermediariesWithUsers = ZRMPolicyVisibilityUtil.getIntermediariesUsers(policyHoldersByIntermediaryMap.keySet(), intermediaryWithIntermediariesGroupsIdMap);
        System.debug('DMM 3 intermediariesWithUsers ' + intermediariesWithUsers);

        // 4º Insertar atm
        ZRMPolicyVisibilityUtil.newPolicyInsertATMs(policyHoldersByIntermediaryMap, intermediariesWithUsers);        

        /*

        // 1º obtener los mediadores y clientes de las polizas en vigor <IntermdiaryId__c, List<PolicyHolder__c>>
        Map<String, Set<String>> policyHoldersByIntermediaryMap = getPolicyHoldersByIntermediaryMap(newList);
        
        // 2º Obtener las agrupaciones de los mediadores para obtener los usuarios agr de esos mediadores <IntermdiaryId__c, IntermediaryGroup__c>
        Map<String, String> intermediaryGroupIdMap = getIntermediaryGroupIdMap(policyHoldersByIntermediaryMap.keySet());
        
        //3º Obtener los usuarios activos nominales de los mediadores de las polizas así como todos los usuarios agr de la agrupación <ProfileName, List<User>
        Map<String, List<User>> usersOrderByProfile = getUsersOrderByProfile(policyHoldersByIntermediaryMap.keySet(), intermediaryGroupIdMap);
        
        // 4º Generar los atm para los usuarios nominales
        List<AccountTeamMember> atmAgenteVentasUser = generateATMAgenteVentaUser(policyHoldersByIntermediaryMap, usersOrderByProfile);        

        // 5º Generar los atm para los usuarios agr
        List<AccountTeamMember> atmAgenteVentasAGRUser = generateATMAgenteVentaAGRUser(policyHoldersByIntermediaryMap, intermediaryGroupIdMap, usersOrderByProfile);        

        // 6º Insertar todos los atm
        insertATMs(atmAgenteVentasUser, atmAgenteVentasAGRUser);

        // Activar posibles registros de competencia para los clientes y mediadores
        List<String> clientIds = getClientsIds(newList);
        CompetitorUtil.recalculateVisibilityCompetitorSetVisibility(clientIds, policyHoldersByIntermediaryMap.keySet());

        // Activar posibles registros de AccountRelationship__c
        AccountRelationshipUtil.recalculateVisibilityAccountRelationshipSetVisibility(clientIds, policyHoldersByIntermediaryMap.keySet());
        */

    }


    /**
     * Metodo que calcula atm para los escenarios de cambio de mediador o tomador
     * 
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    /*public static void zrmVisibilityUpdatePolicy(List<Policy__c> newList, Map<Id, Policy__c> oldMap) {

        // 1º Obtener polizas a procesar (cambio tomador o cambio mediador) <TipoCambio, List<Policy__c>>
        Map<String, List<Policy__c>> policiesToProcess = getPoliciesToProcessAfterUpdate(newList, oldMap);

        // 2º Proceso recalculo mediador
        //Map<String, List<AccountTeamMember>> atmsIntermediaryChangeToProcessMap = ZRMPolicyVisibilityUtil.atmsIntermediaryChangeToProcess(policiesToProcess, oldMap);

        // 3º Proceso recalculo tomador
        //Map<String, List<AccountTeamMember>> atmsPolicyHolderToProcessMap = ZRMPolicyVisibilityUtil.atmsPolicyHolderChangeToProcess(policiesToProcess, oldMap);
        
        // 4º Insertar nuevos atm
        //atmsDML(atmsIntermediaryChangeToProcessMap, atmsPolicyHolderToProcessMap);

    }*/


    /**
     * Método que recorre los elementos del trigger y nos quedamos solo con los que queremos <TipoCambio, List<Policy__c>>
     * 
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    /*private static Map<String, List<Policy__c>> getPoliciesToProcessAfterUpdate(List<Policy__c> newList, Map<Id, Policy__c> oldMap) {
        Map<String, List<Policy__c>> result = new Map<String, List<Policy__c>>();
        List<Policy__c> policiesWithIntermediariesChanges = new List<Policy__c>();
        List<Policy__c> policiesWithPolicyHolderChanges = new List<Policy__c>();
        
        if (newList != null && !newList.isEmpty()) {
            for (Policy__c policy: newList) {            
                if (isPolicyHolderChanged(policy, oldMap)) {
                    policiesWithPolicyHolderChanges.add(policy);
                } else if (isIntermediaryChanged(policy, oldMap)) {
                    policiesWithIntermediariesChanges.add(policy);
                }
            }
        }

        result.put('PoliciesWithIntermediariesChanges', policiesWithIntermediariesChanges);
        result.put('PoliciesWithPolicyHolderChanges', policiesWithPolicyHolderChanges);

        return result;
    }*/


    /**
     * Comprobamos si la polizas ha sufrido un cambio de tomador
     * 
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    /*private static Boolean isPolicyHolderChanged(Policy__c policy, Map<Id, Policy__c> oldMap) {
        Boolean result = false;

        if (!policy.PolicyHolder__c.equals(oldMap.get(policy.Id).PolicyHolder__c)) {
            result = true;
        }

        return result;
    }*/

    /**
     * Comprobamos si la polizas ha sufrido un cambio de mediador
     * 
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    /*private static Boolean isIntermediaryChanged(Policy__c policy, Map<Id, Policy__c> oldMap) {
        Boolean result = false;

        if (!policy.IntermediaryId__c.equals(oldMap.get(policy.Id).IntermediaryId__c)) {
            result = true;
        }

        return result;
    }*/
}
