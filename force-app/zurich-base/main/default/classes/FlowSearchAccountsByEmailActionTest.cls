@isTest
private class FlowSearchAccountsByEmailActionTest {

    @TestSetup
    public static void createScenario()
    {
        //Customers
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<ContactPointEmail> contactPointEmails = TestDataFactory.generateContactPointEmailsFromAccounts(accounts, 1);
        insert contactPointEmails;

        //Intermediary-> NO tienen ContactPointPhones!!!
        List<Account> intermediaryAccounts = TestDataFactory.generateAccounts('001', 'Intermediary', 10);
        insert intermediaryAccounts;
    }

    /**
     * Test para probar si se recibe la información de las cuentas a través de su email
     */
    @isTest
    static void test_execute_ok()
    {
        // SOSL - Resultados de búsqueda
        List<String> emailsToSearch = new List<String>();
        Set<Id> recordIds = new Set<Id>();
        for(ContactPointEmail contactPoint : [SELECT Id, ParentId, ContactId__c, EmailAddress FROM ContactPointEmail])
        {
            recordIds.add(contactPoint.ParentId);
            recordIds.add(contactPoint.Id);
            emailsToSearch.add(contactPoint.EmailAddress);
        }
        Test.setFixedSearchResults( new List<Id>(recordIds) );

        // Test
        Test.startTest();
        List<FlowSearchAccountsByEmailAction.AccountEmailRequest> accountEmailRequests = new List<FlowSearchAccountsByEmailAction.AccountEmailRequest>();
        FlowSearchAccountsByEmailAction.AccountEmailRequest accountRequest = new FlowSearchAccountsByEmailAction.AccountEmailRequest();
        accountRequest.caseEmail = emailsToSearch[0]; //un email que esté dentro de los que encuentra la SOSL
        accountRequest.caseScope = null;//null equivale a todo el scope
        accountEmailRequests.add(accountRequest);
        List<FlowSearchAccountsByEmailAction.AccountEmailResult> matchedRecords = FlowSearchAccountsByEmailAction.execute(accountEmailRequests);
        Test.stopTest();

        //Comprobamos que la búsqueda ha funcionado y no tenemos una lista vacia
        System.assertEquals(false, matchedRecords.isEmpty(), 'SOSL shouldnt be empty');

        // Then
        Map<Id, Account> expectedAccountsById = new Map<Id, Account>(AccountsSelector.selectById(recordIds, new Set<String> {'Id'}) );

        List<String> ids = matchedRecords[0].AccountIds;
        for(String accountId : ids)
        {
            System.assertEquals(true, expectedAccountsById.containsKey(accountId), 'Map should contains the record Id');
        }
    }

    /**
     * Comprueba que si se le pasa un email inventado, devuelve una lista de IDs vacía
     */
    @isTest
    static void test_execute_ko()
    {
        // Test
        Test.startTest();
        List<FlowSearchAccountsByEmailAction.AccountEmailRequest> accountEmailRequests = new List<FlowSearchAccountsByEmailAction.AccountEmailRequest>();
        FlowSearchAccountsByEmailAction.AccountEmailRequest accountRequest = new FlowSearchAccountsByEmailAction.AccountEmailRequest();
        accountRequest.caseEmail = 'noexisteesteemail@entrelosbuscados.com'; //email que no existe en lo que devuelve el SOSL
        accountRequest.caseScope = null;//null equivale a todo el scope
        accountEmailRequests.add(accountRequest);
        List<FlowSearchAccountsByEmailAction.AccountEmailResult> matchedRecords = FlowSearchAccountsByEmailAction.execute(accountEmailRequests);
        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista
        List<String> ids = matchedRecords[0].AccountIds;
        System.assertEquals(true, ids.isEmpty(), 'no debe devolver nada');
    }

}
