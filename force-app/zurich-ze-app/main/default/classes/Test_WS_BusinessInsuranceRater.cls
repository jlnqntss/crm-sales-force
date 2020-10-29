/**
 * Clases de test para WS_BusinessInsuranceRater
 **
 * @author rlopez
 * @date 15/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class Test_WS_BusinessInsuranceRater {
  static final String REQUEST_URI = '/ze/v1/rates/';
  static final String INVALID_REQUEST_URI = '/ze/va/rates/';
  //static final String JSON_INFORMATION = '{"TimeStamp":"2020-04-28T12:23:00","WebEmail":"test@test.com","WebPhone":"600666000","SessionId":"xxxxx","BusinessCode":"3200011531","LastStep":"CRM-01","Status":"Activo","AccountInformation":{"FirstName":"Nombre","LastName":"Apellidos","Family":"10","CommercialActivity":"101100","AnnualRevenue":"200000.10","NumberOfEmployees":"150","TradeName":"Nombre comercial","CompanyName":"Nombre Compañía","NationalIdentifier":"B111111111"},"Offers":[{"QuoteNumberINFO":"456789456","QuoteNumberJRE":"5555555","PolicyNumber":"654654654","OperationCode":"P1","BusinessCode":"3200011531","EffectiveDate":"2020-09-28","CommercialPC":"00001","TechnicalPC":"00526","PaymentType":"A","PaymentTypeSucc":"A","PaymentChannel":"CC","PaymentChannelSucc":"CC","Language":"ES","BuildingCapital":"120000","ContentCapital":"12000","GeneralLiabilityLimit":"12000","NetPremium":"12000","ValidationErrors":"","OfferRiskInformation":{"PropertyStreetType":"VI","PropertyStreet":"Via Augusta","PropertyStreetNumber":"12","PropertyAdditionalInfo":"","PropertyPostalCode":"08006","PropertyCity":"Barcelona","PropertyState":"8","PropertyCountry":"ESP","YearOfConstruction":"1960","Ownership":"P","InsuredType":"I","BuildingType":"I","Height":"AL","RiskFactor01":"0001","RiskFactor02":"","RiskFactor03":"","RiskFactor04":"","RiskFactor05":"","RiskFactor06":"","RiskFactor07":"","RiskFactor08":"0039","RiskFactor09":"","Area":"50","LockType":true,"SecurityDoor":false,"BulletproofDoor":false,"ConnectedAlarm":false,"FireHydrant":false,"Surveillance":false,"SmokeDetector":false,"Sprayer":false,"FireExtinguisher":true,"TypeOfWindows":"2","Strongbox":"N"}}]}';
  static final String JSON_INFORMATION = '{"TimeStamp":"2020-04-28T12:23:00","WebEmail":true,"WebPhone":"600666000","SessionId":"xxxxx","BusinessCode":"3200011531","LastStep":"CRM-01","Status":"Activo","Manager":{"FirstName":"ManagerFirstName","LastName":"ManagerLastName","Email":"manageremail@manager.com","Phone":"123456789"},"AccountInformation":{"FirstName":"Nombre","LastName":"Apellidos","Family":"10","CommercialActivity":"101100","AnnualRevenue":"200000.10","NumberOfEmployees":"150","TradeName":"Nombre comercial","CompanyName":"Nombre Compañía","NationalIdentifier":"B111111111"},"Offers":[{"QuoteNumberINFO":"456789456","QuoteNumberJRE":"5555555","PolicyNumber":"654654654","OperationCode":"P1","BusinessCode":"3200011531","EffectiveDate":"2020-09-28","CommercialPC":"00001","TechnicalPC":"00526","PaymentType":"A","PaymentTypeSucc":"A","PaymentChannel":"CC","PaymentChannelSucc":"CC","Language":"ES","BuildingCapital":"120000","ContentCapital":"12000","GeneralLiabilityLimit":"12000","NetPremium":"12000","ValidationErrors":"","OfferRiskInformation":{"PropertyStreetType":"VI","PropertyStreet":"Via Augusta","PropertyStreetNumber":"12","PropertyAdditionalInfo":"","PropertyPostalCode":"08006","PropertyCity":"Barcelona","PropertyState":"8","PropertyCountry":"ESP","YearOfConstruction":"1960","Ownership":"P","InsuredType":"I","BuildingType":"I","Height":"AL","RiskFactor01":"0001","RiskFactor02":"","RiskFactor03":"","RiskFactor04":"","RiskFactor05":"","RiskFactor06":"","RiskFactor07":"","RiskFactor08":"0039","RiskFactor09":"","Area":"50","LockType":true,"SecurityDoor":false,"BulletproofDoor":false,"ConnectedAlarm":false,"FireHydrant":false,"Surveillance":false,"SmokeDetector":false,"Sprayer":false,"FireExtinguisher":true,"TypeOfWindows":"2","Strongbox":"N"}}]}';

  /**
   * Método que comprueba una ejecución correcta de doPost
   **
   * @author rlopez
   * @date 15/10/2020
   */
  @isTest
  static void test_doPost_processInformation_ok() {
    RestRequest request = new RestRequest();
    RestResponse response = new RestResponse();
    RestContext.response = response;

    request.requestUri = REQUEST_URI;
    request.httpMethod = 'POST';
    request.addHeader('Content-Type', 'application/json');
    request.requestBody = Blob.valueOf(JSON_INFORMATION);
    RestContext.request = request;

    Test.startTest();
    WS_BusinessInsuranceRater.doPost();
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
  static void test_doPost_processInformation_invalidURI_ko() {
    RestRequest request = new RestRequest();
    RestResponse response = new RestResponse();
    RestContext.response = response;

    request.requestUri = INVALID_REQUEST_URI;
    request.httpMethod = 'POST';
    request.addHeader('Content-Type', 'application/json');
    request.requestBody = Blob.valueOf('{}');

    RestContext.request = request;

    Test.startTest();
    WS_BusinessInsuranceRater.doPost();
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
  static void test_doPost_processInformation_invalidContentType_ko() {
    RestRequest request = new RestRequest();
    RestResponse response = new RestResponse();
    RestContext.response = response;

    request.requestUri = REQUEST_URI;
    request.httpMethod = 'POST';
    request.requestBody = Blob.valueOf('{}');

    RestContext.request = request;

    Test.startTest();
    WS_BusinessInsuranceRater.doPost();
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
  static void test_doPost_processInformation_missingLastStep_ko() {
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

    requestInformationJSON.remove('LastStep');
    String requestInformationWithoutLastStep = JSON.serialize(
      requestInformationJSON
    );

    request.requestBody = Blob.valueOf(requestInformationWithoutLastStep);

    RestContext.request = request;

    Test.startTest();
    WS_BusinessInsuranceRater.doPost();
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
  static void test_doPost_processInformation_invalidJSON_ko() {
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
    WS_BusinessInsuranceRater.doPost();
    Test.stopTest();

    System.assertEquals(
      400,
      response.statusCode,
      'Response statusCode should be 400'
    );

    System.assertEquals(
      true,
      response.responseBody.toString().contains('Error deserializing JSON'),
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
   * Método que comprueba que se lanza un error si no recibimos un JSON en el request body
   **
   * @author rlopez
   * @date 29/10/2020
   */
  @isTest
  static void test_doPost_processInformation_notJSON_ko() {
    RestRequest request = new RestRequest();
    RestResponse response = new RestResponse();
    RestContext.response = response;

    request.requestUri = REQUEST_URI;
    request.httpMethod = 'POST';
    request.addHeader('Content-Type', 'application/json');

    request.requestBody = null;

    RestContext.request = request;

    Test.startTest();
    WS_BusinessInsuranceRater.doPost();
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
