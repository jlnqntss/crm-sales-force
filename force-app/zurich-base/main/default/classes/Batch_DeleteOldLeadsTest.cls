/**
 * @description       : 
 * @author            : rserrano
 * @group             : 
 * @last modified on  : 25/04/2024
 * @last modified by  : rserrano
**/
@IsTest
public with sharing class Batch_DeleteOldLeadsTest { 

    private static final String OFFER_SCOPE_VENTAS = GlobalConfigUtil.getGlobalConfigurationValue('Opportunity_Scope_Ventas');
    private static final String OFFER_STATUS_LEGIT_LEAD = GlobalConfigUtil.getGlobalConfigurationValue('Opportunity_Stage_Name_Legit_Lead');

    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Lead', 2);
        insert accounts; 

        //List<Competitor__c> competitors = TestDataFactory.generateCompetitors(accounts, 2);
        //insert competitors;
    }

    @isTest
    static void testBatchUnicaOfertaVentas()
    {
        List<Account> leadsList = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead'];
        // Inserto oferta Ventas/ZRM
        List<Opportunity> opportunitiesToInsert = TestDataFactory.generateOpportunities(leadsList, OFFER_SCOPE_VENTAS, OFFER_STATUS_LEGIT_LEAD, Date.today()+30, 2);
        insert opportunitiesToInsert;

        // Envejezco las ofertas mas allá de 90 días
        for(Opportunity offer : opportunitiesToInsert)
        {
            Test.setCreatedDate(offer.Id, Datetime.now().addDays(-91));
        }


        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        Database.executeBatch(batch, 200);

        Test.stopTest();
        
        //Recuperar registros después de la ejecución
        List<Account> updatedLeadList = [SELECT Id FROM Account WHERE Recordtype.DeveloperName = 'Lead'];
        List<Opportunity> updatedOpportunityList = [SELECT Id FROM Opportunity];
        List<Competitor__c> updatedCompetitorList = [SELECT Id FROM Competitor__c];

        Assert.isTrue(updatedLeadList.size() == 0, 'Se deberían haber borrado todos los leads');
        Assert.isTrue(updatedOpportunityList.size() == 0, 'Se deberían haber borrado todas las ofertas');
        Assert.isTrue(updatedCompetitorList.size() == 0, 'Se deberían haber borrado todas las competencias');
    }


    @isTest
    static void testSchedulerOK()
    {
        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        String sch = '0 0 23 ? * * *';
        String jobID = System.schedule('BATCH DELETE OLD LEADS Test', sch, batch);

        Test.stopTest();
        
        List<CronTrigger> cronList = new List<CronTrigger>([SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobID]);

        Assert.areEqual(1, cronList.size(), 'Debe haber un job programado');
    }
}