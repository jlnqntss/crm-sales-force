/**
 * Clases de test para Batch_DeleteExternalRequest
 **
 * @author nbizkarra
 * @change adelgado 13/11/2020 Cambios en tests y escenario para nuevos requerimientos OCS
 * @date 27/04/2020
 */
@isTest
private with sharing class Test_Batch_DeleteExternalRequest
{
    private static final String INFO_PROCESSED_RECORD_TYPE_DEVELOPER_NAME = 'INFOProcessed';
    public static final Id INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID = Schema.SObjectType.ExternalRequest__c.getRecordTypeInfosByDeveloperName().get(INFO_PROCESSED_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId();
    public static final String PROCESSED_RESULT_KO = 'KO';
    public static final String PROCESSED_RESULT_OK = 'OK';
    private static final String  QUERY_OK = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id,ExternalRequest__c.processed__c}).getQueryProcessedAfterThan(SystemUtil.getAdminSetupMetadata().RetentionExternalRequestKO__c.intValue(), PROCESSED_RESULT_OK);
    private static final String  QUERY_KO = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Id,ExternalRequest__c.processed__c}).getQueryProcessedAfterThan(SystemUtil.getAdminSetupMetadata().RetentionExternalRequestKO__c.intValue(), PROCESSED_RESULT_KO);
    private static final String JOBOK = Batch_DeleteExternalRequest.JOBOK;
    private static final String JOBKO = Batch_DeleteExternalRequest.JOBKO;

    /**
     * Create test data
     **
     * @author nbizkarra
     * @change adelgado 13/11/2020 Cambios en generación de escenario para hacer uso de la clase TestDataFactory
     * @date 27/04/2020
     */
    @TestSetup
    private static void makeData()
    {
        List<ExternalRequest__c> externalRequestListOK = new List<ExternalRequest__c>();

        //External request procesadas con valor OK
        externalRequestListOK.addAll( TestDataFactory.generateExternalRequest('INFO', 'POLICY', 30) );
        Datetime customDateTime = Datetime.now().addDays(-20);

        for(ExternalRequest__c externalRequest : externalRequestListOK)
        {
            externalRequest.Processed__c = true;
            externalRequest.ProcessedDate__c = customDateTime;
            externalRequest.ProcessResult__c = 'OK';
        }

        List<ExternalRequest__c> externalRequestListKO = new List<ExternalRequest__c>();

        //External request procesadas con valor KO
        externalRequestListKO.addAll( TestDataFactory.generateExternalRequest('INFO', 'POLICY', 30) );


        for(ExternalRequest__c externalRequest : externalRequestListKO)
        {
            externalRequest.Processed__c = true;
            externalRequest.ProcessedDate__c = customDateTime;
            externalRequest.ProcessResult__c = 'KO';
        }

        insert externalRequestListOK;
        insert externalRequestListKO;

        //Se aplica el Record Type INFOPRocessed a las External Request, requisito indispensable para que sean borradas.
        for(ExternalRequest__c exR : externalRequestListOK)
        {
            exR.RecordTypeID = INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID;
        }
        for(ExternalRequest__c exR : externalRequestListKO)
        {
            exR.RecordTypeID = INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID;
        }

        update externalRequestListOK;
        update externalRequestListKO;
    }

    /**
     * Comprobar que el batch elimina solo registros de external request procesados cuyo origen sea INFO,
     * que hayan sido procesadas, con un ProcessedResult__c igual a OK y con más de un día de procesado.
     * *
     * @author jchavez
     * @date 24/04/2024
     */
    @isTest
    private static void test_borradoExternalRequestClearOKs()
    {
        List<ExternalRequest__c> exRToDeleteBefore = [Select id from ExternalRequest__c where recordtype.Id =: INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID AND ProcessResult__c =: PROCESSED_RESULT_OK ];

        Test.startTest(); 
        Batch_DeleteExternalRequest b = new Batch_DeleteExternalRequest(QUERY_OK);
        String jobId = database.executeBatch(b, 200 );
        Test.stopTest();

        List<ExternalRequest__c> ExRToDeleteAfter = [Select id from ExternalRequest__c where recordtype.Id =: INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID AND ProcessResult__c =:PROCESSED_RESULT_OK ];
        Assert.areNotEqual(null, jobID, 'Se ha procesado el batch correctamente');
        Assert.areEqual(True, exRToDeleteBefore.size() > ExRToDeleteAfter.size(),'Se ha borrado el Ex correspondiente');
    }

    /**
     * Comprobar que el batch elimina solo registros de external request procesados cuyo origen sea INFO,
     * que hayan sido procesadas, con un ProcessedResult__c igual a KO y con más de siete días de procesado.
     * *
     * @author jchavez
     * @date 24/04/2024
     */
    @isTest
    private static void test_borradoExternalRequestClearKOs()
    {
        List<ExternalRequest__c> exRToDeleteBefore = [Select Id from ExternalRequest__c where recordtype.Id =: INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID AND ProcessResult__c =:PROCESSED_RESULT_KO ];

        Test.startTest(); 
        Batch_DeleteExternalRequest b = new Batch_DeleteExternalRequest(QUERY_KO);
        String jobID = database.executeBatch(b, 200 );
        Test.stopTest();

        List<ExternalRequest__c> exRToDeleteAfter = [Select id from ExternalRequest__c where recordtype.Id =: INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID AND ProcessResult__c =:PROCESSED_RESULT_KO ];
        Assert.areNotEqual(null, jobID, 'Se ha procesado el batch correctamente');
        Assert.areEqual(True , exRToDeleteBefore.size() > exRToDeleteAfter.size(),'Se ha borrado el Ex correspondiente');
    }

	/**
     * Se comprueba que se ha programado correctamente la ejecución del Job Clear_External_Request_OK
     * Si ya está en ejecución, se termina y se vuelve a lanzar
     * *
     * @author jchavez
     * @date 24/04/2024
     */
    @isTest
    private static void test_scheduleExternalRequestClearOKs()
    {
        List<CronTrigger> cronTriggerOK  = [select id from CronTrigger where CronJobDetail.Name =: JOBOK ];
        String jobId = '';

        Test.startTest();
        if(cronTriggerOK.isEmpty())
        {
            jobID = Batch_DeleteExternalRequest.scheduleExternalRequestClearOKs();
            database.executeBatch( new Batch_DeleteExternalRequest(QUERY_OK), 2000 );
        }else
        {
            System.AbortJob(cronTriggerOK[0].Id);
            jobID = Batch_DeleteExternalRequest.scheduleExternalRequestClearOKs();
            database.executeBatch( new Batch_DeleteExternalRequest(QUERY_OK), 2000 );
        }
        Test.stopTest();

        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }

     /**
     * Se comprueba que se ha programado correctamente la ejecución del Job Clear_External_Request_KO
     * Si ya está en ejecución, se termina y se vuelve a lanzar
     * 
     * @author jchavez
     * @date 24/04/2024
     */
    @isTest
    private static void test_scheduleExternalRequestClearKOs()
    {
        String jobId = '';
        List<CronTrigger> cronTriggerKO  = [select id from CronTrigger where CronJobDetail.Name =: JOBKO ];

        Test.startTest();
        if(cronTriggerKO.isEmpty())
        {
            jobID = Batch_DeleteExternalRequest.scheduleExternalRequestClearKOs();
            database.executeBatch( new Batch_DeleteExternalRequest(QUERY_KO), 2000 );
        }else
        {
            System.AbortJob(cronTriggerKO[0].Id);
            jobID = Batch_DeleteExternalRequest.scheduleExternalRequestClearKOs();
            database.executeBatch( new Batch_DeleteExternalRequest(QUERY_KO), 2000 );
        }
        Test.stopTest();
        
        System.assert (!String.isBlank(jobID), 'No se ha programado correctamente el batch');
    }
}