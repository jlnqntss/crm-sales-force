public without sharing class GenesysInteractionsService
{
    public static Integer version { get; set; }

    @TestVisible
    static final String MISSING_FIELDS_REQUIRED = 'some required fields are missing';
    @TestVisible
    static final String FILTER_NOT_DEFINED = 'filterBy value not defined';
    @TestVisible
    static final String SEARCHTYPE_NOT_DEFINED = 'searchType value not defined';

    @TestVisible
    static final String SCOPE_CODE_ALL = 'all';
    @TestVisible
    static final String SCOPE_CODE_ZE = 'ze';
    @TestVisible
    static final String SCOPE_CODE_KLINC = 'klinc';
    @TestVisible
    static final String SCOPE_CODE_CSM = 'csm';
    static final Map<String, String> SCOPE_NAMES_BY_CODE = new Map<String, String>
    {
        SCOPE_CODE_ALL  => 'General',
        SCOPE_CODE_ZE => 'Zurich Empresas',
        SCOPE_CODE_KLINC => 'Klinc',
        SCOPE_CODE_CSM => 'csm'
    };

    //#region Métodos públicos

    /**
     * Sirve a WS_GenesysAPIService
     * Implemental la lógica de iniciar una interacción:
     * 1º crea una tarea
     * 2º busca al cliente y su registro más antiguo
     * 3º consigue el Owner del registro y lo devuelve como el BestAgent
     * @author nescudero
     * @date 22/10/2020
     */
    public static Interaction initInteraction(Interaction request)
    {
        // 1 - Si el servicio no recibe el from, to o interactionType, devolverá un KO
        if ( String.isBlank(request.interactionId) || String.isBlank(request.interactionType) || String.isBlank(request.fromId) || String.isBlank(request.toId) || String.isBlank(request.lookFor) )
        {
            throw new GenesysInteractionsServiceException(MISSING_FIELDS_REQUIRED);
        }

        // 2 - Comprobar si se trata de un mediador y buscarlo
        if( request.scope == SCOPE_CODE_CSM )
        {
            findIntermediary(request);
        }
        // 3 - Resto de scopes
        else //FIXME: Refactorizar cuando se modifique el flow de ZE / ZE Orange para aceptar la estructura Agent
        {
            // 3.2 - Se identifica el mejor agente disponible - el método asigna en consencuencia el registro sobre el que realizar un screenPop
            findBestAgentFor(request);
        }

        // 4 - Se una tarea como registro de la interacción en cola
        createOnQueueInteraction(request);

        return request;
    }

    /**
     * WIP: Falta definir qué campos rellenar en la task
     * @author nescudero
     * @date 22/10/2020
     */
    public static String createOnQueueInteraction(Interaction interactionLog)
    {
        Id interactionRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                                     .get('Interaction')
                                     .getRecordTypeId();

        //WIP
        Task interactionTask = new Task(
            Subject = 'Llamada ' + Datetime.now().format(),
            Status = 'Nueva',
            Priority = 'Normal',
            CallObject = interactionLog.interactionId,
            RecordTypeId = interactionRecordTypeId,
            WhoId = interactionLog.customerId,
            TaskSubtype = 'Call',
            ANI__c = interactionLog.fromId,
            DNIS__c = interactionLog.toId
        );

        if(interactionLog.screenPopRecordId != null && Id.valueOf(interactionLog.screenPopRecordId).getSobjectType() != Contact.SobjectType)
        {
            interactionTask.WhatId = interactionLog.screenPopRecordId;
        }
        //se rellena el campo BestAgent de la Task con el ID del usuario del cual se va a pasar a genesys su email
        if(interactionLog.bestAgentId != null)
        {
            List<User> agents = new List<User>();
            agents = [SELECT Id, Email FROM User WHERE isActive = True AND Email = :interactionLog.bestAgentId];
            if(!agents.isEmpty())
            {
                interactionTask.BestAgent__c = agents[0].Id;
            }
        }

        insert interactionTask;

        interactionLog.callLogId = interactionTask.Id;

        return interactionTask.Id;
    }


    public static SearchResult findRelatedRecords(Interaction interactionLog)
    {
        return findRelatedRecords(
            interactionLog.interactionType == 'Outbound' ? interactionLog.toId : interactionLog.fromId,
            interactionLog.lookFor,
            interactionLog.scope
            );
    }

    /**
     * Busca los registros relacionados con la interacción, definidos como el último registro abierto
     * asociado a cada cliente del tipo definido por el método
     *
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    public static SearchResult findRelatedRecords(String searchFor, String lookFor, String scope)
    {
        SearchResult searchResults = new SearchResult();

        // 1 - Se realiza la búsqueda de contactos
        searchResults.names = findCustomers(searchFor);

        // 2 - Se busca sobre los registros relacionados
        Set<Id> relatedIds = new Set<Id>();

        for(Contact matchedContact : searchResults.names)
        {
            relatedIds.add(matchedContact.Id);
            relatedIds.add(matchedContact.AccountId);
        }

        switch on lookFor {
            when 'Opportunity' {
                List<Opportunity> opportunities = [SELECT Id, OwnerId, ContactId__c, isClosed, AccountId, CreatedDate, Owner.Email
                                                   FROM Opportunity
                                                   WHERE isClosed = FALSE
                                                                    AND (AccountId IN :relatedIds OR ContactId__c IN :relatedIds)
                                                                    AND Scope__c = :SCOPE_NAMES_BY_CODE.get(scope)
                                                                                   ORDER BY CreatedDate DESC];

                searchResults.relatedRecords = (List<SObject>) opportunities;
            }

            when 'Case' {
                List<Case> cases = [
                    SELECT
                    OwnerId,
                    AccountId,
                    ContactId,
                    isClosed,
                    CreatedDate,
                    Owner.Email
                    FROM Case
                    WHERE isClosed = FALSE
                                     AND (AccountId IN :relatedIds OR ContactId IN :relatedIds)
                                     ORDER BY CreatedDate DESC
                ];

                searchResults.relatedRecords = (List<SObject>) cases;
            }
        }

        return searchResults;
    }


    /**
     * Busca los registros relacionados con la interacción
     *
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    public static List<Contact> findCustomers(String searchFor)
    {
        Set<Id> matchedPersonIds = new Set<Id>();

        if (searchFor.contains('@') )
        {
            return new ContactsSelector().applyScope('all').findByEmail(new List<String> { searchFor });
        }

        return new ContactsSelector().applyScope('all').findByPhoneNumber(new List<String> { searchFor });
    }

    /**
     * 1. Si hay múltiples clientes => Tenemos que decidirlo. De momento, recordId=null y bestAgentId=null
       2. Si hay múltiples casos de un mismo cliente =>  RecordId=ID_CLIENTE y *bestAgentId="Case/opportutiny.Owner.Email" del último caso abierto => Si OWner es una cola null
       3. Si hay solo hay una coincidencia => RecordId=ID_CLIENTE y *bestAgentId="Case/opportutiny.Owner.Email"   => Si Owner es una cola null
     * @author nescudero
     * @date 23/10/2020
     */
    public static Interaction findBestAgentFor(Interaction interaction)
    {
        SearchResult searchResults = findRelatedRecords(interaction);
        Contact matchedContact = null;
        SObject matchedRecord = null;

        // 1 - Se considera como registros encontrados los primeros que se haya devuelto en las listas
        //     El BestAgent es el propietario del registro relacionado, y se toma su Id como el email
        if(!searchResults.names.isEmpty() )
        {
            matchedContact = searchResults.names[0];
            interaction.customerId = matchedContact.Id;
            interaction.screenPopRecordId = matchedContact.Id;
        }

        if(!searchResults.relatedRecords.isEmpty() )
        {
            matchedRecord = searchResults.relatedRecords[0];

            if(matchedRecord instanceof Opportunity)
            {
                Opportunity matchedOpty = (Opportunity) matchedRecord;

                interaction.screenPopRecordId = matchedOpty.AccountId;
                interaction.bestAgentId = matchedOpty.Owner.Email;
            }
            else if(matchedRecord instanceof Case)
            {
                Case matchedCase = (Case) matchedRecord;

                interaction.screenPopRecordId = matchedCase.AccountId;
                interaction.bestAgentId = matchedCase.Owner.Email;
            }
        }

        return interaction;
    }

    /**
     * Lanza una búsqueda con la configuración determinada por request
     *
     * @author jmartinezpisson
     * @change adelgado 20/11/2020 Añadida lógica para realizar la búsqueda aplicando los filtros de la request
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResult} Resultados devueltos por la búsqueda
     */
    public static SearchResult findPeopleBy(SearchRequest request)
    {
        // 1 - Comprobar que la request tiene informados todos los campos requeridos
        if ( String.isBlank(request.searchType) || String.isBlank(request.filterBy) || String.isBlank(request.value) || String.isBlank(request.scope) || String.isBlank(request.legalEntity) )
        {
            throw new GenesysPeopleServiceException(MISSING_FIELDS_REQUIRED);
        }

        SearchResult results = new SearchResult();

        // 2 - Realizar la búsqueda de registros en base a los filtros definidos en la request
        switch on request.filterBy
        {
            when 'customers'
            {
                results = findCustomersBy(request);
            }
            when 'intermediaries'
            {
                results = findIntermediariesBy(request);
            }
            /*when 'prospects'
            {
                //TODO - Implementar en el futuro con la lógica correspondiente
            }
            when 'partners'
            {
                //TODO - Implementar en el futuro con la lógica correspondiente
            }*/
            when else
            {
                throw new GenesysPeopleServiceException(FILTER_NOT_DEFINED);
            }
        }

        // 3 - Devolver los resultados obtenidos
        return results;
    }

    /**
     * Lanza una búsqueda con la configuración determinada por request
     *
     * @author adelgado
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResult} Resultados devueltos por la búsqueda
     */
    public static SearchResult findCustomersBy(SearchRequest request)
    {
        SearchResult results = new SearchResult();
        List<Account> accounts = new List<Account>();

        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = request.scope;

        switch on request.searchType
        {
            when 'phone'
            {
                accounts = AccountSearchService.findCustomersByPhoneNumber( new List<String>{request.value}, scope );
            }
            when 'email'
            {
                accounts = AccountSearchService.findCustomersByEmail( new List<String>{request.value}, scope );
            }
            when 'document'
            {
                accounts = AccountSearchService.findCustomersByDocumentId( new List<String>{request.value}, null, scope, null );
            }
            when 'policy_code'
            {
                accounts = AccountSearchService.findCustomersByPolicyNumber( new List<String>{request.value}, scope );

                if(accounts == null || accounts.isEmpty())
                {
                    accounts = AccountSearchService.findCustomersByQuoteNumber( new List<String>{request.value}, scope );
                }
            }
            /*when 'case_number'
            {
                //TODO - Implementar en el futuro con la lógica correspondiente
            }*/
            when else
            {
                throw new GenesysPeopleServiceException(SEARCHTYPE_NOT_DEFINED);
            }
        }

        if(accounts.size() == 1)
        {
            Account customer = accounts.get(0);
            results.screenPopRecordId = customer.Id;
            results.totalPolicies = customer.NumPolicies__pc != null ? Integer.valueOf(customer.NumPolicies__pc) : null;
            results.totalQuotes = customer.NumQuotes__pc != null ? Integer.valueOf(customer.NumQuotes__pc) : null;
        }

        return results;
    }

    /**
     * Lanza una búsqueda con la configuración determinada por request
     *
     * @author adelgado
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResult} Resultados devueltos por la búsqueda
     */
    public static SearchResult findIntermediariesBy(SearchRequest request)
    {
        SearchResult results = new SearchResult();
        List<Account> accounts = new List<Account>();

        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = request.scope;

        switch on request.searchType
        {
            when 'phone'
            {
                accounts = AccountSearchService.findIntermediariesByPhoneNumber( new List<String>{request.value}, scope );
            }
            when 'intermediary_code'
            {
                accounts = AccountSearchService.findIntermediariesByCode( new List<String>{request.value}, scope );
            }
            when else
            {
                throw new GenesysPeopleServiceException(SEARCHTYPE_NOT_DEFINED);
            }
        }

        if(accounts.size() == 1)
        {
            Account intermediary = accounts.get(0);

            results.screenPopRecordId = intermediary.Id;
            results.territoryCode = intermediary.ZoneCode__c;

            results.bestAgents = findBestAgents(new Intermediary(intermediary.Id, intermediary.CsmIndividualsManager__c, intermediary.CsmAdministrationManager__c));
        }

        return results;
    }

     /**
     * Genera una lista estructura Agent con los gestores preferentes del mediador
     *
     * @author adelgado
     * @date 24/11/2020
     */
    public static List<Agent> findBestAgents(Intermediary intermediary)
    {
        Set<Agent> bestAgents = new Set<Agent>();

        // 1 - Obtener los gestores de los casos abiertos asociados al mediador
        for(Case openCase : new CasesSelector().findOpenByAccount(new List<String>{intermediary.intermediaryId}))
        {
            bestAgents.add
            (
                new Agent(openCase.Owner.Email, true, false, false)
            );
        }

        // 2 - Comprobar si uno de los gestores con casos abiertos es el preferente del mediador para individuals
        Boolean exists = false;
        if(!String.isBlank(intermediary.individualsManager))
        {
            for(Agent agent : bestAgents)
            {
                if(agent.agentId.equalsIgnoreCase(intermediary.individualsManager))
                {
                    agent.isForIndividuals = true;
                    exists = true;
                    break;
                }
            }

            if(!exists)
            {
                bestAgents.add(new Agent(intermediary.individualsManager, false, true, false));
            }
        }

        // 3 - Comprobar si uno de los gestores con casos abiertos es el preferente del mediador para administración
        exists = false;
        if(!String.isBlank(intermediary.administrationManager))
        {
            for(Agent agent : bestAgents)
            {
                if(agent.agentId.equalsIgnoreCase(intermediary.administrationManager))
                {
                    agent.isForAdministrative = true;
                    exists = true;
                    break;
                }
            }

            if(!exists)
            {
                bestAgents.add(new Agent(intermediary.administrationManager, false, false, true));
            }
        }

        return new List<Agent>(bestAgents);
    }

    /**
     * Busca el mediador a partir de su ANI
     *
     * @author adelgado
     * @date 26/11/2020
     */
    public static Interaction findIntermediary(Interaction request)
    {
        SearchRequest searchRequest = new SearchRequest();
        searchRequest.searchType = 'phone';
        searchRequest.filterBy = 'intermediaries';
        searchRequest.value = request.fromId;
        searchRequest.scope = request.scope;

        request.caller = findIntermediariesBy(searchRequest);

        request.screenPopRecordId = request.caller.screenPopRecordId;

        return request;
    }

    //#endregion

    //#region Inner Classes

    /**
     * Representa una interacción de Genesys Cloud, enriquecida con información de Salesforce
     *
     * @author nescudero
     */
    public class Interaction
    {
        public String interactionId { get; set; }
        public String interactionType { get; set; }
        public String fromId { get; set; }
        public String toId { get; set; }
        public String queueId { get; set; }
        public String lookFor { get; set; }
        public String scope { get; set; }

        public String screenPopRecordId { get; set; }
        public String customerId { get; set; }
        public String callLogId { get; set; }
        public String bestAgentId { get; set; } //FIXME: Eliminar cuando se modifique el flow de ZE / ZE Orange
        public SearchResult caller { get; set; }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa una solicitud de búsqueda en CRM
     *
     * @author jmartinezpisson
     */
    public class SearchRequest
    {
        public String searchType;
        public String filterBy;
        public String lookFor;
        public String value;
        public String scope;
        public String legalEntity;

        public SearchRequest() {}
        public SearchRequest(Map<String, String> paramsByName)
        {
            this.searchType = paramsByName.get('searchType');
            this.filterBy = paramsByName.get('filterBy');
            this.value = paramsByName.get('value');
            this.scope = paramsByName.get('scope');
            this.legalEntity = paramsByName.get('legalEntity');
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa los resultados de búsqueda del CRM
     *
     * @author jmartinezpisson
     */
    public class SearchResult
    {
        public transient List<Contact> names;
        public transient List<SObject> relatedRecords;
        public String screenPopRecordId;
        public String territoryCode;
        public Integer totalPolicies;
        public Integer totalQuotes;
        public Agent[] bestAgents;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa la información del mediador
     *
     * @author adelgado
     */
    public class Intermediary
    {
        public String intermediaryId;
        public String individualsManager;
        public String administrationManager;

        public Intermediary(){}

        public Intermediary(String intermediaryId, String individualsManager, String administrationManager)
        {
            this.intermediaryId = intermediaryId;
            this.individualsManager = individualsManager;
            this.administrationManager = administrationManager;
        }
    }

    /**
     * Representa la información del agente en el CRM
     *
     * @author adelgado
     */
    public class Agent
    {
        public String agentId;
        public Boolean hasOpenWork;
        public Boolean isForIndividuals;
        public Boolean isForAdministrative;

        public Agent(String agentId, Boolean hasOpenWork, Boolean isForIndividuals, Boolean isForAdministrative)
        {
            this.agentId = agentId;
            this.hasOpenWork = hasOpenWork;
            this.isForIndividuals = isForIndividuals;
            this.isForAdministrative = isForAdministrative;
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    @TestVisible
    class GenesysInteractionsServiceException extends Exception {}

    @TestVisible
    class GenesysPeopleServiceException extends Exception {}
}