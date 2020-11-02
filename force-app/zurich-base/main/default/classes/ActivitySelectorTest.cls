@isTest(SeeAllData = false)
public without sharing class ActivitySelectorTest
{
    public static void setUp()
    {
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 10; i++)
        {
            Task interaction = new Task();
            interaction.Status = 'Nueva';
            interaction.Priority = 'Normal';
            interaction.CallObject = 'ucid' + i;
            interaction.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                                       .get('Interaction')
                                       .getRecordTypeId();
            tasks.add(interaction);
        }
        insert tasks;
    }

    /**
     * Prueba la Query del selector
     * @author nescudero
     * @date 27/10/2020
     */
    @isTest
    static void test_selectTasksByCallObjectIdentifier_list()
    {
        setUp();
        List<String> interactionIds = new List<String> {
            'ucid1',
            'ucid2',
            'ucidNoExiste'
        };

        Test.startTest();
        List<Task> selectedTasks = ActivitySelector.selectTasksByCallObjectIdentifier(
            interactionIds
            );
        Test.stopTest();

        System.assertEquals(
            2,
            selectedTasks.size(),
            'Se debería recibir una lista con 2 tareas encontradas por el campo CallObject'
            );
    }

    /**
     * Prueba la Query del selector
     * @author nescudero
     * @date 27/10/2020
     */
    @isTest
    static void test_selectTasksByCallObjectIdentifier_string()
    {
        setUp();

        Test.startTest();
        List<Task> selectedTasks = ActivitySelector.selectTasksByCallObjectIdentifier(
            'ucid1'
            );
        Test.stopTest();

        System.assertEquals(
            1,
            selectedTasks.size(),
            'Se debería recibir una lista con 1 tarea encontrada por el campo CallObject'
            );
    }

    /**
     * Prueba la Query del selector
     * @author nescudero
     * @date 27/10/2020
     */
    @isTest
    static void test_selectTasksByCallObjectIdentifier_nullOutput()
    {
        setUp();

        Test.startTest();
        List<Task> selectedTasks = ActivitySelector.selectTasksByCallObjectIdentifier(
            'ucidNoExiste'
            );
        Test.stopTest();

        System.assertEquals(
            new List<Task>(),
            selectedTasks,
            'Se debería recibir una lista vacía porque no encuentra nada'
            );
    }

    /**
     * Prueba la Query del selector
     * @author nescudero
     * @date 27/10/2020
     */
    @isTest
    static void test_selectTasksByCallObjectIdentifier_nullInput()
    {
        setUp();

        Test.startTest();
        List<Task> selectedTasks = ActivitySelector.selectTasksByCallObjectIdentifier(
            new List<String>()
            );
        Test.stopTest();

        System.assertEquals(
            new List<Task>(),
            selectedTasks,
            'Se debería recibir una lista vacía'
            );
    }
}
