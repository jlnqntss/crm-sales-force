/**
 * @description       : Clase Util para el objeto FollowUp__c
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 03-06-2023
 * @last modified by  : aberuete
**/

global with sharing class FollowUpsUtil 
{

    /**
     * Método que actualiza los seguimientos para indicar que han sido procesados. 
     * 
     * @author aberuete
     * @date 03/03/2023
     * 
     * @param {List<FollowUp__c> listFollowUp} Lista de seguimientos a actualizar 
     * @return {Boolean errorIsTrue } Devuelve una variable que indica si ha habido algún error al actualizar los seguimientos
     */
    public static Boolean updateFollowUpsToProcessedTrue (List<FollowUp__c> listFollowUp)
    {
        List<String> msgErrores = new List<String>();
        Boolean errorIsTrue = false;
        List<FollowUp__c> listFollowUpToUpdate = new List<FollowUp__c>();
        for (FollowUp__c followUp : listFollowUp )
        {
            followUp.Processed__c = true;
            listFollowUpToUpdate.add(followUp);
        }

        try
        {
            Database.SaveResult [] srList = Database.update(listFollowUp, false);
            for (Database.SaveResult sr: srList )
            {
                if(!sr.isSuccess())
                {
                    for (Database.Error err :sr.getErrors())
                    {
                        msgErrores.add(err.getStatusCode() + ': ' + err.getMessage());
                    }
                    errorIsTrue = true;
                }
            }   
            if (!msgErrores.isEmpty())
            {
                ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error actualizando seguimientos',FollowUpsUtil.class.getName(),(String.join(msgErrores,'\n')));
            } 
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, FollowUpsUtil.class.getName());
        }
        return errorIsTrue;
    }

    /**
     * Método que devuelve una lista de ids de usuarios única a notificar. 
     * Los usuarios que se van a notificar son aquellos que son miembros del equipo de cuentas de las cuentas asociados 
     * a los seguimientos cuyo rol sea el indicado por el seguimiento a notificar. Además se tendrá en cuenta que los usuarios no han sido notificados anteriormente 
     * o bien no hayan sido notificados del tipo de seguimiento a notificar.
     * 
     * @author aberuete
     * @date 03/03/2023
     * 
     * @param {List<FollowUp__c> listFollowUp} Lista de seguimientos
     * @param {String type} Tipo de seguimientos a notificar
     * @param {Set<Id> idsFromUser} Conjunto de ids único 
     * @return {Set<Id> idsFromUser } Devuelve un conjunto de ids unico de usuarios a notificar
     */
    public static Set<Id> getUserIdToNotify (List<FollowUp__c> listFollowUp, String type, Set<Id> idsFromUser)
    {
        Set<String> rolToNotify = new Set<String>();
        Set<Id> accountId = new Set <Id>();

        for (FollowUp__c followUp : listFollowUp )
        {
            string [] rolesSplits = followUp.Notify__c.split(';');
            for (String rol :rolesSplits )
            {
                rolToNotify.add(rol);
            }
            accountId.add(followUp.Account__c);
        }

        List<AccountTeamMember> atmsList = (new AccountTeamMemberSelector()).findUsersByRoleAndAccountIdFields(rolToNotify, accountId, type);
        for (AccountTeamMember atm : atmsList)
        {
            idsFromUser.add(atm.UserId);
        }
        
        return idsFromUser;
    }

    /**
     * Método que actualiza los usuarios para indicar que han sido notificados de la carga de seguimientos.
     * 
     * @author aberuete
     * @date 03/03/2023
     * 
     * @param {Set<Id> idsFromUser} Lista de ids de usuarios a actualizar 
     * @param {String typeOfFollowUp} Tipo de seguimiento que se va a notificar 
     */
    public static void updateUsersToNotify (Set<Id> idsFromUser, String typeOfFollowUp )
    {
        List<User> userslistToUpdate = new List<User>();

        for (User userToUpdate : new UsersSelector().findById(idsFromUser))
        {
            if (!userToUpdate.Notified__c)
            {
                userToUpdate.NotifyDate__c = date.today();
                userToUpdate.NotifyType__c = typeOfFollowUp;
            }
            else 
            {
                userToUpdate.NotifyType__c = userToUpdate.NotifyType__c + ';'+ typeOfFollowUp;
            }
            userToUpdate.TypeToNotify__c = typeOfFollowUp;
            userslistToUpdate.add(userToUpdate);
        }

        List<String> msgErrores = new List<String>();
        try
        {
            Database.SaveResult [] srList = Database.update(userslistToUpdate, false);
            for (Database.SaveResult sr: srList )
            {
                if(!sr.isSuccess())
                {
                    for (Database.Error err :sr.getErrors())
                    {
                        msgErrores.add(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }   
            if (!msgErrores.isEmpty())
            {
                ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR,'Se ha producido un error actualizando usuarios', FollowUpsUtil.class.getName(),(String.join(msgErrores,'\n')));
            } 
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, FollowUpsUtil.class.getName());
        } 
    }
}