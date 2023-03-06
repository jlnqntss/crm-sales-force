/**
 * @description       : Batch llamado por el flow SDM After Insert Seguimientos para eliminar seguimientos 
 *                      creados antes del día de hoy y para cierto tipo
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-05-2023
 * @last modified by  : aberuete
**/

global with sharing class Batch_DeleteFollowUps implements Database.Batchable<sObject>,Database.Stateful
{
    global string type;
    public static Boolean errorIsTrue = false;

    global Batch_DeleteFollowUps ()
    {

    }

    /**
    * @description : Constructor del batch 
    * @param String type : tipo de seguimiento a eliminar
    * @author aberuete 
    **/
    global Batch_DeleteFollowUps (String type)
    {
        if (!String.isBlank(type))
        {
            this.type = type;
        }
    }

    /**
    * @description : Obtiene la query para eliminar los seguimientos
    * @author aberuete 
    **/
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        String query = new FollowUpSelector().findByTypeAndCreatedDateLessThanToday(type);
        return Database.getQueryLocator(query);
    }

    /**
    * @description : Elimina los seguimientos y en caso de error escribe un log 
    * @author aberuete 
    **/
    global void execute(Database.BatchableContext bc, List<sObject> scope)
    {
        try
        {
            List<String> msgErrores = new List<String>();
            if ( scope != null && !scope.isEmpty() )
            {
                Database.DeleteResult [] drList = Database.delete(scope, false);
                for (Database.DeleteResult dr:drList )
                {
                    if(!dr.isSuccess())
                    {
                        for (Database.Error err :dr.getErrors())
                        {
                            msgErrores.add(err.getStatusCode() + ': ' + err.getMessage());
                        }
                        errorIsTrue = true;
                    }
                }   
                if (!msgErrores.isEmpty())
                {
                    ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error borrando seguimientos',Batch_DeleteFollowUps.class.getName(),(String.join(msgErrores,'\n')));
                } 
                
            }
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, Batch_DeleteFollowUps.class.getName());
        }
    }

    /**
    * @description : Comprueba si quedan seguimientos a eliminar y en caso de que queden vuelve a lanzar el batch para eliminar los seguimientos restantes
    * @author aberuete 
    **/
    global void finish(Database.BatchableContext bc)
    {
        Integer numToDelete = new FollowUpSelector().countByTypeAndCreatedDateLessThanToday(type);

        if (numToDelete !=0 && !errorIsTrue )
        {
            Batch_DeleteFollowUps batchDeleteFollowUps = new Batch_DeleteFollowUps(type);
            database.executeBatch(batchDeleteFollowUps, 200);
        }

    }
}