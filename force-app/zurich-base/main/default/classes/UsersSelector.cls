/**
 * @description       : Clase selectora del sobject User
 * @author            : aberuete
 * @group             :
 * @last modified on  : 10-24-2023
 * @last modified by  : aberuete
 **/
public with sharing class UsersSelector extends RecordsSelector
{
    public UsersSelector()
    {
        super( User.getSObjectType() );
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
     * Recupera los Usuarios cuyo email coincida con un conjunto dado
     *
     * @author aberuete
     * @date 24/10/2023
     *
     * @param {List<String> emails} Lista de emails de usuarios
     * @return {List<User>} lista de Usuarios
     */
    public List<User> findByEmails (List<String> emails)
    {
        this.baseQuery.selectFields
        (
            new List<Schema.SObjectField>
        {
            User.Id,
            User.Email
        }
        )
        .addConditionIn(User.Email,emails)
        .enforceSecurity(true);

        return (List<User>) this.baseQuery.run();
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
    public Map<Id, User> getUsersByName(List<String> userNames)
    {

        Map<Id, User> result = new Map<Id, User>();
        if ( userNames != null && !userNames.isEmpty() )
        {
            result = new Map<Id, User>([SELECT Id, Name FROM User WHERE Name IN: userNames]);
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
    public User findUserByEmail(String userEmail)
    {

        User result = null;

        if ( userEmail != null && String.isNotEmpty(userEmail) )
        {
            List<User> users = new List<User>([
                                                  SELECT Id, firstName, lastName, email, userName, profileId, alias, CommunityNickname, ManagerId
                                                  FROM User WHERE email = : userEmail
                                                                          LIMIT 1
                                              ]);

            if( !users.isEmpty() )
            {
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
    public User findUserByCommunityNickname(String communityNickname)
    {

        User result = null;

        if ( communityNickname != null && String.isNotEmpty(communityNickname) )
        {
            List<User> manager = new List<User>([SELECT Id FROM User WHERE IsActive = true AND CommunityNickname = : communityNickname LIMIT 1]);

            if ( manager != null && !manager.isEmpty() )
            {
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
    public User getLoginUserToUpdate(Id userId)
    {
        User result = null;

        if ( userId != null && String.isNotEmpty(userId) )
        {
            List<User> userList = new List<User>([
                                                     SELECT Id, firstName, lastName, email, userName, profileId, alias, CommunityNickname, CallCenterId, UserRoleId, Department, Signature, Title, ManagerId, License_Group__c
                                                     FROM User WHERE Id =: userId LIMIT 1
                                                 ]);

            if ( userList != null && !userList.isEmpty() )
            {
                result = userList.get(0);
            }
        }
        return result;
    }

    /**
     * Obtiene una lista de usuarios por perfil. Es posible seleccionar el máximo de registros devueltos
     * @param profileNames: lista con los perfiles a buscar por nombre
     * @param activeStatus: lista para indicar los estados del usuario: activos, no activos o ambos
     * @param maxResults: para limitar los resultados si se precisa
     * @author jfherrero
     * @date 02/08/2023
     */
    public List<User> findByProfileName(List<String> profileNames, List<boolean> activeStatus, Integer maxResults)
    {
        if(maxResults == null || maxResults < 1)
        {
            maxResults = 50000;
        }
        if( activeStatus == null || activeStatus.isEmpty() )
        {
            activeStatus = new List<Boolean> {true, false};
        }
        List<User> result = new List<User>([SELECT Id, Name, IsActive, Profile.Name
                                            FROM User
                                            WHERE Profile.Name IN: profileNames AND IsActive IN: activeStatus
                                            ORDER BY Profile.Name ASC, Name ASC
                                            Limit: maxResults]);
        return result;
    }
    /**
     * Obtiene una lista de usuarios a través del Account relacionadas con el Contact del User
     * @param contactAccountId: Set de Ids de Account
     * @author jfherrero
     * @date 02/08/2023
     */

    public List<User> findByContactAccountId(Set<Id> contactAccountIds)
    {
        List<User> result = new List<User>([SELECT Id, Contact.AccountId FROM User WHERE Contact.AccountId IN: contactAccountIds]);
        return result;
    }

    /**
     * @description Selector para conseguir usuarios a partir de su alias.
     *              Se recuperan los campos Id y Alias.
     * @author      jgallaga
     * @date        18/08/2023
     */
    public List<User> findUsersByAlias(List<String> aliases)
    {
        List<User> foundUsers = new List<User>();

        if(aliases == null || aliases.isEmpty())
        {
            return foundUsers;
        }

        this.baseQuery.selectField(User.Alias);

        this.baseQuery.addConditionIN(User.Alias, aliases);
        this.baseQuery.addConditionEq(User.IsActive, true);

        return (List<User>) this.baseQuery.run();
    }

    /**
     * @description Selector para conseguir usuarios a partir de su relación con Ids de Account
     * @author      jgallaga
     * @date        16/08/2023
     */
    public List<User> findUsersByAccountId(List<String> accountIds)
    {
        List<User> foundUsers = new List<User>();

        if(accountIds == null || accountIds.isEmpty())
        {
            return foundUsers;
        }

        this.baseQuery.addConditionIn(User.Contact.AccountId, accountIds);
        this.baseQuery.addConditionEq(User.IsActive, true);

        return (List<User>) this.baseQuery.run();
    }
}