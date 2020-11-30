public with sharing class CasesSelector 
{
    /**
     * Busca casos abiertos ordenados por fecha de creación a partir de una lista de ids de cuentas
     * @author adelgado
     * @date 26/11/2020
     * @param  accountIds ids de cuentas
     * @return listado de casos
     */
    public List<Case> findOpenByAccount(String[] accountIds)
    {
        if(accountIds != null && !accountIds.isEmpty())
        {
            return [SELECT OwnerId, Owner.Email FROM Case WHERE isClosed = FALSE AND AccountId IN : accountIds ORDER BY CreatedDate DESC];
        }
        else 
        {
            return new List<Case>();
        }

    }
}