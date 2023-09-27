/**
 * @description       :
 * @author            : overes
 * @group             :
 * @last modified on  : 27-09-2023
 * @last modified by  : overes
 **/
@isTest
private with sharing class AccountLeadOpportunityQueueJobTest
{

    private static String DEFAULT_ADMIN_ALIAS // Añadir el alias de cada user admin para cada entorno si fuera necesario
    {
        get
        {
            if( String.isBlank(DEFAULT_ADMIN_ALIAS) )
            {
                if(SystemUtil.getSandboxName() == 'qa')
                {
                    DEFAULT_ADMIN_ALIAS = 'ntsadmin';
                }
                else
                {
                    DEFAULT_ADMIN_ALIAS = 'adminkli';
                }
            }
            return DEFAULT_ADMIN_ALIAS;
        }
        set;
    }

    @TestSetup
    static void setup()
    {
        // Crear Custom Setting para default user
        Cross_Selling__c setting = new Cross_Selling__c();
        setting.Name = 'Test Setting';
        setting.ContactCenterUser__c = '-';
        setting.DefaultUser__c = DEFAULT_ADMIN_ALIAS;
        insert setting;


        // Lead_Offers__c setting_Lead_offer = new Lead_Offers__c();
        // setting_Lead_offer.BusinessCode__c = '1234567890';
        // setting_Lead_offer.VoiceQueue__c = 'Voz_ZurichEmpresas';
        // setting_Lead_offer.NotificationDaysBeforeDue__c = 5;
        // setting_Lead_offer.DaysToReassignOffer__c = 10;
        // setting_Lead_offer.BusinessHour__c = 'ZRM Ventas';
        // setting_Lead_offer.ContactCenterUser__c = 'Default';
        // insert setting_Lead_offer;

        // Crear Custom Setting para las colas y Business Hours
        Lead_Offers__c leadOffer = TestDataFactory.generateLeadOfferCS();
        insert leadOffer;
    }

    @isTest
    static void test_execute()
    {
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        Date closeDate = Date.newInstance(2023, 10, 10);
        List<Opportunity> opps = TestDataFactory.generateOpportunities(leadAccounts, 'ZRM', 'Quoted', closeDate, 1);
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opps, 1);

        Test.startTest();
        Id jobId = System.enqueueJob( new AccountLeadOpportunityQueueJob(leadAccounts.get(0), opps.get(0), policies.get(0),'44600', '+346871425') );
        Test.stopTest();

        System.assert (jobId != null, 'No se ha encolado el trabajo correctamente');
    }



    @isTest
    static void test_execute_KO()
    {
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        Date closeDate = Date.newInstance(2023, 10, 10);
        List<Opportunity> opps = TestDataFactory.generateOpportunities(leadAccounts, 'ZRM', 'Quoted', closeDate, 1);
        opps[0].InfoQuoteNumber__c = '34523523';
        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opps, 1);

        Test.startTest();
        Id jobId = System.enqueueJob( new AccountLeadOpportunityQueueJob(leadAccounts.get(0), opps.get(0), policies.get(0),'44600', '+346871425') );
        Test.stopTest();

        System.assert (jobId != null, 'No se ha encolado el trabajo correctamente');
    }

    @isTest
    static void test_manageOfferRecord()
    {
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        Date closeDate = Date.newInstance(2023, 10, 10);
        List<Opportunity> opps = TestDataFactory.generateOpportunities(leadAccounts, 'ZRM', 'Quoted', closeDate, 1);

        Test.startTest();
        try
        {
            AccountLeadOpportunityQueueJob.manageOfferRecord(opps.get(0), opps.get(0), opps);
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción');
        }
        Test.stopTest();
    }

    @isTest
    static void test_manageConstrainsKey()
    {
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        Date closeDate = Date.newInstance(2023, 10, 10);
        List<Opportunity> opps = TestDataFactory.generateOpportunities(leadAccounts, 'ZRM', 'Quoted', closeDate, 1);
        Map<String, Account> assign = AccountLeadUtil.leadAssignment(leadAccounts.get(0), opps.get(0).IntermediaryCode__c, opps.get(0).IntermediaryCode__c, null, '44600');
        assign.put( 'CONTACT_CENTER', leadAccounts.get(0) );

        Test.startTest();
        try
        {
            AccountLeadOpportunityQueueJob.manageConstrainsKey(assign,leadAccounts.get(0), opps.get(0), '+346871425');
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción');
        }
        Test.stopTest();
    }

    @isTest
    static void test_manageOfferRecord_infoQuoteNumber_null()
    {
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        Date closeDate = Date.newInstance(2023, 10, 10);
        List<Opportunity> opps = TestDataFactory.generateOpportunities(leadAccounts, 'ZRM', 'Quoted', closeDate, 1);
        opps[0].SessionId__c = '33333333333';
        opps[0].InfoQuoteNumber__c = '34234444444';
        insert opps;

        List<Opportunity> opps2 = TestDataFactory.generateOpportunities(leadAccounts, 'ZRM', 'App Submitted', closeDate, 1);
        opps2[0].InfoQuoteNumber__c = null;
        opps2[0].SessionId__c = '988767656875485';
        insert opps2;

        Test.startTest();
        try
        {
            AccountLeadOpportunityQueueJob.manageOfferRecord(opps.get(0), opps2.get(0), opps);
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción');
        }
        Test.stopTest();
    }

    @isTest
    static void test_manageCallBack()
    {
        List<Account> leadAccounts = TestDataFactory.generateAccounts(null, 'Lead', 1);
        Lead_Offers__c leadOffersCS = Lead_Offers__c.getInstance();
        Date closeDate = Date.newInstance(2023, 10, 10);
        List<Opportunity> opps = TestDataFactory.generateOpportunities(leadAccounts, 'ZRM', 'Quoted', closeDate, 1);

        Test.startTest();
        try
        {
            AccountLeadOpportunityQueueJob.manageCallMeBack(leadAccounts.get(0), opps.get(0), leadOffersCS, '+346871425');
        }
        catch (Exception ex)
        {
            Assert.fail('No debería haberse lanzado ninguna excepción');
        }
        Test.stopTest();
    }



}