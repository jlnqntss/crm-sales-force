@isTest(SeeAllData=false)
public with sharing class ObjectivesSelectorTest {
    
    @TestSetup
    static void makeData(){
        List<Objective__c> objectives = new List<Objective__c>();
        objectives = TestDataFactory.generateObjectives('2022', 1);

        insert objectives;
    }


    /**
     * Prueba OK la Query del selector
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void test_selectObjectivesByYear_list() {

        Test.startTest();
        List<Objective__c> selectedObjectives = ObjectivesViewController.getObjetives('2022');
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
        List<Objective__c> selectedObjectives = ObjectivesViewController.getObjetives(null);
        Test.stopTest();

        System.assertEquals(0, selectedObjectives.size(), 'Se debería recibir una lista con 0 objetivos');
    }

}
