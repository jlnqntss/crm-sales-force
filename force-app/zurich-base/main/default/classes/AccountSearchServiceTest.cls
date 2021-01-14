@isTest
private class AccountSearchServiceTest
{
    @TestSetup
    public static void createScenario()
    {
        //Zurich Empresas
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 10);
        insert contactPointPhones;

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 10);
        insert contactPointEmails;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 10);
        insert policies;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert opportunities;

        //Intermediary-> NO tienen ContactPointPhones!!!
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts('001', 'Intermediary', 10);
        insert intermediaryAccounts;
    }

    @isTest
    static void test_findCustomersByPhoneNumber_ok()
    {
        // SOSL - Resultados de búsqueda
        List<String> telephoneNumberToSearch = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(ContactPointPhone contactPoint : [SELECT Id, ParentId, ContactId__c, TelephoneNumber FROM ContactPointPhone])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
            telephoneNumberToSearch.add(contactPoint.TelephoneNumber);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByPhoneNumber(telephoneNumberToSearch, scope);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(AccountsSelector.selectById(recordIds, new Set<String> {'Id'}) );

        for(Account record : matchedRecords)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(record.Id), 'Map should contains the record Id');
        }
    }

    @isTest
    static void test_findCustomersByPhoneNumber_ko()
    {
        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByPhoneNumber(new List<String>(), scope);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista de teléfonos
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findCustomersByEmail_ok()
    {
        // SOSL - Resultados de búsqueda
        List<String> emailsToSearch = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c, EmailAddress FROM ContactPointEmail])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
            emailsToSearch.add(contactPoint.EmailAddress);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByEmail(emailsToSearch, scope);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(AccountsSelector.selectById(recordIds, new Set<String> {'Id'}) );

        for(Account record : matchedRecords)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(record.Id), 'Map should contains the record Id');
        }
    }

    @isTest
    static void test_findCustomersByEmail_ko()
    {
        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByEmail(new List<String>(), scope);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findCustomersByDocumentId_ok()
    {
        //Recuperamos las cuentas que tienen polizas del TestSetUp
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, NationalId__c, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, 'There should be Accounts');
        Set<Id> accountIds = new Set<Id>();
        List<String> nationalIds = new List<String>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
            nationalIds.add(account.NationalId__c);
        }

        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByDocumentId(nationalIds, 'N', scope, '001');
        //La 'N' es porque se crean así las cuentas en TestDataFactory
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findCustomersByDocumentId_ko()
    {
        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByDocumentId(new List<String>(), 'N', scope, '001');
        //La 'N' es porque se crean así las cuentas en TestDataFactory
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findCustomersByPolicyNumber_ok()
    {
        //Recuperamos las cuentas que tienen polizas del TestSetUp
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, 'There should be Accounts');
        Set<Id> accountIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
        }
        //recuperar las pólizas que hay
        List<String> policyNumbers = new List<String>();
        List<Policy__c> policiesSelected = [SELECT Id, InfoPolicyNumber__c FROM Policy__c WHERE PolicyHolder__c IN :accountIds];
        for(Policy__c policy: policiesSelected)
        {
            policyNumbers.add(policy.InfoPolicyNumber__c);
        }

        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByPolicyNumber(policyNumbers, scope);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findCustomersByPolicyNumber_ko()
    {
        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByPolicyNumber(new List<String>(), scope);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findCustomersByQuoteNumber_ok()
    {
        //Recuperamos las cuentas que tienen ofertas del TestSetUp
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, 'There should be Accounts');
        Set<Id> accountIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
        }
        //recuperar las ofertas que hay
        List<String> quoteNumbers = new List<String>();
        List<Opportunity> quotesSelected = [SELECT Id, InfoQuoteNumber__c FROM Opportunity WHERE AccountId IN :accountIds];
        for(Opportunity quote: quotesSelected)
        {
            quoteNumbers.add(quote.InfoQuoteNumber__c);
        }

        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByQuoteNumber(quoteNumbers, scope);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findCustomersByQuoteNumber_ko()
    {
        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'all';
        List<Account> matchedRecords = AccountSearchService.findCustomersByQuoteNumber(new List<String>(), scope);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findIntermediariesByPhoneNumber_ok()
    {
        //Recuperamos las cuentas Intermediary del TestSetUp
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, Phone, RecordTypeId FROM Account WHERE RecordTypeId =: intermediaryRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, 'There should be Accounts');
        Set<Id> accountIds = new Set<Id>();
        List<String> phoneNumbers = new List<String>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
            phoneNumbers.add(account.Phone);
        }
        Test.setFixedSearchResults( new List<Id>(accountIds) );

        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'csm';
        List<Account> matchedRecords = AccountSearchService.findIntermediariesByPhoneNumber(phoneNumbers, scope);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findIntermediariesByPhoneNumber_ko()
    {
        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'csm';
        List<Account> matchedRecords = AccountSearchService.findIntermediariesByPhoneNumber(new List<String>(), scope);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findIntermediariesByCode_ok()
    {
        //Recuperamos las cuentas Intermediary del TestSetUp
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, INFOIntermediaryCode__c, RecordTypeId FROM Account WHERE RecordTypeId =: intermediaryRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, 'There should be Accounts');
        Set<Id> accountIds = new Set<Id>();
        List<String> codes = new List<String>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
            codes.add(account.INFOIntermediaryCode__c);
        }

        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'csm';
        List<Account> matchedRecords = AccountSearchService.findIntermediariesByCode(codes, scope);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findIntermediariesByCode_ko()
    {
        // Test
        Test.startTest();
        AccountSearchService.Scope scope = new AccountSearchService.Scope();
        scope.scope = 'csm';
        List<Account> matchedRecords = AccountSearchService.findIntermediariesByCode(new List<String>(), scope);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

}