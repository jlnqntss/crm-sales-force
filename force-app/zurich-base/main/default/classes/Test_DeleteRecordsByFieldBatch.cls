/**
 * @description       :
 * @author            : jgallaga
 * @group             :
 * @last modified on  : 05/09/2023
 * @last modified by  : jgallaga
**/
@isTest
public class Test_DeleteRecordsByFieldBatch
{
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
        // Se comprueba que existían 200 Ofertas
        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        System.assertEquals(200, opps.size(), 'Existen 200 Ofertas');

        DeleteRecordsByFieldBatch batch = new DeleteRecordsByFieldBatch('OfferDeleteTemplate', Opportunity.Name);

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Se comprueba que el batch ha borrado las Ofertas
        List<Opportunity> opps2 = [SELECT Id,Description FROM Opportunity WHERE Id IN:Opps];
        System.assertEquals(0, opps2.size(), 'Borrado ok');
    }

    @isTest
    static void test_parameterNull_KO()
    {
        String mensajeParametroNulo = 'El Batch debe crear una excepción si recibe parametros nulos';
        String mensajeError = 'La excepción recibida no es la esperada';

        Test.startTest();
        DeleteRecordsByFieldBatch batch;

        try
        {
            batch =new DeleteRecordsByFieldBatch(null, Opportunity.Name);
            Assert.fail(mensajeParametroNulo);

        }
        catch(IllegalArgumentException nullParamError)
        {
            Assert.isTrue(nullParamError.getMessage().contains(DeleteRecordsByFieldBatch.NULL_PARAMETER_EXCEPTION_MSG), 'El mensaje de error no es correcto');
        }
        catch(Exception unspectedError)
        {
            Assert.fail(mensajeError);
        }

        try
        {
            batch =new DeleteRecordsByFieldBatch(null, null);
            Assert.fail(mensajeParametroNulo);
        }
        Catch(IllegalArgumentException nullParamError)
        {
            Assert.isTrue(nullParamError.getMessage().contains(DeleteRecordsByFieldBatch.NULL_PARAMETER_EXCEPTION_MSG), 'El mensaje de error no es correcto');
        }
        Catch(Exception unspectedError)
        {
            Assert.fail(mensajeError);
        }

        try
        {
            batch = new DeleteRecordsByFieldBatch('filename', null);
            Assert.fail(mensajeParametroNulo);
        }
        Catch(IllegalArgumentException nullParamError)
        {
            Assert.isTrue(nullParamError.getMessage().contains(DeleteRecordsByFieldBatch.NULL_PARAMETER_EXCEPTION_MSG), 'El mensaje de error no es correcto');
        }
        Catch(Exception unspectedError)
        {
            Assert.fail(mensajeError);
        }

        Test.stopTest();
    }

}