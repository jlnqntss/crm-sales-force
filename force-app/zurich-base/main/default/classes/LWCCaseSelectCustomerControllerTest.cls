@isTest
private class LWCCaseSelectCustomerControllerTest {

    @TestSetup
    public static void createScenario()
    {
        //Customers
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        //Intermediary-> NO tienen ContactPointPhones!!!
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts('001', 'Intermediary', 10);
        insert intermediaryAccounts;
    }

    /**
     * Prueba a pasar una lista vacía para ver que devuelve una lista vacía y no un error
     */
    @isTest
    static void test_getAccountsInfo_ko()
    {
        Test.startTest();

        List<Account> selectedAccounts = LWCCaseSelectCustomerController.getAccountsInfo(new List<String>());

        Test.stopTest();

        System.assertEquals(true, selectedAccounts.isEmpty(), 'Se debería recibir una lista vacía');
    }

    /**
     * Prueba a recibir la info de las cuentas que se han pedido
     */
    @isTest
    static void test_getAccountsInfo_ok()
    {
        // When
        Set<Id> accountIds = new Map<Id, Account>( [SELECT Id FROM Account] ).keySet();
        List<String> idsFromLWC = new List<String>();
        for(Id idToString: accountIds)
        {
            idsFromLWC.add(String.valueOf(idToString));
        }

        // Test
        Test.startTest();

        Map<Id, Account> selectedAccountsById = new Map<Id, Account>(LWCCaseSelectCustomerController.getAccountsInfo(idsFromLWC));

        Test.stopTest();

        // Then
        System.assertEquals(true, !selectedAccountsById.isEmpty(), 'Se debería recibir una lista no vacía');
        System.assertEquals(accountIds.size(), selectedAccountsById.keySet().size(), 'Se debería recibir el mismo número de cuentas');
        System.assertEquals(true, selectedAccountsById.keySet().containsAll(accountIds), 'No contiene todos los ids de cuenta');
    }
}
