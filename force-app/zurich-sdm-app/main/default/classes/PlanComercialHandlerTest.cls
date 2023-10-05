@isTest
public with sharing class PlanComercialHandlerTest { 

    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;

    @TestSetup
    static void makeData() {        
        
        Objective__c obj = TestDataFactory.generateObjective(ACTUAL_YEAR, 'PN', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        insert obj;
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
            List<PlanComercial__c> planMensualListBefore = new List<PlanComercial__c>([SELECT Id, TargetKPICurrency__c FROM PlanComercial__c
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()
                                                                                AND ParentPlan__c = :plan.Id
                                                                                AND Indicator__c = 'PN'
                                                                                AND EndDate__c =: endDate
                                                                                LIMIT 1]);


            // update target kpi
            plan.TargetKPICurrency__c = 200;
            
            Test.startTest();
            update plan;
            Test.stopTest();

            // vuelvo a consultar el mismo plan  mensual que arriba para comparar
            if (!planMensualListBefore.isEmpty()) {
                PlanComercial__c planBeforeUpdate = planMensualListBefore.get(0);
                
                PlanComercial__c planAfterUpdate = [SELECT Id, TargetKPICurrency__c FROM PlanComercial__c WHERE Id =:planBeforeUpdate.Id];

                System.assertEquals(true, planBeforeUpdate.TargetKPICurrency__c != planAfterUpdate.TargetKPICurrency__c);
            }
        }   
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
}
