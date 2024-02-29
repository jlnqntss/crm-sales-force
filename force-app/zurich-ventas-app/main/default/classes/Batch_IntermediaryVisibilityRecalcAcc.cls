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
                if (user.Profile.Name == 'Agente Ventas')
                {
                    intermediaryUserMap.put(user.Id, user);
                }
                else if (user.Profile.Name == 'Agente Ventas - AGR')
                {
                    intermediaryAgrUserMap.put(user.Id, user);
                }
            }

            // 1.1. Mapa de combinado de los usuarios de Mediadores y Mediadores AGR
            Map<String, User> allIntermediariesList = new Map<String, User>();
            for (User user : intermediaryUserMap.values())
            {
                allIntermediariesList.put(user.Id, user);
            }
            for (User user : intermediaryAgrUserMap.values())
            {
                allIntermediariesList.put(user.Id, user); 
            }
            
            // 2. Seleccionamos todos los ATMs para ambos usuarios y los agrupamos por id de usuario (mediador)
            List<AccountTeamMember> intermediaryATMs = atmSelector.findZRMATMsByUser(allIntermediariesList.values());
            Map<Id, Set<AccountTeamMember>> intermediaryATMsMap = new Map<Id, Set<AccountTeamMember>>();
            Map<Id, Set<AccountTeamMember>> intermediaryAgrATMsMap = new Map<Id, Set<AccountTeamMember>>();
            for (AccountTeamMember atm : intermediaryATMs)
            {
                if (atm.User.Profile.Name == 'Agente Ventas')
                {
                    if (!intermediaryATMsMap.containsKey(atm.UserId))
                    {
                        intermediaryATMsMap.put(atm.UserId, new Set<AccountTeamMember>());
                    }
                    intermediaryATMsMap.get(atm.UserId).add(atm);
                }
                else if (atm.User.Profile.Name == 'Agente Ventas - AGR')
                {
                    if (!intermediaryAgrATMsMap.containsKey(atm.UserId))
                    {
                        intermediaryAgrATMsMap.put(atm.UserId, new Set<AccountTeamMember>());
                    }
                    intermediaryAgrATMsMap.get(atm.UserId).add(atm);
                }
            }

            // 3. Añadimos a la lista de ATMs a eliminar los ATMs del mediador
            List<AccountTeamMember> toDelete = new List<AccountTeamMember>();
            List<Id> toDeleteAccountIDs = new List<Id>();
            for (Id userID : intermediaryUserMap.keySet())
            {
                if (intermediaryATMsMap.containsKey(userID))
                {
                    toDelete.addAll(intermediaryATMsMap.get(userID));

                    for (AccountTeamMember atm : intermediaryATMsMap.get(userID))
                    {
                        toDeleteAccountIDs.add(atm.AccountId);
                    }
                }
            }

            // 4. Eliminamos de la lista de ATMs de Mediadores AGR los que no coincidan con un cliente (visible o no) de un mediador
            for (Set<AccountTeamMember> atmSet : intermediaryAgrATMsMap.values())
            {
                for (AccountTeamMember atm : atmSet)
                {
                    if (!toDeleteAccountIDs.contains(atm.AccountId))
                    {
                        intermediaryAgrATMsMap.get(atm.UserId).remove(atm);
                    }
                }
            }

            // 4. Añadimos a la lista de ATMs a eliminar los ATMs de los usuarios de la agrupación que coincidan con los clientes del mediador
            for (Id userID : intermediaryAgrUserMap.keySet())
            {
                if (intermediaryAgrATMsMap.containsKey(userID))
                {
                    toDelete.addAll(intermediaryAgrATMsMap.get(userID));
                }
            }

            // 5. Borramos los ATMs (si hay)
            ZRMPolicyVisibilityUtil.deleteATMs(toDelete);

            // 7. Seleccionamos las pólizas de los clientes pertenecientes al mediador y las agrupamos por id de cliente
            Map<Id, Set<Policy__c>> intermediaryPoliciesMap = new Map<Id, Set<Policy__c>>();
            for (Policy__c policy : policiesSelector.selectByIntermediaryId(intermediaryIds))
            {
                if (!intermediaryPoliciesMap.containsKey(policy.PolicyHolder__c))
                {
                    intermediaryPoliciesMap.put(policy.PolicyHolder__c, new Set<Policy__c>());
                }
                intermediaryPoliciesMap.get(policy.PolicyHolder__c).add(policy);
            }

            // 8. Generamos los nuevos ATMs (Mediador y Mediadores AGR) para las cuentas de las pólizas que tiene el mediador
            List<AccountTeamMember> toInsert = new List<AccountTeamMember>();
            for (Id accountId : intermediaryPoliciesMap.keySet())
            {
                toInsert.addAll(AccountTeamMemberUtil.createATMZRMRecordList(accountId, allIntermediariesList.values()));
            }

            // 9. Insertamos los nuevos ATMs
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