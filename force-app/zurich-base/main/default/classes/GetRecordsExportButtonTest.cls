@isTest
private with sharing class GetRecordsExportButtonTest {
    
    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 10);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        insert cases;

    }

    @isTest
    static void test_checkTrue_OK()
    {
        List<List<String>> ListaFlowInputs = new List<List<String>>();

        List<Case> cases = [SELECT Id FROM Case];

        List<String> stringIds= new List<String>();

        for(case c:cases)
        {
            stringIds.add(c.Id);
        }

        ListaFlowInputs.add(stringIds);

        Test.startTest();
        GetRecordsExportButton.GetRecordsExportButton(ListaFlowInputs);
        Test.stopTest();

        List<ContentVersion> ContentVersionList = [SELECT Id,Title FROM ContentVersion WHERE Title='Export.csv'];

        System.assertEquals(1,ContentVersionList.size(), 'no devuelve el número de registros correcto');

    }
}