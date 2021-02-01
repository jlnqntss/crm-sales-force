@isTest
private class RecordsSelectorTest
{
    @testSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 10);
        insert policies;
    }

    @IsTest
    static void test_setLimit()
    {
        PoliciesSelector policiesSelector = new PoliciesSelector();

        Test.startTest();
        policiesSelector.setLimit(1);
        Test.stopTest();

        System.assertEquals('SELECT id FROM Policy__c LIMIT 1', policiesSelector.baseQuery.toQueryString(), 'No se ha generado la query correctamente');
    }

    @IsTest
    static void test_setOffset()
    {
        PoliciesSelector policiesSelector = new PoliciesSelector();

        Test.startTest();
        policiesSelector.setOffset(1);
        Test.stopTest();

        System.assertEquals('SELECT id FROM Policy__c OFFSET 1', policiesSelector.baseQuery.toQueryString(), 'No se ha generado la query correctamente');
    }

    @IsTest
    static void test_setFields_NoRelationshipFields()
    {
        PoliciesSelector policiesSelector = new PoliciesSelector();

        Test.startTest();
        policiesSelector.setFields
        (
          new List<Schema.SObjectField>
          {
            Policy__c.Id,
            Policy__c.Name
          }
        );
        Test.stopTest();

        System.assertEquals('SELECT id, name FROM Policy__c', policiesSelector.baseQuery.toQueryString(), 'No se ha generado la query correctamente');
    }

    @IsTest
    static void test_setFields_relationshipFields()
    {
        PoliciesSelector policiesSelector = new PoliciesSelector();

        Test.startTest();
        policiesSelector.setFields
        (
          new List<Schema.SObjectField>
          {
            Policy__c.Id,
            Policy__c.Name
          },
          new List<String>
          {
            'AccountId__r.Name'
          }
        );
        Test.stopTest();

        System.assertEquals('SELECT id, name, accountid__r.name FROM Policy__c', policiesSelector.baseQuery.toQueryString(), 'No se ha generado la query correctamente');
    }

}