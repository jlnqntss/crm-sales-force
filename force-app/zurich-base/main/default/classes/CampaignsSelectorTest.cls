@isTest
private with sharing class CampaignsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Campaign> campaigns = TestDataFactory.generateCampaigns('001', 10);
        Integer i = 0;
        for (Campaign c: campaigns) {
            c.ExternalId__c = 'Test' + i;
            i++;
        }
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

    @isTest
    static void test_findCampaignByExternalId() {
        Set<String> externalIdsSet = new Set<String>();
        externalIdsSet.add('Test0');

        Test.startTest();
        List<Campaign> matchedRecords = new CampaignsSelector().findCampaignByExternalId(externalIdsSet);
        Test.stopTest();

        System.assertEquals(true, !matchedRecords.isEmpty(), 'List should not be empty');
    }

    @isTest
    static void test_findCampaigId_ok() {
        List<Campaign> campanyas = [SELECT ID from Campaign];
        List<String> ids = new List<String>();

        for (Campaign c : campanyas)
        {
            ids.add(c.id);
        }

        Test.startTest();
        List<Campaign> matchedRecords = new CampaignsSelector().findCampaignById(ids);
        Test.stopTest();

        System.assertEquals(true, !matchedRecords.isEmpty(), 'List should not be empty');
    }

    @isTest
    static void test_findCampaigId_ko() {
        
        List<String> ids = new List<String>();
        ids.add('000AAAAAAAAA');

        Test.startTest();
        List<Campaign> matchedRecords = new CampaignsSelector().findCampaignById(ids);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_findZRMInitiatedCrossSellingCampaings_ok() {
        List<Campaign> campanyas = [SELECT ID from Campaign WHERE Type = 'Cross Selling' OR IsActive = false];
        List<String> ids = new List<String>();

        for (Campaign c : campanyas)
        {
            ids.add(c.id);
        }

        Test.startTest();
        List<Campaign> matchedRecords = new CampaignsSelector().findZRMInitiatedCrossSellingCampaings(ids);
        Test.stopTest();

        System.assertEquals(true, !matchedRecords.isEmpty(), 'List should not be empty');
    }

    /**
    * @description Método de test que comprueba el correcto funcionamiento del 
    * método test 'selectCampaigns' de la clase 'CampaignsSelector'. Este método
    * recupera todas las campañas a las que un usuario tiene acceso. Al estar 
    * ejecutando los test en modo sistema, las campañas que debe recuperar son 
    * todas las que se han insertado en el método 'createScenario'.
    * 
    * @author amiranda 
    * @date 30-10-2023 
    **/
    @IsTest
    static void test_selectCampaigns() 
    {
        Integer totalCampaigns = [SELECT COUNT() FROM Campaign];
        Assert.isTrue(totalCampaigns > 0, 'Debería haber campañas en el sistema.');

        Test.startTest();
        List<Campaign> campaigns = new CampaignsSelector().selectCampaigns();
        Test.stopTest();

        Assert.areEqual(totalCampaigns, campaigns.size(), 'El número total de campañas no coincide.');
    }
}