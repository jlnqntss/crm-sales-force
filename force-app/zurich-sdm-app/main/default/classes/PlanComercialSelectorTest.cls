/**
 * Test para la clase PlanComercialSelector
 *
 * @author nts (agonzalezisasi)
 * @date 04/10/2021
 */
@isTest
private class PlanComercialSelectorTest
{
    public static final Integer ACTUAL_YEAR = 2021;

    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 04/10/2021
     */
    @TestSetup
    static void makeData() 
    {
        TestDataFactorySDM.AnualPlanSetupData(ACTUAL_YEAR);
    }

    /**
     * Test de los metodos para el tratamiento del indicador en los planes comerciales
     *
     * @author nts (agonzalezisasi)
     * @date 04/10/2021
     */
    @isTest
    static void testIndicatorType()
    {
        Test.startTest();
        PlanComercialSelector.eIndicator indicatorType = PlanComercialSelector.getIndicatorType(PlanComercialSelector.INDICATOR_PN);
        System.assertEquals(PlanComercialSelector.eIndicator.type_number, indicatorType, 'Deberia ser de tipo number');

        String targetKpiField = PlanComercialSelector.getTargetKPIFieldByType(indicatorType);
        System.assertEquals('TargetKPINumber__c', targetKpiField, 'Deberia ser el campo TargetKPINumber__c');

        Map<String, String> mapIndicatorTypes = PlanComercialSelector.getMapIndicatorType();
        System.assertNotEquals(null, mapIndicatorTypes, 'Deberia existir el mapa de equivalencias de tipo de indicadores');
        System.assertEquals(false, mapIndicatorTypes.isEmpty(), 'El mapa de equivalencias de tipo de indicadores no deberia estar vacio');
        Test.stopTest();
    }

    /**
     * Test del metodo que recupera los planes anuales de un usuario para un año
     *
     * @author nts (agonzalezisasi)
     * @date 04/10/2021
     */
    @isTest
    static void findAnualPlansByAssignedUserAndYear()
    {
        // Recuperamos el usuario DT
        String dtEmail = String.format(TestDataFactorySDM.TERRITORY_EMAIL, new List<String>{String.valueOf(0)});
        List<User> users = [SELECT Id FROM User WHERE Email = :dtEmail];
        System.assertEquals(1, users.size(), 'Deberia haber 1 usuario DT');
        User dtUser = users[0];      

        PlanComercialSelector planSel = new PlanComercialSelector();
        Test.startTest();
        List<PlanComercial__c> plans = planSel.findAnualPlansByAssignedUserAndYear(dtUser.Id, ACTUAL_YEAR);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, plans, 'Deberia encontrar planes');
        // 1 planes = 1 plan DT
        System.assertEquals(1, plans.size(), 'Deberia encontrar 1 plan del DT');
    }

    /**
     * Test del metodo que recupera los planes descendientes de los planes anuales
     *
     * @author nts (agonzalezisasi)
     * @date 04/10/2021
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

        PlanComercialSelector planSel = new PlanComercialSelector();
        Test.startTest();
        List<PlanComercial__c> childPlans = planSel.findAnnualPlanDescendants(dtPlans);
        Test.stopTest();

        // Comprobamos el resultado
        System.assertNotEquals(null, childPlans, 'Deberia encontrar planes');
        // 1 plan dt = 1 plan RN = 3 planes mediadores
        System.assertEquals(3, childPlans.size(), 'Deberia haber 3 planes descendientes');
    }
}