@isTest(SeeAllData = false)
public with sharing class Test_PreferenceCentreProcessController
{
    @isTest
    static void doUpdate_testNull()
    {
        Contact c = new Contact();
        c.LastName = null;

        Test.startTest();
        PreferenceCentreProcessController.doUpdate(c);
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        System.assertEquals( 1, errorRecords.size() );
    }

    @isTest
    static void doInsert_testNull()
    {
        List<CampaignMember> members = new List<CampaignMember>();
        CampaignMember c = new CampaignMember();
        c.CampaignId = null;
        members.add(c);
        Test.startTest();
        PreferenceCentreProcessController.doInsert(members);
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        System.assertEquals( 1, errorRecords.size() );
    }

    @isTest
    static void doDelete_testNull()
    {
        List<CampaignMember> members = new List<CampaignMember>();
        CampaignMember c = new CampaignMember();
        c.CampaignId = null;
        members.add(c);

        Test.startTest();
        PreferenceCentreProcessController.doDelete(members);
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        System.assertEquals( 1, errorRecords.size() );
    }

    /**
     * Test the select to Scope
     */
    @isTest
    static void test_getScopeData()
    {
        

        String hashid = '123456';

        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 1);
        insert accounts;
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        scopes[0].HashedId__c = hashid;
        insert scopes;

        test.startTest();
        Scope__c scope = PreferenceCentreProcessController.getScopeData(hashid);
        test.stopTest();

        
        System.assertNotEquals(null, scope, 'The scope should not be null');
        
    }

    /**
     * Test the getContactData method
     * 
     * @author nts (agonzalezisasi)
     * @date 27/01/2021
     */
    @isTest
    static void test_getContactData()
    {
        Contact c = new Contact(
            LastName = 'test1'
        );
        insert c;

        List<Contact> contacts = [SELECT Id, HashedId__c FROM Contact WHERE Id = :c.Id];
        System.assertEquals(1, contacts.size(), 'There should be 1 contact');

        Contact contactToFind = null;
        Test.startTest();
        contactToFind = PreferenceCentreProcessController.getContactData(contacts[0].HashedId__c);
        Test.stopTest();

        System.assertNotEquals(null, contactToFind, 'The contact should be found by hashedId');
    }
}