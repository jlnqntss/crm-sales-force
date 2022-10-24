/**
 * Clase de test para el batch RelateCasesToNewAccountsBatch
 * @author jjuaristi@seidor.es
 * @date 20/10/2022
 */
@IsTest
public with sharing class RelateCasesToNewAccountsBatchTest {
    @TestSetup
    static void makeData()
    {
        // Se crean cuentas con cif
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 10);
        insert accounts;
        String cif = accounts[0].NationalId__c;
        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        CasesSelector casesSel = new CasesSelector();
        // Se crean casos con el cif de la primera cuenta, para que se relacionen
        for(Case currentCase : cases)
        {
            currentCase.RecordTypeId = casesSel.rtUSPId;
            currentCase.RobotDocumentId__c = cif;
        }
        insert cases;
    }

    @IsTest
    static void test_RelateCasesToNewAccounts_OK()
    {
        RelateCasesToNewAccountsBatch batch = new RelateCasesToNewAccountsBatch();

        List<Case> cases = [SELECT Id, MediatedCustomer__c FROM Case];

        // Se comprueba que no tenían clientes relacionado
        for(Case currentCase : cases)
        {
            System.assertEquals(null, currentCase.MediatedCustomer__c, 'No deberia haber customer');
        }

        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        List<Case> updatedCases = [SELECT Id, MediatedCustomer__c FROM Case];

        // Se comprueba que el batch los ha relacionado
        for(Case currentCase : updatedCases)
        {
            System.assertNotEquals(null, currentCase.MediatedCustomer__c, 'Deberia haber customer');
        }
    }
}
