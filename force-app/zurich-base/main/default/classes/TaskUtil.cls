/**
 * @description       : Clase Util para el objeto Task
 * @author            : aberuete
 * @group             :
 * @last modified on  : 08-02-2023
 * @last modified by  : aberuete
 **/
public with sharing class TaskUtil
{

    public static final String STATUS_ASIGNADA = 'Asignada';
    public static final String STATUS_CERRADA = 'Cerrada';
    public static final String TYPE_ESCALADO = 'Scaled Case';

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
     * Para aquellas tareas de escalado que se cierran y estan asociadas a casos de ZDA, no se
     * debe permitir el cierre si no hay nada informado en el campo de respuesta (Response__c)
     *
     * @author mario.navarro@seidor.com
     * @date 16/05/2024
     * @param updatedTasks lista de los tareas actualizadas
     * @param oldMap mapa de las tareas antes de la actualización
     */
    public static void setErrorIfClosedAndNoResponseZda(List<Task> updatedTasks, Map<Id,Task> oldMap)
    {
        //Primero obtenemos los casos con los que estan relacionados (para sacar el recordtype
        //del caso no podemos hacerlo a traves de tarea.What.RecordTypeId porque no llega)
        Set<String> relatedIds = new Set<String>();
        for (Task updatedTask : updatedTasks)
        {
            if (updatedTask.WhatId != null)
            {
                relatedIds.add(updatedTask.WhatId.toString());
            }
        }
        List<Case> relatedCases = new CasesSelector().findById(relatedIds, true);

        if (relatedCases.isEmpty())
        {
            //nada que revisar, al no tener casos relacionados
            return;
        }

        Map<Id, Case> casesById = (Map<Id, Case>) CollectionUtil.hashList( relatedCases, Case.fields.Id.getDescribe().getName() );
        Case relatedCase;
        for (Task updatedTask : updatedTasks)
        {
            relatedCase = casesById.get(updatedTask.WhatId);
            if (relatedCase != null && relatedCase.RecordTypeId == CaseUtil.RT_ID_ZDA &&
                isScaledTaskAndClosed(updatedTask, oldMap.get(updatedTask.Id)) &&
                String.isBlank(updatedTask.Response__c))
            {
                //se agrega un error al campo Response__c si esta vacio
                updatedTask.addError(Task.fields.Response__c.getDescribe().getName(), Label.ZDANotAllowedCloseScaledWithoutResponse);
            }
        }
    }

    /**
     * Comprueba es si una tarea de escalado y se ha actualizado para cerrarse
     *
     * @author mario.navarro@seidor.com
     * @date 16/05/2024
     * @param updatedTask tarea actualizada
     * @param oldTask tarea antes de la actualizacion
     * @return true si se ha cerrado; false en caso contrario
     */
    private static Boolean isScaledTaskAndClosed(Task updatedTask, Task oldTask)
    {
        return updatedTask.Status != oldTask.Status && updatedTask.Status == STATUS_CERRADA && updatedTask.Type == TYPE_ESCALADO;
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


        for(Task newEmail:newList)
        {
            if(newEmail.CallObject!=null)
            {
                taskId.add(newEmail.WhatId); 
                mapaGenesys.put(newEmail.WhatId,newEmail.CallObject);
            }
        }

        List<Case> casesToUpdate = new CasesSelector().findByIdControlCC(taskId);

        for (Case relatedCase:casesToUpdate)
        {
            if(relatedCase.RecordTypeId==uspRecordTypeId)
            relatedCase.GenesysID__c=mapaGenesys.get(relatedCase.Id);
        }

        update casesToUpdate;

        
    }
}