/**
 * Test para la clase PlanComercialSDM
 *
 * @author nts (agonzalezisasi)
 * @date 27/07/2021
 */
@isTest
private with sharing class PlanComercialSDMTest
{
    static final String PLAN_NAME = 'Plan 1';
    /**
     * Metodo comun para todas los metodos de test. Inicializa los datos de prueba
     *
     * @author nts (agonzalezisasi)
     * @date 29/06/2021
     */
    @TestSetup
    private static void makeData() 
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
    private static void testCalculateRealKPI_ok()
    {
        // Se recuperan las planes comerciales
        List<PlanComercial__c> plans = [
            SELECT Id, CreatedById, AssignedTo__c, StartDate__c, EndDate__c, IsOwnedByHomeOffice__c,
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
            'PN', PlanComercialSDM.SETTINGS_CALCULATION_TYPE_SUM, 'PN__c', null, true, 'PA_PN__C'));
        sdm.testSettingsIndicator.add(TestDataFactorySDM.generateSDMSettingsPlan(
            'Ratio_Claim', PlanComercialSDM.SETTINGS_CALCULATION_TYPE_RATIO, 'TotalLoad__c', 'Income__c', false, null));
        sdm.testSettingsIndicator.add(TestDataFactorySDM.generateSDMSettingsPlan(
            'Ratio_PoliciesPNIncreas', PlanComercialSDM.SETTINGS_CALCULATION_TYPE_GROWTH, 'PoliciesPN__c', 'PA_PoliciesPN__c', false, null));
        
        // Calculo del KPI para los planes
        sdm.calculateRealKPI(plans);
        Test.stopTest();


        // Comprobacion del resultado -----------------------------------------
        List<PlanComercial__c> checkPlans = [
            SELECT Id, Name, Actual_KPI__c, PAActualKPI__c FROM PlanComercial__c
            WHERE Actual_KPI__c != null
        ];
        System.assertEquals(4, checkPlans.size(), 'Deberia haber 4 planes');
        // Relacionamos el nombre del plan con el resultado del calculo que deberia dar
        Map<String, Decimal> mapPlanResult = new Map<String, Decimal> {
            PLAN_NAME => 10,
            'Plan 2' => 0.4,
            'Plan 3' => 0.75,
            'Plan 4' => 13
        };

        // Relacionamos el nombre del plan con el resultado del cálculo que debería dar para el periodo anterior
        Map<String, Decimal> mapPlanResultPA = new Map<String, Decimal>{PLAN_NAME => 8, 'Plan 4' => 10};

        // Comprobamos el resultado del calculo de cada plan
        for(PlanComercial__c plan: checkPlans) {
            Decimal planResult = mapPlanResult.get(plan.Name);
            System.assertEquals(planResult, plan.Actual_KPI__c, 'El calculo deberia ser ' + planResult + ' para el plan ' + plan.Name);

            // Si es un plan (Plan 1 y Plan 4) sobre los que se ha calculado el KPI del periodo anterior
            if (mapPlanResultPA.containsKey(plan.Name))
            {
                Decimal planResultPA = mapPlanResultPA.get(plan.Name);
                Assert.areEqual(planResultPA, plan.PAActualKPI__c, 'El cálculo del KPI del periodo anterior debería ser ' + planResultPA + ' para el plan ' + plan.Name);
            }
        }
    }
        
    /**
     * Test del metodo que calcula el KPI de una serie de Planes comerciales
     *
     * @author nts (agonzalezisasi)
     * @date 27/07/2021
     */
    @isTest
    private static void testCalculateRealKPI_no_settings()
    {
        // Se recuperan las planes comerciales
        List<PlanComercial__c> plans = [
            SELECT Id, CreatedById, AssignedTo__c, StartDate__c, EndDate__c, IsOwnedByHomeOffice__c,
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
    private static void testRemoveAnnualPlans()
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
            plan.Name = PLAN_NAME;
            plan.StartDate__c = Date.newInstance(2021, 1, 1);
            plan.EndDate__c = Date.newInstance(2021, 12, 31);
            plan.AccumulateType__c = PlanComercialSelector.ACCUMULATE_TYPE_YRD;    
            plan.TargetKPICurrency__c = 1;
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

    /**
     * Test del metodo que elimina planes anuales de usuarios que ya no tienen visibilidad sobre un mediador
     *
     * @author aberuete
     * @date 11/04/2023
     */
    @isTest
    private static void testIfIntermediaryAndUserDeletedEliminatePlans()
    {
        // Recuperamos un ATM
        AccountTeamMember atm = [
            SELECT Id, UserId, AccountId 
            FROM AccountTeamMember 
            WHERE User.Profile.Name = :TestDataFactorySDM.RN_PROFILE
            LIMIT 1
        ];
         // Obtenemos el id de usuario 1
         User rnUser = new User(Id=atm.UserId);
         // Y el id de mediador 1 para crear 1 plan
         Account intermediary = new Account(Id= atm.AccountId);

         // Creamos el plan comercial anual
        Id rtAnnualPlanId = (new PlanComercialSelector()).rtPlanAnualId;
        List<PlanComercial__c> intermediaryPlans = TestDataFactorySDM.generatePlans(
            new List<Account>{intermediary}, 1
        );

        intermediaryPlans[0].Name = PLAN_NAME;
        intermediaryPlans[0].StartDate__c = Date.newInstance(2021, 1, 1);
        intermediaryPlans[0].EndDate__c = Date.newInstance(2021, 12, 31);
        intermediaryPlans[0].AccumulateType__c = PlanComercialSelector.ACCUMULATE_TYPE_YRD;    
        intermediaryPlans[0].TargetKPICurrency__c = 1;
        intermediaryPlans[0].AssignedTo__c = rnUser.Id;
        intermediaryPlans[0].RecordTypeId = rtAnnualPlanId;
        
        // lo insertamos
        System.runAs(rnUser) 
        {
            insert intermediaryPlans;
        }

        Set<String> deletedRelations = new Set<String>();
        deletedRelations.add(atm.AccountId + '#' + atm.UserId);

        Test.startTest();
        PlanComercialSDM sdm = new PlanComercialSDM();
        sdm.ifIntermediaryAndUserDeletedEliminatePlans(intermediaryPlans, deletedRelations);
        Test.stopTest();

        List<PlanComercial__c> existingPlans = [
            SELECT Id 
            FROM PlanComercial__c 
            WHERE RecordtypeId = :rtAnnualPlanId
            AND Intermediary__c != null
        ];

        System.assertEquals(0, existingPlans.size(), 'Deberia haber 0 planes anuales con mediador');
    }

    /**
     * Test que comprueba que se generan correctamente los mapas de intermediarios para calcular posteriormente los kpis
     *
     * @author aberuete
     * @date 11/04/2023
     */
    @isTest
    private static void testGenerateMapIntermediariesToCalculateKpi()
    {
        PlanComercialSDM sdm = new PlanComercialSDM();
        sdm.mapIntermediariesByUserId = new Map<Id, Set<Id>>();
        sdm.mapIntermediariesByUserIdAndAgrupationId = new Map<Id, Map<Id, Set<Id>>>();
        sdm.allIntermediaries = new Set<Id>();

        List<AccountTeamMember> atms = [
            SELECT Id, UserId, AccountId,Account.ParentId 
            FROM AccountTeamMember 
            WHERE User.Profile.Name = :TestDataFactorySDM.RN_PROFILE and Account.ParentId != null
            LIMIT 1
        ];

        Test.startTest();
        sdm.generateMapIntermediariesToCalculateKpi (atms);
        Test.stopTest();

        List<Id> userIds = new List<Id> (sdm.mapIntermediariesByUserId.keySet());
        userIds.add(new List<Id>(sdm.mapIntermediariesByUserIdAndAgrupationId.keySet())[0]);
        List<Id> accountsIds = new List<Id> (sdm.mapIntermediariesByUserId.values()[0]);
        accountsIds.add(new List<Id>((sdm.mapIntermediariesByUserIdAndAgrupationId.values()[0]).keySet())[0]);
        accountsIds.add(new List<Id>((sdm.mapIntermediariesByUserIdAndAgrupationId.values()[0]).values()[0])[0]);

        System.assertEquals(atms[0].UserId, userIds[0], 'El id de usuario del atm debería estar en el mapa de intermediarios por usuario');
        System.assertEquals(atms[0].AccountId, accountsIds[0], 'El id de la cuenta del atm debería estar en el mapa');
        System.assertEquals(atms[0].UserId, userIds[1], 'El id de usuario del atm debería estar en el mapa de intermediario por usuario por agrupación');
        System.assertEquals(atms[0].Account.ParentId, accountsIds[1], 'El id de la cuenta de agrupación del atm debería estar en el mapa');
        System.assertEquals(atms[0].AccountId, accountsIds[2], 'El id de la cuenta del atm debería estar en el mapa de intermediario por usuario por agrupación');
        System.assertEquals(true, sdm.allIntermediaries.contains(atms[0].AccountId), 'El id de la cuenta del atm debería estar en el mapa de todos los intermediarios');
    }
    /**
    * Test que comprueba si se crea correctamente el mapa de kpis por intermediario
    *
    * @author aberuete
    * @date 11/04/2023
    */
    @isTest
    private static void testIfKpisNotEmptyGenerateMapKpiIntermediary()
    {
        PlanComercialSDM sdm = new PlanComercialSDM();
        List<KPI__c> kpis = [Select id,Intermediary__c from Kpi__c where Intermediary__c != null limit 2];

        Test.startTest();
        sdm.ifKpisNotEmptyGenerateMapKpiIntermediary (kpis);
        Test.stopTest();
        
        List<Id> intermediariyIds = new List<Id>(sdm.mapKPIsByIntermediary.keySet());

        System.assertEquals(kpis[0].Intermediary__c, intermediariyIds[0], 'El intermediario debería estar en el mapa');
        System.assertEquals(kpis[0], sdm.mapKPIsByIntermediary.values()[0][0], 'El primer kpi debería de estar en el mapa');
    }

    /**
     * Test que comprueba si se obtiene correctamente los kpis anuales del último mes
     *
     * @author aberuete
     * @date 11/04/2023
     */
    @isTest
    private static void testGetKpisAnualOfTheLastMonth()
    {
        PlanComercialSDM sdm = new PlanComercialSDM();
        Set<String> fields = new Set<String>();
        fields.addAll(PlanComercialSDM.KPI_FILTER_FIELDS);
        List<KPI__c> kpis = new List<KPI__c>();
        Boolean containsYTD = true;
        List<Account> intermediaryList = [Select id from Account where recordtype.developerName = 'Intermediary' ];
        Set<Id> intermediaries = new Map <Id,Account>(intermediaryList).keySet();
        List<KPI__c> kpisToVerify = [Select id from KPI__c where CalcYear__c = '2021' and CalcMonth__c =: sdm.lastMonthOfYear];

        for (KPI__c kpi :kpisToVerify)
        {
            kpi.Temporalidad__c = 'YTD';
        }
        update kpisToVerify;
        
        Test.startTest();
        kpis = sdm.getKpisAnualOfTheLastMonth (intermediaries, fields, containsYTD, kpis);
        Test.stopTest();

        Set<Id> kpisIdsToVerify = new Map<Id,Kpi__c> (kpisToVerify).keySet();
        Set<Id> kpisIds = new Map<Id,Kpi__c> (kpis).keySet();
        System.assertEquals(true, kpisIds.equals(kpisIdsToVerify), 'Los dos conjuntos de ids de kpis deben ser iguales');
    }

     /**
     * Test que comprueba si se obtienen correctamente los campos del métadato SDMCommercialPlan__mdt
     *
     * @author aberuete
     * @date 17/04/2023
     */
    @isTest
    private static void testIfIndicatorSettingNotNUll()
    {
        PlanComercialSDM sdm = new PlanComercialSDM();
        sdm.containsMonths = false;
        sdm.containsYTD = false;
        sdm.userIdsFromPlans = new Set<Id>();
        Set<String> kpiFields = new Set<String>();
        SDMCommercialPlan__mdt indicatorSetting = [Select id,FirstField__c,SecondField__c,ThirdField__c,CalculatedPreviousPeriod__c,PreviousPeriodField__c from SDMCommercialPlan__mdt where Indicator__c = 'PN' limit 1 ];
        PlanComercial__c plan = [Select id,AccumulateType__c,AssignedTo__c from PlanComercial__c where AccumulateType__c != null and AssignedTo__c!= null  limit 1 ];

        Test.startTest();
        kpiFields = sdm.ifIndicatorSettingNotNUll (indicatorSetting, kpiFields, plan);
        Test.stopTest();

        Set<String> kpiFieldsResult = new Set<String>{'PN__c','PA_PN__c'};
        Set<Id> userIdsResult = new Set<Id>{plan.AssignedTo__c};

        System.assertEquals(true, kpiFields.equals(kpiFieldsResult), 'Los campos de kpis deberían ser iguales');
        System.assertEquals(true, sdm.userIdsFromPlans.equals(userIdsResult), 'El id del usuario del plan debería estar en el conjunto de ids de usuarios');
    }

    /**
     * Test que comprueba si se obtienen correctamente los intermediarios asociados a un plan comercial
     *
     * @author aberuete
     * @date 17/04/2023
     */
    @isTest
    private static void testGetIdsIntermediariesOfPlan()
    {
        PlanComercialSDM sdm = new PlanComercialSDM();
        sdm.mapIntermediariesByUserId = new Map<Id, Set<Id>>();
        sdm.mapIntermediariesByUserIdAndAgrupationId = new Map<Id, Map<Id, Set<Id>>>();
        Set<Id> listIntermediaries = new Set<Id>();

        PlanComercial__c plan = [Select id,Intermediary__c,AssignedTo__c  from PlanComercial__c where Intermediary__c!= null and AssignedTo__c != null and Intermediary__r.RecordType.DeveloperName = 'intermediary' limit 1 ];
        PlanComercial__c planWithoutIntermediary = [Select id,Intermediary__c,AssignedTo__c  from PlanComercial__c where Intermediary__c = null and AssignedTo__c != null  limit 1 ];
        
        sdm.mapIntermediariesByUserId.put(plan.AssignedTo__c, listIntermediaries);
        listIntermediaries.add(plan.Intermediary__c);

        Test.startTest();
        Set<Id> intermediaries = sdm.getIdsIntermediariesOfPlan (plan, plan.AssignedTo__c);
        Set<Id> intermediariesNotInPlan = sdm.getIdsIntermediariesOfPlan (planWithoutIntermediary, plan.AssignedTo__c);
        Test.stopTest();

        System.assertEquals(true, intermediaries.equals(new Set<Id>{plan.Intermediary__c}), 'El id de intermediario del plan debería estar en el conjunto de ids devuelto');
        System.assertEquals(true, intermediariesNotInPlan.equals(sdm.mapIntermediariesByUserId.values()[0]), 'El id de intermediario del plan debería estar en el mapa de intermediario por usuario');
    }

    /**
     * Test que comprueba si se obtienen correctamente los kpis de un plan comercial para recalcular su actual kpi
     *
     * @author aberuete
     * @date 17/04/2023
     */
    @isTest
    private static void testGetKpisToCalculate()
    {
        PlanComercialSDM sdm = new PlanComercialSDM();
        sdm.mapKPIsByIntermediary = new Map<Id, List<KPI__c>>();

        KPI__c kpiFromQuery = [Select id,EstructuraUnificada__c,EstructuraDetalle__c,Temporalidad__c,Intermediary__c,CalcYear__c, CalcMonth__c from KPI__c where CalcYear__c = '2021' and CalcMonth__c = '8' limit 1];
        PlanComercial__c plan = [Select id,Segment__c,Product__c,AccumulateType__c,Zone__c,StartDate__c,EndDate__c from PlanComercial__c where Segment__c=: kpiFromQuery.EstructuraUnificada__c and Product__c =:kpiFromQuery.EstructuraDetalle__c and AccumulateType__c=:kpiFromQuery.Temporalidad__c limit 1];
        plan.Zone__c= 'Todos';
        update plan;

        List<KPI__c> kpisOfIntermediary = new List<KPI__c>();
        sdm.mapKPIsByIntermediary.put(kpiFromQuery.Intermediary__c, kpisOfIntermediary);
        kpisOfIntermediary.add(kpiFromQuery);

        Test.startTest();
        List<KPI__c> kpis = sdm.getKpisToCalculate (new Set<Id>{kpiFromQuery.Intermediary__c}, plan);
        Test.stopTest();

        System.assertEquals(kpiFromQuery, kpis[0], 'El kpi debería estar en la lista devuelta');
    }

     /**
     * Test que comprueba si se añade correctamente el plan comercial a actualizar
     *
     * @author aberuete
     * @date 17/04/2023
     */
    @isTest
    private static void testUpdatePlanWithRealKpi()
    {
        PlanComercialSDM sdm = new PlanComercialSDM();
        List<PlanComercial__c> plansToUpdate = new List<PlanComercial__c> ();

        List<KPI__c> kpiFromQuery = [Select id,EstructuraUnificada__c,EstructuraDetalle__c,Temporalidad__c,Intermediary__c,CalcYear__c, CalcMonth__c,PN__c,PA_PN__c from KPI__c where CalcYear__c = '2021' and CalcMonth__c = '8' limit 1];
        PlanComercial__c plan = [Select id,Segment__c,Product__c,AccumulateType__c,Zone__c,StartDate__c,EndDate__c,IsOwnedByHomeOffice__c,Indicator__c from PlanComercial__c where Segment__c=: kpiFromQuery[0].EstructuraUnificada__c and Product__c =:kpiFromQuery[0].EstructuraDetalle__c and AccumulateType__c=:kpiFromQuery[0].Temporalidad__c and Indicator__c = 'PN'  limit 1];
        plan.Zone__c= 'Todos';
        update plan;

        Test.startTest();
        plansToUpdate = sdm.updatePlanWithRealKpi (plansToUpdate,kpiFromQuery, plan);
        Test.stopTest();

        System.assertEquals(plan.Id, plansToUpdate[0].Id, 'El plan debería estar en los planes a actualizar');
    }

     /**
     * Test que comprueba si se actualizan correctamente los planes comerciales tras recalcular sus kpis
     *
     * @author aberuete
     * @date 17/04/2023
     */
    @isTest
    private static void testCalculateRealKpiAndUpdatePlans()
    {
        PlanComercialSDM sdm = new PlanComercialSDM();
        sdm.mapKPIsByIntermediary = new Map<Id, List<KPI__c>>();
        sdm.mapIntermediariesByUserId = new Map<Id, Set<Id>>();
        sdm.mapIntermediariesByUserIdAndAgrupationId = new Map<Id, Map<Id, Set<Id>>>();
        Set<Id> listIntermediaries = new Set<Id>();
        List<PlanComercial__c> plansToUpdate = new  List<PlanComercial__c> ();

        List<KPI__c> kpiFromQuery = [Select id,EstructuraUnificada__c,EstructuraDetalle__c,Temporalidad__c,Intermediary__c,CalcYear__c, CalcMonth__c,PN__c,PA_PN__c from KPI__c where CalcYear__c = '2021' and CalcMonth__c = '8' and Intermediary__c != null  limit 1];
        List<PlanComercial__c> planToUpdate = [Select id,AssignedTo__c,Segment__c,Product__c,AccumulateType__c,Zone__c,StartDate__c,EndDate__c,IsOwnedByHomeOffice__c,Indicator__c,Actual_KPI__c,Intermediary__c from PlanComercial__c where Segment__c=: kpiFromQuery[0].EstructuraUnificada__c and Product__c =:kpiFromQuery[0].EstructuraDetalle__c and AccumulateType__c=:kpiFromQuery[0].Temporalidad__c and Indicator__c = 'PN' and Intermediary__c =:kpiFromQuery[0].Intermediary__c and AssignedTo__c != null  limit 1];
        planToUpdate[0].Zone__c= 'Todos';
        update planToUpdate[0];
        
        List<KPI__c> kpisOfIntermediary = new List<KPI__c>();
        sdm.mapKPIsByIntermediary.put(kpiFromQuery[0].Intermediary__c, kpisOfIntermediary);
        kpisOfIntermediary.add(kpiFromQuery[0]);

        sdm.mapIntermediariesByUserId.put(planToUpdate[0].AssignedTo__c, listIntermediaries);
        listIntermediaries.add(planToUpdate[0].Intermediary__c);

        Test.startTest();
        sdm.calculateRealKpiAndUpdatePlans (planToUpdate, plansToUpdate);
        Test.stopTest();

        PlanComercial__c planAfterUpdate = [Select id,Actual_KPI__c from PlanComercial__c where id =: planToUpdate[0].id ];
      
        System.assertEquals(null, planToUpdate[0].Actual_KPI__c, 'El valor debería ser nulo');
        System.assertNotEquals(null, planAfterUpdate.Actual_KPI__c, 'El valor no debería ser nulo tras actualizarse el plan');
    }

}