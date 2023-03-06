@isTest
public with sharing class PlanesComercialesMensualesUtilTest {

    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;

    // aqui se ejecuta la mayor parte de la clase a la que hacemos test, los metodos a continuación terminan de probarla
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
     * Buscar planes mensuales de retencion
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void testGetPlanesComercialesAnualesMensualesByObjetivosMensual_OK() {

        Map<String, Objective__c> objetivosInput = new Map<String, Objective__c>();

        List<Objective__c> objList = new List<Objective__c>([SELECT Id, Year__c, Indicator__c, Segment__c, Product__c, Zone__c, ExternalId__c FROM Objective__c WHERE Indicator__c = 'Ratio_Retention']);
        
        if (!objList.isEmpty()) {
            Objective__c obj = objList.get(0);

            objetivosInput.put(obj.ExternalId__c, obj);
            List<PlanComercial__c> retentionPlans = PlanesComercialesMensualesUtil.getPlanesComercialesAnualesMensualesByObjetivos(objetivosInput, 'Mensual');

            System.assertEquals(true, retentionPlans.size() != 0);

        }
    }


    /**
     * actualizar kpi de plan comercial para lanzar los metodos de plan mensual util
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
}