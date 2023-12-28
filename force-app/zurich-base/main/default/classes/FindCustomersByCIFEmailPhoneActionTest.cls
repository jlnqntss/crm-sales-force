/**
 * @description       : Clase de test para la acción FindCustomersByCIFEmailPhoneAction
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 06-06-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class FindCustomersByCIFEmailPhoneActionTest 
{
    @TestSetup
    private static void createScenario()
    {
        //Customers
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        accounts[0].NationalId__c = '78432734C';
        accounts[0].Type = 'F';
        accounts[1].NationalId__c = '78432734C';
        accounts[1].Type = 'F';
        insert accounts;

        List<ContactPointEmail> contactPointEmailsToInsert = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 1);
        insert contactPointEmailsToInsert;

        List<ContactPointPhone> contactPointPhonesToInsert = TestDataFactory.generateContactPointPhonesFromAccounts (accounts, 1);
        insert contactPointPhonesToInsert;

        List<Account> businessAccounts = TestDataFactory.generateAccounts('001', 'BusinessCustomer', 1);
        businessAccounts[0].NationalId__c = '78432734C';
        insert businessAccounts;
    }

    /**
     * Comprueba que la acción invocable recupera correctamente las cuentas cuyo national Id coincide con el del caso
     * 
     * @author aberuete
     * @date 01/06/2023
     */
    @isTest
    private static void findAccountsByCif() 
    {
        List<Account> accounts = [Select id from Account where NationalId__c = '78432734C'];
        List<ContactPointEmail> contactPointEmails = [SELECT Id, ParentId, ContactId__c, EmailAddress FROM ContactPointEmail];
        List<ContactPointPhone> contactPointPhones = [SELECT Id, ParentId, ContactId__c, TelephoneNumber FROM ContactPointPhone];

        Test.startTest();
        List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest> accountRequests = new List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest>();
        FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest accountRequest = new FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest();
        accountRequest.caseCIF = '78432734C';
        accountRequest.caseEmail = contactPointEmails[5].EmailAddress;
        accountRequest.casePhone = contactPointPhones[5].TelephoneNumber;
        accountRequests.add(accountRequest);
        List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailorPhoneActionResponse> matchedRecords = FindCustomersByCIFEmailPhoneAction.findByCIFOrEmailOrPhone(accountRequests);
        Test.stopTest();

        System.assertEquals(2, matchedRecords[0].AccountIds.size(), 'Debería haber dos ids de cuentas');
        System.assertEquals(true, matchedRecords[0].AccountIds.contains(accounts[0].id), 'La lista de ids devuelta no es correcta');
        System.assertEquals(true, matchedRecords[0].AccountIds.contains(accounts[1].id), 'La lista de ids devuelta no es correcta');
    }

    /**
     * Comprueba que la acción invocable recupera correctamente las cuentas que están relacionas con contactPointEmails cuyo email coincida con el del caso
     * 
     * @author aberuete
     * @date 01/06/2023
     */
    @isTest
    private static void findAccountsByEmail() 
    {
        List<ContactPointPhone> contactPointPhones = [SELECT Id, ParentId, ContactId__c, TelephoneNumber FROM ContactPointPhone];

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

        Test.startTest();
        List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest> accountRequests = new List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest>();
        FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest accountRequest = new FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest();
        accountRequest.caseCIF = 'mal';
        accountRequest.caseEmail = emailsToSearch[0];
        accountRequest.casePhone = contactPointPhones[5].TelephoneNumber;
        accountRequests.add(accountRequest);
        List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailorPhoneActionResponse> matchedRecords = FindCustomersByCIFEmailPhoneAction.findByCIFOrEmailOrPhone(accountRequests);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'El resultado devuelto no debería estar vacío');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(new AccountsSelector().selectById(recordIds) );

        List<String> ids = matchedRecords[0].AccountIds;
        for(String accountId : ids)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(accountId), 'El mapa debería tener el record id');
        }
    }

    /**
     * Comprueba que la acción invocable recupera correctamente las cuentas que están relacionas con contactPointPhones cuyo teléfono coincida con el del caso
     * 
     * @author aberuete
     * @date 01/06/2023
     */
    @isTest
    private static void findAccountsByPhone() 
    {
        // SOSL - Resultados de búsqueda
        List<String> phonesToSearch = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(ContactPointPhone contactPoint : [SELECT Id, ParentId, ContactId__c, TelephoneNumber FROM ContactPointPhone])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
            phonesToSearch.add(contactPoint.TelephoneNumber);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        Test.startTest();
        List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest> accountRequests = new List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest>();
        FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest accountRequest = new FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailOrPhoneActionRequest();
        accountRequest.caseCIF = 'mal';
        accountRequest.caseEmail = 'noexisteesteemail@entrelosbuscados.com';
        accountRequest.casePhone = phonesToSearch[0];
        accountRequests.add(accountRequest);
        List<FindCustomersByCIFEmailPhoneAction.FindCustomerByCIFOrEmailorPhoneActionResponse> matchedRecords = FindCustomersByCIFEmailPhoneAction.findByCIFOrEmailOrPhone(accountRequests);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'El resultado devuelto no debería estar vacío');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(new AccountsSelector().selectById(recordIds) );

        List<String> ids = matchedRecords[0].AccountIds;
        for(String accountId : ids)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(accountId), 'El mapa debería tener el record id');
        }
    }
}