/**
 * @description       : Batch que recalcula la visibilidad de tareas y eventos de los mediadores ZRM
 * @author            : nts - dmunoz
 * @last modified on  : 29/09/2023
**/
global with sharing class Batch_IntermediaryVisibilityAccActivites implements Database.Batchable<sObject> {
    
    private static final String CLASS_NAME = 'Batch_IntermediaryVisibilityAccActivites';
    private Set<String> accountIds;

    public Batch_IntermediaryVisibilityAccActivites(Set<String> accountIds) {
        this.accountIds = accountIds;
    }


    /*********** Métodos Batch **************************************************************************/
    /**
     * Metodo start del batch, devuelve la lista de elementos a los que se recalculará la visibilidad
     * @param bc: batch context
     * @return Lista de tareas a recalcular
     * @author dmunoz
     * @date 29/09/2023
     */
    global Database.QueryLocator start(Database.BatchableContext bc) { 

        if (accountIds != null && !accountIds.isEmpty()) {
            return Database.getQueryLocator(new AccountsSelector().findZRMBlockedAccountWithActivitiesFromIds(accountIds)); 
        } else {
            return null;
        }
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de account procedentes del método start
     * @return void
     * @author dmunoz
     * @date 29/09/2023
     */
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        try {    
            // obtener el default user de zrm
            Id defaultUserId = obtainDefaultUser();  
            
            Map<String, Map<Id, sObject>> activitiesMap = getActivitiesFromAccount(scope); // keys Events, Tasks

            List<Task> updatedTaskVisibilityList = updateTasksVisibility(activitiesMap, defaultUserId);
            List<Event> updatedEventVisibilityList = updateEventsVisibility(activitiesMap, defaultUserId);

            update updatedTaskVisibilityList;
            update updatedEventVisibilityList;

        } catch (Exception e) {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    /**
     * Metodo finish del batch, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 29/09/2023
     */
    global void finish(Database.BatchableContext bc) {
        // nothing
    }


    /*********** Métodos Auxiliares **************************************************************************/
    /**
     * Obtener el mapa de tareas y eventos de los clientes de scope
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 02/10/2023
     */
    private Map<String, Map<Id, sObject>> getActivitiesFromAccount(List<Account> scope) {
        
        Map<String, Map<Id, sObject>> result = new Map<String, Map<Id, sObject>>();
        Map<Id, sObject> tasksMap = new Map<Id, sObject>();
        Map<Id, sObject> eventsMap = new Map<Id, sObject>();

        
        for (Account acc: scope) {
            for (Task t: acc.Tasks) {
                tasksMap.put(t.Id, t);
            }

            for (Task t: acc.PersonTasks) {
                tasksMap.put(t.Id, t);
            }

            for (Event e: acc.Events) {
                eventsMap.put(e.Id, e);
            }

            for (Event e: acc.PersonEvents) {
                eventsMap.put(e.Id, e);
            }
        }
        
        result.put('Tasks', tasksMap);
        result.put('Events', eventsMap);

        return result;
    }
    
    /**
     * Actualiza el owner de las tareas recuperadas con la consulta de bd con el valor del usuario que indica la metadata, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 29/09/2023
     */
    private List<Task> updateTasksVisibility(Map<String, Map<Id, sObject>> activitiesMap, Id defaultUserId) {
        
        List<Task> result = new List<Task>();
        List<Task> taskToUpdate = activitiesMap.get('Tasks').values();        

        for (Task t: taskToUpdate) {
            t.PriorIntermediaryOwner__c = t.OwnerId;
            t.OwnerId = defaultUserId;
            
            result.add(t);
        }
        return result;
    }


    /**
     * Actualiza el owner de las tareas recuperadas con la consulta de bd con el valor del usuario que indica la metadata, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 29/09/2023
     */
    private List<Event> updateEventsVisibility(Map<String, Map<Id, sObject>> activitiesMap, Id defaultUserId) {
        
        List<Event> result = new List<Event>();
        List<Event> eventsToUpdate = activitiesMap.get('Events').values();        

        for (Event e: eventsToUpdate) {
            e.PriorIntermediaryOwner__c = e.OwnerId;
            e.OwnerId = defaultUserId;

            result.add(e);
        }
        return result;
    }


    /**
     * @description Método para recuperar los Ids de los usuarios configurados para ser los
     *              Ids por defecto
     * @author      dmunoz
     * @date        29/09/2023
     */
    private Id obtainDefaultUser() {
        Id result = null;
        String aliasDeaultUserOnError = Cross_Selling__c.getinstance().DefaultUser__c;

        List<User> defaultUsers = (new UsersSelector()).findUsersByAlias(new List<String>{aliasDeaultUserOnError});

        if (!defaultUsers.isEmpty()) {
            result = defaultUsers.get(0).Id;
        }

        return result;
    }
}