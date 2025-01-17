@isTest
public with sharing class WS_ClientIdentificationServiceTest
{

    static final String REQUEST_URI_BYPOLICY = '/identification/v1/people/';
    static final String REQUEST_URI_BYPHONE = '/identification/v1/findByPhone/';
    static final String REQUEST_URI_BYREGISTRATIONNUMBER = '/identification/v1/findByRegistrationNumber/';

    static final String INVALID_REQUEST_URI_BYPOLICY = '/identification/va/people/';
    static final String INVALID_REQUEST_URI_BYPHONE = '/identification/va/findByPhone/';
    static final String INVALID_REQUEST_URI_BYREGISTRATIONNUMBER = '/identification/va/findByRegistrationNumber/';

    static final String CLIENT_REQUEST = '{"fullName": "Nombre Apellido", "nationalID": "12345678A","policyNumber": "12345678901234"}';
    static final String CLIENT_REQUEST_BYPHONE = '{"fullName": "Nombre Apellido", "nationalID": "12345678A","phoneNumber": "600112233", "groupDescription":"HOGAR"}';
    static final String CLIENT_REQUEST_BYREGISTRATIONNUMBER = '{"registrationNumber": "1111AAA", "groupDescription":"Motor"}';
    static final String CLIENT_REQUEST_WITHOUT_DNI =  '{"fullName": "Nombre Apellido",  "policyNumber": "12345678901234"}';
    static final String CLIENT_REQUEST_WITHOUT_PHONE = '{"fullName": "Nombre Apellido", "nationalID": "12345678A", "groupDescription":"HOGAR"}';
    static final String CLIENT_REQUEST_WITHOUT_REGISTRATIONNUMBER = '{"groupDescription":"Motor"}';

    static final String INCORRECT_JSON =  '"fullName": "Nombre Apellido", "policyNumber": "12345678901234"';


    @TestSetup
    public static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 1);
        insert accounts;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 10);
        insert policies;

        List<Asset> assets = TestDataFactory.generateInsuredObjectsForEachPolicy('Motor', policies, 1);
        insert assets;

        List<ContactPointPhone> contactPhones = TestDataFactory.generateContactPointPhonesFromAccounts(accounts, 1);
        insert contactPhones;
    }

    /**
     * Método que comprueba que se procesa correctamente la información. Enviamos un JSON correcto, nos debe devolver status 200
     *
     * @author arcortazar
     * @date 13/06/2022
     */
    @isTest
    static void test_doPost_processInformation_clients_ok()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI_BYPOLICY;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(CLIENT_REQUEST);
        RestContext.request = request;

        System.debug('++++ request: ' + request);

        Test.startTest();
        WS_ClientIdentificationService.doPost();
        Test.stopTest();

        System.assertEquals(
            200,
            response.statusCode,
            'Response statusCode should be 200'
            );
    }

    /**
     * Método que comprueba que se procesa correctamente la información. Enviamos un JSON correcto, nos debe devolver status 200
     *
     * @author arcortazar
     * @date 03/08/2023
     */
    @isTest
    static void test_doPost_processInformation_byPhoneNumber_ok()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI_BYPHONE;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(CLIENT_REQUEST_BYPHONE);
        RestContext.request = request;

        Test.startTest();
        WS_ClientIdentificationService.doPost();
        Test.stopTest();

        System.assertEquals(
            200,
            response.statusCode,
            'Response statusCode should be 200'
            );
    }

    /**
     * Método que comprueba que se procesa correctamente la información. Enviamos un JSON correcto, nos debe devolver status 200
     *
     * @author jfherrero
     * @date 31/10/2023
     */
    @isTest
    static void test_doPost_processInformation_byRegistrationNumber_ok()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI_BYREGISTRATIONNUMBER;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(CLIENT_REQUEST_BYREGISTRATIONNUMBER);
        RestContext.request = request;

        Test.startTest();
        WS_ClientIdentificationService.doPost();
        Test.stopTest();

        System.assertEquals(
            200,
            response.statusCode,
            'Response statusCode should be 200'
            );
    }

    /**
     * Método que comprueba que se lanza un error cuando la URI no es correcta
     *
     * @author arcortazar
     * @date 13/06/2022
     */
    @isTest
    static void test_doPost_processInformation_invalidURI_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = INVALID_REQUEST_URI_BYPOLICY;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(CLIENT_REQUEST);
        RestContext.request = request;

        Test.startTest();
        WS_ClientIdentificationService.doPost();
        Test.stopTest();

        System.debug('++++ Status: ' + response.statusCode + ', ' + response.responseBody);
        System.assertNotEquals(
            200,
            response.statusCode,
            'Response statusCode should be 200'
            );
    }

    /**
     * Método que comprueba que se lanza un error cuando la URI no es correcta
     *
     * @author arcortazar
     * @date 03/08/2023
     */
    @isTest
    static void test_doPost_processInformation_invalidURI_byPhone_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = INVALID_REQUEST_URI_BYPHONE;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(CLIENT_REQUEST_BYPHONE);
        RestContext.request = request;

        Test.startTest();
        WS_ClientIdentificationService.doPost();
        Test.stopTest();

        System.debug('++++ Status: ' + response.statusCode + ', ' + response.responseBody);
        System.assertNotEquals(
            200,
            response.statusCode,
            'Response statusCode should be 200'
            );
    }

    /**
     * Método que comprueba que se lanza un error cuando no llegan los campos obligatorios
     *
     * @author arcortazar
     * @date 13/06/2022
     */
    @isTest
    static void test_doPost_processInformation_missingDNI_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI_BYPOLICY;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(CLIENT_REQUEST_WITHOUT_DNI);
        RestContext.request = request;

        Test.startTest();
        WS_ClientIdentificationService.doPost();
        Test.stopTest();

        System.debug('++++ Status: ' + response.statusCode + ', ' + response.responseBody);
        System.assertNotEquals(
            200,
            response.statusCode,
            'Response statusCode should not be 200'
            );
    }

    /**
     * Método que comprueba que se lanza un error cuando no llegan los campos obligatorios
     *
     * @author arcortazar
     * @date 03/08/2023
     */
    @isTest
    static void test_doPost_processInformation_missingPhone_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI_BYPHONE;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(CLIENT_REQUEST_WITHOUT_PHONE);
        RestContext.request = request;

        Test.startTest();
        WS_ClientIdentificationService.doPost();
        Test.stopTest();

        System.debug('++++ Status: ' + response.statusCode + ', ' + response.responseBody);
        System.assertNotEquals(
            200,
            response.statusCode,
            'Response statusCode should not be 200'
            );
    }

    /**
     * Método que comprueba que se lanza un error si el JSON recibido no respeta la estructura definida
     **
     * @author arcortazar
     * @date 13/06/2022
     */
    @isTest
    static void test_doPost_processInformation_invalidJSON_offers_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI_BYPOLICY;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(INCORRECT_JSON);
        RestContext.request = request;

        Test.startTest();
        WS_ClientIdentificationService.doPost();
        Test.stopTest();

        System.debug('++++ Status: ' + response.statusCode + ', ' + response.responseBody);

        System.assertEquals(
            400,
            response.statusCode,
            'Response statusCode should be 400'
            );
    }
}
