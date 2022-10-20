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

        List<Case> matchedRecords = new CasesSelector().findOpenByAccount(new List<String>() );

        Test.stopTest();

        //Debe devolver una lista vacía de accounts porque se pasó vacía la lista de teléfonos
        System.assertEquals(true, matchedRecords.isEmpty(), 'no debe devolver nada');
    }


    @isTest
    static void test_findById_matchedRecord()
    {
        List<Case> casos = [SELECT Id FROM Case];
        Set<String> casosIds = new Set<String>();
        casosIds.add(casos.get(0).Id);

        // Test
        Test.startTest();
        List<Case> matchedRecords = new CasesSelector().findById(casosIds);
        Test.stopTest();

        System.assertEquals(casosIds.size(), matchedRecords.size(), 'no devuelve el número de registros correcto');
    }

    @isTest
    static void test_findById_notFound()
    {
        Set<String> casosIds = new Set<String>();
        casosIds.add('500AAAAAAAAAAAAAAA'); // ponemos un Id inventado

        // Test
        Test.startTest();
        List<Case> matchedRecords = new CasesSelector().findById(casosIds);
        Test.stopTest();

        System.assertEquals(0, matchedRecords.size(), 'No debe devolver ningún Caso');
    }

    /**
     * Test del método que devuelve el queryString para RelateCasesToNewAccountsBatch
     * @author jjuaristi@seidor.es
     * @date 20/10/2022
     */
    @isTest
    static void test_getQueryStringCasesToRelateToNewAccounts_matchedRecord()
    {
        CasesSelector casesSel = new CasesSelector();
        List<Case> casos = [SELECT Id, RobotDocumentId__c FROM Case];
        casos[0].RobotDocumentId__c = '2341341';
        casos[1].RobotDocumentId__c = '2341341';

        // Solo el primer caso tendrá recordType USP, de esta manera comprobamos que solo aplica a USP
        casos[0].RecordTypeId = casesSel.rtUSPId;
        update casos;

        // Test
        Test.startTest();
        String query = new CasesSelector().getQueryStringCasesToRelateToNewAccounts('5');
        System.debug(query);
        List<Case> matchedRecords = (List<Case>) Database.query(query);
        Test.stopTest();

        System.assertEquals(1, matchedRecords.size(), 'no devuelve el número de registros correcto');
    }
}