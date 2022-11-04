/**
 * Clases de test para Batch_ProcessExternalRequest
 **
 * @author nbizkarra
 * @date 03/04/2020
 */
@isTest
public class Test_Batch_ProcessExternalRequest
{
    /**
     * Metodo test que comprueba que el batch marca la request como procesada.
     **
     * @author nbizkarra
     * @date 03/04/2020
     */
    @isTest
    static void testBatch()
    {
        // Es nesecesario indicar que el standard pricebook está activo para que el procesamiento no falle
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        update standardPricebook;

        ExternalRequest__c request = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{"emailHash":"7815696ecbf1c96e6894b779456d330e","status":{"codeValue":"Active","code":"6","enumName":"CUSTOMER_STATUS"},"accountBalance":16.27,"masterPolicyDesc":"NESTLE EMPLEADOS","masterPolicySerial":"1031360100007742","gender":{"codeValue":"Male","code":"M","enumName":"GENDER"},"workerPosition":{"codeValue":"Administrador","code":"ADMINISTRATOR","enumName":"CUSTOMER_FLEX_6"},"cnoProfession":{"codeValue":"COREOGRAFOS Y BAILARINES","code":"P512_2514","enumName":"CUSTOMER_FLEX_3"},"profession":{"codeValue":"Actor, bailarín, músico and modelo","code":"P512","enumName":"CUSTOMER_FLEX_4"},"cardExpiryYear":"24","cardExpiryMonth":"01","cardFourDigits":"4242","citizenship":{"codeValue":"Spain","code":"ES","enumName":"CITIZENSHIP"},"country":{"codeValue":"Spain","code":"ES","enumName":"COUNTRY"},"cityArea":"BARCELONA","city":"Barcelona","postalCode":"08005","address1":"Carrer Mallorca 24","subagency":"Life Insurance","customerSerial":"1011360000008885","surname":"Alvarez","firstName":"Pablo","birthdate":"1990-01-01","mobilePhone":"651356666","primaryEmail":"test@test.com","ssn":"55658574P"}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        insert request;

        Test.startTest();
        Batch_ProcessExternalRequest b = new Batch_ProcessExternalRequest('select'); // for coverage
        b = new Batch_ProcessExternalRequest();
        Database.executeBatch(b, 1);
        Test.stopTest();

        request = [SELECT id, Processed__c FROM ExternalRequest__c];
        System.assertEquals(true, request.Processed__c);
    }

    /**
     * Test an exception because the pricebook is not found.
     *
     * @author nts (agonzalezisasi)
     * @date 28/oct/2020
     */
    @isTest
    static void testBatch_ko()
    {
        ExternalRequest__c request = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        insert request;

        Test.startTest();
        Batch_ProcessExternalRequest b = new Batch_ProcessExternalRequest();
        Database.executeBatch(b, 1);
        Test.stopTest();

        request = [SELECT id, Processed__c FROM ExternalRequest__c];
        System.assertEquals(true, request.Processed__c);
    }


    /**
     * For testing Schedule
     */
    @isTest
    static void testBatch_schedule()
    {
        Batch_ProcessExternalRequest m = new Batch_ProcessExternalRequest();
        String sch = '20 30 8 10 2 ?';

        Test.startTest();
        String jobID = system.schedule('Response External Request', sch, m);
        Test.stopTest();
        
    }
}