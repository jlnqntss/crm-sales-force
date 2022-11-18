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
        TestDataFactorySDM.AnualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);
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
        // 1 plan RN, hijo del plan del DT
        System.assertEquals(1, childPlans.size(), 'Deberia haber 1 plan descendiente');
    }

    /**
     * Test del metodo que recupera los planes anuales por mediador y usuario
     *
     * @author nts (agonzalezisasi)
     * @date 11/10/2021
     */
    @isTest
    static void findAnnualPlansByIntermediariesAndUsers()
    {
        String rnEmail = String.format(TestDataFactorySDM.BUSINESS_EMAIL, new List<String>{String.valueOf(0)});
        List<User> users = [SELECT Id FROM User WHERE Email = :rnEmail];
        System.assertEquals(1, users.size(), 'Deberia haber 1 usuario RN');
        Id rtIntermediaryId = (new AccountsSelector()).rtIntermediaryId;
        List<Account> intermediaries = [SELECT Id FROM Account WHERE RecordTypeId = :rtIntermediaryId];
        System.assertEquals(3, intermediaries.size(), 'Deberia haber 3 mediadores');

        Test.startTest();
        PlanComercialSelector planSel = new PlanComercialSelector();
        List<Plancomercial__c> plans = planSel.findAnnualPlansByIntermediariesAndUsers(
            (new Map<Id, Account>(intermediaries)).keySet(), new Set<Id>{Users[0].Id}
        );
        Test.stopTest();

        // Comprobamos el resultado del test
        System.assertEquals(3, plans.size(), 'Deberia haber 3 planes anuales');
    }

    /**
     * Test del metodo que recupera los planes mensuales a partir de unos planes anuales
     *
     * @author nts (dmunoz)
     * @date 29/07/2022
     */
    @isTest
    static void findMensualPlans() {

        List<PlanComercial__c> planesAnuales = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        Test.startTest();
        PlanComercialSelector planSel = new PlanComercialSelector();
        List<Plancomercial__c> plans = planSel.findMensualPlans(planesAnuales);
        Test.stopTest();

        // Comprobamos el resultado del test
        System.assertEquals(0, plans.size(), 'Deberia haber 0 planes mensuales');
    }


    /**
     * Test del metodo que recupera los planes anuales a partir de los indicadores del objetivo
     *
     * @author nts (dmunoz)
     * @date 29/07/2022
     */
    @isTest
    static void findAnualPlanByObjectiveIndicators() {

        List<PlanComercial__c> planesAnuales = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c, Zone__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

     

        if (!planesAnuales.isEmpty()) {
            PlanComercial__c pc = planesAnuales.get(0);

            Set<String> indicatorSet = new Set<String>();
            Set<String> segmentSet = new Set<String>();
            Set<String> productSet = new Set<String>();
            Set<String> zoneSet = new Set<String>();
            Set<Integer> year = new Set<Integer>();

            indicatorSet.add(pc.Indicator__c);
            segmentSet.add(pc.Segment__c);
            productSet.add(pc.Product__c);
            zoneSet.add(pc.Zone__c);
            year.add(pc.StartDate__c.Year());

            Test.startTest();
            PlanComercialSelector planSel = new PlanComercialSelector();
            List<Plancomercial__c> plans = planSel.findAnualPlanByObjectiveIndicators(indicatorSet, segmentSet, productSet, zoneSet, year);

            Test.stopTest();
            
            System.assertEquals(true, plans.isEmpty(), 'No debe haber un plan anual por el valor de metadata');
        }
    }


    /**
     * Test del metodo que recupera los planes mensuales a partir de unos planes anuales
     *
     * @author nts (dmunoz)
     * @date 29/07/2022
     */
    @isTest
    static void findMensualPlanByObjectiveIndicators() {

        List<PlanComercial__c> planesAnuales = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c, Zone__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

     

        if (!planesAnuales.isEmpty()) {
            PlanComercial__c pc = planesAnuales.get(0);

            Test.startTest();
            Objective__c objective = TestDataFactory.generateObjective(ACTUAL_YEAR, pc.Indicator__c, pc.Segment__c, pc.Product__c, pc.Zone__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
            insert objective;

            Test.stopTest();

            Set<String> indicatorSet = new Set<String>();
            Set<String> segmentSet = new Set<String>();
            Set<String> productSet = new Set<String>();
            Set<String> zoneSet = new Set<String>();
            Set<Integer> year = new Set<Integer>();

            indicatorSet.add(pc.Indicator__c);
            segmentSet.add(pc.Segment__c);
            productSet.add(pc.Product__c);
            zoneSet.add(pc.Zone__c);
            year.add(pc.StartDate__c.Year());

            
            PlanComercialSelector planSel = new PlanComercialSelector();
            List<Plancomercial__c> plans = planSel.findMensualPlanByObjectiveIndicators(indicatorSet, segmentSet, productSet, zoneSet, year);            
            
            System.assertEquals(true, plans.isEmpty(), 'No debe haber plan mensual');
        }
    }

    /**
     * Test del metodo que recupera los email del usuario asignado a un plan
     *
     * @author nts (dmunoz)
     * @date 23/08/2022
     */
    @isTest
    static void findAssignedToEmailFromPC() {
        List<PlanComercial__c> planesComerciales = new List<PlanComercial__c>([SELECT ID FROM PlanComercial__c LIMIT 1]);

        PlanComercialSelector planSel = new PlanComercialSelector();
        Test.startTest();
        Map<Id, PlanComercial__c> result = planSel.findAssignedToDataFromPC(planesComerciales);
        Test.stopTest();

        System.assertEquals(false, result.isEmpty(), 'Debe haber resultados');


    }

    /**
     * Test NULL del metodo que recupera los email del usuario asignado a un plan
     *
     * @author nts (dmunoz)
     * @date 23/08/2022
     */
    @isTest
    static void findAssignedToEmailFromPC_Null() {
        List<PlanComercial__c> planesComerciales = new List<PlanComercial__c>([SELECT ID FROM PlanComercial__c LIMIT 1]);

        PlanComercialSelector planSel = new PlanComercialSelector();
        Test.startTest();
        Map<Id, PlanComercial__c> result = planSel.findAssignedToDataFromPC(null);
        Test.stopTest();

        System.assertEquals(true, result.isEmpty(), 'No debe haber resultados');
    }


    /**
     * Test query planes mensuales a borrar dada una fecha
     *
     * @author nts (dmunoz)
     * @date 23/08/2022
     */
    @isTest
    static void findMensualPlanToDeleteByMaxDate() {

        Date d = Date.today();

        PlanComercialSelector planSel = new PlanComercialSelector();
        Test.startTest();
        List<PlanComercial__c> result = planSel.findMensualPlanToDeleteByMaxDate(d);
        Test.stopTest();

        System.assertEquals(true, result.isEmpty(), 'No debe haber resultados');
    }

    /**
     * Test NULL query planes mensuales a borrar dada una fecha
     *
     * @author nts (dmunoz)
     * @date 23/08/2022
     */
    @isTest
    static void findMensualPlanToDeleteByMaxDate_Null() {

        PlanComercialSelector planSel = new PlanComercialSelector();
        Test.startTest();
        List<PlanComercial__c> result = planSel.findMensualPlanToDeleteByMaxDate(null);
        Test.stopTest();

        System.assertEquals(true, result.isEmpty(), 'No debe haber resultados');
    }


    /**
     * Test query consultar el owner id del parent
     *
     * @author nts (dmunoz)
     * @date 23/08/2022
     */
    @isTest
    static void getParentOwnerId() {

        List<PlanComercial__c> planesComercialesQuery = new List<PlanComercial__c>([SELECT Id FROM PlanComercial__c LIMIT 1]);

        PlanComercialSelector planSel = new PlanComercialSelector();
        Test.startTest();
        Map<Id,PlanComercial__c> result = planSel.getParentOwnerId(planesComercialesQuery);
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Debe haber 1 resultado');
    }

    /**
     * Test NULL query consultar el owner id del parent
     *
     * @author nts (dmunoz)
     * @date 23/08/2022
     */
    @isTest
    static void getParentOwnerId_Null() {

        PlanComercialSelector planSel = new PlanComercialSelector();
        Test.startTest();
        Map<Id,PlanComercial__c> result = planSel.getParentOwnerId(null);
        Test.stopTest();

        System.assertEquals(true, result.isEmpty(), 'No debe haber resultados');
    }
}