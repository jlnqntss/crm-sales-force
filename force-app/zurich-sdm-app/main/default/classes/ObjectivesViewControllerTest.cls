/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-08-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest(SeeAllData=false)
public with sharing class ObjectivesViewControllerTest {
    
    @TestSetup
    static void makeData(){
        List<Objective__c> objectives = new List<Objective__c>();
        List<Objective__c> objectives2022 = new List<Objective__c>();
        objectives2022 = TestDataFactory.generateObjectives('2022', 1);

        List<Objective__c> objectives2023 = new List<Objective__c>();
        objectives2023 = TestDataFactory.generateObjectives('2023', 1);

        objectives.addAll(objectives2022);
        objectives.addAll(objectives2023);

        insert objectives;
    }

    /**
     * Prueba la Query del Objetivos
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void test_getObjectives_list() {

        List<Objective__c> l = [SELECT ID, Year__c FROM Objective__c];
        System.debug('test_getObjectives_list ' + l);

        Test.startTest();
        List<Objective__c> selectedObjectives = ObjectivesViewController.getObjetives('2022');
        Test.stopTest();

        System.assertEquals(1, selectedObjectives.size(), 'Se debería recibir una lista con 1 objetivos encontrado por el campo Year__c');
    }

    /**
     * Prueba KO Query del Objetivos
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void testKO_getObjectives_list() {

        Test.startTest();
        List<Objective__c> selectedObjectives = ObjectivesViewController.getObjetives(null);
        Test.stopTest();

        System.assertEquals(0, selectedObjectives.size(), 'Se debería recibir una lista con 0 objetivos');
    }

    /**
     * Prueba la Query del Objetivos
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void test_YearSelector() {


        Test.startTest();
        List<String> result = ObjectivesViewController.getSelectorYearList();
        Test.stopTest();

        System.assertEquals(true, result.contains('2022'), 'Contiene el año 2022');
    }

    /**
     * Prueba clonar objetivos
     * @author dmunoz
     * @date 08/07/2022
     */
    /*
    @isTest
    static void test_clone() {

        // String clone
        String objectiveToClone = '[{"ExternalId__c":"2023-PN-PYMEs-Accidentes","Active__c":true,"December__c":0,"November__c":0,"October__c":0,"September__c":0,"August__c":0,"July__c":0,"June__c":0,"May__c":0,"April__c":0,"March__c":0,"February__c":0.5,"January__c":0.5,"Product__c":"Accidentes","Segment__c":"PYMEs","Indicator__c":"PN","Year__c":"2023","Id":"a1O5E000001gEZxUAM"}]';
        
        //String objectiveToClone = JSON.serialize(ObjectivesSelector.selectObjectivesByYear('2022'));

        System.debug('clone input ' + objectiveToClone);

        Test.startTest();
        Map<String, String> mapCloneResult = ObjectivesViewController.cloneRecords(objectiveToClone, '2023');
        Test.stopTest();

        System.assertEquals('2024', mapCloneResult.get('year'), 'Se debería recibir el año siguiente a 2023');
    }*/

    /**
     * Prueba clonar objetivos
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void testKO_cloneDuplicatesError() {

        // String clone
        String objectiveToClone = '[{"ExternalId__c":"2022-PN-PYMEs-Accidentes","Active__c":true,"December__c":0,"November__c":0,"October__c":0,"September__c":0,"August__c":0,"July__c":0,"June__c":0,"May__c":0,"April__c":0,"March__c":0,"February__c":0.5,"January__c":0.5,"Product__c":"Accidentes","Segment__c":"PYMEs","Indicator__c":"PN","Year__c":"2022","Id":"a1O5E000001gEZxUAM"}]';
        //String serializeQuery = JSON.serialize(objectiveToClone);

        System.debug('clone input ' + objectiveToClone);

        Test.startTest();
        Map<String, String> mapCloneResult = ObjectivesViewController.cloneRecords(objectiveToClone, '2022');
        Test.stopTest();

        System.assertEquals('2022', mapCloneResult.get('year'), 'Se debería recibir el año de entrada');
    }

    /**
     * Prueba KO clonar objetivos
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void testKO_cloneInputNull() {

        Test.startTest();
        Map<String, String> mapCloneResult = ObjectivesViewController.cloneRecords(null, null);
        Test.stopTest();

        System.assertEquals('2022', mapCloneResult.get('year'), 'Se debería recibir el año de entrada');
    }

    /**
     * Prueba actualizar objetivos
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void test_updateRecord() {

        // String clone
        //String objectiveToUpdate = '[{"ExternalId__c":"2022-PN-PYMEs-Accidentes","Active__c":true,"December__c":0,"November__c":0,"October__c":0,"September__c":0,"August__c":0,"July__c":0,"June__c":0,"May__c":0,"April__c":0,"March__c":0,"February__c":0,"January__c":1,"Product__c":"Accidentes","Segment__c":"PYMEs","Indicator__c":"PN","Year__c":"2022","Id":"a1O5E000001gEZxUAM"}]';
        
        String objectiveToUpdate = JSON.serialize(ObjectivesSelector.selectObjectivesByYear('2022'));

        System.debug('update input test' + objectiveToUpdate);

        Test.startTest();
        Map<String, String> mapCloneResult = ObjectivesViewController.updateObjectives(objectiveToUpdate);
        Test.stopTest();

        System.assertEquals('success', mapCloneResult.get('variant'), 'Se debería recibir variante success');
    }

    /**
     * Prueba actualizar objetivos KO
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void testKO_updateRecordError() {

        // String clone
        //String objectiveToUpdate = '[{"ExternalId__c":"2022-PN-PYMEs-Accidentes","Active__c":true,"December__c":0,"November__c":0,"October__c":0,"September__c":0,"August__c":0,"July__c":0,"June__c":0,"May__c":0,"April__c":0,"March__c":0,"February__c":0,"January__c":1,"Product__c":"Accidentes","Segment__c":"PYMEs","Indicator__c":"PN","Year__c":"2022","Id":"a1O5E000001gEZxUAM"}]';
        
        List<Objective__c> query = ObjectivesSelector.selectObjectivesByYear('2022');
        for (Objective__c obj: query) {
            obj.January__c = 100;
            obj.February__c = 100;
        }

        String objectiveToUpdate = JSON.serialize(query);

        System.debug('update input test' + objectiveToUpdate);

        Test.startTest();
        Map<String, String> mapCloneResult = ObjectivesViewController.updateObjectives(objectiveToUpdate);
        Test.stopTest();

        System.assertEquals('error', mapCloneResult.get('variant'), 'Se debería recibir variante error');
    }

    /**
     * Prueba actualizar objetivos KO input null
     * @author dmunoz
     * @date 08/07/2022
     */
    @isTest
    static void testKO_updateRecordNull() {

        Test.startTest();
        Map<String, String> mapCloneResult = ObjectivesViewController.updateObjectives(null);
        Test.stopTest();

        System.assertEquals('error', mapCloneResult.get('variant'), 'Se debería recibir variante error');
    }
}