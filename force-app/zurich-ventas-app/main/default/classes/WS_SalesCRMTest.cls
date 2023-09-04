/**
 * @description       : Clase de test que comprueba el correcto funcionamiento
 * del servicio web Ws_SalesCRM.
 * @author            : amiranda
 * @date              : 04-09-2023
 * @last modified on  : 04-09-2023
 * @last modified by  : amiranda
 * Modifications Log
 * Ver   Date         Author     Modification
 * 1.0   01-09-2023   amiranda   Initial Version
 **/
@isTest
public with sharing class WS_SalesCRMTest
{
    static final String LEAD_GENERATION_URI = '/zrm/v1/leadGeneration';
    static final String QUOTE_AND_BUY_GENERATION_URI = '/zrm/v1/quoteAndBuy';
    static final String INVALID_VERSION_URI = '/zrm/version/leadGeneration';
    static final String INVALID_RESOURCE_URI = '/zrm/v1/invalidResource';
    static final String HTTP_POST_METHOD = 'POST';
    static final String HEADER_CONTENT_TYPE = 'Content-Type';
    static final String HEADER_APPLICATION_JSON = 'application/json';

    static final String ASSERT_ERROR_LOGS_COMMITTED_MESSAGE = 'Errors should be committed';
    static final String ASSERT_ERROR_LOGS_LEVEL_MESSAGE = 'Error log level should be ' + ErrorLogUtil.ERROR_LEVEL_ERROR;
    static final String ASSERT_ERROR_LOGS_WARNING_LEVEL_MESSAGE = 'Error log level should be ' + ErrorLogUtil.ERROR_LEVEL_WARNING;
    static final String ASSERT_STATUS_CODE_400_MESSAGE = 'Response statusCode should be 400';

    @TestSetup
    static void makeData()
    {
        List<Account> intermediaries = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 1);
        insert intermediaries;

        List<Contact> intermediaryContacts = TestDataFactory.generateContactsFromAccounts(intermediaries, 'Contact', 1);
        insert intermediaryContacts;

        Id portalUsersProfileId = [SELECT Id FROM Profile
                                   WHERE Name = 'Agente Ventas' LIMIT 1].Id;
        UserRole portalRoleId = [SELECT Id FROM UserRole
                                 WHERE PortalType = 'None' LIMIT 1];
        List<User> mediatorUsers = TestDataFactory.generateUsersByProfile(portalUsersProfileId, 1);
        mediatorUsers.get(0).Alias = 'agente.m';
        mediatorUsers.get(0).UserRole = portalRoleId;
        mediatorUsers.get(0).ContactId = intermediaryContacts.get(0).Id;
        insert mediatorUsers;
    }

    /**
     * @description Método que comprueba el correcto procesamiento de la petición
     * realizada al recurso 'leadGeneration'.
     *
     * @author amiranda
     * @date 04-09-2023
     **/
    @isTest
    static void test_doPost_processRequest_leadGeneration_ok()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = LEAD_GENERATION_URI;
        request.httpMethod = HTTP_POST_METHOD;
        request.addHeader(HEADER_CONTENT_TYPE, HEADER_APPLICATION_JSON);

        String requestData = '{' +
                             '"origin":"formulario embarcaciones",' +
                             '"name":"Test Name",' +
                             '"phone":"+3400000000",' +
                             '"language": "German",' +
                             '"productBranch": "0000000001",' +
                             '"webIdentifier": "1234",' +
                             '"bestTimeFrom": "2023-06-26T11:00:00.000Z",' +
                             '"documentId": "00000000L"' +
                             '}';

        request.requestBody = Blob.valueOf(requestData);

        RestContext.response = response;
        RestContext.request = request;

        Test.startTest();
        WS_SalesCRM.doPost();
        Test.stopTest();

        Assert.areEqual(200,
                        response.statusCode,
                        'Response statusCode should be 200');

        List<Error_Log__c> errors = [SELECT Id, Level__c FROM Error_Log__c];
        Assert.areEqual(false,
                        errors.isEmpty(),
                        ASSERT_ERROR_LOGS_COMMITTED_MESSAGE);

        for (Error_Log__c error : errors)
        {
            Assert.areEqual(ErrorLogUtil.ERROR_LEVEL_WARNING.toLowerCase(),
                            error.Level__c.toLowerCase(),
                            ASSERT_ERROR_LOGS_LEVEL_MESSAGE);
        }
    }

    /**
     * @description Método que comprueba que se lanza un error si la versión de
     * URI no cumple con el formato especificado (v*) - Ver la clase 'WS_BaseAPI'.
     *
     * @author amiranda
     * @date 01-09-2023
     **/
    @isTest
    static void test_doPost_invalidVersionURI_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = INVALID_VERSION_URI;
        request.httpMethod = HTTP_POST_METHOD;
        request.addHeader(HEADER_CONTENT_TYPE, HEADER_APPLICATION_JSON);
        request.requestBody = Blob.valueOf('{}');

        RestContext.response = response;
        RestContext.request = request;

        Test.startTest();
        WS_SalesCRM.doPost();
        Test.stopTest();

        Assert.areEqual(400,
                        response.statusCode,
                        ASSERT_STATUS_CODE_400_MESSAGE);
        Assert.areEqual(true,
                        response.responseBody.toString().contains('Invalid URI versioning'),
                        'Response body should contains \'Invalid URI versioning\' error message');

        List<Error_Log__c> errors = [SELECT Id, Level__c FROM Error_Log__c];
        Assert.areEqual(false,
                        errors.isEmpty(),
                        ASSERT_ERROR_LOGS_COMMITTED_MESSAGE);

        for (Error_Log__c error : errors)
        {
            Assert.areEqual(ErrorLogUtil.ERROR_LEVEL_ERROR.toLowerCase(),
                            error.Level__c.toLowerCase(),
                            ASSERT_ERROR_LOGS_LEVEL_MESSAGE);
        }
    }

    /**
     * @description Método que comprueba que se lanza un error si el JSON recibido no
     * respeta la estructura definida para el recurso 'leadGeneration'.
     *
     * @author amiranda
     * @date 01-09-2023
     **/
    @isTest
    static void test_doPost_leadGenerationInvalidJSON_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = LEAD_GENERATION_URI;
        request.httpMethod = HTTP_POST_METHOD;
        request.addHeader(HEADER_CONTENT_TYPE, HEADER_APPLICATION_JSON);
        request.requestBody = Blob.valueOf('{"fullName": "Nombre Apellido", "nationalID": "12345678A","policyNumber": "12345678901234"}');

        RestContext.response = response;
        RestContext.request = request;

        Test.startTest();
        WS_SalesCRM.doPost();
        Test.stopTest();

        Assert.areEqual(400,
                        response.statusCode,
                        ASSERT_STATUS_CODE_400_MESSAGE);

        List<Error_Log__c> errors = [SELECT Id, Level__c FROM Error_Log__c];
        Assert.areEqual(false,
                        errors.isEmpty(),
                        ASSERT_ERROR_LOGS_COMMITTED_MESSAGE);

        for (Error_Log__c error : errors)
        {
            Assert.areEqual(ErrorLogUtil.ERROR_LEVEL_ERROR.toLowerCase(),
                            error.Level__c.toLowerCase(),
                            ASSERT_ERROR_LOGS_LEVEL_MESSAGE);
        }
    }

    /**
     * @description Método que comprueba que se lanza un error si el recurso de
     * la URI no corresponde con ninguno de los que se espera recibir. Consultar
     * la declaración de flujo de control 'switch' de la clase 'WS_SalesCRM'.
     *
     * @author amiranda
     * @date 01-09-2023
     **/
    @isTest
    static void test_doPost_invalidResourceURI_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = INVALID_RESOURCE_URI;
        request.httpMethod = HTTP_POST_METHOD;
        request.addHeader(HEADER_CONTENT_TYPE, HEADER_APPLICATION_JSON);
        request.requestBody = Blob.valueOf('{}');

        RestContext.response = response;
        RestContext.request = request;

        Test.startTest();
        WS_SalesCRM.doPost();
        Test.stopTest();

        Assert.areEqual(500,
                        response.statusCode,
                        ASSERT_STATUS_CODE_400_MESSAGE);
        Assert.areEqual(true,
                        response.responseBody.toString().contains('Invalid resource for the request:'),
                        'Response body should contains \'Invalid resource for the request:\' error message');

        List<Error_Log__c> errors = [SELECT Id, Level__c FROM Error_Log__c];
        Assert.areEqual(false,
                        errors.isEmpty(),
                        ASSERT_ERROR_LOGS_COMMITTED_MESSAGE);

        for (Error_Log__c error : errors)
        {
            Assert.areEqual(ErrorLogUtil.ERROR_LEVEL_ERROR.toLowerCase(),
                            error.Level__c.toLowerCase(),
                            ASSERT_ERROR_LOGS_LEVEL_MESSAGE);
        }
    }

    /**
    * @description Método que comprueba que se lanza un error si alguno de
    * los campos requeridos no se encuentra en la información recibida en el
    * recurso 'leadGeneration'.
    *
    * @author amiranda 
    * @date 04-09-2023 
    **/
    @isTest
    static void test_doPost_missingRequiredFields_leadGeneration_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.requestURI = LEAD_GENERATION_URI;
        request.httpMethod = HTTP_POST_METHOD;
        request.addHeader(HEADER_CONTENT_TYPE, HEADER_APPLICATION_JSON);

        String requestData = '{' +
                             // '"origin":"formulario embarcaciones",' +
                             '"name":"Test Name",' +
                             '"phone":"+3400000000",' +
                             '"language": "German",' +
                             '"productBranch": "0000000001",' +
                             '"webIdentifier": "1234",' +
                             '"bestTimeFrom": "2023-06-26T11:00:00.000Z",' +
                             '"documentId": "00000000L"' +
                             '}';

        request.requestBody = Blob.valueOf(requestData);

        RestContext.response = response;
        RestContext.request = request;

        Test.startTest();
        WS_SalesCRM.doPost();
        Test.stopTest();

        Assert.areEqual(400,
                        response.statusCode,
                        ASSERT_STATUS_CODE_400_MESSAGE);

        List<Error_Log__c> errors = [SELECT Id, Level__c FROM Error_Log__c];
        Assert.areEqual(false,
                        errors.isEmpty(),
                        ASSERT_ERROR_LOGS_COMMITTED_MESSAGE);

        for (Error_Log__c error : errors)
        {
            Assert.areEqual(ErrorLogUtil.ERROR_LEVEL_ERROR.toLowerCase(),
                            error.Level__c.toLowerCase(),
                            ASSERT_ERROR_LOGS_LEVEL_MESSAGE);
        }
    }
}