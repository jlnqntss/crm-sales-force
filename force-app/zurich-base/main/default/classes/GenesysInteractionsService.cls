public without sharing class GenesysInteractionsService
{
    public static Integer version { get; set; }
    @TestVisible
    static final String MISSING_FIELDS_REQUIRED = 'some required fields are missing';
    @TestVisible
    static final String SCOPE_CODE_ALL = 'all';
    @TestVisible
    static final String SCOPE_CODE_ZE = 'ze';
    @TestVisible
    static final String SCOPE_CODE_KLINC = 'klinc';
    static final Map<String, String> SCOPE_NAMES_BY_CODE = new Map<String, String> 
    {
        SCOPE_CODE_ALL  => 'General',
        SCOPE_CODE_ZE => 'Zurich Empresas',
        SCOPE_CODE_KLINC => 'Klinc'
    };

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
        if ( String.isBlank(request.interactionId) || String.isBlank(request.interactionType) || String.isBlank(request.fromId) || String.isBlank(request.toId) || String.isBlank(request.lookFor))
        {
            throw new GenesysInteractionsServiceException(MISSING_FIELDS_REQUIRED);
        }

        // 2 - Se identifica el mejor agente disponible - el método asigna en consencuencia el registro sobre el que realizar un screenPop
        findBestAgentFor(request);

        // 3 - Se una tarea como registro dela interacción en cola
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
            TaskSubtype = 'Call'
        );

        if(interactionLog.screenPopRecordId != null && Id.valueOf(interactionLog.screenPopRecordId).getSobjectType() != Contact.SobjectType)
        {
            interactionTask.WhatId = interactionLog.screenPopRecordId;
        }

        insert interactionTask;

        interactionLog.callLogId = interactionTask.Id;

        return interactionTask.Id;
    }


    public static SearchResult findRelatedRecords(Interaction interactionLog)
    {
        return findRelatedRecords(
            interactionLog.interactionType == 'Outbound'? interactionLog.toId:interactionLog.fromId, 
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

        if (searchFor.contains('@'))
        {
            return ContactsSelector.findByEmail(new List<String> { searchFor });
        }

        return ContactsSelector.findByPhoneNumber(new List<String> { searchFor });
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
        if(!searchResults.names.isEmpty())
        {
            matchedContact = searchResults.names[0];
            interaction.customerId = matchedContact.Id;
            interaction.screenPopRecordId = matchedContact.Id;
        }

        if(!searchResults.relatedRecords.isEmpty())
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

    //Salida
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
        public String bestAgentId { get; set; }

        public override String toString()
        {
            return JSON.serialize(this);
        }
    }

    public class SearchResult
    {
        public transient List<Contact> names;
        public transient List<SObject> relatedRecords;
    }

    @TestVisible
    class GenesysInteractionsServiceException extends Exception {}
}