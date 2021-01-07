@isTest
private class ExternalJobQueueBatchControllerTest
{
    /**
     * Método test que válida que se encola un nuevo trabajo de procesamiento de externalRequest
     **
     * @author adelgado
     * @date 30/10/2020
     */
    @isTest
    static void test_checkExternalJobQueueBatch()
    {
        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 10);
        insert externalRequestList;

        Test.startTest();
        ExternalJobQueueBatchController.checkExternalJobQueueBatch();
        List<AsyncApexJob> queuedJobs = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobQueueJob'});
        Test.stopTest();

        System.assertEquals(1, queuedJobs.size(), 'No se ha encolado el trabajo correctamente');

    }

    /**
     * Método test que válida la genración de queries utilizando la técnica de PK Chunking cuando hay más de un registro pendiente
     **
     * @author adelgado
     * @date 19/11/2020
     */
    @isTest
    static void test_getChunkQueries_moreThanOne()
    {
        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 10);
        insert externalRequestList;

        Test.startTest();
        List<String> queries = ExternalJobQueueBatchController.getChunkQueries('INFO');
        Test.stopTest();

        Id originRcordType = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();
        List<ExternalRequest__c> firstPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'ASC');
        List<ExternalRequest__c> lastPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'DESC');

        System.assertEquals(1, queries.size(), 'No se ha generado la query correctamente');
        System.assertEquals
        (
            'SELECT Id FROM ExternalRequest__c WHERE RecordTypeId = \'' + originRcordType + '\' AND Id >= \'' + ( (String) firstPendingExtReq.get(0).Id ).substring(0,15) + '\' AND Id <= \'' + ( (String) lastPendingExtReq.get(0).Id ).substring(0,15) + '\' AND Processed__c = false',
            queries.get(0),
            'No se ha generado la query correctamente'
        );

    }

    /**
     * Método test que válida la genración de queries utilizando la técnica de PK Chunking cuando hay más de un registro pendiente
     **
     * @author adelgado
     * @date 19/11/2020
     */
    @isTest
    static void test_getChunkQueries_onlyOneRecord()
    {
        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 1);
        insert externalRequestList;

        Test.startTest();
        List<String> queries = ExternalJobQueueBatchController.getChunkQueries('INFO');
        Test.stopTest();

        Id originRcordType = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();
        List<ExternalRequest__c> firstPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'ASC');
        List<ExternalRequest__c> lastPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'DESC');

        System.assertEquals(1, queries.size(), 'No se ha generado la query correctamente');
        System.assertEquals
        (
            'SELECT Id FROM ExternalRequest__c WHERE RecordTypeId = \'' + originRcordType + '\' AND Id >= \'' + ( (String) firstPendingExtReq.get(0).Id ).substring(0,15) + '\' AND Id <= \'' + ( (String) lastPendingExtReq.get(0).Id ).substring(0,15) + '\' AND Processed__c = false',
            queries.get(0),
            'No se ha generado la query correctamente'
        );

    }
}