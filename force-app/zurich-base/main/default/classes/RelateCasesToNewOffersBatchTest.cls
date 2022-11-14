/**
 * Clase de test para el batch RelateCasesToNewOffersBatch
 * @author lrodriguez6@seidor.es
 * @date 14/11/2022
 */
@IsTest
public with sharing class RelateCasesToNewOffersBatchTest {
    @TestSetup
    static void makeData()
    {
        // Se crean cuentas 
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 10);
        insert accounts;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        CasesSelector casesSel = new CasesSelector();

        //Se crea oferta para relacionar
        Opportunity offer = new Opportunity();
        offer.AccountId=accounts[0].Id;
        offer.Name='Oferta Test';
        offer.StageName='Quoted';
        offer.CloseDate=System.today()+1;
        offer.InfoQuoteNumber__c='11111';
        insert offer;

        // Se crean casos con la misma oferta creada que la oferta, para que se relacionen
        for(Case currentCase : cases)
        {
            currentCase.RecordTypeId = casesSel.rtUSPId;
            currentCase.CreatedOffer__c = offer.InfoQuoteNumber__c;
        }
        insert cases;
    }

    @IsTest
    static void test_RelateCasesToNewAccounts_OK()
    {
        RelateCasesToNewOffersBatch batch = new RelateCasesToNewOffersBatch();

        List<Case> cases = [SELECT Id, OfferId__c FROM Case];

        // Se comprueba que no tenían ofertas relacionadas
        for(Case currentCase : cases)
        {
            System.assertEquals(null, currentCase.OfferId__c, 'No deberia haber oferta relacionada');
        }

        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        List<Case> updatedCases = [SELECT Id, OfferId__c FROM Case];

        // Se comprueba que el batch los ha relacionado yla oferta ha sido informada
        for(Case currentCase : updatedCases)
        {
            System.assertNotEquals(null, currentCase.OfferId__c, 'Deberia haber oferta relacionada');
        }
    }
}