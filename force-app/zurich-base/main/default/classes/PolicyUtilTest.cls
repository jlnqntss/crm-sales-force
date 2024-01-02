@isTest
private class PolicyUtilTest
{
    private static final String BUSINESS_CODE = '320000001';

    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;
        accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'PartnerOCS', 1);
        accounts[0].INFOBusinessCode__c = BUSINESS_CODE;
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
        List<Account> accounts = [SELECT Name FROM Account WHERE RecordType.DeveloperName = 'BusinessCustomer'];

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

    /**
     * Test que comprueba la generación del partner correspondiente para cada poliza
     *
     * @author nts (agonzalezisasi)
     * @date 10/05/2021
     */
    @isTest
    static void test_generatePartner()
    {
        List<Account> accounts = [SELECT Name FROM Account WHERE RecordType.DeveloperName != 'PartnerOCS'];

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        policies[0].BusinessCode__c = BUSINESS_CODE;

        Test.startTest();
        insert policies;
        Test.stopTest();

        List<Policy__c> policiesWithPartner = [SELECT Id FROM Policy__c WHERE Partner__c != null];
        System.assertEquals(1, policiesWithPartner.size(), 'No se ha informado del partner de la poliza');
    }
}
