/**
 * Test para la clase PlanComercialWithoutSharingSelector
 *
 * @author nts (dmunoz)
 * @date 17/11/2022
 */
@isTest
public with sharing class PlanComercialWithoutSharingSelectorTest {

    public static final Integer ACTUAL_YEAR = 2021;
    
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 17/11/2022
     */
    @TestSetup
    static void makeData(){
        TestDataFactorySDM.AnualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);
    }


    /**
     * Test del metodo que recupera los planes descendientes de los planes anuales
     *
     * @author nts (dmunoz)
     * @date 17/11/2022
     */
    @isTest
    static void findAnnualPlanDescendants()
    {
        // Recuperamos el usuario DT
        String dtEmail = String.format(TestDataFactorySDM.TERRITORY_EMAIL, new List<String>{String.valueOf(0)});
        List<User> users = [SELECT Id FROM User WHERE Email = :dtEmail];
        System.assertEquals(1, users.size(), 'Deberia haber 1 usuario DT');
        User dtUser = users[0];
        List<PlanComercial__c> dtPlans = [SELECT Id FROM PlanComercial__c WHERE AssignedTo__c = :dtUser.Id];
        System.assertEquals(1, dtPlans.size(), 'Deberia haber 1 plan del DT');

        PlanComercialWithoutSharingSelector planSel = new PlanComercialWithoutSharingSelector();
        Test.startTest();
        List<PlanComercial__c> childPlans = planSel.findAnnualPlanDescendants(dtPlans);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, childPlans, 'Deberia encontrar planes');
        // 1 plan RN, hijo del plan del DT
        System.assertEquals(1, childPlans.size(), 'Deberia haber 1 plan descendiente');
    }
}
