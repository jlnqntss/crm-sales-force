@isTest
public class GenerateHashIdActionTest
{
    @TestSetup
    static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;
    }

    @isTest
    static void test_GenerateHashIdAction_execute_ok()
    {
        // Datos petición
        Case relatedCase = [SELECT Id FROM Case LIMIT 1];
        System.assertEquals(true, relatedCase != null, 'Case exists');

        Test.startTest();
        List<GenerateHashIdAction.GenerateHashIdActionRequest> requests = new List<GenerateHashIdAction.GenerateHashIdActionRequest>();

        GenerateHashIdAction.GenerateHashIdActionRequest req = new GenerateHashIdAction.GenerateHashIdActionRequest();

        req.recordId = relatedCase.Id;
        requests.add(req);

        List<GenerateHashIdAction.GenerateHashIdActionResponse> results = GenerateHashIdAction.generateHash(requests);
        Test.stopTest();

        System.assertEquals(false, results.isEmpty(), 'List is not empty');
        System.assertEquals(true, results.get(0).hashId != null, 'HashId generated');
    }
}