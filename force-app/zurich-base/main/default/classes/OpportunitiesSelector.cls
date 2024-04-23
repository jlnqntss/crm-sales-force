/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 23-04-2024
 * @last modified by  : amiranda
 **/
public with sharing class OpportunitiesSelector extends RecordsSelector
{
    private static final String OPPORTUNITY_INTERMEDIARY_GROUP= 'Opportunity.IntermediaryId__r.IntermediaryGroup__c';
    
    //#region Contructores
    public OpportunitiesSelector()
    {
        super( Opportunity.getSObjectType() );
    }

    private static final String OPPORTUNITY_INTERMEDIARY_GROUP= 'Opportunity.IntermediaryId__r.IntermediaryGroup__c';

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
     * @last modified by  : amiranda
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

    /**
     * Método que recupera las ofertas que un mediador no ha podido finalizar asociadas a una campaña de VC
     * *
     * @author dmonuz | 06/10/2023
     * @return  String query
     */
    public String findCrossSellingCampaignNotClosedOffer()
    {
        return 'SELECT Id, StageName, Sales_Loss_Reason__c ' +
               'FROM  Opportunity ' +
               'WHERE Campaign.Type = \'Cross Selling\' ' +
               'AND Campaign.EndDate <= TODAY ' +
               'AND StageName IN (\'Legit Lead\', \'App Submitted\', \'Quoted\') ' +
               'AND ZRM__c = true';
    }

    /**
     * @description Método selector que recupera aquellas ofertas que se encuentran
     * relacionadas con la campaña y con alguna de las cuentas pasada por parámetro.
     *
     * @author amiranda
     * @date 14-11-2023
     * @param accountIds Ids de cuentas relacionadas con las ofertas
     * @param campaignId Id de campañá sobre la que recuperar las ofertas
     * @param offerCloned Indica si se quiere filtar por ofertas clonadas o no clonadas.
     * En caso de que el valor sea 'null' no se aplica el filtro
     * @return List<Opportunity> Lista de ofertas recuperadas
     **/
    public List<Opportunity> selectByAccountIdsAndCampaignId(Set<Id> accountIds, Id campaignId, Boolean offerCloned)
    {
        List<Opportunity> opportunities = new List<Opportunity>();

        if ( !accountIds.isEmpty() && String.isNotBlank(campaignId) )
        {
            Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>
            {
                Opportunity.Name,
                Opportunity.AccountId,
                Opportunity.Sales_Loss_Reason__c,
                Opportunity.PendingIntermediaryReview__c,
                Opportunity.IsClosed
            };

            this.baseQuery
            .selectFields(fields)
            .toLabel('Sales_Loss_Reason__c', 'salesLossReasonLabel')
            .toLabel('StageName')
            .addConditionIn(Opportunity.AccountId, accountIds)
            .addConditionEq(Opportunity.CampaignId, campaignId);

            if (offerCloned != null)
            {
                this.baseQuery.addConditionEq(Opportunity.ClonedOfferForIntermediary__c, offerCloned);
            }

            opportunities = this.baseQuery
                            .enforceSecurity()
                            .run();
        }

        return opportunities;
    }

    /**
     * Método que recupera las ofertas segun el Lead y el Owner
     * *
     * @author arcortazar
     * @date 14/11/2023
     * @param Set<String> lista de identificadores de cuentas
     * @param Set<String> lista de identificadores de mediadores
     * @return  List<Opportunity>
     */
    public String findZRMtoReassign()
    {
        return 'SELECT Id, AccountId, Account.Name, Account.Phone, Account.PreferedContactStart__c, ' +
               'Account.PreferedContactEnd__c, Account.WebId__c, OwnerId, CreatedDate FROM Opportunity ' +
               'WHERE ZRM__c = true AND ReassignToContactCenter__c = true';

    }

    /**
     * Método que recupera las ofertas segun el Lead y el Owner
     * *
     * @author arcortazar
     * @date 14/11/2023
     * @param Set<String> lista de identificadores de cuentas
     * @param Set<String> lista de identificadores de mediadores
     * @return  List<Opportunity>
     */
    public List<Opportunity> findByAccountAndOwner(Set<Id> accountsIDs, Set<Id> usersIDs)
    {
        List<Opportunity> retorno = new List<Opportunity>();
        if ( accountsIDs != null && !accountsIDs.isEmpty()
             && usersIDs != null && !usersIDs.isEmpty() )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                Opportunity.Id,
                Opportunity.AccountId,
                Opportunity.OwnerId
            })
            .addConditionIn(Opportunity.AccountId, accountsIDs)
            .addConditionIn(Opportunity.OwnerId, usersIDs);

            retorno = (List<Opportunity>) this.baseQuery.run();
        }

        return retorno;
    }

    /**
     * Método que obtiene
     * @param Set<String> idsCampaign: listado de identificadores de campañas de las que se han eliminado miembros de campaña
     * @param Set<String> idsCampaignMember: listado de identificadores de miembros de campañas que se han eliminado
     * @return List<Opportunity>
     *
     * @author arcortazar
     * @createdDate 06/11/2023
     */
    public List<Opportunity> findByCampaignAndCampaignMember(Set<String> idsCampaign, Set<String> idsCampaignMembers)
    {
        List<Opportunity> retrievedOffers = new List<Opportunity>();

        if( idsCampaign != null && !idsCampaign.isEmpty() &&
            idsCampaignMembers != null && !idsCampaignMembers.isEmpty() )
        {
            this.baseQuery.selectFields(new Set<Schema.SObjectField> {
                Opportunity.Id,
                Opportunity.StageName,
                Opportunity.SalesProcess__c,
                Opportunity.Sales_Loss_Reason__c
            })
            .selectFields('Opportunity.CampaignId')
            .selectFields('Opportunity.Campaign.Type')
            .selectFields('Account.RecordType.DeveloperName')
            .addConditionIn(Opportunity.CampaignId, idsCampaign)
            .addConditionIn(Opportunity.AccountId, idsCampaignMembers)
            .addConditionEq(Opportunity.IsClosed, false);

            retrievedOffers =  (List<Opportunity>) this.baseQuery.run();
        }

        return retrievedOffers;
    }

    /**
     * Método devuelve las ofertas de un mediador, obviando las que tengan como cliente a cualquiera de los que se incluyen en la lista recibida (accountsIDsNotToQuery)
     * y excluyendo las que no pertenezcan a los campaign member recibidos (campaignMembers)
     *
     * SELECT AccountId FROM Opportunity
     * WHERE IntermediaryId__c = :intermediaryID
     *   AND Account.Blocked__c = false
     *   AND Account.Anonymized__c = false
     *   AND Blocked__c = false
     *   AND Anonymized__c = false
     *   AND AccountId != null
     * IF (accountIDsNotToQuery != null && !accountIDsNotToQuery.isEmpty())
     *   AND AccountId NOT IN :accountIDsNotToQuery
     * IF (campaignIDsToExcludeMembers != null && !campaignIDsToExcludeMembers.isEmpty())
     *   AND CampaignId NOT IN :campaignIDsToExcludeMembers
     *
     *
     * @author fpalomo
     * @date 04/04/2024
     *
     * @return List<Opportunities>
     */
    public List<Opportunity> getIntermediaryOtherOffersByCampaignMembers(Set<String> campaignIDsToExcludeMembers, Set<String> accountIDsNotToQuery, String intermediaryID)
    {

        this.baseQuery.selectFields(new Set<Schema.SObjectField>
        {
            Opportunity.AccountId
        })
        .addConditionEq(Opportunity.IntermediaryId__c, intermediaryID)
        .addConditionEq(Account.Blocked__c, false)
        .addConditionEq(Account.Anonymized__c, false)
        .addConditionEq(Opportunity.Blocked__c, false)
        .addConditionEq(Opportunity.Anonymized__c, false)
        .addConditionNotEq(Opportunity.AccountId, null);

        if ( accountIDsNotToQuery != null && !accountIDsNotToQuery.isEmpty() )
        {
            this.baseQuery.addConditionNotIn(Opportunity.AccountId, accountIDsNotToQuery);
        }

        if ( campaignIDsToExcludeMembers != null && !campaignIDsToExcludeMembers.isEmpty() )
        {
            this.baseQuery.addConditionNotIn(Opportunity.CampaignId, campaignIDsToExcludeMembers);
        }

        return (List<Opportunity>) this.baseQuery.run();
    }


    /**
     * Método que devuelve las ofertas de un mediador obviando o no una lista de clientes (uso en recálculo de visibilidad zrm)
     *
     * @author dmunoz
     * @date 18/03/2024
     *
     * @return List<Opportunities>
     */
    public List<Opportunity> getIntermediaryOtherOffers(Set<String> accountIdsNotToQuery, Account intermediary)
    {
        List<Opportunity> result = new List<Opportunity>();

        // Si no el mediador no tiene lista de clientes que obviar obtengo todas las ofertas
        if ( intermediary != null && accountIdsNotToQuery != null && !accountIdsNotToQuery.isEmpty() )
        {

            result = new List<Opportunity>([SELECT Id, AccountId FROM Opportunity
                                            WHERE IntermediaryId__c = : intermediary.Id
                                                                      AND AccountId NOT IN: accountIdsNotToQuery
                                                                      AND Account.Blocked__c = FALSE
                                                                                               AND Account.Anonymized__c = FALSE
                                                                                                                           AND Blocked__c = FALSE
                                                                                                                                            AND Anonymized__c = FALSE
                                                                                                                                                                AND AccountId != NULL]);

        }
        else if ( intermediary != null && accountIdsNotToQuery != null && accountIdsNotToQuery.isEmpty() )
        {
            result = new List<Opportunity>([SELECT Id, AccountId FROM Opportunity
                                            WHERE IntermediaryId__c = : intermediary.Id
                                                                      AND Account.Blocked__c = FALSE
                                                                                               AND Account.Anonymized__c = FALSE
                                                                                                                           AND Blocked__c = FALSE
                                                                                                                                            AND Anonymized__c = FALSE
                                                                                                                                                                AND AccountId != NULL]);
        }

        return result;
    }


    /**
     * Método que devuelve las ofertas de una agrupacion obviando o no una lista de clientes (uso en recálculo de visibilidad zrm)
     *
     * @author dmunoz
     * @date 18/03/2024
     *
     * @return List<Opportunities>
     */
    public List<Opportunity> offersClientsFromIntermediaryGroup(Set<String> accountIdsToQuery, String intermediaryGroupId)
    {

        List<Opportunity> result = new List<Opportunity>();

        if ( accountIdsToQuery != null && !accountIdsToQuery.isEmpty() && intermediaryGroupId != null && String.isNotEmpty(intermediaryGroupId) )
        {

            result = new List<Opportunity>([SELECT Id, AccountId FROM Opportunity
                                            WHERE IntermediaryId__r.IntermediaryGroup__c = : intermediaryGroupId
                                                                                           AND AccountId IN: accountIdsToQuery
                                                                                           AND Account.Blocked__c = FALSE
                                                                                                                    AND Account.Anonymized__c = FALSE
                                                                                                                                                AND Blocked__c = FALSE
                                                                                                                                                                 AND Anonymized__c = FALSE
                                                                                                                                                                                     AND AccountId != NULL]);

        }
        else if ( accountIdsToQuery != null && accountIdsToQuery.isEmpty() && intermediaryGroupId != null && String.isNotEmpty(intermediaryGroupId) )   // en caso que no haya elementos en accountIdsToQuery traemos todos los registros
        {
            result = new List<Opportunity>([SELECT Id, AccountId FROM Opportunity
                                            WHERE IntermediaryId__r.IntermediaryGroup__c = : intermediaryGroupId
                                                                                           AND Account.Blocked__c = FALSE
                                                                                                                    AND Account.Anonymized__c = FALSE
                                                                                                                                                AND Blocked__c = FALSE
                                                                                                                                                                 AND Anonymized__c = FALSE
                                                                                                                                                                                     AND AccountId != NULL]);
        }

        return result;
    }


    /**
     * Método que devuelve las ofertas de una agrupacion obviando o no una lista de clientes (uso en recálculo de visibilidad zrm)
     *
     * @author dmunoz
     * @date 18/03/2024
     *
     * @return List<Opportunities>
     */
    public List<Opportunity> offersClientsFromIntermediaryGroupExcludeAccountIds(Set<String> accountIdsToQuery, String intermediaryGroupId)
    {

        List<Opportunity> result = new List<Opportunity>();

        if ( accountIdsToQuery != null && !accountIdsToQuery.isEmpty() && intermediaryGroupId != null && String.isNotEmpty(intermediaryGroupId) )
        {

            result = new List<Opportunity>([SELECT Id, AccountId FROM Opportunity
                                            WHERE IntermediaryId__r.IntermediaryGroup__c = : intermediaryGroupId
                                                                                           AND AccountId NOT IN: accountIdsToQuery
                                                                                           AND Account.Blocked__c = FALSE
                                                                                                                    AND Account.Anonymized__c = FALSE
                                                                                                                                                AND Blocked__c = FALSE
                                                                                                                                                                 AND Anonymized__c = FALSE
                                                                                                                                                                                     AND AccountId != NULL]);

        }

        return result;
    }


    /**
     * Obtenemos las polizas de un mediador y las de una agrupacion con excepcion de un conjunto de polizas (necesario para el calculo de visibilidad)
     * QUERY: 
     * SELECT Id, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c 
                                            FROM Opportunity 
                                            WHERE
                                            ID NOT IN: offersToExclude
                                            AND AccountId IN :accountIdsSet
                                            AND AccountId.Blocked__c = FALSE
                                            AND AccountId.Anonymized__c = FALSE
                                            AND (
                                                IntermediaryId__c IN :intermediaryIdsSet OR
                                                IntermediaryId__r.IntermediaryGroup__c IN :intermediaryGroupIdsSet
                                                )
                                            AND Blocked__c = FALSE
                                            AND Anonymized__c = FALSE
                                            AND AccountId != NULL
     * @author dmunoz
     * @date 08/04/2024
     * 
     * 
     */
    public List<Opportunity> selectByIntermediaryAndIntermediaryGroupExcludingOffers(Set<String> intermediaryIdsSet, Set<String> intermediaryGroupIdsSet, Set<String> accountIdsSet, Set<String> offersToExclude)
    {
        List<Opportunity> result = new List<Opportunity>();

        if (intermediaryIdsSet != null && !intermediaryIdsSet.isEmpty() && accountIdsSet != null && !accountIdsSet.isEmpty())
        {
            this.baseQuery.selectFields(new List<Schema.SObjectField>{
                Opportunity.Id,
                Opportunity.AccountId,
                Opportunity.IntermediaryId__c
            }).selectFields(OPPORTUNITY_INTERMEDIARY_GROUP);

            this.baseQuery                            
                            .addConditionNotIn(Opportunity.Id, offersToExclude)
                            .addConditionIn(Opportunity.AccountId, accountIdsSet)
                            .addConditionEq(Opportunity.Account.Blocked__c, FALSE)
                            .addConditionEq(Opportunity.Account.Anonymized__c, FALSE)
                            .addConditionEq(Opportunity.Blocked__c, FALSE)
                            .addConditionEq(Opportunity.Anonymized__c, FALSE)
                            .addConditionNotEq(Opportunity.AccountId, null);

            // si no tiene agrupación podemos traer solo 1 resultado
            if (intermediaryGroupIdsSet != null && intermediaryGroupIdsSet.isEmpty())
            {
                this.baseQuery.addConditionIn(Opportunity.IntermediaryId__c, intermediaryIdsSet)
                            .setLimit(1);
            }

            else
            {
                this.baseQuery.addCondition(Query.doOr(
                    Query.conditionIn('IntermediaryId__c', intermediaryIdsSet),
                    Query.conditionIn('IntermediaryId__r.IntermediaryGroup__c', intermediaryGroupIdsSet)
                ));
            }

            result = this.baseQuery.enforceSecurity().run();
        }        

        return result;
    }


    /**
     * Obtenemos las ofertas que han sufrido un cambio de mediador o cliente en las ultimas 24 horas y que el numero de reintentos sea menor al de la metadata
     * QUERY: 
     * SELECT Id, AccountId, IntermediaryId__c, ZRMMovementType__c, LastAccountId__c
                                            FROM Opportunity 
                                            WHERE
                                            LastDateIntermediaryOrAccountChange__c = YESTERDAY
                                            AND VisibilityRetry__c <= :numMaxRetries
                                            
     * @author dmunoz
     * @date 08/04/2024
     * 
     * 
     */
    public List<Opportunity> getOffersToProcessIntermediaryOrAccountChange(Integer numMaxRetries) {

        List<Opportunity> result = new List<Opportunity>();

        // añado un valor por defecto por si viniera nulo el parámetro
        if (numMaxRetries == null || numMaxRetries <= 0) {
            numMaxRetries = 3;
        }

        this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
                {
                    Opportunity.Id,
                    Opportunity.AccountId,
                    Opportunity.IntermediaryId__c,
                    Opportunity.ZRMMovementType__c,
                    Opportunity.LastAccountId__c,
                    Opportunity.VisibilityRetry__c
                }
            );

            this.baseQuery                            
                            .addConditionEq(Opportunity.LastDateIntermediaryOrAccountChange__c, Query.YESTERDAY)
                            .addConditionLe(Opportunity.VisibilityRetry__c, numMaxRetries);
           
            result = this.baseQuery.enforceSecurity().run();

        return result;
    }
    
    /**
     * Obtenemos las polizas de un mediador y las de una agrupacion con excepcion de un conjunto de polizas (necesario para el calculo de visibilidad)
     * QUERY:
     * SELECT Id, AccountId, IntermediaryId__c, IntermediaryId__r.IntermediaryGroup__c
                                            FROM Opportunity
                                            WHERE
                                            AND AccountId IN :accountIdsSet
                                            AND (
                                                IntermediaryId__c IN :intermediaryIdsSet OR
                                                IntermediaryId__r.IntermediaryGroup__c IN :intermediaryGroupIdsSet
                                                )
                                            AND ProductBranch__c IN :productBranchSet
                                            AND Stage IN ('Legit Lead', 'App Submitted')
                                            AND InfoQuoteNumber__c = null
                                            AND PotentialMatch__c = false
                                            AND CreatedDate = last_n_days: 60
     * @author dmunoz
     * @date 09/04/2024
     */
    public List<Opportunity> findMatchOffers(Set<String> productBranchSet, Set<String> accountIdsSet, Set<String> intermediaryIdsSet, Set<String> intermediaryGroupIdsSet) 
    {

        List<Opportunity> result = new List<Opportunity>();

        if ( intermediaryIdsSet != null && !intermediaryIdsSet.isEmpty() && accountIdsSet != null && !accountIdsSet.isEmpty() )
        {

            this.baseQuery.selectFields
            (
                new List<Schema.SObjectField>
            {
                Opportunity.Id,
                Opportunity.AccountId,
                Opportunity.IntermediaryId__c,
                Opportunity.ProductBranch__c,
                Opportunity.Description,
                Opportunity.CampaignId,
                Opportunity.CreatedDate
            }
            ).selectFields(OPPORTUNITY_INTERMEDIARY_GROUP);

            this.baseQuery
            .addConditionIn(Opportunity.AccountId, accountIdsSet)
            .addConditionIn(Opportunity.ProductBranch__c, productBranchSet)
            .addConditionIn(Opportunity.StageName, new Set<String> {'Legit Lead', 'App Submitted'})
            .addConditionEq(Opportunity.InfoQuoteNumber__c, null)
            .addConditionEq(Opportunity.PotentialMatch__c, false)
            .addConditionEq(Opportunity.CreatedDate, Query.last_n_days(60));

            // si la lista de agrupacion no está vacia buscamos en ambas
            if ( intermediaryGroupIdsSet != null && !intermediaryGroupIdsSet.isEmpty() )
            {
                Query.Condition orCondition = Query.doOr(
                    Query.conditionIn(Opportunity.IntermediaryId__c, intermediaryIdsSet),
                    Query.conditionIn(OPPORTUNITY_INTERMEDIARY_GROUP, intermediaryGroupIdsSet)
                    );

                this.baseQuery.addCondition(orCondition);
            }
            else
            {
                this.baseQuery.addConditionIn(Opportunity.IntermediaryId__c, intermediaryIdsSet);
            }

            result = this.baseQuery.enforceSecurity().run();
        }

        return result;
    }

    /**
    * @description Método que devuelve una query en formato String para recuperar
    * oportunidades que sean 'match potenciales' (PotentialMatch__c = true)
    * @author amiranda 
    * @date 10-04-2024 
    * @return String query en formato String
    **/
    public String getQueryStringPotentialMatchOpportunities()
    {
        Set<Schema.SObjectField> fields = new Set<Schema.SObjectField>
        {
            Opportunity.AccountId,
            Opportunity.IntermediaryId__c,
            Opportunity.Description,
            Opportunity.ProductBranch__c,
            Opportunity.CampaignId,
            Opportunity.CreatedDate
        };

        return this.baseQuery
               .selectFields(fields)
               .selectFields('Opportunity.IntermediaryId__r.IntermediaryGroup__c')
               .addConditionEq(Opportunity.PotentialMatch__c, true) 
               .enforceSecurity()
               .toQueryString();
    }
}