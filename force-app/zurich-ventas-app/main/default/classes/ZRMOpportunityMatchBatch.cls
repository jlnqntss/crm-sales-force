/**
 * @description       : Proceso batch que se encarga de procesar ofertas de ZRM
 * para hacer match contra oportunidades en SF a nivel de cliente y/o lead.
 * @author            : amiranda
 * @date              : 23-04-2024
 * @last modified on  : 03/07/2024
 * @last modified by  : rserrano
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   22-04-2024   amiranda   Initial Version
 **/
public with sharing class ZRMOpportunityMatchBatch implements Database.Batchable<sObject>, Schedulable
{
    // #region Instance properties

    private static final String CLASS_NAME = 'ZRMOpportunityMatchBatch';

    private static final String SCOPE_OPPORTUNITY_MAP = 'ScopeMap';
    private static final String SCOPE_OPPORTUNITY_PRODUCT_BRANCH = 'ProductBranch';
    private static final String SCOPE_OPPORTUNITY_ACCOUNTID = 'AccountId';
    private static final String SCOPE_OPPORTUNITY_INTERMEDIARY = 'Intermediary';
    private static final String SCOPE_OPPORTUNITY_INTERMEDIARY_GROUP = 'IntermediaryGroup';

    private static Set<String> contactPoints = new Set<String>();
    private static Map<id, Opportunity> opportunitiesToUpdate = new Map<Id, Opportunity>();
    private static Map<id, Task> tasksToUpdate = new Map<id, Task>();
    private static Map<id, Event> eventsToUpdate = new Map<id, Event>();
    private static Map<Id, Opportunity> opportunitiesToDelete = new Map<Id, Opportunity>();
    private static Map<Id, Account> accountsByIdToDelete = new Map<Id, Account>();
    private static Map<Id, Competitor__c> competitorsToUpdate = new Map<Id, Competitor__c>();
    private static Map<String, String> matchedLeadToDeleteWithClientMap = new Map<String, String>(); // guarda el par lead - cliente el cual id de lead se ha marcado como candidato a su eliminación



    private String query
    {
        get
        {
            return new OpportunitiesSelector().getQueryStringPotentialMatchOpportunities();
        }
        set;
    }

    // #endregion

    // #region Constructors

    public ZRMOpportunityMatchBatch()
    {}

    public ZRMOpportunityMatchBatch(String query)
    {
        if( !String.isBlank(query) )
        {
            this.query = query;
        }
    }

    // #endregion

    // #region Batchable interface implemented methods

    /**
     * @description Método que se encarga de recupara los registros que serán
     * tratados en el método execute.
     * @author amiranda
     * @date 10-04-2024
     * @param bc Referencia del objeto que implementa la interfaz Database.BatchableContext.
     * @return Database.QueryLocator Conjunto de registros devueltos por 'Database.getQueryLocator'.
     **/
    public Database.QueryLocator start(Database.BatchableContext bc )
    {
        return Database.getQueryLocator(query);
    }

    /**
     * @description Método que se encarga del procesamiento de los registros recuperados
     * en el método start.
     * @author amiranda
     * @date 10-04-2024
     * @param bc Referencia del objeto que implementa la interfaz Database.BatchableContext.
     * @param opportunities Conjunto de registros del objeto Opportunity que se han recuperado
     * en el método start.
     **/
    public void execute(Database.BatchableContext bc, List<Opportunity> scope)
    {
        try
        {
            // 1º obtener los datos del scope para los siguientes métodos
            Map<String, Object> opportunityDataMap = getDataFromOpportunities(scope);

            // 2º Calcular merge de ofertas de cliente
            calculateClientOpportunitiesWithMatch(scope, opportunityDataMap);

            //3º Leads
            Map<Opportunity, Set<String> > offersByIdWithContactInfoData = getOpportunitiesWithContactInfoData( scope, (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_ACCOUNTID) );
            matchLeadWithOpportunities(offersByIdWithContactInfoData);
            // recalculo de registros de competencia que se han de mover al cliente con quien haya hecho match
            moveCompetitorsToMatchedAccount();

            // 4º Ejecutar DMLs
            executeDMLs();
        }
        catch(Exception e)
        {
            ErrorLogUtil.commitError(e, CLASS_NAME);
        }

    }

    /**
     * @description Método que se ejecuta al finalizar el batch.
     * @author amiranda
     * @date 10-04-2022
     * @param bc Referencia del objeto que implementa la inetrfaz Database.BatchableContext.
     **/
    public void finish(Database.BatchableContext bc)
    {
        // Tras finalizar con el proceso de las ofertas de ZRM se procesan las pólizas
        Database.executeBatch(new ZRMPolicyMatchBatch(), 50);
    }

    // #endregion

    // #region Schedulable interface implemented methods

    /**
     * @description Método que se ejecuta programáticamente. Puede ser ejecutado
     * desde Apex (System.schedule()) o desde "Programar Apex".
     * @author amiranda
     * @date 22-04-2024
     * @param SchedulableContext sc Referencia del objeto que implementa la
     * interfaz Schedulable.
     **/
    public void execute(SchedulableContext sc)
    {
        Database.executeBatch(new ZRMOpportunityMatchBatch(), 50);
    }

    // #endregion

    //#region calculo de merge de oferta cliente

    /**
     * Método que devueve los registros a actualizar del match de ofertas de cliente
     * @author dmunoz
     * @date 09/04/2024
     */
    @TestVisible
    private void calculateClientOpportunitiesWithMatch(List<Opportunity> scope, Map<String, Object> opportunityDataMap)
    {
        // 1º Obtener el mapa de match par las ofertas de scope
        Map<String, Opportunity> matchMap = getMatchOffersByParams(opportunityDataMap);

        // 2º match de ofertas
        mergeOffers( (Map<String, Opportunity>) opportunityDataMap.get(SCOPE_OPPORTUNITY_MAP), matchMap );
    }

    //#region Obtener datos y matcheo

    /**
     * Método que devueve a partir de la lista de ofertas los campos necesarios para buscar las ofertas coincidentes
     * @author dmunoz
     * @date 09/04/2024
     */
    @TestVisible
    private Map<String, Object> getDataFromOpportunities(List<Opportunity> scope)
    {
        Map<String, Object> result = new Map<String, Object>();
        Set<String> productBranchSet = new Set<String>(); // guarda los api name de ramo
        Set<String> accountIdSet = new Set<String>(); // guarda el id del cliente de la oferta, si lo ves conveninente lo cambias a codigo afiliación
        Set<String> intermediaryIdSet = new Set<String>(); // guarda los ids de los mediadores de las ofertas
        Set<String> intermediaryGroupIdSet = new Set<String>(); // guarda los ids de las agrupaciones de mediador de aquellos que tengan asociado una agrupación
        Map<String, Opportunity> scopeMap = new Map<String, Opportunity>(); // convierto la lista de ofertas en un mapa

        for (Opportunity offer: scope)
        {
            productBranchSet = addElementToSet(productBranchSet, offer.ProductBranch__c);
            accountIdSet = addElementToSet(accountIdSet, offer.AccountId);
            intermediaryIdSet = addElementToSet(intermediaryIdSet, offer.IntermediaryId__c);
            intermediaryGroupIdSet = addElementToSet(intermediaryGroupIdSet, offer.IntermediaryId__r.IntermediaryGroup__c);
            scopeMap.put(offer.Id, offer);
        }

        result.put(SCOPE_OPPORTUNITY_PRODUCT_BRANCH, productBranchSet);
        result.put(SCOPE_OPPORTUNITY_ACCOUNTID, accountIdSet);
        result.put(SCOPE_OPPORTUNITY_INTERMEDIARY, intermediaryIdSet);
        result.put(SCOPE_OPPORTUNITY_INTERMEDIARY_GROUP, intermediaryGroupIdSet);
        result.put(SCOPE_OPPORTUNITY_MAP, scopeMap);

        return result;
    }

    /**
     * Método que devueve a partir de unos parámetros las ofertas que coincidan con los siguientes criterios:
     * - Mismo Ramo
     * - Estado "No Iniciado", "Pendiente INFO"
     * - Mismo Código de Filiación (id cliente)
     * - Mismo mediador
     * - Misma Agrupacion
     * - Código oferta en blanco
     * - Registros de los pasados 2 meses
     *
     * AL recorrer las ofertas tenemos la siguiente lógica:
     * - Si para un mediador/agrupacion, cliente y ramo hay n ofertas nos quedamos con la que tenga informado el campo "CampaignId" (gana a todas), si no con la mas reciente.
     *
     * @author dmunoz
     * @date 09/04/2024
     * @return mapa con clave id oferta scope y oferta match
     */
    @TestVisible
    private Map<String, Opportunity> getMatchOffersByParams(Map<String, Object> opportunityDataMap)
    {
        Map<String, Opportunity> result = new Map<String, Opportunity>();

        // recupero la informacion de las ofertas
        Set<String> productBranchSet = (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_PRODUCT_BRANCH);
        Set<String> accountIdSet = (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_ACCOUNTID);
        Set<String> intermediaryIdSet = (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_INTERMEDIARY);
        Set<String> intermediaryGroupIdSet = (Set<String>) opportunityDataMap.get(SCOPE_OPPORTUNITY_INTERMEDIARY_GROUP);
        Map<String, Opportunity> scopeMap = (Map<String, Opportunity>) opportunityDataMap.get(SCOPE_OPPORTUNITY_MAP);

        // Ejecuto la consulta de ofertas match
        List<Opportunity> offersMatchQuery = ( new OpportunitiesSelector() ).findMatchOffers(productBranchSet, accountIdSet, intermediaryIdSet, intermediaryGroupIdSet);

        // Recorro los resultados para montar el mapa de resultado
        for ( Opportunity scopeOffer: scopeMap.values() )
        {
            for (Opportunity queryOffer: offersMatchQuery)
            {
                if ( matchConditions(scopeOffer, queryOffer) && checkMatchMap(result, scopeOffer, queryOffer) )
                {
                    result.put(scopeOffer.Id, queryOffer);
                }
            }
        }

        return result;
    }

    /**
     * Método que compara dos ofertas usando los criterios
     * - Mismo Ramo
     * - Mismo Código de Filiación (id cliente)
     * - Mismo mediador
     * - El resto de condiciones del match ya se hace en la query findMatchOffers por lo que solo tenemos que comparar estos datos
     *
     * AL recorrer las ofertas tenemos la siguiente lógica:
     * - Si para un mediador/agrupacion, cliente y ramo hay n ofertas nos quedamos con la que tenga informado el campo "CampaignId" (gana a todas), si no con la mas reciente.
     *
     * @author dmunoz
     * @date 09/04/2024
     * @return boolean
     */
    @TestVisible
    private Boolean matchConditions(Opportunity scopeOpportunity, Opportunity queryOpportunity)
    {
        Boolean result = false;

        if ( scopeOpportunity.ProductBranch__c != null
             && scopeOpportunity.ProductBranch__c.equals(queryOpportunity.ProductBranch__c)
             && scopeOpportunity.AccountId != null
             && scopeOpportunity.AccountId.equals(queryOpportunity.AccountId)
             && checkIntermediaryEquals(scopeOpportunity, queryOpportunity) )
        {
            result = true;
        }

        return result;
    }

    /**
     * Método que compara los mediadores de dos ofertas. Tenemos dos escenarios:
     * Los mediadores coinciden -> result true
     * Los mediadores no coinciden -> comprobar si esos mediadores tienen agrupacion y si es la misma -> result = true
     *
     * @author dmunoz
     * @date 09/04/2024
     * @return boolean
     */
    @TestVisible
    private Boolean checkIntermediaryEquals(Opportunity scopeOpportunity, Opportunity queryOpportunity)
    {
        Boolean result = false;

        if ( scopeOpportunity.IntermediaryId__c != null
             && scopeOpportunity.IntermediaryId__c.equals(queryOpportunity.IntermediaryId__c) )
        {
            result = true;

        }
        else if ( scopeOpportunity.IntermediaryId__r.IntermediaryGroup__c != null
                  && scopeOpportunity.IntermediaryId__r.IntermediaryGroup__c.equals(queryOpportunity.IntermediaryId__r.IntermediaryGroup__c) )
        {
            result = true;
        }

        return result;
    }


    /**
     * Método que una vez se ha comprobado que la oportunidad de la query es un match, si se añade al mapa de resultado. Para ello tenemos 3 condiciones:
     * . Si el mapa para la oferta del scope no tiene ningun match se añade la primera que haya pasado el filtro
     * - Si la oferta tiene id de campaña informado, gana a todas.
     * - Si el mapa resultado para la oferta scope no tiene ya una oferta con campaña informado nos quedamos con la más reciente
     *
     * @author dmunoz
     * @date 09/04/2024
     * @return boolean
     */
    @TestVisible
    private Boolean checkMatchMap(Map<String, Opportunity> matchMap, Opportunity scopeOffer, Opportunity queryOffer)
    {
        Boolean result = false;

        if ( !matchMap.containsKey(scopeOffer.Id) )
        {
            result = true;
        }
        else if ( queryOffer.CampaignId != null
                  && String.isNotEmpty(queryOffer.CampaignId) )
        {
            result = true;
        }
        else if (matchMap.containsKey(scopeOffer.Id)
                 && String.isEmpty(matchMap.get(scopeOffer.Id).CampaignId)
                 && queryOffer.CreatedDate < matchMap.get(scopeOffer.Id).createdDate)
        {
            result = true;
        }

        return result;
    }

    //#region Calculo de Match

    @TestVisible
    private void mergeOffers(Map<String, Opportunity> scopeMap, Map<String, Opportunity> matchOppByScopeId)
    {
        //Mapa que enlaza la oferta scope con la oferta que hace match
        Map<String, String> matchIdByScopeId = new Map<String, String>();

        Opportunity matchOffer;
        // recorrer el scope y ver si en el mapa existe algun resultado
        for ( Opportunity scopeOffer: scopeMap.values() )
        {
            if( matchOppByScopeId.containsKey(scopeOffer.Id) )
            {
                matchOffer = matchOppByScopeId.get(scopeOffer.Id);
                // 1º Mergeamos la oferta del match en la oferta del scope (ER) NOS QUEDAMOS CON LA OFERTA DE ER.
                scopeOffer = mergeOffer(scopeOffer, matchOffer);

                // 2º Identificar esa oferta para mover sus tareas y eventos
                matchIdByScopeId.put(scopeOffer.Id, matchOffer.Id);
                // 3º Marcamos a eliminar la oferta que ha hecho match
                if( !opportunitiesToDelete.containsKey(matchOffer.Id) )
                {
                    opportunitiesToDelete.put(matchOffer.Id, matchOffer);
                }
            }

            scopeOffer.PotentialMatch__c = false; //Desmarcamos para que no vuelva a pasar por el flujo
            opportunitiesToUpdate.put(scopeOffer.Id, scopeOffer);  //Añadimos la oferta modificada tenga match o no.
        }

        // Mover tareas y eventos de aquellas ofertas que si tienen un match
        tasksToUpdate = moveTasksToScopeOffers(matchIdByScopeId);
        eventsToUpdate = moveEventsToScopeOffers(matchIdByScopeId);
    }

    /**
     * Método que sobrescribe los campos "Description" y "CampaignId" de una oportunidad a otra y pasa a la etapa "Oferta Realizada"
     * @author igarcia
     * @param scopeOffer - La oferta donde se sobrescribira los campos
     * @param offerMatch - Oferta de donde se recogerá los campos
     *
     * @return scopeOffer - Se devuelve el scoppeOffer que pasa como parámetro pero con los campos modificados
     * @date 15/04/2024
     */
    @TestVisible
    private Opportunity mergeOffer(Opportunity scopeOffer, Opportunity offerMatch)
    {
        if( String.isNotBlank(offerMatch.Description) )
        {
            scopeOffer.Description = offerMatch.Description;
        }

        if( String.isNotBlank(offerMatch.CampaignId) )
        {
            scopeOffer.CampaignId = offerMatch.CampaignId;
        }

        scopeOffer.StageName = 'Quoted';

        return scopeOffer;
    }

    //#region Tasks & Events

    /**
     * Método que modifica el WhatId de las tareas relacionadas en las ofertas match(value) por la oferta scope(key)
     * @author igarcia
     * @date 15/04/2024
     */
    @TestVisible
    private Map<id, Task> moveTasksToScopeOffers(Map<String, String> matchIdByScopeId)
    {
        Map<Id, Task> result = new Map<Id, Task>();
        List<Task> relatedTasks = new TaskSelector().getTaskRelatedWithWhatId( matchIdByScopeId.values() );
        Map<String, List<SObject> > taskByOppMatchId = fillMapList(relatedTasks, Task.WhatId);
        Map<Id, Sobject> movedTasks = moveRelatedObjectToScopeOffers(matchIdByScopeId, taskByOppMatchId, Task.WhatId);

        for ( SObject obj: movedTasks.values() )
        {
            result.put(obj.Id, (Task) obj);
        }

        return result;
    }


    /**
     * Método que modifica el WhatId de los eventos relacionados en las ofertas match(value) por la oferta scope(key)
     * @author igarcia
     * @date 15/04/2024
     */
    @TestVisible
    private Map<id, Event> moveEventsToScopeOffers(Map<String, String> matchIdByScopeId)
    {
        Map<Id, Event> result = new Map<Id, Event>();
        List<Event> relatedEvents = new EventSelector().getRelatedEventsFromRecord( matchIdByScopeId.values() );
        Map<String, List<SObject> > eventByOppMatchId = fillMapList(relatedEvents, Event.WhatId);
        Map<Id, Sobject> movedEvents = moveRelatedObjectToScopeOffers(matchIdByScopeId, eventByOppMatchId, Event.WhatId);

        for ( SObject obj: movedEvents.values() )
        {
            result.put(obj.Id, (Event) obj);
        }

        return result;
    }


    /**
     * Método que cambia los registros de una lista relacionada de una oportunidad match a una oportunidad scope
     * @date: 23-04-2024
     * @author  igarcia
     */
    @TestVisible
    private Map<id, Sobject> moveRelatedObjectToScopeOffers(Map<String, String> matchIdByScopeId, Map<String, List<SObject> > sObjectByOppMatchId, Schema.SObjectField relatedField)
    {
        Map<id, SObject> movedSobject = new Map<id, SObject>();

        String matchId;
        for( String scopeId : matchIdByScopeId.keySet() )
        {
            matchId = matchIdByScopeId.get(scopeId);

            if( sObjectByOppMatchId.containsKey(matchId) )
            {
                for( SObject obj : sObjectByOppMatchId.get(matchId) )
                {
                    obj.put(relatedField, scopeId);
                    movedSobject.put(obj.Id, obj);
                }
            }
        }

        return movedSobject;
    }

    /**
     * Método que transforma una lista introducida como parámetro en un mapa cuya "Key" sea el campo especificado
     * @date: 23-04-2024
     * @author  igarcia
     */
    @TestVisible
    private Map<String, List<Sobject> > fillMapList(List<Sobject> valuesSet, Schema.SObjectField key)
    {
        Map<String, List<Sobject> > mapList = new Map<String, List<Sobject> >();

        if( valuesSet == null || valuesSet.isEmpty() )
        {
            return mapList;
        }

        String mapkey;

        for(Sobject o : valuesSet)
        {
            mapkey = (String) o.get(key);

            if( !mapList.containsKey(mapkey) )
            {
                mapList.put( mapkey, new List<Sobject>() );
            }
            mapList.get(mapkey).add(o);
        }

        return mapList;
    }

    //#region Leads

    /**
     * @description Método que permite construir un mapa con las oportunidades
     * que potencialmente pueden hacer match relacionadas con la información
     * de contacto (teléfono y/o email) almacenada en la cuenta relacionada
     * (ContactPointEmail y ContactPointPhone).
     *
     * @author amiranda
     * @date 16-04-2024
     * @param opportunities Lista de oportunidades que potencialmente pueden
     * hacer match (ofertas que llegan de info procedentes del metodo start)
     * @return Map<Id, Map<Opportunity, Set<String>>> Mapa de oportunidades con
     * la relación entre oportunidades que potencialmente hacen match con los
     * datos de contacto (teléfono y/o email)
     **/
    @TestVisible
    private Map<Opportunity, Set<String> > getOpportunitiesWithContactInfoData(List<Opportunity> opportunities, Set<String> accountIdSet)
    {
        Map<Opportunity, Set<String> > offersById = new Map<Opportunity, Set<String> >();

        // Se recuperan las cuentas relacionadas con las ofertas junto a los registros 'ContactPointPhone' y 'ContactPointEmail'
        Map<Id, Account> offersRelatedAccounts = new Map<Id, Account>( new AccountsSelector().selectByIdWithCPPhoneAndCPEmail(accountIdSet) );

        // Se agrupan los datos de contacto por oportunidad
        for (Opportunity opportunity : opportunities)
        {
            Account offerRelatedAccount = offersRelatedAccounts?.get(opportunity.AccountId);

            if (offerRelatedAccount != null)
            {
                Set<String> offersRelatedAccountContactInfo = new Set<String>();

                for (ContactPointPhone cpp : offerRelatedAccount.ContactPointPhones)
                {
                    offersRelatedAccountContactInfo.add(cpp.TelephoneNumber);
                }

                for (ContactPointEmail cpe : offerRelatedAccount.ContactPointEmails)
                {
                    offersRelatedAccountContactInfo.add(cpe.EmailAddress);
                }

                contactPoints.addAll(offersRelatedAccountContactInfo);
                offersById.put(opportunity, offersRelatedAccountContactInfo);
            }
        }

        return offersById;
    }

    /**
     * @description Método que se encarga de comprobar si existen oportunidades
     * a nivel de 'Lead' que hagan match. Si alguna oportunidad hace match, esta
     * se marca a eliminar y posteriormente se comprueba si el 'Lead' tiene alguna
     * oportunidad relacionada. Si no tiene, este se marca para eliminar.
     *
     * @author amiranda
     * @date 17-04-2024
     * @param contactDataInfoByOpportunity Mapa que contiene el conjunto de datos
     * de contacto (teléfono y email) por oportunidad que llega de info (opportunity del metodo start).
     **/
    @TestVisible
    private void matchLeadWithOpportunities(Map<Opportunity, Set<String> > contactDataInfoByOpportunity)
    {

        Set<String> recordTypeNames = new Set<String> {AccountsSelector.RT_NAME_LEAD};
        List<Account> leadsWithOpportunities = new AccountsSelector().selectByRTNameAndPhoneAndEmailWithOpportunities(
            contactPoints,
            recordTypeNames
            );

        List<Opportunity> offersToDelete = new List<Opportunity>();
        Map<String, String> scopeMDT = getScopeMDT();

        for ( Opportunity opportunity : contactDataInfoByOpportunity.keySet() )
        {
            Set<String> accountContactData = contactDataInfoByOpportunity.get(opportunity);

            for (Account lead : leadsWithOpportunities)
            {
                Boolean leadShouldBeDeleted = false;

                if ( leadMatchesOpportunity(lead, opportunity, accountContactData) )
                {
                    leadShouldBeDeleted = deleteMatchingOpportunities(lead, opportunity, offersToDelete, scopeMDT);
                }

                if (leadShouldBeDeleted)
                {
                    accountsByIdToDelete.put(lead.Id, lead);
                    matchedLeadToDeleteWithClientMap.put(lead.Id, opportunity.AccountId);
                }
                else if ( !offersToDelete.isEmpty() )
                {
                    // el metodo putAll es capaz de convertir una lista<SObject> en Map<Id, SObject
                    opportunitiesToDelete.putAll(offersToDelete);
                }
            }
        }
    }

    //#region DMLS

    /**
     * Una vez se ha calculado todas las actualizaciones en memoria, se ejecutan los dmls
     * @author amiranda
     * @date 17-04-2024
     **/
    @TestVisible
    private void executeDMLs()
    {
        // Actualizar todas las ofertas del scope, (incluye el merge de ofertas de cliente y el blanqueo del campo PotencialMatch__c)
        if ( !opportunitiesToUpdate.isEmpty() )
        {
            update opportunitiesToUpdate.values();
        }

        // Actualizar tareas que se han movido a la nueva que se ha mergeado
        if ( !tasksToUpdate.isEmpty() )
        {
            update tasksToUpdate.values();
        }

        // Actualizar eventos que se han movido a la nueva que se ha mergeado
        if ( !eventsToUpdate.isEmpty() )
        {
            update eventsToUpdate.values();
        }

        // Actualizar registros de competencia del lead a borrar a su cliente con el que ha hecho merge
        if ( !competitorsToUpdate.isEmpty() )
        {
            update competitorsToUpdate.values();
        }

        // Eliminar ofertas
        if ( !opportunitiesToDelete.isEmpty() )
        {
            delete opportunitiesToDelete.values();
        }

        // Eliminar leads
        if ( !accountsByIdToDelete.isEmpty() )
        {
            delete accountsByIdToDelete.values();
        }
    }

    //#region Metodos Auxiliares

    /**
     * @description Método que comprueba si la oportunidad y el lead hacen match
     * en base a los datos de contacto y la fecha de creación.
     *
     * @author amiranda
     * @date 17-04-2024
     * @param lead Cuenta de tipo 'Lead'
     * @param opportunity Oportunidad de ZRM que potencialmente puede hacer match
     * @param contactData Datos de contacto (teléfono y/o email) de la cuenta
     * relacionada con la Oportunidad
     * @return Boolean Indica si ha hecho match con el Lead
     **/
    private Boolean leadMatchesOpportunity(Account lead, Opportunity opportunity, Set<String> contactData)
    {
        return ( opportunity.CreatedDate > lead.CreatedDate
                 && ( contactData.contains(lead.Phone)
                      || contactData.contains(lead.PersonEmail) ) );
    }

    /**
     * @description Método que comprueba si alguna de las oportunidades relacionadas
     * con el lead han de eliminarse. Además, si todas ellas son marcadas a eliminar
     * nos indica que el 'Lead' relacionado con la oportunidad debe eliminarse.
     *
     * @author amiranda
     * @date 17-04-2024
     * @param lead Lead sobre el que se comprueban sus oportunidades
     * @param opportunity Oportunidad de ZRM que potencialmente puede hacer match
     * @param offersToDelete Lista de ofertas a eliminar
     * @return Boolean Indica si la cuenta de tipo 'Lead' relacionada con las
     * oportunidades ha de eliminarse
     **/
    @TestVisible
    private Boolean deleteMatchingOpportunities(Account lead, Opportunity opportunity, List<Opportunity> offersToDelete, Map<String, String> scopeMDT)
    {
        Set<String> opportunityMatchStages = new Set<String> {'Legit Lead', 'App Submitted'};

        // Se asume que el lead no tienen oportunidades relacionadas y por lo tanto se elimina
        Boolean leadShouldBeDeleted = true;

        // Se comprueba si alguna de las oportunidad relacionadas con la cuenta de tipo 'Lead' hace match
        for (Opportunity leadOpportunity : lead.Opportunities)
        {
            if ( checkIntermediaryEquals(opportunity, leadOpportunity)
                 && opportunityMatchStages.contains(leadOpportunity.StageName)
                 && checkIsZRM(leadOpportunity, scopeMDT) )
            {
                if( !offersToDelete.contains(leadOpportunity) )
                {
                    offersToDelete.add(leadOpportunity);
                    opportunity.SalesProcess__c = 'L';
                }
            }
            else
            {
                // El Lead tiene al menos una oportunidad que no hace match, por lo tanto no se debe eliminar
                leadShouldBeDeleted = false;
            }
        }
        return leadShouldBeDeleted;
    }

    /**
     * Método que comprueba si una oferta es de zrm
     * @author dmunoz
     * @date 09/04/2024
     */
    @TestVisible
    private Boolean checkIsZRM(Opportunity offer, Map<String, String> scopeMDT)
    {
        Boolean result = false;

        if (offer.ZRM__c == true)
        {
            result = true;
        }
        else if ( String.isBlank(offer.BusinessCode__c) || 'Ventas'.equals( scopeMDT?.get(offer.BusinessCode__c) ) )
        {
            result = true;
        }

        return result;
    }

    /**
     * Método que obtiene el valor de ventas de la metadata de scope (BusinessCode)
     * @author dmunoz
     * @date 09/04/2024
     */
    @TestVisible
    private Map<String, String> getScopeMDT()
    {
        Map<String, String> result = new Map<String, String>();

        List<Scope_Setting__mdt> scopeMDT = Scope_Setting__mdt.getAll().values();

        for(Scope_Setting__mdt scope : scopeMDT)
        {
            result.put(scope.BusinessCode__c, scope.Scope__c);
        }

        return result;
    }


    /**
     * Método que inserta en un conjunto si el valor seleccionado no es vacío o nulo
     * @author dmunoz
     * @date 09/04/2024
     */
    @TestVisible
    private Set<String> addElementToSet(Set<String> result, String value)
    {
        if ( value != null && String.isNotEmpty(value) )
        {
            result.add(value);
        }
        return result;
    }


    /**
     * Método que transfiere las competencias de un lead a un cliente para ello se modifica el valor de la relacion del lkp de competencia
     * usando el mapa matchedLeadToDeleteWithClientMap <IdLead, IdCliente> que relaciona el lead que se va a borrar con el cliente con el que ha hecho match
     * @author dmunoz
     * @date 07/10/2024
     */
    private void moveCompetitorsToMatchedAccount()
    {
        //Obtiene Ids de Leads:
        List<String> leadIds = new List<String>( matchedLeadToDeleteWithClientMap.keySet() );

        //Obtiene todas las competencias vinculadas a las cuentas de leads implicadas
        List<Competitor__c> relatedComptetitors = new CompetitorsSelector().getCompetitorsRelatedWithAccauntIds( leadIds );

        //Actualiza campo Id de cuenta de cada competencia
        for (Competitor__c competitor : relatedComptetitors)
        {
            // Verifica si el campo Account__c del Competitor coincide con alguna clave del mapa
            if ( matchedLeadToDeleteWithClientMap.containsKey(competitor.Account__c) )
            {
                // Cambia el campo Account__c al nuevo valor del mapa
                competitor.Account__c = matchedLeadToDeleteWithClientMap.get(competitor.Account__c);
                competitorsToUpdate.put(competitor.Id, competitor);
            }
        }
    }
}