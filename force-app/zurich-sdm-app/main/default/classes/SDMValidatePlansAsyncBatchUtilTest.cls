@isTest
public with sharing class SDMValidatePlansAsyncBatchUtilTest {

    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;

    @TestSetup
    static void makeData(){
        Objective__c obj = TestDataFactory.generateObjective(ACTUAL_YEAR, 'PN', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        insert obj;
    }
    
    /**
     * Test metadata planes mensuales piloto
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void getValidEmailsFromMetadataTest() {
        Test.startTest();
        List<String> metadataEmailList = SDMValidatePlansAsyncBatchUtil.getValidEmailsFromMetadata();
        Test.stopTest();

        System.assertEquals(true, !metadataEmailList.isEmpty(), 'Debe haber resultados en la metadata piloto de emails');
    }


    /**
     * Test objetivo está activo
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void isObjectiveActiveTest() {

        // generar objetivo en memoria activo
        Objective__c obj = new Objective__c();
        obj.Active__c = true;

        Test.startTest();
        Boolean result = SDMValidatePlansAsyncBatchUtil.isObjectiveActive(obj);
        Test.stopTest();

        System.assertEquals(true, result, 'El Objetivo debe estar activo');
    }


    /**
     * Test objetivo es RT objetivo
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void isRTObjectiveTest() {

        // generar objetivo en memoria activo
        Objective__c obj = new Objective__c();
        obj.RecordTypeId = ObjectivesSelector.rtObjectives;

        Test.startTest();
        Boolean result = SDMValidatePlansAsyncBatchUtil.isRTObjective(obj);
        Test.stopTest();

        System.assertEquals(true, result, 'El Objetivo debe tener RT Objetivo');
    }


    /**
     * Test objetivo es Ratio Retencion
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void isRetentionObjectiveTest() {

        // generar objetivo en memoria activo
        Objective__c obj = new Objective__c();
        obj.Indicator__c = 'Ratio_Retention';

        Test.startTest();
        Boolean result = SDMValidatePlansAsyncBatchUtil.isRetentionObjective(obj);
        Test.stopTest();

        System.assertEquals(true, result, 'El Objetivo debe tener indicador ratio retencion');
    }

    /**
     * Test objetivo es Siniestralidad
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void isAccidentObjectiveTest() {

        // generar objetivo en memoria activo
        Objective__c obj = new Objective__c();
        obj.Indicator__c = 'Ratio_Claim';

        Test.startTest();
        Boolean result = SDMValidatePlansAsyncBatchUtil.isAccidentObjective(obj);
        Test.stopTest();

        System.assertEquals(true, result, 'El Objetivo debe tener indicador siniestralidad');
    }


    /**
     * Test objetivo no es Ratio Retencion
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void isOtherIndicatorTest() {

        // generar objetivo en memoria activo
        Objective__c obj = new Objective__c();
        obj.Indicator__c = 'PN';

        Test.startTest();
        Boolean result = SDMValidatePlansAsyncBatchUtil.isOtherIndicator(obj);
        Test.stopTest();

        System.assertEquals(true, result, 'El Objetivo debe tener indicador PN');
    }


    /**
     * Test objetivo pasa de inactivo a activo
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void checkActiveTest() {        

        List<Objective__c> listaObjetivo = new List<Objective__c>([SELECT Id, Active__c FROM Objective__c LIMIT 1]);

        if (!listaObjetivo.isEmpty()) {
            // actualizar objetivo de activo a inactivo
            List<Objective__c> listaObjetivoUpdate = new List<Objective__c>();
            Objective__c objClone;
            for (Objective__c o: listaObjetivo) {
                objClone = o.clone(false, false, false, false);
                objClone.Active__c = false;
                objClone.Id = o.Id;
                listaObjetivoUpdate.add(objClone);
            }

            update listaObjetivoUpdate;
            Map<Id, SObject> oldMap = new Map<Id, SObject>();
            oldMap.put(listaObjetivoUpdate.get(0).Id, listaObjetivoUpdate.get(0));

            Objective__c obj = listaObjetivo.get(0);
            obj.Active__c = true;

            Test.startTest();
            Boolean result = SDMValidatePlansAsyncBatchUtil.checkActive(obj, oldMap);
            Test.stopTest();
            System.assertEquals(true, result, 'El Objetivo debe pasar de inactivo a activo');
        }
    }

    /**
     * Test objetivo pasa de inactivo a activo
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void checkInactiveTest() {        

        List<Objective__c> listaObjetivo = new List<Objective__c>([SELECT Id, Active__c FROM Objective__c LIMIT 1]);

        if (!listaObjetivo.isEmpty()) {

            Map<Id, SObject> oldMap = new Map<Id, SObject>();
            oldMap.put(listaObjetivo.get(0).Id, listaObjetivo.get(0));

            Objective__c obj = listaObjetivo.get(0).clone(false, false, false, false);
            obj.Id = listaObjetivo.get(0).Id;
            obj.Active__c = false;

            System.debug(obj.Active__c);
            System.debug(oldMap.values().get(0));

            Test.startTest();
            Boolean result = SDMValidatePlansAsyncBatchUtil.checkInactive(obj, oldMap);
            Test.stopTest();
            System.assertEquals(true, result, 'El Objetivo debe pasar de activo a inactivo');
        }
    }


    /**
     * Test plan es anual
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void isPlanAnualTest() {

        PlanComercial__c plan = new PlanComercial__c();
        plan.RecordTypeId = Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId();

        Test.startTest();
        Boolean result = SDMValidatePlansAsyncBatchUtil.isPlanAnual(plan);
        Test.stopTest();
        System.assertEquals(true, result, 'El plan debe tener RT anual');        
    }


    /**
     * Test plan es PN, Cartera o APES pasa de inactivo a activo
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void checkPlanIndicatorTest() {

        PlanComercial__c plan = new PlanComercial__c();
        plan.Indicator__c = 'PN';

        Test.startTest();
        Boolean result = SDMValidatePlansAsyncBatchUtil.checkPlanIndicator(plan);
        Test.stopTest();
        System.assertEquals(true, result, 'El plan debe tener indicador PN');        
    }
}