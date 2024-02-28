/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 18/10/2023
 * @last modified by  : jgallaga
**/
@istest
public with sharing class GDPRPropagateBlockedFieldBatchTest
{

    private static final String ACCOUNT_CUSTOMER = 'Customer';
    private static final String ACCOUNT_BCUSTOMER = 'BusinessCustomer';
    private static final String LEGAL_ENTITY = '001';
    private static final Id CustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().
                                                get(ACCOUNT_CUSTOMER).getRecordTypeId();
    private static final Id BCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().
                                                get(ACCOUNT_BCUSTOMER).getRecordTypeId();


    @TestSetup
    private static void makeData()
    {
        List<Account> accs = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_CUSTOMER, 1);

        for(Integer i = 0; accs.size() < i; i++){
            accs[i].FirstName = 'Test Account';
            accs[i].LastName = '-001';
            accs[i].RecordTypeId = CustomerRecordTypeId;
        }
        insert accs;

        List<Opportunity> opp = TestDataFactory.generateOpportunitiesForEachAccount(accs, 'ZE', 'Closed Won', System.today().addDays(10), 1);
        insert opp;

        List<Policy__c> poliza1 = TestDataFactory.generatePoliciesForEachAccount(accs, 1);
        insert poliza1;

        List<Policy__c> poliza2 = TestDataFactory.generatePoliciesForEachOpportunity(opp, 1);
        insert poliza2;

        Claim__c cl = new Claim__c(Name='000049', PolicyHolder__c=accs[0].Id);
        insert cl;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accs, 3);
        cases[0].PolicyNum__c = poliza1[0].Name;
        cases[1].CreatedOffer__c = opp[0].Name;
        cases[2].ClaimId__c = cl.Id;
        insert cases;

        Task tk = new Task(WhatId=cases[0].Id, Status='3');
        insert tk;

        EmailMessage em = new EmailMessage(RelatedToId=cases[0].Id, ParentId=cases[0].Id, ActivityId=tk.Id);
        insert em;

        List<Account> accs2 = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_BCUSTOMER, 1);
        for(Integer i = 0; accs2.size() < i; i++){
            accs2[i].FirstName = 'Test Account';
            accs2[i].LastName = '-001';
            accs2[i].RecordTypeId = BCustomerRecordTypeId;
        }
        insert accs2;

        Contact cont = new Contact(LastName='Contact Test', AccountId=accs2[0].Id);
        insert cont;

        Campaign camp = new Campaign(Name='Campaña test', LegalEntity__c='001');
        insert camp;

        CampaignMember cm = new CampaignMember(ContactId=cont.Id, CampaignId=camp.Id);
        insert cm;
    }

    /*************************************************
     * PROPAGATE BLOCKED
     ************************************************/

    @isTest
    private static void test_blockFieldPropagation_ContactBlocked()
    {
        List<Account> allTestAccounts = [SELECT Id FROM Account];

        for(Account currentTestAccount : allTestACcounts)
        {
            currentTestAccount.blocked__c = true;
        }

        update allTestAccounts;

        Test.startTest();
        Database.executeBatch(new GDPRPropagateBlockedFieldBatch(false));
        Test.stopTest();

        for(Account testAccount : [SELECT Blocked__c FROM Account])
        {
            Assert.isTrue(testAccount.Blocked__c,'No se ha asignado el campo blocked a true en las cuentas');
        }

        for(Contact testContact : [SELECT Blocked__c FROM Contact])
        {
            Assert.isTrue(testContact.Blocked__c,'No se ha asignado el campo blocked a true en los contactos');
        }
    }

    @isTest
    private static void test_blockFieldPropagation_CampaignMemberBlocked()
    {
        List<Account> allTestAccounts = [SELECT Id FROM Account];

        for(Account currentTestAccount : allTestACcounts)
        {
            currentTestAccount.blocked__c = true;
        }

        update allTestAccounts;

        List<Contact> allTestContacts = [SELECT Id FROM Contact];

        for(Contact currentTestContact : allTestContacts)
        {
            currentTestContact.Blocked__c = true;
        }

        update allTestContacts;

        Test.startTest();
        Database.executeBatch(new GDPRPropagateBlockedFieldBatch('2', false));
        Test.stopTest();

        for(CampaignMember testCampaignMember : [SELECT Blocked__c FROM CampaignMember])
        {
            Assert.isTrue(testCampaignMember.Blocked__c, 'No se ha asignado el campo blocked a true en los miembros de campaña');
        }
    }

    @isTest
    private static void test_blockFieldPropagation_OpportunityBlocked()
    {
        List<Account> allTestAccounts = [SELECT Id FROM Account];

        for(Account currentTestAccount : allTestACcounts)
        {
            currentTestAccount.blocked__c = true;
        }

        update allTestAccounts;

        Test.startTest();
        Database.executeBatch(new GDPRPropagateBlockedFieldBatch('3', false));
        Test.stopTest();

        for(Opportunity testOpportunity : [SELECT Blocked__c FROM Opportunity])
        {
            Assert.isTrue(testOpportunity.Blocked__c, 'No se ha asignado el campo blocked a true en las ofertas');
        }
    }

    /**
     *
     */
    @isTest
    private static void test_blockFieldPropagation_CaseAndEmailMessageBlocked()
    {
        List<Account> allTestAccounts = [SELECT Id FROM Account];

        for(Account currentTestAccount : allTestACcounts)
        {
            currentTestAccount.blocked__c = true;
        }

        update allTestAccounts;

        Test.startTest();
        Database.executeBatch(new GDPRPropagateBlockedFieldBatch('4', false));
        Test.stopTest();

        for(Case testCase : [SELECT Blocked__c FROM Case])
        {
            Assert.isTrue(testCase.Blocked__c, 'No se ha asignado el campo blocked a true en los casos');
        }

        for(EmailMessage testEmailmessage : [SELECT Blocked__c FROM EmailMessage])
        {
            Assert.isTrue(testEmailmessage.Blocked__c, 'No se ha asignado el campo blocked a true en los Email Message');
        }
    }

    /*************************************************
     * PROPAGATE ANONYMOUS
     ************************************************/

     @isTest
     private static void test_anonymousFieldPropagation_Contact()
     {
         List<Account> allTestAccounts = [SELECT Id FROM Account];

         for(Account currentTestAccount : allTestACcounts)
         {
             currentTestAccount.Anonymized__c = true;
         }

         update allTestAccounts;

         Test.startTest();
         Database.executeBatch(new GDPRPropagateBlockedFieldBatch(true));
         Test.stopTest();

         for(Account testAccount : [SELECT Anonymized__c FROM Account])
         {
             Assert.isTrue(testAccount.Anonymized__c,'No se ha asignado el campo anonymized a true en las cuentas');
         }

         for(Contact testContact : [SELECT Anonymized__c FROM Contact])
         {
             Assert.isTrue(testContact.Anonymized__c,'No se ha asignado el campo anonymized a true en los contactos');
         }
     }

     @isTest
     private static void test_anonymousFieldPropagation_CampaignMember()
     {
         List<Account> allTestAccounts = [SELECT Id FROM Account];

         for(Account currentTestAccount : allTestACcounts)
         {
             currentTestAccount.Anonymized__c = true;
         }

         update allTestAccounts;

         List<Contact> allTestContacts = [SELECT Id FROM Contact];

         for(Contact currentTestContact : allTestContacts)
         {
             currentTestContact.Anonymized__c = true;
         }

         update allTestContacts;

         Test.startTest();
         Database.executeBatch(new GDPRPropagateBlockedFieldBatch('3', true));
         Test.stopTest();

         for(CampaignMember testCampaignMember : [SELECT Anonymized__c FROM CampaignMember])
         {
             Assert.isTrue(testCampaignMember.Anonymized__c, 'No se ha asignado el campo anonymized a true en los miembros de campaña');
         }
     }

     @isTest
     private static void test_anonymousFieldPropagation_Opportunity()
     {
         List<Account> allTestAccounts = [SELECT Id FROM Account];

         for(Account currentTestAccount : allTestACcounts)
         {
             currentTestAccount.Anonymized__c = true;
         }

         update allTestAccounts;

         Test.startTest();
         Database.executeBatch(new GDPRPropagateBlockedFieldBatch('4', true));
         Test.stopTest();

         for(Opportunity testOpportunity : [SELECT Anonymized__c FROM Opportunity])
         {
             Assert.isTrue(testOpportunity.Anonymized__c, 'No se ha asignado el campo anonymized a true en las ofertas');
         }
     }

     /**
      *
      */
     @isTest
     private static void test_anonymousFieldPropagation_CaseAndEmailMessage()
     {
         List<Account> allTestAccounts = [SELECT Id FROM Account];

         for(Account currentTestAccount : allTestACcounts)
         {
             currentTestAccount.Anonymized__c = true;
         }

         update allTestAccounts;

         Test.startTest();
         Database.executeBatch(new GDPRPropagateBlockedFieldBatch('5', true));
         Test.stopTest();

         List<Case> testCases = [SELECT Anonymized__c FROM Case];

         for(Case testCase : testCases)
         {
             Assert.isTrue(testCase.Anonymized__c, 'No se ha asignado el campo anonymized a true en los casos');
         }

         for(EmailMessage testEmailmessage : [SELECT Anonymized__c FROM EmailMessage where parentId IN :testCases])
         {
             Assert.isTrue(testEmailmessage.Anonymized__c, 'No se ha asignado el campo anonymized a true en los Email Message');
         }

         for(EmailMessage allMail : [SELECT HTmlBody FROM EmailMessage])
         {
            System.debug(allMail.HTMLBody);
         }
     }
}