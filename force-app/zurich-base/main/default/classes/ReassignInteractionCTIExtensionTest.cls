/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 09/08/2022
 * @last modified by  : jgallaga
**/
@isTest(SeeAllData = false)
private without sharing class ReassignInteractionCTIExtensionTest
{
    /**
    * @description  Se asegura que al cambiar de advisor en una interacción, este ultimo queda como propietario de la tarea.
    *               Se usan dos usuarios y se simula una llamada. La llamada será primero tratada por el primer Advisor que tomará la
    *               llamada y después se la "traspasa" al segundo advisor. El traspaso produce un evento de colgar la interaccion en el primer usuario.
    *               Cuando el segundo agente toma esa llamada, comienza la interaccion con el usuario que deberá quedarse con la posesión
    *               de la tarea (interacción) al terminar el proceso.
    * @author jgallaga | 05/08/2022
    **/
    @isTest
    static void test_onSaveLog_chageTaskOwner()
    {
        List<Task> tasksInTestStart = [SELECT Id From Task];

        System.assert(tasksInTestStart.isEmpty(), 'For this test there should not be any task');

        // Creamos los dos advisors
        String zeAdvisorProfileName = 'ZE User';
        Id advisorProfileId         = [SELECT Id FROM Profile WHERE Name = :zeAdvisorProfileName].Id;
        List<User> advisorUsers     = TestDataFactory.generateUsersByProfile(advisorProfileId,2);
        insert advisorUsers;

        User advisor1 = advisorUsers.get(0);
        User advisor2 = advisorUsers.get(1);

        Test.startTest();

        // Evento de coger la llamada
        String interactionChangedEventString = '{"eventName": "interactionChanged", "interaction" : { "id": "ucid0"},  "callLog": {"CallObject": "ucid0"}}';

        // Se coge la llamada con el primer usuario
        System.runAs(advisor1)
        {
            ReassignInteractionCTIExtension.onSaveLog(interactionChangedEventString);
        }

        List<Task> tasksInSystem = [SELECT id FROM task];

        System.assertEquals(1, tasksInSystem.size(), 'La interaccion solo debería crear una tarea');

        Task createdTask = tasksInSystem.get(0);

        // Evento de colgar la llamada
        String interactionDisconnectEventString = '{"eventName": "interactionDisconnected", "interaction" : { "id": "'+ createdTask.Id +'"},  "callLog": {"CallObject": "ucid0", "calldurationinseconds":2, "id":"' + createdTask.Id +'"}}';

        // Se "traspasa" la llamada
        System.runAs(advisor1)
        {
            ReassignInteractionCTIExtension.onSaveLog(interactionDisconnectEventString);
        }

        tasksInSystem = [SELECT id, Status, OwnerId, RecordType.DeveloperName FROM task];

        System.assertEquals(1, tasksInSystem.size(), 'No se deben crear mas tareas aparte de la interacción original');

        Task currentTask = tasksInSystem.get(0);
        System.assertEquals('Cerrada', currentTask.Status, 'La interacción debería haber acabado como Cerrada');
        System.assertEquals(advisor1.Id, currentTask.OwnerId, 'El propietario de la primera interacción no es correcta');

        // Se coge la llamada con el segundo usuario
        System.runAs(advisor2)
        {
            ReassignInteractionCTIExtension.onSaveLog(interactionChangedEventString);
        }

        tasksInSystem = [SELECT id, Status FROM task];

        System.assertEquals(1, tasksInSystem.size(), 'Una interaccion solo debería crear una tarea');
        currentTask = tasksInSystem.get(0);
        System.assertEquals('Asignada', currentTask.Status, 'El estado no ha cambiado a asignada');

        // Se cuelga la llamada
        System.runAs(advisor2)
        {
            ReassignInteractionCTIExtension.onSaveLog(interactionDisconnectEventString);
        }

        Test.stopTest();

        tasksInSystem = [SELECT id, Status, OwnerId, RecordType.DeveloperName FROM task];
        currentTask = tasksInSystem.get(0);

        System.assertEquals(1, tasksInSystem.size(), 'Se han generado mas tareas de las necesarias');
        System.assertEquals('Cerrada', currentTask.Status, 'La interacción debería haber acabado como Cerrada');
        System.assertEquals(advisor2.Id, currentTask.OwnerId, 'El propietario de la primera interacción no es correcta');

        List<Error_Log__c> errores = [SELECT id FROM Error_Log__c];
        System.assert(errores.isEmpty(),' El proceso no puede haber generado errores');
    }

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

        List<Task> tasks = [SELECT Status, RecordTypeId FROM Task];

        System.assertEquals(
            'Asignada',
            tasks[0].Status,
            'Se debería haber actualizado el status de la tarea'
            );

        System.assertEquals(
            Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId(),
            tasks[0].RecordTypeId,
            'El tipo de registro de la tarea actualizada no es Interacción'
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

    /**
     * Prueba que se actualice el Owner del Offer relacionado con la task
     * Y del resto de Offer que coincidan en misma AccountId y ScopeId
     */
    @isTest
    static void test_changeOwner_ExtraOffers_ok()
    {
        List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = 'Integrator'];
        Id integratorId = users[0].Id;

        //Crear Offer relacionado a la TASK
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        //2º crear ámbito ZE
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 5);
        for(Opportunity opp: opportunities)
        {
            opp.OwnerId = integratorId; //Poner al usuario integrador como Owner
            opp.ScopeId__c = scopes[0].Id; //Poner el mismo scope a todas
        }
        insert opportunities;
        Id selectedOppId = opportunities[0].Id;
        List<Task> interaction = TestDataFactory.generateInteractionTasksWithWhatId(selectedOppId, 1);
        insert interaction;

        System.assertEquals(integratorId, opportunities[0].OwnerId, 'Se debería haber insertado el Offer con Owner el usuario integrador');
        System.assertEquals(opportunities[0].Id, interaction[0].WhatId, 'Se debería haber insertado la Task con WhatId la Offer');
        System.assertEquals(scopes[0].Id, opportunities[0].ScopeId__c, 'Se debería haber insertado la Offer con el mismo Scope ZE');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<Opportunity> updatedOffer = [SELECT Id, AccountId, ScopeId__c, OwnerId FROM Opportunity ];

        Integer i = 0;
        for(Opportunity o: updatedOffer)
        {
            System.assertEquals(scopes[0].Id, o.ScopeId__c, 'ScopeId - ' + i);
            System.assertEquals(accounts[0].Id, o.AccountId, 'AccountId - ' + i);
            System.assertEquals(UserInfo.getUserId(), o.OwnerId, 'OwnerId - ' + i);
            i++;
        }
    }

    /**
     * Prueba que NO se actualice el Owner del Offer relacionado con la task
     * Y del resto de Offer que coincidan en misma AccountId y ScopeId
     */
    @isTest
    static void test_changeOwner_ExtraOffers_ko()
    {
        List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = 'Integrator'];
        Id integratorId = users[0].Id;

        //Crear Offer relacionado a la TASK
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        //2º crear ámbito ZE
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 5);
        for(Opportunity opp: opportunities)
        {
            opp.OwnerId = integratorId; //Poner al usuario integrador como Owner
            opp.ScopeId__c = scopes[0].Id; //Poner el mismo scope a todas
        }
        insert opportunities;

        System.assertEquals(integratorId, opportunities[0].OwnerId, 'Se debería haber insertado el Offer con Owner el usuario integrador');
        System.assertEquals(scopes[0].Id, opportunities[0].ScopeId__c, 'Se debería haber insertado la Offer con el mismo Scope ZE');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<Opportunity> updatedOffer = [SELECT Id, AccountId, ScopeId__c, OwnerId FROM Opportunity ];

        Integer i = 0;
        for(Opportunity o: updatedOffer)
        {
            System.assertEquals(scopes[0].Id, o.ScopeId__c, 'ScopeId - ' + i);
            System.assertEquals(accounts[0].Id, o.AccountId, 'AccountId - ' + i);
            System.assertEquals(integratorId, o.OwnerId, 'El Offer, al no estar relacionado con la Task, no debería haberse modificado su OwnerId - ' + i);
            i++;
        }
    }

    /**
     * Prueba que NO se actualice el Owner del Offer relacionado con la task
     * Y del resto de Offer que coincidan en misma AccountId y ScopeId
     */
    @isTest
    static void test_changeOwner_ExtraOffers_ko_v2()
    {
        List<User> users = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = 'Integrator'];
        Id integratorId = users[0].Id;

        //Crear Offer relacionado a la TASK
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 5);
        for(Opportunity opp: opportunities)
        {
            opp.OwnerId = integratorId; //Poner al usuario integrador como Owner
        }
        insert opportunities;
        Id selectedOppId = opportunities[0].Id;
        List<Task> interaction = TestDataFactory.generateInteractionTasksWithWhatId(selectedOppId, 1);
        insert interaction;

        System.assertEquals(integratorId, opportunities[0].OwnerId, 'Se debería haber insertado el Offer con Owner el usuario integrador');
        System.assertEquals(opportunities[0].Id, interaction[0].WhatId, 'Se debería haber insertado la Task con WhatId la Offer');

        ReassignInteractionCTIExtension.onSaveLog(
            '{ "eventName": "interactionChanged", "interaction" : {"id": "ucid0"} , "callLog": {"CallObject": "ucid0"}}'
            );

        List<Opportunity> updatedOffer = [SELECT Id, AccountId, ScopeId__c, OwnerId FROM Opportunity ];

        Integer i = 0;
        for(Opportunity o: updatedOffer)
        {
            System.assertEquals(accounts[0].Id, o.AccountId, 'AccountId - ' + i);
            if(o.Id == selectedOppId)
            {
                System.assertEquals(UserInfo.getUserId(), o.OwnerId, 'El OwnerId de la Offer seleccionada sí cambia - ' + i);
            }
            else
            {
                System.assertEquals(integratorId, o.OwnerId, 'El OwnerId del resto de Offers se mantiene en Integrator porque no están en el mismo scope que la principal - ' + i);
            }
            i++;
        }
    }

    /**
     * Prueba la comprobación de ID real
     * @date 5/7/2021
     */
    @isTest
    static void test_onSaveLog_parseId()
    {
        List<Task> interaction = TestDataFactory.generateInteractionTasks(1);
        insert interaction;
        Id taskId = interaction[0].Id;

        Test.startTest();
        ReassignInteractionCTIExtension.onSaveLog(
            '{"eventName": "interactionChanged", "interaction" : { "id": "'+taskId+'"},  "callLog": {"CallObject": "'+taskId+'", "Id": "'+taskId+'", "Status":"Asignada"}}'
            );
        Test.stopTest();

        //Hacer query para recuperar los nuevos valores
        List<Task> tasks = [SELECT Status, RecordTypeId FROM Task];

        System.assertEquals(
            'Asignada',
            tasks[0].Status,
            'Se debería haber actualizado el status de la tarea'
            );

        System.assertEquals(
            Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get('Interaction').getRecordTypeId(),
            tasks[0].RecordTypeId,
            'El tipo de registro de la tarea actualizada no es Interacción'
            );
    }
}