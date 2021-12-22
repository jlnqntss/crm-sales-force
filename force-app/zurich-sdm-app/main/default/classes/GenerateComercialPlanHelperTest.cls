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
        Id rtPlanAnualId = (new PlanComercialSelector()).rtPlanAnualId;

        // Creamos el plan principal
        List<PlanComercial__c> mainPlans = TestDataFactorySDM.generatePlansWithoutIntermediary(1);
        mainPlans[0].RecordTypeId = rtPlanAnualId;
        mainPlans[0].AccumulateType__c = PlanComercialSelector.ACCUMULATE_TYPE_YRD;
        insert mainPlans;

        // Creamos los hijos del plan principal
        List<PlanComercial__c> childPlans = TestDataFactorySDM.generatePlansWithoutIntermediary(NUM_PLANS);
        // Hacemos que el plan principal sea el "padre" del resto de planes "hijos"
        for(PlanComercial__c childPlan: childPlans) {
            childPlan.ParentPlan__c = mainPlans[0].Id;
            childPlan.RecordTypeId = rtPlanAnualId;
            childPlan.AccumulateType__c = PlanComercialSelector.ACCUMULATE_TYPE_YRD;
        }
        insert childPlans;
    }

    @isTest
    static void deleteDescendantPlans()
    {
        List<PlanComercial__c> mainPlan = [SELECT Id, Name FROM PlanComercial__c WHERE ParentPlan__c = null];
        System.assertEquals(1, mainPlan.size(), 'Deberia haber 1 plan comercial principal');

        Test.startTest();
        GenerateComercialPlanHelper.deleteDescendantPlans(mainPlan);
        Test.stopTest();

        List<PlanComercial__c> plansResult = [SELECT Id, Name FROM PlanComercial__c WHERE ParentPlan__c != null];
        System.assertEquals(0, plansResult.size(), 'No deberia haber planes anuales hijos');
    }
}
