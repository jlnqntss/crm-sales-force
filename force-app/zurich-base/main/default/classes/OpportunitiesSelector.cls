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
            .addCondition(Query.conditionEq(Opportunity.IsTest__c, false)) // arcortazar - 31/01/2022: Incluímos esta condición para que no devuelva las ofertas de test
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
            Opportunity.SessionId__c,
            Opportunity.isUpdatedFromINFO__c
        })
        .addCondition(Query.conditionEq(Opportunity.AccountId, accountId))
        .addCondition(Query.conditionEq(Opportunity.Scope__c, scope));

        return (List<Opportunity>) this.baseQuery.run();
    }


    /**
     * Busca Ofertas a partir del Id del cliente, del ambito.
     * 
     * @author nts (arcortazar)
     * @date 01/02/2022
     * @param {Id id} id de la oportunidad
     * @return {List<Opportunity} ofertas encontradas
     */
    public List<Opportunity> findById(Id id)
    {   
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Opportunity.Id,
            Opportunity.AccountId,
            Opportunity.ScopeId__c,
            Opportunity.OwnerId,
            Opportunity.IsTest__c 
        })
        .selectFields('Owner.ProfileId')
        .selectFields('Owner.Profile.Name')
        .addCondition(Query.conditionEq(Opportunity.Id, id));
        return (List<Opportunity>) this.baseQuery.run();
    }

    /**
     * Busca Ofertas a partir del AccountId, ScopeId y que tenga distinto ID
     * 
     * @author nts (arcortazar)
     * @date 01/02/2022
     * @param {Id id} id de la oportunidad
     * @param {Id accountId} id de la Account asociada a la oportunidd
     * @param {String scope} id del scope
     * @return {List<Opportunity} ofertas encontradas
     */
    public List<Opportunity> findByAccountIdAndScopeAndNotId(Id id, Id accountId, String scope)
    {
        this.baseQuery.selectFields(new Set<Schema.SObjectField>{
            Opportunity.Id,
            Opportunity.IsTest__c,
            Opportunity.OwnerId
        })
        .selectFields('Owner.ProfileId')
        .selectFields('Owner.Profile.Name')
        .addCondition(Query.conditionNotEq(Opportunity.Id, id))
        .addCondition(Query.conditionEq(Opportunity.AccountId, accountId))
        .addCondition(Query.conditionEq(Opportunity.ScopeId__c, scope));
        
        return (List<Opportunity>) this.baseQuery.run();
        
    }

    /**
     * Busca Ofertas a partir del Id del cliente, del ambito.
     * 
     * @author nts (arcortazar)
     * @date 30/03/2022
     * @param {Set<String> } lista de InfoQuoteNumber por los que buscar
     * @return {List<Opportunity} ofertas encontradas
     */
    public Set<String> findUpdatedFromInfoByQuoteNumber(Set<String> quoteNumbers)
    {
        Set<String> setInfoQuoteNumbers = new Set<String>();
        if(!quoteNumbers.isEmpty() && quoteNumbers != null)
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Opportunity.Id,
                Opportunity.InfoQuoteNumber__c
            })
            .addConditionString('InfoQuoteNumber__c IN (\'' + String.join(new List<String>(quoteNumbers), '\',\'') + '\')')
            .addCondition(Query.conditionEq(Opportunity.isUpdatedFromINFO__c, true));

            List<Opportunity> listaRetorno = (List<Opportunity>) this.baseQuery.run();
            for (Opportunity o : listaRetorno)
            {
                setInfoQuoteNumbers.add(o.InfoQuoteNumber__c);
            }
            return setInfoQuoteNumbers;
        }
        else 
        {
            return setInfoQuoteNumbers;
        }
    }

   /**
    * Método utilizado por el batch RelateCasesToNewOffersBatch para definir el scope
    * @author lrodriguez6@seidor.es
    * @date 11/11/2022
    * @param String days para filtrar la query
    * @return String query que se va a lanzar en el batch
    */
    public List<Opportunity> findByCreatedOfferAndCreationDate(List<String> createdOffer, String daysToRetrieve)
    {
        if(daysToRetrieve != null && !String.isBlank(daysToRetrieve) && createdOffer != null && !createdOffer.isEmpty())
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField>{
                Opportunity.Id,
                Opportunity.InfoQuoteNumber__c
            })
            .addConditionIn(Opportunity.InfoQuoteNumber__c, createdOffer);

           

            return (List<Opportunity>) this.baseQuery.run();
        }
        else
        {
            return new List<Opportunity>();
        }
    }
}