/**
 * @description       : Batch llamado por el trigger after insert FollowUp__c para actualizar los seguimientos.
 *                      Una vez que están procesados, se actualizan los usuarios a notificar y se llama al batch
 *                      que elimina los seguimientos anteriores del tipo de seguimiento que se ha insertado.
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-06-2023
 * @last modified by  : aberuete
**/
global with sharing class Batch_ProcessFollowUps implements Database.Batchable<sObject>,Database.Stateful
{
    global String type;
    global  Set<Id> idsFromUser = new Set<Id>();
    public static Boolean errorIsTrue = false;

     /**
    * @description : Constructor del batch 
    * @param String type : tipo de seguimiento que se inserta
    * @author aberuete 
    **/
    global Batch_ProcessFollowUps(String type)
    {
        if (!String.isBlank(type))
        {
            this.type = type;
        }
    }

     /**
    * @description : Obtiene la query para actualizar los seguimientos
    * @author aberuete 
    **/
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        
        String query = new FollowUpSelector().findByTypeCreatedDateTodayAndProccessed(type,false);
        return Database.getQueryLocator(query);
    }

    /**
    * @description : Actualiza los seguimientos para indicar que se han procesado y obtiene los ids de los usuarios a actualizar
    * @author aberuete 
    **/
    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        if ( scope != null && !scope.isEmpty() )
        {
            List<FollowUp__c> listFollowUp = (List<FollowUp__c>) scope;
            errorIsTrue = FollowUpsUtil.updateFollowUpsToProcessedTrue (listFollowUp);
            idsFromUser = FollowUpsUtil.getUserIdToNotify (listFollowUp, type, idsFromUser);   
        }
    }

    /**
    * @description : Comprueba si quedan seguimientos a actualizar y en caso de que queden vuelve a lanzar el batch para actualizar los seguimientos restantes.
                    En caso contrario, actualiza los usuarios a notificar y lanza el batch de eliminar los seguimientos 
                    creados antes del día de hoy y del tipo de seguimiento que se ha insertado.
    * @author aberuete 
    **/
    global void finish(Database.BatchableContext bc)
    {

        Integer numToProcessed = new FollowUpSelector().countByTypeCreatedDateTodayAndProcessed(type, false);

        if (numToProcessed !=0 && !errorIsTrue )
        {
            Batch_ProcessFollowUps batchProcessFollowUps = new Batch_ProcessFollowUps(type);
            database.executeBatch(batchProcessFollowUps, 200);
        }
        else if (numToProcessed == 0)
        {
            FollowUpsUtil.updateUsersToNotify(idsFromUser, type);
            database.executeBatch(new Batch_DeleteFollowUps(type), 200);
        }

    }
}