@isTest
public with sharing class ObjetivosHandlerTest {

    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;

    @TestSetup
    static void makeData() {        
        
        TestDataFactorySDM.anualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);       
    }

    @isTest
    static void testOK_insertObjetivo() {

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);
            System.debug('pc original KPI  ' + pc.TargetKPINumber__c);
            Objective__c obj = TestDataFactory.generateObjective(ACTUAL_YEAR, pc.Indicator__c, pc.Segment__c, pc.Product__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

            Test.startTest();
            insert obj;

            Test.stopTest();

            List<PlanComercial__c> planesMensuales = new List<PlanComercial__c>([SELECT ID, Name, startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c
                                                                                FROM PlanComercial__c 
                                                                                WHERE ParentPlan__c =: pc.Id 
                                                                                AND RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('MensualPlan').getRecordTypeId()]);
            System.debug('num mensuales testOK_insertObjetivo ' + planesMensuales.size());
            
            System.assertEquals(0, planesMensuales.size(), 'No hay planes mensuales insertados');
        }        
    }


    @isTest
    static void testOK_updateObjetivo() {

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);
            System.debug('pc original KPI  ' + pc.TargetKPINumber__c);
            Objective__c objetivo = TestDataFactory.generateObjective(ACTUAL_YEAR, pc.Indicator__c, pc.Segment__c, pc.Product__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
            insert objetivo;

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
            System.debug('num mensuales testOK_updateObjetivo ' + planesMensuales.size());

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