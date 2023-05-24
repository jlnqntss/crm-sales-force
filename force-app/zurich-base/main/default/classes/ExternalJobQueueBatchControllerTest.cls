/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 05-23-2023
 * @last modified by  : aberuete
**/
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
        Map<String,List<String>> queriesByOrigin = ExternalJobQueueBatchController.getChunkQueries(2);
        Test.stopTest();

        Id originRcordType = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();
        List<ExternalRequest__c> firstPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'ASC', 2);
        List<ExternalRequest__c> lastPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'DESC', 2);

        System.assertEquals(1, queriesByOrigin.values().size(), 'No se ha generado la query correctamente');
        // Check query text
        String q = 'SELECT Id FROM ExternalRequest__c WHERE RecordTypeId = \'' + originRcordType + '\' AND Id >= \'' + ( (String) firstPendingExtReq.get(0).Id ).substring(0,15) + '\' AND Id <= \'' + ( (String) lastPendingExtReq.get(0).Id ).substring(0,15) + '\' AND Processed__c = false';
        String priorityEntities = '';
        if( INFOHandler.PRIORITY_ENTITIES != null && !INFOHandler.PRIORITY_ENTITIES.isEmpty() ) {
            priorityEntities = ' AND Entity__c NOT IN ' + INFOHandler.PriorityEntitiesToString;
        }
        q += priorityEntities;

        System.assertEquals (q, queriesByOrigin.values()[0][0], 'No se ha generado la query correctamente');
        System.assertEquals ('INFO', queriesByOrigin.keySet().iterator().next(), 'El origen no es correcto');

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
        Map<String,List<String>> queriesByOrigin = ExternalJobQueueBatchController.getChunkQueries(2);
        Test.stopTest();

        Id originRcordType = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get('INFO').getRecordTypeId();
        List<ExternalRequest__c> firstPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'ASC', 2);
        List<ExternalRequest__c> lastPendingExtReq = new ExternalRequestsSelector().setLimit(1).selectMinMaxPendingByRecordType(originRcordType, 'DESC', 2);

        System.assertEquals(1, queriesByOrigin.values().size(), 'No se ha generado la query correctamente');
        // Check query text
        String q = 'SELECT Id FROM ExternalRequest__c WHERE RecordTypeId = \'' + originRcordType + '\' AND Id >= \'' + ( (String) firstPendingExtReq.get(0).Id ).substring(0,15) + '\' AND Id <= \'' + ( (String) lastPendingExtReq.get(0).Id ).substring(0,15) + '\' AND Processed__c = false';
        String priorityEntities = '';
        if( INFOHandler.PRIORITY_ENTITIES != null && !INFOHandler.PRIORITY_ENTITIES.isEmpty() ) {
            priorityEntities = ' AND Entity__c NOT IN ' + INFOHandler.PriorityEntitiesToString;
        }
        q += priorityEntities;

        System.assertEquals(q,queriesByOrigin.values()[0][0],'No se ha generado la query correctamente');
        System.assertEquals ('INFO', queriesByOrigin.keySet().iterator().next(), 'El origen no es correcto');

    }

     /**
     * Método test que válida que se encola un nuevo trabajo de procesamiento de externalRequest de tipo Nota
     * y que hace uso de cola prioritaria
     **
     * @author nts (agonzalezisasi)
     * @date 11/05/2021
     */
    @isTest
    static void test_checkExternalJobPriorityQueueBatch()
    {
        List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();
        externalRequestList.addAll(
            TestDataFactory.generateExternalRequest('INFO', 'NOTE', 10)
        );
        insert externalRequestList;

        Test.startTest();
        ExternalJobQueueBatchController.checkExternalJobPriorityQueueBatch();
        List<AsyncApexJob> executingBatch = new AsyncApexJobsSelector().selectByClassName(new Set<String> {'ExternalJobPriorityQueueBatch'});
        Test.stopTest();

        System.assertEquals(1, executingBatch.size(), 'No se ha encolado el trabajo de cola prioritaria');

    }

    /**
    * @description Método de test que valida el correcto funcionamiento del método 
    * que elimina los ceros iniciales de un String
    * @author amiranda | 18-04-2023 
    **/
    @isTest
    static void test_dropLeadingZeros()
    {
        Map<String, String> expectedValuesByPassedValue = new Map<String, String>{
            '123456' => '123456',
            '00000123456' => '123456',
            '12345600000' => '12345600000',
            '12034056' => '12034056',
            '  00123456' => '123456',
            '00123456  ' => '123456',
            '  00123456  ' => '123456',
            'abcdefg' => null,
            'abcd123456' => null,
            '  ' => null,
            '' => null
        };

        for (String passedValue : expectedValuesByPassedValue.keySet())
        {
            String expectedValue = expectedValuesByPassedValue.get(passedValue);
            Assert.areEqual(expectedValue, 
                            ExternalJobQueueBatchController.dropLeadingZeros(passedValue),
                            'El valor pasado por parámetro (' + passedValue + ') no coincide con el valor esperado (' + expectedValue + ')');
        }
    }
}