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
        Group g1 = new Group(Name='group name', type='Queue');
        insert g1;
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        insert q1;
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
}