@isTest
public with sharing class ClaimsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachScope(scopes, 'Qualification', System.today(), 1);
        insert opportunities;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachOpportunity(opportunities, 10);
        insert policies;

        // List<Asset> insuredObjects = TestDataFactory.generateInsuredObjectsForEachPolicy(policies);
        // insert insuredObjects;

        // List<Claim__c> claims = TestDataFactory.generateClaimsForEachPolicy(policies, 10);
        // insert claims;
    }

}