@isTest
private class ExternalJobQueueBatchControllerTest
{
    /**
     * Método test que válida el procesamiento de las external request insertadas
     **
     * @author adelgado
     * @date 30/10/2020
     */
    @isTest
    static void test_checkExternalJobQueueBatch_newExternalRequest()
    {
        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 10);

        Test.startTest();
        insert externalRequestList;
        Test.stopTest();

        List<ExternalRequest__c> extReqProcessed = [SELECT Id FROM ExternalRequest__c WHERE Processed__c = true];

        System.assertEquals(10, extReqProcessed.size(), 'No se han procesado las external request insertadas');

    }
}