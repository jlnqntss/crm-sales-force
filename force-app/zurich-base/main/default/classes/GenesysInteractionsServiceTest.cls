@isTest(SeeAllData = false)
public without sharing class GenesysInteractionsServiceTest
{
    /**
     * creación de registros necesarios
     **
     * @author nescudero
     * @date 23/10/2020
     */
    @testSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;
        //Actualizar con los datos usados en los test
        accounts.get(0).NationalId__c = '777888111Y';
        update accounts.get(0);

        List<Account> intermediaries = TestDataFactory.generateAccounts('001', 'Intermediary', 10);
        insert intermediaries;
        //Actualizar con los datos usados en los test
        intermediaries.get(0).INFOIntermediaryCode__c = '0999888777';
        intermediaries.get(0).Phone = '111555777';
        update intermediaries.get(0);

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 10);
        insert contactPointPhones;
        //Actualizar con los datos usados en los test
        contactPointPhones.get(0).TelephoneNumber = '123456789';
        update contactPointPhones.get(0);

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 10);
        insert contactPointEmails;
        //Actualizar con los datos usados en los test
        contactPointEmails.get(0).EmailAddress = 'nescudero@nts-solutions.com';
        update contactPointEmails.get(0);

        //se crea 1 caso para cada cuenta
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

        //se crea 1 caso para cada cuenta de mediador
        List<Case> intermediaryCases = TestDataFactory.generateCasesForEachAccount(intermediaries, 1);
        insert intermediaryCases;

        //Se crea 1 opp para cada cuenta
        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert opportunities;

        //se crea 1 póliza para cada cuenta
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 10);
        insert policies;
        policies.get(0).InfoPolicyNumber__c = '666777111333';
        update policies.get(0);

        List<Task> tasks = TestDataFactory.generateInteractionTasks(10);
        insert tasks;
    }


    // #region initInteraction tests

    /**
     * Valida el escenario en el que para un interacción Inbound hay una oportunidad abierta para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_initInteraction_noInteractionId()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '4000';
        testInteractionLog.interactionId =null;
        testInteractionLog.toId = '123456789';
        testInteractionLog.interactionType = 'Outbound';
        testInteractionLog.lookFor = 'Opportunity';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : testInteractionLog.toId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        GenesysInteractionsService.GenesysInteractionsServiceException expectedError;

        Test.startTest();

        try
        {
            GenesysInteractionsService.initInteraction(testInteractionLog);
        }
        catch(GenesysInteractionsService.GenesysInteractionsServiceException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        // Then
        System.assertNotEquals(null, expectedError, 'No se ha lanzado una excepción');
    }


    /**
     * Valida el escenario en el que para un interacción Inbound hay una oportunidad abierta para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_initInteraction_outboundMatchedOpportunityPhoneInteraction()
    {
        //TODO: Mejora -> Sobrecargar método en TestDataFactory.generateOpportunitiesForEachAccount() con nuevo parámetro ownerID sin romper test antiguos
        //Controlar el email que tiene UserInfo:
        Id testUserId = UserInfo.getUserId();
        User testUser = new User(Id = testUserId, Email = 'emailfortesting@nts-solutions.com');
        update testUser;

        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '4000';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '123456789';
        testInteractionLog.interactionType = 'Outbound';
        testInteractionLog.lookFor = 'Opportunity';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : testInteractionLog.toId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.initInteraction(testInteractionLog);

        Test.stopTest();

        // Then
        Opportunity expectedOpportunity = [SELECT AccountId, Owner.Email, OwnerId FROM Opportunity LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email, BestAgent__c, WhatId, WhoId, Status, CallObject FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedOpportunity.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedOpportunity.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(false, expectedTasks.isEmpty(), 'No se han generado tareas');
        System.assertEquals(expectedTasks[0].Id, testInteractionLog.callLogId, 'No coinciden el Id. de tarea');
        System.assertEquals(expectedTasks[0].CallObject, testInteractionLog.interactionId, 'No coinciden el Id. de tarea');
        System.assertEquals(expectedTasks[0].WhoId, testInteractionLog.customerId, 'No coinciden el Id. de cliente de tarea');
        System.assertEquals(expectedTasks[0].WhatId, testInteractionLog.screenPopRecordId, 'No coinciden el Id. de registro relacionado de tarea');
        System.assertEquals(expectedTasks[0].Status, 'Nueva', 'El estado de la tarea no es el inicial');
        System.assertEquals(expectedTasks[0].BestAgent__c, expectedOpportunity.OwnerId, 'El Lookup de BestAgent debería estar relleno con el ID del usuario que tenga el Email que se ha pasado a Genesys');
    }

    /**
     * Valida el escenario en el que para un interacción Inbound hay que identificar al mediador
     **
     * @author adelgado
     * @date 26/11/2020
     */
    @IsTest
    static void test_initInteraction_inboundMatchedIntermediary()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '111555777';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '123456789';
        testInteractionLog.interactionType = 'Inbound';
        testInteractionLog.lookFor = 'Case';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_CSM;

        // SOSL - Resultados de búsqueda
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        Set<Id> recordIds = new Map<Id, Account> ([SELECT Id FROM Account WHERE RecordtypeId = : intermediaryRecordTypeId AND Phone = '111555777']).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.initInteraction(testInteractionLog);

        Test.stopTest();

        // Then
        List<Account> expectedAccounts = AccountsSelector.selectById(recordIds, new Set<String> {'Id'});
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email, WhatId, WhoId, Status, CallObject FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedAccounts[0].Id, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de mediador');

        System.assertEquals(false, expectedTasks.isEmpty(), 'No se han generado tareas');
        System.assertEquals(expectedTasks[0].Id, testInteractionLog.callLogId, 'No coinciden el Id. de tarea');
        System.assertEquals(expectedTasks[0].CallObject, testInteractionLog.interactionId, 'No coinciden el Id. de tarea');
        System.assertEquals(expectedTasks[0].WhoId, testInteractionLog.customerId, 'No coinciden el Id. de cliente de tarea');
        System.assertEquals(expectedTasks[0].WhatId, testInteractionLog.screenPopRecordId, 'No coinciden el Id. de registro relacionado de tarea');
        System.assertEquals(expectedTasks[0].Status, 'Nueva', 'El estado de la tarea no es el inicial');
    }


    // #endregion

    // #region findBestAgentFor tests


    /**
     * Valida el escenario en el que para un interacción Inbound hay una oportunidad abierta para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_noRecordMatches()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '123456789';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';
        testInteractionLog.lookFor = 'Opportunity';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        delete [SELECT Id FROM Opportunity];

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : testInteractionLog.fromId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(testInteractionLog.customerId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de cliente');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(null, testInteractionLog.bestAgentId, 'El id. de agenet no es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }

    /**
     * Valida el escenario en el que para un interacción Inbound hay una oportunidad abierta para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_ByPhone_inboundMatchedOpportunityInteraction()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '123456789';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';
        testInteractionLog.lookFor = 'Outbound';
        testInteractionLog.lookFor = 'Opportunity';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : testInteractionLog.fromId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        Opportunity expectedOpportunity = [SELECT AccountId, Owner.Email FROM Opportunity LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedOpportunity.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedOpportunity.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }

    /**
     * Valida el escenario en el que para un interacción Inbound hay una oportunidad abierta para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_ByPhone_outboundMatchedOpportunityInteraction()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '4000';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '123456789';
        testInteractionLog.interactionType = 'Outbound';
        testInteractionLog.lookFor = 'Opportunity';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : testInteractionLog.toId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        Opportunity expectedOpportunity = [SELECT AccountId, Owner.Email FROM Opportunity LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedOpportunity.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedOpportunity.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }


    /**
     * Valida el escenario en el que para un interacción Inbound hay una caso abierto para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_ByPhone_inboundMatchedCaseInteraction()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '123456789';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';
        testInteractionLog.lookFor = 'Case';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : testInteractionLog.fromId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        Case expectedCase = [SELECT AccountId, Owner.Email FROM Case LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedCase.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedCase.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }

    /**
     * Valida el escenario en el que para un interacción Outbound hay un caso abierto para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_ByPhone_outboundMatchedCaseInteraction()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '4000';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '123456789';
        testInteractionLog.interactionType = 'Outbound';
        testInteractionLog.lookFor = 'Case';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : testInteractionLog.toid]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        Case expectedCase = [SELECT AccountId, Owner.Email FROM Case LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedCase.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedCase.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }


    /**
     * Valida el escenario en el que para un interacción Inbound hay una oportunidad abierta para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_ByEmailinboundMatchedOpportunityInteraction()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = 'nescudero@nts-solutions.com';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';
        testInteractionLog.lookFor = 'Outbound';
        testInteractionLog.lookFor = 'Opportunity';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointEmail> ([SELECT Id FROM ContactPointEmail WHERE EmailAddress = : testInteractionLog.fromId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        Opportunity expectedOpportunity = [SELECT AccountId, Owner.Email FROM Opportunity LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedOpportunity.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedOpportunity.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }

    /**
     * Valida el escenario en el que para un interacción Inbound hay una oportunidad abierta para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_ByEmail_outboundMatchedOpportunityInteraction()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '4000';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = 'nescudero@nts-solutions.com';
        testInteractionLog.interactionType = 'Outbound';
        testInteractionLog.lookFor = 'Opportunity';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointEmail> ([SELECT Id FROM ContactPointEmail WHERE EmailAddress = : testInteractionLog.toId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        Opportunity expectedOpportunity = [SELECT AccountId, Owner.Email FROM Opportunity LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedOpportunity.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedOpportunity.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }


    /**
     * Valida el escenario en el que para un interacción Inbound hay una caso abierto para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_ByEmail_inboundMatchedCaseInteraction()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = 'nescudero@nts-solutions.com';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = '4000';
        testInteractionLog.interactionType = 'Inbound';
        testInteractionLog.lookFor = 'Outbound';
        testInteractionLog.lookFor = 'Case';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointEmail> ([SELECT Id FROM ContactPointEmail WHERE EmailAddress = : testInteractionLog.fromId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        Case expectedCase = [SELECT AccountId, Owner.Email FROM Case LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedCase.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedCase.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }

    /**
     * Valida el escenario en el que para un interacción Outbound hay un caso abierto para un cliente
     * relacioando
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findBestAgentFor_ByEmail_outboundMatchedCaseInteraction()
    {
        // When
        GenesysInteractionsService.Interaction testInteractionLog = new GenesysInteractionsService.Interaction();

        testInteractionLog.fromId = '4000';
        testInteractionLog.interactionId = '98976-dsa-ad';
        testInteractionLog.toId = 'nescudero@nts-solutions.com';
        testInteractionLog.interactionType = 'Outbound';
        testInteractionLog.lookFor = 'Case';
        testInteractionLog.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointEmail> ([SELECT Id FROM ContactPointEmail WHERE EmailAddress = : testInteractionLog.toId]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.findBestAgentFor(testInteractionLog);

        Test.stopTest();

        // Then
        Case expectedCase = [SELECT AccountId, Owner.Email FROM Case LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedCase.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedCase.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
        System.assertEquals(true, expectedTasks.isEmpty(), 'Se han generado tareas');
    }

    // #endregion

    // #region Test methods for findPeopleBy

    /**
     * Valida el escenario en el que para una búsqueda de teléfono hay un único resultado.
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findPeopleBy_Customer_Phone_matchedPerson()
    {
        // When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'phone';
        searchRequest.value = '123456789';
        searchRequest.filterBy  = 'customers';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'gi';

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : searchRequest.value]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.SearchResult result = GenesysInteractionsService.findPeopleBy(searchRequest);

        Test.stopTest();

        // Then
        List<Account> expectedAccounts = [SELECT Id FROM Account WHERE Id IN (SELECT ParentId FROM ContactPointPhone WHERE Id IN :recordIds )];

        System.assertEquals(1, expectedAccounts.size(), 'Debería haber encontrado un único resultado');
        System.assertEquals(expectedAccounts.get(0).Id, result.screenPopRecordId, 'Debería haber encontrado un único resultado');
    }

    /**
     * Valida el escenario en el que para una búsqueda de email hay un único resultado.
     **
     * @author adelgado
     * @date 23/11/2020
     */
    @IsTest
    static void test_findPeopleBy_Customer_Email_matchedPerson()
    {
        // When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'email';
        searchRequest.value = 'nescudero@nts-solutions.com';
        searchRequest.filterBy  = 'customers';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'gi';

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointEmail> ([SELECT Id FROM ContactPointEmail WHERE EmailAddress = : searchRequest.value]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.SearchResult result = GenesysInteractionsService.findPeopleBy(searchRequest);

        Test.stopTest();

        // Then
        List<Account> expectedAccounts = [SELECT Id FROM Account WHERE Id IN (SELECT ParentId FROM ContactPointEmail WHERE Id IN :recordIds )];

        System.assertEquals(1, expectedAccounts.size(), 'Debería haber encontrado un único resultado');
        System.assertEquals(expectedAccounts.get(0).Id, result.screenPopRecordId, 'Debería haber encontrado un único resultado');
    }

    /**
     * Valida el escenario en el que para una búsqueda de documento hay un único resultado.
     **
     * @author adelgado
     * @date 23/11/2020
     */
    @IsTest
    static void test_findPeopleBy_Customer_Document_matchedPerson()
    {
        // When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'document';
        searchRequest.value = '777888111Y';
        searchRequest.filterBy  = 'customers';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'gi';

        // Test
        Test.startTest();

        GenesysInteractionsService.SearchResult result = GenesysInteractionsService.findPeopleBy(searchRequest);

        Test.stopTest();

        // Then
        List<Account> expectedAccounts = [SELECT Id FROM Account WHERE NationalId__c = : searchRequest.value];

        System.assertEquals(1, expectedAccounts.size(), 'Debería haber encontrado un único resultado');
        System.assertEquals(expectedAccounts.get(0).Id, result.screenPopRecordId, 'Debería haber encontrado un único resultado');
    }

    /**
     * Valida el escenario en el que para una búsqueda de póliza hay un único resultado.
     **
     * @author adelgado
     * @date 23/11/2020
     */
    @IsTest
    static void test_findPeopleBy_Customer_PolicyCode_matchedPerson()
    {
        // When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'policy_code';
        searchRequest.value = '666777111333';
        searchRequest.filterBy  = 'customers';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'gi';

        // Test
        Test.startTest();

        GenesysInteractionsService.SearchResult result = GenesysInteractionsService.findPeopleBy(searchRequest);

        Test.stopTest();

        // Then
        List<Account> expectedAccounts = [SELECT Id FROM Account WHERE Id IN (SELECT PolicyHolder__c FROM Policy__c WHERE InfoPolicyNumber__c = : searchRequest.value)];

        System.assertEquals(1, expectedAccounts.size(), 'Debería haber encontrado un único resultado');
        System.assertEquals(expectedAccounts.get(0).Id, result.screenPopRecordId, 'Debería haber encontrado un único resultado');
    }

    /**
     * Valida el escenario en el que para una búsqueda de teléfono hay un único resultado.
     **
     * @author adelgado
     * @date 23/11/2020
     */
    @IsTest
    static void test_findPeopleBy_Intermediary_Phone_matchedPerson()
    {
        // When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'phone';
        searchRequest.value = '111555777';
        searchRequest.filterBy  = 'intermediaries';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'all';

        // SOSL - Resultados de búsqueda
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        Set<Id> recordIds = new Map<Id, Account> ([SELECT Id FROM Account WHERE RecordTypeId = : intermediaryRecordTypeId AND Phone = : searchRequest.value]).keySet();
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.SearchResult result = GenesysInteractionsService.findPeopleBy(searchRequest);

        Test.stopTest();

        // Then
        List<Account> expectedAccounts = AccountsSelector.selectById(recordIds, new Set<String> {'Id'});

        System.assertEquals(1, expectedAccounts.size(), 'Debería haber encontrado un único resultado');
        System.assertEquals(expectedAccounts.get(0).Id, result.screenPopRecordId, 'Debería haber encontrado un único resultado');
    }

    /**
     * Valida el escenario en el que para una búsqueda de código de intermerdiario hay un único resultado.
     **
     * @author adelgado
     * @date 23/11/2020
     */
    @IsTest
    static void test_findPeopleBy_Intermediary_IntermediaryCode_matchedPerson()
    {
        // When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'intermediary_code';
        searchRequest.value = '999888777';
        searchRequest.filterBy  = 'intermediaries';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'all';

        // Test
        Test.startTest();

        GenesysInteractionsService.SearchResult result = GenesysInteractionsService.findPeopleBy(searchRequest);

        Test.stopTest();

        // Then
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> expectedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = : intermediaryRecordTypeId AND InfoIntermediaryCode__c = : searchRequest.value.leftPad(10, '0')];

        System.assertEquals(1, expectedAccounts.size(), 'Debería haber encontrado un único resultado');
        System.assertEquals(expectedAccounts.get(0).Id, result.screenPopRecordId, 'Debería haber encontrado un único resultado');
    }

    /**
     * Valida que en caso de no recibir todos los parámetros necesarios devuelve una excepción
     **
     * @author adelgado
     * @date 25/11/2020
     */
    @IsTest
    static void test_findPeopleBy_RequiredFieldsError()
    {
        //When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        // Test
        GenesysInteractionsService.GenesysPeopleServiceException expectedError;

        Test.startTest();

        try
        {
            GenesysInteractionsService.findPeopleBy(searchRequest);
        }
        catch(GenesysInteractionsService.GenesysPeopleServiceException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        // Then
        System.assertNotEquals(null, expectedError, 'No se ha lanzado una excepción');

    }

    /**
     * Valida que en caso de no recibir todos los parámetros necesarios devuelve una excepción
     **
     * @author adelgado
     * @date 25/11/2020
     */
    @IsTest
    static void test_findPeopleBy_NoValidFilterBy()
    {
        //When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'tttttttt';
        searchRequest.value = '999888777';
        searchRequest.filterBy  = 'tttttt';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'all';

        // Test
        GenesysInteractionsService.GenesysPeopleServiceException expectedError;

        Test.startTest();

        try
        {
            GenesysInteractionsService.findPeopleBy(searchRequest);
        }
        catch(GenesysInteractionsService.GenesysPeopleServiceException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        // Then
        System.assertNotEquals(null, expectedError, 'No se ha lanzado una excepción');

    }

    /**
     * Valida que en caso de no recibir todos los parámetros necesarios devuelve una excepción
     **
     * @author adelgado
     * @date 25/11/2020
     */
    @IsTest
    static void test_findCustomersBy_NoValidSearchType()
    {
        //When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'tttttttt';
        searchRequest.value = '999888777';
        searchRequest.filterBy  = 'customers';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'all';

        // Test
        GenesysInteractionsService.GenesysPeopleServiceException expectedError;

        Test.startTest();

        try
        {
            GenesysInteractionsService.findCustomersBy(searchRequest);
        }
        catch(GenesysInteractionsService.GenesysPeopleServiceException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        // Then
        System.assertNotEquals(null, expectedError, 'No se ha lanzado una excepción');

    }

    /**
     * Valida que en caso de no recibir todos los parámetros necesarios devuelve una excepción
     **
     * @author adelgado
     * @date 25/11/2020
     */
    @IsTest
    static void test_findIntermediariesBy_NoValidSearchType()
    {
        //When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'tttttttt';
        searchRequest.value = '999888777';
        searchRequest.filterBy  = 'intermediaries';
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;
        searchRequest.legalEntity  = 'all';

        // Test
        GenesysInteractionsService.GenesysPeopleServiceException expectedError;

        Test.startTest();

        try
        {
            GenesysInteractionsService.findIntermediariesBy(searchRequest);
        }
        catch(GenesysInteractionsService.GenesysPeopleServiceException error)
        {
            expectedError = error;
        }

        Test.stopTest();

        // Then
        System.assertNotEquals(null, expectedError, 'No se ha lanzado una excepción');

    }

    /**
     * Valida la generación de la estructura Agent cuando el mediador no tiene casos abiertos
     **
     * @author adelgado
     * @date 25/11/2020
     */
    @IsTest
    static void test_findBestAgents_Intermediary_noCasesOpen()
    {
        // When
        GenesysInteractionsService.Intermediary intermediary = new GenesysInteractionsService.Intermediary();
        intermediary.intermediaryId = '0000000';
        intermediary.individualsManager = 'testIndividualsManager@test.com';
        intermediary.administrationManager = 'testAdministrationManager@test.com';

        // Test
        Test.startTest();

        List<GenesysInteractionsService.Agent> bestAgents = GenesysInteractionsService.findBestAgents(intermediary);

        Test.stopTest();

        // Then
        System.assertEquals(false, bestAgents.isEmpty(), 'No se ha generado la estructura de agentes');
        System.assertEquals(2, bestAgents.size(), 'No se ha generado la estructura de agentes correctamente');

    }


    // #endregion
}