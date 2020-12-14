@isTest
private with sharing class OpportunitiesSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'CustomerGI', 1);
        insert contacts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachScope(scopes, 'Qualification', System.today(), 10);
        insert opportunities;
    }

    @isTest
    static void test_selectByAccountIdAndScopes_matchedRecords()
    {
        List<Scope__c> existingScopes = [SELECT Id, AccountId__c FROM Scope__c];
        System.assertEquals(false, existingScopes.isEmpty(), 'List should NOT be empty');

        Set<Id> scopesIds = new Set<Id>();
        for(Scope__c scope: existingScopes)
        {
            scopesIds.add(scope.Id);
        }

        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector(
            new Set<String> {'Id', 'AccountId', 'ScopeId__c'}
            ).selectByAccountIdAndScopes(existingScopes.get(0).AccountId__c, scopesIds);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(Opportunity matchedOpp: matchedRecords)
        {
            System.assertEquals(true, scopesIds.contains(matchedOpp.ScopeId__c), 'Set should contain the Id');
            System.assertEquals(true, matchedOpp.AccountId == existingScopes.get(0).AccountId__c, 'AccountId should be the same');
        }
    }

    @isTest
    static void test_selectByAccountIdAndScopes_emptySet_matchedRecords()
    {
        List<Scope__c> existingScopes = [SELECT Id, AccountId__c FROM Scope__c];
        System.assertEquals(false, existingScopes.isEmpty(), 'List should NOT be empty');

        Set<Id> scopesIds = new Set<Id>();

        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector().selectByAccountIdAndScopes(existingScopes.get(0).AccountId__c, scopesIds);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByAccountIdAndScopes_nullSet_matchedRecords()
    {
        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector().selectByAccountIdAndScopes(null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByAccountIdAndScopes_invalidFields_matchedRecords()
    {
        List<Scope__c> existingScopes = [SELECT Id, AccountId__c FROM Scope__c];
        System.assertEquals(false, existingScopes.isEmpty(), 'List should NOT be empty');

        Set<Id> scopesIds = new Set<Id>();

        Test.startTest();
        List<Opportunity> matchedRecords = new OpportunitiesSelector(
            new Set<String> {'invalidField'}
            ).selectByAccountIdAndScopes(existingScopes.get(0).AccountId__c, scopesIds);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}