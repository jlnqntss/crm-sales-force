/**
 * Clase con los métodos de utilidad de visibilidad ZRM para ofertas
 *
 * @author dmunoz
 * @date 05/03/2024 
 */
public without sharing class ZRMOfferVisibilityUtil {

    /**
     * Método que devuelve de forma ordenada un mapa con los distintos mediadores de las ofertas no bloqueadas o anonimizadas trigger y sus clientes asociados de la forma <IntermdiaryId__c, List<AccountId>>
     * 
     *
     * @author dmunoz
     * @date 05/03/2024 
     */
    public static Map<String, Set<String>> getAccountIdByIntermediaryMap(List<Opportunity> newList) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();

        for (Opportunity offer: newList) {     
            if (String.isNotEmpty(offer.IntermediaryId__c) && !offer.Blocked__c && !offer.Anonymized__c) { // poliza anulada o en vigor no bloqueada/anonimizada
                result = generateSetMap(result, offer.IntermediaryId__c, offer.AccountId);                
            }            
        }

        return result;
    }


    /**
     * Método que obtiene las ids de agrupación mediador de los mediadores de las pólizas recibidas <IntermediaryId, IntermediaryGroup__c>
     * 
     *
     * @author dmunoz
     * @date 05/03/2024 
     */
    public static Map<String, String> getIntermediaryGroupIdMap(Set<String> intermediariesOfferSet) {

        Map<String, String> result = new Map<String, String>();
        AccountsSelector accountSelector = new AccountsSelector();

        List<Account> intermediariesQueryList = accountSelector.findIntermediaryGroupByIntermediaries(intermediariesOfferSet);
       
        for (Account acc: intermediariesQueryList) {
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
     * @date 05/03/2024 
     */
    public static Map<String, List<String>> getIntermediariesUsers(Set<String> intermediariesSet, Map<String, String> mediadoresIdsYAgrupacionesIdMap) {
        Map<String, List<String>> result = new Map<String, List<String>>();

        // eliminio los nulos de intermediaryGroupsList para evitar enviar nulos a la query
        List<String> intermediaryGroupsNotNullList = removeNullFromList(mediadoresIdsYAgrupacionesIdMap.values());       
        
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
        result = addAGRUsers(result, intermediariesSet, mediadoresIdsYAgrupacionesIdMap, userAGRList);
           

        return result;
    }


    /**
     * Método que devuelve los mediadores y una lista de usuarios a los que crearemos un atm
     * @param offerAccountsTriggerByIntermediaryMap <IntermdiaryId, Set<AccountId>
     * @param intermediariesWithUsers <IntermediaryId, List<UserId>> usuarios a insertar atm para cada mediador
     *
     * @author dmunoz 
     * @date 05/03/2024
     */
    public static void newOfferInsertATMs(Map<String, Set<String>> offerAccountsTriggerByIntermediaryMap, Map<String, List<String>> intermediariesWithUsers) {

        List<AccountTeamMember> result = new List<AccountTeamMember>();
        List<AccountTeamMember> atms;

        // Generar los registros de atm para usuarios nominales relacionado por id de mediador
        for (String intermediaryId: offerAccountsTriggerByIntermediaryMap.keySet()) {
            for (String accountId: offerAccountsTriggerByIntermediaryMap.get(intermediaryId)) {
                atms = AccountTeamMemberUtil.createATMZRMRecordList(accountId, intermediariesWithUsers.get(intermediaryId));
                result.addAll(atms);
            }
        }

        // insertamos los atm
        if (!result.isEmpty()) {
            insert result;
        }
    }


    /**
     * Método que aañde los usuarios agr de otros mediadores de su agrupación 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    private static Map<String, List<String>> addAGRUsers(Map<String, List<String>> result, Set<String> intermediariesSet, Map<String, String> mediadoresIdsYAgrupacionesIdMap, List<User> userAGRList) {

        String intermediaryGroupId;
        for (String intermediaryId: intermediariesSet) {
            intermediaryGroupId = mediadoresIdsYAgrupacionesIdMap.get(intermediaryId);
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
     * Método que añade un valor a un Map<String, Set<String>>
     *
     * @author dmunoz
     * @date 05/03/2024 
     */
    private static Map<String, Set<String>> generateSetMap(Map<String, Set<String>> mapToInsert, String key, String valueToAdd) {
        Set<String> aux;
        if (mapToInsert.containsKey(key)) {
            aux = mapToInsert.get(key);
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        } else {
            aux = new Set<String>();
            aux.add(valueToAdd);
            mapToInsert.put(key, aux);
        }

        return mapToInsert;
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
    
}