@isTest
public with sharing class SDMDeletePlansAsyncBatchTest {

    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;
    
    @TestSetup
    static void makeData(){
        List<Objective__c> objList = new List<Objective__c>();
        Objective__c obj = TestDataFactory.generateObjective(ACTUAL_YEAR, 'PN', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        Objective__c objRetention = TestDataFactory.generateObjective(ACTUAL_YEAR, 'Ratio_Retention', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

        objList.add(obj);
        objList.add(objRetention);
        insert objList;

        TestDataFactorySDM.anualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);
    }


    /**
     * eliminar planes mensuales pn
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void testDeletePlanPN_OK() {
        List<PlanComercial__c> planesIniciales = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                                            AND ParentPlan__c != NULL 
                                                                            AND Indicator__c = 'PN'
                                                                            AND Intermediary__c = NULL]);

        List<PlanComercial__c> planesToDelete = new List<PlanComercial__c>([SELECT Id
                                                        FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Indicator__c = 'PN'
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToDelete.isEmpty()) {

            Test.startTest();
            delete planesToDelete;
            Test.stopTest();

            List<PlanComercial__c> planesAfterDelete = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                                            AND ParentPlan__c != NULL 
                                                                            AND Indicator__c = 'PN'
                                                                            AND Intermediary__c = NULL]);

            System.assertEquals(true, planesIniciales.size() != planesAfterDelete.size());
        }
    }


    /**
     * eliminar objetivo retencion
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void testDeleteObjetivoRetencion_OK() {
        List<Objective__c> objToDelete = new List<Objective__c>([SELECT Id FROM Objective__c WHERE Indicator__c = 'Ratio_Retention' LIMIT 1]);
        List<PlanComercial__c> planesIniciales = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                                            AND ParentPlan__c != NULL 
                                                                            AND Indicator__c = 'Ratio_Retention'
                                                                            AND Intermediary__c = NULL]);
        

        if (!objToDelete.isEmpty()) {

            Test.startTest();
            delete objToDelete;
            Test.stopTest();

            List<PlanComercial__c> planesAfterDelete = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                                            AND ParentPlan__c != NULL 
                                                                            AND Intermediary__c = NULL]);

            System.assertEquals(true, planesIniciales.size() != planesAfterDelete.size());
        }
    }


    /**
     * eliminar recursivo planes anuales
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void testDMLRecursivoAnual_OK() {
        Map<String, List<PlanComercial__c>> deleteRecursivoMap = new Map<String, List<PlanComercial__c>>();
        List<PlanComercial__c> planesAnualesIniciales = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()                                                                            
                                                                            AND Indicator__c = 'Ratio_Retention'
                                                                            ]);        

        if (!planesAnualesIniciales.isEmpty()) {

            deleteRecursivoMap.put('Anual', planesAnualesIniciales);

            Test.startTest();
            Database.executeBatch(new SDMDeletePlansAsyncBatch(deleteRecursivoMap), 200);
            Test.stopTest();

            List<PlanComercial__c> planesAfterDelete = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                                            AND Indicator__c = 'Ratio_Retention']);

            System.assertEquals(true, planesAnualesIniciales.size() != planesAfterDelete.size());
        }
    }


    /**
     * eliminar recursivo planes mensuales
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void testDMLRecursivoMensual_OK() {
        Map<String, List<PlanComercial__c>> deleteRecursivoMap = new Map<String, List<PlanComercial__c>>();
        List<PlanComercial__c> planesAnualesIniciales = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                            
                                                                            AND Indicator__c = 'Ratio_Retention'
                                                                            ]);        

        if (!planesAnualesIniciales.isEmpty()) {

            deleteRecursivoMap.put('Mensual', planesAnualesIniciales);

            Test.startTest();
            Database.executeBatch(new SDMDeletePlansAsyncBatch(deleteRecursivoMap), 200);
            Test.stopTest();

            List<PlanComercial__c> planesAfterDelete = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()
                                                                            AND Indicator__c = 'Ratio_Retention']);

            System.assertEquals(true, planesAnualesIniciales.size() != planesAfterDelete.size());
        }
    }


    /**
     * continue recursive test
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void testContinueRecursive_OK() {
        Map<String, List<PlanComercial__c>> deleteRecursivoMap = new Map<String, List<PlanComercial__c>>();
        List<PlanComercial__c> planesAnualesIniciales = new List<PlanComercial__c>([SELECT Id
                                                                            FROM PlanComercial__c 
                                                                            WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                            
                                                                            AND Indicator__c = 'Ratio_Retention'
                                                                            ]);        

        if (!planesAnualesIniciales.isEmpty()) {

            deleteRecursivoMap.put('Mensual', planesAnualesIniciales);

            Test.startTest();
            SDMDeletePlansAsyncBatch batch = new SDMDeletePlansAsyncBatch(deleteRecursivoMap);
            Boolean result = batch.continueRecursive();
            Test.stopTest();
            
            System.assertEquals(true, result);
        }
    }

}