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
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'CustomerGI', 1);
        insert contacts;

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

        //Se crea 1 opp para cada cuenta
        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert opportunities;

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.initInteraction(testInteractionLog);

        Test.stopTest();

        // Then
        Opportunity expectedOpportunity = [SELECT AccountId, Owner.Email FROM Opportunity LIMIT 1];
        List<Task> expectedTasks = [SELECT AccountId, Owner.Email, WhatId, WhoId, Status, CallObject FROM Task WHERE CallObject = :testInteractionLog.interactionId];

        System.assertEquals(expectedOpportunity.Owner.Email, testInteractionLog.bestAgentId, 'No coincide el Id. del mejor agente');
        System.assertEquals(expectedOpportunity.AccountId, testInteractionLog.screenPopRecordId, 'No se está realizando screen pop del Id. de oportunidad');
        System.assertNotEquals(null, testInteractionLog.customerId, 'El id del cliente es nulo');
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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

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
     * Valida el escenario en el que para una b´suqueda de teléfono hay un único resultado.
     * TODO: Completar con la implementaciónd completa de findPeopleBy
     **
     * @author jmartinezpisson
     * @date 02/11/2020
     */
    @IsTest
    static void test_findPeopleBy_Phone_matchedPerson()
    {
        // When
        GenesysInteractionsService.SearchRequest searchRequest = new GenesysInteractionsService.SearchRequest();

        searchRequest.searchType = 'phone';
        searchRequest.value = '123456789';
        searchRequest.filterBy  = null;
        searchRequest.scope = GenesysInteractionsService.SCOPE_CODE_ALL;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Map<Id, ContactPointPhone> ([SELECT Id FROM ContactPointPhone WHERE TelephoneNumber = : searchRequest.value]).keySet();
        Test.setFixedSearchResults(new List<Id>(recordIds) );

        // Test
        Test.startTest();

        GenesysInteractionsService.SearchResult result = GenesysInteractionsService.findPeopleBy(searchRequest);

        Test.stopTest();

        // Then
        List<Account> expectedAccounts = [SELECT Id FROM Account WHERE Id IN (SELECT ParentId FROM ContactPointPhone WHERE Id IN :recordIds )];

        System.assertEquals(1, result.screenPopRecordIds.size(), 'Debería haber encontrado un único resultado');

        Set<String> matchedIds = new Set<String>(result.screenPopRecordIds);

        for(Account expectedAccount : expectedAccounts)
        {
            matchedIds.contains(expectedAccount.Id);
        }
    }

    // #endregion
}
