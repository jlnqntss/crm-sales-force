@isTest
private with sharing class ContactsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        Account acc = new Account();
        acc.LastName = 'nescudero';
        acc.LegalEntity__pc = Label.GeneralInsurance;
        insert acc;

        ContactPointPhone cpp = new ContactPointPhone();
        cpp.ParentId = acc.Id;
        cpp.TelephoneNumber = '123456789';
        insert cpp;

        ContactPointEmail cpe = new ContactPointEmail();
        cpe.ParentId = acc.Id;
        cpe.EmailAddress = 'nescudero@nts-solutions.com';
        insert cpe;
    }

    @isTest
    static void test_findByPhoneNumber_matchedRecords()
    {
        // Escenario
        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Set<Id>();
        
        for(ContactPointPhone contactPoint : [SELECT Id, ParentId, ContactId__c FROM ContactPointPhone WHERE TelephoneNumber = '123456789'])
        {
            recordIds.add(contactPoint.ParentId);
        }

        Test.setFixedSearchResults(new List<Id>(recordIds) );


        // Test
        Test.startTest();

        List<Contact> matchedRecords = ContactsSelector.findByPhoneNumber(new List<String> { '123456789'});

        Test.stopTest();

        // Then
        Map<Id, Contact> expectedContactsById = new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId IN: recordIds OR Id IN: recordIds]);

        for(Contact record : matchedRecords)
        {
            System.assertEquals(true, expectedContactsById.containsKey(record.Id) );
        }
    }

    @isTest
    static void test_findByEmail_matchedRecords()
    {
        // Escenario
        // SOSL - Resultados de búsqueda
        Set<Id> recordIds = new Set<Id>();
        
        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c FROM ContactPointEmail WHERE EmailAddress = 'nescudero@nts-solutions.com'])
        {
            recordIds.add(contactPoint.ParentId);
        }

        Test.setFixedSearchResults(new List<Id>(recordIds) );
        
        // Test
        Test.startTest();

        List<Contact> matchedRecords = ContactsSelector.findByPhoneNumber(new List<String> { 'nescudero@nts-solutions.com'} );

        Test.stopTest();

        // Then
        Map<Id, Contact> expectedContactsById = new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId IN: recordIds OR Id IN: recordIds]);

        for(Contact record : matchedRecords)
        {
            System.assertEquals(true, expectedContactsById.containsKey(record.Id) );
        }
    }
}