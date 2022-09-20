@isTest
public with sharing class AssetsSelectorTest {
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
    static void test_selectByPolicyID()
    {
        // Comprobaciones iniciales
        List<Policy__c> policies = [SELECT Id FROM Policy__c];
        System.assertEquals(false, policies.isEmpty(), 'Policies list should NOT be empty');

        Test.startTest();
        List<Asset> matchedRecords = new AssetsSelector().selectByPolicyID(policies[0].Id);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');
    }
}
