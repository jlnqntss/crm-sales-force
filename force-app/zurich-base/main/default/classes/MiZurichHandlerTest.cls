/**
 * @description       : Clase de test para la clase MiZurichHandler 
 * @author            : aberuete
 * @group             : 
 * @last modified on  : 08-16-2023
 * @last modified by  : aberuete
**/
@isTest
private with sharing class MiZurichHandlerTest 
{
    private static final Integer NUM_ER_FORM_INC = 5;
    private static final String MESSAGE_CAN_NOT_REGISTER = 'No puedo registrarme';
    private static final String MESSAGE_WRONG_DATA = 'Mis datos introducidos son erróneos';
    private static final String MESSAGE_CASE_DESCRIPTION = 'Descripcion del caso';
    private static final String EMAIL_CASE = 'mizruchemail@gmail.com';
    private static final String LASTNAME_CASE = 'Ortega Carrasco';

    @TestSetup
    private static void makeData()
    {
        List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

         //FORM_INC
         externalRequestList.addAll( TestDataFactory.generateExternalRequest(MiZurichHandler.HANDLER_ORIGIN, 'FORM_INC', NUM_ER_FORM_INC));

         insert externalRequestList;
    }  

    /**
     * Test que comprueba que se obtiene la información necesaria para poder procesar las external request pendientes correctamente
     **
     * @author aberuete
     * @date 15/05/2023
     */
    @isTest
    private static void test_prepare()
    {
        Transformer transformer = new Transformer(MiZurichHandler.HANDLER_ORIGIN);

        Set<String> objects = new Set<String>();

        for (Transformer__mdt setting : TransformerSelector.selectMetadataByOrigin(MiZurichHandler.HANDLER_ORIGIN) )
        {
            objects.add(setting.OriginEntity__c);
        }

        List<ExternalRequest__c> externalRequestList = new ExternalRequestsSelector(new List<Schema.SObjectField>
                                                                                    { ExternalRequest__c.Entity__c,
                                                                                      ExternalRequest__c.Action__c,
                                                                                      ExternalRequest__c.Payload__c,
                                                                                      ExternalRequest__c.ContentFormat__c}).selectByOrigin(new Set<String> {MiZurichHandler.HANDLER_ORIGIN});

        Test.startTest();
        MiZurichHandler.prepare(transformer, externalRequestList);
        Test.stopTest();

        System.assertEquals(objects.size(),ExternalRequestHandlerUtil.recordsToUpsertByEntity.size(),'No se ha generado correctamente el mapa por entidades');
        System.assertEquals(objects.size(),ExternalRequestHandlerUtil.recordsToDeleteByEntity.size(),'No se ha generado correctamente el mapa por entidades');
        System.assertNotEquals(null,ExternalRequestHandlerUtil.maxRetries,'El número máximo de intentos no debería ser nulo');
        System.assertEquals(false,ExternalRequestHandlerUtil.entitiesByPrirority.isEmpty(),'El mapa de entidades por prioridad no debería estar vacío');
        System.assertEquals(false,ExternalRequestHandlerUtil.entityIndexes.isEmpty(),'La lista de prioridades de entidades no debería estar vacía');
        System.assertEquals(false,ExternalRequestHandlerUtil.mapRobotHegeoFieldsMapping.isEmpty(),'El mapa de tipificaciones no debería estar vacío');
    }

    /**
     * Test que comprueba que al procesar las external request se actualiza correctamente el mapa de registros a actualizar
     **
     * @author aberuete
     * @date 15/05/2023
     */
    @isTest
    private static void test_process_upsert_OK()
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
        Test.stopTest();

        System.assertEquals(NUM_ER_FORM_INC,ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(MiZurichHandler.FORM_INC).get(MiZurichHandler.SOBJECT_CASE).size(),'No se ha generado correctamente el mapa de registros del caso'); 
    }

    /**
     * Test que comprueba que al procesar external request de una entidad que no existe procesa la external request como ko
     **
     * @author aberuete
     * @date 15/05/2023
     */
    @isTest
    private static void test_process_ERROR_NoEntity()
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

        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            externalRequest.Entity__c = 'TTTTTTTTTTTTTT';
        }

        Test.startTest();
        MiZurichHandler.prepare(transformer, externalRequestList);
        MiZurichHandler.process(externalRequestList);
        Test.stopTest();

        Integer totalExternalRequests = NUM_ER_FORM_INC;

        System.assertEquals(totalExternalRequests,ExternalRequestHandlerUtil.externalRequestResultList.size(),'No se han marcado como erroneas todas las external request' );
    }

    /**
     * Test que comprueba que al procesar external request cuyo payload esta nulo procesa la external request como ko
     **
     * @author aberuete
     * @date 15/05/2023
     */
    @isTest
    private static void test_process_ERROR_NoPayload()
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

        for (ExternalRequest__c externalRequest : externalRequestList)
        {
            externalRequest.Payload__c = null;
        }

        Test.startTest();
        MiZurichHandler.prepare(transformer, externalRequestList);
        MiZurichHandler.process(externalRequestList);
        Test.stopTest();

        Integer totalExternalRequests = NUM_ER_FORM_INC;
                                        
        System.assertEquals(totalExternalRequests,ExternalRequestHandlerUtil.externalRequestResultList.size(),'No se han marcado como erroneas todas las external request');
    }

    /**
     * Test que comprueba que se procesan correctamente las external request y se insertan los registros de la entidad en salesforce
     **
     * @author aberuete
     * @date 15/05/2023
     */
    @isTest
    private static void test_persists_upsert_OK()
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
        Test.stopTest();

        List<Case> caseList = [SELECT Id FROM Case];
        
        System.assertEquals(NUM_ER_FORM_INC, caseList.size(), 'No se han insertado todos los registros de caso');
    }

    /**
     * Test que comprueba que se procesan y actualizan correctamente las external request 
     **
     * @author aberuete
     * @date 15/05/2023
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
        MiZurichHandler.manageResult(null, externalRequestList);
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
     * @date 15/05/2023
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
        MiZurichHandler.manageResult(null, externalRequestList);
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
        System.assertEquals(1,errors.size(),'No se han generado los errores correctamente');
    }

    /**
     * Test que comprueba que se procesa y se crea correctamente la información del caso 
     **
     * @author aberuete
     * @date 22/05/2023
     */
    @isTest
    private static void test_processFormToCase()
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

        Map<String, Object> recordValuesMap = new Map<String, Object> 
        {
            'miZurich_inputForm2' => MESSAGE_CAN_NOT_REGISTER,
            'miZurich_inputForm3' => MESSAGE_WRONG_DATA,
            'miZurich_description' => MESSAGE_CASE_DESCRIPTION,
            'miZurich_nif' => '73562398D',
            'miZurich_telf' => '602543627',
            'miZurich_email' => EMAIL_CASE,
            'miZurich_name' => 'Andrea',
            'miZurich_lastName' => LASTNAME_CASE
        };

        Test.startTest();
        MiZurichHandler.prepare(transformer, externalRequestList);
        MiZurichHandler.processFormToCase(recordValuesMap, externalRequestList[0]);
        Test.stopTest();

        Case caserecord = (Case) ExternalRequestHandlerUtil.recordsToUpsertByEntity.get(MiZurichHandler.FORM_INC).get(MiZurichHandler.SOBJECT_CASE).keySet().iterator().next();
        System.assertEquals(false, ExternalRequestHandlerUtil.recordsToUpsertByEntity.isEmpty(), 'Debe haber registros a insertar');
        System.assertEquals('Web', caserecord.Origin , 'El origen del caso es incorrecto');
        System.assertEquals(Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('OCSInquiry').getRecordTypeId(), caserecord.RecordTypeId , 'El record type  del caso es incorrecto');
        System.assertEquals('Generic end customer', caserecord.SourceArea__c , 'El area del caso es incorrecto');
        System.assertEquals('Asignado', caserecord.Status , 'El estado del caso es incorrecto');
        System.assertEquals('CC Service', caserecord.CallCenter__c , 'El call center del caso es incorrecto');
        System.assertEquals('Solicitud de ayuda al registro de MiZurich', caserecord.Subject , 'El asunto del caso es incorrecto');
    }
    
    /**
     * Test que comprueba que se genera correctamente la descripción del caso 
     **
     * @author aberuete
     * @date 22/05/2023
     */
    @isTest
    private static void test_getDescription()
    {
        Map<String, Object> recordValuesMap = new Map<String, Object> 
        {
            'miZurich_inputForm2' => MESSAGE_CAN_NOT_REGISTER,
            'miZurich_inputForm3' => MESSAGE_WRONG_DATA,
            'miZurich_description' => MESSAGE_CASE_DESCRIPTION,
            'miZurich_nif' => '73562398D',
            'miZurich_telf' => '602543627',
            'miZurich_email' => EMAIL_CASE,
            'miZurich_name' => 'Andrea',
            'miZurich_lastName' => LASTNAME_CASE
        };

        Test.startTest();
        String descriptionFromMethod = MiZurichHandler.getDescription (recordValuesMap);
        Test.stopTest();

        String descriptionCase = 'Nombre: Andrea Ortega Carrasco' + '\n' + 'DNI: 73562398D'+'\n'+'Correo electrónico: mizruchemail@gmail.com'+
                                 '\n'+'Teléfono: 602543627'+ '\n'+ 'INFORMACIÓN ADICIONAL: Descripcion del caso' + '\n';

        System.assertEquals(descriptionCase, descriptionFromMethod, 'La descripción del caso no es correcta');
    }
}