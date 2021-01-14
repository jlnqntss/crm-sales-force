@isTest
private class PolicyUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada póliza
     *
     * @author adelgado
     * @date 08/01/2021
     */
    @isTest
    static void test_generateScope()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);

        Test.startTest();
        insert policies;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];
        List<Policy__c> policiesUpdated = [SELECT Scope__c, ScopeId__c FROM Policy__c];

        System.assertEquals(10, scopes.size(), 'No se han generado todos los ámbitos necesarios');
        System.assertEquals(10, policiesUpdated.size(), 'No se han generado todas las pólizas');

        for(Policy__c policy : policiesUpdated)
        {
            System.assert (String.isNotBlank(policy.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (policy.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }
}
