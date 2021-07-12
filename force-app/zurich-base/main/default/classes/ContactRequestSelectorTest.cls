@isTest
private with sharing class ContactRequestSelectorTest 
{
    @TestSetup
    static void makeData(){
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;
    }

    @isTest
    static void findByCustomerIdAndContactDatetime() {
        // Recuperamos la cuenta
        List<Account> accounts = [SELECT Id, PersonContactId FROM Account];
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
}