@isTest
private with sharing class AccountsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        //Zurich Empresas
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'CustomerGI', 1);
        insert contacts;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 10);
        insert contactPointPhones;

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 10);
        insert contactPointEmails;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 10);
        insert policies;

        List<Opportunity> opportunities = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert opportunities;

        //Intermediary-> NO tienen ContactPointPhones!!!
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 10);
        insert intermediaryAccounts;
    }

    @isTest
    static void test_findByNationalId_matchedRecords()
    {
        // Escenario

        //Preparamos datos, recuperamos un DNI de un Contact existente
        Id businessCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, NationalId__c, RecordTypeId FROM Account WHERE RecordTypeId =: businessCustomerRecordTypeId LIMIT 1];
        System.assertEquals(1, accountsToSearch.size(), 'There should be 1 Account');

        String nationalId = accountsToSearch.get(0).NationalId__c;

        Set<Id> recordIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            recordIds.add(account.Id);
        }

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('ZE').findByNationalId(new List<String> { nationalId }, 'N', Label.GeneralInsurance);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, recordIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findByNationalId_notFound()
    {
        // Escenario

        //Preparamos datos, un DNI que no este en ninguna de las cuentas existentes
        String nationalId = 'A';

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('ZE').findByNationalId(new List<String> { nationalId }, 'N', Label.GeneralInsurance);

        Test.stopTest();

        // Then
        System.assertEquals(true, matchedRecords.isEmpty(), 'The list should be empty');
    }

    @isTest
    static void test_findByNationalId_emptyNationalIdType()
    {
        // Escenario

        //Preparamos datos, un DNI que no este en ninguna de las cuentas existentes
        Id businessCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, NationalId__c, RecordTypeId FROM Account WHERE RecordTypeId =: businessCustomerRecordTypeId LIMIT 1];
        System.assertEquals(1, accountsToSearch.size(), 'There should be 1 Account');

        String nationalId = accountsToSearch.get(0).NationalId__c;

        Set<Id> recordIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            recordIds.add(account.Id);
        }

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('ZE').findByNationalId(new List<String> { nationalId }, '', Label.GeneralInsurance);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, recordIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findByNationalId_matchedRecords_bulk()
    {
        // Escenario

        //Preparamos datos, recuperamos un DNI de un Contact existente
        List<Account> accountsToSearch = [SELECT Id, NationalId__c FROM Account];
        System.assertEquals(true, accountsToSearch.size() > 1, 'There should be more than 1 Account');

        List<String> listDNI = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            listDNI.add(account.NationalId__c);
            recordIds.add(account.Id);
        }

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('ZE').findByNationalId(listDNI, 'N', Label.GeneralInsurance);

        Test.stopTest();

        // Then
        System.assertEquals(false, matchedRecords.isEmpty(), 'The list shouldnt be empty');

        for(Account record : matchedRecords)
        {
            System.assertEquals(true, recordIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findByPhoneNumber_ok()
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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByPhoneNumber(telephoneNumberToSearch);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN: recordIds]);

        for(Account record : matchedRecords)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(record.Id), 'Map should contains the record Id');
        }
    }

    @isTest
    static void test_findByPhoneNumber_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByPhoneNumber(new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista de teléfonos
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findByEmail_ok()
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
        Test.setFixedSearchResults(new List<Id>(recordIds) );

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByEmail(emailsToSearch);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN: recordIds]);

        for(Account record : matchedRecords)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(record.Id), 'Map should contains the record Id');
        }
    }

    @isTest
    static void test_findByEmail_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByEmail(new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findByPolicyNumber_ok()
    {
        //Recuperamos las cuentas que tienen polizas del TestSetUp
        Id businessCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId =: businessCustomerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, 'There should be Accounts');
        Set<Id> accountIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
        }
        //recuperar las pólizas que hay
        List<String> policyNumbers = new List<String>();
        List<Policy__c> policiesSelected = [SELECT InfoPolicyNumber__c FROM Policy__c WHERE PolicyHolder__c IN :accountIds];
        for(Policy__c policy: policiesSelected)
        {
            policyNumbers.add(policy.InfoPolicyNumber__c);
        }

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByPolicyNumber(policyNumbers);

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
    static void test_findByPolicyNumber_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByPolicyNumber(new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findByQuoteNumber_ok()
    {
        //Recuperamos las cuentas que tienen polizas del TestSetUp
        Id businessCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId =: businessCustomerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, 'There should be Accounts');
        Set<Id> accountIds = new Set<Id>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
        }
        //recuperar las ofertas que hay
        List<String> quoteNumbers = new List<String>();
        List<Opportunity> quotesSelected = [SELECT InfoQuoteNumber__c FROM Opportunity WHERE AccountId IN :accountIds];
        for(Opportunity quote: quotesSelected)
        {
            if(!String.isBlank(quote.InfoQuoteNumber__c) )
            {
                quoteNumbers.add(quote.InfoQuoteNumber__c);
            }
        }

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByQuoteNumber(quoteNumbers);

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
    static void test_findByQuoteNumber_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByQuoteNumber(new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findByIntermediaryPhoneNumber_ok()
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
        Test.setFixedSearchResults(new List<Id>(accountIds) );

        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByIntermediaryPhoneNumber(phoneNumbers);
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
    static void test_findByIntermediaryPhoneNumber_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().applyScope('all').findByIntermediaryPhoneNumber(new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    @isTest
    static void test_findByIntermediaryCode_ok()
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
        List<Account> matchedRecords = new AccountsSelector().applyScope('csm').findByIntermediaryCode(codes);
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
    static void test_findByIntermediaryCode_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = new AccountsSelector().applyScope('csm').findByIntermediaryCode(new List<String>() );
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }

    /**
     * Test findByIdsAndScope method
     * 
     * @author NTS (agonzalezisasi)
     * @date 10/12/2020
     */
    @isTest
    static void test_findByIdsAndScope_ok()
    {
        // Include Personal Accounts Test - 10/12/2020 - NTS (agonzalezisasi)
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 2);
        insert accounts;
        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 3);
        insert scopes;

        Test.startTest();
            Set<Id> ids = new Set<Id>{accounts[0].Id, accounts[1].Id};
            AccountsSelector accountSel = new AccountsSelector();
            List<Account> result = accountSel.findByIdsAndScope(ids, new List<String>{'ZE', 'ZEO'});
        Test.stopTest();

        System.Debug('-------------- Results');
        System.assertEquals(2, result.size(), 'There should be 2 accounts');
        System.assertEquals(3, result[0].Scope__r.size(), 'There should be 3 scopes for the first account');
        System.assertEquals(3, result[1].Scope__r.size(), 'There should be 3 scopes for the second account');
    }
}