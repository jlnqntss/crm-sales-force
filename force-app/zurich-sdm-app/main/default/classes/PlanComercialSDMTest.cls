/**
 * Test para la clase PlanComercialSDM
 *
 * @author nts (agonzalezisasi)
 * @date 27/07/2021
 */
@isTest
private class PlanComercialSDMTest
{
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @TestSetup
    static void makeData() 
    {
        TestDataFactorySDM.PlanComercialSetupData();
    }

    /**
     * Test del metodo que calcula el KPI de una serie de Planes comerciales
     *
     * @author nts (agonzalezisasi)
     * @date 27/07/2021
     */
    @isTest
    static void testCalculateRealKPI_ok()
    {
        // Se recuperan las planes comerciales
        List<PlanComercial__c> plans = [
            SELECT Id, CreatedById, AssignedTo__c,
                   Indicator__c, Intermediary__c, Product__c, Segment__c, AccumulateType__c
            FROM PlanComercial__c
        ];
        System.assertEquals(3, plans.size(), 'Deberia haber 3 planes antes del test');


        // Ejecucion del Test -------------------------------------------------
        Test.startTest();
        PlanComercialSDM sdm = new PlanComercialSDM();
        // Configuracion de los indicadores de los planes comerciales
        sdm.testSettingsIndicator = new List<SDMCommercialPlan__mdt>();
        sdm.testSettingsIndicator.add(TestDataFactorySDM.generateSDMSettingsPlan(
            'PN', PlanComercialSDM.SETTINGS_CALCULATION_TYPE_SUM, 'PN__c', null));
        sdm.testSettingsIndicator.add(TestDataFactorySDM.generateSDMSettingsPlan(
            'Ratio_Claim', PlanComercialSDM.SETTINGS_CALCULATION_TYPE_RATIO, 'TotalLoad__c', 'Income__c'));
        sdm.testSettingsIndicator.add(TestDataFactorySDM.generateSDMSettingsPlan(
            'Ratio_PoliciesPNIncreas', PlanComercialSDM.SETTINGS_CALCULATION_TYPE_GROWTH, 'PoliciesPN__c', 'PA_PoliciesPN__c'));
        
        // Calculo del KPI para los planes
        sdm.calculateRealKPI(plans);
        Test.stopTest();


        // Comprobacion del restulado -----------------------------------------
        List<PlanComercial__c> checkPlans = [
            SELECT Id, Actual_KPI__c FROM PlanComercial__c
            WHERE Actual_KPI__c != null
        ];
        System.assertEquals(3, checkPlans.size(), 'Deberia haber 3 planes');
        Map<Id, PlanComercial__c> mapPlans = new Map<Id, PlanComercial__c>(checkPlans);
        // Comprobamos el primer plan
        PlanComercial__c plan = mapPlans.get(plans[0].Id);
        System.assertNotEquals(null, plan, 'El primer plan deberia existir');
        System.assertEquals(10, plan.Actual_KPI__c, 'El calculo deberia ser 10');

        // Comprobamos el segundo plan
        plan = mapPlans.get(plans[1].Id);
        System.assertNotEquals(null, plan, 'El segundo plan deberia existir');
        System.assertEquals(0.4, plan.Actual_KPI__c, 'El calculo deberia ser 0.4');

        // Comprobamos el tercer plan
        plan = mapPlans.get(plans[2].Id);
        System.assertNotEquals(null, plan, 'El tercer plan deberia existir');
        System.assertEquals(0.75, plan.Actual_KPI__c, 'El calculo deberia ser 0.75');
    }
        
    /**
     * Test del metodo que calcula el KPI de una serie de Planes comerciales
     *
     * @author nts (agonzalezisasi)
     * @date 27/07/2021
     */
    @isTest
    static void testCalculateRealKPI_no_settings()
    {
        Id rtIntermediaryId = new AccountsSelector().rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId LIMIT 1];
        System.assertEquals(1, intermediaries.size(), 'Deberia haber 1 mediador');

        // Generacion de los planes comerciales -------------------------------
        List<PlanComercial__c> plans = TestDataFactorySDM.generatePlans(intermediaries, 1);
        insert plans;

        // Ejecucion del Test -------------------------------------------------
        Test.startTest();
        PlanComercialSDM sdm = new PlanComercialSDM();
        // Dejamos la configuracion vacia para que no encuentre el Indicador del plan en la configuracion
        sdm.testSettingsIndicator = new List<SDMCommercialPlan__mdt>();
        // Calculo del KPI para los planes
        sdm.calculateRealKPI(plans);
        Test.stopTest();

        // Comprobacion del restulado -----------------------------------------
        String className = PlanComercialSDM.CLASS_NAME;
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Source_Class__c = :className];
        System.assertEquals(false, errorLogs.isEmpty(), 'Deberia haber error logs');
    }
}