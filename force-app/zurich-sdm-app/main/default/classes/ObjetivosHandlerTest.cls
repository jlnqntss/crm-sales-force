@isTest
public with sharing class ObjetivosHandlerTest {

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

            List<PlanComercial__c> planMensualListBefore = new List<PlanComercial__c>([SELECT Id, TargetKPICurrency__c FROM PlanComercial__c
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
                PlanComercial__c planAfterUpdate = [SELECT Id, TargetKPICurrency__c FROM PlanComercial__c WHERE Id =:planBeforeUpdate.Id];
    
                System.assertEquals(true, planBeforeUpdate.TargetKPICurrency__c != planAfterUpdate.TargetKPICurrency__c);
            }

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
}