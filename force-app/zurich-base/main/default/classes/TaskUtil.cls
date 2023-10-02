/**
 * @description       : Clase Util para el objeto Task
 * @author            : aberuete
 * @group             :
 * @last modified on  : 08-02-2023
 * @last modified by  : aberuete
 **/
public with sharing class TaskUtil
{
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
}