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

        // hotfix: obtener cuentas de tipo personales con el campo PersonContactId relleno
        accounts = new List<Account>([SELECT Id, PersonContactId FROM Account WHERE PersonContactId != null]);

        List<CampaignMember> campaignMembers = TestDataFactory.generateCampaignMembersForEachCampaign(accounts, campaigns, 'Subscribed');
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

    @isTest
    static void test_selectById_matchedRecords()
    {
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        List<CampaignMember> currentCampaignMembers = [SELECT ContactId FROM CampaignMember];
        System.assertEquals(false, currentCampaignMembers.isEmpty(), 'List should NOT be empty');

        Set<Id> campaignMembersIDs = new Set<Id>();
        for(CampaignMember member: currentCampaignMembers)
        {
            campaignMembersIDs.add(member.Id);
        }

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector(new Set<String> {'Id', 'ContactId', 'CampaignId'}).selectById(campaignMembersIDs);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(CampaignMember matched: matchedRecords)
        {
            System.assertEquals(true, campaignMembersIDs.contains(matched.Id), 'Set should contain ContactId');
        }
    }

    @isTest
    static void test_selectById_emptySet_matchedRecords()
    {
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectById(new Set<Id>());
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectById_null_matchedRecords()
    {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectById(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectById_invalidFields_matchedRecords()
    {
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector(new Set<String> {'invalidField'}).selectById(new Set<Id>());
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByStatus_matchedRecords()
    {
        List<Campaign> campaigns = [SELECT Id FROM Campaign];
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        Id campaignToSearch = campaigns.get(0).Id;

        List<CampaignMember> currentCampaignMembers = [SELECT Id, Status FROM CampaignMember];
        System.assertEquals(false, currentCampaignMembers.isEmpty(), 'List should NOT be empty');

        String statusToSearch = currentCampaignMembers.get(0).Status;

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector(
            new Set<String> {'Id', 'Status'}
            ).selectByStatus(statusToSearch);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(CampaignMember matched: matchedRecords)
        {
            System.assertEquals(true, matched.Status == statusToSearch, 'Status should be the same');
        }
    }

    @isTest
    static void test_selectByStatus_emptyString_matchedRecords()
    {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByStatus( '' );
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByStatus_null_matchedRecords()
    {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByStatus(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_findZRMPendingRevMediatorCampaignMembers()
    {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().findZRMPendingRevMediatorCampaignMembers();
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByCampaignTypeAndId_matchedRecords()
    {
        List<String> campaignMemberTypes = new List<String>();
        Set<Id> campaignMemberIds = new Set<Id>();

        for(CampaignMember cm : [SELECT Id, Campaign.Type FROM CampaignMember])
        {
            campaignMemberTypes.add(cm.Campaign.Type);
            campaignMemberIds.add(cm.Id);
        }

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByCampaignTypeAndId(campaignMemberTypes, campaignMemberIds);
        Test.stopTest();

        System.assertEquals(campaignMemberIds.size(), matchedRecords.size(), 'Records should match');
    }

    @isTest
    static void test_selectByCampaignTypeAndId_emptyList_matchedRecords()
    {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByCampaignTypeAndId(null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByCampaignTypeAndId_null_matchedRecords()
    {
        List<String> campaignMemberTypes = new List<String> { 'AXAXAXAXAXAXAXAX' };

        Set<Id> campaignMemberIds = new Set<Id>();

        for(CampaignMember cm : [SELECT Id, Campaign.Type FROM CampaignMember])
        {
            campaignMemberIds.add(cm.Id);
        }

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByCampaignTypeAndId(campaignMemberTypes, campaignMemberIds);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}