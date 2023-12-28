/**
 * Clases de test para Batch_DeleteExternalRequest
 **
 * @author nbizkarra
 * @change adelgado 13/11/2020 Cambios en tests y escenario para nuevos requerimientos OCS
 * @date 27/04/2020
 */
@isTest
private class Test_Batch_DeleteExternalRequest
{

    /**
     * Create test data
     **
     * @author nbizkarra
     * @change adelgado 13/11/2020 Cambios en generación de escenario para hacer uso de la clase TestDataFactory
     * @date 27/04/2020
     */
    @TestSetup
    static void makeData()
    {
        
        List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

        //External request procesadas
        externalRequestList.addAll( TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 15) );
        externalRequestList.addAll( TestDataFactory.generateExternalRequest('IBA', 'NATURAL_ACCOUNT', 15) );

        Datetime customDateTime = Datetime.now().addDays(-10);

        for(ExternalRequest__c externalRequest : externalRequestList)
        {
            externalRequest.Processed__c = true;
            externalRequest.ProcessedDate__c = customDateTime;
        }

        //External request no procesadas
        externalRequestList.addAll( TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 15) );
        externalRequestList.addAll( TestDataFactory.generateExternalRequest('IBA', 'NATURAL_ACCOUNT', 15) );

        insert externalRequestList;

        Datetime fechaHora10KO = System.today() - 10;
        Datetime fechaHora4KO = System.today() - 4;
        Datetime fechaHora2OK = System.today() - 2;
        Datetime fechaHoraHoyOK = System.today();

        List<ExternalRequest__c> requests = new List<ExternalRequest__c>();

        for (Integer i = 1; i <= 10; i++) {
            requests.add(
                new ExternalRequest__c(
                Country__c = 'test',
                Entity__c = 'Claim', 
                Origin__c = 'IBA',
                Processed__c = true,
                ProcessedDate__c = fechaHora10KO,
                ProcessResult__c = 'KO'
                )
            );
        }

        for (Integer i = 1; i <= 20; i++) {
            requests.add(
                new ExternalRequest__c(
                Country__c = 'test',
                Entity__c = 'Claim', 
                Origin__c = 'IBA',
                Processed__c = true,
                ProcessedDate__c = fechaHora4KO,
                ProcessResult__c = 'KO'
                )
            );
        }

        for (Integer i = 1; i <= 30; i++) {
            requests.add(
                new ExternalRequest__c(
                Country__c = 'test',
                Entity__c = 'Claim', 
                Origin__c = 'IBA',
                Processed__c = true,
                ProcessedDate__c = fechaHora2OK,
                ProcessResult__c = 'OK'
                )
            );
        }

        for (Integer i = 1; i <= 40; i++) {
            requests.add(
                new ExternalRequest__c(
                Entity__c = 'Claim', 
                Origin__c = 'IBA',
                Country__c = 'test',
                Processed__c = true,
                ProcessedDate__c = fechaHoraHoyOK,
                ProcessResult__c = 'OK'
                )
            );
        }

        insert requests;
    }

    /**
     * Comprobar que el batch elimina solo registros de external request procesados cuyo origen sea INFO
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    static void test_EliminarRequestsProcesadas_INFO()
    {
        Integer numReqPreBatch = [SELECT COUNT() FROM ExternalRequest__c];

        String query = 'SELECT Id FROM ExternalRequest__c WHERE Processed__c = true AND Origin__c = \'INFO\'';

        Test.startTest();
        database.executeBatch(new Batch_DeleteExternalRequest(query), 200);
        Test.stopTest();

        Integer numReqAfterBatch = [SELECT COUNT() FROM ExternalRequest__c];

        System.assertEquals(numReqPreBatch - 55, numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
    }

    /**
     * Comprobar que el batch elimina solo registros de external request procesados cuyo origen sea IBA
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    static void test_EliminarRequestsProcesadas_IBA()
    {
        Integer numReqPreBatch = [SELECT COUNT() FROM ExternalRequest__c];

        String query = 'SELECT Id FROM ExternalRequest__c WHERE Processed__c = true AND Origin__c = \'IBA\'';

        Test.startTest();
        database.executeBatch(new Batch_DeleteExternalRequest(query), 200);
        Test.stopTest();

        Integer numReqAfterBatch = [SELECT COUNT() FROM ExternalRequest__c];

        System.assertEquals(numReqPreBatch - 115, numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
    }

    /**
     * Comprobar que el batch elimina todos los registros de external request procesados independientemente del origen
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    static void test_EliminarRequestsProcesadas()
    {
        Integer numReqPreBatch = [SELECT COUNT() FROM ExternalRequest__c];

        String query = 'SELECT Id FROM ExternalRequest__c WHERE Processed__c = true';

        Test.startTest();
        database.executeBatch(new Batch_DeleteExternalRequest(query), 200);
        Test.stopTest();

        Integer numReqAfterBatch = [SELECT COUNT() FROM ExternalRequest__c];

        System.assertEquals(numReqPreBatch - 130, numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
    }

    /**
     * Comprobar que el batch elimina todos los registros de external request creadas antes del número de días indicado en el metadato personalizado
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    static void test_EliminarRequests_Metadato()
    {

        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        System.assertNotEquals(null, adminSetup.RetentionExternalRequestKO__c, 'Metadato No existe');
        System.assertNotEquals(null, adminSetup.RetentionExternalRequestOK__c, 'Metadato No existe');

        Integer numReqPreBatchKO = new ExternalRequestsSelector().count(null, 0,'KO');
        Integer numReqPreBatchOK = new ExternalRequestsSelector().count(null, 0,'OK');

        Test.startTest();
        database.executeBatch(new Batch_DeleteExternalRequest(), 200);
        Test.stopTest();

        Integer numReqAfterBatchKO = new ExternalRequestsSelector().count(null, 0, 'KO');
        Integer numReqAfterBatchOK = new ExternalRequestsSelector().count(null, 0, 'OK');

        System.assertEquals(numReqPreBatchKO,30,'Error  KO pre');
        System.assertEquals(numReqPreBatchOK,70,'Error  OK pre');
        System.assertEquals(numReqAfterBatchOK,40,'Error  ok after');
        System.assertEquals(numReqAfterBatchKO,20,'Error  KO after');
    }
    
    /**
     * Comprobar la programación del batch sin pasar una query como parámetro
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    static void testBatch_schedule_noQuery()
    {
        Test.startTest();
        String jobID = system.schedule( 'Delete External Request Test', '20 30 8 10 2 ?', new Batch_DeleteExternalRequest() );
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }

    /**
     * Comprobar la programación del batch sin pasar una query como parámetro
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    static void testBatch_schedule_customQuery()
    {
        Test.startTest();
        String jobID = system.schedule( 'Delete External Request Test', '20 30 8 10 2 ?', new Batch_DeleteExternalRequest('SELECT Id FROM ExternalRequest__c WHERE Processed__c = true') );
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }

    /**
     * Comprobar la programación del batch
     * *
     * @author adelgado
     * @date 03/12/2020
     */
    @isTest
    static void testBatch_scheduleExternalRequestClearOcs_Params()
    {
        Test.startTest();
        String jobID = Batch_DeleteExternalRequest.scheduleExternalRequestClearOcs();
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }

    @isTest
    static void testBatch_scheduleExternalRequestClearKlinc_Params()
    {
        Test.startTest();
        String jobID = Batch_DeleteExternalRequest.scheduleExternalRequestClearKlinc();
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }

    /**
     * Comprobar la programación del batch
     * *
     * @author adelgado
     * @date 03/12/2020
     */
    @isTest
    static void testBatch_scheduleExternalRequestErrorClear_Params()
    {
        Test.startTest();
        String jobID = Batch_DeleteExternalRequest.scheduleExternalRequestErrorClear();
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }
}