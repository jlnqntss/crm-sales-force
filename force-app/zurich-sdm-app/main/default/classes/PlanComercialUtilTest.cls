@isTest
public with sharing class PlanComercialUtilTest {
    public static final Integer ACTUAL_YEAR = Date.today().year() + 1;

    @TestSetup
    static void makeData() {        
        
        TestDataFactorySDM.anualPlanSetupData(ACTUAL_YEAR, AccountsSelector.SDM_DT_EMAIL_FIELD);       
    }


    @isTest
    static void testInsertUpdatePlanesMensuales() {

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);

            Test.startTest();
		    System.enqueueJob(new GestionarPlanesMensualesQueueableJob(planesToJob, 'Insert'));     

            System.debug('-------------------------Update KPI-----------------------------------------------------------------------------');

            pc.TargetKPINumber__c = 1000;

            // llamará al encolable por update
            update pc;

            Test.stopTest();

            Plancomercial__c pcPostUpdate = [SELECT Id, TargetKPINumber__c FROM Plancomercial__c WHERE Id = :pc.Id];

            System.assertEquals(1000, pcPostUpdate.TargetKPINumber__c, 'Debe tener KPI con valor 1000');
        }
    }

    @isTest
    static void testDelete() {

        List<PlanComercial__c> planesToJob = new List<PlanComercial__c>([SELECT ID, Name, SendNotifications__c, AccumulateType__c, Startdate__c, EndDate__c, Indicator__c, Segment__c, Product__c, TargetKPINumber__c FROM PlanComercial__c 
                                                        WHERE RecordTypeId = :Schema.SObjectType.PlanComercial__c.getRecordTypeInfosByDeveloperName().get('AnualPlan').getRecordTypeId()
                                                        AND ParentPlan__c != NULL 
                                                        AND Intermediary__c = NULL
                                                        LIMIT 1]);

        if (!planesToJob.isEmpty()) {
            PlanComercial__c pc = planesToJob.get(0);

            Test.startTest();
            delete pc;
            Test.stopTest();

            List<Plancomercial__c> deletedPC = new List<PlanComercial__c>([SELECT Id, TargetKPINumber__c FROM Plancomercial__c WHERE Id = :pc.Id]);

            System.assertEquals(0, deletedPC.size(), 'Se debe haber eliminado el plan anual');
        }
    }
}
