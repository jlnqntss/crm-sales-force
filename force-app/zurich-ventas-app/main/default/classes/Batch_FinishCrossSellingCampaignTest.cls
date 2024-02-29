@IsTest
public with sharing class Batch_FinishCrossSellingCampaignTest {
    
    @TestSetup
    static void makeData(){
        // Crear custom setting que indica el usuario genérico
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;

        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 1);
        
        for (Campaign c: campaigns) {
            c.Type = 'Cross Selling';
            c.IsActive = true;
            c.StartDate = Date.today() - 1;
            c.EndDate = Date.today();
            c.ExternalId__c = 'TestCampaign';
        }

        insert campaigns;

        // Insertar oportunidades
        List<Opportunity> offerList = new List<Opportunity>();

        List<Opportunity> legitLeadOfferList = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'Ventas', 'Legit Lead', Date.today(), 1);
        Integer i = 0;
        for (Opportunity o: legitLeadOfferList) {
            o.InfoQuoteNumber__c = '';              
            o.CampaignId = campaigns.get(0).Id;
            o.ZRM__c = true;
        }

        i = 50;
        List<Opportunity> appSubmittedOferList = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'Ventas', 'App Submitted', Date.today(), 1);
        for (Opportunity o: appSubmittedOferList) {
            o.InfoQuoteNumber__c = o.InfoQuoteNumber__c + i;            
            o.CampaignId = campaigns.get(0).Id;
            o.ZRM__c = true;
            i++;
        }

        i = 100;
        List<Opportunity> quotedOfferList = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'Ventas', 'Quoted', Date.today(), 1);
        for (Opportunity o: quotedOfferList) {
            o.InfoQuoteNumber__c = o.InfoQuoteNumber__c + i;            
            o.CampaignId = campaigns.get(0).Id;
            o.ZRM__c = true;
            i++;
        }

        offerList.addAll(legitLeadOfferList);
        offerList.addAll(appSubmittedOferList);
        offerList.addAll(quotedOfferList);

        insert offerList;

        // insertar tarea
        List<Task> taskList = TestDataFactory.generateInteractionTasksWithWhatId(appSubmittedOferList.get(0).Id, 1);
        insert taskList;
    }

    @isTest
    static void testBatchOk() {

        List<Opportunity> offersBeforeList = new List<Opportunity>([SELECT Id FROM Opportunity WHERE StageName != 'Closed Lost']);

        Test.startTest();

        Batch_FinishCrossSellingCampaign batch = new Batch_FinishCrossSellingCampaign();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        List<Opportunity> offersAfterList = new List<Opportunity>([SELECT Id FROM Opportunity WHERE Id IN :offersBeforeList AND StageName = 'Closed Lost']);
        System.assertEquals(offersBeforeList.size(), offersAfterList.size(), 'Las ofertas deberian haberse cambiado de etapa a Cerrada Perdida');
    }


    @isTest
    static void testScheduleByQuery() {
         // prueba batch
         Test.startTest();
         String jobName = 'testScheduleByQuery';
         String cron = '';
 
         String jobId = Batch_FinishCrossSellingCampaign.createStandardSchedule(jobName, cron);
 
         Test.stopTest();
 
         List<CronTrigger> cronList = new List<CronTrigger>([SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId]);
 
         System.assertEquals(1, cronList.size(), 'Debe haber un job programado');

    }
}