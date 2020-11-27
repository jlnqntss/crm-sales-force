@isTest
private class ExternalJobQueueJobTest
{
    /**
     * Método test que válida que se encola un nuevo trabajo de procesamiento de externalRequest
     **
     * @author adelgado
     * @date 19/11/2020
     */
    @isTest
    static void test_execute()
    {
        Test.startTest();
        Id jobId = System.enqueueJob( new ExternalJobQueueJob('INFO') );
        Test.stopTest();

        System.assert (jobId != null, 'No se ha encolado el trabajo correctamente');
    }
}