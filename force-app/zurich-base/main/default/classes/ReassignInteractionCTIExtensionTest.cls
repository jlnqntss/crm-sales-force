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
        Task interaction = new Task();
        interaction.Status = 'Nueva';
        interaction.CallObject = 'ucid1';
        interaction.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName()
                                   .get('Interaction')
                                   .getRecordTypeId();
        insert interaction;

        Test.startTest();
        ReassignInteractionCTIExtension.onSaveLog(
            '{"eventName": "interactionChanged", "interaction" : { "id": "ucid1"},  "callLog": {"CallObject": "ucid1"}}'
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
}