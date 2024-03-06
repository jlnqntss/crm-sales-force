public with sharing class ZRMVisibilityRecalcUtil {
    /**
     * @description Devuelve un mapa de IDs de mediadores junto con sus ATMs <UserID, Set<AccountTeamMember>>
     * @author fpalomo
     * @date 29/02/2024
     */
    private static Map<Id, Set<AccountTeamMember>> getIntermediaryATMsMap(List<AccountTeamMember> intermediaryATMs)
    {
        Map<Id, Set<AccountTeamMember>> intermediaryATMsMap = new Map<Id, Set<AccountTeamMember>>();
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
        }
        return intermediaryATMsMap;
    }

    /**
     * @description Devuelve un mapa de IDs de mediadores AGR junto con sus ATMs <UserID, Set<AccountTeamMember>>
     * @author fpalomo
     * @date 29/02/2024
     */
    private static Map<Id, Set<AccountTeamMember>> getAGRIntermediaryATMsMap(List<AccountTeamMember> intermediaryATMs)
    {
        Map<Id, Set<AccountTeamMember>> intermediaryAgrATMsMap = new Map<Id, Set<AccountTeamMember>>();
        for (AccountTeamMember atm : intermediaryATMs)
        {
            if (atm.User.Profile.Name == 'Agente Ventas - AGR')
            {
                if (!intermediaryAgrATMsMap.containsKey(atm.UserId))
                {
                    intermediaryAgrATMsMap.put(atm.UserId, new Set<AccountTeamMember>());
                }
                intermediaryAgrATMsMap.get(atm.UserId).add(atm);
            }
        }
        return intermediaryAgrATMsMap;
    }

    /**
     * @description Devuelve la lista de AccountTeamMembers a eliminar
     * @author fpalomo
     * @date 29/02/2024
     */
    public static List<AccountTeamMember> getATMsToDelete(Map<Id, User> intermediaryUserMap, Map<Id, User> intermediaryAgrUserMap, List<AccountTeamMember> intermediaryATMs)
    {
        List<AccountTeamMember> toDelete = new List<AccountTeamMember>();
        List<Id> toDeleteAccountIDs = new List<Id>();

        Map<Id, Set<AccountTeamMember>> intermediaryATMsMap = getIntermediaryATMsMap(intermediaryATMs);
        Map<Id, Set<AccountTeamMember>> intermediaryAgrATMsMap = getAGRIntermediaryATMsMap(intermediaryATMs);

        // Añadimos a la lista de ATMs a eliminar los ATMs del mediador
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

        // Eliminamos de la lista de ATMs de Mediadores AGR los que no coincidan con un cliente (visible o no) de un mediador
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

        // Añadimos a la lista de ATMs a eliminar los ATMs de los usuarios de la agrupación que coincidan con los clientes del mediador
        for (Id userID : intermediaryAgrUserMap.keySet())
        {
            if (intermediaryAgrATMsMap.containsKey(userID))
            {
                toDelete.addAll(intermediaryAgrATMsMap.get(userID));
            }
        }

        return toDelete;
    }

    /**
     * @description Devuelve las pólizas de los clientes pertenecientes al mediador agrupadas por id de cliente
     * @author fpalomo
     * @date 29/02/2024
     */
    public static Map<Id, Set<Policy__c>> getIntermediaryPoliciesMap(List<Policy__c> policies)
    {
        Map<Id, Set<Policy__c>> intermediaryPoliciesMap = new Map<Id, Set<Policy__c>>();

        for (Policy__c policy : policies)
        {
            if (!intermediaryPoliciesMap.containsKey(policy.PolicyHolder__c))
            {
                intermediaryPoliciesMap.put(policy.PolicyHolder__c, new Set<Policy__c>());
            }
            intermediaryPoliciesMap.get(policy.PolicyHolder__c).add(policy);
        }

        return intermediaryPoliciesMap;
    }
}