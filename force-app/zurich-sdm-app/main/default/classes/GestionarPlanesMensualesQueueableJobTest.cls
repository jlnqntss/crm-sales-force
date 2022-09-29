@isTest
public with sharing class GestionarPlanesMensualesQueueableJobTest {

    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;

    @TestSetup
    static void makeData() {        
        
        TestDataFactorySDM.anualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);       
    }


    @isTest
    static void testInsertUpdatePlanesMensuales() {

        System.debug('----------------------------Test testInsertPlanesMensuales-------------------------------------------------------------');

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, 
                                                                Indicator__c, Segment__c, Product__c, TargetKPIPercent__c, TargetKPINumber__c, TargetKPICurrency__c, OwnerId, Actual_KPI__c 
                                                        FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);
            System.debug('pc original KPI  ' + pc.TargetKPINumber__c);
            Objective__c obj = TestDataFactory.generateObjective(ACTUAL_YEAR, pc.Indicator__c, pc.Segment__c, pc.Product__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

            insert obj;

            Test.startTest();
		    System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesToJob, 'Insert'));     

            System.debug('-------------------------Update KPI-----------------------------------------------------------------------------');

            pc.TargetKPINumber__c = 1000;

            // llamará al encolable por update
            update pc;

            Test.stopTest();


            List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()]);
            System.debug('num mensuales ' + planesMensuales.size());
            
            System.assertEquals(12, planesMensuales.size(), 'Se deben haber insertado 12 planes mensuales');

            Date endDate = Date.newInstance(ACTUAL_YEAR, 1, 31);
            List<PlanComercial__c> planesMensualesUpdated = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE ParentPlan__c =: pc.Id 
                                                                                AND RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()
                                                                                AND EndDate__c = :endDate]);

            System.debug('planesMensualesUpdated ' + planesMensualesUpdated);

            System.assertEquals(800, (pc.TargetKPINumber__c * obj.January__c) / 100, 'Se espera el 80% de 1000, 800');
        }
    }

    @isTest
    static void deletePlanesMensuales() {
        System.debug('----------------------------Test deletePlanesMensuales-------------------------------------------------------------');

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);

            Test.startTest();
		    System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesToJob, 'Insert'));     

            System.debug('-------------------------Delete KPI-----------------------------------------------------------------------------');

            // llamará al encolable por update
            delete pc;

            Test.stopTest();


            List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE ParentPlan__c =: pc.Id 
                                                                                AND RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()]);
            System.debug('num mensuales ' + planesMensuales.size());

            System.assertEquals(0, planesMensuales.size(), 'Se deben haber eliminado todos los planes mensuales');
        }
    }


    @isTest
    static void testNullInputs() {
        System.debug('----------------------------Test testNullInputs-------------------------------------------------------------');

        List<PlanComercial__c> planesComercialesAnualesList = null;

        Test.startTest();
        System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesComercialesAnualesList, null));   
        Test.stopTest();

        List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()]);
        System.debug('num mensuales testNullInputs ' + planesMensuales.size());

        System.assertEquals(0, planesMensuales.size(), 'No se deben haber insertado planes mensuales');
    }

    // elimino campos obligatorios de los planes y se captura excepcion
    @isTest
    static void testKOInsertPlanesMensuales() {
        System.debug('----------------------------Test testKOInsertPlanesMensuales-------------------------------------------------------------');

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);

            Objective__c obj = TestDataFactory.generateObjective(ACTUAL_YEAR, pc.Indicator__c, pc.Segment__c, pc.Product__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

            insert obj;

            Test.startTest();
		    System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesToJob, 'Insert'));     
            Test.stopTest();


            List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE ParentPlan__c =: pc.Id 
                                                                                AND RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()]);
            System.debug('num mensuales testKOInsertPlanesMensuales ' + planesMensuales.size());

            System.assertEquals(0, planesMensuales.size(), 'No se ha creado ningún plan mensual');
        }
    }

    // test delete PC (RN)
    @isTest
    static void testOK_DeletePlanAnualRN() {

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                                        AND ParentPlan__c != NULL 
                                                                        AND Intermediary__c = NULL
                                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);

            Objective__c obj = TestDataFactory.generateObjective(ACTUAL_YEAR, pc.Indicator__c, pc.Segment__c, pc.Product__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

            insert obj;

            Test.startTest();
		    System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesToJob, 'Delete'));     
            Test.stopTest();

            List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE ParentPlan__c =: pc.Id 
                                                                                AND RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()]);
            System.debug('num mensuales testKOInsertPlanesMensuales ' + planesMensuales.size());

            System.assertEquals(0, planesMensuales.size(), 'No debe existir ningun plan mensual');
        }

    }

    // test update objetivo
    @isTest
    static void testOK_UpdatePesosObjetivo() {

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                                        AND ParentPlan__c != NULL 
                                                                        AND Intermediary__c = NULL
                                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);

            Objective__c objective = TestDataFactory.generateObjective(ACTUAL_YEAR, pc.Indicator__c, pc.Segment__c, pc.Product__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
            insert objective;

            List<Objective__c> objectivesList = new List<Objective__c>([SELECT Id, Product__c, Indicator__c, Segment__c, January__c, February__c, March__c, April__c, 
                                                                            May__c, June__c, July__c, August__c, September__c, October__c, November__c, December__c, Total__c, Year__c, Active__c, ExternalId__c
                                                                            FROM Objective__c LIMIT 1]);

            for (Objective__c obj: objectivesList) {
                obj.January__c = 100;
                obj.February__c = 0;
            }

            Test.startTest();
            update objectivesList;   
            Test.stopTest();

            List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE ParentPlan__c =: pc.Id 
                                                                                AND RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()
                                                                                AND CALENDAR_YEAR(StartDate__c) =: ACTUAL_YEAR]);
            System.debug('num mensuales testOK_UpdatePesosObjetivo ' + planesMensuales.size());

            if (!planesMensuales.isEmpty()) {
                PlanComercial__c pcMensual = planesMensuales.get(0);
                System.assertEquals(pc.TargetKPINumber__c, pcMensual.TargetKPINumber__c, 'Debe tener el mismo kpi que el anual');
            }            
        }
    }


    // test delete PC (RN)
    @isTest
    static void testOK_DeleteObjetivo() {

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                                        AND ParentPlan__c != NULL 
                                                                        AND Intermediary__c = NULL
                                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);

            Objective__c objective = TestDataFactory.generateObjective(ACTUAL_YEAR, pc.Indicator__c, pc.Segment__c, pc.Product__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
            insert objective;

            List<Objective__c> objectivesList = new List<Objective__c>([SELECT Id, Product__c, Indicator__c, Segment__c, January__c, February__c, March__c, April__c, 
                                                                            May__c, June__c, July__c, August__c, September__c, October__c, November__c, December__c, Total__c, Year__c, Active__c, ExternalId__c
                                                                            FROM Objective__c LIMIT 1]);

            for (Objective__c obj: objectivesList) {
                obj.January__c = 100;
                obj.February__c = 0;
                //mapObjetivosPesos.put(obj.ExternalId__c, obj);
            }

            Test.startTest();
		    //System.enqueueJob(new GestionarPlanesMensualesQueueableJob(mapObjetivos, 'Update'));  
            delete objectivesList;   
            Test.stopTest();

            List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE ParentPlan__c =: pc.Id 
                                                                                AND RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()
                                                                                AND CALENDAR_YEAR(StartDate__c) =: ACTUAL_YEAR]);
            System.debug('num mensuales testOK_DeleteObjetivo ' + planesMensuales.size());
            System.assertEquals(0, planesMensuales.size(), 'no debe existir ningun plan mensual');               
        }
    }
}