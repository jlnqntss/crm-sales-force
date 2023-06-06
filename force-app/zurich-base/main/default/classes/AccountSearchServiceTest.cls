/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 06-06-2023
 * @last modified by  : aberuete
**/
@isTest
private class AccountSearchServiceTest
{
    static final string MESSAGE_LISTAS_IGUALES = 'Las dos listas deberían ser iguales';
    static final String MESSAGE_NO_DEVOLVER_NADA = 'no debe devolver nada';
    static final String MESSAGE_DEBERIA_HABER_CUENTAS = 'There should be Accounts';
    static final String MESSAGE_LISTA_DEBERIA_ESTAR_VACIA = 'List shouldnt be empty';
    static final String MESSAGE_SET_DEBE_TENER_RECORD_ID = 'Set should contains the record Id';

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
        List<Account> matchedRecords = AccountSearchService.findCustomersByPhoneNumber(telephoneNumberToSearch, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL, null, null);
        List<Account> matchedRecordsByRecordType = AccountSearchService.findCustomersByPhoneNumber(telephoneNumberToSearch, null, RecordsSelector.LegalEntity.ALL, new List<String>{'Customer'}, null);
        List<Account> matchedRecordsByRecordTypeAndType = AccountSearchService.findCustomersByPhoneNumber(telephoneNumberToSearch, null, RecordsSelector.LegalEntity.ALL, new List<String>{'Customer'}, new List<String>{'F','J'});
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');
        System.assertEquals(true, matchedRecords.equals(matchedRecordsByRecordType), MESSAGE_LISTAS_IGUALES);
        System.assertEquals(0, matchedRecordsByRecordTypeAndType.size(), 'No debería devolver ninguna cuenta');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(new AccountsSelector().selectById(recordIds) );

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
        List<Account> matchedRecords = AccountSearchService.findCustomersByPhoneNumber(new List<String>(), RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL, null, null);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista de teléfonos
        System.assertEquals(true, matchedRecords.isEmpty(), MESSAGE_NO_DEVOLVER_NADA);
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
        List<Account> matchedRecords = AccountSearchService.findCustomersByEmail(emailsToSearch, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL, null, null);
        List<Account> matchedRecordsByRecordType = AccountSearchService.findCustomersByEmail(emailsToSearch, null, RecordsSelector.LegalEntity.ALL, new List<String> {'Customer'}, null);
        List<Account> matchedRecordsByRecordTypeAndType = AccountSearchService.findCustomersByEmail(emailsToSearch, null, RecordsSelector.LegalEntity.ALL, new List<String> {'Customer'}, new List<String>{'F','J'});
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');
        System.assertEquals(true, matchedRecords.equals(matchedRecordsByRecordType), MESSAGE_LISTAS_IGUALES);
        System.assertEquals(0, matchedRecordsByRecordTypeAndType.size(), 'No debería devolver ninguna cuenta');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(new AccountsSelector().selectById(recordIds) );

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
        List<Account> matchedRecords = AccountSearchService.findCustomersByEmail(new List<String>(), RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL, null, null);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), MESSAGE_NO_DEVOLVER_NADA);
    }

    @isTest
    static void test_findCustomersByDocumentId_ok()
    {
        //Recuperamos las cuentas que tienen polizas del TestSetUp
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, NationalId__c, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, MESSAGE_DEBERIA_HABER_CUENTAS);
        Set<Id> accountIds = new Set<Id>();
        List<String> nationalIds = new List<String>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
            nationalIds.add(account.NationalId__c);
        }

        // Test
        Test.startTest();
        List<Account> matchedRecords = AccountSearchService.findCustomersByDocumentId(nationalIds, 'N', RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL, null, null);
        Map <Id,Account> mapMatchedRecords = new Map<Id,Account>(matchedRecords);
        List<Account> matchedRecordsByRecordType = AccountSearchService.findCustomersByDocumentId(nationalIds, 'N', null, RecordsSelector.LegalEntity.ALL, new List<String>{'Customer'}, null);
        Map<Id,Account> mapMatchedRecordsByRecordType = new Map<Id,Account>(matchedRecordsByRecordType);
        List<Account> matchedRecordsByRecordTypeAndType = AccountSearchService.findCustomersByDocumentId(nationalIds, 'N', null, RecordsSelector.LegalEntity.ALL, new List<String>{'Customer'}, new List<String>{'F','J'});
        
        //La 'N' es porque se crean así las cuentas en TestDataFactory
        Test.stopTest();
        List<Id> listIdsMatchedRecords = new List<Id>(mapMatchedRecords.keySet());
        List<Id> listIdsMatchedRecordsByRecordType = new List<Id> (mapMatchedRecordsByRecordType.keySet());
        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), MESSAGE_LISTA_DEBERIA_ESTAR_VACIA);
        System.assertEquals(true, listIdsMatchedRecords.equals(listIdsMatchedRecordsByRecordType), MESSAGE_LISTAS_IGUALES);
        System.assertEquals(0, matchedRecordsByRecordTypeAndType.size(), 'El número de cuentas devuelto debería ser 0');

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), MESSAGE_SET_DEBE_TENER_RECORD_ID);
        }
    }

    @isTest
    static void test_findCustomersByDocumentId_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = AccountSearchService.findCustomersByDocumentId(new List<String>(), 'N', RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.GI, null, null);
        //La 'N' es porque se crean así las cuentas en TestDataFactory
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), MESSAGE_NO_DEVOLVER_NADA);
    }

    @isTest
    static void test_findCustomersByPolicyNumber_ok()
    {
        //Recuperamos las cuentas que tienen polizas del TestSetUp
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, MESSAGE_DEBERIA_HABER_CUENTAS);
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
        List<Account> matchedRecords = AccountSearchService.findCustomersByPolicyNumber(policyNumbers, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), MESSAGE_LISTA_DEBERIA_ESTAR_VACIA);

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), MESSAGE_SET_DEBE_TENER_RECORD_ID);
        }
    }

    @isTest
    static void test_findCustomersByPolicyNumber_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = AccountSearchService.findCustomersByPolicyNumber(new List<String>(), RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), MESSAGE_NO_DEVOLVER_NADA);
    }

    @isTest
    static void test_findCustomersByQuoteNumber_ok()
    {
        //Recuperamos las cuentas que tienen ofertas del TestSetUp
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, RecordTypeId FROM Account WHERE RecordTypeId =: customerRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, MESSAGE_DEBERIA_HABER_CUENTAS);
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
        List<Account> matchedRecords = AccountSearchService.findCustomersByQuoteNumber(quoteNumbers, RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), MESSAGE_LISTA_DEBERIA_ESTAR_VACIA);

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), MESSAGE_SET_DEBE_TENER_RECORD_ID);
        }
    }

    @isTest
    static void test_findCustomersByQuoteNumber_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = AccountSearchService.findCustomersByQuoteNumber(new List<String>(), RecordsSelector.Scope.ALL, RecordsSelector.LegalEntity.ALL);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), MESSAGE_NO_DEVOLVER_NADA);
    }

    @isTest
    static void test_findIntermediariesByPhoneNumber_ok()
    {
        //Recuperamos las cuentas Intermediary del TestSetUp
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, Phone, RecordTypeId FROM Account WHERE RecordTypeId =: intermediaryRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, MESSAGE_DEBERIA_HABER_CUENTAS);
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
        List<Account> matchedRecords = AccountSearchService.findIntermediariesByPhoneNumber(phoneNumbers);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), MESSAGE_LISTA_DEBERIA_ESTAR_VACIA);

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), MESSAGE_SET_DEBE_TENER_RECORD_ID);
        }
    }

    @isTest
    static void test_findIntermediariesByPhoneNumber_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = AccountSearchService.findIntermediariesByPhoneNumber(new List<String>());
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), MESSAGE_NO_DEVOLVER_NADA);
    }

    @isTest
    static void test_findIntermediariesByCode_ok()
    {
        //Recuperamos las cuentas Intermediary del TestSetUp
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, INFOIntermediaryCode__c, RecordTypeId FROM Account WHERE RecordTypeId =: intermediaryRecordTypeId];
        System.assertEquals(true, accountsToSearch.size() > 0, MESSAGE_DEBERIA_HABER_CUENTAS);
        Set<Id> accountIds = new Set<Id>();
        List<String> codes = new List<String>();
        for(Account account: accountsToSearch)
        {
            accountIds.add(account.Id);
            codes.add(account.INFOIntermediaryCode__c);
        }

        // Test
        Test.startTest();
        List<Account> matchedRecords = AccountSearchService.findIntermediariesByCode(codes);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), MESSAGE_LISTA_DEBERIA_ESTAR_VACIA);

        // Then
        for(Account record : matchedRecords)
        {
            System.assertEquals(true, accountIds.contains(record.Id), MESSAGE_SET_DEBE_TENER_RECORD_ID);
        }
    }

    @isTest
    static void test_findIntermediariesByCode_ko()
    {
        // Test
        Test.startTest();
        List<Account> matchedRecords = AccountSearchService.findIntermediariesByCode(new List<String>());
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        System.assertEquals(true, matchedRecords.isEmpty(), MESSAGE_NO_DEVOLVER_NADA);
    }

}