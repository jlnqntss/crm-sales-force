public with sharing class AccountRelationshipUtil {
    /**
     * Cambia el propietario de las AccountRelationship al usuario por defecto para evitar que un mediador conserve la visibilidad sobre una AccountRelationship
     *
     * @author fpalomo
     * @date 09/02/2024
     */
    public static void onBeforeInsertChangeOwner(List<AccountRelationship__c> newList)
    {
        User defaultOwnerUser = getDefaultOwnerUser();

        for (AccountRelationship__c ar : newList)
        {
            if (ar.OwnerId != defaultOwnerUser.Id)
            {
                ar.OwnerId = defaultOwnerUser.Id;
            }
        }
    }

    /**
     * Al crear un nuevo AccountRelationship, actualiza el campo IntermediaryId__c con el AccountId del usuario actual si es un Agente de Ventas o Agente Ventas AGR
     *
     * @author fpalomo
     * @date 09/02/2024
     */
    public static void updateIntermediaryId(List<AccountRelationship__c> newList, Map<Id, AccountRelationship__c> oldMap)
    {
        User currentUser = [SELECT Id, AccountId, Contact.AccountId, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        for (AccountRelationship__c ar : newList)
        {
            if (oldMap != null && oldMap.containsKey(ar.Id))
            {
                AccountRelationship__c oldAr = oldMap.get(ar.Id);

                if (oldAr.IntermediaryId__c == ar.IntermediaryId__c)
                {
                    continue;
                }
            }
            
            if (currentUser.Profile.Name == ProfilesSelector.PROFILE_AGENTE_VENTAS || currentUser.Profile.Name == ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR)
            {
                ar.IntermediaryId__c = currentUser.Contact.AccountId;
            }
        }
    }

    /**
     * Obtiene el usuario por defecto para asignarle la propiedad de las AccountRelationship
     *
     * @author fpalomo
     * @date 09/02/2024
     */
    public static User getDefaultOwnerUser()
    {
        UsersSelector userSelector = new UsersSelector();
        
        List<User> defaultUsers = userSelector.findUsersByAlias(new List<String> {
            Cross_Selling__c.getinstance().DefaultUser__c
        });

        return defaultUsers.get(0);
    }      
}