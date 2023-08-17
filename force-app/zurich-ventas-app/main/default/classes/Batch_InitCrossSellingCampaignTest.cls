@isTest
public with sharing class Batch_InitCrossSellingCampaignTest {
    
    @TestSetup
    static void makeData() {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 2);
        Integer i = 0;
        for (Campaign c: campaigns) {
            c.Type = 'Cross Selling';
            c.IsActive = true;
            c.StartDate = Date.today();
            c.ExternalId__c = 'TestCampaign';

            if (i == 1) { // la segunda campaña será para probar el clone al CC
                c.ExternalId__c += '#CC';
            }

            i++;
        }
        insert campaigns;

        // hotfix: obtener cuentas de tipo personales con el campo PersonContactId relleno
        accounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null]);


        // generate campaign member status
        List<Campaign> campaignTest = [SELECT Id FROM Campaign WHERE ExternalId__c = 'TestCampaign'];
        List<String> newStatusList = new List<String>();
        newStatusList.add('Pdte. Revisión Mediador');
        newStatusList.add('Gestión CC');

        List<CampaignMemberStatus> cmsList = TestDataFactory.generateCampaignStatus(newStatusList, campaignTest.get(0).Id);
        insert cmsList;

        // generate campaign member
        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(accounts, campaignTest, 'Pdte. Revisión Mediador');
        for (CampaignMember cm: campaignMembers) {
            cm.LeadPhone__c = '600000000';
        }
        insert campaignMembers;

        
    }

    @isTest
    static void executeBatch_ok() {

        List<CampaignMember> ccCampaignMemberListBefore = new List<CampaignMember>([SELECT Id FROM CampaignMember WHERE Campaign.ExternalId__c = 'TestCampaign#CC']);

        Test.startTest();
        Batch_InitCrossSellingCampaign batch = new Batch_InitCrossSellingCampaign();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        List<CampaignMember> ccCampaignMemberListAfter = new List<CampaignMember>([SELECT Id FROM CampaignMember WHERE Campaign.ExternalId__c = 'TestCampaign#CC']);

        System.assertEquals(true, ccCampaignMemberListBefore.size() != ccCampaignMemberListAfter.size(), 'El tamaño no debe coincidir en la campaña de CC, tras ejecutar debe tener los registros clonados');

    }


    @isTest
    static void testScheduleByQuery() {
        
        // prueba batch
        Test.startTest();
        String jobName = 'Prueba Test Batch'; 
        String cron = '0 0 3 * * ?'; 

        String jobId = Batch_InitCrossSellingCampaign.createStandardSchedule(jobName, cron);

        Test.stopTest();

        List<CronTrigger> cronList = new List<CronTrigger>([SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]);

        System.assertEquals(1, cronList.size(), 'Debe haber un job programado');        
    }
}