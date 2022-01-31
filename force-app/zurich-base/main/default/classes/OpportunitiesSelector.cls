public with sharing class OpportunitiesSelector extends RecordsSelector
{
    //#region Contructores
    public OpportunitiesSelector()
    {
        super(Opportunity.getSObjectType());
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
        List<Opportunity> result = new List<Opportunity>();

        if( accountId != null && scopeIds != null ) {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Opportunity.Id,
                Opportunity.AccountId,
                Opportunity.ScopeId__c,
                Opportunity.OwnerId
            })
            .addCondition(Query.conditionEq(Opportunity.AccountId, accountId))
            .addCondition(Query.conditionIn(Opportunity.ScopeId__c, scopeIds))
            .orderBy(Opportunity.CreatedDate.getDescribe().getName(), 'DESC');

            result = (List<Opportunity>) this.baseQuery.run();
        }

        return result;

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
     * 
     * @last modified by  : arcortazar
     */
    public List<Opportunity> selectByAccountIdScopesAndOwnerProfile(Id accountId, Set<Id> scopeIds, Set<String> ownerProfileNames)
    {
        List<Opportunity> result = new List<Opportunity>();

        if(accountId != null && scopeIds != null && ownerProfileNames != null) {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Opportunity.Id,
                Opportunity.AccountId,
                Opportunity.ScopeId__c,
                Opportunity.OwnerId
            })
            .addCondition(Query.conditionEq(Opportunity.AccountId, accountId))
            .addCondition(Query.conditionIn(Opportunity.ScopeId__c, scopeIds))
            .addConditionString('Owner.Profile.Name IN (\'' + String.join(new List<String>(ownerProfileNames), '\',\'') + '\')')
            .addCondition(Query.conditionIn(Opportunity.IsTest__c, false)) // arcortazar - 31/01/2022: Incluímos esta condición para que no devuelva las ofertas de test
            .orderBy(Opportunity.CreatedDate.getDescribe().getName(), 'DESC');

            result = (List<Opportunity>) this.baseQuery.run();
        }

        return result;
    }

    /**
     * Busca Ofertas a partir del Id del cliente, del ambito.
     * 
     * @author nts (agonzalezisasi)
     * @date 04/06/2021
     * @param {Id accountId} id del cliente
     * @param {String scope} ambito
     * @return {List<Opportunity} ofertas encontradas
     */
    public List<Opportunity> findByAccountIdAndScope(Id accountId, String scope)
    {
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Opportunity.Id,
            Opportunity.InfoQuoteNumber__c,
            Opportunity.SessionId__c
        })
        .addCondition(Query.conditionEq(Opportunity.AccountId, accountId))
        .addCondition(Query.conditionEq(Opportunity.Scope__c, scope));

        return (List<Opportunity>) this.baseQuery.run();
    }
}