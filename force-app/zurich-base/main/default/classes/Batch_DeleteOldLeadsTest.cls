/**
 * @description       :
 * @author            : rserrano
 * @group             :
 * @last modified on  : 25/04/2024
 * @last modified by  : rserrano
 **/
@IsTest
public with sharing class Batch_DeleteOldLeadsTest
{

    private static final String OFFER_SCOPE_VENTAS = GlobalConfigUtil.getGlobalConfigurationValue('Opportunity_Scope_Ventas');
    private static final String OFFER_STATUS_LEGIT_LEAD = GlobalConfigUtil.getGlobalConfigurationValue('Opportunity_Stage_Name_Legit_Lead');

    @TestSetup
    static void makeData()
    {

        /*****************************  CUSTOM SETTINGS  ****************************/
        Cross_Selling__c ventaCruzada = new Cross_Selling__c();
        ventaCruzada.ContactCenterUser__c = 'generico';
        ventaCruzada.DefaultUser__c = 'adminkli';

        insert ventaCruzada;

        // Insertar objetos para el test

        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Lead', 2);
        insert accounts;

        List<Competitor__c> competitors = TestDataFactory.generateCompetitors(accounts, 2);
        insert competitors;
    }

    // compruebo que en el caso de leads con ofertas legit lead solo de ventas/zrm elimina todos los datos, lead, oferta y competencias
    @isTest
    private static void testBatchUnicaOfertaVentas()
    {
        List<Account> leadsList = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead'];
        // Inserto oferta Ventas/ZRM
        List<Opportunity> opportunitiesToInsert = TestDataFactory.generateOpportunities(leadsList, OFFER_SCOPE_VENTAS, OFFER_STATUS_LEGIT_LEAD, Date.today() + 30, 2);
        insert opportunitiesToInsert;

        // Envejezco las ofertas mas allá de 90 días
        for(Opportunity offer : opportunitiesToInsert)
        {
            Test.setCreatedDate( offer.Id, Datetime.now().addDays(-91) );
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


    // compruebo que un lead le cargo ofertas de ZE y Ventas para que no elimine el lead ni sus competencias
    @isTest
    private static void testBatchLeadConOfertasVentaYZE()
    {
        List<Account> leadsList = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead' LIMIT 1];
        // Inserto oferta Ventas/ZRM
        List<Opportunity> opportunitiesToInsert = TestDataFactory.generateOpportunities(leadsList, OFFER_SCOPE_VENTAS, OFFER_STATUS_LEGIT_LEAD, Date.today() + 30, 1);
        insert opportunitiesToInsert;

        // Inserto oferta ZE
        List<Opportunity> opportunitiesZEToInsert = TestDataFactory.generateOpportunities(leadsList, 'ze', OFFER_STATUS_LEGIT_LEAD, Date.today() + 30, 1);
        // le asigno un codigo de negocio
        for (Opportunity opp: opportunitiesZEToInsert)
        {
            OPP.Scope__c = 'ZE';
            opp.BusinessCode__c = '123456';
        }
        insert opportunitiesZEToInsert;

        // Envejezco las ofertas mas allá de 90 días
        for(Opportunity offer : opportunitiesToInsert)
        {
            Test.setCreatedDate( offer.Id, Datetime.now().addDays(-91) );
        }

        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        //Recuperar registros después de la ejecución
        List<Account> updatedLeadList = [SELECT Id FROM Account WHERE Id = : leadsList.get(0).Id];
        List<Opportunity> updatedOpportunityList = [SELECT Id FROM Opportunity WHERE AccountId = : leadsList.get(0).Id];
        List<Competitor__c> updatedCompetitorList = [SELECT Id FROM Competitor__c WHERE Account__c = : leadsList.get(0).Id];

        Assert.isTrue(updatedLeadList.size() > 0, 'NO Se deberían haber borrado todos los leads');
        Assert.isTrue(updatedOpportunityList.size() > 0, 'NO Se deberían haber borrado todas las ofertas');
        Assert.isTrue(updatedCompetitorList.size() > 0, 'NO Se deberían haber borrado todas las competencias');
    }

    // compruebo que un lead le cargo ofertas de Ventas (2 una con -90 dias y otra con -50) para que no elimine el lead, ni la otra oferta ni sus competencias
    @isTest
    private static void testBatchLeadConOfertasVentaSinCaducar()
    {
        List<Account> leadsList = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead' LIMIT 1];
        // Inserto oferta Ventas/ZRM
        List<Opportunity> opportunitiesToInsert = TestDataFactory.generateOpportunities(leadsList, OFFER_SCOPE_VENTAS, OFFER_STATUS_LEGIT_LEAD, Date.today() + 30, 2);
        insert opportunitiesToInsert;

        // Envejezco solo una oferta mas allá de 90 días
        Test.setCreatedDate( opportunitiesToInsert.get(0).Id, Datetime.now().addDays(-91) );

        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        //Recuperar registros después de la ejecución
        List<Account> updatedLeadList = [SELECT Id FROM Account WHERE Id = : leadsList.get(0).Id];
        List<Opportunity> updatedOpportunityList = [SELECT Id FROM Opportunity WHERE AccountId = : leadsList.get(0).Id];
        List<Competitor__c> updatedCompetitorList = [SELECT Id FROM Competitor__c WHERE Account__c = : leadsList.get(0).Id];

        Assert.isTrue(updatedLeadList.size() > 0, 'NO Se deberían haber borrado todos los leads');
        Assert.isTrue(updatedOpportunityList.size() == 1, 'Debe quedar una oferta de ZRM');
        Assert.isTrue(updatedCompetitorList.size() > 0, 'NO Se deberían haber borrado todas las competencias');
    }


    // compruebo que un lead le cargo ofertas de Ventas (2 una con -90 dias y otra con -50)  y de ZE con fecha caducada para que no elimine el lead, ni las 2 ofertas una de ventas y otra de ZE, ni sus competencias
    @isTest
    private static void testBatchLeadConOfertasVentaYZESinCaducar()
    {
        List<Account> leadsList = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead' LIMIT 1];
        // Inserto oferta Ventas/ZRM
        List<Opportunity> opportunitiesToInsert = TestDataFactory.generateOpportunities(leadsList, OFFER_SCOPE_VENTAS, OFFER_STATUS_LEGIT_LEAD, Date.today() + 30, 2);
        insert opportunitiesToInsert;

        // Envejezco solo una oferta mas allá de 90 días
        Test.setCreatedDate( opportunitiesToInsert.get(0).Id, Datetime.now().addDays(-91) );

        // Inserto oferta ZE
        List<Opportunity> opportunitiesZEToInsert = TestDataFactory.generateOpportunities(leadsList, 'ze', OFFER_STATUS_LEGIT_LEAD, Date.today() + 30, 1);
        // le asigno un codigo de negocio
        for (Opportunity opp: opportunitiesZEToInsert)
        {
            OPP.Scope__c = 'ZE';
            opp.BusinessCode__c = '123456';
        }
        insert opportunitiesZEToInsert;

        Test.setCreatedDate( opportunitiesZEToInsert.get(0).Id, Datetime.now().addDays(-151) );

        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        //Recuperar registros después de la ejecución
        List<Account> updatedLeadList = [SELECT Id FROM Account WHERE Id = : leadsList.get(0).Id];
        List<Opportunity> updatedOpportunityList = [SELECT Id FROM Opportunity WHERE AccountId = : leadsList.get(0).Id];
        List<Competitor__c> updatedCompetitorList = [SELECT Id FROM Competitor__c WHERE Account__c = : leadsList.get(0).Id];

        Assert.isTrue(updatedLeadList.size() > 0, 'NO Se deberían haber borrado todos los leads');
        Assert.isTrue(updatedOpportunityList.size() == 2, 'Debe quedar una oferta de ZRM y otra de ZE');
        Assert.isTrue(updatedCompetitorList.size() > 0, 'NO Se deberían haber borrado todas las competencias');
    }


    // compruebo que en el caso de leads con ofertas legit lead solo de ventas/zrm elimina todos los datos, lead, oferta y competencias
    @isTest
    private static void testBatchLeadConCaso()
    {
        List<Account> leadsList = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Lead'];
        // Inserto oferta Ventas/ZRM
        List<Opportunity> opportunitiesToInsert = TestDataFactory.generateOpportunities(leadsList, OFFER_SCOPE_VENTAS, OFFER_STATUS_LEGIT_LEAD, Date.today() + 30, 2);
        insert opportunitiesToInsert;

        // Envejezco las ofertas mas allá de 90 días
        for(Opportunity offer : opportunitiesToInsert)
        {
            Test.setCreatedDate( offer.Id, Datetime.now().addDays(-91) );
        }

        // Inserto un caso al lead
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(leadsList, 1);
        insert cases;


        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        //Recuperar registros después de la ejecución
        List<Account> updatedLeadList = [SELECT Id FROM Account WHERE Recordtype.DeveloperName = 'Lead'];
        List<Opportunity> updatedOpportunityList = [SELECT Id FROM Opportunity];
        List<Competitor__c> updatedCompetitorList = [SELECT Id FROM Competitor__c];

        Assert.isTrue(updatedLeadList.size() > 0, 'No se deberían haber borrado todos los leads');
        Assert.isTrue(updatedOpportunityList.size() == 0, 'Se deberían haber borrado todas las ofertas');
        Assert.isTrue(updatedCompetitorList.size() > 0, 'No se deberían haber borrado todas las competencias');
    }

    @isTest
    private static void testSchedulerOK()
    {
        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        String sch = '0 0 23 ? * * *';
        String jobID = System.schedule('BATCH DELETE OLD LEADS Test', sch, batch);

        Test.stopTest();

        List<CronTrigger> cronList = new List<CronTrigger>([SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = : jobID]);

        Assert.areEqual(1, cronList.size(), 'Debe haber un job programado');
    }
}