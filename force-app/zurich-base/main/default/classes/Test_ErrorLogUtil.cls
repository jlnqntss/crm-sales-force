/**
 * Clases de test para ErrorLogUtil
 **
 * @author nts
 * @date 24/02/2020
 */
@isTest(SeeAllData = false)
public class Test_ErrorLogUtil
{
    @testSetup
    static void makeData()
    {
    }

    @isTest
    static void testCommitErrors()
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
    static void testHandleErrors()
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
    static void test_ErrorLogHandlerMethods()
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
    static void testHandleExternalRequestErrors()
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
    static void testCommitExternalRequestErrors()
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
}