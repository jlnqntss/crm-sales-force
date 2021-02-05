/**
 * Clase de test para FindCustomerByPhoneAction
 * 
 * @author rlopez
 * @date 27/01/2021
 */
@isTest(SeeAllData=false)
public with sharing class FindCustomerByPhoneActionTest
{
    @TestSetup
    static void createScenario(){
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<ContactPointPhone> contactPointPhones = TestDataFactory.generateContactPointPhonesFromScopes(scopes, 1);
        insert contactPointPhones;
    }

    /**
     * Comprueba que la acción invocable recupera correctamente
     * el Id del cliente que estamos buscando por teléfono
     * 
     * @author rlopez
     * @date 27/01/2021
     */
    @isTest
    static void test_findCustomerByPhoneAction_findByPhone_ok()
    {
        List<Scope__c> createdScopes = [SELECT Id FROM Scope__c];
        List<ContactPointPhone> contactPointPhoneToSearch = new ContactPointPhonesSelector(
            new Set<String>{'Id', 'TelephoneNumber', 'ParentId'}
        ).selectByScopeIdAndIsPrimary(new Set<Id>{createdScopes.get(0).Id}, true, null);

        Set<Id> recordIds = new Set<Id>();
        for(ContactPointPhone contactPoint : contactPointPhoneToSearch)
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        //Preparamos la Request
        List<FindCustomerByPhoneAction.FindCustomerByPhoneActionRequest> requests = new List<FindCustomerByPhoneAction.FindCustomerByPhoneActionRequest>();
        FindCustomerByPhoneAction.FindCustomerByPhoneActionRequest customerInformation = new FindCustomerByPhoneAction.FindCustomerByPhoneActionRequest();
        customerInformation.phone = contactPointPhoneToSearch.get(0).TelephoneNumber;
        customerInformation.scope = RecordsSelector.Scope.ZE.name();

        requests.add(customerInformation);

        Test.startTest();
        List<FindCustomerByPhoneAction.FindCustomerByPhoneActionResponse> results = FindCustomerByPhoneAction.findByPhone(requests);
        Test.stopTest();

        System.assertEquals(false, results.isEmpty(), 'List should NOT be empty');
        System.assertEquals(contactPointPhoneToSearch.get(0).ParentId, results.get(0).customerId, 'It should be the same Id');
    }

    /**
     * Comprueba que la acción invocable retorna una lista vacía
     * en caso de no encontrar un cliente con ese número de teléfono
     * 
     * @author rlopez
     * @date 27/01/2021
     */
    @isTest
    static void test_findCustomerByPhoneAction_findByPhone_notFound_ok()
    {
        //Preparamos la Request
        List<FindCustomerByPhoneAction.FindCustomerByPhoneActionRequest> requests = new List<FindCustomerByPhoneAction.FindCustomerByPhoneActionRequest>();
        FindCustomerByPhoneAction.FindCustomerByPhoneActionRequest customerInformation = new FindCustomerByPhoneAction.FindCustomerByPhoneActionRequest();
        customerInformation.phone = 'fakephone';
        customerInformation.scope = RecordsSelector.Scope.ZE.name();

        requests.add(customerInformation);

        Test.startTest();
        List<FindCustomerByPhoneAction.FindCustomerByPhoneActionResponse> results = FindCustomerByPhoneAction.findByPhone(requests);
        Test.stopTest();

        System.assertEquals(true, results.isEmpty(), 'List should be empty');
    }
}