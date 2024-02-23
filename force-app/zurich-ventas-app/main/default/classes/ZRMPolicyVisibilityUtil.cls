/**
 * Clase con los métodos de utilidad de visibilidad ZRM para el trigger de póliza
 *
 * @author dmunoz
 * @date 21/02/2024 
 */
public with sharing class ZRMPolicyVisibilityUtil {


    /**
     * Método que devuelve de forma ordenada un mapa con los distintos mediadores de las polizas en vigor/anuladas del trigger y sus clientes asociados de la forma <IntermdiaryId__c, List<PolicyHolder__c>>
     * 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    public static Map<String, Set<String>> getPolicyHoldersByIntermediaryMap(List<Policy__c> newList) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();

        Set<String> aux;

        for (Policy__c policy: newList) {     
            if ('A'.equals(policy.PolicyStatus__c) || 'V'.equals(policy.PolicyStatus__c) && !policy.Blocked__c && !policy.Anonymized__c) { // poliza anulada o en vigor no bloqueada/anonimizada
                // si contiene el mediador en el mapa añado el cliente al conjunto (si es repetido no se añade)       
                if (result.containsKey(policy.IntermediaryId__c)) {
                    aux = result.get(policy.IntermediaryId__c);
                    aux.add(policy.PolicyHolder__c);
                    result.put(policy.IntermediaryId__c, aux);
    
                } else { // si no existe la clave para ese mediador, creamos la lista 
                    aux = new Set<String>();
                    aux.add(policy.PolicyHolder__c);
                    result.put(policy.IntermediaryId__c, aux);
                }
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
    public static Map<String, String> getIntermediaryGroupIdMap(Set<String> intermediariesPolicySet) {

        Map<String, String> result = new Map<String, String>();
        AccountsSelector accountSelector = new AccountsSelector();

        List<Account> intermediariesQueryList = accountSelector.findIntermediaryGroupByIntermediaries(intermediariesPolicySet);
       
        for (Account acc: intermediariesQueryList) {
            result.put(acc.Id, acc.IntermediaryGroup__c);
        }

        return result;
    }



    /**
     * Método que devuelve los mediadores y una lista de usuarios a los que crearemos un atm
     * @param intermediariesSet Set<IntermediaryId>
     * @param intermediaryWithIntermediariesGroupsIdMap <IntermediaryId, IntermediaryGroup> de cada mediador obtenemos el 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    public static Map<String, List<String>> getIntermediariesUsers(Set<String> intermediariesSet, Map<String, String> intermediaryWithIntermediariesGroupsIdMap) {
        Map<String, List<String>> result = new Map<String, List<String>>();

        // eliminio los nulos de intermediaryGroupsList para evitar enviar nulos a la query
        List<String> intermediaryGroupsNotNullList = removeNullFromList(intermediaryWithIntermediariesGroupsIdMap.values());       
        
        // Recuperamos los usuarios de los mediadores y los agrupacion de la agrupación a la que pertenezcan
        List<User> userQuery = (new UsersSelector()).findZRMActiveUsersFromIntermediaryAndAGRFromGroup(intermediariesSet, intermediaryGroupsNotNullList);


        // Recorremos los usuarios y añadimos aquellos de cada mediador
        List<User> userAGRList = new List<User>();
        for (User user : userQuery) {
            if (intermediariesSet.contains(user.Contact.AccountId)) {
                result = generateMap(result, user.Contact.AccountId, user.Id);
            }

            // Añado el usuario agr para recorrerlos despues
            if ('Agente Ventas - AGR'.equals(user.Profile.Name)) {
                userAGRList.add(user);
            }
        }

        // Recorremos los mediadores y añadimos los usuarios agr

        result = addAGRUsers(result, intermediariesSet, intermediaryWithIntermediariesGroupsIdMap, userAGRList);
           

        return result;
    }



    /**
     * Método que devuelve los mediadores y una lista de usuarios a los que crearemos un atm
     * @param policyHoldersByIntermediaryMap <IntermdiaryId, Set<PolicyHolder>
     * @param intermediariesWithUsers <IntermediaryId, List<UserId>> usuarios a insertar atm para cada mediador
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    public static void newPolicyInsertATMs(Map<String, Set<String>> policyHoldersByIntermediaryMap, Map<String, List<String>> intermediariesWithUsers) {

        List<AccountTeamMember> result = new List<AccountTeamMember>();
        List<AccountTeamMember> atms;

        // Generar los registros de atm para usuarios nominales relacionado por id de mediador
        for (String intermediaryId: policyHoldersByIntermediaryMap.keySet()) {
            for (String policyHolderId: policyHoldersByIntermediaryMap.get(intermediaryId)) {
                atms = AccountTeamMemberUtil.createATMZRMRecordList(policyHolderId, intermediariesWithUsers.get(intermediaryId));
                result.addAll(atms);
            }
        }

        System.debug('DMM 4 atms To Insert ' + result);

        // insertamos los atm
        if (!result.isEmpty()) {

            insert result;

            // si se insertan atm comprobamos si hay que activar registros de competencias y cuentas relacionadas
            // Activar posibles registros de competencia para los clientes y mediadores
            List<String> clientIds = getClientsIds(policyHoldersByIntermediaryMap.values());
            CompetitorUtil.recalculateVisibilityCompetitorSetVisibility(clientIds, policyHoldersByIntermediaryMap.keySet());

            // Activar posibles registros de AccountRelationship__c
            AccountRelationshipUtil.recalculateVisibilityAccountRelationshipSetVisibility(clientIds, policyHoldersByIntermediaryMap.keySet());

        }
    }

    /**
     * Método que aañde los usuarios agr de otros mediadores de su agrupación 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    private static Map<String, List<String>> addAGRUsers(Map<String, List<String>> result, Set<String> intermediariesSet, Map<String, String> intermediaryWithIntermediariesGroupsIdMap, List<User> userAGRList) {

        String intermediaryGroupId;
        for (String intermediaryId: intermediariesSet) {
            intermediaryGroupId = intermediaryWithIntermediariesGroupsIdMap.get(intermediaryId);
            // si tiene agrupacion añado los usuarios agr a los que apunte ese mediador
            if (intermediaryGroupId != null) {
                for (User userAGR: userAGRList) {
                    if (userAGR.Contact.Account.IntermediaryGroup__c.equals(intermediaryGroupId)) {
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
    private static List<String> removeNullFromList(List<String> listToRemoveNull) {

        List<String> result = new List<String>();

        for (String value: listToRemoveNull) {
            if (String.isNotEmpty(value)) {
                result.add(value);
            }
        }


        return result;
    }

    /**
     * Método que devuelve una lista de todos los clientes de las polizas que han llegado de info
     * 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    private static List<String> getClientsIds(List<Set<String>> policyHolderList) {
        List<String> result = new List<String>();

        for (Set<String> policyHolderSet: policyHolderList) {
            result.addAll(policyHolderSet);
        }

        return result;
    }


    /**
     * Método que añade un valor a un Map<String, List<String>>
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    private static Map<String, List<String>> generateMap(Map<String, List<String>> mapToInsert, String key, String valueToAdd) {
        List<String> aux;
        if (mapToInsert.containsKey(key)) {
            aux = mapToInsert.get(key);
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        } else {
            aux = new List<String>();
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        }

        return mapToInsert;
    }











    /**
     * Método que recupera los atm a eliminar e insertar en caso de que se hayan producido cambios de mediador en una póliza
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    /*public static Map<String, List<AccountTeamMember>> atmsIntermediaryChangeToProcess(List<Policy__c> policiesWithIntermediariesChanges, Map<Id, Policy__c> oldMap) {

        Map<String, List<AccountTeamMember>> result = new Map<String, List<AccountTeamMember>>();

        // 1º Obtener los datos de las agrupaciones tanto de los mediadores finales como de los mediadores old <IntermediaryGroup__c, List<IntermediaryId>>, List<IntermediaryId
        Map<String, Object> intermediaryData = getAllIntermediaryGroupsAndIntermediary(policiesWithIntermediariesChanges, oldMap);
        // Recupero el mapa de agrupaciones de mediadores Old
        Map<String, List<String>> intermediaryGroupsWithIntermediariesOldMap = (Map<String, List<String>>) intermediaryData.get('IntermediaryGroupsWithIntermediariesOld');
        // Recupero el mapa de agrupaciones de mediadores New
        Map<String, List<String>> intermediaryGroupsWithIntermediariesMap = (Map<String, List<String>>) intermediaryData.get('IntermediaryGroupsWithIntermediaries');
        // Recupero la lista de mediadores sin agrupacion Old
        Set<String> intermediariesWithoutIntermediaryGroupOldMap = (Set<String>) intermediaryData.get('IntermediariesWithoutIntermediaryOldGroup');
        // Recupero la lista de mediadores sin agrupacion New
        Set<String> intermediariesWithoutIntermediaryGroupMap = (Set<String>) intermediaryData.get('IntermediariesWithoutIntermediaryGroup');

        // 2º Obtengo los usuarios de cada mediador <IntermediaryId, List<User>
        Map<String, List<User>> intermediariesWithUser;// = getIntermediariesAndUsers();


        // 3º De las agrupaciones de mediadores Old, obtengo todas las pólizas que apunten a los clientes de las pólizas del trigger <PolicyHolder__c, List<IntermediaryId>>
        Map<String, List<String>> policyHolderAndIntermediariesMap;

        // 4º Recorremos las polizas y obtenemos los atm a eliminar
        /*for (Policy__c policy: policiesWithIntermediariesChanges) {
            List<String> policyHolderIntermediaries = policyHolderAndIntermediariesMap.get(policy.PolicyHolder__c);
            // si está vacia, quiere decir que no hay 
            if (policyHolderIntermediaries != null && policyHolderIntermediaries.isEmpty()) {
                // añadir a atm a buscar (policyHolder, intermediariesWithUsers.get(policy.IntermediaryId__c)) Siendo List<User> 
            }
        }*/


        // ---------

        // 5º Insertamos los nuevos atm para los usuarios de los nuevos mediadores de cada policy holder (policiesWithIntermediariesChanges)

        // ------------------------------------------------------------------------------
        


        // Recupero los mediadores old
        // Recupero el id de agrupacion de esos mediadores old SET<String> agrupacionesIdOld
        // Obtengo las polizas de la agrupacion para los clientes de policiesWithIntermediariesChanges y (mediadorId IN :MediadoresOld OR mediador.IntermediaryGroupId__c IN :agrupacionesIdOld) AND ID NOT IN :policiesWithIntermediariesChanges (evito recuperar las polizas que han cambiado)

        // compruebo para cada mediador old si existe alguna poliza 


        //return result;
    //}



    /**
     * Método que recupera los atm a eliminar e insertar en caso de que se hayan producido cambios de cliente en una póliza
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    /*public static Map<String, List<AccountTeamMember>> atmsPolicyHolderChangeToProcess(List<Policy__c> policiesWithPolicyHandlerChanges, Map<Id, Policy__c> oldMap) {

        Map<String, List<AccountTeamMember>> result = new Map<String, List<AccountTeamMember>>();



        

        // 1º Obtener lista de clientes old
        //Set<String> policyHolderOldIdSet = policyHolderOldIdSet(policiesWithPolicyHandlerChanges, oldMap);

        // 2º Obtener lista de mediadores de las polizas Set<IntermediaryId>
        Set<String> intermediariesFromPolicySet;

        // 3º Obtener agrupaciones con mediadores
        //Map<String, List<String>> intermediaryWith = getIntermediariesGroupFromIntermediary(intermediariesFromPolicySet);

        // 4º Obtener mediadores y usuarios <IntermediaryId, List<User>>

        // 5º Comprobar si sigo teniendo a nivel de agrupacion alguna poliza para ese cliente
        //List<AccountTeamMember> atmsToDelete = getATMsToDeletePolicyHolderChangeProcess();



        return result;
    }*/

    
    /**
     * Método que obtiene los clientes anteriores de las polizas
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    /*private static Set<String> policyHolderOldIdSet(List<Policy__c> policiesWithPolicyHandlerChanges, Map<Id, Policy__c> oldMap) {

        Set<String> result = new Set<String>();

        for (Policy__c policy :policiesWithPolicyHandlerChanges) {
            result.add(oldMap.get(policy.Id).PolicyHolder__c);
        }

        return result;
    }*/

    /**
     * 
     * intermediaryAndIntermediaryGroupMap <IntermediaryId, IntermediaryGroupId>
     * intermediaryGroupPolicyHolders <IntermediaryGroupId, Set<PolicyHolder> (no incluye las polizas del trigger) solo tenemos que ver si para esa agrupacion existe alguna otra poliza para ese cliente
     * intermediaryPolicyHolders <IntermediaryId, Set<PolicyHolder> (no incluye las polizas del trigger) solo tenemos que ver si para ese mediador existe alguna otra poliza para ese cliente
     * intermediariesWithUsersMap <IntermediaryId, List<User>
     * 
     */

    /*private static List<AccountTeamMember> getATMsToDeletePolicyHolderChangeProcess(Map<String, String> intermediaryAndIntermediaryGroupMap) {
        List<AccountTeamMember> result = new List<AccountTeamMember>();

        Set<String> policyHolderToATMQuery = new Set<String>();
        Set<String> usersIdToATMQuery = new Set<String>();

        // Recorro cada cliente old
        String policyHolderOld;
        for (Policy__c policy: policiesWithPolicyHandlerChanges) {
            policyHolderOld = oldMap.get(policy.Id).PolicyHolder__c;
            // obtengo el mediador de la poliza
            String intermediaryId = policy.IntermediaryId__c;
            // ¿tiene agrupacion ese mediador?
            if (intermediaryAndIntermediaryGroupMap.get(intermediaryId) != null) {
                
            } else { //no tiene agrupacion
                // Existe alguna poliza adicional para ese cliente para ese mediador?
                Set<String> intermediaryPoliciesHolderSet = intermediaryPolicyHolders.get(intermediaryId);
                if (intermediaryPoliciesHolderSet != null && intermediaryPoliciesHolderSet.isEmpty()) {
                    // añadir a datos to query atm, policyHolderOld, List<User>
                    policyHolderToATMQuery.add(policyHolderOld);
                    usersIdToATMQuery.AddAll(intermediariesWithUsersMap.get(intermediaryId));                    
                }
            }

        }

        return result;
    }*/



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
     * Método que recorre las polizas para obtener los mediadores y así ordenar la información en agrupaciones (si tienen) <IntermediaryGroup, List<Intermediary> o List<String>
     *
     * @author dmunoz
     * @date 21/02/2024 
     */
    /*private static Map<String, Object> getAllIntermediaryGroupsAndIntermediary(List<Policy__c> policiesToProcess, Map<Id, Policy__c> oldMap) {

        Map<String, Object> result = new Map<String, Object>();
        Map<String, List<String>> intermediaryGroupsWithIntermediariesOldMap = new Map<String, List<String>>();
        Map<String, List<String>> intermediaryGroupsWithIntermediariesMap = new Map<String, List<String>>();
        Set<String> intermediariesWithoutIntermediaryGroupOldList = new Set<String>();
        Set<String> intermediariesWithoutIntermediaryGroupList = new Set<String>();
        AccountsSelector accountSelector = new AccountsSelector();

        // Genero Listas de mediadores new y mediadores old
        Set<String> intermediariesOldSet = new Set<String>();
        Set<String> intermediariesNewSet = new Set<String>();

        for (Policy__c policy :policiesToProcess) {
            intermediariesNewSet.add(policy.IntermediaryId__c);
            intermediariesOldSet.add(oldMap.get(policy.Id).IntermediaryId__c);
        }

        
        // Query BD
        Set<String> intermediariesToQuery = new Set<String>();
        intermediariesToQuery.addAll(intermediariesNewSet);
        intermediariesToQuery.addAll(intermediariesOldSet);
        List<Account> intermediariesQueryList = accountSelector.findIntermediaryGroupByIntermediaries(intermediariesToQuery);

        for (Account intermediary: intermediariesQueryList) {
            if (String.isEmpty(intermediary.IntermediaryGroup__c)) {
                if (intermediariesOldSet.contains(intermediary.Id)) {
                    intermediariesWithoutIntermediaryGroupOldList.add(intermediary.Id);
                }
                if (intermediariesNewSet.contains(intermediary.Id)) {
                    intermediariesWithoutIntermediaryGroupList.add(intermediary.Id);
                }
            } else {
                if (intermediariesOldSet.contains(intermediary.Id)) {
                    intermediaryGroupsWithIntermediariesOldMap = generateMap(intermediaryGroupsWithIntermediariesOldMap, intermediary.IntermediaryGroup__c, intermediary.Id);
                } 
                if (intermediariesNewSet.contains(intermediary.Id)) {
                    intermediaryGroupsWithIntermediariesMap = generateMap(intermediaryGroupsWithIntermediariesOldMap, intermediary.IntermediaryGroup__c, intermediary.Id);
                }
            }
        }

        result.put('IntermediaryGroupsWithIntermediariesOld', intermediaryGroupsWithIntermediariesOldMap);
        result.put('IntermediaryGroupsWithIntermediaries', intermediaryGroupsWithIntermediariesMap);
        result.put('IntermediariesWithoutIntermediaryGroup', intermediariesWithoutIntermediaryGroupList);
        result.put('IntermediariesWithoutIntermediaryOldGroup', intermediariesWithoutIntermediaryGroupOldList);
        return result;
    }*/


    
    
}