@isTest
public with sharing class SDMUpdatePlansAsyncBatchTest {

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
     * generar actualizar planes pn y los planes mensuales asociados se deben modificar
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void updateKPIPlanComercialPNTest_OK() {
        List<PlanComercial__c> planesToUpdate = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, 
                                                                Indicator__c, Segment__c, Product__c, TargetKPIPercent__c, TargetKPINumber__c, TargetKPICurrency__c, OwnerId, Actual_KPI__c, Zone__c, 
                                                                ParentPlan__r.OwnerId, Intermediary__c
                                                        FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Indicator__c = 'PN'
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToUpdate.isEmpty()) {
            PlanComercial__c plan = planesToUpdate.get(0);

            Date endDate = Date.newInstance(ACTUAL_YEAR, 1, 31);

            // obtener el kpi del plan mensual antes de actualizar
            List<PlanComercial__c> planMensualListBefore = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()
                                                                                AND ParentPlan__c = :plan.Id
                                                                                AND Indicator__c = 'PN'
                                                                                AND EndDate__c =: endDate
                                                                                LIMIT 1]);


            // update target kpi
            plan.TargetKPINumber__c = 200;
            
            Test.startTest();
            update plan;
            Test.stopTest();

            // vuelvo a consultar el mismo plan  mensual que arriba para comparar
            if (!planMensualListBefore.isEmpty()) {
                PlanComercial__c planBeforeUpdate = planMensualListBefore.get(0);
                
                PlanComercial__c planAfterUpdate = [SELECT Id, TargetKPINumber__c FROM PlanComercial__c WHERE Id =:planBeforeUpdate.Id];

                System.assertEquals(true, planBeforeUpdate.TargetKPINumber__c != planAfterUpdate.TargetKPINumber__c);
            }
        }   
    }


    /**
     * actualizar pesos objetivo pn
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void updatePesosObjetivoPNTest_OK() {

        // obtener objetivo 
        List<Objective__c> objList = new List<Objective__c>([SELECT Id, January__c FROM Objective__c WHERE Indicator__c = 'PN' LIMIT 1]);

        if (!objList.isEmpty()) {
            Date endDate = Date.newInstance(ACTUAL_YEAR, 1, 31);

            List<PlanComercial__c> planMensualListBefore = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'PN'
                                                                                AND EndDate__c =: endDate
                                                                                LIMIT 1]);

            Objective__c obj = objList.get(0);
            obj.January__c = 70.0;
            obj.February__c = 0.0;
            obj.December__c = 30.0;

            Test.startTest();
            update obj;
            Test.stopTest();

            if (!planMensualListBefore.isEmpty()) {
                PlanComercial__c planBeforeUpdate = planMensualListBefore.get(0);
                PlanComercial__c planAfterUpdate = [SELECT Id, TargetKPINumber__c FROM PlanComercial__c WHERE Id =:planBeforeUpdate.Id];
    
                System.assertEquals(true, planBeforeUpdate.TargetKPINumber__c != planAfterUpdate.TargetKPINumber__c);
            }

        }
    }

    /**
     * inactivar objetivo pn
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void inactiveObjetivoPNTest_OK() {

        // obtener objetivo 
        List<Objective__c> objList = new List<Objective__c>([SELECT Id, January__c FROM Objective__c WHERE Indicator__c = 'PN' LIMIT 1]);

        if (!objList.isEmpty()) {

            List<PlanComercial__c> planMensualListBefore = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'PN']);

            Objective__c obj = objList.get(0);
            obj.Active__c = false;

            Test.startTest();
            update obj;
            Test.stopTest();

            if (!planMensualListBefore.isEmpty()) {
                List<PlanComercial__c> planMensualListAfter = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                    WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                    AND Indicator__c = 'PN']);
    
                System.assertEquals(true, planMensualListBefore.size() != planMensualListAfter.size());
            }
        }
    }


    /**
     * activar objetivo pn
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void activeObjetivoPNTest_OK() {

        // obtener objetivo 
        List<Objective__c> objList = new List<Objective__c>([SELECT Id, January__c FROM Objective__c WHERE Indicator__c = 'PN' LIMIT 1]);

        if (!objList.isEmpty()) {
            Test.startTest();
            Objective__c obj = objList.get(0);
            obj.Active__c = false;
            update obj;

            List<PlanComercial__c> planMensualListBefore = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'PN']);


            obj.Active__c = true;
            update obj;
            Test.stopTest();

            if (!planMensualListBefore.isEmpty()) {
                List<PlanComercial__c> planMensualListAfter = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                    WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                    AND Indicator__c = 'PN']);
    
                System.assertEquals(true, planMensualListBefore.size() != planMensualListAfter.size());
            }
        }
    }


    /**
     * inactivar objetivo ratio retencion
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void inactiveObjetivoRatioRetencionTest_OK() {

        // obtener objetivo 
        List<Objective__c> objList = new List<Objective__c>([SELECT Id, January__c FROM Objective__c WHERE Indicator__c = 'Ratio_Retention' LIMIT 1]);

        if (!objList.isEmpty()) {

            List<PlanComercial__c> planMensualListBefore = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'Ratio_Retention']);

            Objective__c obj = objList.get(0);
            obj.Active__c = false;

            Test.startTest();
            update obj;
            Test.stopTest();

            if (!planMensualListBefore.isEmpty()) {
                List<PlanComercial__c> planMensualListAfter = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                    WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                    AND Indicator__c = 'Ratio_Retention']);
    
                System.assertEquals(true, planMensualListBefore.size() != planMensualListAfter.size());
            }
        }
    }


    /**
     * activar objetivo retencion
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void activeObjetivoRatioRetencionTest_OK() {

        // obtener objetivo 
        List<Objective__c> objList = new List<Objective__c>([SELECT Id, January__c FROM Objective__c WHERE Indicator__c = 'Ratio_Retention' LIMIT 1]);

        if (!objList.isEmpty()) {
            List<PlanComercial__c> planMensualListInicial = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'Ratio_Retention']);

            Test.startTest();
            Objective__c obj = objList.get(0);
            obj.Active__c = false;
            update obj;

            // activar objetivo
            obj.Active__c = true;
            update obj;
            Test.stopTest();

            List<PlanComercial__c> planMensualListAfter = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'Ratio_Retention']);

            
            System.assertEquals(true, planMensualListInicial.size() == planMensualListAfter.size(), 'El numero de planes mensuales debe ser igual antes y despues del test');
            
        }
    }


    /**
     * dml recursivo insert plan mensual
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void dmlRecursivoInsertPlanMensualPN_OK() {
        Map<String, List<PlanComercial__c>> mapDMLRecursivo = new Map<String, List<PlanComercial__c>>();

        List<PlanComercial__c> planMensualListToClone = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'PN' LIMIT 1]);

        List<PlanComercial__c> planMensualToInsert = new List<PlanComercial__c>();
        for (PlanComercial__c plan: planMensualListToClone) {
            planMensualToInsert.add(plan.clone(false, false, false, false));
        }

        mapDMLRecursivo.put('PlanesMensualesToInsert', planMensualToInsert);
        Test.startTest();
        Database.executeBatch(new SDMUpdatePlansAsyncBatch(mapDMLRecursivo), 200);
        Test.stopTest();

        List<PlanComercial__c> planMensualListAfterBatch = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'PN']);


        System.assertEquals(true, planMensualListAfterBatch.size() != 0);

    }

    /**
     * dml recursivo update plan mensual
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void dmlRecursivoUpdatePlanMensualPN_OK() {
        Map<String, List<PlanComercial__c>> mapDMLRecursivo = new Map<String, List<PlanComercial__c>>();

        List<PlanComercial__c> planMensualListInicial = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'PN' LIMIT 1]);

        if (!planMensualListInicial.isEmpty()) {
            List<PlanComercial__c> planMensualListToUpdate = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                    WHERE Id =: planMensualListInicial.get(0).Id]);
    
            List<PlanComercial__c> planMensualToUpdate = new List<PlanComercial__c>();
            
            for (PlanComercial__c plan: planMensualListToUpdate) {
                plan.TargetKPINumber__c = 600.0;
                planMensualToUpdate.add(plan);
            }
    
            mapDMLRecursivo.put('PlanesMensualesToUpdate', planMensualToUpdate);
            Test.startTest();
            Database.executeBatch(new SDMUpdatePlansAsyncBatch(mapDMLRecursivo), 200);
            Test.stopTest();
    
            PlanComercial__c planMensualAfterBatch = [SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                    WHERE Id =: planMensualListInicial.get(0).Id];
    
            System.assertEquals(true, planMensualListInicial.get(0).TargetKPINumber__c != planMensualAfterBatch.TargetKPINumber__c);

        }
    }

    /**
     * dml recursivo delete plan mensual pn
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void dmlRecursivoDeletePlanMensualPN_OK() {
        Map<String, List<PlanComercial__c>> mapDMLRecursivo = new Map<String, List<PlanComercial__c>>();

        List<PlanComercial__c> planMensualListInicial = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'PN']);

        if (!planMensualListInicial.isEmpty()) {
    
            mapDMLRecursivo.put('PlanesMensualesToDelete', planMensualListInicial);
            Test.startTest();
            Database.executeBatch(new SDMUpdatePlansAsyncBatch(mapDMLRecursivo), 200);
            Test.stopTest();
    
            List<PlanComercial__c>  planMensualAfterBatch = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()                                                                                
                                                        AND Indicator__c = 'PN']);
    
            System.assertEquals(true, planMensualAfterBatch.size() == 0);

        }
    }

    /**
     * dml recursivo delete plan anual retencion
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void dmlRecursivoDeletePlanAnualRetencion_OK() {
        Map<String, List<PlanComercial__c>> mapDMLRecursivo = new Map<String, List<PlanComercial__c>>();

        List<PlanComercial__c> planMensualListInicial = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'Ratio_Retention']);

        if (!planMensualListInicial.isEmpty()) {
    
            mapDMLRecursivo.put('PlanesAnualesToDelete', planMensualListInicial);
            Test.startTest();
            Database.executeBatch(new SDMUpdatePlansAsyncBatch(mapDMLRecursivo), 200);
            Test.stopTest();
    
            List<PlanComercial__c>  planMensualAfterBatch = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()                                                                                
                                                        AND Indicator__c = 'Ratio_Retention']);
    
            System.assertEquals(true, planMensualAfterBatch.size() == 0);

        }
    }


    /**
     * test continue recursive
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void continueRecursive_OK() {

        Map<String, List<PlanComercial__c>> mapDMLRecursivo = new Map<String, List<PlanComercial__c>>();
        List<PlanComercial__c> planMensualListInicial = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()                                                                                
                                                                                AND Indicator__c = 'Ratio_Retention']);

        if (!planMensualListInicial.isEmpty()) {
    
            mapDMLRecursivo.put('PlanesAnualesToDelete', planMensualListInicial);
            SDMUpdatePlansAsyncBatch batch = new SDMUpdatePlansAsyncBatch(mapDMLRecursivo);
            Test.startTest();
            Boolean result = batch.continueRecursive();
            Test.stopTest();
    
            System.assertEquals(true, result);

        }
    }
}