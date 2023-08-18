/**
 * Clase de test para el batch Batch_DeleteOffers
 * @author lrodriguez6@seidor.es
 * @date 14/08/2023
 */
@IsTest
public with sharing class Batch_DeleteFieldsTest {
    @TestSetup
    static void makeData()
    {
        // Se crea una cuenta para vincularla con las Ofertas 
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 1);
    
        insert accounts;


        //Se crean las ofertas a borrar posteriormente
        List<Opportunity> opps = TestDataFactory.generateOpportunities(accounts,'USP','Legit Lead',System.today()+5,200);
        for (Integer i=0;i<opps.size();i++)
        {
            opps[i].Name='OFERTA '+i;
            opps[i].Description='TEST DESCRIPCIÓN';
        }
        insert opps;
    }

    @IsTest
    static void test_DeleteFields_OK()
    {
        List<String> parame= new  List<String>();
        parame.add('OfferDeleteTemplate');
        parame.add('Name');
        parame.add('Opportunity');
        Batch_DeleteFields batch = new Batch_DeleteFields(parame);

        List<Opportunity> opps = [SELECT Id FROM Opportunity];

        // Se comprueba que existían 200 Ofertas
        System.assertEquals(200, opps.size(), 'Existen 200 Ofertas');
        

        Test.startTest();
        Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        List<Opportunity> opps2 = [SELECT Id,Description FROM Opportunity WHERE Id IN:Opps];

        // Se comprueba que el batch ha borrado las Ofertas
        System.assertEquals(0, opps2.size(), 'Borrado ok');

    }
}