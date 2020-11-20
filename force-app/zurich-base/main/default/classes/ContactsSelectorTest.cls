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

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 10);
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

        List<Contact> matchedRecords = new ContactsSelector().applyScope('all').findByPhoneNumber(new List<String> { telephoneNumberToSearch });

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

        List<Contact> matchedRecords = new ContactsSelector().applyScope('all').findByEmail(new List<String> { emailToSearch } );

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
    static void test_findByEmail_ze_matchedRecords()
    {
        // Escenario

        //Preparamos datos, recuperamos un email de un ContactPointEmail existente
        Id noVidaRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('CustomerGI').getRecordTypeId();
        List<Contact> contactsToSearch = [SELECT Id, AccountId FROM Contact WHERE RecordTypeId =: noVidaRecordTypeId LIMIT 1];
        System.assertEquals(1, contactsToSearch.size(), 'There should be 1 Contact');

        List<ContactPointEmail> contactPointEmailToSearch = [SELECT Id, EmailAddress FROM ContactPointEmail WHERE ParentId =: contactsToSearch.get(0).AccountId LIMIT 1];
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

        List<Contact> matchedRecords = new ContactsSelector().applyScope('ze').findByEmail(new List<String> { emailToSearch } );

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
}