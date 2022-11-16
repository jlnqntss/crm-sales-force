/**
 * Test para la clase DeleteOldMensualPlanBatch
 *
 * @author nts (dmunoz)
 * @date 13/09/2021
 */
@isTest
public with sharing class DeleteOldMensualPlanBatchTest {

    @TestSetup
    static void makeData(){
        
        Integer year = Date.today().year();
        TestDataFactorySDM.anualPlanSetupData(year, AccountsSelector.SDM_DT_EMAIL_FIELD);

        // crear planes mensuales
        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPIPercent__c, TargetKPINumber__c, TargetKPICurrency__c, Zone__c  FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);
            Objective__c obj = TestDataFactory.generateObjective(year, pc.Indicator__c, pc.Segment__c, pc.Product__c, pc.Zone__c, 80.0, 20.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

            insert obj;
        }
    }
    
    /**
     * Test Programar borrado planes mensuales por fecha
     *
     * @author nts (dmunoz)
     * @date 13/09/2022
     */
    @isTest
    static void testScheduleByDate() {  
        
        // prueba batch
        Test.startTest();
        String jobName = 'testScheduleByDate';
        String cron = '0 0 13 * * ?';
        Integer months = 1;

        String jobId = DeleteOldMensualPlanBatch.createStandardScheduleByDate(jobName, cron, months);

        Test.stopTest();

        List<CronTrigger> cronList = new List<CronTrigger>([SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]);

        System.assertEquals(1, cronList.size(), 'Debe haber un job programado');
        
    }

    /**
     * Test Programar borrado planes mensuales por query
     *
     * @author nts (dmunoz)
     * @date 13/09/2022
     */
    @isTest
    static void testScheduleByQuery() {
        
        // prueba batch
        Test.startTest();
        String jobName = ''; // lo dejo vacio para usar los valores por defecto
        String cron = ''; // lo dejo vacio para usar los valores por defecto
        String query = 'SELECT Id FROM PlanComercial__c WHERE RecordType.DeveloperName = \'MensualPlan\'';

        String jobId = DeleteOldMensualPlanBatch.createStandardScheduleByQuery(jobName, cron, query);

        Test.stopTest();

        List<CronTrigger> cronList = new List<CronTrigger>([SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]);

        System.assertEquals(1, cronList.size(), 'Debe haber un job programado');

        //List<PlanComercial__c> planesMensualesAfter = new List<PlanComercial__c>([SELECT id FROM PlanComercial__c WHERE Recordtype.DeveloperName = 'MensualPlan']);
        //System.assertEquals(0, planesMensualesAfter.size(), 'No debe haber ningun plan mensual');
        
    }

}
