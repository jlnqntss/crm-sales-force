/**
 * @description       : Clase de test para la clase ExternalRequestHandlerUtil
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 05-17-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class ExternalRequestHandlerUtilTest 
{
    private static final Integer NUM_ER_FORM_INC = 5;
    private static final Integer NUM_ER_NATURAL_ACCOUNT = 5;

    @TestSetup
    private static void makeData()
    {
        List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

         //FORM_INC
         externalRequestList.addAll( TestDataFactory.generateExternalRequest(MiZurichHandler.HANDLER_ORIGIN, 'FORM_INC', NUM_ER_FORM_INC));

         //Personas físicas
         externalRequestList.addAll(TestDataFactory.generateExternalRequest(INFOHandler.HANDLER_ORIGIN, 'NATURAL_ACCOUNT', NUM_ER_NATURAL_ACCOUNT));

         insert externalRequestList;
    }  

    /**
     * Test que comprueba que se obtiene la información necesaria para poder procesar las external request pendientes correctamente
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_prepareExternalRequestToProcess()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        Set<String> objects = new Set<String>();

        for (Transformer__mdt setting : TransformerSelector.selectMetadataByOrigin(INFOHandler.HANDLER_ORIGIN) )
        {
            objects.add(setting.OriginEntity__c);
        }
        
        Test.startTest();
        ExternalRequestHandlerUtil.prepareExternalRequestToProcess(transformer, INFOHandler.HANDLER_ORIGIN);
        Test.stopTest();

        System.assertEquals(objects.size(),ExternalRequestHandlerUtil.recordsToUpsertByEntity.size(),'No se ha generado correctamente el mapa por entidades');
        System.assertEquals(objects.size(),ExternalRequestHandlerUtil.recordsToDeleteByEntity.size(),'No se ha generado correctamente el mapa por entidades');
        System.assertNotEquals(null,ExternalRequestHandlerUtil.maxRetries,'El número máximo de intentos no debería ser nulo');
        System.assertEquals(false,ExternalRequestHandlerUtil.entitiesByPrirority.isEmpty(),'El mapa de entidades por prioridad no debería estar vacío');
        System.assertEquals(false,ExternalRequestHandlerUtil.entityIndexes.isEmpty(),'La lista de prioridades de entidades no debería estar vacía');
        System.assertEquals(false,ExternalRequestHandlerUtil.mapRobotHegeoFieldsMapping.isEmpty(),'El mapa de tipificaciones no debería estar vacío');
    }

    /**
     * Test que comprueba que se procesan correctamente las external request procedentes de MiZurich y se insertan los registros de la entidad en salesforce
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_persists_upsert_MiZurich_OK()
    {
        Transformer transformer = new Transformer(MiZurichHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {MiZurichHandler.HANDLER_ORIGIN});
    
        Test.startTest();
        MiZurichHandler.prepare(transformer, externalRequestList);
        MiZurichHandler.process(externalRequestList);
        ExternalRequestHandlerUtil.persistExternalRequest('MiZurichHandler');
        Test.stopTest();

        List<Case> caseList = [SELECT Id FROM Case];

        System.assertEquals(NUM_ER_FORM_INC, caseList.size(), 'No se han insertado todos los registros de caso');
        
    }

     /**
     * Test que comprueba que se procesan correctamente las external request procedentes de INFO y se insertan los registros de la entidad en salesforce
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_persists_upsert_INFO_OK()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});
    
        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        ExternalRequestHandlerUtil.persistExternalRequest('INFOHandler');
        Test.stopTest();

        List<Account> accountList = [SELECT Id FROM Account];

        System.assertEquals( NUM_ER_NATURAL_ACCOUNT,accountList.size(),'No se han insertado todos los registros de cuenta');
    }

    /**
     * Test que comprueba que se procesan correctamente las external request procedentes de INFO y se borran los registros de la entidad en salesforce
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_persists_delete_OK()
    {
        Transformer transformer = new Transformer(INFOHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        INFOHandler.prepare(transformer, externalRequestList);
        INFOHandler.process(externalRequestList);
        INFOHandler.persists(externalRequestList);
        INFOHandler.manageResult(null, externalRequestList);

        List<ExternalRequest__c> externalRequestListUpserted = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                            { ExternalRequest__c.Entity__c,
                                                                                              ExternalRequest__c.Action__c,
                                                                                              ExternalRequest__c.Payload__c,
                                                                                              ExternalRequest__c.ContentFormat__c,
                                                                                              ExternalRequest__c.NumRetry__c,
                                                                                              ExternalRequest__c.Origin__c,
                                                                                              ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {INFOHandler.HANDLER_ORIGIN});

        List<ExternalRequest__c> externalRequestToDelete = new List<ExternalRequest__c>();

        for(ExternalRequest__c externalRequest : externalRequestListUpserted)
        {
            externalRequest.Processed__C = false;
            externalRequest.Action__C = 'DELETE';
            externalRequestToDelete.add(externalRequest);   
        }

        update externalRequestToDelete;

        Test.startTest();
        INFOHandler.prepare(transformer, externalRequestToDelete);
        INFOHandler.process(externalRequestToDelete);
        ExternalRequestHandlerUtil.persistExternalRequest('INFOHandler');
        Test.stopTest();

        List<Account> accountList = [SELECT Id FROM Account]; 
        System.assertEquals(0, accountList.size(), 'No se han borrado todos los registros de cuentas');
    }

     /**
     * Test que comprueba que se procesan y actualizan correctamente las external request 
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_manageResult_OK()
    {
        Transformer transformer = new Transformer(MiZurichHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {MiZurichHandler.HANDLER_ORIGIN});

        Test.startTest();
        MiZurichHandler.prepare(transformer, externalRequestList);
        MiZurichHandler.process(externalRequestList);
        MiZurichHandler.persists(externalRequestList);
        ExternalRequestHandlerUtil.manageResultExternalRequest(null, externalRequestList, 'MiZurichHandler');
        Test.stopTest();

        List<ExternalRequest__c> externalRequestListUpdated = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                           { ExternalRequest__c.Entity__c,
                                                                                             ExternalRequest__c.Action__c,
                                                                                             ExternalRequest__c.Payload__c,
                                                                                             ExternalRequest__c.ContentFormat__c,
                                                                                             ExternalRequest__c.NumRetry__c,
                                                                                             ExternalRequest__c.Origin__c,
                                                                                             ExternalRequest__c.CreatedDate}).selectProcessedByOrigin(new Set<String> {MiZurichHandler.HANDLER_ORIGIN});

        List<ExternalRequestError__c> externalRequestErrors = [
            SELECT Id
            FROM ExternalRequestError__c
            WHERE Origin__c = :MiZurichHandler.HANDLER_ORIGIN
        ];

        Integer totalExternalRequests = NUM_ER_FORM_INC;

        System.assertEquals(totalExternalRequests,externalRequestListUpdated.size(),'No se han procesado todas las external request');
       
        System.assertEquals(0, externalRequestErrors.size(),'Se han insertado external request erróneas en la entidad External Request Error');
    }

    /**
     * Test que comprueba que se procesan y actualizan correctamente las external request y en caso de error se generan correctamente los externalRequestError
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_manageResult_ERROR()
    {
        Transformer transformer = new Transformer(MiZurichHandler.HANDLER_ORIGIN);

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {MiZurichHandler.HANDLER_ORIGIN});

        externalRequestList.get(0).Payload__c = null;

        Test.startTest();
        MiZurichHandler.prepare(transformer, externalRequestList);
        MiZurichHandler.process(externalRequestList);
        MiZurichHandler.persists(externalRequestList);
        ExternalRequestHandlerUtil.manageResultExternalRequest(null, externalRequestList, 'MiZurichHandler');
        Test.stopTest();

        List<ExternalRequest__c> externalRequestListUpdated = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                           { ExternalRequest__c.Entity__c,
                                                                                             ExternalRequest__c.Action__c,
                                                                                             ExternalRequest__c.Payload__c,
                                                                                             ExternalRequest__c.ContentFormat__c,
                                                                                             ExternalRequest__c.NumRetry__c,
                                                                                             ExternalRequest__c.Origin__c,
                                                                                             ExternalRequest__c.CreatedDate}).selectProcessedByOrigin(new Set<String> {MiZurichHandler.HANDLER_ORIGIN});

        List<ExternalRequestError__c> errors = [SELECT Id FROM ExternalRequestError__c];

        Integer totalExternalRequests = NUM_ER_FORM_INC;
        
        System.assertEquals(totalExternalRequests,externalRequestListUpdated.size(),'No se han procesado todas las external request');
    }

    /**
     * Test que comprueba que se actualiza correctamente la información de la external request
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_setExternalRequest()
    {
        ExternalRequestHandlerUtil.externalRequestResultList = new List<ExternalRequest__c>();

        ExternalRequestHandlerUtil.maxRetries = (Integer) new ExternalJobQueueBatchesSelector
        (
            new List<Schema.SObjectField> {ExternalJobQueueBatch__mdt.Retries__c}
        ).selectByOrigin(new Set<String> {MiZurichHandler.HANDLER_ORIGIN}).get(0).Retries__c;

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c,
                                                                                      ExternalRequest__c.NumRetry__c,
                                                                                      ExternalRequest__c.Origin__c,
                                                                                      ExternalRequest__c.CreatedDate}).selectByOrigin(new Set<String> {MiZurichHandler.HANDLER_ORIGIN});
        externalRequestList[0].NumRetry__c = 2;

        Test.startTest();
        ExternalRequestHandlerUtil.setExternalRequest(externalRequestList[0], false, 'OK', null, true);
        Test.stopTest();

        System.assertEquals(false, ExternalRequestHandlerUtil.externalRequestResultList.isEmpty(), 'La lista no debería estar vacía');
        System.assertEquals(true, ExternalRequestHandlerUtil.externalRequestResultList[0].Processed__c, 'Debería estar procesada la external request');
        System.assertEquals('OK', ExternalRequestHandlerUtil.externalRequestResultList[0].ProcessResult__c, 'El resultado del procesamiento de la external requets debería ser OK');
    }

    /**
     * Test que comprueba que se rellena correctamente el mapa de entidades por prioridad
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_fillEntitiesByPriorityMap()
    {
        ExternalRequestHandlerUtil.entitiesByPrirority = new Map<Decimal, String>();
        ExternalRequestHandlerUtil.entityIndexes = new List<Decimal>();

        Test.startTest();
        ExternalRequestHandlerUtil.fillEntitiesByPriorityMap();
        Test.stopTest();

        System.assertEquals(false, ExternalRequestHandlerUtil.entitiesByPrirority.isEmpty(), 'El mapa de prioridades por entidades no debería estar vacío');
        System.assertEquals(false, ExternalRequestHandlerUtil.entityIndexes.isEmpty(), 'La lista de prioridades no debería estar vacía');
    }

     /**
     * Test que comprueba que antes de insertar la external request se rellena el campo index que contiene la prioridad de la entidad para ser procesada
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_setERIndex()
    {
        ExternalRequestHandlerUtil.entitiesByPrirority = new Map<Decimal, String>();
        ExternalRequestHandlerUtil.entityIndexes = new List<Decimal>();

        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest(MiZurichHandler.HANDLER_ORIGIN, 'FORM_INC', 1);
        externalRequestList[0].Index__c = null;

        Test.startTest();
        insert externalRequestList;
        Test.stopTest();

        ExternalRequest__c externalRequestAfterInsert = [Select id,Index__c from ExternalRequest__c where id =: externalRequestList[0].id ];

        System.assertNotEquals(null, externalRequestAfterInsert.Index__c, 'El indice no debería ser nulo');
    }

    /**
     * Test que comprueba que se rellena correctamente el mapa de tipificaciones
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_fillMapRobotHegeoFieldsMapping()
    {
        ExternalRequestHandlerUtil.mapRobotHegeoFieldsMapping = new Map<String, Map<String, Map<String,String>>> ();

        Test.startTest();
        ExternalRequestHandlerUtil.fillMapRobotHegeoFieldsMapping();
        Test.stopTest();

        System.assertEquals(false, ExternalRequestHandlerUtil.mapRobotHegeoFieldsMapping.isEmpty(), 'El mapa de tipificaciones no debería estar vacío');
    }

    /**
     * Test que comprueba que se obtiene correctamente la tipificación del caso y se actualizan sus valores
     **
     * @author aberuete
     * @date 17/05/2023
     */
    @isTest
    private static void test_fillTypificationIntoCase()
    {
        Case caseRecord = new Case ();
        ExternalRequestHandlerUtil.mapRobotHegeoFieldsMapping = new Map<String, Map<String, Map<String,String>>> ();
        ExternalRequestHandlerUtil.fillMapRobotHegeoFieldsMapping();

        String infoType = 'source type';
        String infoSubtype = 'source subtype';
        Map<String, Object> recordValuesMap = new Map<String, Object> {
                                                'miZurich_inputForm2' => infoType,
                                                'miZurich_inputForm3' => infoSubtype
                                                };
        Map<String,String> subtypeAndtype3 = new Map<String,String>();
        Map<String, Map<String,String>> mapTipification = new Map<String, Map<String,String>> ();
        subtypeAndtype3.put('Gestión de recibos','Anulación');
        mapTipification.put ('Gestión Económica', subtypeAndtype3);
        ExternalRequestHandlerUtil.mapRobotHegeoFieldsMapping.put(infoType + infoSubtype,mapTipification);                    

        Test.startTest();
        caseRecord = ExternalRequestHandlerUtil.fillTypificationIntoCase (recordValuesMap, 'miZurich_inputForm2', 'miZurich_inputForm3', caseRecord);
        Test.stopTest();

        System.assertEquals('Gestión Económica', caseRecord.Type, 'El tipo de la tipificación no es correcto');
        System.assertEquals('Gestión de recibos', caseRecord.SubType__c, 'El subtipo de la tipificación no es correcto');
        System.assertEquals('Anulación', caseRecord.TypeN3__c, 'El tipo 3 de la tipificación no es correcto');
    }
}