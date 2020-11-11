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
    static final String JSON_INFORMATION = '{"timeStamp":"2020-04-28T12:23:00","webEmail":true,"webPhone":"600666000","sessionId":"xxxxx","businessCode":"3200011531","lastStep":"CRM-01","status":"Activo","manager":{"firstName":"ManagerFirstName","lastName":"ManagerLastName","email":"manageremail@manager.com","phone":"123456789"},"accountInformation":{"firstName":"Nombre","lastName":"Apellidos","family":"10","commercialActivity":"101100","annualRevenue":"200000.10","numberOfEmployees":"150","tradeName":"Nombre comercial","companyName":"Nombre Compañía","nationalIdentifier":"B111111111"},"offers":[{"quoteNumberINFO":"456789456","quoteNumberJRE":"5555555","policyNumber":"654654654","operationCode":"P1","businessCode":"3200011531","effectiveDate":"2020-09-28","commercialPC":"00001","technicalPC":"00526","paymentType":"A","paymentTypeSucc":"A","paymentChannel":"CC","paymentChannelSucc":"CC","language":"ES","buildingCapital":"120000","contentCapital":"12000","generalLiabilityLimit":"12000","netPremium":"12000","validationErrors":"","offerRiskInformation":{"propertyStreetType":"VI","propertyStreet":"Via Augusta","propertyStreetNumber":"12","propertyAdditionalInfo":"","propertyPostalCode":"08006","propertyCity":"Barcelona","propertyState":"8","propertyCountry":"ESP","yearOfConstruction":"1960","ownership":"P","insuredType":"I","buildingType":"I","height":"AL","riskFactor01":"0001","riskFactor02":"","riskFactor03":"","riskFactor04":"","riskFactor05":"","riskFactor06":"","riskFactor07":"","riskFactor08":"0039","riskFactor09":"","area":"50","lockType":true,"securityDoor":false,"bulletproofDoor":false,"connectedAlarm":false,"fireHydrant":false,"surveillance":false,"smokeDetector":false,"sprayer":false,"fireExtinguisher":true,"typeOfWindows":"2","strongbox":"N"}}]}';

    /**
     * Método que comprueba una ejecución correcta de doPost
     **
     * @author rlopez
     * @date 15/10/2020
     */
    @isTest
    static void test_doPost_processInformation_offers_ok()
    {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(JSON_INFORMATION);
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
        System.assertEquals(
            true,
            errors.isEmpty(),
            'List of errors should be empty'
            );
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
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');

        //Eliminamos LastStep del JSON
        Map<String, Object> requestInformationJSON = (Map<String, Object>) JSON.deserializeUntyped(
            JSON_INFORMATION
            );

        requestInformationJSON.remove('lastStep');
        String requestInformationWithoutLastStep = JSON.serialize(
            requestInformationJSON
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
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        RestContext.response = response;

        request.requestUri = REQUEST_URI;
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');

        //Añadimos un campo que no existe en la estructura definida
        Map<String, Object> requestInformationJSON = (Map<String, Object>) JSON.deserializeUntyped(
            JSON_INFORMATION
            );

        requestInformationJSON.put('undefinedField', 'undefinedValue');
        String invalidRequestInformation = JSON.serialize(requestInformationJSON);

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
}
