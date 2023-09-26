/**
 * @description       : Clase Util para el objeto Task
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 08-02-2023
 * @last modified by  : aberuete
**/
public with sharing class TaskUtil 
{
    private static Map<Id, CampaignMember> taskIdCampaignMemberMap = new Map<Id, CampaignMember>();
    private static Map<String, List<CampaignMember>> campaignMemberDML = new Map<String, List<CampaignMember>>();

    /**
     * BULK BEFORE
     * Recupera los datos a ser utilizados en el before trigger
     * 
     * @author fpalomo
     * @date 11/09/2023
     * 
     * @param List<Task> newList : Lista de tareas a actualizar
     */
    public static void mapBeforeData(List<Task> newList)
    {
        if(newList == null)
        {
            return;
        }
        
        Set<Id> campaignMembersIds = new Set<Id>();
        Map<Id, Id> taskIdCampaignMemberIdMap = new Map<Id, Id>();
        for(Task task : newList)
        {
            if(String.isNotBlank(task.CampaignMemberID__c))
            {
                taskIdCampaignMemberIdMap.put(task.CampaignMemberID__c, task.Id);
                campaignMembersIds.add(task.CampaignMemberID__c);
            }
        }
        
        // Add here all fields from relations that will be used during the trigger execution, these fields are not added by the loop below
        Set<String> cmFields = new Set<String>{ 'Campaign.MaxCallRetries__c' };
        
        // All fields from the object are aded to allow the clone() used in retryCallNotReachedCampaignMember() to make an exact copy of the CampaignMember
        for (Schema.SObjectField sObjectField : Schema.getGlobalDescribe().get('CampaignMember').getDescribe().fields.getMap().values())
        {
             cmFields.add(sObjectField.getDescribe().getName());
        }
        
        List<CampaignMember> campaignMembers = new CampaignMembersSelector(cmFields).selectById(campaignMembersIds);
        for(CampaignMember campaignMember : campaignMembers)
        {
            taskIdCampaignMemberMap.put(taskIdCampaignMemberIdMap.get(campaignMember.Id), campaignMember);
        }

    }

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
     * Borra y reinserta los miembros de campaña que no pueden contactarse y aumenta el contador de reintentos de rellamada
     * 
     * @author fpalomo
     * @date 11/09/2023
     * 
     * @param List<Task> newList : Lista de tareas a actualizar
     */
    public static void retryCallNotReachedCampaignMember(List<Task> newList)
    {
        campaignMemberDML.put('delete', new List<CampaignMember>());
        campaignMemberDML.put('insert', new List<CampaignMember>());

        for(Task newTask : newList)
        {
            CampaignMember cm = taskIdCampaignMemberMap.get(newTask.Id);
            
            if(cm == null || String.isBlank(cm.CampaignId) || cm.Campaign.MaxCallRetries__c == null)
            {
                return;
            }
            
            if(cm.Campaign.MaxCallRetries__c > cm.CallRetries__c)
            {
                CampaignMember cmClone = cm.clone(false, true, false, true);
                
                campaignMemberDML.get('delete').add(cm);
                campaignMemberDML.get('insert').add(cmClone);
            }
            
        }
    }

    /**
     * Ejecuta las operaciones DML para la clase TaskUtil
     * 
     * @author fpalomo
     * @date 11/09/2023
     * 
     * @param List<Task> newList : Lista de tareas a actualizar
     */
    public static void executeCampaignMembersDML()
    {
        if(campaignMemberDML.containsKey('delete') && !campaignMemberDML.get('delete').isEmpty())
        {
            delete campaignMemberDML.get('delete');
        }

        if(campaignMemberDML.containsKey('insert') && !campaignMemberDML.get('insert').isEmpty())
        {
            insert campaignMemberDML.get('insert');
        }
    }
}