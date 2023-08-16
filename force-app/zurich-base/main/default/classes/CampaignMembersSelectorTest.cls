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
    static void test_findZRMPendingRevMediatorCampaignMembers() {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().findZRMPendingRevMediatorCampaignMembers();
        Test.stopTest();

        System.assertEquals(campaignMembers.size(), matchedRecords.size(), 'Records should match');
    }

    @isTest
    static void test_selectById_matchedRecords()
    {
        List<String> campaignMembers = new List<String>();

        for(CampaignMember cm : [SELECT Id FROM CampaignMember])
        {
            campaignMembers.add(cm.id);
        }

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectById(campaignMembers);
        Test.stopTest();

        System.assertEquals(campaignMembers.size(), matchedRecords.size(), 'Records should match');
    }

    @isTest
    static void test_selectById_emptyList_matchedRecords()
    {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectById(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectById_null_matchedRecords()
    {
        CampaignMember cm = new CampaignMember();
        List<String> cmIds = new List<String> { String.valueOf(cm.id) };

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectById(cmIds);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }


    @isTest
    static void test_selectByCampaignType_matchedRecords()
    {
        List<String> campaignMembers = new List<String>();

        for(CampaignMember cm : [SELECT Campaign.Type FROM CampaignMember])
        {
            campaignMembers.add(cm.Campaign.Type);
        }

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByCampaignType(campaignMembers);
        Test.stopTest();

        System.assertEquals(campaignMembers.size(), matchedRecords.size(), 'Records should match');
    }

    @isTest
    static void test_selectByCampaignType_emptyList_matchedRecords()
    {
        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByCampaignType(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByCampaignType_null_matchedRecords()
    {
        CampaignMember cm = new CampaignMember();
        List<String> cmIds = new List<String> { 'AXAXAXAXAXAXAXAX' };

        Test.startTest();
        List<CampaignMember> matchedRecords = new CampaignMembersSelector().selectByCampaignType(cmIds);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}