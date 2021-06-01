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
        externalRequestList.addAll( TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 30) );
        externalRequestList.addAll( TestDataFactory.generateExternalRequest('IBA', 'NATURAL_ACCOUNT', 30) );

        Datetime customDateTime = Datetime.now().addDays(-10);

        for(ExternalRequest__c externalRequest : externalRequestList)
        {
            externalRequest.Processed__c = true;
            externalRequest.ProcessedDate__c = customDateTime;
        }

        //External request no procesadas
        externalRequestList.addAll( TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 30) );
        externalRequestList.addAll( TestDataFactory.generateExternalRequest('IBA', 'NATURAL_ACCOUNT', 30) );

        insert externalRequestList;
    }

    /**
     * Este método de test llama al Batch con query personalizada, para borrar los requests cuyo processed date mayor que 600 dias.
       No se borra ningún registro.
     **
     * @author nbizkarra
     * @date 27/04/2020
     * @change adelgado 13/11/2020
     */
    @isTest
    static void test_NoEliminarRequests()
    {
        Integer numReqPreBatch = [SELECT COUNT() FROM ExternalRequest__c];

        String query = 'SELECT Id FROM ExternalRequest__c WHERE Processed__c = true AND ProcessedDate__c < LAST_N_DAYS:600';

        Test.startTest();
        database.executeBatch(new Batch_DeleteExternalRequest(query), 200);
        Test.stopTest();

        Integer numReqAfterBatch = [SELECT COUNT() FROM ExternalRequest__c];

        System.assertEquals(numReqPreBatch, numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
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

        System.assertEquals(numReqPreBatch - 30, numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
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

        System.assertEquals(numReqPreBatch - 30, numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
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

        System.assertEquals(numReqPreBatch - 60, numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
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
        Integer numReqPreBatch = [SELECT COUNT() FROM ExternalRequest__c];

        Test.startTest();
        database.executeBatch(new Batch_DeleteExternalRequest(), 200);
        Test.stopTest();

        Integer numReqAfterBatch = [SELECT COUNT() FROM ExternalRequest__c];

        System.assertEquals(numReqPreBatch, numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
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