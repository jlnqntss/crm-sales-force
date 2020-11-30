@isTest
private class CasesSelectorTest 
{
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 10);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;
    }

    @isTest
    static void test_findOpenByAccount_matchedRecords()
    {
        Id intermediaryRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Intermediary').getRecordTypeId();
        List<Account> accountsToSearch = [SELECT Id, INFOIntermediaryCode__c, RecordTypeId FROM Account WHERE RecordTypeId =: intermediaryRecordTypeId];

        List<String> accountIds = new List<String>();
        for(Account acc : accountsToSearch)
        {
            accountIds.add(acc.Id);
        }

        // Test
        Test.startTest();

        List<Case> matchedRecords = new CasesSelector().findOpenByAccount(accountIds);

        Test.stopTest();

        System.assertEquals(10, matchedRecords.size(), 'no devuelve el número de registros correcto');   
    }

    @isTest
    static void test_findOpenByAccount_notFound()
    {
        // Test
        Test.startTest();

        List<Case> matchedRecords = new CasesSelector().findOpenByAccount(new List<String>());

        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista de teléfonos
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }
}