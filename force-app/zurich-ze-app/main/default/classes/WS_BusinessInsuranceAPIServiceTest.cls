/**
 * Clases de test para WS_BusinessInsuranceAPIService
 **
 * @author rlopez
 * @date 15/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class WS_BusinessInsuranceAPIServiceTest
{
    static final String REQUEST_URI = '/ze/v1/offers/';
    static final String INVALID_REQUEST_URI = '/ze/va/offers/';
    static final String INTERACTIONS_REQUEST = '{"name":"Carles Sans","phone":"600666000","bestTimeFrom":"2020-09-28T06:00:00.000Z","bestTimeUntil":"2020-09-28T09:00:00.000Z"}';
    static final String INTERACTIONS_REQUEST_WITHOUT_PHONE = '{"name":"Carles Sans","bestTimeFrom":"2020-09-28T06:00:00.000Z","bestTimeUntil":"2020-09-28T09:00:00.000Z"}';
    static final String INTERACTIONS_URI = '/ze/v1/interactions/';
    static final String INTERACTIONS_MOCK_BODY = '{"conversation":{"id":"7e131fcf-1639-45b2-89e5-9c3787b5dc75","selfUri":"/api/v2/conversations/7e131fcf-1639-45b2-89e5-9c3787b5dc75"},' +
                                                 '"callbackIdentifiers":[{"type":"EXTERNAL","id":"4b005d83-8246-4eb5-a89c-3f948751632b"},{"type":"ACD","id":"9f359553-e45b-42c3-8420-99bb01582eb9"}]}';

    @TestSetup
    static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'Customer', 10);
        insert accounts;

        List<Scope__c> scopes = TestDataFactory.generateScopesForEachAccount(accounts, 'ZE', 1);
        insert scopes;

        List<Product2> products = TestDataFactory.generateProducts(10);
        insert products;
    }

    /**
     * Método que comprueba una ejecución correcta de doPost
     **
     * @author rlopez
     * @date 15/10/2020
     */
    @isTest
    static void test_doPost_processInformation_offers_ok()
    {
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, existingProducts);

        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf( JSON.serialize(jsonInformation) );
        RestContext.request = request;

        Test.startTest();
        WS_BusinessInsuranceAPIService.doPost();
        Test.stopTest();

        System.assertEquals(
            200,
            response.statusCode,
            'Response statusCode should be 200'
            );

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        // FIXME: System.assertEquals(
        //     true,
        //     errors.isEmpty(),
        //     'List of errors should be empty'
        //     );
    }

    /**
     * Método que comprueba que se lanza un error si la versión de la URI no cumple el formato especificado (v*)
     **
     * @author rlopez
     * @date 16/10/2020
     */
    @isTest
    static void test_doPost_processInformation_invalidURI_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = INVALID_REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{}');

        RestContext.request = request;

        Test.startTest();
        WS_BusinessInsuranceAPIService.doPost();
        Test.stopTest();

        System.assertEquals(
            400,
            response.statusCode,
            'Response statusCode should be 400'
            );

        System.assertEquals(
            true,
            response.responseBody.toString().contains('Invalid URI versioning'),
            'Response body should contains this error message'
            );

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(
            false,
            errors.isEmpty(),
            'List of errors shouldnt be empty'
            );
    }

    /**
     * Método que comprueba que se lanza un error si la versión de la URI no cumple el formato especificado (v*)
     **
     * @author rlopez
     * @date 28/10/2020
     */
    @isTest
    static void test_doPost_processInformation_invalidContentType_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf('{}');

        RestContext.request = request;

        Test.startTest();
        WS_BusinessInsuranceAPIService.doPost();
        Test.stopTest();

        System.assertEquals(
            400,
            response.statusCode,
            'Response statusCode should be 400'
            );

        System.assertEquals(
            true,
            response.responseBody.toString()
            .contains('Invalid Content-Type on request headers'),
            'Response body should contains this error message'
            );

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(
            false,
            errors.isEmpty(),
            'List of errors shouldnt be empty'
            );
    }

    /**
     * Método que comprueba que se lanza un error si no tenemos campo LastStep en la información recibida
     **
     * @author rlopez
     * @date 29/10/2020
     */
    @isTest
    static void test_doPost_processInformation_missingLastStep_offers_ko()
    {
        //Preparamos el JSON
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, existingProducts);

        //Preparamos la request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');

        //Eliminamos LastStep del JSO
        jsonInformation.remove('lastStep');

        String requestInformationWithoutLastStep = JSON.serialize(
            jsonInformation
            );

        request.requestBody = Blob.valueOf(requestInformationWithoutLastStep);

        RestContext.request = request;

        Test.startTest();
        WS_BusinessInsuranceAPIService.doPost();
        Test.stopTest();

        System.assertEquals(
            400,
            response.statusCode,
            'Response statusCode should be 400'
            );

        System.assertEquals(
            true,
            response.responseBody.toString().contains('LastStep field missing'),
            'Response body should contains this error message'
            );

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(
            false,
            errors.isEmpty(),
            'List of errors shouldnt be empty'
            );
    }

    /**
     * Método que comprueba que se lanza un error si el JSON recibido no respeta la estructura definida
     **
     * @author rlopez
     * @date 29/10/2020
     */
    @isTest
    static void test_doPost_processInformation_invalidJSON_offers_ko()
    {
        //Preparamos el JSON
        String emailFromJSON = 'newemail@fakeemail.com.invalid';
        String phoneFromJSON = '123456789';

        List<Account> existingAccounts = [SELECT Id, NationalId__c FROM Account WHERE NationalId__c != null];
        System.assertEquals(false, existingAccounts.isEmpty(), 'List should NOT be empty');

        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Map<String, Object> jsonInformation = TestDataFactory.generateBusinessInsuranceOffersWebJSON('CRM-08', existingAccounts.get(0).NationalId__c, emailFromJSON, phoneFromJSON, existingProducts);

        //Preparamos la request
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');

        //Añadimos un campo que no existe en la estructura definida
        jsonInformation.put('undefinedField', 'undefinedValue');
        String invalidRequestInformation = JSON.serialize(jsonInformation);

        request.requestBody = Blob.valueOf(invalidRequestInformation);

        RestContext.request = request;

        Test.startTest();
        WS_BusinessInsuranceAPIService.doPost();
        Test.stopTest();

        System.assertEquals(
            400,
            response.statusCode,
            'Response statusCode should be 400'
            );

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(
            false,
            errors.isEmpty(),
            'List of errors shouldnt be empty'
            );
    }

    /**
     * Método que comprueba que se lanza un error si no recibimos un JSON en el request body
     **
     * @author rlopez
     * @date 29/10/2020
     */
    @isTest
    static void test_doPost_processInformation_notJSON_offers_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');

        request.requestBody = null;

        RestContext.request = request;

        Test.startTest();
        WS_BusinessInsuranceAPIService.doPost();
        Test.stopTest();

        System.assertEquals(
            500,
            response.statusCode,
            'Response statusCode should be 500'
            );

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(
            false,
            errors.isEmpty(),
            'List of errors shouldnt be empty'
            );
    }

    /**
     * Prueba una Request de CallMeBack
     * Se debería crear un ContactRequest con los datos en SF
     */
    @isTest
    static void test_doPost_interactions_ok()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = INTERACTIONS_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(INTERACTIONS_REQUEST);
        RestContext.request = request;

        //Como no se está creando la cola de purecloud__PureCloud_Queue__c no hace falta
        //setear el GenesysCloudMock ya que no va a entrar en el ProcessBuilder que enruta

        Test.startTest();
        WS_BusinessInsuranceAPIService.doPost();
        Test.stopTest();

        System.assertEquals(200, response.statusCode,'Response statusCode should be 200');

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(true, errors.isEmpty(),'List of errors should be empty');
        List<ContactRequest> contactRequests = [SELECT Id FROM ContactRequest];
        System.assertEquals(1, contactRequests.size(), 'Debería haberse insertado un contact request');
    }

    /**
     * Prueba una Request de CallMeBack
     * Debería dar FALLO porque no tiene el campo phone relleno
     */
    @isTest
    static void test_doPost_interactions_ko()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = INTERACTIONS_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        //metemos un body sin campo phone y como requiere el campo phone, dará error
        request.requestBody = Blob.valueOf(INTERACTIONS_REQUEST_WITHOUT_PHONE);
        RestContext.request = request;

        Test.startTest();
        WS_BusinessInsuranceAPIService.doPost();
        Test.stopTest();

        System.assertEquals(400, response.statusCode,'Response statusCode should be 400');

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(false, errors.isEmpty(),'List of errors should not be empty');

        List<ContactRequest> contactRequests = [SELECT Id FROM ContactRequest];
        System.assertEquals(0, contactRequests.size(), 'NO debería haberse insertado un contact request');
    }
}
