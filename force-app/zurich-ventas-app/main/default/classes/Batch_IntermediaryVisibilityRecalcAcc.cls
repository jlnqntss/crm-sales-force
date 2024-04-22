/**
 * @description       : Batch que recalcula la visibilidad sobre los clientes de los mediadores ZRM
 * @author            : fpalomo
 * @last modified on  : 28/02/2024
 **/
public with sharing class Batch_IntermediaryVisibilityRecalcAcc implements Database.Batchable<sObject>
{
    private static final String CLASS_NAME = 'Batch_IntermediaryVisibilityRecalcAcc';
    private Set<String> accountIDs;

    /**
     * @description Constructor
     * @param accountIDs Set<String> con los ids de las cuentas a recalcular
     */
    public Batch_IntermediaryVisibilityRecalcAcc(Set<String> accountIDs)
    {
        this.accountIDs = accountIDs;
    }
    
    /**
     * @description Clase wrapper para el metodo invocable
     * @author fpalomo
     */
    public class Requests
    {
        @InvocableVariable public String intermediaryId;
    }

    /**
     * @description Metodo invocable para lanzar el batch desde un flow
     * @param requests List<Requests>
     * @author fpalomo
     */
    @InvocableMethod
    public static void invocableExecuteBatch(List<Requests> requests)
    {
        if (requests == null || requests.isEmpty())
        {
            return;
        }

        if (requests[0].intermediaryId != null && String.isNotEmpty(requests[0].intermediaryId))
        {
            Database.executeBatch(new Batch_IntermediaryVisibilityRecalcAcc(new Set<String>{requests[0].intermediaryId}), 200);
        }
    }
    
    public List<Account> start(Database.BatchableContext bc)
    {
        AccountsSelector accountsSelector = new AccountsSelector();
        accountsSelector.baseQuery.selectFields(new Set<String>{ 'IntermediaryGroup__c' });

        return ( accountsSelector.selectById(new Set<Id>((List<Id>) new List<String>(accountIDs))));
    }


    public void execute(Database.BatchableContext bc, List<Account> scope)
    {
        UsersSelector usersSelector = new UsersSelector();
        AccountTeamMemberSelector atmSelector = new AccountTeamMemberSelector();
        PoliciesSelector policiesSelector = new PoliciesSelector();

        try
        {
            List<String> intermediaryGroupIDs = new List<String>();
            Set<String> intermediaryIds = new Set<String>();

            for (Account acc : scope)
            {
                intermediaryGroupIDs.add(acc.IntermediaryGroup__c);
                intermediaryIds.add(acc.Id);
            }

            // 1. Seleccionamos el usuario del mediador (accountIDs) y los usuarios de la agrupación, los agrupamos en dos mapas distintos
            Map<Id, User> intermediaryUserMap = new Map<Id, User>();
            Map<Id, User> intermediaryAgrUserMap = new Map<Id, User>();
            for (User user : usersSelector.findZRMActiveUsersFromIntermediaryAndAGRFromGroup(intermediaryIds, intermediaryGroupIDs))
            {
                if (user.Profile.Name == ProfilesSelector.PROFILE_AGENTE_VENTAS)
                {
                    intermediaryUserMap.put(user.Id, user);
                }
                else if (user.Profile.Name == ProfilesSelector.PROFILE_AGENTE_VENTAS_AGR)
                {
                    intermediaryAgrUserMap.put(user.Id, user);
                }
            }

            // 2. Mapa de combinado de los usuarios de Mediadores y Mediadores AGR
            Map<String, User> allIntermediariesList = new Map<String, User>();
            for (User user : intermediaryUserMap.values())
            {
                allIntermediariesList.put(user.Id, user);
            }
            for (User user : intermediaryAgrUserMap.values())
            {
                allIntermediariesList.put(user.Id, user); 
            }
            
            // 3. Seleccionamos todos los ATMs para ambos usuarios
            List<AccountTeamMember> intermediaryATMs = atmSelector.findZRMATMsByUser(allIntermediariesList.values());

            // 4. Obtenemos los ATMs a eliminar
            List<AccountTeamMember> toDelete = ZRMVisibilityRecalcUtil.getATMsToDelete(intermediaryUserMap, intermediaryAgrUserMap, intermediaryATMs);

            // 5. Borramos los ATMs
            ZRMPolicyVisibilityUtil.deleteATMs(toDelete);

            // 6. Seleccionamos las pólizas de los clientes pertenecientes al mediador y las agrupamos por id de cliente
            List<Policy__c> policies = policiesSelector.selectByIntermediaryId(intermediaryIds);
            Map<Id, Set<Policy__c>> intermediaryPoliciesMap = ZRMVisibilityRecalcUtil.getIntermediaryPoliciesMap(policies);

            // 7. Generamos los nuevos ATMs (Mediador y Mediadores AGR) para las cuentas de las pólizas que tiene el mediador
            List<AccountTeamMember> toInsert = new List<AccountTeamMember>();
            for (Id accountId : intermediaryPoliciesMap.keySet())
            {
                toInsert.addAll(AccountTeamMemberUtil.createATMZRMRecordList(accountId, allIntermediariesList.values()));
            }

            // 8. Insertamos los nuevos ATMs
            ZRMPolicyVisibilityUtil.insertATMs(toInsert);
        }
        catch (Exception e)
        {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }
    }

    public void finish(Database.BatchableContext bc)
    {
        // Unused
    }
}