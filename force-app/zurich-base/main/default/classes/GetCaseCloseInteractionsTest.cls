@isTest
private with sharing class GetCaseCloseInteractionsTest {
    
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

        Integer cuenta=0;

        for(case c:cases)
        {
            stringIds.add(c.Id);
        }

        ListaFlowInputs.add(stringIds);

        
        // Test
        Test.startTest();

        GetCaseCloseInteractions.getCaseCloseInteractions(ListaFlowInputs);

        Test.stopTest();

        List<Case> cases2 = [SELECT Id,CloseInteraction__c FROM Case ];

        for(case c:cases2)
        {
            if(c.CloseInteraction__c==true)
            {
                cuenta=cuenta+1;
            }
        }



        System.assertEquals(10,cuenta, 'no devuelve el número de registros correcto');
    }


}