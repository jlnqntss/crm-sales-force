@isTest
private with sharing class ScopesSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;
    }

    @isTest
    static void test_selectById_matchedRecords()
    {
        List<Scope__c> createdScopes = [SELECT Id FROM Scope__c];
        System.assertEquals(false, createdScopes.isEmpty(), 'List should NOT be empty');

        Set<Id> scopesIds = new Set<Id>();
        for(Scope__c scope: createdScopes)
        {
            scopesIds.add(scope.Id);
        }

        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector(new Set<String> {'Id'}).selectById(scopesIds);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(Scope__c matchedScope: matchedRecords)
        {
            System.assertEquals(true, scopesIds.contains(matchedScope.Id), 'Set should contain the Id');
        }
    }

    @isTest
    static void test_selectById_emptySet_matchedRecords()
    {
        Set<Id> scopesIds = new Set<Id>();

        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector().selectById(scopesIds);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectById_nullSet_matchedRecords()
    {
        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector().selectById(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectById_invalidFields_matchedRecords()
    {
        Set<Id> scopesIds = new Set<Id>();

        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector(new Set<String> {'invalidField'}).selectById(scopesIds);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByAccountId_matchedRecords()
    {
        List<Scope__c> createdScopes = [SELECT Id, AccountId__c FROM Scope__c];
        System.assertEquals(false, createdScopes.isEmpty(), 'List should NOT be empty');

        Set<Id> scopesIds = new Set<Id>();
        Set<Id> accountsIds = new Set<Id>();
        for(Scope__c scope: createdScopes)
        {
            scopesIds.add(scope.Id);
            accountsIds.add(scope.AccountId__c);
        }

        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector(
            new Set<String> {'Id'}
            ).selectByAccountId(accountsIds);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(Scope__c matchedScope: matchedRecords)
        {
            System.assertEquals(true, scopesIds.contains(matchedScope.Id), 'Set should contain the Id');
        }
    }

    @isTest
    static void test_selectByAccountId_emptySet_matchedRecords()
    {
        Set<Id> accountsIds = new Set<Id>();

        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector().selectByAccountId(accountsIds);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByAccountId_nullSet_matchedRecords()
    {
        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector().selectByAccountId(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByAccountIdAndScope_matchedRecords()
    {
        List<Scope__c> createdScopes = [SELECT Id, AccountId__c, Scope__c FROM Scope__c];
        System.assertEquals(false, createdScopes.isEmpty(), 'List should NOT be empty');

        //Actualizamos el Scope de uno de ellos
        createdScopes.get(0).Scope__c = 'ZEO';
        update createdScopes;

        Set<Id> scopesIds = new Set<Id>();
        Set<Id> accountsIds = new Set<Id>();
        for(Scope__c scope: createdScopes)
        {
            scopesIds.add(scope.Id);
            accountsIds.add(scope.AccountId__c);
        }

        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector(
            new Set<String> {'Id'}
            ).selectByAccountIdAndScope(accountsIds, 'ZEO');
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(Scope__c matchedScope: matchedRecords)
        {
            System.assertEquals(true, scopesIds.contains(matchedScope.Id), 'Set should contain the Id');
        }
    }

    @isTest
    static void test_selectByAccountIdAndScope_emptySet_matchedRecords()
    {
        Set<Id> accountsIds = new Set<Id>();

        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector().selectByAccountIdAndScope(accountsIds, 'ZE');
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByAccountIdAndScope_nullSet_matchedRecords()
    {
        Test.startTest();
        List<Scope__c> matchedRecords = new ScopesSelector().selectByAccountIdAndScope(null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}