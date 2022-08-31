@isTest(SeeAllData=false)
public with sharing class ObjectivesSelectorTest {
    
    @TestSetup
    static void makeData(){
        Objective__c objective = TestDataFactory.generateObjective(2022, 'PN', 'Particulares', 'Autos', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

        insert objective;
    }


    /**
     * Prueba OK la Query del selector
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void test_selectObjectivesByYear_list() {

        Test.startTest();
        List<Objective__c> selectedObjectives = ObjectivesSelector.selectObjectivesByYear('2022');
        Test.stopTest();

        System.assertEquals(1, selectedObjectives.size(), 'Se debería recibir una lista con 1 objetivos encontrado por el campo Year__c');
    }

     /**
     * Prueba KO la Query del selector
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void testKO_selectObjectivesByYear_list() {

        Test.startTest();
        List<Objective__c> selectedObjectives = ObjectivesSelector.selectObjectivesByYear(null);
        Test.stopTest();

        System.assertEquals(0, selectedObjectives.size(), 'Se debería recibir una lista con 0 objetivos');
    }


    /**
     * Prueba ok query selectObjectivesByExternalId
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void testOK_selectObjectivesByExternalId_list() {

        List<Objective__c> objList = new List<Objective__c>([SELECT ExternalId__c FROM Objective__c LIMIT 1]);
        Set<String> objExternalIdSet = new Set<String>();

        for (Objective__c obj: objList) {
            objExternalIdSet.add(obj.ExternalId__c);
        }


        Test.startTest();
        List<Objective__c> selectedObjectives = ObjectivesSelector.selectObjectivesByExternalId(objExternalIdSet);
        Test.stopTest();

        System.assertEquals(1, selectedObjectives.size(), 'Se debería recibir una lista con 1 objetivos');
    }

    /**
     * Prueba ko query selectObjectivesByExternalId
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void testKO_selectObjectivesByExternalId_list() {


        Test.startTest();
        List<Objective__c> selectedObjectives = ObjectivesSelector.selectObjectivesByExternalId(null);
        Test.stopTest();

        System.assertEquals(0, selectedObjectives.size(), 'Se debería recibir una lista con 0 objetivos');
    }

}