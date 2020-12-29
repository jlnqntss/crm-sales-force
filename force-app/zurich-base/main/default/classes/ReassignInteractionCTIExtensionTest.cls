@isTest(SeeAllData = false)
public without sharing class ReassignInteractionCTIExtensionTest
{
    /**
     * Prueba a que se actualiza la tarea existente
     * @author nescudero
     * @date 27/10/2020
     */
    @isTest
    static void test_onSaveLog_updateTask()
    {
        List<Task> interaction = TestDataFactory.generateInteractionTasks(1);
        insert interaction;

        Test.startTest();
        ReassignInteractionCTIExtension.onSaveLog(
            '{"eventName": "interactionChanged", "interaction" : { "id": "ucid0"},  "callLog": {"CallObject": "ucid0"}}'
            );
        Test.stopTest();

        List<Task> tasks = [SELECT Status FROM Task];

        System.assertEquals(
            'Asignada',
            tasks[0].Status,
            'Se debería haber actualizado el status de la tarea'
            );
    }

    /**
     * Prueba a que se crea una nueva tarea
     * @author nescudero
     * @date 27/10/2020
     */
    @isTest
    static void test_onSaveLog_createTask()
    {
        Test.startTest();
        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "noExiste"} , "callLog": {"CallObject": "noExiste"}}'
            );
        Test.stopTest();

        List<Task> tasks = [SELECT Status FROM Task];

        System.assertEquals(
            'Asignada',
            tasks[0].Status,
            'Se debería haber creado una tarea'
            );
    }

    /**
     * Prueba que se actualice el Owner del caso relacionado con la task
     */
    @isTest
    static void test_onSaveLog_changeCaseOwnerFromQueueToUser_ok()
    {
        Test.startTest();
            //En el stopTest finaliza el future
            byPassMixedDMLOperation();
        Test.stopTest();

        List<Group> queues = [SELECT Id, Type FROM Group WHERE Type = 'Queue'];
        Id queueId = queues[0].Id;

        //Crear Caso relacionado a la TASK
        List<Case> cases = TestDataFactory.generateCasesWithOwnerId(queueId, 1);
        insert cases;
        List<Task> interaction = TestDataFactory.generateInteractionTasksWithWhatId(cases[0].Id, 1);
        insert interaction;

        System.assertEquals(queueId, cases[0].OwnerId, 'Se debería haber insertado el Caso con Owner la Cola');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<Case> updatedCase = [SELECT Id, OwnerId FROM Case];

        System.assertEquals(UserInfo.getUserId(), updatedCase[0].OwnerId, 'Se debería haber actualizado el Owner del Caso con el User actual');
    }

    @future
    private static void byPassMixedDMLOperation()
    {
        //Crear Cola por si acaso en la Org no estan creadas aún (Se ven en los test)
        List<Group> queue = TestDataFactory.generateQueueGroups(1);
        insert queue;
        List<QueueSObject> queueType = TestDataFactory.generateQueueSObject(queue[0].Id, 'Case', 1);
        insert queueType;
    }

    /**
     * Prueba que el Owner del Caso no se actualiza porque
     * la tarea no está relacionada
     */
    @isTest
    static void test_onSaveLog_changeCaseOwnerFromQueueToUser_ko()
    {
        Test.startTest();
            //En el stopTest finaliza el future
            byPassMixedDMLOperation();
        Test.stopTest();

        List<Group> queues = [SELECT Id, Type FROM Group WHERE Type = 'Queue'];
        Id queueId = queues[0].Id;

        //Crear caso con owner una Cola
        List<Case> cases = TestDataFactory.generateCasesWithOwnerId(queueId, 1);
        insert cases;

        //Crear Task SIN relacionarlo con Case
        List<Task> interaction = TestDataFactory.generateInteractionTasks(1);
        insert interaction;

        System.assertEquals(queueId, cases[0].OwnerId, 'Se debería haber insertado el Caso con Owner la Cola');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<Case> updatedCase = [SELECT Id, OwnerId FROM Case];

        System.assertEquals(queueId, updatedCase[0].OwnerId, 'El caso, al no estar relacionado con la Task, no debería haberse modificado su OwnerId');
    }

    /**
     * Prueba que se actualice el Owner del Offer relacionado con la task
     */
    @isTest
    static void test_changeOwner_Offer_ok()
    {
        List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = 'Integrator'];
        Id integratorId = users[0].Id;

        //Crear Offer relacionado a la TASK
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;
        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        opportunities[0].OwnerId = integratorId; //Poner al usuario integrador como Owner
        insert opportunities;
        List<Task> interaction = TestDataFactory.generateInteractionTasksWithWhatId(opportunities[0].Id, 1);
        insert interaction;

        System.assertEquals(integratorId, opportunities[0].OwnerId, 'Se debería haber insertado el Offer con Owner el usuario integrador');
        System.assertEquals(opportunities[0].Id, interaction[0].WhatId, 'Se debería haber insertado la Task con WhatId la Offer');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<Opportunity> updatedOffer = [SELECT Id, OwnerId FROM Opportunity];

        System.assertEquals(UserInfo.getUserId(), updatedOffer[0].OwnerId, 'Se debería haber actualizado el Owner del Offer con el User actual');
    }

    /**
     * Prueba que NO se actualice el Owner del Offer relacionado con la task porque no es perfil integrador
     */
    @isTest
    static void test_changeOwner_Offer_ko()
    {
        List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = 'Integrator'];
        Id integratorId = users[0].Id;

        //Crear Offer relacionado a la TASK
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;
        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        opportunities[0].OwnerId = integratorId; //Poner al usuario integrador como Owner
        insert opportunities;
        //Crear Task SIN relacionarlo con Offer
        List<Task> interaction = TestDataFactory.generateInteractionTasks(1);
        insert interaction;

        System.assertEquals(integratorId, opportunities[0].OwnerId, 'Se debería haber insertado el Offer con Owner el usuario integrador');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<Opportunity> updatedOffer = [SELECT Id, OwnerId FROM Opportunity];

        System.assertEquals(integratorId, updatedOffer[0].OwnerId, 'El Offer, al no estar relacionado con la Task, no debería haberse modificado su OwnerId');
    }

    /**
     * Prueba que se actualice el Owner del ContactRequest relacionado con la task
     */
    @isTest
    static void test_changeOwner_ContactRequest_ok()
    {
        List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = 'Integrator'];
        Id integratorId = users[0].Id;

        // ContactRequest - Se necesita un ContactRequest que no enrute a través de PB.
        ContactRequest cr = new ContactRequest();
        cr.OwnerId = integratorId;
        insert cr;
        List<Task> interaction = TestDataFactory.generateInteractionTasksWithWhatId(cr.Id, 1);
        insert interaction;

        System.assertEquals(integratorId, cr.OwnerId, 'Se debería haber insertado el Offer con Owner el usuario integrador');
        System.assertEquals(cr.Id, interaction[0].WhatId, 'Se debería haber insertado la Task con WhatId la ContactRequest');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<ContactRequest> updatedContactRequest = [SELECT Id, OwnerId FROM ContactRequest];

        System.assertEquals(UserInfo.getUserId(), updatedContactRequest[0].OwnerId, 'Se debería haber actualizado el Owner del ContactRequest con el User actual');
    }

    /**
     * Prueba que se NO actualice el Owner del ContactRequest relacionado con la task
     */
    @isTest
    static void test_changeOwner_ContactRequest_ko()
    {
        List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = 'Integrator'];
        Id integratorId = users[0].Id;

        // ContactRequest - Se necesita un ContactRequest que no enrute a través de PB.
        ContactRequest cr = new ContactRequest();
        cr.OwnerId = integratorId;
        insert cr;
        //Crear Task SIN relacionarlo con Offer
        List<Task> interaction = TestDataFactory.generateInteractionTasks(1);
        insert interaction;

        System.assertEquals(integratorId, cr.OwnerId, 'Se debería haber insertado el Offer con Owner el usuario integrador');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<ContactRequest> updatedContactRequest = [SELECT Id, OwnerId FROM ContactRequest];

        System.assertEquals(integratorId, updatedContactRequest[0].OwnerId, 'El ContactRequest, al no estar relacionado con la Task, no debería haberse modificado su OwnerId');
    }
}