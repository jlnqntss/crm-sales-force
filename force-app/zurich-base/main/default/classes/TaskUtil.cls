/**
 * @description       : Clase Util para el objeto Task
 * @author            : aberuete
 * @group             :
 * @last modified on  : 08-02-2023
 * @last modified by  : aberuete
 **/
public with sharing class TaskUtil
{

    @testvisible
    private static final Id uspRecordTypeId = CaseUtil.RT_ID_USPINQUIRY;
    
    /**
     * Método que marca la tarea para que sea pública para los usuarios de la comunidad
     * en caso de que el owner sea un usuario de la comunidad de ocs
     *
     * @author aberuete
     * @date 01/08/2023
     *
     * @param List<Task> newList : Lista de tareas a actualizar
     */
    public static void markPublicWhenOwnerUserCommunity(List<Task> newList)
    {
        Set<Id> ownerTaskset = new Set<Id>();

        for (Task task : newList)
        {
            ownerTaskset.add (task.OwnerId);
        }

        List<User> infoByUser = new UsersSelector().findById(ownerTaskset);
        Map<Id,User> mapIdByUser = new Map<Id,User> (infoByUser);

        for (Task taskToUpdate : newList )
        {
            User ownerTask = mapIdByUser.get(taskToUpdate.OwnerId);

            if ( ownerTask != null && ownerTask.Profile.Name != null && !String.isBlank(ownerTask.Profile.Name) && ownerTask.Profile.name == 'OCS Community User' && taskToUpdate.IsVisibleInSelfService != true )
            {
                taskToUpdate.IsVisibleInSelfService = true;
            }
        }
    }

    /**
     * Método que cierra las tareas abiertas relacionadas con una oportunidad para ZRM
     *
     * @author aberuete
     * @date 01/08/2023
     *
     * @param List<Task> newList : Lista de tareas a actualizar
     */
    public static List<Task> completeTaskByWhatId(Set<Id> opportuniesList) {

        List<Task> result = new List<Task>();

        if (opportuniesList != null && !opportuniesList.isEmpty()) {
            result = ActivitySelector.selectOpenTasksByWhatId(opportuniesList);

            for (Task t: result) {
                t.Status = 'Cerrada';
            }
        }

        return result;
    }


    /**
     * Método que informa en el caso el Id Genesys 
     *
     * @author LRODRIGUEZ
     * @date 14/05/2024
     *
     * @param List<Task> newList : Lista de tareas a actualizar
     */
    public static void checkIdGenesys(List<Task> newList) {


        Set<String> taskId = new Set<String>();
        Map<Id, String> mapaGenesys = new Map<Id, String>();


        for(Task t:newList)
        {
            if(t.CallObject!=null)
            {
                taskId.add(t.WhatId); 
                mapaGenesys.put(t.WhatId,t.CallObject);
            }
        }

        List<Case> casesToUpdate = new CasesSelector().findByIdControlCC(taskId);

        for (Case c:casesToUpdate)
        {
            if(c.RecordTypeId==uspRecordTypeId)
            c.GenesysID__c=mapaGenesys.get(c.Id);
        }

        update casesToUpdate;

        
    }
}