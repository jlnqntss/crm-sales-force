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
            
            if (currentUser.Profile.Name == 'Agente Ventas' || currentUser.Profile.Name == 'Agente Ventas - AGR')
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

    /**
     * Metodo que vuelve a dar visibilidad sobre los registros de cuenta relacionada para los clientes que se da visibilidad
     * 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    public static void recalculateVisibilityAccountRelationshipSetVisibility(List<String> accountIdList, Set<String> intermediaryIdList) {
        AccountRelationshipSelector selector = new AccountRelationshipSelector();
        List<AccountRelationship__c> accountsRelationshipToUpdate = new List<AccountRelationship__c>();
        
        List<AccountRelationship__c> accountRelationshipsToActivate = selector.findAccountRelationshipToGiveVisibility(accountIdList, intermediaryIdList);        

        AccountRelationship__c aux;
        for (AccountRelationship__c accountRelationship: accountRelationshipsToActivate) {
            aux = new AccountRelationship__c();
            aux.Id = accountRelationship.Id;
            aux.IntermediaryId__c = accountRelationship.IntermediaryIdOld__c;
            aux.IntermediaryIdOld__c = null;
            accountsRelationshipToUpdate.add(aux);
        }
        if (!accountsRelationshipToUpdate.isEmpty()) {
            update accountsRelationshipToUpdate;
        }
    }


    /**
     * Metodo que vuelve a dar visibilidad sobre los registros de cuenta relacionada para los clientes que se da visibilidad
     * 
     *
     * @author dmunoz
     * @date 12/02/2024 
     */
    public static void recalculateVisibilityDenyAccountRelationshipSetVisibility(List<String> accountIdList, Set<String> intermediaryIdList) {
        AccountRelationshipSelector selector = new AccountRelationshipSelector();
        List<AccountRelationship__c> accountsRelationshipToUpdate = new List<AccountRelationship__c>();
        
        List<AccountRelationship__c> accountRelationshipsToActivate = selector.findAccountRelationshipToGiveVisibility(accountIdList, intermediaryIdList);        

        AccountRelationship__c aux;
        for (AccountRelationship__c accountRelationship: accountRelationshipsToActivate) {
            aux = new AccountRelationship__c();
            aux.Id = accountRelationship.Id;
            aux.IntermediaryIdOld__c = accountRelationship.IntermediaryId__c;
            aux.IntermediaryId__c = null;
            accountsRelationshipToUpdate.add(aux);
        }
        if (!accountsRelationshipToUpdate.isEmpty()) {
            update accountsRelationshipToUpdate;
        }
    }
    
}