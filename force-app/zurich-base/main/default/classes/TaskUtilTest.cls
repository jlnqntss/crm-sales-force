/**
 * @description       : Clase test para la clase TaskUtil
 * @author            : aberuete
 * @group             :
 * @last modified on  : 08-03-2023
 * @last modified by  : aberuete
 **/
@isTest
private with sharing class TaskUtilTest
{
    @testSetup
    private static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        Account portalAccount = new Account();
        portalAccount.Name = 'TestAccount';
        accounts.add(portalAccount);
        insert accounts;

        Contact contactPortal = new Contact ();
        contactPortal.FirstName = 'Test';
        contactPortal.LastName = 'McTesty';
        contactPortal.AccountId = portalAccount.Id;
        insert contactPortal;

        Profile profile = [SELECT Id FROM Profile WHERE Name='OCS Community User' LIMIT 1];
        String profileId= profile.Id;
        List<User> ocsUser =TestDataFactory.generateUsersByProfile(profileId, 1);
        ocsUser[0].ContactId = contactPortal.Id;
        insert ocsUser;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 1);
        insert campaigns;

        List<Account> personAccounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null AND Name != 'TestAccount']);
        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(personAccounts, campaigns, 'Subscribed');
        insert campaignMembers;

        // Crear GenesysCloudQueue de prueba
        purecloud__PureCloud_Queue__c genesysQueue = new purecloud__PureCloud_Queue__c(
            Name = 'Test Queue',
            purecloud__PureCloud_Queue_ID__c = 'Id de prueba'
            );
        insert genesysQueue;

        // Crear registros de ContactRequest
        List<ContactRequest> contactRequests = new List<ContactRequest>();
        contactRequests.add( new ContactRequest(
                                 GenesysInteractionId__c = 'interaction_01',
                                 Status = 'New',
                                 PreferredContactDatetime__c = System.now(),
                                 GenesysCloudQueueId__c = genesysQueue.Id
                                 ) );
        contactRequests.add( new ContactRequest(
                                 GenesysInteractionId__c = 'interaction_02',
                                 Status = 'New',
                                 PreferredContactDatetime__c = System.now().addDays(1),
                                 GenesysCloudQueueId__c = genesysQueue.Id
                                 ) );
        insert contactRequests;

        // Crear tareas (Task) relacionadas con el GenesysInteractionId__c
        List<Task> tasks = new List<Task>();
        tasks.add( new Task(
                       CallObject = 'interactionId1',
                       WhatId = contactRequests[0].Id, // Relacionar la tarea con un ContactRequest
                       Subject = 'Test Task'
                       ) );
        insert tasks;
    }

    /*
     * Test que comprueba que al crear una tarea cuyo owner sea un usuario de la comunidad de ocs se crea con el valor public a true
     * @author aberuete
     * @date 01/08/2023
     */
    @isTest
    private static void test_createTaskOwnerCommunity()
    {
        User userCommunity = [Select id from User where profile.name = 'OCS Community User' and isActive = true limit 1 ];
        Task taskToCreate = new Task();
        taskToCreate.Status = 'Asignada';
        taskToCreate.Priority = 'Normal';
        taskToCreate.OwnerId = userCommunity.Id;

        Test.startTest();
        insert taskToCreate;
        Test.stopTest();

        Task taskAfterInsert = [Select id, IsVisibleInSelfService from Task where id =: taskToCreate.id ];
        System.assertEquals(true, taskAfterInsert.IsVisibleInSelfService, 'No se ha actualizado el valor public de la tarea correctamente');
    }

    /*
     * Test que comprueba que al actualizar una tarea cuyo owner sea un usuario de la comunidad de ocs se crea con el valor public a true
     * @author aberuete
     * @date 01/08/2023
     */
    @isTest
    private static void test_updateTaskOwnerCommunity()
    {
        User userCommunity = [Select id from User where profile.name = 'OCS Community User' and isActive = true limit 1 ];

        Task taskToCreate = new Task();
        taskToCreate.Status = 'Asignada';
        taskToCreate.Priority = 'Normal';
        insert taskToCreate;

        Task taskAfterInsert = [Select id, IsVisibleInSelfService, OwnerId from Task where id =: taskToCreate.id ];
        System.assertEquals(false, taskAfterInsert.IsVisibleInSelfService, 'El valor public de la tarea debería ser falso');

        Test.startTest();
        taskToCreate.OwnerId = userCommunity.Id;
        update taskToCreate;
        Test.stopTest();

        Task taskAfterUpdate = [Select id, IsVisibleInSelfService, OwnerId from Task where id =: taskToCreate.id ];
        System.assertEquals(true, taskAfterUpdate.IsVisibleInSelfService, 'El valor public de la tarea debería ser verdadero');
    }

    /*
     * Test que comprueba que se borra una tarea correctamente
     * @author aberuete
     * @date 01/08/2023
     */
    @isTest
    private static void test_deleteTask()
    {
        Task taskToCreate = new Task();
        taskToCreate.Status = 'Asignada';
        taskToCreate.Priority = 'Normal';
        taskToCreate.Subject = 'Tarea de prueba';
        insert taskToCreate;

        Task taskInserted = [SELECT Id FROM Task WHERE Id = : taskToCreate.Id LIMIT 1];
        System.assertNotEquals(null, taskInserted, 'La tarea debería haberse creado correctamente');

        Test.startTest();
        delete taskToCreate;
        Test.stopTest();

        // Verificar que la tarea fue eliminada correctamente
        List<Task> tasksAfterDelete = [SELECT Id FROM Task WHERE Id = : taskToCreate.Id];
        System.assertEquals(0, tasksAfterDelete.size(), 'La tarea no debería existir después de ser eliminada');

        // List<Task> taskAfterDelete = [Select id from Task];
        // System.assertEquals(0, taskAfterDelete.size(), 'La tarea no debería existir');
    }

    /**
     * Testea el metodo setErrorIfClosedAndNoResponseZda, para ello:
     * - Se intenta cerrar una tarea asociada a caso ZDA sin respuesta: no debe permitirlo
     * - Se intenta cerrar una tarea asociada a caso ZDA con respuesta: debe permitirlo
     * - Se intenta cerrar una tarea asociada a caso NO ZDA sin respuesta: debe permitirlo
     *
     * @author mario.navarro@seidor.com
     * @date 16/05/2024
     */
    @isTest
    private static void test_setErrorIfClosedAndNoResponseZda()
    {
        List<Case> casesList = TestDataFactory.generateZDACases(2);
        Case sprinklrCase = new Case (
            RecordTypeId = CaseUtil.RT_ID_OCSSPRINKLR
            );
        casesList.add(sprinklrCase);

        insert casesList;

        List<Task> tasksToProcess = new List<Task>();

        //Tarea asociada a caso ZDA que NO tendra respuesta
        Task taskNoAnswerNotClosed = new Task();
        taskNoAnswerNotClosed.Status = TaskUtil.STATUS_ASIGNADA;
        taskNoAnswerNotClosed.WhatId = casesList[0].Id;
        taskNoAnswerNotClosed.Type = TaskUtil.TYPE_ESCALADO;
        tasksToProcess.add(taskNoAnswerNotClosed);

        //Tarea asociada a caso ZDA que SI tendra respuesta
        Task taskWithAnswerClosed = new Task();
        taskWithAnswerClosed.Status = TaskUtil.STATUS_ASIGNADA;
        taskWithAnswerClosed.WhatId = casesList[1].Id;
        taskWithAnswerClosed.Type = TaskUtil.TYPE_ESCALADO;
        tasksToProcess.add(taskWithAnswerClosed);

        //Tarea asociada a caso NO ZDA que NO tendra respuesta
        Task taskNoAnswerClosed = new Task();
        taskNoAnswerClosed.Status = TaskUtil.STATUS_ASIGNADA;
        taskNoAnswerClosed.WhatId = casesList[2].Id;
        taskNoAnswerClosed.Type = TaskUtil.TYPE_ESCALADO;
        tasksToProcess.add(taskNoAnswerClosed);

        insert tasksToProcess;
        List<Task> insertedTasks = [SELECT Id FROM Task WHERE Id IN : tasksToProcess];
        Assert.isFalse( insertedTasks.isEmpty() );

        taskNoAnswerNotClosed.Status = TaskUtil.STATUS_CERRADA;
        taskWithAnswerClosed.Status = TaskUtil.STATUS_CERRADA;
        taskWithAnswerClosed.Response__c = 'Respuesta del escalado para el tarea asociada a caso ZDA';
        taskNoAnswerClosed.Status = TaskUtil.STATUS_CERRADA;

        Test.startTest();
        //false para que, los que no den error se actualicen
        Database.update(tasksToProcess, false);
        Test.stopTest();

        Task taskNoAnswerNotClosedPostUpdate = [SELECT Status FROM Task WHERE Id = : taskNoAnswerNotClosed.Id];
        Task taskWithAnswerClosedPostUpdate = [SELECT Status FROM Task WHERE Id = : taskWithAnswerClosed.Id];
        Task taskNoAnswerClosedPostUpdate = [SELECT Status FROM Task WHERE Id = : taskNoAnswerClosed.Id];

        Assert.areEqual(TaskUtil.STATUS_ASIGNADA, taskNoAnswerNotClosedPostUpdate.Status);
        Assert.areEqual(TaskUtil.STATUS_CERRADA, taskWithAnswerClosedPostUpdate.Status);
        Assert.areEqual(TaskUtil.STATUS_CERRADA, taskNoAnswerClosedPostUpdate.Status);
    }

    /*
     * Test que comprueba la id de Genesys en caso
     * @author lrodriguez
     * @date 21/05/2024
     */
    @isTest
    private static void test_Genesys_USP()
    {

        Case casoToEmailMessage = new Case (Subject = 'prueba Genesys',Status = 'Assigned', Origin = 'Email', RecordTypeId = CaseUtil.RT_ID_USPINQUIRY);
        insert casoToEmailMessage;

        Task taskToCreate = new Task();
        taskToCreate.Status = 'Asignada';
        taskToCreate.Priority = 'Normal';
        taskToCreate.CallObject = 'd7faf2ef-aadc-4001-85a4-17633fcfe492';
        taskToCreate.WhatId = casoToEmailMessage.id;



        Test.startTest();
        insert taskToCreate;
        Test.stopTest();

        Case casesEmailDefault = [SELECT Id,GenesysID__c,LinkIdGenesys__c FROM Case WHERE Subject = 'prueba Genesys'];
        System.assertEquals(casesEmailDefault.GenesysID__c,'d7faf2ef-aadc-4001-85a4-17633fcfe492','Debe estar informado con id Genesys');
        System.assertEquals(casesEmailDefault.LinkIdGenesys__c,'https://apps.mypurecloud.ie/directory/#/engage/admin/interactions/d7faf2ef-aadc-4001-85a4-17633fcfe492','Debe estar informado con link id Genesys');
    }

    /*
     * Test que comprueba la id de Genesys en caso
     * @author jlnavarroq
     * @date 12/11/2024
     */
    @isTest
    static void test_FindByGenesysInteractionIds()
    {
        Set<String> interactionIds = new Set<String> {'interactionId1'};
        // Obtener ContactRequest de prueba
        ContactRequest contactRequest = [SELECT Id, GenesysCloudQueueId__c FROM ContactRequest WHERE GenesysInteractionId__c = 'interaction_01' LIMIT 1];

        // Crear una tareas relacionadas con el ContactRequest
        List<Task> tasksToCreate = new List<Task>();
        tasksToCreate.add( new Task(
                               Status = 'Asignada',
                               Priority = 'Normal',
                               WhatId = contactRequest.Id, // Relacionamos la tarea con el ContactRequest
                               OwnerId = UserInfo.getUserId()
                               ) );
        tasksToCreate.add( new Task(
                               Status = 'Asignada',
                               Priority = 'Normal',
                               WhatId = contactRequest.Id, // Relacionamos la tarea con el ContactRequest
                               OwnerId = UserInfo.getUserId()
                               ) );
        tasksToCreate.add( new Task(
                               Status = 'Asignada',
                               Priority = 'Normal',
                               WhatId = contactRequest.Id, // Relacionamos la tarea con el ContactRequest
                               OwnerId = UserInfo.getUserId()
                               ) );

        // Iniciar el contexto de prueba
        Test.startTest();
        insert tasksToCreate; // Insertamos la tarea
        Test.stopTest();

        for( Task taskToCreate : tasksToCreate)
        {
            // Verificar que el campo GenesysQueue__c se ha asignado correctamente
            Task taskAfterInsert = [SELECT Id, GenesysQueue__c FROM Task WHERE Id = : taskToCreate.Id LIMIT 1];
            System.debug('taskAfterInsert.GenesysQueue__c: ' + taskAfterInsert.GenesysQueue__c);
            System.assertNotEquals(null, taskAfterInsert.GenesysQueue__c, 'El campo GenesysQueue__c en la tarea debería estar asignado');

            // Verificar que el nombre de la cola es el esperado
            purecloud__PureCloud_Queue__c genesysQueue = [SELECT Name FROM purecloud__PureCloud_Queue__c WHERE Id = : taskAfterInsert.GenesysQueue__c LIMIT 1];
            System.assertEquals('Test Queue', genesysQueue.Name, 'El nombre de la cola de Genesys no es el esperado en la tarea');
        }

    }
}