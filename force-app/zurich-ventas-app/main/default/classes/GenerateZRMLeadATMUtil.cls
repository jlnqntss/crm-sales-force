/**
 * Clase utilidad del trigger para el evento ZRMLeadATM__e
 *
 * @author dmunoz
 * @date 07/03/2024 
 */
public with sharing class GenerateZRMLeadATMUtil {
    
    public static void handleEventAfterInsert(List<ZRMLeadATM__e> eventListTrigger) {

        try
        {
            
            List<String> leadsIds = new List<String>();
            List<String> eventUsersIdList = new List<String>();
    
            for (ZRMLeadATM__e event: eventListTrigger) {
                eventUsersIdList.add(event.ZRMUserId__c);
                leadsIds.add(event.AccountId__c);
            }
    
            // Update owner
            updateZRMLeadsOwner(leadsIds);
    
            // Generate ATMs
            generateZRMLeadsATM(leadsIds, eventUsersIdList);

        }
        catch (Exception e)
        {            
            ErrorLogUtil.commitError(e, 'GenerateZRMLeadATMTrigger', 'handleEventAfterInsert');            
        }


    }


    private static void updateZRMLeadsOwner(List<String> leadsIdsToUpdateOwner) {

        List<Account> leadsToUpdate = new List<Account>();
        String defaultUser = obtainDefaultUser();
        Account acc;

        for (String accountId: leadsIdsToUpdateOwner) {
            acc = new Account();
            acc.Id = accountId;
            acc.OwnerId = defaultUser;
            leadsToUpdate.add(acc);

        }

        update leadsToUpdate;
        
    }


    private static void generateZRMLeadsATM(List<String> leadsIds, List<String> eventUsersIdList) {

        List<AccountTeamMember> atmToInsert = new List<AccountTeamMember>();

        // Obtengo el mediador y agrupacion del usuario del evento. Solo me quedo con el primero ya que generamos un evento por cada lead no se inserta en modo bulk
        UsersSelector userSelector = new UsersSelector();
        User userEvent = userSelector.findUserIntermediaryByUserId(eventUsersIdList.get(0));

        // Obtengo todos los usuarios a los que generaremos atm a través del mediador y de la agrupacion del mediador        
        Set<String> intermediariesSet = new Set<String>{userEvent.Contact.AccountId};
        Map<String, String> mediadoresIdsYAgrupacionesIdMap = new Map<String, String>();
        mediadoresIdsYAgrupacionesIdMap.put(userEvent.Contact.AccountId, userEvent.Contact.Account.IntermediaryGroup__c);

        // <IntermediaryId, List<UserId>
        Map<String, List<String>> intermediariesWithUsers = ZRMAccountVisibilityUtil.getIntermediariesUsers(intermediariesSet, mediadoresIdsYAgrupacionesIdMap);

        // Generamos los atms a insertar (el bucle solo se ejecutará una vez)
        for (String leadId: leadsIds) {
            atmToInsert.addAll(AccountTeamMemberUtil.createATMZRMRecordList(leadId, intermediariesWithUsers.get(userEvent.Contact.AccountId)));
        }

        if (!atmToInsert.isEmpty()) {
            insert atmToInsert;
        }
    }

    /**
     * @description Método para recuperar los Ids de los usuarios configurados para ser los
     *              Ids por defecto para el usuario por defecto CC y el usuario por defecto
     *              en caso de error.
     * @author      jgallaga
     * @date        18/08/2023
     */
    private static String obtainDefaultUser()
    {

        String defaultUserId;
        String aliasDeaultUser = Cross_Selling__c.getinstance().DefaultUser__c;

        UsersSelector userQuery = new UsersSelector();

        List<User> defaultUsers = userQuery.findUsersByAlias(new List<String> {aliasDeaultUser});

        defaultUserId = defaultUsers.get(0).Id;

        return defaultUserId;
    }

}