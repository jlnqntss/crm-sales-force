@isTest
private with sharing class ContactPointEmailsSelectorTest
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

        List<Scope__c> insertedScopes = [SELECT Id, AccountId__c, Scope__c, AccountId__r.Name FROM Scope__c WHERE Id IN: scopes];

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromScopes(insertedScopes, 1);
        insert contactPointEmails;
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
        List<ContactPointEmail> matchedRecords = new ContactPointEmailsSelector(new Set<String> {'Id', 'ScopeId__c'}).selectByScopeIdAndIsPrimary(scopeIds, true, null);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        for(ContactPointEmail contactPoint: matchedRecords)
        {
            System.assertEquals(true, scopeIds.contains(contactPoint.ScopeId__c), 'Set should contain the ScopeId__c');
        }
    }

    @isTest
    static void test_selectByScopeIdAndIsPrimary_excludingContactPointEmails_matchedRecords()
    {
        List<Scope__c> scopesToSearch = [SELECT Id FROM Scope__c];
        System.assertEquals(false, scopesToSearch.isEmpty(), 'List should NOT be empty');

        Set<Id> scopeIds = new Set<Id>();
        for(Scope__c scope: scopesToSearch)
        {
            scopeIds.add(scope.Id);
        }

        List<ContactPointEmail> excludedContactPointEmails = [SELECT Id FROM ContactPointEmail WHERE ScopeId__c IN: scopeIds LIMIT 1];
        System.assertEquals(false, excludedContactPointEmails.isEmpty(), 'List should NOT be empty');

        Test.startTest();
        List<ContactPointEmail> matchedRecords = new ContactPointEmailsSelector(new Set<String> {'Id', 'ScopeId__c'}).selectByScopeIdAndIsPrimary(scopeIds, true, excludedContactPointEmails);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');

        //Preparamos el set de Ids de excludedContactPointEmails para comprobar que no se recuperan esos registros
        Set<Id> excludedContactPointEmailsIds = new Set<Id>();
        for(ContactPointEmail excluded: excludedContactPointEmails)
        {
            excludedContactPointEmailsIds.add(excluded.Id);
        }

        for(ContactPointEmail contactPoint: matchedRecords)
        {
            System.assertEquals(true, scopeIds.contains(contactPoint.ScopeId__c), 'Set should contain the Id');
            System.assertEquals(false, excludedContactPointEmailsIds.contains(contactPoint.Id), 'Set should NOT contain the Id');
        }
    }

    @isTest
    static void test_selectByScopeIdAndIsPrimary_emptySet_matchedRecords()
    {
        Set<Id> scopesIds = new Set<Id>();

        Test.startTest();
        List<ContactPointEmail> matchedRecords = new ContactPointEmailsSelector().selectByScopeIdAndIsPrimary( scopesIds, true, new List<ContactPointEmail>() );
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByScopeIdAndIsPrimary_nullSet_matchedRecords()
    {
        Test.startTest();
        List<ContactPointEmail> matchedRecords = new ContactPointEmailsSelector().selectByScopeIdAndIsPrimary(null, null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByIsPrimary_ok()
    {
        Test.startTest();
        List<ContactPointEmail> primaryContactPointEmails = new ContactPointEmailsSelector(new Set<String> {'Id', 'IsPrimary'}).selectByIsPrimary(true);
        Test.stopTest();

        System.assertEquals(false, primaryContactPointEmails.isEmpty(), 'List should NOT be empty');
        for(ContactPointEmail primary: primaryContactPointEmails)
        {
            System.assertEquals(true, primary.IsPrimary, 'It should be true');
        }
    }

    @isTest
    static void test_selectByIsPrimary_null_ok()
    {
        Test.startTest();
        List<ContactPointEmail> matchedRecords = new ContactPointEmailsSelector().selectByIsPrimary(null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByScopeIdAndEmailAddress_ok()
    {
        List<ContactPointEmail> contactPointEmails = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'ScopeId__c', 'EmailAddress'}
            ).selectByIsPrimary(true);
        System.assertEquals(false, contactPointEmails.isEmpty(), 'List should NOT be empty');

        //Extraemos ScopeId y EmailAddress para buscar
        Set<Id> scopeIds = new Set<Id> {contactPointEmails.get(0).ScopeId__c};
        String emailAddressToSearch = contactPointEmails.get(0).EmailAddress;

        Test.startTest();
        List<ContactPointEmail> matchedRecords = new ContactPointEmailsSelector(
            new Set<String> {'Id', 'ScopeId__c', 'EmailAddress'}
            ).selectByScopeIdAndEmailAddress(scopeIds, emailAddressToSearch);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');
        for(ContactPointEmail record: matchedRecords)
        {
            System.assertEquals(true, scopeIds.contains(record.ScopeId__c), 'Set should contain ScopeId__c');
            System.assertEquals(record.EmailAddress, emailAddressToSearch, 'EmailAddress should be the same');
        }
    }

    @isTest
    static void test_selectByScopeIdAndEmailAddress_null_ok()
    {
        Test.startTest();
        List<ContactPointEmail> matchedRecords = new ContactPointEmailsSelector().selectByScopeIdAndEmailAddress(null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectById_invalidFields_matchedRecords()
    {
        Set<Id> scopesIds = new Set<Id>();

        Test.startTest();
        List<ContactPointEmail> matchedRecords = new ContactPointEmailsSelector(new Set<String> {'invalidField'}).selectByScopeIdAndIsPrimary( scopesIds, true, new List<ContactPointEmail>() );

        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}