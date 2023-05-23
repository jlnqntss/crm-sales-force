/**
 * @description       : Clase selectora del sobject User
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 02-20-2023
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
        );

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
}