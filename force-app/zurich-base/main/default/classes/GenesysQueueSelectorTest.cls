/**
 *
 * @author jgarciamartinez@nts-solutions.com
 * @date 29/03/2022
 * clase test para comprobar que el selector de queries funciona
 * correctamente
 */
@IsTest
public with sharing class GenesysQueueSelectorTest
{
    @TestSetup
    static void makeData()
    {
        List<purecloud__PureCloud_Queue__c> testingGenesysQueues = TestDataFactory.generateGenesysQueues(5);
        testingGenesysQueues[1].IsSurveyable__c = true;
        insert testingGenesysQueues;
    }

    @isTest
    static void test_selectAllGenesysQueues_OK()
    {
        List<purecloud__PureCloud_Queue__c> totalQueues = [SELECT Id, Name, IsSurveyable__c FROM purecloud__PureCloud_Queue__c];

        Test.startTest();
        GenesysQueueSelector queueSelector = new GenesysQueueSelector();
        List<purecloud__PureCloud_Queue__c> selectedQueues = queueSelector.getAllQueues();
        Test.stopTest();

        System.assertEquals(totalQueues.size(), selectedQueues.size(), 'No hay las colas esperadas');
    }

    @isTest
    static void test_findByName_ok()
    {

        List<purecloud__PureCloud_Queue__c> queryGroups = [SELECT Id, Name, CallCenter__c FROM purecloud__PureCloud_Queue__c LIMIT 1];
        List<String> queueNames = new List<String>();

        for (purecloud__PureCloud_Queue__c queue : queryGroups)
        {
            queueNames.add(queue.Name);
        }

        Test.startTest();

        List<purecloud__PureCloud_Queue__c> queueResult = new GenesysQueueSelector().getQueuesByName(queueNames);
        Test.stopTest();

        System.assertEquals(queryGroups[0].Id, queueResult[0].Id, 'Ambas ids deben ser iguales');
        System.assertEquals(queryGroups[0].CallCenter__c, queueResult[0].CallCenter__c, 'Ambas ids deben ser iguales');
        System.assertEquals(false, queueResult.isEmpty(), 'Debería haber encontrado al menos una cola');

    }

    @isTest
    static void test_findByName_ko()
    {

        Test.startTest();
        List<purecloud__PureCloud_Queue__c> queueResultNull = new GenesysQueueSelector().getQueuesByName( new List<String>() );
        Test.stopTest();

        System.assertEquals(true, queueResultNull.isEmpty(), 'Debería ser una lista vacía');

    }
}