/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 19/10/2023
 * @last modified by  : jgallaga
**/
@isTest
public with sharing class GDPRDeleteAnonymizedRecordsBatchTest
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

        for(Integer i = 0; accs.size() < i; i++)
        {
            accs[i].FirstName = 'Test Account';
            accs[i].LastName = ' 00' + i;
            accs[i].RecordTypeId = CustomerRecordTypeId;
        }
        insert accs;

        List<Opportunity> opp = TestDataFactory.generateOpportunitiesForEachAccount(accs, 'ZE', 'Closed Won', System.today().addDays(10), 1);
        for(Opportunity nextO : opp)
        {
            nextO.Anonymized__c = true;
        }
        insert opp;

        List<Policy__c> poliza1 = TestDataFactory.generatePoliciesForEachAccount(accs, 1);
        for(Policy__c nextP : poliza1)
        {
            nextP.Anonymized__c = true;
        }
        insert poliza1;

        List<Policy__c> poliza2 = TestDataFactory.generatePoliciesForEachOpportunity(opp, 1);
        for(Policy__c nextP : poliza2)
        {
            nextP.Anonymized__c = true;
        }
        insert poliza2;

        Claim__c cl = new Claim__c(Name='000049', PolicyHolder__c=accs[0].Id, Policy__c = poliza1[0].Id);
        cl.Anonymized__c = true;
        insert cl;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accs, 3);
        cases[0].PolicyNum__c = poliza1[0].Name;
        cases[0].Anonymized__c = true;
        cases[1].CreatedOffer__c = opp[0].Name;
        cases[1].Anonymized__c = true;
        cases[2].ClaimId__c = cl.Id;
        cases[2].Anonymized__c = true;
        insert cases;

        Task tk = new Task(WhatId=cases[0].Id, Status='3');
        tk.Anonymized__c = true;
        insert tk;

        EmailMessage em = new EmailMessage(RelatedToId=cases[0].Id, ParentId=cases[0].Id, ActivityId=tk.Id);
        em.Anonymized__c = true;
        insert em;
        sacaCuentas('E');
        List<Account> accs2 = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_BCUSTOMER, 1);
        sacaCuentas('F');
        for(Integer i = 0; accs2.size() < i; i++)
        {
            accs2[i].Name = 'Test Account 00' + i;
            accs2[i].RecordTypeId = BCustomerRecordTypeId;
            accs2[i].Anonymized__c = true;
        }
        sacaCuentas('G');
        insert accs2;
        sacaCuentas('H');

        Contact cont = new Contact(LastName='Contact Test', AccountId=accs2[0].Id);
        cont.Anonymized__c = true;
        insert cont;

        Campaign camp = new Campaign(Name='Campaña test', LegalEntity__c='001');
        insert camp;

        CampaignMember cm = new CampaignMember(ContactId=cont.Id, CampaignId=camp.Id);
        cm.Anonymized__c = true;
        insert cm;
    }

    private static void sacaCuentas(String prefixDebug)
    {
        for(Account nextA : [SELECT Name, Anonymized__c FROM Account])
        {
            System.debug(prefixDebug + ' -> ' + nextA.Name + ' - ' + NextA.Anonymized__c);
        }
    }

    @isTest
    private static void test_deleteAnonimized()
    {

        List<Account> accs = [SELECT Id FROM Account WHERE Anonymized__c = false];
        for(Account testA : accs)
        {
            testA.Anonymized__c = true;
        }
        update accs;

        List<Account> deletedAccounts = [SELECT Id FROM Account WHERE Anonymized__c = true];
        Assert.isFalse(deletedAccounts.isEmpty(), 'No existen cuentas marcadas como anonima');

        List<Contact> deletedContacts = [SELECT Id FROM Contact WHERE Anonymized__c = true];
        Assert.isFalse(deletedContacts.isEmpty(), 'No existen contactos marcados como anonimo');

        List<CampaignMember> deletedCampaignMembers = [SELECT Id FROM CampaignMember WHERE Anonymized__c = true];
        Assert.isFalse(deletedCampaignMembers.isEmpty(), 'No existen miembros de campaña marcados como anonimo');

        List<Opportunity> deletedOpportunities = [SELECT Id FROM Opportunity WHERE Anonymized__c = true];
        Assert.isFalse(deletedOpportunities.isEmpty(), 'No existen las ofertas marcadas como anonima');

        List<Case> deletedCases = [SELECT id FROM Case WHERE Anonymized__c = true];
        Assert.isFalse(deletedCases.isEmpty(), 'No existen los casos marcados como anonimo');

        List<Policy__c> deletedPolicies = [SELECT Id FROM Policy__c WHERE Anonymized__c = true];
        Assert.isFalse(deletedPolicies.isEmpty(), 'No existen las polizas marcadas como anonimo');

        List<Claim__c> deletedClaims = [SELECT id FROM Claim__c WHERE Anonymized__c = true];
        Assert.isFalse(deletedClaims.isEmpty(), 'No existen las reclamaciones marcadas como anonima');

        List<EmailMessage> deletedEmailMessages = [SELECT Id FROM EMailMessage WHERE Anonymized__c = true];
        Assert.isFalse(deletedEmailMessages.isEmpty(), 'No existen los emails marcados como anonimo');

        List<Task> deletedTasks = [SELECT Id FROM Task WHERE Anonymized__c = true];
        Assert.isFalse(deletedTasks.isEmpty(), 'No existen las tareas marcadas como anonimo');

        Test.startTest();
        Database.executeBatch(new GDPRDeleteAnonymizedRecordsBatch());
        Test.stopTest();

        deletedTasks = [SELECT Id FROM Task];
        Assert.isTrue(deletedTasks.isEmpty(), 'No se han borrado las tareas marcadas como anonimo');

        deletedEmailMessages = [SELECT Id FROM EMailMessage];
        Assert.isTrue(deletedEmailMessages.isEmpty(), 'No se han borrado los emails marcados como anonimo');

        deletedClaims = [SELECT id FROM Claim__c];
        Assert.isTrue(deletedClaims.isEmpty(), 'No se han borrado las reclamaciones marcadas como anonima');

        deletedPolicies = [SELECT Id FROM Policy__c];
        Assert.isTrue(deletedPolicies.isEmpty(), 'No se han borrado las polizas marcadas como anonimo');

        deletedCases = [SELECT id FROM Case];
        Assert.isTrue(deletedCases.isEmpty(), 'No se han borrado los casos marcados como anonimo');

        deletedOpportunities = [SELECT Id FROM Opportunity];
        Assert.isTrue(deletedOpportunities.isEmpty(), 'No se han borrado las ofertas marcadas como anonima');

        deletedCampaignMembers = [SELECT Id FROM CampaignMember];
        Assert.isTrue(deletedCampaignMembers.isEmpty(), 'No se han borrado los miembros de campaña marcados como anonimo');

        deletedContacts = [SELECT Id FROM Contact];
        Assert.isTrue(deletedContacts.isEmpty(), 'No se han borrado los contactos marcados como anonimo');

        deletedAccounts = [SELECT Id FROM Account];
        Assert.isTrue(deletedAccounts.isEmpty(), 'No se han borrado las cuentas marcadas como anonima');
    }
}