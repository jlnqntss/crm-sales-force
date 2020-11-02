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
        Account acc = new Account();
        acc.LastName = 'nescudero';
        acc.LegalEntity__pc = Label.GeneralInsurance;
        insert acc;

        ContactPointPhone cpp = new ContactPointPhone();
        cpp.ParentId = acc.Id;
        cpp.TelephoneNumber = '123456789';
        insert cpp;

        ContactPointEmail cpe = new ContactPointEmail();
        cpe.ParentId = acc.Id;
        cpe.EmailAddress = 'nescudero@nts-solutions.com';
        insert cpe;

        Case caso = new Case();
        caso.AccountId = acc.Id;

        insert caso;

        caso.OwnerId = USerInfo.getUserid();

        update caso;

        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.Name = 'opp';
        opp.StageName = 'New';
        opp.CloseDate = System.today().addDays(10);
        opp.Scope__c = 'General';
        insert opp;

        Task interaction = new Task();
        interaction.Status = 'Nueva';
        interaction.Priority = 'Normal';
        interaction.CallObject = 'ucid';
        interaction.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                                   .get('Interaction')
                                   .getRecordTypeId();
        insert interaction;
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
}
