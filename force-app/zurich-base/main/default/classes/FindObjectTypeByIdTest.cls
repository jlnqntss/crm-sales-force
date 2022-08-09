/**
 * Clase de test para FindObjectTypeById
 * 
 * @author palegria
 * @date 14/07/2022
 */
@isTest(SeeAllData=false)
public with sharing class FindObjectTypeByIdTest
{
    /**
     * Comprueba que la acción invocable recupera correctamente el sObject Type.
     * 
     * @author palegria
     * @date 14/07/2022
     */
    @isTest
    static void test_findObjectTypeById_findObjectType_ok()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        //Preparamos la Request
        List<FindObjectTypeById.FindObjectTypeByIdRequest> requestsList = new List<FindObjectTypeById.FindObjectTypeByIdRequest>();
        FindObjectTypeById.FindObjectTypeByIdRequest request = new FindObjectTypeById.FindObjectTypeByIdRequest();
        request.id = accounts[0].Id;
        requestsList.add(request);

        Test.startTest();
        List<FindObjectTypeById.FindObjectTypeByIdResponse> results = FindObjectTypeById.findObjectType(requestsList);
        Test.stopTest();

        System.assertEquals(false, results.isEmpty(), 'List should NOT be empty');
        System.assertEquals('Account', results.get(0).objectType, 'It should be Account');
    }
}