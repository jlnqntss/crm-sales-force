@isTest
public with sharing class SDMInsertPlansAsyncBatchTest {

    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;

    /**
     * generar planes pn y retencion
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void insertPlanComercialTest_OK() {

        List<Objective__c> objList = new List<Objective__c>();
        Objective__c obj = TestDataFactory.generateObjective(ACTUAL_YEAR, 'PN', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
        Objective__c objRetention = TestDataFactory.generateObjective(ACTUAL_YEAR, 'Ratio_Retention', 'Particulares', 'Autos', '11 BARCELONA', 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

        objList.add(obj);
        objList.add(objRetention);
        insert objList;

        TestDataFactorySDM.anualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);

        List<PlanComercial__c> planesGeneradosList = new List<PlanComercial__c>([SELECT Id FROM PlanComercial__c WHERE RecordType.DeveloperName = 'MensualPlan']);
        System.assertEquals(true, !planesGeneradosList.isEmpty(), 'Se han de haber generado planes mensuales');
    }


    /**
     * test accion batch incorrecta
     *
     * @author nts (dmunoz)
     * @date 28/02/2023
     */
    @isTest
    static void insertPlanComercialTest_KO() {
        TestDataFactorySDM.anualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);

        List<PlanComercial__c> planesComerciales = new List<PlanComercial__c>([SELECT Id FROM PlanComercial__c]);
        Database.executeBatch(new SDMInsertPlansAsyncBatch(planesComerciales, 'ActionError'), 200);
    }
}