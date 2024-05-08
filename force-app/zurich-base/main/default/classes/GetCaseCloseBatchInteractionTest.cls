@isTest
private class GetCaseCloseBatchInteractionTest {
    
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
        
        List<Case> cases = [SELECT Id,CloseInteractionBatch__c,ExpectedClosingDate__c FROM Case];

        List<String> stringIds= new List<String>();

        Integer cuenta=0;

        for(case c:cases)
        {
            stringIds.add(c.Id);
        }

        ListaFlowInputs.add(stringIds);

        
        // Test
        Test.startTest();

        GetCaseCloseBatchInteractions.getCaseCloseBatchInteractions(ListaFlowInputs);

        Test.stopTest();

        List<Case> cases2 = [SELECT Id,CloseInteractionBatch__c,ExpectedClosingDate__c FROM Case ];

        for(case c:cases2)
        {
            if(c.CloseInteractionBatch__c== true && c.ExpectedClosingDate__c==System.TODAY())
            {
                cuenta=cuenta+1;
            }
        }



        System.assertEquals(10,cuenta, 'no devuelve el número de registros correcto');
    }


}