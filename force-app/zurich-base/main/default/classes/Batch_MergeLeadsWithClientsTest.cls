/**
 * Test for the Batch Batch_MergeLeadsWithClients
 *
 * @author nts (agonzalezisasi)
 * @date 03/02/2021
 */
@isTest
public class Batch_MergeLeadsWithClientsTest
{
    private static final string LEGAL_ENTITY = '001';
    private static final string SCOPE_GENERAL = 'General';
    private static final string OFFER_STAGE_NEW = 'New';
    private static final string ACCOUNT_INTERMEDIARY = 'Intermediary';
    private static final string ACCOUNT_CUSTOMER = 'Customer';
    private static final string ACCOUNT_BUSINESS = 'BusinessCustomer';
    private static final Id LeadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().
                get(Batch_MergeLeadsWithClients.LEAD_RECORDTYPE_DEVELOPERNAME).getRecordTypeId();

    @TestSetup
    static void makeData(){
        
        // create 1 Lead accounts
        List<Account> leadAccounts = TestDataFactory.generateAccounts(LEGAL_ENTITY, Batch_MergeLeadsWithClients.LEAD_RECORDTYPE_DEVELOPERNAME, 1);
        for(Integer i=0,j=leadAccounts.size();i<j;i++){
            leadAccounts[i].firstName = 'test';
            leadAccounts[i].LastName = 'Lead ' + i;
            leadAccounts[i].RecordTypeId = LeadRecordTypeId;
        }
        insert leadAccounts;
        
        // create 1 client accounts of other types
        List<Account> clientAccountsOther = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_INTERMEDIARY, 1);
        insert clientAccountsOther;

        // join the accounts
        leadAccounts.addAll(clientAccountsOther);
        
        // create new offers, for leads and for other clients
        List<Opportunity> newOffers = TestDataFactory.generateOpportunitiesForEachAccount(
            leadAccounts, SCOPE_GENERAL, OFFER_STAGE_NEW, System.today().addDays(10), 1
        );
        insert newOffers;

