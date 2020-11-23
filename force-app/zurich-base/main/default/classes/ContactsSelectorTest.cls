@isTest
private with sharing class ContactsSelectorTest
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

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, '', 10);
        insert contactPointEmails;
    }

    @isTest
    static void test_findByPhoneNumber_matchedRecords()
    {
        // Escenario

        //Preparamos datos, recuperamos un telefono de un ContactPointPhone existente
        List<ContactPointPhone> contactPointPhoneToSearch = [SELECT Id, TelephoneNumber FROM ContactPointPhone LIMIT 1];
        System.assertEquals(1, contactPointPhoneToSearch.size(), 'There should be 1 ContactPointPhone');

        String telephoneNumberToSearch = contactPointPhoneToSearch.get(0).TelephoneNumber;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Set<Id>();

        for(ContactPointPhone contactPoint : [SELECT Id, ParentId, ContactId__c FROM ContactPointPhone WHERE TelephoneNumber =: telephoneNumberToSearch])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
        }

        Test.setFixedSearchResults( new List<Id>(recordIds) );


        // Test
        Test.startTest();

        List<Contact> matchedRecords = ContactsSelector.findByPhoneNumber(new List<String> { telephoneNumberToSearch });

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        Map<Id, Contact> expectedContactsById = new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId IN: recordIds OR Id IN: recordIds]);

        for(Contact record : matchedRecords)
        {
            System.assertEquals(true, expectedContactsById.containsKey(record.Id), 'Map should contains the record Id');
        }
    }

    @isTest
    static void test_findByEmail_matchedRecords()
    {
        // Escenario

        //Preparamos datos, recuperamos un email de un ContactPointEmail existente
        List<ContactPointEmail> contactPointEmailToSearch = [SELECT Id, EmailAddress FROM ContactPointEmail LIMIT 1];
        System.assertEquals(1, contactPointEmailToSearch.size(), 'There should be 1 ContactPointEmail');

        String emailToSearch = contactPointEmailToSearch.get(0).EmailAddress;

        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Set<Id>();

        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c FROM ContactPointEmail WHERE EmailAddress =: emailToSearch])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
        }

        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();

        List<Contact> matchedRecords = ContactsSelector.findByEmail(new List<String> { emailToSearch } );

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        Map<Id, Contact> expectedContactsById = new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId IN: recordIds OR Id IN: recordIds]);

        for(Contact record : matchedRecords)
        {
            System.assertEquals(true, expectedContactsById.containsKey(record.Id), 'Map should contains the record Id');
        }
    }

    @isTest
    static void test_findByNationalId_matchedRecords()
    {
        // Escenario

        //Preparamos datos, recuperamos un DNI de un Contact existente
        Id noVidaRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId();
        List<Contact> contactsToSearch = [SELECT Id, Account.NationalId__c, RecordTypeId FROM Contact WHERE RecordTypeId =: noVidaRecordTypeId LIMIT 1];
        System.assertEquals(1, contactsToSearch.size(), 'There should be 1 Contact');

        String nationalId = contactsToSearch.get(0).Account.NationalId__c;

        Set<Id> recordIds = new Set<Id>();
        for(Contact contact: contactsToSearch)
        {
            recordIds.add(contact.Id);
        }

        // Test
        Test.startTest();

        List<Contact> matchedRecords = new ContactsSelector().applyScope('ZE').findByNationalId(new List<String> { nationalId }, 'N', Label.GeneralInsurance);

        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'List shouldnt be empty');

        // Then
        for(Contact record : matchedRecords)
        {
            System.assertEquals(true, recordIds.contains(record.Id), 'Set should contains the record Id');
        }
    }

    @isTest
    static void test_findByNationalId_notFound()
    {
        // Escenario

        //Preparamos datos, un DNI que no este en ninguno de los contactos existentes
        String nationalId = 'A';

        // Test
        Test.startTest();

        List<Contact> matchedRecords = new ContactsSelector().applyScope('ZE').findByNationalId(new List<String> { nationalId }, 'N', Label.GeneralInsurance);

        Test.stopTest();

        // Then
        System.assertEquals(true, matchedRecords.isEmpty(), 'The list should be empty');
    }

    @isTest
    static void test_findByNationalId_emptyNationalIdType()
    {
        // Escenario

        //Preparamos datos, un DNI que no este en ninguno de los contactos existentes
        Id noVidaRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId();
        List<Contact> contactsToSearch = [SELECT Id, Account.NationalId__c, RecordTypeId FROM Contact WHERE RecordTypeId =: noVidaRecordTypeId LIMIT 1];
        System.assertEquals(1, contactsToSearch.size(), 'There should be 1 Contact');

        String nationalId = contactsToSearch.get(0).Account.NationalId__c;

        // Test
        Test.startTest();

        List<Contact> matchedRecords = new ContactsSelector().applyScope('ZE').findByNationalId(new List<String> { nationalId }, '', Label.GeneralInsurance);

        Test.stopTest();

        // Then
        System.assertEquals(true, matchedRecords.isEmpty(), 'The list should be empty');
    }

    @isTest
    static void test_findByNationalId_matchedRecords_bulk()
    {
        // Escenario

        //Preparamos datos, recuperamos un DNI de un Contact existente
        List<Contact> contactsToSearch = [SELECT Id, Account.NationalId__c FROM Contact];
        System.assertEquals(true, contactsToSearch.size() > 1, 'There should be more than 1 Contact');

        List<String> listDNI = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(Contact contact: contactsToSearch)
        {
            listDNI.add(contact.Account.NationalId__c);
            recordIds.add(contact.Id);
        }

        // Test
        Test.startTest();

        List<Contact> matchedRecords = new ContactsSelector().applyScope('ZE').findByNationalId(listDNI, 'N', Label.GeneralInsurance);

        Test.stopTest();

        // Then
        System.assertEquals(false, matchedRecords.isEmpty(), 'The list shouldnt be empty');

        for(Contact record : matchedRecords)
        {
            System.assertEquals(true, recordIds.contains(record.Id), 'Set should contains the record Id');
        }
    }
}