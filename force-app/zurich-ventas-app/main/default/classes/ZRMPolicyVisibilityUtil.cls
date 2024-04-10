/**
 * Clase con los métodos de utilidad de visibilidad ZRM para el trigger de póliza
 *
 * @author dmunoz
 * @date 21/02/2024
 */
public with sharing class ZRMPolicyVisibilityUtil
{


    /**
     * Método que recalcula la visibilidad en caso de un cambio de mediador de una poliza
     *
     *
     * @author dmunoz
     * @date 27/02/2024
     */
    public static void atmsIntermediaryChangeToProcess(Map<String, List<Policy__c> > policiesToProcess, Map<Id, Policy__c> oldMap)
    {

        List<Policy__c> policiesWithIntermediaryChanges = policiesToProcess.get('PoliciesWithIntermediariesChanges');

        // procesamos si hay registros
        if ( policiesWithIntermediaryChanges != null && !policiesWithIntermediaryChanges.isEmpty() )
        {

            // Recalcular visibilidad mediadores old

            // Obtener mediador y clientes <IntermediaryId, Set<PolicyHolderOldId>>
            Map<String, Set<String> > policyHoldersTriggerByIntermediaryMap = getPolicyHoldersOldByIntermediaryChangeMap(policiesWithIntermediaryChanges, oldMap);

            // 1º Obtener datos
            // Obtener Set<IntermediaryOldTriggerId>
            // Obtener Set<PolicyHolderTriggerId>
            Map<String, Set<String> > datosPolicyTrigger = getPolicyTriggerData(policiesWithIntermediaryChanges, oldMap);

            // Obtener el conjunto de mediadores old Set<IntermediaryOldTriggerId>
            Set<String> intermediaryIdTriggerOldSet = datosPolicyTrigger.get('IntermediariesTriggerOldSet');
            Set<String> intermediaryIdTriggerNewSet = datosPolicyTrigger.get('IntermediariesTriggerNewSet');
            Set<String> policyHolderTriggerOldSet = datosPolicyTrigger.get('PolicyHolderTriggerOldSet');

            // Obtener el conjunto de clientes de las polizas

            // 2º Obtener las agrupaciones de mediadores old <IntermediaryIdTriggerOld, IntermediaryGroupIdDeIntermediaryIdOld>
            Map<String, String> mediadoresIdsOldYAgrupacionesIdMap = getIntermediaryGroupIdMap(intermediaryIdTriggerOldSet); // <IntermediaryId, IntermediaryGroupId>
            Map<String, String> mediadoresIdsNewYAgrupacionesIdMap = getIntermediaryGroupIdMap(intermediaryIdTriggerNewSet); // <IntermediaryId, IntermediaryGroupId>

            // Obtener el conjunto de agrupaciones de los mediadores old del trigger
            Set<String> intermediaryGroupIdSet = new Set<String>( mediadoresIdsOldYAgrupacionesIdMap.values() );
            intermediaryGroupIdSet.remove(null);

            // 3º Obtener las polizas que apuntan a mediador old (excluyendo las polizas del trigger) (2 mapas) <IntermediaryOldId/IntermediaryGroupIdDeIntermediaryIdOld, Set<PolicyHolderId>>
            Map<String, Map<String, Set<String> > > intermediaryOldBDPoliciesMap = getPolicyHolderOldPolicies(mediadoresIdsOldYAgrupacionesIdMap, intermediaryGroupIdSet, policyHolderTriggerOldSet, policiesWithIntermediaryChanges);

            // 4º Obtener los atm de todos los clientes que apuntan a intermediaryOld (2 mapas) <IntermediaryOldId/IntermediaryGroupIdDeIntermediaryIdOld, <PolicyHolderId, List<ATM>>>
            Map<String, Map<String, Map<String, List<AccountTeamMember> > > > atmsToProcess = atmsToProcess(intermediaryIdTriggerOldSet, intermediaryGroupIdSet, policyHolderTriggerOldSet);

            // 5º Recorrer los atm obtenidos y devolvemos aquellos que vamos a eliminar (nos quedamos con los atm si existe alguna otra poliza para ese cliente que apunte a intermediaryIdOld)
            List<AccountTeamMember> atmsToDelete = getATMsToDelete(mediadoresIdsOldYAgrupacionesIdMap, intermediaryOldBDPoliciesMap, atmsToProcess, policyHoldersTriggerByIntermediaryMap);

            // 6º Eliminamos los registros de atm que ya no deben existir y recalculamos la visiblidad de competencia y cuentas relacionadas
            deleteATMs(atmsToDelete);

            // Crear nuevos atm mediadoresNew -----------------------------------------------------------------
            // 7º Obtener usuarios mediadores de las polizas <IntermediaryId, <UsuarioId>
            Map<String, List<String> > intermediariesWithUsers = getIntermediariesUsers(intermediaryIdTriggerNewSet, mediadoresIdsNewYAgrupacionesIdMap);

            // 8º Obtener registros de atm para los usuarios de los mediadores de las polizas del trigger y clientesNew
            List<AccountTeamMember> atmsToInsert = getATMsToInsert(policiesWithIntermediaryChanges, intermediariesWithUsers);

            // 9º Insertar registros atm y recalcular visibilidad competencia y cuenta relacionada
            insertATMs(atmsToInsert);
        }
    }

    /**
     * Método que obtiene datos a partir de las polizas de entrada del trigger
     *
     *
     * @author dmunoz
     * @date 27/02/2024
     */
    private static Map<String, Set<String> > getPolicyTriggerData(List<Policy__c> policiesToProcess, Map<Id, Policy__c> oldMap)
    {

        Map<String, Set<String> > result = new Map<String, Set<String> >();
        Set<String> intermediaryIdTriggerOldSet = new Set<String>();
        Set<String> intermediaryIdTriggerNewSet = new Set<String>();
        Set<String> policyHolderTriggerOldSet = new Set<String>();

        for (Policy__c policy: policiesToProcess)
        {
            intermediaryIdTriggerOldSet.add(oldMap.get(policy.Id).IntermediaryId__c);
            policyHolderTriggerOldSet.add(oldMap.get(policy.Id).policyHolder__c);
            intermediaryIdTriggerNewSet.add(policy.IntermediaryId__c);
        }

        result.put('IntermediariesTriggerOldSet', intermediaryIdTriggerOldSet);
        result.put('IntermediariesTriggerNewSet', intermediaryIdTriggerNewSet);
        result.put('PolicyHolderTriggerOldSet', policyHolderTriggerOldSet);

        return result;

    }


    /******************************************************************************** Cambio Tomador de poliza ************************************************************************************************/

    /**
     * Método que recalcula la visibilidad en caso de un cambio de tomador de una poliza
     *
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    public static void atmsPolicyHolderChangeToProcess(Map<String, List<Policy__c> > policiesToProcess, Map<Id, Policy__c> oldMap)
    {

        List<Policy__c> policiesWithPolicyHolderChanges = policiesToProcess.get('PoliciesWithPolicyHolderChanges');

        // procesamos si hay registros
        if ( policiesWithPolicyHolderChanges != null && !policiesWithPolicyHolderChanges.isEmpty() )
        {
            // Obtener mediador y clientes <IntermediaryId, Set<PolicyHolderOldId>>
            Map<String, Set<String> > policyHoldersTriggerByIntermediaryMap = getPolicyHoldersOldByIntermediaryMap(policiesWithPolicyHolderChanges, oldMap);

            // 1º Query las agrupaciones de los mediadores de las polizas <IntermediaryId, IntermediaryGroupId>
            // Preparo datos
            Map<String, Set<String> > intermediaryAndPolicyHolderOldSet = getIntermediaryAndPolicyHolderOldFromPolicies(policiesWithPolicyHolderChanges, oldMap);
            // Consulto y construyo el mapa <IntermediaryId, IntermediaryGroupId>
            Map<String, String> mediadoresIdsYAgrupacionesIdMap = getIntermediaryGroupIdMap( intermediaryAndPolicyHolderOldSet.get('IntermediariesSet') ); // <IntermediaryId, IntermediaryGroupId>

            // Obtener conjunto de ids de agrupaciones de mediador Set<IntermediaryGroupId>
            // obtengo el conjunto de id de agrupacion (elimino nulos)
            Set<String> intermediaryGroupIdSet = new Set<String>( mediadoresIdsYAgrupacionesIdMap.values() );
            intermediaryGroupIdSet.remove(null);

            // 2º Obtengo de oldMap los policyHolderOldId del trigger Set<policyHolderOldIdTriggerSet>
            Set<String> policyHolderOldIdTriggerSet = intermediaryAndPolicyHolderOldSet.get('ClientsOldSet');

            // 3º Query polizas que apunten a ese cliente y mediador/agrupacion sea el de la poliza (quitamos las polizas del trigger).  <IntermediaryId/IntermediaryGroupId, Set<PolicyHolderId>>
            Map<String, Map<String, Set<String> > > intermediaryPoliciesWithPolicyHolderOldBDMap = getPolicyHolderOldPolicies(mediadoresIdsYAgrupacionesIdMap, intermediaryGroupIdSet, policyHolderOldIdTriggerSet, policiesWithPolicyHolderChanges);

            // 4º Obtener los atm de policyHolderOldIdTriggerSet, usuarios mediadores/agrupacion
            Map<String, Map<String, Map<String, List<AccountTeamMember> > > > atmsToProcess = atmsToProcess(mediadoresIdsYAgrupacionesIdMap.keySet(), intermediaryGroupIdSet, policyHolderOldIdTriggerSet);

            // 5º Recorrer los atm obtenidos y devolvemos aquellos que vamos a eliminar
            List<AccountTeamMember> atmsToDelete = getATMsToDelete(mediadoresIdsYAgrupacionesIdMap, intermediaryPoliciesWithPolicyHolderOldBDMap, atmsToProcess, policyHoldersTriggerByIntermediaryMap);

            // 6º Eliminamos los registros de atm que ya no deben existir y recalculamos la visiblidad de competencia y cuentas relacionadas
            deleteATMs(atmsToDelete);

            // 7º Obtener usuarios mediadores de las polizas <IntermediaryId, <UsuarioId>
            Map<String, List<String> > intermediariesWithUsers = getIntermediariesUsers(mediadoresIdsYAgrupacionesIdMap.keySet(), mediadoresIdsYAgrupacionesIdMap);

            // 8º Obtener registros de atm para los usuarios de los mediadores de las polizas del trigger y clientesNew
            List<AccountTeamMember> atmsToInsert = getATMsToInsert(policiesWithPolicyHolderChanges, intermediariesWithUsers);

            // 9º Insertar registros atm y recalcular visibilidad competencia y cuenta relacionada
            insertATMs(atmsToInsert);
        }

    }

    //Obtener mediador y clientes <IntermediaryId, Set<PolicyHolderOldId>> de las polizas old del trigger
    private static Map<String, Set<String> > getPolicyHoldersOldByIntermediaryMap(List<Policy__c> policyList, Map<Id, Policy__c> oldMap)
    {

        Map<String, Set<String> > result = new Map<String, Set<String> >();

        for (Policy__c policy: policyList)
        {
            result = generateSetMap(result, policy.IntermediaryId__c, oldMap.get(policy.Id).policyHolder__c);
        }

        return result;
    }


    //Obtener mediador y clientes <IntermediaryOldId, Set<PolicyHolderOldId>> de las polizas old del trigger
    private static Map<String, Set<String> > getPolicyHoldersOldByIntermediaryChangeMap(List<Policy__c> policyList, Map<Id, Policy__c> oldMap)
    {

        Map<String, Set<String> > result = new Map<String, Set<String> >();

        Policy__c policyOld;
        for (Policy__c policy: policyList)
        {
            policyOld = oldMap.get(policy.Id);
            result = generateSetMap(result, policyOld.IntermediaryId__c, policyOld.policyHolder__c);
        }

        return result;
    }



    /**
     * Query polizas que apunten a ese cliente y mediador/agrupacion sea el de la poliza (quitamos las polizas del trigger).
     * recorro las polizas y guardo en 2 mapas distintos: Un mapa con las polizas del mediador y otro mapa con las polizas de la agrupacion
     *
     * @param mediadoresIdsYAgrupacionesIdMap <IntermediaryId, IntermediaryGroupId>
     * @param intermediaryGroupIdSet IntermediaryGroupId no nulos de mediadoresIdsYAgrupacionesIdMap
     * @param policyHolderOldIdTriggerSet conjunto de clientes old
     * @param policiesWithPolicyHolderChanges polizas del trigger
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static Map<String, Map<String, Set<String> > > getPolicyHolderOldPolicies(Map<String, String> mediadoresIdsYAgrupacionesIdMap, Set<String> intermediaryGroupIdSet, Set<String> policyHolderOldIdTriggerSet, List<Policy__c> policiesWithPolicyHolderChanges)
    {

        Map<String, Map<String, Set<String> > > result = new Map<String, Map<String, Set<String> > >();

        // 1º Query de polizas
        List<Policy__c> policiesQuery = ( new PoliciesSelector() ).selectByIntermediaryAndIntermediaryGroupExcludingPolicies(mediadoresIdsYAgrupacionesIdMap.keySet(), intermediaryGroupIdSet, policyHolderOldIdTriggerSet, policiesWithPolicyHolderChanges);

        // 2º Ordenar los resultados
        Map<String, Set<String> > intermediaryClientOldBDMap = new Map<String, Set<String> >(); // clientesOld del mediador que hay en mediadoresIdsYAgrupacionesIdMap.keySet() <IntermediaryId, Set<PolicyHolderId>>
        Map<String, Set<String> > intermediaryGroupClientOldBDMap = new Map<String, Set<String> >();  // todos los clienteOld de una agrupacion a la que pertenece el mediador que hay en mediadoresIdsYAgrupacionesIdMap.keySet() <IntermediaryGroupId, Set<PolicyHolderId>>

        // por cada poliza de la query compruebo su mediador y añado al cliente
        for (Policy__c policy: policiesQuery)
        {
            // si el mediador de la poliza no pertenece a una agrupacion lo añadimos a intermediaryClientOldBDMap
            if ( String.isEmpty(policy.IntermediaryId__r.IntermediaryGroup__c) )
            {
                intermediaryClientOldBDMap = generateSetMap(intermediaryClientOldBDMap, policy.IntermediaryId__c, policy.PolicyHolder__c);

            }
            else if ( String.isNotEmpty(policy.IntermediaryId__r.IntermediaryGroup__c) && mediadoresIdsYAgrupacionesIdMap.containsKey(policy.IntermediaryId__c) )   // si el mediador de la poliza pertenece a una agrupacion y ese mediador está en mediadoresIdsYAgrupacionesIdMap.keySet() lo añadimos a intermediaryClientOldBDMap Y intermediaryGroupClientOldBDMap
            {
                intermediaryClientOldBDMap = generateSetMap(intermediaryClientOldBDMap, policy.IntermediaryId__c, policy.PolicyHolder__c);
                intermediaryGroupClientOldBDMap = generateSetMap(intermediaryGroupClientOldBDMap, policy.IntermediaryId__r.IntermediaryGroup__c, policy.PolicyHolder__c); // añado tambien a la lista de polizas de la agrupacion para cuando se calcule la visibilidad de usuarios AGR

            }
            else if ( String.isNotEmpty(policy.IntermediaryId__r.IntermediaryGroup__c) && !mediadoresIdsYAgrupacionesIdMap.containsKey(policy.IntermediaryId__c) )   // si el mediador de la poliza pertenece a una agrupacion y ese mediador NO está en mediadoresIdsYAgrupacionesIdMap.keySet() lo añadimos a intermediaryGroupClientOldBDMap
            {
                intermediaryGroupClientOldBDMap = generateSetMap(intermediaryGroupClientOldBDMap, policy.IntermediaryId__r.IntermediaryGroup__c, policy.PolicyHolder__c);
            }
        }

        result.put('IntermediaryClientOldBDMap', intermediaryClientOldBDMap);
        result.put('IntermediaryGroupClientOldBDMap', intermediaryGroupClientOldBDMap);

        return result;
    }


    /**
     * Consultamos los atm y los ordenamos en <IntermediaryId, <PolicyHolderId, List<ATM>>>
     *
     * @param intermediaryPoliciesWithPolicyHolderOldBDMap contiene 2 mapas de informacion de pólizas <IntermediaryId/IntermediaryGroupId, Set<PolicyHolderId>>
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static Map<String, Map<String, Map<String, List<AccountTeamMember> > > > atmsToProcess(Set<String> intermediaryIdSet, Set<String> intermediaryGroupIdSet, Set<String> policyHolderOldIdTriggerSet)
    {
        Map<String, Map<String, Map<String, List<AccountTeamMember> > > > result = new Map<String, Map<String, Map<String, List<AccountTeamMember> > > >();

        Map<String, Map<String, List<AccountTeamMember> > > intermediaryATMs = new Map<String, Map<String, List<AccountTeamMember> > >();
        Map<String, Map<String, List<AccountTeamMember> > > intermediaryGroupATMs = new Map<String, Map<String, List<AccountTeamMember> > >();


        // Query atm
        List<AccountTeamMember> atmsQuery = ( new AccountTeamMemberSelector() ).findZRMATMsByAccountIdAndIntermediaryOrIntermediaryGroup(intermediaryIdSet, intermediaryGroupIdSet, policyHolderOldIdTriggerSet);

        // Recorro cada atm y lo clasifico segun sea del mediador o de la agrupacion
        for (AccountTeamMember atm: atmsQuery)
        {

            // si el mediador del usuario NO tiene agrupacion
            String intermediaryGroupId = atm.User.Contact.Account.IntermediaryGroup__c;
            String intermediaryId = atm.User.Contact.AccountId;

            // si el mediador no tiene agrupacion
            if ( String.isEmpty(intermediaryGroupId) )
            {
                intermediaryATMs = generateMapATM(intermediaryATMs, intermediaryId, atm);

            }
            else     // si el mediador del usuario SI tiene agrupacion informamos el mapa de atm de mediador y de agrupacion
            {
                if ( 'Agente Ventas'.equals(atm.user.Profile.Name) )
                {
                    intermediaryATMs = generateMapATM(intermediaryATMs, intermediaryId, atm);

                }
                else if ( 'Agente Ventas - AGR'.equals(atm.user.Profile.Name) )   // usuario agrupacion
                {
                    intermediaryGroupATMs = generateMapATM(intermediaryGroupATMs, intermediaryGroupId, atm);
                }
            }
        }

        result.put('IntermediaryATMs', intermediaryATMs);
        result.put('IntermediaryGroupATMs', intermediaryGroupATMs);


        return result;
    }

    /**
     * Recorremos los mediadores y eliminamos los atm en caso que no tengan para dicho cliente otra
     *
     * @param mediadoresIdsYAgrupacionesIdMap  <IntermediaryId, IntermediaryGroupId>
     * @param intermediaryPoliciesWithPolicyHolderOldBDMap contiene 2 mapas de informacion de pólizas <IntermediaryId/IntermediaryGroupId, Set<PolicyHolderId>>
     * @param atmsToProcess contiene 2 mapas de atm <IntermediaryId/IntermediaryGroupId, <PolicyHolderId, List<ATM>>>
     * @param policyHoldersTriggerByIntermediaryMap <IntermediaryId, Set<PolicyHolderOldId>>
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static List<AccountTeamMember> getATMsToDelete(Map<String, String> mediadoresIdsYAgrupacionesIdMap, Map<String, Map<String, Set<String> > > intermediaryPoliciesWithPolicyHolderOldBDMap, Map<String, Map<String, Map<String, List<AccountTeamMember> > > > atmsToProcess, Map<String, Set<String> > policyHoldersTriggerByIntermediaryMap)
    {
        List<AccountTeamMember> result = new List<AccountTeamMember>();

        // Obtengo los mapas de polizas
        Map<String, Set<String> > intermediaryClientOldBDMap = intermediaryPoliciesWithPolicyHolderOldBDMap.get('IntermediaryClientOldBDMap');
        Map<String, Set<String> > intermediaryGroupClientOldBDMap = intermediaryPoliciesWithPolicyHolderOldBDMap.get('IntermediaryGroupClientOldBDMap');

        // Obtengo los mapas de atm
        Map<String, Map<String, List<AccountTeamMember> > > intermediaryATMs = atmsToProcess.get('IntermediaryATMs');
        Map<String, Map<String, List<AccountTeamMember> > > intermediaryGroupATMs = atmsToProcess.get('IntermediaryGroupATMs');


        // 1º recorremos los mediadores para eliminar aquellos atm que sobran, quitamos primero los registros de intermediaryATMs (intermediaryATMs contiene los atm de mediadores sin agrupacion y/o mediadores con agrupacion sin usuarios agr)
        List<AccountTeamMember> atmList = checkATMsIntermediary(mediadoresIdsYAgrupacionesIdMap, intermediaryATMs, intermediaryClientOldBDMap, policyHoldersTriggerByIntermediaryMap);
        result.AddAll(atmList);


        // 2º Preparaciones para recorrer los registros atm de agrupaciones intermediaryGroupATMs (intermediaryGroupATMs contiene los atm por agrupación solo los que apuntan a usuarios AGR)
        // convierto el mapa <IntermediaryId, IntermediaryGroupId> en <IntermediaryGroupId, Set<IntermediaryId>>
        Map<String, Set<String> > intermediaryGroupIdsAndIntermediaryId = getIntermediaryGroupsWithIntermediaries(mediadoresIdsYAgrupacionesIdMap);

        // convierto policyHoldersTriggerByIntermediaryMap <IntermediaryId, Set<PolicyHolderId>> -> <IntermediaryGroupId, Set<PolicyHolderId>>
        Map<String, Set<String> > policyHoldersOldTriggerByIntermediaryGroupMap = intermediaryGroupClientsFromTrigger(intermediaryGroupIdsAndIntermediaryId, policyHoldersTriggerByIntermediaryMap);

        // 3º compruebo los atm de la agrupacion (solo borramos atm de usuarios AGR)
        List<AccountTeamMember> atmAGR = checkATMsIntermediaryGroup(intermediaryGroupIdsAndIntermediaryId, intermediaryGroupATMs, intermediaryGroupClientOldBDMap, policyHoldersOldTriggerByIntermediaryGroupMap);
        result.addAll(atmAGR);

        return result;
    }

    /** Metodo que comprueba si hay que borrar atm para la agrupacion (usuarios AGR)
     *
     * @param intermediaryId: id de mediador a comprobar
     * @param intermediaryATMs: atms del mediador, si no tiene agrupacion tendrá todos los de sus usuarios, si tiene agrupacion solo contiene los de usuarios nominales (<IntermediaryId, <PolicyHolderId, List<ATM>>>)
     * @param intermediaryClientOldBDMap: contiene para cada mediador los clientes de los cuales existen otras polizas (<IntermediaryId, Set<PolicyHolderId>>)
     * @param policyHoldersTriggerByIntermediaryMap: contiene todos los clientes old de las polizas que han llegado del trigger por mediador obtenidas de bd sin contar las polizas <IntermediaryId, <PolicyHolderOldId>
     *
     */
    private static List<AccountTeamMember> checkATMsIntermediary(Map<String, String> mediadoresIdsYAgrupacionesIdMap, Map<String, Map<String, List<AccountTeamMember> > > intermediaryATMs,
                                                                 Map<String, Set<String> > intermediaryClientOldBDMap, Map<String, Set<String> > policyHoldersTriggerByIntermediaryMap)
    {

        List<AccountTeamMember> result = new List<AccountTeamMember>();

        //recorro de cada mediador los clientesold de policyHoldersTriggerByIntermediaryMap
        Set<String> clientsToKeepVisibility;
        for ( String intermediaryId: mediadoresIdsYAgrupacionesIdMap.keySet() )
        {

            // por cada cliente old de las polizas del trigger compruebo si para dicho mediador existe alguna otra poliza para ese cliente
            for ( String clientIdOld: policyHoldersTriggerByIntermediaryMap.get(intermediaryId) )
            {
                clientsToKeepVisibility = intermediaryClientOldBDMap.get(intermediaryId);

                // si no puedo encontrar en el mapa de polizas a dicho cliente para ese mediador -> elimino atm
                if ( clientsToKeepVisibility == null || !clientsToKeepVisibility.contains(clientIdOld) )
                {
                    result.addAll( addATMToDelete(intermediaryATMs, intermediaryId, clientIdOld) );
                }
            }
        }

        return result;
    }


    /** compruebo si es necesario eliminar atm para usuarios AGR
     *
     * @param intermediaryGroupIdsAndIntermediaryId: id de agrupacion y sus mediadores <IntermediaryGroupId, Set<IntermediaryId>>
     * @param intermediaryGroupATMs: atms de la agrupación para usuarios con perfil Agente Ventas - AGR <IntermediaryGroupId, <PolicyHolderId, List<ATM>>>
     * @param intermediaryGroupClientOldBDMap: contiene para cada mediador los clientes de los cuales existen otras polizas <IntermediaryGroupId, Set<PolicyHolderOldId>>
     * @param policyHoldersOldTriggerByIntermediaryGroupMap: contiene todos los clientes old de las polizas del trigger por agrupacion <IntermediaryGroupId, <PolicyHolderOldId>
     * @param
     */
    private static List<AccountTeamMember> checkATMsIntermediaryGroup(Map<String, Set<String> > intermediaryGroupIdsAndIntermediaryId,
                                                                      Map<String, Map<String, List<AccountTeamMember> > > intermediaryGroupATMs,
                                                                      Map<String, Set<String> > intermediaryGroupClientOldBDMap,
                                                                      Map<String, Set<String> > policyHoldersOldTriggerByIntermediaryGroupMap)
    {

        List<AccountTeamMember> result = new List<AccountTeamMember>();

        // Por cada agrupacion miro si el cliente lo tiene algun mediador
        Set<String> clientesOldTriggerSet;
        for ( String intermediaryGroupId: intermediaryGroupIdsAndIntermediaryId.keySet() )
        {

            // si el cliente old que llega del trigger no lo sigue viendo la agrupacion -> eliminar
            if ( policyHoldersOldTriggerByIntermediaryGroupMap.containsKey(intermediaryGroupId) )
            {
                clientesOldTriggerSet = policyHoldersOldTriggerByIntermediaryGroupMap.get(intermediaryGroupId);
                // por cada cliente old de las polizas del trigger
                for (String clienteOldIdTrigger : clientesOldTriggerSet)
                {

                    Set<String> clientesAgrupacionSigueViendo = intermediaryGroupClientOldBDMap.get(intermediaryGroupId);
                    if ( clientesAgrupacionSigueViendo == null || !clientesAgrupacionSigueViendo.contains(clienteOldIdTrigger) )
                    {
                        // borrar
                        result.addAll( addATMToDelete(intermediaryGroupATMs, intermediaryGroupId, clienteOldIdTrigger) );
                    }
                }
            }
        }

        return result;
    }


    /**
     * Comprobamos las claves para evitar errores null pointer
     *
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static List<AccountTeamMember> addATMToDelete(Map<String, Map<String, List<AccountTeamMember> > > intermediaryATMs, String intermediaryId, String accountId)
    {
        List<AccountTeamMember> result = new List<AccountTeamMember>();

        if ( intermediaryATMs.containsKey(intermediaryId) && intermediaryATMs.get(intermediaryId).containsKey(accountId) )
        {
            result.addAll( intermediaryATMs.get(intermediaryId).get(accountId) );
        }

        return result;
    }

    /**
     * En caso que haya atm a eliminar los borramos y desencadenamos el recalculo de competencia y cuentas relacionadas
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    public static void deleteATMs(List<AccountTeamMember> atmsToDelete)
    {


        if ( !atmsToDelete.isEmpty() )
        {
            delete atmsToDelete;
        }
    }

    /**
     * Calculamos los atms a insertar
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static List<AccountTeamMember> getATMsToInsert(List<Policy__c> policyList, Map<String, List<String> > intermediariesWithUsers)
    {
        List<AccountTeamMember> result = new List<AccountTeamMember>();

        // por cada poliza obtnemos el mediador y el cliente y generamos los atm
        for (Policy__c policy: policyList)
        {
            result.AddAll( AccountTeamMemberUtil.createATMZRMRecordList( policy.PolicyHolder__c, intermediariesWithUsers.get(policy.IntermediaryId__c) ) );
        }

        return result;
    }


    /**
     * En caso que haya atm a eliminar los borramos y desencadenamos el recalculo de competencia y cuentas relacionadas
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    public static void insertATMs(List<AccountTeamMember> atmsToInsert)
    {


        if ( !atmsToInsert.isEmpty() )
        {
            insert atmsToInsert;
        }
    }


    /**
     * Método que devuelve de forma ordenada un mapa con los distintos mediadores de las polizas en vigor/anuladas del trigger y sus clientes asociados de la forma <IntermdiaryId__c, List<PolicyHolder__c>>
     *
     *
     * @author dmunoz
     * @date 12/02/2024
     */
    public static Map<String, Set<String> > getPolicyHoldersByIntermediaryMap(List<Policy__c> newList)
    {
        Map<String, Set<String> > result = new Map<String, Set<String> >();

        for (Policy__c policy: newList)
        {
            if (String.isNotEmpty(policy.IntermediaryId__c) && String.isNotEmpty(policy.PolicyHolder__c) && ( 'A'.equals(policy.PolicyStatus__c) || 'V'.equals(policy.PolicyStatus__c) )
                && !policy.Blocked__c && !policy.Anonymized__c)       // poliza anulada o en vigor no bloqueada/anonimizada
            {
                result = generateSetMap(result, policy.IntermediaryId__c, policy.PolicyHolder__c);
            }
        }

        return result;
    }


    /**
     * Método que obtiene las ids de agrupación mediador de los mediadores de las pólizas recibidas <IntermediaryId, IntermediaryGroup__c>
     *
     *
     * @author dmunoz
     * @date 12/02/2024
     */
    public static Map<String, String> getIntermediaryGroupIdMap(Set<String> intermediariesPolicySet)
    {

        Map<String, String> result = new Map<String, String>();
        AccountsSelector accountSelector = new AccountsSelector();

        List<Account> intermediariesQueryList = accountSelector.findIntermediaryGroupByIntermediaries(intermediariesPolicySet);

        for (Account acc: intermediariesQueryList)
        {
            result.put(acc.Id, acc.IntermediaryGroup__c);
        }

        return result;
    }



    /**
     * Método que devuelve los mediadores y una lista de usuarios a los que crearemos un atm
     * @param intermediariesSet Set<IntermediaryId>
     * @param mediadoresIdsYAgrupacionesIdMap <IntermediaryId, IntermediaryGroup> de cada mediador obtenemos el
     *
     * @author dmunoz
     * @date 12/02/2024
     */
    public static Map<String, List<String> > getIntermediariesUsers(Set<String> intermediariesSet, Map<String, String> mediadoresIdsYAgrupacionesIdMap)
    {
        Map<String, List<String> > result = new Map<String, List<String> >();

        // eliminio los nulos de intermediaryGroupsList para evitar enviar nulos a la query
        List<String> intermediaryGroupsNotNullList = removeNullFromList( mediadoresIdsYAgrupacionesIdMap.values() );

        // Recuperamos los usuarios de los mediadores y los agrupacion de la agrupación a la que pertenezcan
        List<User> userQuery = ( new UsersSelector() ).findZRMActiveUsersFromIntermediaryAndAGRFromGroup(intermediariesSet, intermediaryGroupsNotNullList);


        // Recorremos los usuarios y añadimos aquellos de cada mediador
        List<User> userAGRList = new List<User>();
        for (User user : userQuery)
        {
            if ( intermediariesSet.contains(user.Contact.AccountId) )
            {
                result = generateMap(result, user.Contact.AccountId, user.Id);
            }

            // Añado el usuario agr para recorrerlos despues
            if ( 'Agente Ventas - AGR'.equals(user.Profile.Name) )
            {
                userAGRList.add(user);
            }
        }

        // Recorremos los mediadores y añadimos los usuarios agr
        result = addAGRUsers(result, intermediariesSet, mediadoresIdsYAgrupacionesIdMap, userAGRList);


        return result;
    }



    /**
     * Método que devuelve los mediadores y una lista de usuarios a los que crearemos un atm
     * @param policyHoldersTriggerByIntermediaryMap <IntermdiaryId, Set<PolicyHolder>
     * @param intermediariesWithUsers <IntermediaryId, List<UserId>> usuarios a insertar atm para cada mediador
     *
     * @author dmunoz
     * @date 12/02/2024
     */
    public static void newPolicyInsertATMs(Map<String, Set<String> > policyHoldersTriggerByIntermediaryMap, Map<String, List<String> > intermediariesWithUsers)
    {

        List<AccountTeamMember> result = new List<AccountTeamMember>();
        List<AccountTeamMember> atms;

        // Generar los registros de atm para usuarios nominales relacionado por id de mediador
        for ( String intermediaryId: policyHoldersTriggerByIntermediaryMap.keySet() )
        {
            for ( String policyHolderId: policyHoldersTriggerByIntermediaryMap.get(intermediaryId) )
            {
                atms = AccountTeamMemberUtil.createATMZRMRecordList( policyHolderId, intermediariesWithUsers.get(intermediaryId) );
                result.addAll(atms);
            }
        }

        // insertamos los atm
        if ( !result.isEmpty() )
        {
            insert result;
        }
    }

    /**
     * Método que aañde los usuarios agr de otros mediadores de su agrupación
     *
     * @author dmunoz
     * @date 12/02/2024
     */
    private static Map<String, List<String> > addAGRUsers(Map<String, List<String> > result, Set<String> intermediariesSet, Map<String, String> mediadoresIdsYAgrupacionesIdMap, List<User> userAGRList)
    {

        String intermediaryGroupId;
        for (String intermediaryId: intermediariesSet)
        {
            intermediaryGroupId = mediadoresIdsYAgrupacionesIdMap.get(intermediaryId);
            // si tiene agrupacion añado los usuarios agr a los que apunte ese mediador
            if (intermediaryGroupId != null)
            {
                for (User userAGR: userAGRList)
                {
                    if ( userAGR.Contact.Account.IntermediaryGroup__c != null && String.isNotEmpty(userAGR.Contact.Account.IntermediaryGroup__c) && userAGR.Contact.Account.IntermediaryGroup__c.equals(intermediaryGroupId) )
                    {
                        result = generateMap(result, intermediaryId, userAGR.Id);
                    }
                }
            }
        }

        return result;
    }



    /**
     * Método que elimina valores nulos de una lista, se crea ya que el metodo removeAll(null) no funciona
     *
     * @author dmunoz
     * @date 21/02/2024
     */
    private static List<String> removeNullFromList(List<String> listToRemoveNull)
    {

        List<String> result = new List<String>();

        for (String value: listToRemoveNull)
        {
            if ( String.isNotEmpty(value) )
            {
                result.add(value);
            }
        }


        return result;
    }


    /**
     * Método que añade un valor a un Map<String, List<String>>
     *
     * @author dmunoz
     * @date 21/02/2024
     */
    private static Map<String, List<String> > generateMap(Map<String, List<String> > mapToInsert, String key, String valueToAdd)
    {
        List<String> aux;
        if ( mapToInsert.containsKey(key) )
        {
            aux = mapToInsert.get(key);
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        }
        else
        {
            aux = new List<String>();
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        }

        return mapToInsert;
    }

    /**
     * Método que añade un valor a un Map<String, Set<String>>
     *
     * @author dmunoz
     * @date 21/02/2024
     */
    private static Map<String, Set<String> > generateSetMap(Map<String, Set<String> > mapToInsert, String key, String valueToAdd)
    {
        Set<String> aux;
        if ( mapToInsert.containsKey(key) )
        {
            aux = mapToInsert.get(key);
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        }
        else
        {
            aux = new Set<String>();
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        }

        return mapToInsert;
    }


    /**
     * metodo que genera el mapa de atm <IntermediaryId, <ClientOldId, List<AccountTeam>>> o <IntermediaryGroupId, <ClientOldId, List<AccountTeam>>>
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static Map<String, Map<String, List<AccountTeamMember> > > generateMapATM(Map<String, Map<String, List<AccountTeamMember> > > result, String key1, AccountTeamMember atm)
    {
        Map<String, List<AccountTeamMember> > auxMap;
        List<AccountTeamMember> auxList;

        // si el mapa resultado contiene ese mediador
        if ( result.containsKey(key1) )
        {
            auxMap = result.get(key1);
            if ( auxMap.containsKey(atm.AccountId) )
            {
                auxList = auxMap.get(atm.AccountId);
                auxList.add(atm);
                auxMap.put(atm.AccountId, auxList);
                result.put(key1, auxMap);
            }
            else
            {
                auxList = new List<AccountTeamMember>();
                auxList.add(atm);
                auxMap.put(atm.AccountId, auxList);
                result.put(key1, auxMap);
            }

        }
        else     // si el mapa resultado NO contiene ese mediador, añado el mediador, el cliente del atm y el atm
        {
            auxMap = new Map<String, List<AccountTeamMember> >();
            auxList = new List<AccountTeamMember>();
            auxList.add(atm);
            auxMap.put(atm.AccountId, auxList);
            result.put(key1, auxMap);
        }
        return result;
    }


    /**
     * Método que obtiene los mediadores de las polizas y los clientes old de las polizas que se han modificado
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static Map<String, Set<String> > getIntermediaryAndPolicyHolderOldFromPolicies(List<Policy__c> policiesWithPolicyHolderChanges, Map<Id, Policy__c> oldMap)
    {
        Map<String, Set<String> > result = new Map<String, Set<String> >();
        Set<String> intermediariesSet = new  Set<String>();
        Set<String> clientsOldSet = new  Set<String>();

        for (Policy__c policy: policiesWithPolicyHolderChanges)
        {
            intermediariesSet.add(policy.IntermediaryId__c);
            clientsOldSet.add(oldMap.get(policy.Id).PolicyHolder__c);
        }

        result.put('IntermediariesSet', intermediariesSet);
        result.put('ClientsOldSet', clientsOldSet);

        return result;
    }


    /**
     * Convierto el mapa convierto el mapa <IntermediaryId, IntermediaryGroupId> en <IntermediaryGroupId, Set<IntermediaryId>>
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static Map<String, Set<String> > getIntermediaryGroupsWithIntermediaries(Map<String, String> mediadoresIdsYAgrupacionesIdMap)
    {
        Map<String, Set<String> > result = new Map<String, Set<String> >();
        String intermediaryGroupId;

        for ( String intermediaryId: mediadoresIdsYAgrupacionesIdMap.keySet() )
        {
            intermediaryGroupId = mediadoresIdsYAgrupacionesIdMap.get(intermediaryId);
            if ( String.isNotEmpty(intermediaryGroupId) )
            {
                result = generateSetMap(result, intermediaryGroupId, intermediaryId);
            }
        }

        return result;
    }


    /**
     * Convierto el mapa convierto el mapa <IntermediaryId, IntermediaryGroupId> en <IntermediaryGroupId, Set<IntermediaryId>>
     *
     * @param intermediaryGroupIdsAndIntermediaryId <IntermediaryGroupId, Set<IntermediaryId>>
     * @param policyHoldersTriggerByIntermediaryMap <IntermediaryId, Set<PolicyHolderId>>
     *
     * @author dmunoz
     * @date 26/02/2024
     */
    private static Map<String, Set<String> > intermediaryGroupClientsFromTrigger(Map<String, Set<String> > intermediaryGroupIdsAndIntermediaryId, Map<String, Set<String> > policyHoldersTriggerByIntermediaryMap)
    {
        Map<String, Set<String> > result = new Map<String, Set<String> >();


        // por cada agrupacion añado todos los registros de id de clientes
        Set<String> aux;
        for ( String intermediaryGroupId: intermediaryGroupIdsAndIntermediaryId.keySet() )
        {
            aux = new Set<String>();
            for ( String intermediaryId: intermediaryGroupIdsAndIntermediaryId.get(intermediaryGroupId) )
            {
                aux.addAll( policyHoldersTriggerByIntermediaryMap.get(intermediaryId) );

            }
            result.put(intermediaryGroupId, aux);
        }

        return result;
    }


}