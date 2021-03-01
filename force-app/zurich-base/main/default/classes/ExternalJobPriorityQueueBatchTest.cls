/**
 * Test class for ExternalJobPriorityQueueBatch class.
 * 
 * @author nts (agonzalezisasi)
 * @date 12/02/2021
 */
@isTest
private class ExternalJobPriorityQueueBatchTest
{
    @TestSetup
    static void makeData()
    {
        List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

        //Personas físicas
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'NOTE', 200)
            );

        insert externalRequestList;
    }

    /**
     * Método test que válida la correcta ejecución de las external request cuyo origen sea recibido por parámetro
     * Lógica correspondiente a INFO se valida en la clase INFOHandlerTest
     **
     * @author adelgado
     * @date 15/10/2020
     */
    @isTest
    static void test_execute_Origin()
    {
        Test.startTest();
        ExternalJobPriorityQueueBatch ejqb = new ExternalJobPriorityQueueBatch('INFO');
        Id batchId = Database.executeBatch(ejqb);
        Test.stopTest();

        List<ExternalRequest__c> erProcessed = new ExternalRequestsSelector().selectProcessedByOrigin(new Set<String> {'INFO'});

        System.assertEquals(
            200,
            erProcessed.size(),
            'No se han procesado todas las external request'
            );
    }

    /**
     * Método test que válida la correcta ejecución de las external request cuyo origen y query sean recibidos por parámetro
     * Lógica correspondiente a INFO se valida en la clase INFOHandlerTest
     **
     * @author adelgado
     * @date 15/10/2020
     */
    @isTest
    static void test_execute_OriginAndQuery()
    {
        Test.startTest();
        ExternalJobPriorityQueueBatch ejqb = new ExternalJobPriorityQueueBatch('INFO', 'SELECT Id FROM ExternalRequest__c');
        Id batchId = Database.executeBatch(ejqb);
        Test.stopTest();

        List<ExternalRequest__c> erProcessed = new ExternalRequestsSelector().selectProcessedByOrigin(new Set<String> {'INFO'});

        System.assertEquals(
            200,
            erProcessed.size(),
            'No se han procesado todas las external request'
            );
    }
}