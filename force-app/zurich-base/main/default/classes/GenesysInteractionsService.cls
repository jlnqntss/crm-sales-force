/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @modified on  : 06-06-2023
 * @modified by  : aberuete
 * @last modified on  : 22-05-2024
 * @last modified by  : jfherrero
**/
public with sharing class GenesysInteractionsService
{
    public static Integer version { get; set; }

    @TestVisible
    static final String MISSING_FIELDS_REQUIRED = 'Some required fields are missing';
    static final String MISSING_FIELDS_ERROR =': searchType, filterBy and value. Payload: ';
    @TestVisible
    static final String FILTER_NOT_DEFINED = 'filterBy value not defined';
    @TestVisible
    static final String SEARCHTYPE_NOT_DEFINED = 'searchType value not defined';

    @TestVisible
    static final String NO_QUEUE_MISSED_CALLS = 'There is no task queue Missed Calls';
    @TestVisible
    static final String TASK_QUEUE = 'Missed Calls';

    //Refactorización
    static final String ASSET_REGISTRATION_NUMBER = 'InsuredObject__r.RegistrationNumber__c';
    static final String POLICY_TYPE = 'Policy__r.PolicyType__c';
    static final String POLICY_NUMBER = 'Policy__r.Name';
    static final String POLICY_BRANCH = 'Policy__r.ProductId__r.GroupDescription__c';
    static final String POLICY_PARTNER_SF_CODE = 'Policy__r.Partner__r.PartnerSFCode__c';
    static final String POLICY_PARTNER_SECTOR = 'Policy__r.Partner__r.PartnerSector__c';
    static final String POLICY_PARTNER_NAME = 'Policy__r.Partner__r.GrandparentBusinessName__c';
    static final String POLICY_INTERMEDIARY_CODE = 'Policy__r.IntermediaryId__r.INFOIntermediaryCode__c';
    static final String POLICY_INTERMEDIARY_MOBILE_PHONE = 'Policy__r.IntermediaryId__r.MainMobilePhone__c';
    static final String POLICY_INTERMEDIARY_PHONE = 'Policy__r.IntermediaryId__r.Phone';
    static final String POLICY_INTERMEDIARY_MAIL = 'Policy__r.IntermediaryId__r.MainEmail__c';
    static final String POLICY_INTERMEDIARY_CHANNEL = 'Policy__r.IntermediaryId__r.Channel__c';
    static final String POLICY_INTERMEDIARY_SEGMENT = 'Policy__r.IntermediaryId__r.Segment__c';
    static final String INTERMEDIARY_MOBILE_PHONE = 'IntermediaryId__r.MainMobilePhone__c';
    static final String INTERMEDIARY_PHONE = 'IntermediaryId__r.Phone';
    static final String INTERMEDIARY_MAIL = 'IntermediaryId__r.MainEmail__c';
    static final String INTERMEDIARY_CHANNEL = 'IntermediaryId__r.Channel__c';
    static final String INTERMEDIARY_SEGMENT = 'IntermediaryId__r.Segment__c';
    static final String INTERMEDIARY_CODE = 'IntermediaryId__r.INFOIntermediaryCode__c';
    static final String PRODUCT_GROUP_DESCRIPTION = 'ProductId__r.GroupDescription__c';
    static final String PARTNER_SECTOR = 'Partner__r.PartnerSector__c';
    static final String PARTNER_SF_CODE = 'Partner__r.PartnerSFCode__c';
    static final String PARTNER_GRANDPARENT_BUSINESS_CODE = 'Partner__r.GrandparentBusinessName__c';
    
    
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
        if( String.isNotblank(request.filterBy) && request.filterBy.equalsIgnoreCase('intermediaries') )
        {
            findPeopleByScope(request, 'intermediaries');
        }
        // 3 - Comprobar si se trata de un cliente final y buscarlo
        else if( String.isNotblank(request.filterBy) && request.filterBy.equalsIgnoreCase('customers')  )
        {
            findPeopleByScope(request, 'customers');
        }
        // 4 - Comprobar si se trata de un partner
        else if( String.isNotblank(request.filterBy) && request.filterBy.equalsIgnoreCase('partners')  )
        {
            findPeopleByScope(request, 'partners');
        }
        // 5 - Resto de scopes
        else if( String.isEmpty(request.filterBy) )
        {
            // 5.2 - Se identifica el mejor agente disponible - el método asigna en consencuencia el registro sobre el que realizar un screenPop
            findBestAgentFor(request);
        }

        // 6 - Se una tarea como registro de la interacción en cola
        createOnQueueInteraction(request);

        return request;
    }

    /**
     * WIP: Falta definir qué campos rellenar en la task
     * @author nescudero
     * @date 22/10/2020
     * @edit 4/8/2021 Añadidas estadísticas con checkbox para informes
     */
    public static String createOnQueueInteraction(Interaction interactionLog)
    {
        Id queueTaskId = null;
        //Encontrar Cola para Task -> Si no existe -> Missed Calls -> si no existe -> ErrorLog
        try{
            queueTaskId = searchQueueTaskId(interactionLog.queueId);
        }catch(Exception e){ //No se para la ejecución por faltar el OwnerId, solo se registra
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_ERROR, e.getMessage(), 'GenesysInteractionsService.createOnQueueInteraction', e.getStackTraceString());
        }

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
            Type = 'Call',
            ANI__c = interactionLog.fromId,
            DNIS__c = interactionLog.toId
        );

        //No se puede insertar una Task con OwnerId a null
        if(queueTaskId != null)
        {
            interactionTask.OwnerId = queueTaskId;
        }

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

        //20210804: Estadísticas/Informes
        if(interactionLog.caller != null)
        {
            interactionTask.IdentifiedByNIF__c = !(interactionLog.caller.identifiedByNIF == null || interactionLog.caller.identifiedByNIF == false);
            interactionTask.IdentifiedByANI__c = (interactionLog.caller.identifiedByANI != null && interactionLog.caller.identifiedByANI );
            interactionTask.NoIdentified__c = (interactionLog.caller.noIdentified != null && interactionLog.caller.noIdentified );
            interactionTask.MultiIdentifiedByNIF__c = (interactionLog.caller.multiIdentifiedByNIF != null && interactionLog.caller.multiIdentifiedByNIF );
            interactionTask.MultiIdentifiedByANI__c = (interactionLog.caller.multiIdentifiedByANI != null && interactionLog.caller.multiIdentifiedByANI );
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
                                                                    AND Scope__c = :scope
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
            when else 
            {
                // else code
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

        ContactsSelector contactsSelector = new ContactsSelector();
        contactsSelector.setScope(RecordsSelector.Scope.ALL);

        if (searchFor.contains('@') )
        {
            return contactsSelector.findByEmail(new List<String> { searchFor });
        }

        return contactsSelector.findByPhoneNumber(new List<String> { searchFor });
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
        if ( String.isBlank(request.searchType) || String.isBlank(request.filterBy) || String.isBlank(request.value) )
        {
            throw new GenesysPeopleServiceException(GenesysInteractionsService.class.getName() 
            + MISSING_FIELDS_REQUIRED + MISSING_FIELDS_ERROR + request);
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
            when 'partners'
            {
                results = findPartnersBy(request);
            }
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
     * @author jjuaristi
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResult} Resultados devueltos por la búsqueda
     */
    public static SearchResult findPartnersBy(SearchRequest request)
    {
        SearchResult results = new SearchResult();
        List<Account> accounts = new List<Account>();

        switch on request.searchType
        {
            when 'phone'
            {
                // Recuperamos el contacto con el ANI recibido
                List<Contact> contacto = new ContactsSelector().findByANI(request.value);
                // Debería devolver solo 1 aunque lo almacenemos en una lista
                accounts = new AccountsSelector().selectById( ContactUtil.generateAccountIdSet(contacto) );
            }
            when else
            {
                throw new GenesysPeopleServiceException(SEARCHTYPE_NOT_DEFINED);
            }
        }

        if(accounts.size() == 1)
        {
            Account partner = accounts.get(0);

            results.screenPopRecordId = partner.Id;
            results.territoryCode = partner.ZoneCode__c;
            results.phone = String.isBlank(partner.MainMobilePhone__c)? partner.Phone : partner.MainMobilePhone__c;
            results.email = partner.MainEmail__c;
            results.nationalId = partner.NationalId__c;

            // Construimos un intermediario falso (es el id del partner) para pasar al método el ID del partner y que el agente sea el owner de un caso abierto
            Intermediary fakePartner = new Intermediary();
            fakePartner.intermediaryId = partner.Id;
            results.bestAgents = findBestAgents(fakePartner, false);
        }

        //20210804: Estadísticas/Informes
        if(accounts.size() == 0)
        {
            results.noIdentified = true;
        }
        else if(accounts.size() == 1 && request.searchType == 'phone')
        {
            results.identifiedByANI = true;
        }
        else if(accounts.size() > 1 && request.searchType == 'phone')
        {
            results.multiIdentifiedByANI = true;
        }

        return results;
    }

    /**
     * Obtener el detalle de una póliza activa a partir de su código
     *
     * @author adelgado
     * @date 20/01/2021
     */
    public static ActivePolicy findActivePolicy(String policyCode)
    {
        // 1 - Comprobar que se ha recibido un número de póliza
        if ( String.isBlank(policyCode) )
        {
            throw new GenesysPoliciesServiceException(GenesysInteractionsService.class.getName() 
            + MISSING_FIELDS_REQUIRED + ': policyCode.');
        }

        // 2 - Recuperar la póliza a partir del número recibido
        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SobjectField>
            {
                Policy__c.Id,
                Policy__c.Name,
                Policy__c.PolicyType__c
            },
            new List<String>
            {
                PRODUCT_GROUP_DESCRIPTION,
                PARTNER_SECTOR,
                PARTNER_SF_CODE,
                PARTNER_GRANDPARENT_BUSINESS_CODE,
                INTERMEDIARY_MOBILE_PHONE,
                INTERMEDIARY_PHONE,
                INTERMEDIARY_MAIL,
                INTERMEDIARY_CHANNEL,
                INTERMEDIARY_SEGMENT, 
                INTERMEDIARY_CODE 
            }
        );

        List<Policy__c> policies = policiesSelector.selectByNumber(policyCode);

        // 3 - Devolver la información de la póliza si se ha obtenido un único resultado
        if(policies != null && !policies.isEmpty() && policies.size() == 1)
        {
            return new ActivePolicy(policies[0]);
        }

        return new ActivePolicy();
    }

    /**
     * Obtener el detalle de un siniestro abierto
     *
     * @author adelgado
     * @date 20/01/2021
     */
    public static OpenedClaim findOpenedClaim(SearchRequest request)
    {
        // 1 - Comprobar que la request tiene informados todos los campos requeridos
        if ( String.isBlank(request.searchType) || String.isBlank(request.searchTerm) )
        {
            throw new GenesysClaimsServiceException(GenesysInteractionsService.class.getName() 
            + MISSING_FIELDS_REQUIRED + ', searchType and searchTerm. Payload: ' + request);
        }

        // 2 - Realizar la búsqueda de siniestro en base a los filtros definidos en la request
        ClaimsSelector claimsSelector = new ClaimsSelector();
        claimsSelector.setFields
        (
            new List<Schema.SobjectField>
            {
                Claim__c.Id,
                Claim__c.Name,
                Claim__c.Status__c,
                Claim__c.ClaimOwnerTeamCode__c,
                Claim__c.ClaimOwnerNationalId__c,
                Claim__c.ClaimOwnerName__c,
                Claim__c.ClaimOwnerFirstName__c,
                Claim__c.ClaimOwnerLastName__c
            },
            new List<String>
            {
                ASSET_REGISTRATION_NUMBER,
                POLICY_TYPE, POLICY_BRANCH,
                POLICY_PARTNER_SF_CODE,
                POLICY_PARTNER_SECTOR,
                POLICY_PARTNER_NAME,
                POLICY_NUMBER,
                POLICY_INTERMEDIARY_CODE, 
                POLICY_INTERMEDIARY_MOBILE_PHONE,
                POLICY_INTERMEDIARY_PHONE,
                POLICY_INTERMEDIARY_MAIL,
                POLICY_INTERMEDIARY_CHANNEL,
                POLICY_INTERMEDIARY_SEGMENT
            }
        );

        List<Claim__c> claims = new List<Claim__c>();

        switch on request.searchType
        {
            when 'claim_number'
            {
                claims = claimsSelector.selectByNumber(request.searchTerm);
            }
            when 'car_registration'
            {
                claims = claimsSelector.selectByPlate(request.searchTerm);
            }
            when else 
            {
                // else code
            }
        }

        // 3 - Devolver la información del siniestro si se ha obtenido un único resultado
        if(claims != null && !claims.isEmpty() && claims.size() == 1)
        {
            return new OpenedClaim(claims[0]);
        }

        return new OpenedClaim();
    }

    /**
     * Lanza una búsqueda con la configuración determinada por request
     *
     * @author adelgado
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResult} Resultados devueltos por la búsqueda
     * @last modified on  : 22-05-2024
     * @last modified by  : jfherrero
     */
    public static SearchResult findCustomersBy(SearchRequest request)
    {
        SearchResult results = new SearchResult();
        List<Account> accounts = new List<Account>();

        RecordsSelector.Scope scope = RecordsSelector.getScope(request.scope);
        RecordsSelector.LegalEntity legalEntity = RecordsSelector.getLegalEntity(request.legalEntity);

        String searchType = request.searchType;
        accounts = findCustomersBySearchType (new List<String>{request.value}, searchType, scope, legalEntity);

        if(accounts.size() == 1)
        {
            // Vamos a registrar el parámetro opcional 'intent'. En éste caso para cambiar el cálculo del
            // preferredClaim en base al mismo. Suponiendo que venga informado y no esté vacío
            String intent = String.isNotBlank(request.intent) ? request.intent : '';

            Account customer = accounts.get(0);
            results.screenPopRecordId = customer.Id;
            results.nationalId = customer.NationalId__c;
            results.totalPolicies = customer.NumPolicies__pc != null ? Integer.valueOf(customer.NumPolicies__pc) : null;
            results.totalQuotes = customer.NumQuotes__pc != null ? Integer.valueOf(customer.NumQuotes__pc) : null;

            results.policies = findActivePolicies(customer.Id, RecordsSelector.getScope(request.scope), RecordsSelector.getLegalEntity(request.legalEntity));
            results.claims = findOpenedClaims(customer.Id, RecordsSelector.getScope(request.scope), RecordsSelector.getLegalEntity(request.legalEntity), intent);
        }

        //20210804: Estadísticas/Informes
        if(accounts.size() == 0)
        {
            results.noIdentified = true;
        }
        else if(accounts.size() == 1 && searchType == 'phone')
        {
            results.identifiedByANI = true;
        }
        else if(accounts.size() > 1 && searchType == 'phone')
        {
            results.multiIdentifiedByANI = true;
        }
        else if(accounts.size() == 1 && searchType == 'document')
        {
            results.identifiedByNIF = true;
        }
        else if(accounts.size() > 1 && searchType == 'document')
        {
            results.multiIdentifiedByNIF = true;
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

        switch on request.searchType
        {
            when 'phone'
            {
                accounts = AccountSearchService.findIntermediariesByPhoneNumber( new List<String>{request.value} );
            }
            when 'intermediary_code'
            {
                accounts = AccountSearchService.findIntermediariesByCode( new List<String>{request.value} );
            }
            when 'document'
            {
                accounts = AccountSearchService.findIntermediariesByNIF( new List<String>{request.value} );
            }
            when else
            {
                throw new GenesysPeopleServiceException(SEARCHTYPE_NOT_DEFINED);
            }
        }

        if(accounts.size() == 1 || (accounts.size() > 1 && request.searchType == 'document' ))
        {
            Account intermediary = accounts.get(0);

            results.screenPopRecordId = intermediary.Id;
            results.territoryCode = intermediary.ZoneCode__c;
            results.phone = String.isBlank(intermediary.MainMobilePhone__c)? intermediary.Phone : intermediary.MainMobilePhone__c;
            results.email = intermediary.MainEmail__c;
            results.nationalId = intermediary.NationalId__c;
            results.intermediaryChannel = intermediary.Channel__c;
            results.intermediarySegment = intermediary.Segment__c;
            results.association = intermediary.Association__c;

            results.bestAgents = findBestAgents(new Intermediary(intermediary.Id, intermediary.CsmIndividualsManager__c, intermediary.CsmAdministrationManager__c), true);
        }

        //20210804: Estadísticas/Informes
        if(accounts.size() == 0)
        {
            results.noIdentified = true;
        }
        else if(accounts.size() == 1 && request.searchType == 'phone')
        {
            results.identifiedByANI = true;
        }
        else if(accounts.size() > 1 && request.searchType == 'phone')
        {
            results.multiIdentifiedByANI = true;
        }

        return results;
    }

     /**
     * Genera una lista estructura Agent con los gestores preferentes del mediador
     *
     * @author adelgado
     * @date 24/11/2020
     */
    public static List<Agent> findBestAgents(Intermediary intermediary, Boolean isIntermediary)
    {
        Set<Agent> bestAgents = new Set<Agent>();

        // 1 - Obtener los gestores de los casos abiertos asociados al mediador
        CasesSelector casesSelector = new CasesSelector();
        casesSelector.setFields
        (
            new List<Schema.SObjectField>
            {
                Case.OwnerId
            },
            new List<String>
            {
                'Owner.Email'
            }
        );

        if(!isIntermediary)
        {
            for(Case openCase : casesSelector.findOpenByAccount(new List<String>{intermediary.intermediaryId}))
            {
                if (openCase.Owner.Email != null)
                {
                    bestAgents.add
                    (
                        new Agent(openCase.Owner.Email, true, false, false)
                    );
                }
            }
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
     * Buscar a partir del ANI y scope
     *
     * @author adelgado
     * @date 26/11/2020
     */
    public static Interaction findPeopleByScope(Interaction request, String filterBy)
    {
        SearchRequest searchRequest = new SearchRequest();
        searchRequest.searchType = 'phone';
        searchRequest.filterBy = filterBy;
        searchRequest.value = request.fromId;
        searchRequest.scope = request.scope;
        searchRequest.legalEntity = request.legalEntity;

        request.caller = findPeopleBy(searchRequest);

        request.screenPopRecordId = request.caller.screenPopRecordId;

        return request;
    }

    /**
     * Obtener las pólizas activas a partir de un Id de cliente
     *
     * @author adelgado
     * @date 20/01/2021
     */
    @testVisible
    private static ActivePolicies findActivePolicies(Id customerId, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity)
    {
        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SobjectField>
            {
                Policy__c.Id,
                Policy__c.Name,
                Policy__c.PolicyType__c
            },
            new List<String>
            {
                PRODUCT_GROUP_DESCRIPTION,
                PARTNER_SECTOR,
                PARTNER_SF_CODE,
                INTERMEDIARY_MOBILE_PHONE,
                INTERMEDIARY_PHONE,
                INTERMEDIARY_MAIL,
                INTERMEDIARY_CHANNEL,
                INTERMEDIARY_SEGMENT,
                INTERMEDIARY_CODE,
                PARTNER_GRANDPARENT_BUSINESS_CODE
            }
        );

        policiesSelector.setScope(scope);
        policiesSelector.setLegalEntity(legalEntity);

        List<Policy__c> policies = policiesSelector.selectByHolder(customerId);

        return new ActivePolicies(policies);
    }

    /**
     * Obtener las pólizas activas a partir de un Id de cliente
     *
     * @author adelgado
     * @date 20/01/2021
     */
    @testVisible
    private static ActivePoliciesSabadell findActivePoliciesSabadell(Id customerId, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity)
    {
        PoliciesSelector policiesSelector = new PoliciesSelector();
        policiesSelector.setFields
        (
            new List<Schema.SobjectField>
            {
                Policy__c.Id,
                Policy__c.Name,
                Policy__c.PolicyType__c
            },
            new List<String>
            {
                PRODUCT_GROUP_DESCRIPTION,
                PARTNER_SECTOR,
                PARTNER_SF_CODE,
                INTERMEDIARY_MOBILE_PHONE,
                INTERMEDIARY_PHONE,
                INTERMEDIARY_MAIL,
                INTERMEDIARY_CHANNEL,
                INTERMEDIARY_SEGMENT,
                INTERMEDIARY_CODE,
                PARTNER_GRANDPARENT_BUSINESS_CODE
            }
        );

        policiesSelector.setScope(scope);
        policiesSelector.setLegalEntity(legalEntity);

        List<Policy__c> policies = policiesSelector.selectByHolder(customerId);

        return new ActivePoliciesSabadell(policies);
    }

    /**
     * Obtener los siniestros abiertos a partir de un Id de cliente
     *
     * @author adelgado
     * @date 20/01/2021
     */
    @testVisible
    private static OpenedClaims findOpenedClaims(Id customerId, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity, String intent)
    {
        ClaimsSelector claimsSelector = new ClaimsSelector();
        claimsSelector.setFields
        (
            new List<Schema.SobjectField>
            {
                Claim__c.Id,
                Claim__c.Name,
                Claim__c.Status__c,               
                Claim__c.ClaimType__c,
                Claim__c.ClaimOwnerTeamCode__c,
                Claim__c.ClaimOwnerNationalId__c,
                Claim__c.ClaimOwnerName__c,
                Claim__c.ClaimOwnerFirstName__c,
                Claim__c.ClaimOwnerLastName__c
            },
            new List<String>
            {
                ASSET_REGISTRATION_NUMBER,
                POLICY_TYPE, POLICY_BRANCH,
                POLICY_PARTNER_SF_CODE,
                POLICY_PARTNER_SECTOR,
                POLICY_PARTNER_NAME,
                POLICY_INTERMEDIARY_CODE,
                POLICY_NUMBER,
                POLICY_INTERMEDIARY_MOBILE_PHONE,
                POLICY_INTERMEDIARY_PHONE,
                POLICY_INTERMEDIARY_MAIL,
                POLICY_INTERMEDIARY_CHANNEL,
                POLICY_INTERMEDIARY_SEGMENT
            }
        );

        claimsSelector.setScope(scope);
        claimsSelector.setLegalEntity(legalEntity);

        List<Claim__c> claims = claimsSelector.selectByHolder(customerId);

        return new OpenedClaims(claims, intent);
    }

    /**
     * Busca si existe una Cola que permita objeto Task que tenga el mismo nombre
     * en Genesys.
     * Si no existe, o queueID ha venido vacío, se asignará a 'Missed Calls'
     * Si no existe esa cola se registra error y se devuelve null.
     * @date 28/01/2021
     */
    @TestVisible
    private static Id searchQueueTaskId(String genesysQueueId)
    {
        Id queueId = null; //Si el proceso falla, se devolverá a null
        String queueName = null;

        //1º Construir mapa con las colas de Genesys Id <-> Nombre
        Map<String,String> mapGenesysQueueIdName = new Map<String,String>();
        List<purecloud__PureCloud_Queue__c> genesysQueues = new List<purecloud__PureCloud_Queue__c>();
        genesysQueues = [SELECT Id, Name, purecloud__PureCloud_Queue_ID__c, SalesforceQueueName__c FROM purecloud__PureCloud_Queue__c];
        for(purecloud__PureCloud_Queue__c gQueue: genesysQueues)
        {
            mapGenesysQueueIdName.put(gQueue.purecloud__PureCloud_Queue_ID__c, gQueue.SalesforceQueueName__c);
        }

        //2º Construir mapa de colas para TASK Nombre <-> Id
        Map<String,Id> mapTaskQueueNameId = new Map<String,Id>();
        List<QueueSobject> taskQueues = new List<QueueSobject>();
        taskQueues = [SELECT QueueId, Queue.Name, SobjectType FROM QueueSobject WHERE SobjectType = 'Task'];
        for(QueueSobject tQueue: taskQueues)
        {
            mapTaskQueueNameId.put(tQueue.Queue.Name, tQueue.QueueId);
        }

        //3º Si existe la cola con mismo nombre en Genesys
        if(genesysQueueId != null && mapGenesysQueueIdName.containsKey(genesysQueueId))
        {   //Si existe la cola con mismo nombre en SF
            queueName = mapGenesysQueueIdName.get(genesysQueueId);
            if(mapTaskQueueNameId.containsKey(queueName))
            {
                queueId = mapTaskQueueNameId.get(queueName);
            }
            else{//4º Sino existe en SF, se asigna 'Missed_Calls'
                if(mapTaskQueueNameId.containsKey(TASK_QUEUE))
                {
                    queueId = mapTaskQueueNameId.get(TASK_QUEUE);
                }
            }
        }
        else{//4º Si viene vacío o no existe en Genesys, se asigna 'Missed_Calls'
            if(mapTaskQueueNameId.containsKey(TASK_QUEUE))
            {
                queueId = mapTaskQueueNameId.get(TASK_QUEUE);
            }
        }

        //5º Si tampoco existe Missed_Calls, se devuelve null y queda sin asignar.
        if(queueId == null)
        {   //Se avisa de la falta de dicha cola con un ErrorLog pero no se para la ejecución
            ErrorLogUtil.commitError(ErrorLogUtil.ERROR_LEVEL_WARNING, NO_QUEUE_MISSED_CALLS, 'GenesysInteractionsService.searchQueueTaskId');
        }

        return queueId;
    }

    /**
     * Obtener true o false dependiendo de si el Customer es Digital (KLINC)
     * @date 23/02/2021
     */
    public static DigitalCustomer findDigitalCustomer(DigitalCustomer request)
    {
        // 1 - Comprobar que la request tiene informados todos los campos requeridos
        if (String.isBlank(request.searchType) || String.isBlank(request.value))
        {
            throw new GenesysInteractionsServiceException(GenesysInteractionsService.class.getName() 
            + MISSING_FIELDS_REQUIRED + ': searchType and value. Payload: ' + request);
        }

        // 2 - Realizar la búsqueda de siniestro en base a los filtros definidos en la request
        List<Order> klincPolicies = new List<Order>();
        switch on request.searchType {
            when 'phone'
            {
                klincPolicies = DigitalCustomerSearchService.findPoliciesByCustomerPhone(request.value);
            }
            when 'document'
            {
                klincPolicies = DigitalCustomerSearchService.findPoliciesByCustomerDocument(request.value);
            }
            when 'email'
            {
                klincPolicies = DigitalCustomerSearchService.findPoliciesByCustomerEmail(request.value);
            }
            when else 
            {
                // else code
            }
        }

        // 3 - Si tiene al menos 1 póliza, es de Klinc
        if(klincPolicies != null && !klincPolicies.isEmpty() && klincPolicies.size() > 0)
        {
            request.isDigitalCustomer = true;
            return request;
        }

        //Si no tiene pólizas activas no se sabe si es de Klinc
        request.isDigitalCustomer = false;
        return request;
    }

    /**
     * Lanza una búsqueda con la configuración determinada por request y devuelve una lista de Accounts
     *
     * @author jfherrero
     * @param List<String> values                       Valores para buscar
     * @param String searchType                         Tipo de búsqueda a realizar
     * @param RecordsSelector.Scope scope               Ámbito de la búsqueda
     * @param RecordsSelector.LegalEntity legalEntity   Entidad legal
     * 
     * @return {SearchResult} Resultados devueltos por la búsqueda
     */
    private static List<Account> findCustomersBySearchType (List<String> values, String searchType, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity)
    {
        List<Account> accounts = new List<Account>();

        switch on searchType
        {
            when 'phone'
            {
                accounts = AccountSearchService.findCustomersByPhoneNumber( values, scope, legalEntity, null, null );
            }
            when 'email'
            {
                accounts = AccountSearchService.findCustomersByEmail( values, scope, legalEntity, null, null );
            }
            when 'document'
            {
                accounts = AccountSearchService.findCustomersByDocumentId( values, null, scope, legalEntity, null, null );
            }
            when 'policy_code'
            {
                accounts = AccountSearchService.findCustomersByPolicyNumber( values, scope, legalEntity );

                if(accounts == null || accounts.isEmpty())
                {
                    accounts = AccountSearchService.findCustomersByQuoteNumber( values, scope, legalEntity );
                }
            }
            when else
            {
                throw new GenesysPeopleServiceException(SEARCHTYPE_NOT_DEFINED);
            }
        }

        return accounts;
    }

    /**
     * Lanza una búsqueda con la configuración determinada por request
     *
     * @author jfherrero
     * @date 19/03/2024
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResultAuto} Resultados devueltos por la búsqueda
     */
    public static SearchResultAuto findPeopleAutoBy(SearchRequest request)
    {
        // 1 - Comprobar que la request tiene informados todos los campos requeridos
        if ( String.isBlank(request.searchType) || String.isBlank(request.filterBy) || String.isBlank(request.value) )
        {
            throw new GenesysPeopleServiceException(GenesysInteractionsService.class.getName() 
            + MISSING_FIELDS_REQUIRED + MISSING_FIELDS_ERROR + request);
        }

        SearchResultAuto results = new SearchResultAuto();

        // 2 - Realizar la búsqueda de registros en base a los filtros definidos en la request
        switch on request.filterBy
        {
            // Inicialmente vamos a trabajar sólo con búsqueda de 'customers'
            when 'customers'
            {
                results = findCustomersAutoBy(request);
            }
            //Inicialmente vamos a trabajar sólo buscando customers
            when else
            {
                throw new GenesysPeopleServiceException(FILTER_NOT_DEFINED+'('+request.filterBy+')');
            }
        }

        // 3 - Devolver los resultados obtenidos
        return results;
    }

    /**
     * Lanza una búsqueda con la configuración determinada por request
     *
     * @author jfherrero
     * @date 24/04/2024
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResultAuto} Resultados devueltos por la búsqueda
     */
    public static SearchResultSabadell findPeopleSabadellBy(SearchRequest request)
    {
        // 1 - Comprobar que la request tiene informados todos los campos requeridos
        if ( String.isBlank(request.searchType) || String.isBlank(request.filterBy) || String.isBlank(request.value) )
        {
            throw new GenesysPeopleServiceException(GenesysInteractionsService.class.getName() 
            + MISSING_FIELDS_REQUIRED + MISSING_FIELDS_ERROR + request);
        }

        SearchResultSabadell results = new SearchResultSabadell();

        // 2 - Realizar la búsqueda de registros en base a los filtros definidos en la request
        switch on request.filterBy
        {
            // Inicialmente vamos a trabajar sólo con búsqueda de 'customers'
            when 'customers'
            {
                results = findCustomersSabadellBy(request);
            }
            //Inicialmente vamos a trabajar sólo buscando customers
            when else
            {
                throw new GenesysPeopleServiceException(FILTER_NOT_DEFINED+'('+request.filterBy+')');
            }
        }

        // 3 - Devolver los resultados obtenidos
        return results;
    }
    
    /**
     * Lanza una búsqueda con la configuración determinada por request
     * Se desdobla la funcionalidad para recuperar nuevos valores.
     *
     * @author jfherrero
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResultAuto} Resultados devueltos por la búsqueda
     */
    public static SearchResultAuto findCustomersAutoBy(SearchRequest request)
    {
        SearchResultAuto results = new SearchResultAuto();
        List<Account> accounts = new List<Account>();

        String searchType = request.searchType;
        RecordsSelector.Scope scope = RecordsSelector.getScope(request.scope);
        
        RecordsSelector.LegalEntity legalEntity = RecordsSelector.getLegalEntity(request.legalEntity);

        accounts = findCustomersBySearchType (new List<String>{request.value}, searchType, scope, legalEntity);

        if(accounts.size() == 1)
        {
            results.identifiedByNIF = true;
            Account customer = accounts.get(0);
            results.screenPopRecordId = customer.Id;
            results.nationalId = customer.NationalId__c;
            results.email = customer.MainEmail__c;
            results.phone = String.isBlank(customer.Phone)? customer.MainMobilePhone__c : customer.Phone;
            results.totalPolicies = customer.NumPolicies__pc != null ? Integer.valueOf(customer.NumPolicies__pc) : null;
            results.totalQuotes = customer.NumQuotes__pc != null ? Integer.valueOf(customer.NumQuotes__pc) : null;

            // Nos interesa únicamente el ramo 'AUTOS'
            List<Claim__c> latestClaims = findLatestClaimsByBranch(customer.Id, RecordsSelector.getScope(request.scope), RecordsSelector.getLegalEntity(request.legalEntity), 'AUTOS');

            if(latestClaims != null && latestClaims.size()>0)
            {
                results.claim = new ClaimAuto(latestClaims[0]);
                results.policy = new PolicyAuto(latestClaims[0]);
            }
        }

        //Estadísticas/Informes
        else if(accounts.size() == 0)
        {
            results.noIdentified = true;
        }
        else if(accounts.size() > 1)
        {
            results.multiIdentifiedByNIF = true;
        }

        return results;
    }

    /**
     * Lanza una búsqueda con la configuración determinada por request
     * Se desdobla la funcionalidad para recuperar nuevos valores.
     *
     * @author jfherrero
     * @date 24-04-2024
     * @param {SearchRequest} request Solicitud de búsqueda
     * @return {SearchResultAuto} Resultados devueltos por la búsqueda
     */
    public static SearchResultSabadell findCustomersSabadellBy(SearchRequest request)
    {
        SearchResultSabadell results = new SearchResultSabadell();
        List<Account> accounts = new List<Account>();

        RecordsSelector.Scope scope = RecordsSelector.getScope(request.scope);
        RecordsSelector.LegalEntity legalEntity = RecordsSelector.getLegalEntity(request.legalEntity);

        String searchType = request.searchType;
        accounts = findCustomersBySearchType (new List<String>{request.value}, searchType, scope, legalEntity);

        if(accounts.size() == 1)
        {
            Account customer = accounts.get(0);
            results.screenPopRecordId = customer.Id;
            results.nationalId = customer.NationalId__c;
            results.totalPolicies = customer.NumPolicies__pc != null ? Integer.valueOf(customer.NumPolicies__pc) : null;
            results.totalQuotes = customer.NumQuotes__pc != null ? Integer.valueOf(customer.NumQuotes__pc) : null;

            results.policies = findActivePoliciesSabadell(customer.Id, RecordsSelector.getScope(request.scope), RecordsSelector.getLegalEntity(request.legalEntity));
            results.claims = findOpenedClaims(customer.Id, RecordsSelector.getScope(request.scope), RecordsSelector.getLegalEntity(request.legalEntity), '');
        }

        //20210804: Estadísticas/Informes
        if(accounts.size() == 0)
        {
            results.noIdentified = true;
        }
        else if(accounts.size() == 1 && searchType == 'phone')
        {
            results.identifiedByANI = true;
        }
        else if(accounts.size() > 1 && searchType == 'phone')
        {
            results.multiIdentifiedByANI = true;
        }
        else if(accounts.size() == 1 && searchType == 'document')
        {
            results.identifiedByNIF = true;
        }
        else if(accounts.size() > 1 && searchType == 'document')
        {
            results.multiIdentifiedByNIF = true;
        }

        return results;
    }

    /**
     * Obtener el último siniestro de un cliente para un ramo indicado
     *
     * @author jfherrero
     * @date 14/03/2024
     */
    @testVisible
    private static List<Claim__c> findLatestClaimsByBranch(Id customerId, RecordsSelector.Scope scope, RecordsSelector.LegalEntity legalEntity, String branch)
    { 
        ClaimsSelector claimsSelector = new ClaimsSelector();
        claimsSelector.setFields
        (
            new List<Schema.SobjectField>
            {
                //Datos del siniestro
                Claim__c.Id,
                Claim__c.Name,
                Claim__c.Status__c,
                Claim__c.ClaimType__c,
                Claim__c.ClaimOwnerTeamName__c,
                Claim__c.ClaimOwnerTeamCode__c,
                Claim__c.ClaimOwnerNationalId__c,
                Claim__c.ClaimOwnerName__c,
                Claim__c.ClaimOwnerFirstName__c,
                Claim__c.ClaimOwnerLastName__c,
                Claim__c.CreatedDate
            },
            new List<String>
            {
                //Datos de la póliza
                'Policy__r.Id',
                POLICY_NUMBER,
                POLICY_TYPE, 
                'Policy__r.CommercialCode__c',
                'Policy__r.TechnicalCode__c',
                'Policy__r.ProductId__r.Name',
                POLICY_BRANCH,
                //Datos del partner
                'Policy__r.Partner__c',
                POLICY_PARTNER_SF_CODE,
                POLICY_PARTNER_SECTOR,
                POLICY_PARTNER_NAME,
                //Datos del mediador
                POLICY_INTERMEDIARY_CODE,
                'Policy__r.IntermediaryId__r.IntermediaryDescription__c',
                'Policy__r.IntermediaryId__r.ClassDescription__c',
                POLICY_INTERMEDIARY_MOBILE_PHONE,
                POLICY_INTERMEDIARY_PHONE,
                POLICY_INTERMEDIARY_MAIL,
                POLICY_INTERMEDIARY_CHANNEL,
                POLICY_INTERMEDIARY_SEGMENT,
                'Policy__r.IntermediaryId__r.SegmentDescription__c',
                //Datos del tomador
                'Policy__r.PolicyHolder__r.Name',
                'Policy__r.PolicyHolder__r.NationalId__c',
                'Policy__r.PolicyHolder__r.MainEmail__c',
                'Policy__r.PolicyHolder__r.Phone',
                'Policy__r.PolicyHolder__r.MainMobilePhone__c',
                //Datos del objeto asegurado
                ASSET_REGISTRATION_NUMBER,
                'InsuredObject__r.BrandName__c',
                'InsuredObject__r.Model__c'
            }
        );

        claimsSelector.setScope(scope);
        claimsSelector.setLegalEntity(legalEntity);

        //Recogemos el último siniestro: determinar si lo queremos cerrado 'T' o no cerrado
        List<Claim__c> claims = claimsSelector.selectByHolderAndBranch(customerId, 'AUTOS', false, 'CreatedDate', 'desc');

        return claims;
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
        public String scope
        {
            get
            {
                if(String.isBlank(scope))
                {
                    return RecordsSelector.Scope.ALL.name();
                }
                else
                {
                    return scope;
                }
            }
            set;
        }
        public String legalEntity
        {
            get
            {
                if(String.isBlank(legalEntity))
                {
                    return RecordsSelector.LegalEntity.ALL.name();
                }
                else
                {
                    return legalEntity;
                }
            }
            set;
        }
        public String filterBy;

        public String screenPopRecordId { get; set; }
        public String customerId { get; set; }
        public String callLogId { get; set; }
        public String bestAgentId { get; set; }
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
        public String value
        {
            get
            {
                return cleanTerm(value, searchType);
            }
            set;
        }
        public String scope
        {
            get
            {
                if(String.isBlank(scope))
                {
                    return RecordsSelector.Scope.ALL.name();
                }
                else
                {
                    return scope;
                }
            }
            set;
        }
        public String legalEntity
        {
            get
            {
                if(String.isBlank(legalEntity))
                {
                    return RecordsSelector.LegalEntity.ALL.name();
                }
                else
                {
                    return legalEntity;
                }
            }
            set;
        }
        public String searchTerm
        {
            get
            {
                return cleanTerm(searchTerm, searchType);
            }
            set;
        }
        public String intent
        {
            get
            {
                if(String.isBlank(intent))
                {
                    return '';
                }
                else
                {
                    return intent.toUpperCase();
                }
            }
            set;
        }

        public SearchRequest() {}
        public SearchRequest(Map<String, String> paramsByName)
        {
            this.searchType = paramsByName.get('searchType');
            this.intent = paramsByName.get('intent');
            this.filterBy = paramsByName.get('filterBy');
            this.value = paramsByName.get('value');
            this.scope = paramsByName.get('scope');
            this.legalEntity = paramsByName.get('legalEntity');
            this.searchTerm = paramsByName.get('searchTerm');
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }

        /**
         * Removes the whitespaces and converts characters to uppercase in the term parameter
         *
         * @author nts (agonzalezisasi)
         */
        private String cleanTerm(String term, String type)
        {
            String result = String.isEmpty(term)? '':term;

            switch on type {
                when 'document', 'car_registration' {
                    result = result.deleteWhitespace().toUpperCase();
                }
                when 'claim_number' {
                    result = result.deleteWhitespace().toUpperCase().leftPad(10, '0');
                }
                when else 
                {
                    // else code
                }
            }

            return result;
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
        public String phone;
        public String email;
        public String territoryCode;
        public Integer totalPolicies;
        public Integer totalQuotes;
        public Agent[] bestAgents;
        public ActivePolicies policies;
        public OpenedClaims claims;
        public String nationalId;

        //20210804: Estadísticas/Informes
        public Boolean identifiedByNIF;
        public Boolean identifiedByANI;
        public Boolean noIdentified;
        public Boolean multiIdentifiedByNIF;
        public Boolean multiIdentifiedByANI;

        // 2023-03-01 (arcortazar)
        public String intermediaryChannel;
        public String intermediarySegment;

        // 2023-09-20 (arcortazar)
        public String association;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa los resultados de búsqueda del CRM
     *
     * @author jfherrero
     * @date 24/04/2024
     */
    public class SearchResultSabadell
    {
        public transient List<Contact> names;
        public transient List<SObject> relatedRecords;
        public String screenPopRecordId;
        public String phone;
        public String email;
        public String territoryCode;
        public Integer totalPolicies;
        public Integer totalQuotes;
        public Agent[] bestAgents;
        public ActivePoliciesSabadell policies;
        public OpenedClaims claims;
        public String nationalId;
        public String intermediaryChannel;
        public String intermediarySegment;
        public String association;

        //20210804: Estadísticas/Informes
        public Boolean identifiedByNIF;
        public Boolean identifiedByANI;
        public Boolean noIdentified;
        public Boolean multiIdentifiedByNIF;
        public Boolean multiIdentifiedByANI;

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

        public override String toString()
        {
            return JSON.serialize(this);
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

    /**
     * Representa la información de las pólizas activas en el CRM. Ofrece las pólizas ordenadas por partner, sector, intermediario y tipo
     * A nivel de integración, la representación JSON incluye todos los parámetros, incluido los atributos privados, para que sistemas como
     * Genesys puedan procesar la información
     *
     * @author adelgado
     */
    public class ActivePolicies
    {
        public Map<String, List<ActivePolicy>> byPartner { get; private set;}
        public Map<String, List<ActivePolicy>> bySector { get; private set;}
        public Map<String, List<ActivePolicy>> byIntermediary { get; private set;}
        public Map<String, List<ActivePolicy>> byType { get; private set;}

        /**
         * Representa la póliza preferente de cara al enrutamiento - una póliza preferente se considera bajo los casos siguientes:
         * - El cliente tiene una única póliza
         * - El cliente tiene varias pólizas, todas del mismo partner y tipo
         */
        public ActivePolicy preferredPolicy
        {
            get
            {
                if(total != 1 || hasMultipleTypes && hasMultiplePartners)
                {
                    return null;
                }

                return  this.policies[0];
            }
        }

        /**
         * Determina si existen pólizas de múltiples tipos
         */
        public Boolean hasMultipleTypes
        {
            get
            {
                return this.byType.size() > 1;
            }
        }

        /**
         * Determina si existen pólizas de múltiples partners
         */
        public Boolean hasMultiplePartners
        {
            get
            {
                return this.byPartner.size() > 1;
            }
        }

        /**
         * Determina si existen pólizas de múltiples intermediarios
         */
        public Boolean hasMultipleIntermediaries
        {
            get
            {
                return this.byIntermediary.size() > 1;
            }
        }

         /**
         * Devuelve el total de pólizas
         */
        public Integer total
        {
            get
            {
                return this.policies.size();
            }
        }

        private List<ActivePolicy> policies;

        public ActivePolicies (List<Policy__c> policies)
        {
            this.policies = new List<ActivePolicy> ();
            this.byPartner = new Map<String, List<ActivePolicy>>();
            this.bySector = new Map<String, List<ActivePolicy>>();
            this.byIntermediary = new Map<String, List<ActivePolicy>>();
            this.byType = new Map<String, List<ActivePolicy>>();

            for(Policy__c policy: policies)
            {
                this.add(new ActivePolicy(policy));
            }
        }

        public void add(ActivePolicy policy)
        {
            this.policies.add(policy);

            if(String.isNotBlank(policy.partnerName))
            {
                if(!byPartner.containsKey(policy.partnerName))
                {
                    byPartner.put(policy.partnerName, new List<ActivePolicy>());
                }

                byPartner.get(policy.partnerName).add(policy);
            }

            if(String.isNotBlank(policy.partnerSector))
            {
                if(!bySector.containsKey(policy.partnerSector))
                {
                    bySector.put(policy.partnerSector, new List<ActivePolicy>());
                }

                bySector.get(policy.partnerSector).add(policy);
            }

            if(String.isNotBlank(policy.intermediaryCode))
            {
                if(!byIntermediary.containsKey(policy.intermediaryCode))
                {
                    byIntermediary.put(policy.intermediaryCode, new List<ActivePolicy>());
                }

                byIntermediary.get(policy.intermediaryCode).add(policy);
            }

            if(String.isNotBlank(policy.type))
            {
                if(!byType.containsKey(policy.type))
                {
                    byType.put(policy.type, new List<ActivePolicy>());
                }

                byType.get(policy.type).add(policy);
            }
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa la información de las pólizas activas en el CRM. Ofrece las pólizas ordenadas por partner, sector, intermediario y tipo
     * A nivel de integración, la representación JSON incluye todos los parámetros, incluido los atributos privados, para que sistemas como
     * Genesys puedan procesar la información. Versión ajustada para consultas de Banco Sabadell
     *
     * @author jfherrero
     * @date 24/04/2024
     */
    public class ActivePoliciesSabadell
    {
        public Map<String, List<ActivePolicy>> byPartner { get; private set;}
        public Map<String, List<ActivePolicy>> bySector { get; private set;}
        public Map<String, List<ActivePolicy>> byIntermediary { get; private set;}
        public Map<String, List<ActivePolicy>> byType { get; private set;}

        /**
         * Representa la póliza preferente de cara al enrutamiento - una póliza preferente se considera bajo los casos siguientes:
         * - El cliente tiene una única póliza
         * - El cliente tiene varias pólizas, todas del mismo partner y tipo
         */
        public ActivePolicy preferredPolicy
        {
            get
            {
                if (this.byType.get('AUTOS') != null && this.byType.get('AUTOS').size() > 0)
                {
                    return this.byType.get('AUTOS')[0];
                }
                
                return null;
            }
        }

        /**
         * Determina si existen pólizas de múltiples tipos
         */
        public Boolean hasMultipleTypes
        {
            get
            {
                return this.byType.size() > 1;
            }
        }

        /**
         * Determina si existen pólizas de múltiples partners
         */
        public Boolean hasMultiplePartners
        {
            get
            {
                return this.byPartner.size() > 1;
            }
        }

        /**
         * Determina si existen pólizas de múltiples intermediarios
         */
        public Boolean hasMultipleIntermediaries
        {
            get
            {
                return this.byIntermediary.size() > 1;
            }
        }

         /**
         * Devuelve el total de pólizas
         */
        public Integer total
        {
            get
            {
                return this.policies.size();
            }
        }

        private List<ActivePolicy> policies;

        public ActivePoliciesSabadell (List<Policy__c> policies)
        {
            this.policies = new List<ActivePolicy> ();
            this.byPartner = new Map<String, List<ActivePolicy>>();
            this.bySector = new Map<String, List<ActivePolicy>>();
            this.byIntermediary = new Map<String, List<ActivePolicy>>();
            this.byType = new Map<String, List<ActivePolicy>>();

            for(Policy__c policy: policies)
            {
                this.add(new ActivePolicy(policy));
            }
        }

        public void add(ActivePolicy policy)
        {
            this.policies.add(policy);

            if(String.isNotBlank(policy.partnerName))
            {
                if(!byPartner.containsKey(policy.partnerName))
                {
                    byPartner.put(policy.partnerName, new List<ActivePolicy>());
                }

                byPartner.get(policy.partnerName).add(policy);
            }

            if(String.isNotBlank(policy.partnerSector))
            {
                if(!bySector.containsKey(policy.partnerSector))
                {
                    bySector.put(policy.partnerSector, new List<ActivePolicy>());
                }

                bySector.get(policy.partnerSector).add(policy);
            }

            if(String.isNotBlank(policy.intermediaryCode))
            {
                if(!byIntermediary.containsKey(policy.intermediaryCode))
                {
                    byIntermediary.put(policy.intermediaryCode, new List<ActivePolicy>());
                }

                byIntermediary.get(policy.intermediaryCode).add(policy);
            }

            if(String.isNotBlank(policy.type))
            {
                if(!byType.containsKey(policy.type))
                {
                    byType.put(policy.type, new List<ActivePolicy>());
                }

                byType.get(policy.type).add(policy);
            }
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa la información de una póliza activa en el CRM
     *
     * @author adelgado
     */
    public class ActivePolicy
    {
        public String destinationCode;
        public String id;
        public String policyCode;
        public String type;
        public String partnerName;
        public String partnerSector;
        public String intermediaryCode;
        public String intermediaryChannel;
        public String intermediaryPhone;
        public String intermediaryEmail;
        public String intermediarySegment;

        public ActivePolicy(){}
        public ActivePolicy(Policy__c policy)
        {
            this.destinationCode = policy.Partner__r.PartnerSFCode__c;
            this.id = policy.id;
            this.policyCode = policy.Name;
            this.type = String.isNotBlank(policy.PolicyType__c) ? policy.PolicyType__c : policy.ProductId__r.GroupDescription__c;
            this.partnerName = policy.Partner__r.GrandparentBusinessName__c;
            this.partnerSector = policy.Partner__r.PartnerSector__c;
            this.intermediaryCode = policy.IntermediaryId__r.INFOIntermediaryCode__c;
            this.intermediaryChannel = policy.IntermediaryId__r.Channel__c;
            this.intermediarySegment = policy.IntermediaryId__r.Segment__c;
            this.intermediaryEmail = policy.IntermediaryId__r.MainEmail__c;
            this.intermediaryPhone = String.isBlank(policy.IntermediaryId__r.Phone)? policy.IntermediaryId__r.MainMobilePhone__c : policy.IntermediaryId__r.Phone;
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa la información de los siniestros abiertos en el CRM
     *
     * @author adelgado
     * @last modified on  : 22-05-2024
     * @last modified by  : jfherrero
     */
    public class OpenedClaims
    {
        public String intent;
        public Map<String, List<OpenedClaim>> byOwner;
        public Map<String, List<OpenedClaim>> byType;
        public Boolean hasMultipleTypes
        {
            get
            {
                return this.byType.size() > 1;
            }
        }
        public Boolean hasDifferentOwners
        {
            get
            {
                return !this.hasMultipleTypes && this.byOwner.size() > 1;
            }
        }

        public Integer total
        {
           get
           {
                return this.claims.size();
           }
        }

        public OpenedClaim preferredClaim
        {
            get
            {
                switch on intent {
                    when 'CONS_HOG'
                    {
                        return getClaimHogar();
                    }	
                    when 'CONS_COM'
                    {
                        return getClaimComercio();
                    }
                    when 'CONS_PYMS'
                    {
                        return getClaimPYMES();
                    }
                    when else
                    {
                        if(total == 0 || (total != 1 && hasDifferentOwners))
                        {
                            return null;
                        }

                        return this.claims[0];
                    }
                }      
            }
        }

        private OpenedClaim getClaimHogar ()
        {
            if (this.byType.get('HOGAR') != null && this.byType.get('HOGAR').size()>0)
            {
                return this.byType.get('HOGAR')[0];
            }
            else if (this.byType.get('INMUEBLES') != null && this.byType.get('INMUEBLES').size()>0)
            {
                return this.byType.get('INMUEBLES')[0];
            }
            else if (this.byType.get('COMERCIOS') != null && this.byType.get('COMERCIOS').size()>0)
            {
                return this.byType.get('COMERCIOS')[0];
            }
            else if (this.byType.get('PYMES') != null && this.byType.get('PYMES').size()>0)
            {
                return this.byType.get('PYMES')[0];
            }
            else
            {
                return null;
            }
        }

        private OpenedClaim getClaimComercio ()
        {
            if (this.byType.get('INMUEBLES') != null && this.byType.get('INMUEBLES').size()>0)
            {
                return this.byType.get('INMUEBLES')[0];
            }
            else if (this.byType.get('HOGAR') != null && this.byType.get('HOGAR').size()>0)
            {
                return this.byType.get('HOGAR')[0];
            }
            else if (this.byType.get('COMERCIOS') != null && this.byType.get('COMERCIOS').size()>0)
            {
                return this.byType.get('COMERCIOS')[0];
            }
            else if (this.byType.get('PYMES') != null && this.byType.get('PYMES').size()>0)
            {
                return this.byType.get('PYMES')[0];
            }
            else
            {
                return null;
            }
        }

        private OpenedClaim getClaimPYMES ()
        {
            if (this.byType.get('PYMES') != null && this.byType.get('PYMES').size()>0)
            {
                return this.byType.get('PYMES')[0];
            }
            else if (this.byType.get('COMERCIOS') != null && this.byType.get('COMERCIOS').size()>0)
            {
                return this.byType.get('COMERCIOS')[0];
            }
            else if (this.byType.get('INMUEBLES') != null && this.byType.get('INMUEBLES').size()>0)
            {
                return this.byType.get('INMUEBLES')[0];
            }
            else if (this.byType.get('HOGAR') != null && this.byType.get('HOGAR').size()>0)
            {
                return this.byType.get('HOGAR')[0];
            }
            else
            {
                return null;
            }
        }

        private List<OpenedClaim> claims;

        public OpenedClaims (List<Claim__c> claims)
        {
            this.claims = new List<OpenedClaim>();
            byOwner = new Map<String, List<OpenedClaim>>();
            byType = new Map<String, List<OpenedClaim>>();

            for(Claim__c claim: claims)
            {
                this.add(new OpenedClaim(claim));
            }
        }

        public OpenedClaims (List<Claim__c> claims, String intent)
        {
            this.intent = intent;
            this.claims = new List<OpenedClaim>();
            byOwner = new Map<String, List<OpenedClaim>>();
            byType = new Map<String, List<OpenedClaim>>();

            for(Claim__c claim: claims)
            {
                this.add(new OpenedClaim(claim));
            }
        }

        public void add(OpenedClaim claim)
        {
            this.claims.add(claim);

            if(String.isNotBlank(claim.ownerTeam))
            {
                if(!byOwner.containsKey(claim.ownerTeam))
                {
                    byOwner.put(claim.ownerTeam, new List<OpenedClaim>());
                }

                byOwner.get(claim.ownerTeam).add(claim);
            }

            if(String.isNotBlank(claim.policyType))
            {
                if(!byType.containsKey(claim.policyType))
                {
                    byType.put(claim.policyType, new List<OpenedClaim>());
                }

                byType.get(claim.policyType).add(claim);
            }
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa la información de un siniestro abierto en una póliza en el CRM
     *
     * @author adelgado
     */
    public class OpenedClaim
    {
        public String id;
        public String ownerTeam;
        public String ownerFullname;
        public String ownerNationalId;
        public String status;
        public String carRegistration;
        public String claimNumber;
        public ActivePolicy policy;
        public String policyType
        {
            get
            {
                return policy != null? policy.type:'';
            }
        }

        public OpenedClaim() {}
        public OpenedClaim(Claim__c claim)
        {
            this.id = claim.id;
            this.ownerTeam = claim.ClaimOwnerTeamCode__c;
            this.ownerFullname = String.join(new List<String>{claim.ClaimOwnerFirstName__c, claim.ClaimOwnerFirstName__c, claim.ClaimOwnerFirstName__c}, ' ').toUpperCase();
            this.ownerNationalId = claim.ClaimOwnerNationalId__c;
            this.status = claim.Status__c;
            this.carRegistration = claim.InsuredObject__r.RegistrationNumber__c;
            this.claimNumber = claim.Name;
            this.policy = new ActivePolicy(claim.Policy__r);
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    /**
     * Representa si un Customer es Digital (KLINC)
     */
    public class DigitalCustomer
    {
        public Boolean isDigitalCustomer;
        public String searchType;
        public String value
        {
            get
            {
                return cleanTerm(value, searchType);
            }
            set;
        }

        public DigitalCustomer() {}
        public DigitalCustomer(Map<String, String> paramsByName)
        {
            this.searchType = paramsByName.get('searchType');
            this.value = paramsByName.get('value');
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }

        /**
         * Removes the whitespaces and converts characters to uppercase in the term parameter
         *
         * @author nts (agonzalezisasi)
         */
        private String cleanTerm(String term, String type)
        {
            String result = String.isEmpty(term)? '':term;

            switch on type {
                when 'document' {
                    result = result.deleteWhitespace().toUpperCase();
                }
                when else 
                {
                    // else code
                }
            }

            return result;
        }
    }

    /**
     * Representa los resultados de búsqueda del CRM para búsquedas de Auto
     *
     * @author  jfherrero
     * @date    19/03/2024
     */
    public class SearchResultAuto
    {
        public transient List<Contact> names;
        public transient List<SObject> relatedRecords;
        public String screenPopRecordId;
        public String phone;
        public String email;
        public Integer totalPolicies;
        public Integer totalQuotes;
        public ClaimAuto claim;
        public PolicyAuto policy;
        public String nationalId;

        //Estadísticas/Informes
        public Boolean identifiedByNIF;
        public Boolean identifiedByANI;
        public Boolean noIdentified;
        public Boolean multiIdentifiedByNIF;
        public Boolean multiIdentifiedByANI;

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }
    
    /**
     * Representa la información de un siniestro abierto en una póliza en el CRM
     *
     * @author jfherrero
     */
    public class ClaimAuto
    {
        public String id;
        public String ownerTeam;
        public String ownerTeamCode;
        public String ownerFullname;
        public String ownerNationalId;
        public String status;
        public String carRegistration;
        public String carBrand;
        public String carModel;
        public String claimNumber;
        public String claimType;

        public ClaimAuto() {}
        public ClaimAuto(Claim__c claim)
        {
            this.id = claim.id;
            this.ownerTeam = claim.ClaimOwnerTeamName__c;
            this.ownerTeamCode = claim.ClaimOwnerTeamCode__c;
            this.ownerFullname = String.join(new List<String>{claim.ClaimOwnerName__c, claim.ClaimOwnerFirstName__c, claim.ClaimOwnerLastName__c}, ' ').toUpperCase();
            this.ownerNationalId = claim.ClaimOwnerNationalId__c;
            this.status = claim.Status__c;
            this.carRegistration = claim.InsuredObject__r.RegistrationNumber__c;
            this.carBrand = claim.InsuredObject__r.BrandName__c;
            this.carModel = claim.InsuredObject__r.Model__c;
            this.claimNumber = claim.Name;
            this.claimType = claim.ClaimType__c;
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }
    
    
    /**
     * Representa la información de una póliza de auto activa en el CRM
     *
     * @author jfherrero
     */
    public class PolicyAuto
    {
        public String id;
        public String policyCode;
        public String policyTechnicalCode;
        public String policyCommercialCode;
        public String type;
        public String intermediaryClass;
        public String partnerId;
        public String destinationCode;
        public String partnerName;
        public String partnerSector;
        public String intermediaryCode;
        public String intermediaryDescription;
        public String intermediaryChannel;
        public String intermediaryPhone;
        public String intermediaryEmail;
        public String intermediarySegment;
        public String intermediarySegmentDescription;
        public String holderName;
        public String holderNationalId;


        public PolicyAuto(){}
        public PolicyAuto(Policy__c policy)
        {
            this.id = policy.id;
            this.policyCode = policy.Name;
            this.policyTechnicalCode = policy.TechnicalCode__c;
            this.policyCommercialCode = policy.CommercialCode__c;
            this.type = String.isNotBlank(policy.PolicyType__c) ? policy.PolicyType__c : policy.ProductId__r.GroupDescription__c;
            this.intermediaryClass = policy.IntermediaryId__r.ClassDescription__c;
            this.partnerId = policy.Partner__c;
            this.destinationCode = policy.Partner__r.PartnerSFCode__c;
            this.partnerName = policy.Partner__r.GrandparentBusinessName__c;
            this.partnerSector = policy.Partner__r.PartnerSector__c;
            this.intermediaryCode = policy.IntermediaryId__r.INFOIntermediaryCode__c;
            this.intermediaryDescription = policy.IntermediaryId__r.IntermediaryDescription__c;
            this.intermediaryChannel = policy.IntermediaryId__r.Channel__c;
            this.intermediaryPhone = String.isBlank(policy.IntermediaryId__r.Phone)? policy.IntermediaryId__r.MainMobilePhone__c : policy.IntermediaryId__r.Phone;
            this.intermediaryEmail = policy.IntermediaryId__r.MainEmail__c;
            this.intermediarySegment = policy.IntermediaryId__r.Segment__c;
            this.intermediarySegmentDescription = policy.IntermediaryId__r.SegmentDescription__c;
            this.holderName = policy.PolicyHolder__r.Name;
            this.holderNationalId = policy.PolicyHolder__r.NationalId__c;
        }
        public PolicyAuto(Claim__c claim)
        {
            this.id = claim.Policy__r.id;
            this.policyCode = claim.Policy__r.Name;
            this.policyTechnicalCode = claim.Policy__r.TechnicalCode__c;
            this.policyCommercialCode = claim.Policy__r.CommercialCode__c;
            this.type = String.isNotBlank(claim.Policy__r.PolicyType__c) ? claim.Policy__r.PolicyType__c : claim.Policy__r.ProductId__r.GroupDescription__c;
            this.intermediaryClass = claim.Policy__r.IntermediaryId__r.ClassDescription__c;
            this.partnerId = claim.Policy__r.Partner__c;
            this.destinationCode = claim.Policy__r.Partner__r.PartnerSFCode__c;
            this.partnerName = claim.Policy__r.Partner__r.GrandparentBusinessName__c;
            this.partnerSector = claim.Policy__r.Partner__r.PartnerSector__c;
            this.intermediaryCode = claim.Policy__r.IntermediaryId__r.INFOIntermediaryCode__c;
            this.intermediaryDescription = claim.Policy__r.IntermediaryId__r.IntermediaryDescription__c;
            this.intermediaryChannel = claim.Policy__r.IntermediaryId__r.Channel__c;
            this.intermediaryPhone = String.isBlank(claim.Policy__r.IntermediaryId__r.Phone)? claim.Policy__r.IntermediaryId__r.MainMobilePhone__c : claim.Policy__r.IntermediaryId__r.Phone;
            this.intermediaryEmail = claim.Policy__r.IntermediaryId__r.MainEmail__c;
            this.intermediarySegment = claim.Policy__r.IntermediaryId__r.Segment__c;
            this.intermediarySegmentDescription = claim.Policy__r.IntermediaryId__r.SegmentDescription__c;
            this.holderName = claim.Policy__r.PolicyHolder__r.Name;
            this.holderNationalId = claim.Policy__r.PolicyHolder__r.NationalId__c;
        }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }
    
    public class GenesysInteractionsServiceException extends Exception {}

    public class GenesysPeopleServiceException extends Exception {}

    public class GenesysPoliciesServiceException extends Exception {}

    public class GenesysClaimsServiceException extends Exception {}
}