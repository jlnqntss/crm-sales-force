@isTest
private with sharing class CampaignMembersSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 10);
        insert campaigns;

        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(accounts, campaigns);
        insert campaignMembers;
    }

    @isTest
    static void test_selectByCampaignAndContact_matchedRecords()
    {
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        Id campaignToSearch = campaigns.get(0).Id;

        List<CampaignMember> currentCampaignMembers = [SELECT ContactId FROM CampaignMember];
        System.assertEquals(false, currentCampaignMembers.isEmpty(), 'List should NOT be empty');

        Set<Id> contactsToSearch = new Set<Id>();
        for(CampaignMember member: currentCampaignMembers)
        {
            contactsToSearch.add(member.ContactId);
        }

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector(
            new Set<String> {'Id', 'ContactId', 'CampaignId'}
            ).selectByCampaignAndContact(campaignToSearch, contactsToSearch);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(CampaignMember matched: matchedRecords)
        {
            System.assertEquals(true, matched.CampaignId == campaignToSearch, 'CampaignId should be the same');
            System.assertEquals(true, contactsToSearch.contains(matched.ContactId), 'Set should contain ContactId');
        }
    }

    @isTest
    static void test_selectByCampaignAndContact_emptySet_matchedRecords()
    {
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        Id campaignToSearch = campaigns.get(0).Id;

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByCampaignAndContact( campaignToSearch, new Set<Id>() );
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByCampaignAndContact_null_matchedRecords()
    {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByCampaignAndContact(null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByCampaignAndContact_invalidFields_matchedRecords()
    {
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        Id campaignToSearch = campaigns.get(0).Id;
        Set<Id> contactsToSearch = new Set<Id>();

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector(
            new Set<String> {'invalidField'}
            ).selectByCampaignAndContact(campaignToSearch, contactsToSearch);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}