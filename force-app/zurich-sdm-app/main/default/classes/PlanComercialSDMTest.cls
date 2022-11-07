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
            SELECT Id, CreatedById, AssignedTo__c, StartDate__c, EndDate__c,
                   Indicator__c, Intermediary__c, Product__c, Segment__c, AccumulateType__c, Zone__c
            FROM PlanComercial__c
        ];
        System.assertEquals(4, plans.size(), 'Deberia haber 4 planes antes del test');


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


        // Comprobacion del resultado -----------------------------------------
        List<PlanComercial__c> checkPlans = [
            SELECT Id, Name, Actual_KPI__c FROM PlanComercial__c
            WHERE Actual_KPI__c != null
        ];
        System.assertEquals(4, checkPlans.size(), 'Deberia haber 4 planes');
        // Relacionamos el nombre del plan con el resultado del calculo que deberia dar
        Map<String, Decimal> mapPlanResult = new Map<String, Decimal> {
            'Plan 1' => 10,
            'Plan 2' => 0.4,
            'Plan 3' => 0.75,
            'Plan 4' => 13
        };
        // Comprobamos el resultado del calculo de cada plan
        for(PlanComercial__c plan: checkPlans) {
            Decimal planResult = mapPlanResult.get(plan.Name);
            System.assertEquals(planResult, plan.Actual_KPI__c, 'El calculo deberia ser ' + planResult + ' para el plan ' + plan.Name);
        }
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
        // Se recuperan las planes comerciales
        List<PlanComercial__c> plans = [
            SELECT Id, CreatedById, AssignedTo__c, StartDate__c, EndDate__c,
                   Indicator__c, Intermediary__c, Product__c, Segment__c, AccumulateType__c
            FROM PlanComercial__c
        ];
        System.assertEquals(4, plans.size(), 'Deberia haber 4 planes antes del test');

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

    /**
     * Test del metodo que elimina planes anuales de usuarios que ya no tienen visibilidad sobre un mediador
     *
     * @author nts (agonzalezisasi)
     * @date 13/10/2021
     */
    @isTest
    static void testRemoveAnnualPlans()
    {
        // Recuperamos un ATM
        List<AccountTeamMember> atms = [
            SELECT Id, UserId, AccountId 
            FROM AccountTeamMember 
            WHERE User.Profile.Name = :TestDataFactorySDM.RN_PROFILE
            LIMIT 1
        ];
        System.assertEquals(1, atms.size(), 'Deberia haber al menos 1 registro de ATM');
        // Obtenemos el id de usuario 1
        User rnUser = new User(Id=atms[0].UserId);
        // Y el id de mediador 1 para crear 1 plan
        Account intermediary = new Account(Id= atms[0].AccountId);

        // Creamos el plan comercial anual
        Id rtAnnualPlanId = (new PlanComercialSelector()).rtPlanAnualId;
        List<PlanComercial__c> intermediaryPlans = TestDataFactorySDM.generatePlans(
            new List<Account>{intermediary}, 1
        );
        for(PlanComercial__c plan: intermediaryPlans) {
            plan.Name = 'Plan 1';
            plan.StartDate__c = Date.newInstance(2021, 1, 1);
            plan.EndDate__c = Date.newInstance(2021, 12, 31);
            plan.AccumulateType__c = PlanComercialSelector.ACCUMULATE_TYPE_YRD;    
            plan.TargetKPINumber__c = 1;
            plan.AssignedTo__c = rnUser.Id;
            plan.RecordTypeId = rtAnnualPlanId;
        }

        // lo insertamos
        System.runAs(rnUser) {
            insert intermediaryPlans;
        }

        // Comprobamos que existe
        // De nuevo recuperamos los planes anuales con mediadores
        List<PlanComercial__c> plans = [
            SELECT Id 
            FROM PlanComercial__c 
            WHERE RecordtypeId = :rtAnnualPlanId
            AND Intermediary__c != null
        ];
        System.assertEquals(1, plans.size(), 'Deberia haber 1 plan anual');

        // Y lo borramos el primer ATM para comprobar que solo se elimna esa relacion y no ambas
        delete atms;

        Test.startTest();
        PlanComercialSDM sdm = new PlanComercialSDM();
        sdm.removeAnnualPlans(atms);
        Test.stopTest();

        // Comprobamos el resultado del test

        // De nuevo recuperamos los planes anuales con mediadores
        List<PlanComercial__c> existingPlans = [
            SELECT Id 
            FROM PlanComercial__c 
            WHERE RecordtypeId = :rtAnnualPlanId
            AND Intermediary__c != null
        ];
        // Ahora deberia haber 1 plan anual
        System.assertEquals(0, existingPlans.size(), 'Deberia haber 0 planes anuales con mediador');
    }
}