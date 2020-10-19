/**
 * Clases de test para WS_BusinessServiceQuoting
 **
 * @author rlopez
 * @date 15/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class Test_WS_BusinessServiceQuoting {
  static final String REQUEST_URI = '/v1/ze/services/quotes/';
  static final String INVALID_REQUEST_URI = '/va/ze/services/quotes/';
  static final String JSON_INFORMATION = '{\n\"TimeStamp\":\"2020-04-28T12:23:00\",\n\"WebEmail\":\"test@test.com\",\n\"WebPhone\":\"600666000\",\n\"SessionId\":\"xxxxx\",\n\"BusinessCode\":\"3200011531\",\n\"LastStep\":\"CRM-09\",\n\"Status\":\"Activo\",\n\"Cuenta\":{\n\"FirstName\":\"Nombre\",\n\"LastName\":\"Apellidos\",\n\"Family\":\"10\",\n\"CommercialActivity\":\"101100\",\n\"AnnualRevenue\":\"200000.10\",\n\"NumberOfEmployees\":\"150\",\n\"TradeName\":\"Nombre comercial\",\n\"CompanyName\":\"Nombre Compañía\",\n\"NationalIdentifier\":\"B111111111\"\n},\n\"Ofertas\":[\n{\n\"QuoteNumberINFO\":\"456789456\",\n\"QuoteNumberJRE\":\"5555555\",\n\"PolicyNumber\":\"654654654\",\n\"OperationCode\":\"P1\",\n\"BusinessCode\":\"3200011531\",\n\"EffectiveDate\":\"2020-09-28\",\n\"CommercialPC\":\"00001\",\n\"TechnicalPC\":\"00526\",\n\"PaymentType\":\"A\",\n\"PaymentTypeSucc\":\"A\",\n\"PaymentChannel\":\"CC\",\n\"PaymentChannelSucc\":\"CC\",\n\"Language\":\"ES\",\n\"BuildingCapital\":\"120000\",\n\"ContentCapital\":\"12000\",\n\"GeneralLiabilityLimit\":\"12000\",\n\"NetPremium\":\"12000\",\n\"ValidationErrors\":\"\",\n\"Riesgo\":{\n\"PropertyStreetType\":\"VI\",\n\"PropertyStreet\":\"Via Augusta\",\n\"PropertyStreetNumber\":\"12\",\n\"PropertyAdditionalInfo\":\"\",\n\"PropertyPostalCode\":\"08006\",\n\"PropertyCity\":\"Barcelona\",\n\"PropertyState\":\"8\",\n\"PropertyCountry\":\"ESP\",\n\"YearOfConstruction\":\"1960\",\n\"Ownership\":\"P\",\n\"InsuredType\":\"I\",\n\"BuildingType\":\"I\",\n\"Height\":\"AL\",\n\"RiskFactor01\":\"0001\",\n\"RiskFactor02\":\"\",\n\"RiskFactor03\":\"\",\n\"RiskFactor04\":\"\",\n\"RiskFactor05\":\"\",\n\"RiskFactor06\":\"\",\n\"RiskFactor07\":\"\",\n\"RiskFactor08\":\"0039\",\n\"RiskFactor09\":\"\",\n\"Area\":\"50\",\n\"LockType\":true,\n\"SecurityDoor\":false,\n\"BulletproofDoor\":false,\n\"ConnectedAlarm\":false,\n\"FireHydrant\":false,\n\"Surveillance\":false,\n\"SmokeDetector\":false,\n\"Sprayer\":false,\n\"FireExtinguisher\":true,\n\"TypeOfWindows\":\"2\",\n\"Strongbox\":\"N\"\n}\n}\n]\n}';

  /**
   * Método que comprueba una ejecución correcta de doPost
   **
   * @author rlopez
   * @date 15/10/2020
   */
  @isTest
  static void test_doPost_processInformation_ok() {
    RestRequest request = new RestRequest();

    request.requestUri = REQUEST_URI;
    request.httpMethod = 'POST';
    request.addHeader('Content-Type', 'application/json');
    request.requestBody = Blob.valueOf('{}');
    RestContext.request = request;

    WS_BusinessServiceQuoting.Request myReq = (WS_BusinessServiceQuoting.Request) JSON.deserializeStrict(
      JSON_INFORMATION,
      WS_BusinessServiceQuoting.Request.class
    );

    Test.startTest();
    WS_BusinessServiceQuoting.Response doPostResponse = WS_BusinessServiceQuoting.doPost();
    Test.stopTest();

    System.assertEquals(
      'success',
      doPostResponse.status,
      'El status debería ser success'
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

    request.requestUri = INVALID_REQUEST_URI;
    request.httpMethod = 'POST';
    request.addHeader('Content-Type', 'application/json');
    request.requestBody = Blob.valueOf('{}');

    RestContext.request = request;

    Test.startTest();
    WS_BusinessServiceQuoting.Response doPostResponse = WS_BusinessServiceQuoting.doPost();
    Test.stopTest();

    System.assertEquals(
      'error',
      doPostResponse.status,
      'El status debería ser error'
    );
    System.assertEquals(
      true,
      doPostResponse.errors.get(0)
        .errorMessage.contains('Invalid URI versioning'),
      'Debería retornar un error que contenga \'Invalid URI versioning\''
    );
  }
}
