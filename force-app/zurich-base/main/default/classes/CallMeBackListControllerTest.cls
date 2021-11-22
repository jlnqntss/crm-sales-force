/**
 * @description       : 
 * @author            : jjuaristi
 * @group             : 
 * @last modified on  : 19-11-2021
 * @last modified by  : jjuaristi
**/
@isTest
private class CallMeBackListControllerTest {

    @TestSetup
    public static void createScenario()
    {
        //Creamos la cuenta            
        List<Account> accounts = TestDataFactory.generateAccounts('Life insurance', 'Customer', 1);
        insert accounts;

        //Creamos los contactRequests asociados a esa cuenta 
        List<Account> createdAccounts = [SELECT PersonContactId FROM Account];
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
    }

    
    @isTest
    static void test_getContactRequestsById_ok()
    {
        //Obtenemos el whoId a enviar al controlador
        Account account = [SELECT Id, PersonContactId FROM Account LIMIT 1];

        // Test
        Test.startTest();

        List<ContactRequest> foundContactRequests = CallMeBackListController.getContactRequestsByCustomerId(account.PersonContactId);

        Test.stopTest();

        // Asserts, en el makeData se le añaden 10 CR
        System.assertEquals(10, foundContactRequests.size(), 'Debería contener 10 CR');
    }

    @isTest
    static void test_getContactRequestsById_ko()
    {
        // Test
        Test.startTest();
        try
        {
            List<ContactRequest> foundContactRequests = CallMeBackListController.getContactRequestsByCustomerId('3246525');

        }catch(Exception ex)
        {
            System.assertEquals('AuraHandledException', ex.getTypeName());
        }

        Test.stopTest();
    }
}