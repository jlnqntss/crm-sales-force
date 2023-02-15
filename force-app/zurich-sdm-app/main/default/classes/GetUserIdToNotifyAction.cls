/**
 * @description       : Esta acción es llamada desde un flow para obtener los ids de los usuarios
 *                      a los que hay que notificar cuando se realiza una carga de seguimientos
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 02-14-2023
 * @last modified by  : aberuete
**/
public with sharing class GetUserIdToNotifyAction 
{
    /*
     * Método que devuelve una lista de los id de usuario que hay que notificar. 
     * Además actualiza los usuarios que se vayan a notificar, indicando la fecha de notificación 
     * y tipo de seguimiento del que se va a notificar
     * @author aberuete
     * @date 14/02/2023
     * @param List<FollowUp__c> listFollowUps Seguimientos recibidos desde el flow
     * @return List<List<Id>> Lista de ids que recibe el flow
     */
    @InvocableMethod
    (  
        label='Get User Id To Notify' 
        description='Returns a list of user ids to notify'
    )
    public static List<List<Id>> getUserIdToNotify(List<FollowUp__c> listFollowUps) 
    {
        List<List<Id>> listToReturn = new List<List<Id>>();
        Set<String> rolToNotify = new Set<String>();
        Set<Id> accountId = new Set <Id>();
        String typeOfFollowUp = null;
        //Set<String> types = new Set<String>();
        for (FollowUp__c followUp : listFollowUps )
        {
            List<Id> listOfIds = new List<Id>();
            listToReturn.add(listOfIds);
            string [] rolesSplits = followUp.Notify__c.split(';');
            for (String rol :rolesSplits )
            {
                rolToNotify.add(rol);
            }
            accountId.add(followUp.Account__c);
            //types.add(followUp.Type__c);
            if (typeOfFollowUp == null)
            {
                typeOfFollowUp = followUp.Type__c;
            }
        }

        List<AccountTeamMember> atmsList = (new AccountTeamMemberSelector()).findUsersByRoleAndAccountIdFields(rolToNotify, accountId, typeOfFollowUp);
        System.debug ('query atms'+ atmsList);
        Set<Id> idsFromUser = new Set<Id>();
        for (AccountTeamMember atm : atmsList)
        {
            idsFromUser.add(atm.UserId);
        }
        System.debug ('ids from user 42 '+idsFromUser );
        
        //String type = new List<String>(types)[0];

        // Actualizamos los usuarios
        if (!idsFromUser.isEmpty())
        {
            updateUsersToNotify (idsFromUser,typeOfFollowUp);
            listToReturn[0] = new List<Id>(idsFromUser);
        }

        return listToReturn;
    }

    /*
     * Método que actualiza los usuarios que se vayan a notificar, indicando la fecha de notificación 
     * y tipo de seguimiento del que se va a notificar
     * @author aberuete
     * @date 14/02/2023
     * @param Set<Id> idsFromUser Lista de ids de usuario a actualizar
     * @param String typeOfFollowUp tipo de seguimiento que se carga 
     */
    @future
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
            System.debug('user to update'+ userToUpdate);
            userslistToUpdate.add(userToUpdate);
        }

        update userslistToUpdate;  
    }

     /*
    * Esta clase es usada para introducir un parametro en el método invocable
    * @author  aberuete
    * @date 14/02/2023
    */
    public class FlowInputs
    {
        // Lista de registros 
        @InvocableVariable 
        public List<FollowUp__c> listofFollowUps;
    }
}