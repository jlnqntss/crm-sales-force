/**
 * @description       : Batch que recalcula la visibilidad de tareas de los mediadores ZRM
 * @author            : nts - dmunoz
 * @last modified on  : 29/09/2023
**/
global with sharing class Batch_IntermediaryVisibilityRecalcTask implements Database.Batchable<sObject>{

    private static final String CLASS_NAME = 'Batch_IntermediaryVisibilityRecalcTask';
    private Set<String> accountIds;

    public Batch_IntermediaryVisibilityRecalcTask(Set<String> accountIds) {
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
    global List<Task> start(Database.BatchableContext bc) { 

        if (accountIds != null && !accountIds.isEmpty()) {
            return (new ActivitySelector()).findZRMTaskAssignedToAccountIds(accountIds);
        } else {
            return new List<Task> (); 
        }
    }


    /**
     * Metodo execute del batch, 
     * @param bc: batch context
     * @param scope lista de Offers procedentes del método start
     * @return void
     * @author dmunoz
     * @date 29/09/2023
     */
    global void execute(Database.BatchableContext bc, List<Task> scope) {
        try {            
            List<Task> updatedTaskVisibilityList = updateTaskVisibility(scope);

            update updatedTaskVisibilityList;
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
     * Actualiza el owner de las tareas recuperadas con la consulta de bd con el valor del usuario que indica la metadata, 
     * @param bc: batch context
     * @return void
     * @author dmunoz
     * @date 29/09/2023
     */
    private List<Task> updateTaskVisibility(List<Task> scope) {

        // obtener el default user de zrm
        Id defaultUserId = obtainDefaultUser();

        for (Task t: scope) {
            t.PriorIntermediaryOwner__c = t.OwnerId;
            t.OwnerId = defaultUserId;
        }
        return scope;
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