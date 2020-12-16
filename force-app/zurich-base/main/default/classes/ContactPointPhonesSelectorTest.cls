@isTest
private with sharing class ContactPointPhonesSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Scope__c> insertedScopes = [SELECT Id, AccountId__c, Scope__c, AccountId__r.Name FROM Scope__c WHERE Id IN: scopes];

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromScopes(insertedScopes, 1);
        insert contactPointPhones;
    }

    @isTest
    static void test_selectByScopeIdAndIsPrimary_matchedRecords()
    {
        List<Scope__c> scopesToSearch = [SELECT Id FROM Scope__c];
        System.assertEquals(false, scopesToSearch.isEmpty(), 'List should NOT be empty');

        Set<Id> scopeIds = new Set<Id>();
        for(Scope__c scope: scopesToSearch)
        {
            scopeIds.add(scope.Id);
        }

        Test.startTest();
        List<ContactPointPhone> matchedRecords = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'ScopeId__c'}
            ).selectByScopeIdAndIsPrimary(scopeIds, true, null);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(ContactPointPhone contactPoint: matchedRecords)
        {
            System.assertEquals(true, scopeIds.contains(contactPoint.ScopeId__c), 'Set should contain the ScopeId__c');
        }
    }

    @isTest
    static void test_selectByScopeIdAndIsPrimary_excludingContactPointPhones_matchedRecords()
    {
        List<Scope__c> scopesToSearch = [SELECT Id FROM Scope__c];
        System.assertEquals(false, scopesToSearch.isEmpty(), 'List should NOT be empty');

        Set<Id> scopeIds = new Set<Id>();
        for(Scope__c scope: scopesToSearch)
        {
            scopeIds.add(scope.Id);
        }

        List<ContactPointPhone> primaryContactPointPhones = new ContactPointPhonesSelector().selectByScopeIdAndIsPrimary(scopeIds, true, null);
        System.assertEquals(false, primaryContactPointPhones.isEmpty(), 'List should NOT be empty');

        List<ContactPointPhone> excludedContactPointPhones = new List<ContactPointPhone> {primaryContactPointPhones.get(0)};

        Test.startTest();
        List<ContactPointPhone> matchedRecords = new ContactPointPhonesSelector(new Set<String> {'Id', 'ScopeId__c'}).selectByScopeIdAndIsPrimary(scopeIds, true, excludedContactPointPhones);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        //Preparamos el set de Ids de excludedContactPointPhones para comprobar que no se recuperan esos registros
        Set<Id> excludedContactPointPhonesIds = new Set<Id>();
        for(ContactPointPhone excluded: excludedContactPointPhones)
        {
            excludedContactPointPhonesIds.add(excluded.Id);
        }

        for(ContactPointPhone contactPoint: matchedRecords)
        {
            System.assertEquals(true, scopeIds.contains(contactPoint.ScopeId__c), 'Set should contain the Id');
            System.assertEquals(false, excludedContactPointPhonesIds.contains(contactPoint.Id), 'Set should NOT contain the Id');
        }
    }

    @isTest
    static void test_selectByScopeIdAndIsPrimary_emptySet_matchedRecords()
    {
        Set<Id> scopesIds = new Set<Id>();

        Test.startTest();
        List<ContactPointPhone> matchedRecords = new ContactPointPhonesSelector().selectByScopeIdAndIsPrimary( scopesIds, true, new List<ContactPointPhone>() );
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByScopeIdAndIsPrimary_nullSet_matchedRecords()
    {
        Test.startTest();
        List<ContactPointPhone> matchedRecords = new ContactPointPhonesSelector().selectByScopeIdAndIsPrimary(null, null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByIsPrimary_ok()
    {
        Test.startTest();
        List<ContactPointPhone> primaryContactPointPhones = new ContactPointPhonesSelector(new Set<String> {'Id', 'IsPrimary'}).selectByIsPrimary(true);
        Test.stopTest();

        System.assertEquals(false, primaryContactPointPhones.isEmpty(), 'List should NOT be empty');
        for(ContactPointPhone primary: primaryContactPointPhones)
        {
            System.assertEquals(true, primary.IsPrimary, 'It should be true');
        }
    }

    @isTest
    static void test_selectByIsPrimary_null_ok()
    {
        Test.startTest();
        List<ContactPointPhone> matchedRecords = new ContactPointPhonesSelector().selectByIsPrimary(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByScopeIdAndTelephoneNumber_ok()
    {
        List<ContactPointPhone> contactPointPhones = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'ScopeId__c', 'TelephoneNumber'}
            ).selectByIsPrimary(true);
        System.assertEquals(false, contactPointPhones.isEmpty(), 'List should NOT be empty');

        //Extraemos ScopeId y TelephoneNumber para buscar
        Set<Id> scopeIds = new Set<Id> {contactPointPhones.get(0).ScopeId__c};
        String telephoneNumberToSearch = contactPointPhones.get(0).TelephoneNumber;

        Test.startTest();
        List<ContactPointPhone> matchedRecords = new ContactPointPhonesSelector(
            new Set<String> {'Id', 'ScopeId__c', 'TelephoneNumber'}
            ).selectByScopeIdAndTelephoneNumber(scopeIds, telephoneNumberToSearch);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');
        for(ContactPointPhone record: matchedRecords)
        {
            System.assertEquals(true, scopeIds.contains(record.ScopeId__c), 'Set should contain ScopeId__c');
            System.assertEquals(record.TelephoneNumber, telephoneNumberToSearch, 'TelephoneNumber should be the same');
        }
    }

    @isTest
    static void test_selectByScopeIdAndTelephoneNumber_null_ok()
    {
        Test.startTest();
        List<ContactPointPhone> matchedRecords = new ContactPointPhonesSelector().selectByScopeIdAndTelephoneNumber(null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectById_invalidFields_matchedRecords()
    {
        Set<Id> scopesIds = new Set<Id>();

        Test.startTest();
        List<ContactPointPhone> matchedRecords = new ContactPointPhonesSelector(new Set<String> {'invalidField'}).selectByScopeIdAndIsPrimary( scopesIds, true, new List<ContactPointPhone>() );

        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}