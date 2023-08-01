/**
 * @description       : Clase selectora del sobject User
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 07-31-2023
 * @last modified by  : aberuete
**/
public with sharing class UsersSelector extends RecordsSelector 
{
    public UsersSelector() 
    {
        super(User.getSObjectType());
    }

     /**
     * Recupera los Usuarios cuya id coincidan con un conjunto dado
     * 
     * @author aberuete
     * @date 20/02/2023
     * 
     * @param {Set<Id> userIds} Set de ids de usuarios 
     * @return {List<User>} lista de Usuarios
     */
    public List<User> findById (Set<Id> userIds)
    {
        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
            {
                User.Id,
                User.NotifyType__c,
                User.NotifyDate__c,
                User.Notified__c
            }
        )
        .selectFields('Profile.Name');

        return (List<User>) this.baseQuery.byId(userIds).run();
    }

    /**
     * Recupera los Usuarios cuya id coincidan con un conjunto dado de nombres
     * 
     * @author dmunoz
     * @date 23/05/2023
     * 
     * @param {List<String> userNames} lista de nombres de usuarios 
     * @return {Map<Id, User>} mapa de Usuarios
     */
    public Map<Id, User> getUsersByName(List<String> userNames) {

        Map<Id, User> result = new Map<Id, User>();
        if (userNames != null && !userNames.isEmpty()) {
            result = new Map<Id, User>([SELECT Id, Name FROM User WHERE Name IN :userNames]);
        }

        return result;
    }


     /**
     * Recupera Usuario por email
     * 
     * @author dmunoz
     * @date 15/06/2023
     * 
     * @param {List<String> userNames} lista de nombres de usuarios 
     * @return {Map<Id, User>} mapa de Usuarios
     */
    public User findUserByEmail(String userEmail) {

        User result = null;

        if (userEmail != null && String.isNotEmpty(userEmail)) {
            List<User> users = new List<User>([
                SELECT Id, firstName, lastName, email, userName, profileId, alias, CommunityNickname, ManagerId
                FROM User WHERE email = :userEmail 
                LIMIT 1
            ]);

            if( !users.isEmpty() ) {
                result = users.get(0);
            }
        }

        return result;
    }    

     /**
     * Recupera Usuario por nickname de comunidad
     * 
     * @author dmunoz
     * @date 15/06/2023
     * 
     * @param communityNickname
     * @return Usuario
     */
    public User findUserByCommunityNickname(String communityNickname) {

        User result = null;

        if (communityNickname != null && String.isNotEmpty(communityNickname)) {
            List<User> manager = new List<User>([SELECT Id FROM User WHERE IsActive = true AND CommunityNickname = :communityNickname LIMIT 1]);

            if (manager != null && !manager.isEmpty()) {
                result = manager.get(0);
            }
        }

        return result;
    }


    /**
     * Recupera los datos de Usuario por id para comprobar si alguno de estos se ha modificado con respecto a la informacion que llega de IAM
     * 
     * @author dmunoz
     * @date 15/06/2023
     * 
     * @param communityNickname
     * @return Usuario
     */
    public User getLoginUserToUpdate(Id userId) {
        User result = null;

        if (userId != null && String.isNotEmpty(userId)) { 
            List<User> userList = new List<User>([
                SELECT Id, firstName, lastName, email, userName, profileId, alias, CommunityNickname, CallCenterId, UserRoleId, Department, Signature, Title, ManagerId
                FROM User WHERE Id =: userId LIMIT 1
            ]);

            if (userList != null && !userList.isEmpty()) {
                result = userList.get(0);
            }
        }
        return result;
    }
}