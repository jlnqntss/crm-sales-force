@isTest
private with sharing class CampaignsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 10);
        insert campaigns;
    }

    @isTest
    static void test_selectByName_matchedRecords()
    {
        List<Campaign> campaigns = [SELECT Id, Name FROM Campaign];
        System.assertEquals(false, campaigns.isEmpty(), 'List should NOT be empty');

        String nameToSearch = campaigns.get(0).Name;

        Test.startTest();
        List<Campaign> matchedRecords = new CampaignsSelector(
            new Set<String> {'Id', 'Name'}
            ).selectByName(new Set<String> {nameToSearch});
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(Campaign matched: matchedRecords)
        {
            System.assertEquals(true, matched.Name == nameToSearch, 'Name should be the same');
        }
    }

    @isTest
    static void test_selectByName_emptySet_matchedRecords()
    {
        Set<String> names = new Set<String>();
        Test.startTest();
        List<Campaign> matchedRecords = new CampaignsSelector().selectByName(names);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByName_nullSet_matchedRecords()
    {
        Test.startTest();
        List<Campaign> matchedRecords = new CampaignsSelector().selectByName(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByName_invalidFields_matchedRecords()
    {
        Set<String> names = new Set<String>();

        Test.startTest();
        List<Campaign> matchedRecords = new CampaignsSelector(
            new Set<String> {'invalidField'}
            ).selectByName(names);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}