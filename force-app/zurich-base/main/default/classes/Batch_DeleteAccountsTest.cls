/*
 * Test for the Batch Batch_DeleteAccounts
 *
 * @author mfernandezcarrera
 * @date 30/06/203
 */
@isTest
 public class Batch_DeleteAccountsTest
{
    private static final string ACCOUNT_LEAD = 'Lead';
    private static final string ACCOUNT_CUSTOMER = 'Customer';
    private static final string LEGAL_ENTITY = '001';
    private static final string OFFER_STAGE_NEW = 'New';
    private static final string SCOPE_GENERAL = 'ZE';
    static final String QUERY_Account = 'SELECT Id FROM Account WHERE Id NOT IN (select AccountId from Opportunity) AND RecordType.Name=\'Lead\'';
    private static final Id LeadRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().
                get(ACCOUNT_LEAD).getRecordTypeId();
    private static final Id CustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().
                get(ACCOUNT_CUSTOMER).getRecordTypeId();


    @TestSetup
    static void makeData(){
        
        // create Lead accounts
        List<Account> leadAccounts = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_LEAD, 2);
        for(Integer i=0;leadAccounts.size()<i;i++){
            leadAccounts[i].firstName = 'test';
            leadAccounts[i].LastName = 'Lead ' + i;
            leadAccounts[i].RecordTypeId = LeadRecordTypeId;
            leadAccounts[i].Salutation = 'Mr.';
        }
        insert leadAccounts;
        
        // create customer accounts 
        List<Account> clientAccountsOther = TestDataFactory.generateAccounts(LEGAL_ENTITY, ACCOUNT_CUSTOMER, 2);
        for(Integer i=0;clientAccountsOther.size()<i;i++){
            clientAccountsOther[i].firstName = 'test';
            clientAccountsOther[i].LastName = 'Customer ' + i;
            clientAccountsOther[i].RecordTypeId = CustomerRecordTypeId;
            clientAccountsOther[i].Salutation = 'Mr.';
        }
        insert clientAccountsOther;

        leadAccounts.addAll(clientAccountsOther);
        
        // create new offers, for leads[0]
        List<Opportunity> newOffers = TestDataFactory.generateOpportunitiesForEachAccount(
            leadAccounts, 'ZE', OFFER_STAGE_NEW,System.today().addDays(10), 1);
        insert newOffers;
    }

    @isTest
    static void test_NoDeleteAccounts()
    {
        test.startTest();
        Batch_DeleteAccounts batchDeleteAcc=new Batch_DeleteAccounts();
        Database.executeBatch(batchDeleteAcc);
        test.stopTest();
        List<Account> accountListNew= [SELECT id FROM ACCOUNT];
        System.assertEquals(4, accountListNew.size());
    }

    @isTest
    static void test_DeleteLeadWithoutOffer()
    {
        Account acc= new Account();
        acc.FirstName='Prueba';
        acc.LastName='TestDeleteLead';
        acc.RecordTypeId=LeadRecordTypeId;
        insert acc;

        test.startTest();
        Batch_DeleteAccounts batchDeleteAcc=new Batch_DeleteAccounts();
        Database.executeBatch(batchDeleteAcc);
        test.stopTest();
        List<Account> accountListNew= [SELECT id FROM ACCOUNT];
        System.assertEquals(4, accountListNew.size());
    }

    @isTest
    static void test_NoDeleteCustomerWithoutOffer()
    {
        Account acc= new Account();
        acc.FirstName='Prueba';
        acc.LastName='TestNoDeleteCustomer';
        acc.RecordTypeId=CustomerRecordTypeId;
        insert acc;

        test.startTest();
        Batch_DeleteAccounts batchDeleteAcc=new Batch_DeleteAccounts();
        Database.executeBatch(batchDeleteAcc);
        test.stopTest();
        List<Account> accountListNew= [SELECT id FROM ACCOUNT];
        System.assertEquals(5, accountListNew.size());
    }


    @isTest
    static void test_NoDeleteAccounts2()
    {
        test.startTest();

        Batch_DeleteAccounts batchDeleteAcc=new Batch_DeleteAccounts(QUERY_Account);
        Database.executeBatch(batchDeleteAcc);
        test.stopTest();
        List<Account> accountListNew= [SELECT id FROM ACCOUNT];
        System.assertEquals(4, accountListNew.size());
    }

    @isTest
    static void test_DeleteLeadWithoutOffer2()
    {
        Account acc= new Account();
        acc.FirstName='Prueba';
        acc.LastName='TestDeleteLead';
        acc.RecordTypeId=LeadRecordTypeId;
        insert acc;

        test.startTest();
        
        Batch_DeleteAccounts batchDeleteAcc=new Batch_DeleteAccounts(QUERY_Account);
        Database.executeBatch(batchDeleteAcc);
        test.stopTest();
        List<Account> accountListNew= [SELECT id FROM ACCOUNT];
        System.assertEquals(4, accountListNew.size());
    }

    @isTest
    static void test_NoDeleteCustomerWithoutOffer2()
    {
        Account acc= new Account();
        acc.FirstName='Prueba';
        acc.LastName='TestNoDeleteCustomer';
        acc.RecordTypeId=CustomerRecordTypeId;
        insert acc;

        test.startTest();
        Batch_DeleteAccounts batchDeleteAcc=new Batch_DeleteAccounts(QUERY_Account);
        Database.executeBatch(batchDeleteAcc);
        test.stopTest();
        List<Account> accountListNew= [SELECT id FROM ACCOUNT];
        System.assertEquals(5, accountListNew.size());
    }
}