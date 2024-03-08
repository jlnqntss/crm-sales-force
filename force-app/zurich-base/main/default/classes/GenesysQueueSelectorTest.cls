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

    /**
     * Comprobar que se recuperan las colas de Genesys por nombre
     * @author nts- jfherrero
     * @date 25/03/2024
     */
    @isTest
    static void test_selectGenesysQueuesByName_OK()
    {
        List<purecloud__PureCloud_Queue__c> totalQueues = [SELECT Id, Name FROM purecloud__PureCloud_Queue__c];
        List<String> queueNames = new List<String>();

        for (purecloud__PureCloud_Queue__c queue : totalQueues)
        {
            queueNames.add(queue.Name);
        }

        Test.startTest();
        GenesysQueueSelector queueSelector = new GenesysQueueSelector();
        List<purecloud__PureCloud_Queue__c> selectedQueues = queueSelector.getQueuesByName(queueNames);
        Test.stopTest();

        System.assertEquals(totalQueues.size(), queueNames.size(), 'No hay las colas esperadas');
    }
}