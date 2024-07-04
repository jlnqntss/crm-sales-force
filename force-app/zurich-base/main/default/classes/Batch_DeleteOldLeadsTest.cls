/**
 * @description       : 
 * @author            : rserrano
 * @group             : 
 * @last modified on  : 25/04/2024
 * @last modified by  : rserrano
**/
@IsTest
public with sharing class Batch_DeleteOldLeadsTest {
    @TestSetup
    static void makeData()
    {
        RecordType leadRt = [SELECT Id FROM Recordtype WHERE Name = 'Lead' AND SobjectType = 'Account' LIMIT 1];
        Scope_Setting__mdt ventasScopeMdt = Scope_Setting__mdt.getInstance('Zurich_Ventas');
        Scope_Setting__mdt zeScopeMdt = Scope_Setting__mdt.getInstance('ZE');
        Map<String, String> configValues = GlobalConfigUtil.getGlobalConfigurationValues();
        Id rtOppLife = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(configValues.get('Opportunity_RecordTypeDevName_Life')).getRecordTypeId();

        
        //Leads a borrar
        List<Account> leadsToDeleteLst = new List<Account>();
        List<Opportunity> offersToDeleteLst = new List<Opportunity>();

        for(Integer i = 0; i < 10; i++)
        {
            leadsToDeleteLst.add(new Account(LastName = 'LeadToDelete' + i, RecordTypeId = leadRt.Id));
        }
        insert leadsToDeleteLst;

        for(Account acc : leadsToDeleteLst)
        {
            offersToDeleteLst.add(new Opportunity(Name = 'OF' + acc.LastName, AccountId = acc.Id, StageName = 'Legit Lead', BusinessCode__c = ventasScopeMdt.BusinessCode__c, CloseDate = Date.today().addDays(7)));
        }
        insert offersToDeleteLst;

        //Leads que no borra el proceso
        // Leads con varias ofertas
        List<Account> leadsWithMultipleOffersLst = new List<Account>();
        List<Opportunity> offerLst = new List<Opportunity>();

        for(Integer i = 0; i < 10; i++)
        {
            leadsWithMultipleOffersLst.add(new Account(LastName = 'LeadMultipleOffers' + i, RecordTypeId = leadRt.Id));
        }
        insert leadsWithMultipleOffersLst;

        for(Account acc : leadsWithMultipleOffersLst)
        {
            for(Integer i = 0; i < 2; i++)
            {
                offerLst.add(new Opportunity(Name = 'OF' + acc.LastName, AccountId = acc.Id, StageName = 'Legit Lead', BusinessCode__c = ventasScopeMdt.BusinessCode__c, CloseDate = Date.today().addDays(7)));
            }
        }
        insert offerLst;

        // Leads con una oferta de otro business code
        List<Account> leadsFromOtherBusinessLst = new List<Account>();
        List<Opportunity> offersFromOtherBusinessLst = new List<Opportunity>();

        for(Integer i = 0; i < 10; i++)
        {
            leadsFromOtherBusinessLst.add(new Account(LastName = 'LeadOtherBusiness' + i, RecordTypeId = leadRt.Id));
        }
        insert leadsFromOtherBusinessLst;
        
        for(Account acc : leadsFromOtherBusinessLst)
        {
            offersFromOtherBusinessLst.add(new Opportunity(Name = 'OF' + acc.LastName, AccountId = acc.Id, StageName = 'Legit Lead', BusinessCode__c = zeScopeMdt.BusinessCode__c, CloseDate = Date.today().addDays(7)));
        }
        insert offersFromOtherBusinessLst;

        // Leads con ofertas iniciadas
        List<Account> leadsNonLegitLst = new List<Account>();
        List<Opportunity> offersNonLegitLst = new List<Opportunity>();

        for(Integer i = 0; i < 10; i++)
        {
            leadsNonLegitLst.add(new Account(LastName = 'LeadNonLegit' + i, RecordTypeId = leadRt.Id));
        }
        insert leadsNonLegitLst;

        for(Account acc : leadsNonLegitLst)
        {
            offersNonLegitLst.add(new Opportunity(Name = 'OF' + acc.LastName, AccountId = acc.Id, StageName = 'Quoted', BusinessCode__c = ventasScopeMdt.BusinessCode__c, CloseDate = Date.today().addDays(7)));
        }
        
        insert offersNonLegitLst;

        //Leads con ofertas de tipo vida que no se tienen que eliminar 
        List<Account> leadsWithOfferLife = new List<Account>();
        List<Opportunity> lifeOffers = new List<Opportunity>();

        for(Integer i = 0; i < 10; i++)
        {
            leadsWithOfferLife.add(new Account(LastName = 'LeadToNotDelete' + i, RecordTypeId = leadRt.Id));
        }
        insert leadsWithOfferLife;

        for(Account acc : leadsWithOfferLife)
        {
            lifeOffers.add(new Opportunity(Name = 'OF' + acc.LastName, AccountId = acc.Id, StageName = 'Legit Lead', BusinessCode__c = ventasScopeMdt.BusinessCode__c, recordTypeId = rtOppLife ,CloseDate = Date.today().addDays(7)));
        }
        insert lifeOffers;

        //Setear la fecha de creación de todos los leads
        for(Account acc : [SELECT Id FROM Account])
        {
            Test.setCreatedDate(acc.Id, Datetime.now().addDays(-91));
        }
    }
    @isTest
    static void testBatchOK()
    {
        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        Database.executeBatch(batch, 200);

        Test.stopTest();
        
        //Recuperar leads no borrados después del proceso
        List<Account> updatedLeadLst = [SELECT Id FROM Account];

        Assert.areEqual(40, updatedLeadLst.size(), 'Debería haber 40 leads sin borrar');
    }

    @isTest
    static void testSchedulerOK()
    {
        Test.startTest();

        Batch_DeleteOldLeads batch = new Batch_DeleteOldLeads();
        String sch = '0 0 23 ? * * *';
        String jobID = System.schedule('BATCH DELETE OLD LEADS', sch, batch);

        Test.stopTest();
        
        List<CronTrigger> cronList = new List<CronTrigger>([SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobID]);

        Assert.areEqual(1, cronList.size(), 'Debe haber un job programado');
    }
}