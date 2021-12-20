/**
 * Clase de Test de la clase GenerateComercialPlanHelper
 *
 * @author nts (agonzalezisasi)
 * @date 20/12/2021
 *
 */
@isTest
private with sharing class GenerateComercialPlanHelperTest {
    public static final Integer NUM_PLANS = 5;
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 20/12/2021
     */
    @TestSetup
    static void makeData() 
    {
        List<PlanComercial__c> plans = TestDataFactorySDM.generatePlansWithoutIntermediary(NUM_PLANS);
        insert plans;
    }

    @isTest
    static void deleteDescendantPlans()
    {
        List<PlanComercial__c> plans = [SELECT Id FROM PlanComercial__c];
        System.assertEquals(NUM_PLANS, plans.size(), 'Deberia haber ' + NUM_PLANS + ' planes comerciales');

        Test.startTest();
        GenerateComercialPlanHelper.deleteDescendantPlans(plans);
        Test.stopTest();

        List<PlanComercial__c> plansResult = [SELECT Id FROM PlanComercial__c];
        System.assertEquals(0, plansResult.size(), 'No deberia haber planes comerciales');
    }
}
