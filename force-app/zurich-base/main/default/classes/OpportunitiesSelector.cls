/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 09-25-2023
 * @last modified by  : overes
 **/
public with sharing class OpportunitiesSelector extends RecordsSelector
{
    //#region Contructores
    public OpportunitiesSelector()
    {
        super( Opportunity.getSObjectType() );
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

        if( accountId != null && scopeIds != null )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                Opportunity.Id,
                Opportunity.AccountId,
                Opportunity.ScopeId__c,
                Opportunity.OwnerId
            })
            .addCondition( Query.conditionEq(Opportunity.AccountId, accountId) )
            .addCondition( Query.conditionIn(Opportunity.ScopeId__c, scopeIds) )
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
     * @last modified by  : overes
     */
    public List<Opportunity> selectByAccountIdScopesAndOwnerProfile(Id accountId, Set<Id> scopeIds, Set<String> ownerProfileNames)
    {
        List<Opportunity> result = new List<Opportunity>();

        if(accountId != null && scopeIds != null && ownerProfileNames != null)
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                Opportunity.Id,
                Opportunity.AccountId,
                Opportunity.ScopeId__c,
                Opportunity.OwnerId
            })
            .addCondition( Query.conditionEq(Opportunity.AccountId, accountId) )
            .addCondition( Query.conditionIn(Opportunity.ScopeId__c, scopeIds) )
            .addConditionString('Owner.Profile.Name IN (\'' + String.join(new List<String>(ownerProfileNames), '\',\'') + '\')')
            .addCondition( Query.conditionEq(Opportunity.IsTest__c, false) ) // arcortazar - 31/01/2022: Incluímos esta condición para que no devuelva las ofertas de test
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
        this.baseQuery.selectFields(new Set<Schema.SObjectField> {
            Opportunity.Id,
            Opportunity.InfoQuoteNumber__c,
            Opportunity.SessionId__c,
            Opportunity.isUpdatedFromINFO__c
        })
        .addCondition( Query.conditionEq(Opportunity.AccountId, accountId) )
        .addCondition( Query.conditionEq(Opportunity.Scope__c, scope) );

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
        this.baseQuery.selectFields(new Set<Schema.SObjectField> {
            Opportunity.Id,
            Opportunity.AccountId,
            Opportunity.ScopeId__c,
            Opportunity.OwnerId,
            Opportunity.IsTest__c
        })
        .selectFields('Owner.ProfileId')
        .selectFields('Owner.Profile.Name')
        .addCondition( Query.conditionEq(Opportunity.Id, id) );
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
        this.baseQuery.selectFields(new Set<Schema.SObjectField> {
            Opportunity.Id,
            Opportunity.IsTest__c,
            Opportunity.OwnerId
        })
        .selectFields('Owner.ProfileId')
        .selectFields('Owner.Profile.Name')
        .addCondition( Query.conditionNotEq(Opportunity.Id, id) )
        .addCondition( Query.conditionEq(Opportunity.AccountId, accountId) )
        .addCondition( Query.conditionEq(Opportunity.ScopeId__c, scope) );

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
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                Opportunity.Id,
                Opportunity.InfoQuoteNumber__c
            })
            .addConditionString('InfoQuoteNumber__c IN (\'' + String.join(new List<String>(quoteNumbers), '\',\'') + '\')')
            .addCondition( Query.conditionEq(Opportunity.isUpdatedFromINFO__c, true) );

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
        if( daysToRetrieve != null && !String.isBlank(daysToRetrieve) && createdOffer != null && !createdOffer.isEmpty() )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
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


    /**
     * Busca Ofertas a partir del Id del cliente, del ambito.
     *
     * @author nts (arcortazar)
     * @date 01/02/2022
     * @param {Id id} id de la oportunidad
     * @return {List<Opportunity} ofertas encontradas
     */
    public List<Opportunity> findByName(Set<String> setNames)
    {
        if( setNames != null && !setNames.isEmpty() )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                Opportunity.Id,
                Opportunity.Name
            })
            .addCondition( Query.conditionIn(Opportunity.Name, setNames) );
            return (List<Opportunity>) this.baseQuery.run();
        }
        else
        {
            return new List<Opportunity>();
        }
    }

    /**
     * @description Método que recupera ofertas en base al Id de la cuenta, el códig
     * de intermediario, el ramo, la fecha de creación y que la oferta no esté cerrada.
     *
     * @author amiranda
     * @date 01-09-2023
     * @param Id accountId Id de la cuenta asociada a la oportunidad
     * @param String intermediaryCode Código de intermedairio asociado a la oportunidad
     * @param String productBranch Ramo de la oportunidad
     * @param Query.DateLiteral daysToRetrieve Días a tener en cuenta
     * @return List<Opportunity> Lista de ofertas encontradas
     **/
    public List<Opportunity> findByAccIdAndIntermediaryCodAndProdBranchAndCreationDateAndNotClosed(
        Id accountId,
        String intermediaryCode,
        String productBranch,
        Query.DateLiteral daysToRetrieve)
    {

        List<Opportunity> retrievedOpportunities = new List<Opportunity>();

        if ( accountId != null  && daysToRetrieve != null )
        {
            Set<Schema.SObjectField> fieldsToRetrieve = new Set<Schema.SObjectField>
            {
                Opportunity.Name,
                Opportunity.StageName,
                Opportunity.AccountId,
                Opportunity.OwnerId,
                Opportunity.IntermediaryId__c,
                Opportunity.IntermediaryCode__c,
                Opportunity.PersonLeadSource__c,
                Opportunity.ProductBranch__c,
                Opportunity.Description,
                Opportunity.PreferedContactStart__c,
                Opportunity.PreferedContactEnd__c
            };

            retrievedOpportunities = this.baseQuery.selectfields(fieldsToRetrieve)
                                     .addConditionEq(Opportunity.AccountId, accountId)
                                     .addConditionEq(Opportunity.IntermediaryCode__c, intermediaryCode)
                                     .addConditionEq(Opportunity.ProductBranch__c, productBranch)
                                     .addConditionEq(Opportunity.CreatedDate, daysToRetrieve)
                                     .addConditionNotEq(Opportunity.StageName, 'Closed Won')
                                     .addConditionNotEq(Opportunity.StageName, 'Closed Lost')
                                     .run();
        }

        return retrievedOpportunities;
    }

    /**
     * Método que recupera las ofertas que InfoQuoteNumber es nulo
     * *
     * @author overes | 09-04-2023
     * @param offerRecord
     * @return  List<Opportunity>
     */
    public List<Opportunity> findOppWhenInfoQuoteNumberIsNull(Opportunity offerRecord)
    {
        return [SELECT Id, SessionId__c, InfoQuoteNumber__c, StageName, Name, CloseDate FROM Opportunity
                WHERE SessionId__c = : offerRecord.SessionId__c
                                     OR (AccountId = : offerRecord.InfoQuoteNumber__c AND CarRegistration__c = : offerRecord.CarRegistration__c AND PersonLeadSource__c = : offerRecord.PersonLeadSource__c)
                                     ORDER BY CreatedDate DESC];
    }

    /**
     * Método que recupera las ofertas que InfoQuoteNumber no es nulo
     * *
     * @author overes | 09-04-2023
     * @param offerRecord
     * @return  List<Opportunity>
     */
    public List<Opportunity> findOppWhenInfoQuoteNumberIsNOTNull(Opportunity offerRecord)
    {
        return [SELECT Id, SessionId__c, InfoQuoteNumber__c, StageName, Name, CloseDate FROM Opportunity
                WHERE SessionId__c = : offerRecord.SessionId__c
                                     OR InfoQuoteNumber__c = : offerRecord.InfoQuoteNumber__c
                                                             OR (AccountId = : offerRecord.AccountId AND CarRegistration__c = : offerRecord.CarRegistration__c AND PersonLeadSource__c = : offerRecord.PersonLeadSource__c)
                                                             ORDER BY CreatedDate DESC];
    }

    /**
     * Método que recupera las ofertas que necesitan recalcular la visibilidad para zrm
     * *
     * @author dmonuz | 18/9/2023
     * @return  List<Opportunity>
     */
    public List<Opportunity> findOffersWithIncorrectVisibility() {

        List<Opportunity> result = new List<Opportunity>([SELECT Id, Account.Blocked__c, Owner.Profile.Name, IntermediaryId__c, 
                                                        IntermediaryId__r.IsPartner, IntermediaryId__r.IntermediaryGroup__c, 
                                                        IntermediaryId__r.IntermediaryGroup__r.IntermediaryWithUser__c, IntermediaryVisibilityAcc__c 
                                                        FROM Opportunity
                                                        WHERE (IntermediaryVisibilityAcc__c != null OR IntermediaryId__r.IntermediaryGroup__c != null)
                                                        AND (IntermediaryVisibilityForm__c = null
                                                        OR (IntermediaryId__r.IsPartner = true AND IntermediaryVisibilityForm__c = 'MainIntermediary')
                                                        OR (IntermediaryId__r.IsPartner = false AND IntermediaryVisibilityForm__c = 'CurrentIntermediary'))]);
        return result;
    }


    /**
     * Método que recupera las ofertas que necesitan recalcular la visibilidad para zrm a partir de una lista de ids
     * *
     * @author dmonuz | 18/9/2023
     * @return  List<Opportunity>
     */
    public List<Opportunity> findOffersWithIncorrectVisibilityByAccountId(Set<String> accountIds) {

        List<Opportunity> result = new List<Opportunity>();

        if (accountIds != null && !accountIds.isEmpty()) {
            result = new List<Opportunity>([SELECT Id, Account.Blocked__c, Owner.Profile.Name, IntermediaryId__c, 
                                                            IntermediaryId__r.IsPartner, IntermediaryId__r.IntermediaryGroup__c, 
                                                            IntermediaryId__r.IntermediaryGroup__r.IntermediaryWithUser__c, IntermediaryVisibilityAcc__c 
                                                            FROM Opportunity
                                                            WHERE AccountId IN :accountIds AND (IntermediaryVisibilityAcc__c != null OR IntermediaryId__r.IntermediaryGroup__c != null)
                                                            AND (IntermediaryVisibilityForm__c = null
                                                            OR (IntermediaryId__r.IsPartner = true AND IntermediaryVisibilityForm__c = 'MainIntermediary')
                                                            OR (IntermediaryId__r.IsPartner = false AND IntermediaryVisibilityForm__c = 'CurrentIntermediary'))]);
        }

        return result;

    }

    /**
     * Devuelve un String con la query para conseguir oportunidades de campaña de Venta Cruzada que no esten cerradas
     * *
     * @author  jgallaga | 07-09-2023
     * @return  String
     */
    public String findCrossSellingOpportunitiesNotClosed()
    {
        this.baseQuery
        .selectFields(new List<Schema.SObjectField> {Opportunity.AccountId, Opportunity.CampaignId, Opportunity.Campaign.Type})
        .addConditionEq(Opportunity.Campaign.Type, 'Cross Selling')
        .addConditionEq(Opportunity.IsClosed, false);

        return 'SELECT Accountid, Campaignid, Campaign.type, SalesProcess__c, Account.RecordType.DeveloperName FROM Opportunity WHERE (Campaign.Type = \'Cross Selling\') AND (IsClosed = false)';
    }
}