public with sharing class OpportunitiesSelector extends BaseSelector
{
    //#region Contructores
    public OpportunitiesSelector()
    {}

    public OpportunitiesSelector(Set<String> fieldsToQuery)
    {
        this();
        this.sObjectToQuery = 'Opportunity';
        this.fieldsToQuery = fieldsToQuery;
    }
    //#endregion

    /**
     * Busca Opportunities a partir del Id de cuenta y de un conjunto de Ids de Scopes
     *
     * @author rlopez
     * @date 30/11/2020
     * @param  accountId    Id de la cuenta para la que queremos buscar ofertas
     * @param  scopesIds    Conjunto de Ids de Scope por los que queremos buscar ofertas
     *
     * @return              Listado de opportunies sobre los que se ha realizado match
     */
    public List<Opportunity> selectByAccountIdAndScopes(Id accountId, Set<Id> scopeIds)
    {
        if(accountId != null && scopeIds != null)
        {
            String query = String.format(
                'SELECT {0} FROM Opportunity ' +
                'WHERE AccountId = : accountId AND ScopeId__c IN : scopeIds ' +
                'ORDER BY createdDate DESC ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Opportunity>) Database.query(query);
        }
        else
        {
            return new List<Opportunity>();
        }
    }

    /**
     * Busca Opportunities a partir del Id de cuenta, de un conjunto de Ids de Scopes y
     * de un conjunto de nombres de perfiles para filtrar por los propietarios
     *
     * @author rlopez
     * @date 12/01/2021
     * @param accountId         Id de la cuenta para la que queremos buscar ofertas
     * @param scopesIds         Conjunto de Ids de Scope por los que queremos buscar ofertas
     * @param ownerProfileNames Conjunto de nombres de perfiles para filtrar los propietarios de las ofertas
     *
     * @return                  Listado de opportunies sobre los que se ha realizado match
     */
    public List<Opportunity> selectByAccountIdScopesAndOwnerProfile(Id accountId, Set<Id> scopeIds, Set<String> ownerProfileNames)
    {
        if(accountId != null && scopeIds != null && ownerProfileNames != null)
        {
            String query = String.format(
                'SELECT {0} FROM Opportunity ' +
                'WHERE AccountId = : accountId AND ScopeId__c IN : scopeIds AND Owner.Profile.Name IN : ownerProfileNames ' +
                'ORDER BY createdDate DESC ',
                new List<String> {
                String.join(new List<String> (this.fieldsToQuery), ',')
            }
                );
            return (List<Opportunity>) Database.query(query);
        }
        else
        {
            return new List<Opportunity>();
        }
    }
}