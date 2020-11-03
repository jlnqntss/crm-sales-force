@isTest(SeeAllData = false)
public without sharing class ActivitySelectorTest
{

    /**
     * Generación de escenario usando TestDataFactory
     * @author nescudero
     * @date 03/11/2020
     */
    @TestSetup
    static void makeData()
    {
        List<Task> tasks = new List<Task>();
        tasks = TestDataFactory.generateInteractionTasks(10);
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
    static void test_selectTasksByCallObjectIdentifier_nullInput1()
    {
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

    /**
     * Prueba la Query del selector
     * @author nescudero
     * @date 03/11/2020
     */
    @isTest
    static void test_selectTasksByCallObjectIdentifier_nullInput2()
    {
        List<String> nullList = null;
        Test.startTest();
        List<Task> selectedTasks = ActivitySelector.selectTasksByCallObjectIdentifier(
            nullList
            );
        Test.stopTest();

        System.assertEquals(
            new List<Task>(),
            selectedTasks,
            'Se debería recibir una lista vacía'
            );
    }

    /**
     * Prueba la Query del selector
     * @author nescudero
     * @date 03/11/2020
     */
    @isTest
    static void test_selectTasksByCallObjectIdentifier_nullInput3()
    {
        String nullString = null;
        Test.startTest();
        List<Task> selectedTasks = ActivitySelector.selectTasksByCallObjectIdentifier(
            nullString
            );
        Test.stopTest();

        System.assertEquals(
            new List<Task>(),
            selectedTasks,
            'Se debería recibir una lista vacía'
            );
    }
}
