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

        //External request procesadas
        externalRequestListOK.addAll( TestDataFactory.generateExternalRequest('INFO', 'INFO_PROCESSED', 30) );
        //externalRequestList.addAll( TestDataFactory.generateExternalRequest('IBA', 'NATURAL_ACCOUNT', 15) );

        Datetime customDateTime = Datetime.now().addDays(-20);

        for(ExternalRequest__c externalRequest : externalRequestListOK)
        {
            externalRequest.Processed__c = true;
            externalRequest.ProcessedDate__c = customDateTime;
            externalRequest.ProcessResult__c = 'OK';
        }

        List<ExternalRequest__c> externalRequestListKO = new List<ExternalRequest__c>();

        //External request procesadas
        externalRequestListKO.addAll( TestDataFactory.generateExternalRequest('INFO', 'INFO_PROCESSED', 30) );
        //externalRequestList.addAll( TestDataFactory.generateExternalRequest('IBA', 'NATURAL_ACCOUNT', 15) );


        for(ExternalRequest__c externalRequest : externalRequestListKO)
        {
            externalRequest.Processed__c = true;
            externalRequest.ProcessedDate__c = customDateTime;
            externalRequest.ProcessResult__c = 'KO';
        }

        insert externalRequestListOK;
        insert externalRequestListKO;

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
     * Comprobar que el batch elimina solo registros de external request procesados cuyo origen sea INFO
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    private static void test_scheduleExternalRequestClearOKs()
    {
        List<ExternalRequest__c> ExRToDeleteBefore = [Select id from ExternalRequest__c where recordtype.Id =: INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID AND ProcessResult__c =: PROCESSED_RESULT_OK ];

        Test.startTest(); 
        Batch_DeleteExternalRequest b = new Batch_DeleteExternalRequest(QUERY_OK);
        String jobId = database.executeBatch(b, 200 );
        Test.stopTest(); 

        List<ExternalRequest__c> ExRToDeleteAfter = [Select id from ExternalRequest__c where recordtype.Id =: INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID AND ProcessResult__c =:PROCESSED_RESULT_OK ];
        Assert.areNotEqual(null, jobID);
        Assert.areEqual(True, ExRToDeleteBefore.size() > ExRToDeleteAfter.size(),'Se ha borrado el Ex correspondiente');
    }

    /**
     * Comprobar que el batch elimina solo registros de external request procesados cuyo cuyo resultado de procesado sea KO
     * *
     * @author adelgadot
     * @date 13/11/2020
     */
    @isTest
    private static void test_scheduleExternalRequestClearKOs()
    {
        List<ExternalRequest__c> ExRToDeleteBefore = [Select Id from ExternalRequest__c where recordtype.Id =: INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID AND ProcessResult__c =:PROCESSED_RESULT_KO ];

        Test.startTest(); 
        Batch_DeleteExternalRequest b = new Batch_DeleteExternalRequest(QUERY_KO);
        String jobID = database.executeBatch(b, 200 );
        Test.stopTest(); 

        List<ExternalRequest__c> ExRToDeleteAfter = [Select id from ExternalRequest__c where recordtype.Id =: INFO_PROCESSED_RECORD_TYPE_DEVELOPER_ID AND ProcessResult__c =:PROCESSED_RESULT_KO ];
        Assert.areNotEqual(null, jobID);
        Assert.areEqual(True , ExRToDeleteBefore.size() > ExRToDeleteAfter.size(),'Se ha borrado el Ex correspondiente');
    }

    /**
     * Comprobar que el batch elimina todos los registros de external request procesados independientemente del origen
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    private static void test_EliminarRequestsProcesadas()
    {
        Integer numReqPreBatch = [SELECT COUNT() FROM ExternalRequest__c LIMIT 50000];

        String query = 'SELECT Id FROM ExternalRequest__c WHERE Processed__c = true';

        Test.startTest();
        database.executeBatch(new Batch_DeleteExternalRequest(query), 200);
        Test.stopTest();

        Integer numReqAfterBatch = [SELECT COUNT() FROM ExternalRequest__c LIMIT 50000];

        Assert.areEqual(numReqPreBatch , numReqAfterBatch, 'Se han eliminado registros de external request erroneos');
    }

    /**
     * Comprobar que el batch elimina todos los registros de external request creadas antes del número de días indicado en el metadato personalizado
     * *
     * @author adelgado
     * @date 13/11/2020
     */
    @isTest
    private static void test_EliminarRequests_Metadato()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        Assert.areNotEqual(null, adminSetup.RetentionExternalRequestKO__c, 'Metadato No existe');
        Assert.areNotEqual(null, adminSetup.RetentionExternalRequestOK__c, 'Metadato No existe');
    }

    @isTest
    private static void test_scheduleExternalRequestClear()
    {
        Batch_DeleteExternalRequest b = new Batch_DeleteExternalRequest(QUERY_KO);
        Test.startTest();
        String jobID = system.schedule( 'Delete External Request Test', '0 50 * * * ?', b);
        Test.stopTest();

        Assert.areNotEqual(null, jobID, 'Se ha programado la ejecución del batch');
    }
}