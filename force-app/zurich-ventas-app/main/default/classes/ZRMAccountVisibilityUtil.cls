/**
 * Clase con los métodos de utilidad de visibilidad ZRM para clientes
 *
 * @author dmunoz
 * @date 05/03/2024 
 */
public with sharing class ZRMAccountVisibilityUtil {   

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
            if (user.Profile.Name == ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR) {
                userAGRList.add(user);
            }
        }

        // Recorremos los mediadores y añadimos los usuarios agr
        result = addAGRUsers(result, intermediariesSet, mediadoresIdsYAgrupacionesIdMap, userAGRList);
           

        return result;
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