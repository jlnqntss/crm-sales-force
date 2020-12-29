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
        System.Debug('- - - - - Test_PreferenceCentreProcessController.test_getScopeData - - - - -');

        String hashid = '123456';

        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 1);
        insert accounts;
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        scopes[0].HashedId__c = hashid;
        insert scopes;

        test.startTest();
        Scope__c scope = PreferenceCentreProcessController.getScopeData(hashid);
        test.stopTest();

        System.Debug('---------------- Results');
        System.assertNotEquals(null, scope, 'The scope should not be null');
        
    }
}