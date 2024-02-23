/**
 * Batch que se ejecuta de forma diaria y que se encarga de recalcular la visibilidad de las agrupaciones en caso que se haya producido un cambio.
 * 
 * @author nts (dmunoz)
 * @date 15/02/2024
 *
 */

global with sharing class Batch_RecalcVisibilityIntermediaryGroup implements Database.Batchable<sObject>, Schedulable {

    private static final String CLASS_NAME = 'Batch_RecalcVisibilityIntermediaryGroup';
    private static final string AGENTEVENTA_PROFILE = 'Agente Ventas';
    private static final string AGENTEVENTAAGR_PROFILE = 'Agente Ventas - AGR';

    
    /*********** Invocar Schedule Batch **************************************************************************/
    /**
     * Método para programar de forma sencilla al batch 
     * @param jobName: nombre del batch a ejecutar (opcional)
     * @param timeExpression: expresion CRON para programar el batch
     * @return String: job id
     * @author dmunoz
     * @date 15/02/2024
     */
    public static String createStandardSchedule(String jobName, String timeExpression) {
        jobName = setJobName(jobName);
        timeExpression = setTimeExpression(timeExpression);
        
        return System.schedule(jobName, timeExpression, new Batch_RecalcVisibilityIntermediaryGroup());
    }


    /*********** Métodos Schedulable **************************************************************************/
    /**
     * Método execute necesario por la interfaz Schedulable
     * @param sc: Contexto Schedulable
     * @return void
     * @author dmunoz
     * @date 15/02/2024
     */
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_RecalcVisibilityIntermediaryGroup(), 200);               
    }

    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de ofertas a las que hay que modificar la etapa y motivo de cierre
     * @param bc: batch context
     * @return List ofertas a modificar
     * @author dmunoz
     * @date 15/02/2024
     */
    global Database.QueryLocator start(Database.BatchableContext bc) { 
        return Database.getQueryLocator((new AccountsSelector()).findIntermediariesWithGroupChanges());        
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de Opportunity procedentes del método start
     * @return void
     * @author dmunoz
     * @date 15/02/2024
     */
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        try {

            // 1º Obtener los mediadores que no tienen agrupaciones ya que en caso que haya registros de este tipo hay que recalcular toda 
            List<Account> intermediariesWithNoGroup = getIntermediariesWithNoGroup(scope);
            System.debug('DMM 1 intermediariesWithNoGroup ' + intermediariesWithNoGroup);
            // 1º B Obtengo la lista de ids de mediadores baja
            List<String> intermediariesIdsWithNoGroupList = getIntermediariesIdsWithNoGroupList(intermediariesWithNoGroup);
            System.debug('DMM 1B intermediariesIdsWithNoGroupList ' + intermediariesIdsWithNoGroupList);

            // 2º Ordenar los datos para obtener la relación entre Agrupación y Mediadores <IntermediaryGroup, List<IntermediaryId>
            Set<String> intermediaryGroupsSet = getIntermediaryGroupsFromIntermediaries(scope);
            System.debug('DMM 2 intermediaryGroupsSet ' + intermediaryGroupsSet);       
            
            // 3º A partir de todas las agrupaciones a recalcular montamos el mapa de agrupaciones con todos sus mediadores <IntermediaryGroupId, List<IntermediaryId>>
            Map<String, List<String>> intermediaryGroupsWithIntermediaries = calculateIntermediaryGroupsWithIntermediaries(intermediaryGroupsSet, intermediariesWithNoGroup);
            System.debug('DMM 3 intermediaryGroupsWithIntermediaries ' + intermediaryGroupsWithIntermediaries);

            // 4º Consultamos los usuarios de las agrupaciones
            List<User> usersFromIntermediariesWithGroup = (new UsersSelector()).findZRMActiveUsersByIntermediaryGroupId(intermediaryGroupsWithIntermediaries.keySet());
            System.debug('DMM 4 usersFromIntermediariesWithGroup ' + usersFromIntermediariesWithGroup);
            
            // 5º Obtenemos los usuarios de los mediadores que no tienen agrupación
            List<User> usersFromIntermediariesWithNoGroup = (new UsersSelector()).findZRMActiveUsersByIntermediaryId(intermediariesIdsWithNoGroupList);     
            System.debug('DMM 5 usersFromIntermediariesWithNoGroup ' + usersFromIntermediariesWithNoGroup);

            // 6º Obtener la lista de usuarios de cada agrupación <IntermediaryId, List<User>>, en caso que un mediador pertenezca a una agrupación donde exista algún usuario AGR lo añadimos a la lista de usuarios para generar la visibilidad completa de estos usuarios
            Map<String, List<User>> intermediaryUserMap = getZRMActiveUsersByIntermediaryId(usersFromIntermediariesWithGroup, usersFromIntermediariesWithNoGroup, intermediaryGroupsWithIntermediaries);
            System.debug('DMM 6 intermediaryUserMap ' + intermediaryUserMap);

            // 7º Obtener polizas para cada mediador <IntermediaryId, List<PolicyHolder__c>>
            Map<String, Set<String>> intermediaryPolicies = getIntermediaryPolicies(intermediaryGroupsWithIntermediaries.keySet(), intermediariesIdsWithNoGroupList);
            System.debug('DMM 7 intermediaryPolicies ' + intermediaryPolicies);

            // 8º Eliminar atm, desactivar competencias y cuentas relacionadas
            List<AccountTeamMember> atmsDeleted = deleteATM(usersFromIntermediariesWithGroup, usersFromIntermediariesWithNoGroup);
            Set<String> intermediariesSet = getIntermediariesSet(intermediaryGroupsWithIntermediaries, intermediariesIdsWithNoGroupList);
            deactivateCompetitorAndAccountRelationships(intermediariesSet, atmsDeleted);

            // 9º Insertar atm, activar competencias y cuentas relacionadas        
            List<AccountTeamMember> atmsInserted = insertATM(intermediaryGroupsWithIntermediaries, intermediariesIdsWithNoGroupList, intermediaryPolicies, intermediaryUserMap);
            activateCompetitorAndAccountRelationships(intermediariesSet, atmsInserted);
                                 
            
        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }
    
    /**
     * Metodo finish del batch, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 15/02/2024
     */
    global void finish(Database.BatchableContext bc) {
        // nothing
    }


    /******************************************************************************************* Métodos auxiliares ************************************************************************************************/

    /**
     * En primer lugar recuperamos los registros de mediador que han perdido agrupación (bajas)
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024     
     */
    private List<Account> getIntermediariesWithNoGroup(List<Account> scope) {
        List<Account> result = new List<Account>();

        for (Account intermediary: scope) {
            if (intermediary.IntermediaryGroup__c == null) {
                result.add(intermediary);
            } 
        }

        return result;
    }

    /**
     * En primer lugar recuperamos los registros de mediador que han perdido agrupación (bajas)
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024     
     */
    private List<String> getIntermediariesIdsWithNoGroupList(List<Account> intermediariesWithNoGroup) {
        List<String> result = new List<String>();

        for (Account intermediary: intermediariesWithNoGroup) {            
            result.add(intermediary.Id);
            
        }

        return result;
    }

    /**
     * Obtenemos las agrupaciones de los mediadores que han sufrido alta o modificación, en caso de modificacion añado tambien la agrupación antigua ya que hay que recalcularla
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private Set<String> getIntermediaryGroupsFromIntermediaries(List<Account> scope) {
        Set<String> result = new Set<String>();
        
        for (Account intermediary: scope) {
            if (String.isNotEmpty(intermediary.IntermediaryGroup__c)) {                
                result.add(intermediary.IntermediaryGroup__c);                
            }

            // si viene de un cambio de agrupación tendrá informado el campo LastIntermediaryGroup__c, se ha de añadir también para recalcular la visibilidad de esa agrupación
            if (String.isNotEmpty(intermediary.LastIntermediaryGroup__c)) {
                result.add(intermediary.LastIntermediaryGroup__c);
            }
        }

        return result;
    }

    /**
     * Calculamos el mapa de agrupaciones y la lista de todos sus mediadores <IntermediaryGroupId, List<IntermediaryId>>
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private Map<String, List<String>> calculateIntermediaryGroupsWithIntermediaries(Set<String> intermediaryGroupsSet, List<Account> intermediariesWithNoGroupList) {
        Map<String, List<String>> result = new Map<String, List<String>>();

        // añado al conjunto todas las agrupaciones de los mediadores
        Set<String> intermediaryGroupsToQuery = new Set<String>();
        intermediaryGroupsToQuery.addAll(intermediaryGroupsSet);

        for (Account intermediaryWithNoGroup: intermediariesWithNoGroupList) {
            intermediaryGroupsToQuery.add(intermediaryWithNoGroup.LastIntermediaryGroup__c);
        }

        // consulto en bd los mediadores de las agrupaciones a recalcular para crear el mapa <IntermediaryGroupId, List<IntermediaryId>>
        List<Account> intermediariesQuery = (new AccountsSelector()).findAllIntermediarysFromIntermediaryGroups(intermediaryGroupsToQuery);

        List<String> aux;
        for (Account intermediary: intermediariesQuery) {
            if (result.containsKey(intermediary.IntermediaryGroup__c)) {
                aux = result.get(intermediary.IntermediaryGroup__c);
                aux.add(intermediary.Id);
                result.put(intermediary.IntermediaryGroup__c, aux);
            } else {
                aux = new List<String>();
                aux.add(intermediary.Id);
                result.put(intermediary.IntermediaryGroup__c, aux);
            }
        }

        return result;
    }


    /**
     * Obtenemos todos los usuarios de las agrupaciones <IntermediaryId, List<UserId>>
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private Map<String, List<User>> getZRMActiveUsersByIntermediaryId(List<User> usersFromIntermediariesWithGroup, List<User> usersFromIntermediariesWithNoGroup, Map<String, List<String>> intermediaryGroupsWithIntermediaries) {
        
        Map<String, List<User>> result = new Map<String, List<User>>();
        
        List<User> aux;
        for (User user: usersFromIntermediariesWithGroup) {
            if (result.containsKey(user.Contact.AccountId)) {
                aux = result.get(user.Contact.AccountId);
                aux.add(user);
                result.put(user.Contact.AccountId, aux);
            } else {
                aux = new List<User>();
                aux.add(user);
                result.put(user.Contact.AccountId, aux);
            }
        }    
        
        // añado los usuarios agr a los mediadores que corresponda para que tambien tengan visibilidad sobre los clientes que cada mediador ve
        result = getAGRUsersByIntermediaryGroup(result, intermediaryGroupsWithIntermediaries, usersFromIntermediariesWithGroup);
        
        for (User user: usersFromIntermediariesWithNoGroup) {
            if (result.containsKey(user.Contact.AccountId)) {
                aux = result.get(user.Contact.AccountId);
                aux.add(user);
                result.put(user.Contact.AccountId, aux);
            } else {
                aux = new List<User>();
                aux.add(user);
                result.put(user.Contact.AccountId, aux);
            }
        }       
        
        return result;
    }


    /**
     * Añadimos los usuarios agr a de una agrupacion a todos los mediadores
     * 
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private Map<String, List<User>> getAGRUsersByIntermediaryGroup(Map<String, List<User>> intermediaryUserMap, Map<String, List<String>> intermediaryGroupWithIntermediaries, List<User> usersFromIntermediariesWithGroup) {        

        List<String> intermediaryList;
        List<User> userList;
        for (User user: usersFromIntermediariesWithGroup) {
            if ('Agente Ventas - AGR'.equals(user.Profile.Name)) {
                // obtengo los mediadores de la agrupacion del usuario agr
                intermediaryList = intermediaryGroupWithIntermediaries.get(user.Contact.Account.IntermediaryGroup__c);
                // para cada mediador que existe en la agrupación que marca el usuario le añado el usuario
                for (String intermediaryId: intermediaryList) {                    
                    userList = intermediaryUserMap.get(intermediaryId);
                    if (userList != null) {
                        userList.add(user);
                        intermediaryUserMap.put(intermediaryId, userList);

                    } else {
                        userList = new List<User>();
                        userList.add(user);
                        intermediaryUserMap.put(intermediaryId, userList);
                    }
                   
                }
            }
        }

        return intermediaryUserMap;
    }

    /**
     * Eliminamos los registros de atm de los usuarios de las agrupaciones y los que no tienen agrupacion
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private List<AccountTeamMember> deleteATM(List<User> usersFromIntermediariesWithGroup, List<User> usersFromIntermediariesWithNoGroup) {
        AccountTeamMemberSelector selector = new AccountTeamMemberSelector();
        List<User> allUser = new List<User>();
        allUser.addAll(usersFromIntermediariesWithGroup);
        allUser.addAll(usersFromIntermediariesWithNoGroup);

        List<AccountTeamMember> atmsToDelete = selector.findZRMATMsByUser(allUser);

        System.debug('DMM 8 atmsToDelete ' + atmsToDelete);

        if (!atmsToDelete.isEmpty()) {
            delete atmsToDelete;
        }
        return atmsToDelete;
    }

    /**
     * Obtenemos todas las polizas en vigor y anuladas de cada agrupación para calcular los ATM <IntermediaryId, List<PolicyHolder>>
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private Map<String, Set<String>> getIntermediaryPolicies(Set<String> intermediaryGroupIdSet, List<String> intermediariesWithNoGroups) {
        Map<String, Set<String>> result = new Map<String, Set<String>>();
        PoliciesSelector selector = new PoliciesSelector();

        // Obtengo la lista de ids de mediadores sin agrupación
        Set<String> intermediaryIdsSet = new Set<String>();
        intermediaryIdsSet.addAll(intermediariesWithNoGroups);
        

        List<Policy__c> policiesQuery = selector.selectByIntermediaryGroupId(intermediaryGroupIdSet, intermediaryIdsSet);

        Set<String> aux;
        for (Policy__c policy: policiesQuery) {
            if (result.containsKey(policy.IntermediaryId__c)) {
                aux = result.get(policy.IntermediaryId__c);
                aux.add(policy.PolicyHolder__c);
                result.put(policy.IntermediaryId__c, aux);
            } else {
                aux = new Set<String>();
                aux.add(policy.PolicyHolder__c);
                result.put(policy.IntermediaryId__c, aux);
            }
        }

        return result;
    }

    /**
     * Generamos los registros de atm a para cada mediador de cada agrupación a partir de los clientes de póliza de cada mediador
     * 
     * @param intermediaryGroupWithIntermediaries <IntermediaryGroup, List<IntermediaryId>  
     * @param intermediariesWithNoGroup <IntermediaryId>
     * @param intermediaryPolicies <IntermediaryId, List<PolicyHolder__c>>
     * @param intermediaryUserMap <IntermediaryId, List<UserId>>
     * @param 
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private List<AccountTeamMember> insertATM(Map<String, List<String>> intermediaryGroupWithIntermediaries, List<String> intermediariesWithNoGroups, Map<String, Set<String>> intermediaryPolicies, Map<String, List<User>> intermediaryUserMap) {

        List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();

        // recorremos cada agrupacion
        for (String intermediaryGroupId: intermediaryGroupWithIntermediaries.keySet()) {
            atmsToInsert.addAll(generateATMs(intermediaryGroupWithIntermediaries.get(intermediaryGroupId), intermediaryPolicies, intermediaryUserMap));
        }

        // recorremos los mediadores sin agrupacion
        atmsToInsert.addAll(generateATMs(intermediariesWithNoGroups, intermediaryPolicies, intermediaryUserMap));
        System.debug('DMM 9 ' + atmsToInsert);
        
        if (!atmsToInsert.isEmpty()) {
            insert atmsToInsert;
        }
        
        return atmsToInsert;
    }

    /**
     * Generamos los registros de atm a para cada mediador
     * 
     * @param intermediaryGroupWithIntermediaries <IntermediaryGroup, List<IntermediaryId>  
     * @param intermediariesWithNoGroup <IntermediaryId>
     * @param intermediaryPolicies <IntermediaryId, List<PolicyHolder__c>>
     * @param intermediaryUserMap <IntermediaryId, List<UserId>>
     * @param 
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private List<AccountTeamMember> generateATMs(List<String> intermediariesList, Map<String, Set<String>> intermediaryPolicies, Map<String, List<User>> intermediaryUserMap) {
        
        List<AccountTeamMember> result = new List<AccountTeamMember>();
        List<AccountTeamMember> atmsGenerated = new List<AccountTeamMember>();

        for (String intermediaryId: intermediariesList) {
            
            // recorremos cada cliente de cada poliza ordenados por mediador
            if (intermediaryPolicies.containsKey(intermediaryId)) {                
                for (String policyHolder: intermediaryPolicies.get(intermediaryId)) {
                    atmsGenerated = AccountTeamMemberUtil.createATMZRMRecordList(policyHolder, intermediaryUserMap.get(intermediaryId));
                    
                    result.addAll(atmsGenerated);
                }
            }
        }

        return result;
    }

    /**
     * Desactivar los registros de competencia y cuentas relacionadas para los clientes que ve cada mediador al eliminar los atm
     * 
     * @param intermediaryGroupWithIntermediaries <IntermediaryGroup, List<IntermediaryId>  
     * @param intermediariesWithNoGroup <IntermediaryId>
     * @param 
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private void deactivateCompetitorAndAccountRelationships(Set<String> intermediariesSet, List<AccountTeamMember> atmsList) {
        // Activar posibles registros de competencia para los clientes y mediadores
        List<String> clientIds = getClientsIds(atmsList);
        CompetitorUtil.recalculateVisibilityCompetitorDenyVisibility(clientIds, intermediariesSet);

        // Activar posibles registros de AccountRelationship__c
        AccountRelationshipUtil.recalculateVisibilityDenyAccountRelationshipSetVisibility(clientIds, intermediariesSet);
    }



    /**
     * Activar los registros de competencia y cuentas relacionadas para los clientes que ve cada mediador
     * 
     * @param intermediaryGroupWithIntermediaries <IntermediaryGroup, List<IntermediaryId>  
     * @param intermediariesWithNoGroup <IntermediaryId>
     * @param 
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private void activateCompetitorAndAccountRelationships(Set<String> intermediariesSet, List<AccountTeamMember> atmsInsertedList) {
        // Activar posibles registros de competencia para los clientes y mediadores
        List<String> clientIds = getClientsIds(atmsInsertedList);        
        CompetitorUtil.recalculateVisibilityCompetitorSetVisibility(clientIds, intermediariesSet);

        // Activar posibles registros de AccountRelationship__c
        AccountRelationshipUtil.recalculateVisibilityAccountRelationshipSetVisibility(clientIds, intermediariesSet);
    }

    /**
     * Obtengo los accountid de los registros de atm insertados ya que estos han gando visibilidad
     * 
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private List<String> getClientsIds(List<AccountTeamMember> atmsList) {
        List<String> result = new List<String>();

        for (AccountTeamMember atm: atmsList) {
            result.add(atm.AccountId);
        }

        return result;
    }

    /**
     * Añado todos los mediadores a los que se ha calculado atm
     * 
     * 
     * @author nts (dmunoz)
     * @date 15/02/2024
     */
    private Set<String> getIntermediariesSet(Map<String, List<String>> intermediaryGroupWithIntermediaries, List<String> intermediariesWithNoGroups) {
        Set<String> result = new Set<String>();

        // añado los mediadores de las agrupaciones
        for (String intermediaryGroup: intermediaryGroupWithIntermediaries.keySet()) {
            result.addAll(intermediaryGroupWithIntermediaries.get(intermediaryGroup));
        }

        // añado los mediadores sin agrupacion
        result.addAll(intermediariesWithNoGroups);

        return result;
    }


    /******************************************************************************************* Métodos auxiliares Schedule****************************************************************************************/
    /**
     * Dar un nombre por defecto al Job programado en caso de no informar este valor
     * @param jobName: Nombre del batch programado
     * @return String
     * @author dmunoz
     * @date 06/10/2023
     */
    private static String setJobName(String jobName) {
        if (String.isEmpty(jobName)){
            jobName = 'Batch_RecalcVisibilityIntermediaryGroup';
        } 
        return jobName; 
    }

    /**
     * Dar una expresión CRON por defecto al Job programado en caso de no informar este valor
     * @param timeExpression: Expresión CRON a utilizar
     * @return String
     * @author dmunoz
     * @date 06/10/2023
     */
    private static String setTimeExpression(String timeExpression) {
        if (String.isEmpty(timeExpression)){
            timeExpression = '0 0 5 * * ?' ; 
        } 
        return timeExpression; 
    }
}