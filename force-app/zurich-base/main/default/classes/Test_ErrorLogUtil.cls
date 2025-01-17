/**
 * Clases de test para ErrorLogUtil
 **
 * @author nts
 * @date 24/02/2020
 */
@isTest(SeeAllData = false)
private with sharing class Test_ErrorLogUtil
{
    @testSetup
    private static void makeData()
    {}

    @isTest
    private static void testCommitErrors()
    {
        Test.startTest();
        try
        {
            List<String> vals;
            String err = vals[0];
        }
        catch (Exception ex)
        {
            /* Test 1 */
            ErrorLogUtil.commitError(ex);
            /* Test 2 */
            ErrorLogUtil.commitError(ex, 'OriginClass_Test02');
            /* Test 3 */
            ErrorLogUtil.commitError(ex, 'OriginClass_Test03', 'OriginMethod_Test03');
            /* Test 4 */
            ErrorLogUtil.commitError(
                ErrorLogUtil.ERROR_LEVEL_CRITICAL,
                'Message_Test04',
                'OriginClass_Test04'
                );
        }
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        System.assertEquals( 4, errorRecords.size() );
    }

    @isTest
    private static void testHandleErrors()
    {
        //List<Error_Event__e> errorEvents = TestDataFactory.getErrorEvents(5);
        List<Error_Event__e> errorEvents = new List<Error_Event__e>();
        errorEvents.add(
            new Error_Event__e(
                Message__c = 'test message',
                Source_Class__c = 'test class',
                Source_Method__c = 'test method',
                Line_Number__c = 12,
                Level__c = 'Error',
                Stack_Trace__c = 'Test',
                Job_ID__c = 'Test',
                Record_External_ID__c = 'Test',
                Record_Object__c = 'Test',
                Type_Name__c = 'Test',
                Throwing_time__c = System.now()
                )
            );

        Test.startTest();
        ErrorLogUtil.handleErrors(errorEvents);
        Test.stopTest();
        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        System.assertEquals( 1, errorRecords.size() );
    }

    @IsTest
    private static void test_ErrorLogHandlerMethods()
    {
        /* Cobertura para el handler que implementa la interfaz ITigger */

        Test.startTest();

        /* Insertar un error */
        insert new Error_Log__c(
            Message__c = 'Error inicial',
            Source_Class__c = 'TestClass',
            Source_Method__c = 'TestMethod',
            Line_Number__c = 45,
            Level__c = 'Error',
            Stack_Trace__c = 'Traza',
            Job_ID__c = null,
            Record_External_ID__c = null,
            Record_Object__c = null,
            Type_Name__c = null,
            Throwing_time__c = System.now()
            );

        /* Actualizar el error insertado */
        Error_Log__c insertedError = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Source_Class__c = 'TestClass'
                                    LIMIT 1
        ];
        insertedError.Message__c = 'Nuevo mensaje';
        update insertedError;

        /* Eliminar el error actualizado */
        delete insertedError;

        Test.stopTest();
    }

    @isTest
    private static void testHandleExternalRequestErrors()
    {
        List<ExternalRequestErrorEvent__e> errorEvents = new List<ExternalRequestErrorEvent__e> {
            new ExternalRequestErrorEvent__e(
                Action__c = 'Upsert',
                ContentFormat__c = 'JSON',
                Entity__c = 'Customer',
                ExternalRequestCreatedDate__c = System.now(),
                JobId__c = '9062I000000Xjj0QAC',
                Message__c = 'Test Message',
                Origin__c = 'INFO',
                Payload__c = '{"campo1": "valor1", "campo2": "valor2"}',
                RecordId__c = '9062I000000Xjj0QEM',
                StackTrace__c = 'Test Stack Trace',
                ThrowingTime__c = System.now()
                )
        };
        Test.startTest();
        ErrorLogUtil.handleExternalRequestErrors(errorEvents);
        Test.stopTest();
        List<ExternalRequestError__c> errorRecords = [
            SELECT Id
            FROM ExternalRequestError__c
        ];
        System.assertEquals(
            1,
            errorRecords.size(),
            '[0] No se han recuperado los registros esperados'
            );
    }

    @isTest
    private static void testCommitExternalRequestErrors()
    {
        // Insertar un external request
        ExternalRequest__c request = TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 1).get(0);
        insert request;

        Test.startTest();
        try
        {
            List<String> vals;
            String err = vals[0];
        }
        catch (Exception ex)
        {
            /* Test 1 */
            ErrorLogUtil.commitError(request, 'Test Message', '9062I000000Xjj0QAC');
            /* Test 2 */
            ErrorLogUtil.commitError(request, ex, '9062I000000Xjj0QAD');
        }
        Test.stopTest();

        List<ExternalRequestError__c> errorRecords = [
            SELECT Id
            FROM ExternalRequestError__c
        ];
        System.assertEquals(
            2,
            errorRecords.size(),
            '[0] No se han recuperado los registros esperados'
            );
    }

    @isTest
    private static void testCommitError_newWebFormRequest()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';
        List<Scope_Setting__mdt> scopeSettingsList = [
            SELECT Id, BusinessCode__c, Scope__c, Scope_Name__c
            FROM Scope_Setting__mdt
        ];
        System.assertEquals(false, scopeSettingsList.isEmpty(), 'List should NOT be empty');
        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON( 'CRM-01', '1111111A', emailFromJSON, phoneFromJSON, scopeSettingsList.get(0).BusinessCode__c, new List<Product2>() );
        String serializedJSON = JSON.serialize(jsonInformation);
        Test.startTest();
        ErrorLogUtil.commitError( 'warning', 'New webform request', 'WS_BusinessInsuranceAPIService', serializedJSON );
        Test.stopTest();

        List<Error_Log__c> errorRecords = [
            SELECT Id, Stack_Trace__c
            FROM Error_Log__c
        ];
        System.assertEquals(
            false,
            errorRecords.isEmpty(),
            'Debería existir un error log'
            );

        System.assertEquals(true, serializedJSON == errorRecords.get(0).Stack_Trace__c, 'StackTrace debería contener el valor de serializedJSON');
    }

    /**
     * Test del método que comprueba si se genera un error si falla la operación DML
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_generateMessageByError()
    {
        Case caseTest = new Case(Subject = 'Caso de prueba');
        insert caseTest;

        List<Case> caseToUpdate = new List<Case>();
        caseTest.OwnerId = null;
        caseToUpdate.add(caseTest);

        Test.startTest();
        ErrorLogUtil.generateMessageByError(Database.update(caseToUpdate, false),'Se ha producido un error actualizando los casos', Test_ErrorLogUtil.class.getName());
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id,Message__c,Source_Class__c  FROM Error_Log__c];
        Assert.isTrue(errorRecords.size() > 0, 'Deberia de haber algun error');
        Assert.areEqual(Test_ErrorLogUtil.class.getName(), errorRecords[0].Source_Class__c, 'La clase que ha generado el error no es correcta');
    }
}