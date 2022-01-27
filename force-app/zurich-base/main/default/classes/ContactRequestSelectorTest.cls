/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @last modified on  : 18-11-2021
 * @last modified by  : jjuaristi
**/
@isTest
private with sharing class ContactRequestSelectorTest 
{
    @TestSetup
    static void makeData(){
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        // arcortazar - 21/01/2022
        // Añadimos al Setup la creación de una BusinessAccount y un contacto asociado.
        List<Account> businessAccounts = TestDataFactory.generateAccounts('001', 'BusinessCustomer', 1);
        insert businessAccounts;

        List<Contact> businessContact = TestDataFactory.generateContactsFromAccounts(businessAccounts, ContactsSelector.RT_NAME_CONTACT, 1);
        businessContact.get(0).LastName = businessAccounts.get(0).Name;
        insert businessContact;

    }

    @isTest
    static void findByCustomerIdAndContactDatetime() {
        // Recuperamos la cuenta
        Id recordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        List<Account> accounts = [SELECT Id, PersonContactId FROM Account WHERE RecordTypeId = :recordTypeIdAccount];
        System.assertEquals(1, accounts.size(), 'Deberia haber 1 cuenta');

        // Creamos 3 ContactRequest de ejemplo. 1 con fecha y hora de contacto en el pasado y 
        // 2 con fecha y hora de contacto en el futuro
        List<ContactRequest> contactReqs = TestDataFactory.generateContactRequest(accounts[0].PersonContactId, 3);
        contactReqs[0].PreferredContactDatetime__c = System.now().addMinutes(5);
        contactReqs[1].PreferredContactDatetime__c = System.now().addMinutes(-10);
        contactReqs[2].PreferredContactDatetime__c = System.now().addMinutes(15);
        insert contactReqs;


        Test.startTest();
        // Buscamos los ContactRequest para el momento actual
        List<ContactRequest> foundContactReqs =
            new ContactRequestSelector().findByCustomerIdAndContactDatetime(
                accounts[0].PersonContactId,
                System.now()
            );

        Test.stopTest();

        // Los 2 con fecha y hora en el futuro
        System.assertEquals(2, foundContactReqs.size(), 'Deberia encontrar 2 ContactRequest');
    }

    @isTest
    static void findByCustomerId() {
        // Recuperamos la cuenta
        Id recordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

        List<Account> accounts = [SELECT Id, PersonContactId FROM Account WHERE RecordTypeId = :recordTypeIdAccount];
        System.assertEquals(1, accounts.size(), 'Deberia haber 1 cuenta');

        // Creamos 3 ContactRequest de ejemplo. 1 con fecha y hora de contacto en el pasado y 
        // 2 con fecha y hora de contacto en el futuro
        List<ContactRequest> contactReqs = TestDataFactory.generateContactRequest(accounts[0].PersonContactId, 3);
        contactReqs[0].PreferredContactDatetime__c = System.now().addMinutes(5);
        contactReqs[1].PreferredContactDatetime__c = System.now().addMinutes(-10);
        contactReqs[2].PreferredContactDatetime__c = System.now().addMinutes(15);
        insert contactReqs;


        Test.startTest();
        // Buscamos los ContactRequest para el momento actual
        List<ContactRequest> foundContactReqs =
            new ContactRequestSelector().findByCustomerId(
                accounts[0].PersonContactId, ''
            );

        Test.stopTest();

        // Los 2 con fecha y hora en el futuro
        System.assertEquals(3, foundContactReqs.size(), 'Deberia encontrar 3 ContactRequest');
    }

    @isTest
    static void findByCustomerId_byName() {
        // Recuperamos la cuenta
        Id recordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();

        List<Account> accounts = [SELECT Id, Name, RecordTypeId FROM Account WHERE RecordTypeId = :recordTypeIdAccount];
        System.assertEquals(1, accounts.size(), 'Deberia haber 1 cuenta Business creada');

        List<Contact> contacts = [SELECT Id, Name, Account.Name, Account.RecordTypeId FROM Contact WHERE Account.RecordTypeId = :recordTypeIdAccount];
        System.assertEquals(1, contacts.size(), 'Deberia haber 1 contacto asociado a la cuenta Business');

        // Creamos 3 ContactRequest de ejemplo asociados al contacto. 1 con fecha y hora de contacto en el pasado y 
        // 2 con fecha y hora de contacto en el futuro
        List<ContactRequest> contactReqs = TestDataFactory.generateContactRequest(contacts[0].Id, 3);
        contactReqs[0].PreferredContactDatetime__c = System.now().addMinutes(5);
        contactReqs[1].PreferredContactDatetime__c = System.now().addMinutes(-10);
        contactReqs[2].PreferredContactDatetime__c = System.now().addMinutes(15);
        insert contactReqs;

        Test.startTest();
        // Buscamos los ContactRequest mediante el nombre de la cuenta (y no mediante su customerId)
        List<ContactRequest> foundContactReqs =
            new ContactRequestSelector().findByCustomerId(
                '', accounts[0].Name
            );

        Test.stopTest();

        // Los 2 con fecha y hora en el futuro
        System.assertEquals(3, foundContactReqs.size(), 'Deberia encontrar 3 ContactRequest');
    }
}