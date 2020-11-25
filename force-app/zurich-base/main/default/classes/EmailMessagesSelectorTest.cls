@isTest
private with sharing class EmailMessagesSelectorTest
{
    static final Integer BULK_NUM_RECORDS = 10;
    @TestSetup
    public static void createScenario()
    {
        List<EmailMessage> parentEmailMessages = TestDataFactory.generateEmailMessages(BULK_NUM_RECORDS);
        insert parentEmailMessages;

        List<EmailMessage> childEmailMessages = TestDataFactory.generateEmailMessagesFromEmailMessages(parentEmailMessages, 1);
        insert childEmailMessages;

        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunities(accounts, 'ZE', 'Qualification', System.today(), BULK_NUM_RECORDS);
        insert opportunities;

        List<EmailMessage> emailMessagesRelatedToOpportunities = TestDataFactory.generateEmailMessagesFromOpportunities(opportunities, 1);
        insert emailMessagesRelatedToOpportunities;

        List<EmailMessageRelation> emailMessageRelations = TestDataFactory.generateEmailMessageRelations(emailMessagesRelatedToOpportunities, UserInfo.getUserId(), 'ToAddress');
        insert emailMessageRelations;
    }

    @isTest
    static void test_fieldsToQuery_getInvalidFields()
    {
        Set<String> invalidFieldsSet = new Set<String> {'InvalidField1', 'InvalidField2'};

        //Buscamos EmailMessage que tenga ese Id como MessageIdentifier (indica que es una respuesta sobre ese email)
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        emailMessagesSelectorObj.sObjectToQuery = 'EmailMessage';
        emailMessagesSelectorObj.fieldsToQuery = invalidFieldsSet;

        Set<String> fieldsToQueryGet = emailMessagesSelectorObj.fieldsToQuery;
        Test.stopTest();

        System.assertEquals(1, fieldsToQueryGet.size(), 'The set size should be 1');
        System.assertEquals(true, fieldsToQueryGet.contains('Id'), 'The set should contains Id field');
    }

    @isTest
    static void test_selectByMessageIdentifier_matchedRecords()
    {
        //Recuperamos todos los emails que tengan MessageIdentifier
        List<EmailMessage> childEmailMessages = [SELECT Id, RelatedToId, MessageIdentifier FROM EmailMessage WHERE MessageIdentifier != null];
        System.assertEquals(false, childEmailMessages.isEmpty(), 'List should NOT be empty');

        //Almacenamos el Id del EmailMessage en un Set de Strings para pasar como parametro al selector
        Set<String> setToSearch = new Set<String> {childEmailMessages.get(0).MessageIdentifier};

        //Buscamos EmailMessage que tenga ese Id como MessageIdentifier (indica que es una respuesta sobre ese email)
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        List<EmailMessage> relatedEmails = emailMessagesSelectorObj.selectByMessageIdentifier(setToSearch);
        Test.stopTest();

        System.assertEquals(false, relatedEmails.isEmpty(), 'The list shouldnt be empty');

        //Comprobamos que, de los emails que hemos recuperado, el MessageIdentifier encaja con los que hemos buscado
        List<EmailMessage> relatedEmailsInfo = [SELECT Id, MessageIdentifier FROM EmailMessage WHERE Id IN : relatedEmails];
        for(EmailMessage relatedEmail: relatedEmailsInfo)
        {
            System.assertEquals(true, setToSearch.contains(relatedEmail.MessageIdentifier), 'setToSearch should contains EmailMessage MessageIdentifier');
        }
    }

    @isTest
    static void test_selectByMessageIdentifier_matchedRecords_bulk()
    {
        //Recuperamos un email que no tenga MessageIdentifier (un email padre)
        List<EmailMessage> emailsMessageToSearch = [SELECT Id, MessageIdentifier FROM EmailMessage WHERE MessageIdentifier != null];
        System.assertEquals(true, emailsMessageToSearch.size() >= BULK_NUM_RECORDS, 'There should be greater than ' + BULK_NUM_RECORDS);

        //Almacenamos los Ids delEmailMessages en un Set de Strings para pasar como parametro al selector
        Set<String> setToSearch = new Set<String>();
        for(EmailMessage emailMessage: emailsMessageToSearch)
        {
            setToSearch.add(emailMessage.MessageIdentifier);
        }

        //Buscamos EmailMessage que tenga ese Id como MessageIdentifier (indica que es una respuesta sobre ese email)
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id', 'MessageIdentifier'};
        List<EmailMessage> relatedEmails = emailMessagesSelectorObj.selectByMessageIdentifier(setToSearch);
        Test.stopTest();

        System.assertEquals(false, relatedEmails.isEmpty(), 'The list shouldnt be empty');

        //Comprobamos que, de los emails que hemos recuperado, el MessageIdentifier encaja con los que hemos buscado
        Set<String> messageIdentifierSet = new Set<String>();
        for(EmailMessage relatedEmail: relatedEmails)
        {
            messageIdentifierSet.add(relatedEmail.MessageIdentifier);
        }

        System.assertEquals(true, setToSearch.containsAll(messageIdentifierSet), 'Set should cotains all MessageIdentifiers from related EmailMessages');
    }

    @isTest
    static void test_selectByMessageIdentifier_notFound_matchedRecords()
    {
        //Almacenamos un Id que no existe en un Set de Strings para pasar como parametro al selector
        Set<String> setToSearch = new Set<String> {'InvalidId'};

        //Buscamos EmailMessage que tenga ese Id como MessageIdentifier (indica que es una respuesta sobre ese email)
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        List<EmailMessage> relatedEmails = emailMessagesSelectorObj.selectByMessageIdentifier(setToSearch);
        Test.stopTest();

        System.assertEquals(true, relatedEmails.isEmpty(), 'The list should be empty');
    }

    @isTest
    static void test_selectByMessageIdentifier_emptyMessageIdentifiers()
    {
        //Utilizamos el selector pasando como parámetro un Set vacio
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        List<EmailMessage> relatedEmails = emailMessagesSelectorObj.selectByMessageIdentifier( new Set<String>() );
        Test.stopTest();

        System.assertEquals(true, relatedEmails.isEmpty(), 'The list shouldnt be empty');
    }

    @isTest
    static void test_selectByMessageIdentifier_nullMessageIdentifiers()
    {
        //Utilizamos el selector pasando como parámetro un valor nulo
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        List<EmailMessage> relatedEmails = emailMessagesSelectorObj.selectByMessageIdentifier(null);
        Test.stopTest();

        System.assertEquals(true, relatedEmails.isEmpty(), 'The list shouldnt be empty');
    }

    @isTest
    static void test_selectBySubject_matchedRecords()
    {
        //Recuperamos un email aleatorio
        List<EmailMessage> randomEmail = [SELECT Id, Subject FROM EmailMessage LIMIT 1];
        System.assertEquals(1, randomEmail.size(), 'There should be 1 EmailMessage');

        //Almacenamos el asunto del EmailMessage en una lista de Strings para pasar como parametro al selector
        List<String> subjectsToSearch = new List<String> {randomEmail.get(0).Subject};

        //Buscamos EmailMessage que tenga ese Id como MessageIdentifier (indica que es una respuesta sobre ese email)
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id', 'Subject'};
        List<EmailMessage> matchedRecords = emailMessagesSelectorObj.selectBySubject(subjectsToSearch);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'The list shouldnt be empty');

        //Comprobamos que, de los emails que hemos recuperado, el asunto encaja con los que hemos buscado
        for(EmailMessage matchedEmail: matchedRecords)
        {
            System.assertEquals(true, matchedEmail.Subject == subjectsToSearch.get(0), 'Subjects should be the same');
        }
    }

    @isTest
    static void test_selectBySubject_emptySubjects()
    {
        //Utilizamos el selector pasando como parámetro un Set vacio
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        List<EmailMessage> relatedEmails = emailMessagesSelectorObj.selectBySubject( new List<String>() );
        Test.stopTest();

        System.assertEquals(true, relatedEmails.isEmpty(), 'The list shouldnt be empty');
    }

    @isTest
    static void test_selectByRelatedObjectId_matchedRecords()
    {
        //Recuperamos un email aleatorio
        List<EmailMessage> randomEmail = [SELECT Id, RelatedToId FROM EmailMessage WHERE RelatedToId != null LIMIT 1];
        System.assertEquals(1, randomEmail.size(), 'There should be 1 EmailMessage');

        Set<String> setToSearch = new Set<String> {randomEmail.get(0).RelatedToId};

        //Buscamos EmailMessage que tenga ese Id como RelatedToId
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id', 'RelatedToId'};
        List<EmailMessage> matchedRecords = emailMessagesSelectorObj.selectByRelatedObjectId(setToSearch);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'The list shouldnt be empty');

        //Comprobamos que, de los emails que hemos recuperado, el asunto encaja con los que hemos buscado
        for(EmailMessage matchedEmail: matchedRecords)
        {
            System.assertEquals(true, setToSearch.contains(matchedEmail.RelatedToId), 'Set should contains RelatedToId');
        }
    }

    @isTest
    static void test_selectByRelatedObjectId_emptyRelatedObjects()
    {
        //Utilizamos el selector pasando como parámetro un Set vacio
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        List<EmailMessage> relatedEmails = emailMessagesSelectorObj.selectByRelatedObjectId( new Set<String>() );
        Test.stopTest();

        System.assertEquals(true, relatedEmails.isEmpty(), 'The list shouldnt be empty');
    }

    @isTest
    static void test_selectRelationByEmailAndRelation_matchedRecords()
    {
        //Recuperamos un email aleatorio
        List<EmailMessageRelation> randomEmailRelation = [SELECT Id, EmailMessageId, RelationId FROM EmailMessageRelation LIMIT 1];
        System.assertEquals(1, randomEmailRelation.size(), 'There should be 1 EmailMessage');

        Set<String> emailMessageIdSet = new Set<String> {randomEmailRelation.get(0).EmailMessageId};
        Set<String> relationIdSet = new Set<String> {randomEmailRelation.get(0).RelationId};

        //Buscamos EmailMessage que tenga ese Id como RelatedToId
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        emailMessagesSelectorObj.fieldsToQuery = new Set<String> {'Id', 'EmailMessageId', 'RelationId'};
        List<EmailMessageRelation> matchedRecords = emailMessagesSelectorObj.selectRelationByEmailAndRelation(emailMessageIdSet, relationIdSet);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'The list shouldnt be empty');

        //Comprobamos que, de los emails que hemos recuperado, el asunto encaja con los que hemos buscado
        for(EmailMessageRelation matchedEmailRelation: matchedRecords)
        {
            System.assertEquals(true, emailMessageIdSet.contains(matchedEmailRelation.EmailMessageId), 'Set should contains EmailMessageId');
            System.assertEquals(true, relationIdSet.contains(matchedEmailRelation.RelationId), 'Set should contains RelationId');
        }
    }

    @isTest
    static void test_selectRelationByEmailAndRelation_emptyRelations()
    {
        //Utilizamos el selector pasando como parámetro un Set vacio
        Test.startTest();
        EmailMessagesSelector emailMessagesSelectorObj = new EmailMessagesSelector();
        List<EmailMessageRelation> relatedEmailRelations = emailMessagesSelectorObj.selectRelationByEmailAndRelation( new Set<String>(), new Set<String>() );
        Test.stopTest();

        System.assertEquals(true, relatedEmailRelations.isEmpty(), 'The list shouldnt be empty');
    }

    //#region selectByInteractionId

    /**
     * Prueba la Query del selector con entrada null
     * @author jmartinezpisson
     * @date 17/11/2020
     */
    @isTest
    static void test_selectByInteractionId_nullInput()
    {
        Test.startTest();

        List<EmailMessage> selectedEmailMessages = new EmailMessagesSelector().selectByInteractionId(null);

        Test.stopTest();

        System.assertEquals(true, selectedEmailMessages.isEmpty(), 'Se debería recibir una lista vacía');
    }

    /**
     * Prueba la Query del selector con entrada vacía
     * @author jmartinezpisson
     * @date 17/11/2020
     */
    @isTest
    static void test_selectByInteractionId_emptyInput()
    {
        Test.startTest();

        List<EmailMessage> selectedEmailMessages = new EmailMessagesSelector().selectByInteractionId( new Set<String>() );

        Test.stopTest();

        System.assertEquals(true, selectedEmailMessages.isEmpty(), 'Se debería recibir una lista vacía');
    }


    /**
     * Prueba la Query del selector con Ids. reales
     * @author jmartinezpisson
     * @date 17/11/2020
     */
    @isTest
    static void test_selectByInteractionId_recordInput()
    {
        // When
        // Se simula una situación en que los EmailMessages tienen interactionIds
        List<EmailMessage> emailMessages = new List<EmailMessage>();
        Set<String> interactionIds = new Set<String>();

        for(EmailMessage message : [SELECT Id, GenesysInteractionId__c FROM EmaiLMessage LIMIT 10])
        {
            interactionIds.add( 'genesys-id-' + emailMessages.size() );
            message.GenesysInteractionId__c = 'genesys-id-' + emailMessages.size();
            emailMessages.add(message);
        }

        update emailMessages;

        // Test
        Test.startTest();

        Map<Id, EmailMessage> selectedEmailMessagesById = new Map<Id, EmailMessage>( new EmailMessagesSelector().selectByInteractionId(interactionIds) );

        Test.stopTest();

        // Then
        System.assertEquals(emailMessages.size(), selectedEmailMessagesById.size(), 'Se debería recibir una lista no vacía');
        System.assertEquals(true, selectedEmailMessagesById.keySet().containsAll( new Map<Id, EmailMessage>(emailMessages).keySet() ), 'No contiene todos los ids de email');
    }


    //#endregion
}