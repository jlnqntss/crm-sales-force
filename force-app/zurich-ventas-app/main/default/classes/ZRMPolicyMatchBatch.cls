public with sharing class ZRMPolicyMatchBatch implements Database.Batchable<sObject>
{
    // #region Instance properties

    private static final String CLASS_NAME = 'ZRMPolicyMatchBatch';

    private static final String SCOPE_POLICY_MAP = 'ScopeMap';
    private static final String SCOPE_POLICY_PRODUCT_BRANCH = 'ProductBranch';
    private static final String SCOPE_POLICY_ACCOUNTID = 'AccountId';
    private static final String SCOPE_POLICY_INTERMEDIARY = 'Intermediary';
    private static final String SCOPE_POLICY_INTERMEDIARY_GROUP = 'IntermediaryGroup';

    private static Set<String> contactPoints = new Set<String>();
    private static List<Policy__c> policiesToUpdate = new List<Policy__c>();
    private static List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
    private static List<Opportunity> opportunitiesToDelete = new List<Opportunity>();
    private static List<Account> accountsToDelete = new List<Account>();

    private String query
    {
        get
        {
            return new PoliciesSelector().getQueryStringPotentialMatchPolicies();
        }
        set;
    }

    // #endregion

    // #region Constructors

    public ZRMPolicyMatchBatch()
    {}

    public ZRMPolicyMatchBatch(String query)
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
    public void execute(Database.BatchableContext bc, List<Policy__c> scope)
    {
        try
        {
            // 1º obtener los datos del scope para los siguientes métodos
            Map<String, Object> policyDataMap = getDataFromPolicies(scope);

            // 2º Calculamos si para el existe una oferta que pueda hacer match con la póliza
            Map<String, Policy__c> policiesWithNoMatch = calculateClientOpportunitiesWithMatch(scope, policyDataMap);

            //3º Leads
            Map<Policy__c, Set<String> > policiesByIdWithContactInfoData = getPoliciesWithContactInfoData( policiesWithNoMatch.values(), (Set<String>) policyDataMap.get(SCOPE_POLICY_ACCOUNTID) );
            matchLeadWithOpportunities(policiesByIdWithContactInfoData);

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
        // do nothing
    }

    // #endregion

    //#region calculo de merge de oferta cliente

    /**
     * Método que devueve los registros a actualizar del match de ofertas de cliente. 
     * 
     * @return Devuelve el mapa de polizas que no han hecho match con una oferta para tener esas en cuenta para los leads
     * @author dmunoz
     * @date 09/04/2024
     */
    private Map<String, Policy__c> calculateClientOpportunitiesWithMatch(List<Policy__c> scope, Map<String, Object> opportunityDataMap)
    {
        Map<String, Policy__c> result = (Map<String, Policy__c>) opportunityDataMap.get(SCOPE_POLICY_MAP);

        // 1º Obtener el mapa de match para las polizas de scope <idPoliza, ofertamatch>
        Map<String, Opportunity> matchMap = getMatchOffersByParams(opportunityDataMap);

        // 2º match de ofertas
        result = mergePolicies(result, matchMap );

        return result;
    }

    //#region Obtener datos y matcheo

    /**
     * Método que devueve a partir de la lista de polizas los campos necesarios para buscar las polizas coincidentes
     * @author dmunoz
     * @date 09/04/2024
     */
    private Map<String, Object> getDataFromPolicies(List<Policy__c> scope)
    {
        Map<String, Object> result = new Map<String, Object>();
        Set<String> productBranchSet = new Set<String>(); // guarda los api name de ramo
        Set<String> accountIdSet = new Set<String>(); // guarda el id del cliente de la poliza, si lo ves conveninente lo cambias a codigo afiliación
        Set<String> intermediaryIdSet = new Set<String>(); // guarda los ids de los mediadores de las polizas
        Set<String> intermediaryGroupIdSet = new Set<String>(); // guarda los ids de las agrupaciones de mediador de aquellos que tengan asociado una agrupación
        Map<String, Policy__c> scopeMap = new Map<String, Policy__c>(); // convierto la lista de polizas en un mapa

        for (Policy__c policy: scope)
        {
            productBranchSet = addElementToSet(productBranchSet, policy.ProductId__r.GroupCode__c);
            accountIdSet = addElementToSet(accountIdSet, policy.PolicyHolder__c);
            intermediaryIdSet = addElementToSet(intermediaryIdSet, policy.IntermediaryId__c);
            intermediaryGroupIdSet = addElementToSet(intermediaryGroupIdSet, policy.IntermediaryId__r.IntermediaryGroup__c);
            scopeMap.put(policy.Id, policy);
        }

        result.put(SCOPE_POLICY_PRODUCT_BRANCH, productBranchSet);
        result.put(SCOPE_POLICY_ACCOUNTID, accountIdSet);
        result.put(SCOPE_POLICY_INTERMEDIARY, intermediaryIdSet);
        result.put(SCOPE_POLICY_INTERMEDIARY_GROUP, intermediaryGroupIdSet);
        result.put(SCOPE_POLICY_MAP, scopeMap);

        return result;
    }

    /**
     * Método que devueve a partir de unos parámetros las polizas que coincidan con los siguientes criterios:
     * - Mismo Ramo
     * - Estado "No Iniciado", "Pendiente INFO"
     * - Mismo Código de Filiación (id cliente)
     * - Mismo mediador
     * - Misma Agrupacion
     * - Código oferta en blanco
     * - Registros de los pasados 2 meses
     *
     * AL recorrer las polizas tenemos la siguiente lógica:
     * - Si para un mediador/agrupacion, cliente y ramo hay n polizas nos quedamos con la que tenga informado el campo "CampaignId" (gana a todas), si no con la mas reciente.
     *
     * @author dmunoz
     * @date 09/04/2024
     * @return mapa con clave id oferta scope y oferta match
     */
    private Map<String, Opportunity> getMatchOffersByParams(Map<String, Object> policyDataMap)
    {
        Map<String, Opportunity> result = new Map<String, Opportunity>();

        // recupero la informacion de las polizas
        Set<String> productBranchSet = (Set<String>) policyDataMap.get(SCOPE_POLICY_PRODUCT_BRANCH);
        Set<String> accountIdSet = (Set<String>) policyDataMap.get(SCOPE_POLICY_ACCOUNTID);
        Set<String> intermediaryIdSet = (Set<String>) policyDataMap.get(SCOPE_POLICY_INTERMEDIARY);
        Set<String> intermediaryGroupIdSet = (Set<String>) policyDataMap.get(SCOPE_POLICY_INTERMEDIARY_GROUP);
        Map<String, Policy__c> scopeMap = (Map<String, Policy__c>) policyDataMap.get(SCOPE_POLICY_MAP);

        // Ejecuto la consulta de ofertas match
        List<Opportunity> offersMatchQuery = ( new OpportunitiesSelector() ).findMatchOffers(productBranchSet, accountIdSet, intermediaryIdSet, intermediaryGroupIdSet);

        // Recorro los resultados para montar el mapa de resultado
        for ( Policy__c scopePolicy: scopeMap.values() )
        {
            for (Opportunity queryOffer: offersMatchQuery)
            {
                if ( matchConditions(scopePolicy, queryOffer) && checkMatchMap(result, scopePolicy, queryOffer) )
                {
                    result.put(scopePolicy.Id, queryOffer);
                }
            }
        }

        return result;
    }

    /**
     * Método que compara dos polizas usando los criterios
     * - Mismo Ramo
     * - Mismo Código de Filiación (id cliente)
     * - Mismo mediador
     * - El resto de condiciones del match ya se hace en la query findMatchOffers por lo que solo tenemos que comparar estos datos
     *
     * AL recorrer las polizas tenemos la siguiente lógica:
     * - Si para un mediador/agrupacion, cliente y ramo hay n polizas nos quedamos con la que tenga informado el campo "CampaignId" (gana a todas), si no con la mas reciente.
     *
     * @author dmunoz
     * @date 09/04/2024
     * @return boolean
     */
    private Boolean matchConditions(Policy__c scopePolicy, Opportunity queryOpportunity)
    {
        Boolean result = false;

        if ( scopePolicy.ProductId__c != null &&
             scopePolicy.ProductId__r.GroupCode__c != null
             && scopePolicy.ProductId__r.GroupCode__c.equals(queryOpportunity.ProductBranch__c)
             && scopePolicy.PolicyHolder__c != null
             && scopePolicy.PolicyHolder__c.equals(queryOpportunity.AccountId)
             && checkIntermediaryEquals(scopePolicy, queryOpportunity) )
        {
            result = true;
        }

        return result;
    }

    /**
     * Método que compara los mediadores de dos polizas. Tenemos dos escenarios:
     * Los mediadores coinciden -> result true
     * Los mediadores no coinciden -> comprobar si esos mediadores tienen agrupacion y si es la misma -> result = true
     *
     * @author dmunoz
     * @date 09/04/2024
     * @return boolean
     */
    private Boolean checkIntermediaryEquals(Policy__c scopePolicy, Opportunity queryOpportunity)
    {
        Boolean result = false;

        if ( scopePolicy.IntermediaryId__c != null
             && scopePolicy.IntermediaryId__c.equals(queryOpportunity.IntermediaryId__c) )
        {
            result = true;

        }
        else if ( scopePolicy.IntermediaryId__r.IntermediaryGroup__c != null
                  && scopePolicy.IntermediaryId__r.IntermediaryGroup__c.equals(queryOpportunity.IntermediaryId__r.IntermediaryGroup__c) )
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
    private Boolean checkMatchMap(Map<String, Opportunity> matchMap, Policy__c scopePolicy, Opportunity queryOffer)
    {
        Boolean result = false;

        if ( !matchMap.containsKey(scopePolicy.Id) )
        {
            result = true;
        }
        else if ( queryOffer.CampaignId != null
                  && String.isNotEmpty(queryOffer.CampaignId) )
        {
            result = true;
        }
        else if (matchMap.containsKey(scopePolicy.Id)
                 && String.isEmpty(matchMap.get(scopePolicy.Id).CampaignId)
                 && queryOffer.CreatedDate < matchMap.get(scopePolicy.Id).createdDate)
        {
            result = true;
        }

        return result;
    }

    //#region Calculo de Match

    /**
     * Método que se encarga de actualizar la póliza con la oferta que hace match.
     * 
     * @return mapa con las polizas que no han hecho match
     *
     * @author dmunoz
     * @date 09/04/2024
     */
    private Map<String, Policy__c> mergePolicies(Map<String, Policy__c> scopeMap, Map<String, Opportunity> matchOppByScopeId)
    {

        Map<String, Policy__c> result = new Map<String, Policy__c>(scopeMap);

        Policy__c policyToUpdate;
        Opportunity offerToUpdate;

        for ( String idPolicy: scopeMap.keySet() )
        {
            // inicializo el objeto policyToUpdate
            policyToUpdate = scopeMap.get(idPolicy);

            // compruebo si existe en el mapa de match una oferta que haga match
            if ( matchOppByScopeId.containsKey(idPolicy) )
            {
                offerToUpdate = matchOppByScopeId.get(idPolicy);
                
                // actualizo la relación de póliza con oferta
                policyToUpdate.OpportunityName__c = offerToUpdate.Id;

                // elimino la poliza del mapa resultado para no tenerla en cuenta en el proceso de leads
                result.remove(idPolicy);
            }

            policyToUpdate.Id = idPolicy; 
            policyToUpdate.PotentialMatch__c = false;

            // añado los registros a actualizar
            policiesToUpdate.add(policyToUpdate);
        }
        
        return result;
    }

    //#region Lead

    /**
     * @description Método que permite construir un mapa con las pólizas
     * que potencialmente pueden hacer match relacionadas con la información
     * de contacto (teléfono y/o email) almacenada en la cuenta relacionada
     * (ContactPointEmail y ContactPointPhone).
     *
     * @author amiranda
     * @date 16-04-2024
     * @param opportunities Lista de oportunidades que potencialmente pueden
     * hacer match
     * @return Map<Id, Map<Policy__c, Set<String>>> Mapa de pólizas con
     * la relación entre pólizas que potencialmente hacen match con los
     * datos de contacto (teléfono y/o email)
     **/
    private Map<Policy__c, Set<String> > getPoliciesWithContactInfoData(List<Policy__c> policies, Set<String> accountIdSet)
    {
        Map<Policy__c, Set<String> > policiesById = new Map<Policy__c, Set<String> >();

        // Se recuperan las cuentas relacionadas con las polizas junto a los registros 'ContactPointPhone' y 'ContactPointEmail'
        Map<Id, Account> policiesRelatedAccounts = new Map<Id, Account>( new AccountsSelector().selectByIdWithCPPhoneAndCPEmail(accountIdSet) );

        // Se agrupan los datos de contacto por póliza
        for (Policy__c policy : policies)
        {
            Account policyRelatedAccount = policiesRelatedAccounts?.get(policy.PolicyHolder__c);

            if (policyRelatedAccount != null)
            {
                Set<String> policiesRelatedAccountContactInfo = new Set<String>();

                for (ContactPointPhone cpp : policyRelatedAccount.ContactPointPhones)
                {
                    policiesRelatedAccountContactInfo.add(cpp.TelephoneNumber);
                }

                for (ContactPointEmail cpe : policyRelatedAccount.ContactPointEmails)
                {
                    policiesRelatedAccountContactInfo.add(cpe.EmailAddress);
                }

                contactPoints.addAll(policiesRelatedAccountContactInfo);
                policiesById.put(policy, policiesRelatedAccountContactInfo);
            }
        }

        return policiesById;
    }

    /**
     * @description Método que se encarga de comprobar si existen oportunidades
     * a nivel de 'Lead' que hagan match. Los Leads y las oportunidades relacionadas
     * se procesan del siguiente modo:
     *
     * 1. Lead que hace match sin oportunidades -> El Lead se debe eliminar
     * 2. Lead con oportunidades relacionadas (todas ellas de ZRM) -> El Lead se debe
     *    eliminar (sus oportunidades se eliminan de forma automática por lo que
     *    no deben incluirse como oportunidades a eliminar).
     * 3. Lead con oportunidades relacionadas (todas ellas de ZRM, tiene la
     *    oportunidad más reciente) -> Como la oportunidad que hace match por
     *    ser la más reciente pertenece a este Lead, el Lead no se puede eliminar (se mergeará).
     *    Lo que sí debe suceder, es que el resto de oportunidades relacionadas
     *    con el Lead se deben eliminar.
     * 4. Lead con oportunidades relacionadas (no todas son de ZRM) -> El Lead no
     *    se puede eliminar por tener oportunidades que no son de ZRM. Se eliminan
     *    únicamente las oportunidades que hacen match.
     *
     * @author amiranda
     * @date 17-04-2024
     * @param contactDataInfoByOpportunity Mapa que contiene el conjunto de datos
     * de contacto (teléfono y email) por póliza.
     **/
    private void matchLeadWithOpportunities(Map<Policy__c, Set<String> > contactDataInfoByPoilicy)
    {
        Set<String> recordTypeNames = new Set<String> {AccountsSelector.RT_NAME_LEAD};
        Map<Id, Account> leadsById = new Map<Id, Account>( new AccountsSelector().selectByRTNameAndPhoneAndEmailWithOpportunities(
                                                               contactPoints,
                                                               recordTypeNames
                                                               ) );

        for ( Policy__c policy : contactDataInfoByPoilicy.keySet() )
        {
            Set<String> accountContactData = contactDataInfoByPoilicy.get(policy);
            Map<Id, List<Opportunity> > opportunitiesByLeadId = new Map<Id, List<Opportunity> >();
            Set<Id> leadWithOpportunitiesNotRelatedToZRM = new Set<Id>();

            for ( Account lead : leadsById.values() )
            {
                // Se asume que el lead no tiene oportunidades relacionadas
                Boolean leadHasOpportunities = false;

                // Se comprueba si el Lead hace match
                if ( leadMatchesPolicy(lead, policy, accountContactData) )
                {
                    for (Opportunity opportunity : lead.Opportunities)
                    {
                        leadHasOpportunities = true;

                        // Se procesan las oportunidades que hagan match
                        processZRMOpportunity(policy, opportunity, opportunitiesByLeadId, leadWithOpportunitiesNotRelatedToZRM);
                    }
                }

                // Si el lead que hace match no tiene oportunidades relacionadas se elimina
                if (!leadHasOpportunities)
                {
                    accountsToDelete.add(lead);
                }
            }

            // Si ha habido match con alguna oportunidad, debemos quedarnos con la más reciente
            if ( !opportunitiesByLeadId.isEmpty() )
            {
                // Se obtiene la oportunidad "ganadora" que será actualizada
                Opportunity winningOpportunity = getWinningOpportunity(opportunitiesByLeadId);

                // Se relaciona la oportunidad "ganadora" con la póliza
                policy.OpportunityName__c = winningOpportunity.Id;

                // Se actualiza el tomador de la oportunidad "ganadora"
                updateWinningOpportunity(winningOpportunity, policy.PolicyHolder__c);

                // Se procesan el resto de las oportunidades relacionadas al lead de la oportunidad "ganadora"
                processRelatedOpportunities(opportunitiesByLeadId.remove(winningOpportunity.OldAccountId__c), winningOpportunity);


                // Se procesan el resto de Leads que han hecho match y tienen alguna oportunidad relacionada
                processRemainingLeads(opportunitiesByLeadId, leadsById, leadWithOpportunitiesNotRelatedToZRM);
            }
        }
    }

    //#region DMLS

    /**
     * Una vez se ha calculado todas las actualizaciones en memoria, se ejecutan los dmls
     * @author amiranda
     * @date 17-04-2024
     **/
    private void executeDMLs()
    {
        // Actualizar todas las ofertas del scope, (incluye el merge de ofertas de cliente y el blanqueo del campo PotencialMatch__c)
        if ( !opportunitiesToUpdate.isEmpty() )
        {
            update opportunitiesToUpdate;
        }

        // Actualizar polizas de scope
        if ( !policiesToUpdate.isEmpty() )
        {
            update policiesToUpdate;
        }

        // Eliminar ofertas
        if ( !opportunitiesToDelete.isEmpty() )
        {
            delete opportunitiesToDelete;
        }

        // Eliminar leads
        if ( !accountsToDelete.isEmpty() )
        {
            delete accountsToDelete;
        }
    }

    //#region Metodos Auxiliares

    /**
     * @description Método que comprueba si la póliza y el lead hacen match
     * en base a los datos de contacto y la fecha de creación.
     *
     * @author amiranda
     * @date 17-04-2024
     * @param lead Cuenta de tipo 'Lead'
     * @param opportunity Póliza de ZRM que potencialmente puede hacer match
     * @param contactData Datos de contacto (teléfono y/o email) de la cuenta
     * relacionada con la póliza
     * @return Boolean Indica si ha hecho match con el Lead
     **/
    private Boolean leadMatchesPolicy(Account lead, Policy__c policy, Set<String> contactData)
    {
        return ( policy.CreatedDate > lead.CreatedDate
                 && ( contactData.contains(lead.Phone)
                      || contactData.contains(lead.PersonEmail) ) );
    }

    /**
     * @description Método que se encarga de comprobar si la oportunidad pertenece
     * al aplicativo ZRM. Si es así, la oportunidad se añade a la lista del mapa
     * de oportunidades agrupadas por el Id del Lead relacionado. Por el contrario,
     * se añade el Lead relacionado con la oportunidad al conjunto de Ids de Leads.
     *
     * @author amiranda
     * @date 19-04-2024
     * @param policy Póliza del scope que no ha podido relacionarse con una
     * oportunidad a nivel de cliente.
     * @param opportunity Oportunidad relacionada con el Lead que ha hecho match.
     * @param opportunitiesByLeadId Mapa de oportunidades asociadas a los diferentes Leads
     * @param leadIds Conjunto de Leads con oportunidades relacionadas a otros.
     * aplicativos que no son ZRM.
     **/
    private void processZRMOpportunity(Policy__c policy, Opportunity opportunity, Map<Id, List<Opportunity> > opportunitiesByLeadId, Set<Id> leadIds)
    {
        Set<String> opportunityMatchStages = new Set<String> {'Legit Lead', 'App Submitted'};
        Map<String, String> scopeMDT = getScopeMDT();

        // Se comprueba si la oportunidad hace match con los criterios definidos
        if ( checkIntermediaryEquals(policy, opportunity)
             && opportunityMatchStages.contains(opportunity.StageName)
             && checkIsZRM(opportunity, scopeMDT) )
        {
            // Si hace match guardamos en un mapa la oportunidad relacionada con el lead
            if ( !opportunitiesByLeadId.containsKey(opportunity.AccountId) )
            {
                opportunitiesByLeadId.put( opportunity.AccountId, new List<Opportunity>() );
            }

            opportunitiesByLeadId.get(opportunity.AccountId).add(opportunity);
        }
        else
        {
            // Si tiene oportunidades relacionadas que no pertenecen a ZRM el lead no se puede eliminar
            leadIds.add(opportunity.AccountId);
        }
    }

    /**
     * @description Método que se encarga de comprobar cuál es la oportunidad más
     * reciente de todas las oportunidades relacionadas con los diferentes Leads.
     *
     * @author amiranda
     * @date 19-04-2024
     * @param opportunitiesByLeadId Mapa con las oportunidades relacionadas con un Lead
     * @return Opportunity más reciente
     **/
    private Opportunity getWinningOpportunity(Map<Id, List<Opportunity> > opportunitiesByLeadId)
    {
        List<Opportunity> opportunities = new List<Opportunity>();

        // Recopilamos todas las oportunidades de los diferentes leads
        for ( Id leadId : opportunitiesByLeadId.keySet() )
        {
            opportunities.addAll( opportunitiesByLeadId.get(leadId) );
        }

        Opportunity winningOpportunity;

        // Comprobamos cuál es la oportunidad más reciente
        for (Opportunity opportunity : opportunities)
        {
            if (winningOpportunity == null
                || winningOpportunity.CreatedDate < opportunity.CreatedDate)
            {
                winningOpportunity = opportunity;
            }
        }

        return winningOpportunity;
    }

    /**
     * @description Método que se encarga de procesar el resto de oportunidades
     * relacionadas con el Lead relacionado con la oportunidad "ganadora".
     *
     * @author amiranda
     * @date 19-04-2024
     * @param opportunities Lista con el resto de oportunidades relacionadas con
     * lead de la oportunidad "ganadora"
     * @param winningOpportunity Oportunidad "ganadora"
     **/
    private void processRelatedOpportunities(List<Opportunity> opportunities, Opportunity winningOpportunity)
    {
        // Las oportunidades que no coinciden con la oportunidad "ganadora" se añaden a eliminar
        for (Opportunity opportunity : opportunities)
        {
            if ( winningOpportunity.AccountId  != opportunity.AccountId)
            {
                opportunitiesToDelete.add(opportunity);
            }
        }
    }

    /**
     * @description Método que se encarga de actualizar tanto el tomador actual
     * (tomador de la póliza) como el tomador anterior (el lead inicialmente
     * relacionado con la oportunidad) de la oportunidad "ganadora".
     *
     * @author amiranda
     * @date 19-04-2024
     * @param winningOpportunity Oportunidad "ganadora".
     * @param policyHolder Id del tomador de la póliza
     **/
    private void updateWinningOpportunity(Opportunity winningOpportunity, Id policyHolder)
    {
        // Modificamos el nuevo y antiguo tomador de la póliza "ganadora"
        winningOpportunity.OldAccountId__c = winningOpportunity.AccountId;
        winningOpportunity.AccountId = policyHolder;
        opportunitiesToUpdate.add(winningOpportunity);
    }

    /**
     * @description Método que se encarga de procesar el resto de Leads que han
     * hecho match. Si el lead tiene únicamente oportunidades de ZRM, se elimina
     * el lead (como consecuencia se eliminan sus oportunidades relacioandas). Si
     * por el contrario tiene oportunidades de otro aplicativo, solamente se
     * eliminan las oportunidades de ZRM.
     *
     * @author amiranda
     * @date 19-04-2024
     * @param opportunitiesByLeadId Mapa con las oportunidades relacionadas a
     * los diferentes leads.
     * @param leadIds Conjunto de Ids de los leads que tienen oportunidades relacionadas
     * de otros aplicativos.
     **/
    private void processRemainingLeads(Map<Id, List<Opportunity> > opportunitiesByLeadId, Map<Id, Account> leadsById, Set<Id> leadIds)
    {
        // Se procesan el resto de leads que han hecho match
        for ( Id leadId : opportunitiesByLeadId.keySet() )
        {
            // Si el lead tiene oportunidades que no son de ZRM relacionadas solamente se eliminan sus oportunidades
            if ( leadIds.contains(leadId) )
            {
                opportunitiesToDelete.addAll( opportunitiesByLeadId.get(leadId) );
            }
            else
            {
                // Si no tiene otras oportunidades, se elimina el lead. Como consecuencia, todas sus oportunidades se eliminarán.
                accountsToDelete.add( leadsById.get(leadId) );
            }
        }
    }

    /**
     * Método que comprueba si una oferta es de zrm
     * @author dmunoz
     * @date 09/04/2024
     */
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
    private Set<String> addElementToSet(Set<String> result, String value)
    {
        if ( value != null && String.isNotEmpty(value) )
        {
            result.add(value);
        }
        return result;
    }
}