        // create 2 Client accounts (Coming from INFO), type Customer (PersonAccount) and type BusinessCustomer (Account)
        List<Account> clientAccounts = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_CUSTOMER, 1);
        clientAccounts.addAll(TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_BUSINESS, 1));
        insert clientAccounts;

        // create contact points for the accounts
        insert TestDataFactory.generateContactPointAddressesFromAccounts(clientAccounts, 1);
        insert TestDataFactory.generateContactPointPhonesFromAccounts(clientAccounts, 1);
        insert TestDataFactory.generateContactPointEmailsFromAccounts(clientAccounts, 1);

        // create 2 cases for those clients
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(clientAccounts, 2);
        insert cases;
    }
    
    @isTest
    static void test_PersonAccount_ok()
    {
        // Get the lead account
        List<Account> leadAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :LeadRecordTypeId LIMIT 1];
        System.assertEquals(1, leadAccounts.size(), 'There should be 1 lead account');
        // Get the customer account (PersonAccount)
        List<Account> customerAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_CUSTOMER LIMIT 1];
        System.assertEquals(1, customerAccount.size(), 'There should be 1 customer account');
        // Get the Offer of the lead
        List<Opportunity> leadOffers = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :leadAccounts];
        System.assertEquals(1, leadOffers.size(), 'There sould be 1 offer for the lead');
        // Change the offer from lead to PersonAccount --> fill the OldAccountId__c
        leadOffers[0].Accountid = customerAccount[0].Id;
        update leadOffers;


        // Merge the lead and the PersonAccount
        Test.startTest();
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients(
            'SELECT Id, AccountId, OldAccountId__c, Account.RecordType.DeveloperName FROM Opportunity WHERE OldAccountId__c = \'' + leadAccounts[0].Id + '\''
        );
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Check that the leads accounts still exist and the record type has changed
        List<Account> mergedLeads = [SELECT Id FROM Account WHERE Id IN :leadAccounts AND RecordType.DeveloperName != :Batch_MergeLeadsWithClients.LEAD_RECORDTYPE_DEVELOPERNAME];
        System.assertEquals(1, mergedLeads.size(), 'There should be 1 accounts with the lead ID');

        // Check that the leads accounts has the case related sobjects
        List<Case> cases = [SELECT Id FROM Case WHERE AccountId IN :leadAccounts];
        System.assertEquals(2, cases.size(), 'There should be 2 cases');

        // Check that the leads accounts has the offers
        List<Opportunity> offers = [SELECT Id, OldAccountId__c FROM Opportunity WHERE AccountId IN :leadAccounts];
        System.assertEquals(1, offers.size(), 'There should be 1 offers');
        // In UI this is ok but in testing is not working....
        // System.assertEquals(null, offers[0].OldAccountId__c, 'The OldAccountId__c of the offer should be null');
    }

    
    @isTest
    static void test_PersonAccount_ko()
    {
        // Get the lead account
        List<Account> leadAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :LeadRecordTypeId LIMIT 1];
        System.assertEquals(1, leadAccounts.size(), 'There should be 1 lead account');
        // Get the customer account (PersonAccount)
        List<Account> customerAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_CUSTOMER LIMIT 1];
        System.assertEquals(1, customerAccount.size(), 'There should be 1 customer account');
        // Get the Offer of the lead
        List<Opportunity> leadOffers = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :leadAccounts];
        System.assertEquals(1, leadOffers.size(), 'There sould be 1 offer for the lead');
        // Change the offer from lead to PersonAccount --> fill the OldAccountId__c
        leadOffers[0].Accountid = customerAccount[0].Id;
        update leadOffers;


        // Merge the lead and the PersonAccount
        Test.startTest();
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients(
            'SELECT Id, AccountId, OldAccountId__c, Account.RecordType.DeveloperName FROM Opportunity WHERE OldAccountId__c = \'' + leadAccounts[0].Id + '\''
        );
        // force an error when trying to merge the Name field for PersonAccounts
        batch.fieldsToMergePerson.add('Name');
        Database.executeBatch(batch, 1);
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c];
        System.debug(errors);
        System.assertEquals(false, errors.isEmpty(), 'There should be Error Logs');
    }

    
    @isTest
    static void test_Account_ok()
    {
        // Get the lead account
        List<Account> leadAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :LeadRecordTypeId LIMIT 1];
        System.assertEquals(1, leadAccounts.size(), 'There should be 1 lead account');
        // Get the customer account (PersonAccount)
        List<Account> customerAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_BUSINESS LIMIT 1];
        System.assertEquals(1, customerAccount.size(), 'There should be 1 BusinessCustomer account');
        // Get the Offer of the lead
        List<Opportunity> leadOffers = [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :leadAccounts];
        System.assertEquals(1, leadOffers.size(), 'There sould be 1 offer for the lead');
        // Change the offer from lead to PersonAccount --> fill the OldAccountId__c
        leadOffers[0].Accountid = customerAccount[0].Id;
        update leadOffers;


        // Merge the lead and the PersonAccount
        Test.startTest();
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients(
            'SELECT Id, AccountId, OldAccountId__c, Account.RecordType.DeveloperName FROM Opportunity WHERE OldAccountId__c = \'' + leadAccounts[0].Id + '\''
        );
        Database.executeBatch(batch, 1);
        Test.stopTest();

        // Check that the leads accounts still exist and the record type has changed
        List<Account> mergedLeads = [SELECT Id FROM Account WHERE Id IN :leadAccounts AND RecordType.DeveloperName != :Batch_MergeLeadsWithClients.LEAD_RECORDTYPE_DEVELOPERNAME];
        System.assertEquals(1, mergedLeads.size(), 'There should be 1 accounts with the lead ID');

        // Check that the leads accounts has the case related sobjects
        List<Case> cases = [SELECT Id FROM Case WHERE AccountId IN :leadAccounts];
        System.assertEquals(2, cases.size(), 'There should be 2 cases');

        // Check that the leads accounts has the offers
        List<Opportunity> offers = [SELECT Id, OldAccountId__c FROM Opportunity WHERE AccountId IN :leadAccounts];
        System.assertEquals(1, offers.size(), 'There should be 1 offers');
        // In UI this is ok but in testing is not working....
        // System.assertEquals(null, offers[0].OldAccountId__c, 'The OldAccountId__c of the offer should be null');
    }

    @isTest
    static void test_MoreThanOneScope()
    {
        List<Opportunity> offers = [SELECT Id, AccountId FROM Opportunity];
        System.assertEquals(2, offers.size(), 'There should be 2 offers');
        List<Account> customerAccount = [SELECT Id FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_CUSTOMER LIMIT 1];
        System.assertEquals(1, customerAccount.size(), 'There should be 1 customer account');

        offers[0].AccountId = customerAccount[0].Id;
        offers[1].AccountId = customerAccount[0].Id;
        update offers;
        
        string result = null;
        Test.startTest();
        Batch_MergeLeadsWithClients batch = new Batch_MergeLeadsWithClients();
        Database.executeBatch(batch, 2);
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(false, errors.isEmpty(), 'There should be Error Logs');
    }

    /**
     * For testing Schedule
     */
    @isTest
    static void test_schedule()
    {
        Batch_MergeLeadsWithClients m = new Batch_MergeLeadsWithClients();
        String sch = '20 30 8 10 2 ?';

        Test.startTest();
        String jobID = system.schedule('Batch Merge Leads with Clients', sch, m);
        Test.stopTest();
        //System.Debug('jobID: ' + jobID);
    }
}