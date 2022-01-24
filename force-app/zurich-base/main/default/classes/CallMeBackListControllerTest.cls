/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @last modified on  : 21-01-2022
 * @last modified by  : arcortazar
**/
@isTest
private class CallMeBackListControllerTest {

    @TestSetup
    public static void createScenario()
    {
        //Creamos la cuenta            
        List<Account> accounts = TestDataFactory.generateAccounts('Life insurance', 'Customer', 1);
        insert accounts;

        // arcortazar - 21/01/2022
        // Añadimos al Setup la creación de una BusinessAccount con un contacto asociado, así como los CustomerRequest asociados a esta cuenta
        List<Account> businessAccounts = TestDataFactory.generateAccounts('Life insurance', 'BusinessCustomer', 1);
        insert businessAccounts;

        List<Contact> businessContact = TestDataFactory.generateContactsFromAccounts(businessAccounts, ContactsSelector.RT_NAME_CONTACT, 1);
        businessContact.get(0).LastName = businessAccounts.get(0).Name;
        insert businessContact;

        // Obtenemos los recordTypes de cada cuenta
        Id recordTypeIdPersonAccount = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        Id recordTypeIdBusiness = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();
        
        //Creamos los contactRequests asociados a la PersonAccount 
        List<Account> createdAccounts = [SELECT PersonContactId FROM Account WHERE RecordTypeId = :recordTypeIdPersonAccount];
        Id perConId = createdAccounts.get(0).PersonContactId;
        List<ContactRequest> contactReqs = new List<ContactRequest>();

        for (Integer i = 0; i < 10; i++) {
            contactReqs.add(
                new ContactRequest(
                    GenesysInteractionId__c= 'b5d554e7-94b7-4fe1-8041-bfd9992a569' + i,
                    Status= 'New',
                    WhoId= perConId,
                    PreferredContactDatetime__c= DateTime.now()
                )
            );
        }
        insert contactReqs;

        // arcortazar - 21/02/2022
        // Creamos los contactRequests asociados a la BusinessAccount
        List<Contact> createdContact = [SELECT Id FROM Contact WHERE Account.RecordTypeId = :recordTypeIdBusiness];
        Id perConBusinessId = createdContact.get(0).Id;
        List<ContactRequest> contactReqsBusiness = new List<ContactRequest>();

        for (Integer i = 0; i < 15; i++) {
            contactReqsBusiness.add(
                new ContactRequest(
                    GenesysInteractionId__c= 'b5d554e7-94b7-4fe1-8041-bfd9992a890' + i,
                    Status= 'New',
                    WhoId= perConBusinessId,
                    PreferredContactDatetime__c= DateTime.now()
                )
            );
        }
        insert contactReqsBusiness;
    }

    
    @isTest
    static void test_getContactRequestsById_ok()
    {
        //Obtenemos el whoId a enviar al controlador
        Account account = [SELECT Id, PersonContactId FROM Account LIMIT 1];
        String name = '';

        // Test
        Test.startTest();

        List<ContactRequest> foundContactRequests = CallMeBackListController.getContactRequestsByCustomerId(account.PersonContactId, name);

        Test.stopTest();

        // Asserts, en el makeData se le añaden 10 CR
        System.assertEquals(10, foundContactRequests.size(), 'Debería contener 10 CR');
    }

    @isTest
    static void test_getContactRequestsById_ko()
    {
        String name = '';
        // Test
        Test.startTest();
        try
        {
            List<ContactRequest> foundContactRequests = CallMeBackListController.getContactRequestsByCustomerId('3246525', name);

        }catch(Exception ex)
        {
            System.assertEquals('AuraHandledException', ex.getTypeName());
        }

        Test.stopTest();
    }

    @isTest
    static void test_getContactRequestsByName_ok()
    {
        // Obtenemos el ID del recordType de la Business Account
        Id recordTypeIdBusiness = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessCustomer').getRecordTypeId();

        //Obtenemos el N a enviar al controlador
        Contact contacto = [SELECT Id, Name FROM Contact WHERE Account.RecordTypeId = :recordTypeIdBusiness];
        // Test
        Test.startTest();

        List<ContactRequest> foundContactRequests = CallMeBackListController.getContactRequestsByCustomerId('', contacto.Name);

        Test.stopTest();

        // Asserts, en el makeData se le añaden 10 CR
        System.assertEquals(15, foundContactRequests.size(), 'Debería contener 15 CR');
    }

    
    @isTest
    static void test_getContactRequestsByName_ko()
    {
        String name = 'Nombre Test'; // Nombre de test que no existe
        // Test
        Test.startTest();
        try
        {
            List<ContactRequest> foundContactRequests = CallMeBackListController.getContactRequestsByCustomerId('3246525', name);

        }catch(Exception ex)
        {
            System.assertEquals('AuraHandledException', ex.getTypeName());
        }

        Test.stopTest();
    }
}