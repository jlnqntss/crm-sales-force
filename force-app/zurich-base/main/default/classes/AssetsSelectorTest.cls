@isTest
public with sharing class AssetsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachScope(scopes, 'Qualification', System.today(), 1);
        insert opportunities;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opportunities, 1);
        insert policies;

        List<Asset> insuredObjects = TestDataFactory.generateInsuredObjectsForEachPolicy('Motor', policies, 1);
        insert insuredObjects;
    }

    @isTest
    static void test_selectByPolicyID_ok()
    {
        // Comprobaciones iniciales
        List<Policy__c> policies = [SELECT Id FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), 'Policies list should NOT be empty');

        List<String> ids = new List<String>();
        for (Policy__c p : policies)
        {
            ids.add(p.id);
        }

        Test.startTest();
        List<Asset> matchedRecords = new AssetsSelector().selectByPolicyID(ids);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');
    }

    @isTest
    static void test_selectByPolicyID_ko()
    {
        Test.startTest();
        List<Asset> matchedRecords = new AssetsSelector().selectByPolicyID( new List<String>() );
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByRegistrationNumber_ok()
    {
        // Comprobaciones iniciales
        List<Asset> assets = [SELECT Id, RegistrationNumber__c FROM Asset LIMIT 1];
        assets[0].RegistrationNumber__c = '9999ZZZ';
        update assets[0];

        Test.startTest();
        List<Asset> matchedRecords = new AssetsSelector().selectByRegistrationNumber(new List<String> {'9999ZZZ'});
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');
    }

    @isTest
    static void test_selectByRegistrationNumber_ko()
    {
        Test.startTest();
        List<Asset> matchedRecords = new AssetsSelector().selectByRegistrationNumber( new List<String>() );
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}