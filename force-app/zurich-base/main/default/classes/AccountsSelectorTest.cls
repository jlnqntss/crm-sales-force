@isTest
private with sharing class AccountsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        /*List<Account> businessAccounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
           insert businessAccounts;*/

        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'CustomerGI', 1);
        insert contacts;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 10);
        insert contactPointPhones;

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 10);
        insert contactPointEmails;
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

        // Test
        Test.startTest();

        List<Account> matchedRecords = new AccountsSelector().applyScope('ZE').findByNationalId(new List<String> { nationalId }, '', Label.GeneralInsurance);

        Test.stopTest();

        // Then
        System.assertEquals(true, matchedRecords.isEmpty(), 'The list should be empty');
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
}