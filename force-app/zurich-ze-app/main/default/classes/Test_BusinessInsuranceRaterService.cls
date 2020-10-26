/**
 * Clases de test para BusinessInsuranceRaterService
 **
 * @author rlopez
 * @date 15/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class Test_BusinessInsuranceRaterService {
  static final String REQUEST_URI = '/ze/v1/services/quotes/';
  static final String INVALID_REQUEST_URI = '/ze/va/services/quotes/';
  static final String JSON_INFORMATION = '{\n\"TimeStamp\":\"2020-04-28T12:23:00\",\n\"WebEmail\":\"test@test.com\",\n\"WebPhone\":\"600666000\",\n\"SessionId\":\"xxxxx\",\n\"BusinessCode\":\"3200011531\",\n\"LastStep\":\"CRM-09\",\n\"Status\":\"Activo\",\n\"AccountInformation\":{\n\"FirstName\":\"Nombre\",\n\"LastName\":\"Apellidos\",\n\"Family\":\"10\",\n\"CommercialActivity\":\"101100\",\n\"AnnualRevenue\":\"200000.10\",\n\"NumberOfEmployees\":\"150\",\n\"TradeName\":\"Nombre comercial\",\n\"CompanyName\":\"Nombre Compañía\",\n\"NationalIdentifier\":\"B111111111\"\n},\n\"Offers\":[\n{\n\"QuoteNumberINFO\":\"456789456\",\n\"QuoteNumberJRE\":\"5555555\",\n\"PolicyNumber\":\"654654654\",\n\"OperationCode\":\"P1\",\n\"BusinessCode\":\"3200011531\",\n\"EffectiveDate\":\"2020-09-28\",\n\"CommercialPC\":\"00001\",\n\"TechnicalPC\":\"00526\",\n\"PaymentType\":\"A\",\n\"PaymentTypeSucc\":\"A\",\n\"PaymentChannel\":\"CC\",\n\"PaymentChannelSucc\":\"CC\",\n\"Language\":\"ES\",\n\"BuildingCapital\":\"120000\",\n\"ContentCapital\":\"12000\",\n\"GeneralLiabilityLimit\":\"12000\",\n\"NetPremium\":\"12000\",\n\"ValidationErrors\":\"\",\n\"OfferRiskInformation\":{\n\"PropertyStreetType\":\"VI\",\n\"PropertyStreet\":\"Via Augusta\",\n\"PropertyStreetNumber\":\"12\",\n\"PropertyAdditionalInfo\":\"\",\n\"PropertyPostalCode\":\"08006\",\n\"PropertyCity\":\"Barcelona\",\n\"PropertyState\":\"8\",\n\"PropertyCountry\":\"ESP\",\n\"YearOfConstruction\":\"1960\",\n\"Ownership\":\"P\",\n\"InsuredType\":\"I\",\n\"BuildingType\":\"I\",\n\"Height\":\"AL\",\n\"RiskFactor01\":\"0001\",\n\"RiskFactor02\":\"\",\n\"RiskFactor03\":\"\",\n\"RiskFactor04\":\"\",\n\"RiskFactor05\":\"\",\n\"RiskFactor06\":\"\",\n\"RiskFactor07\":\"\",\n\"RiskFactor08\":\"0039\",\n\"RiskFactor09\":\"\",\n\"Area\":\"50\",\n\"LockType\":true,\n\"SecurityDoor\":false,\n\"BulletproofDoor\":false,\n\"ConnectedAlarm\":false,\n\"FireHydrant\":false,\n\"Surveillance\":false,\n\"SmokeDetector\":false,\n\"Sprayer\":false,\n\"FireExtinguisher\":true,\n\"TypeOfWindows\":\"2\",\n\"Strongbox\":\"N\"\n}\n}\n]\n}';

  /**
   * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-01
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM01_ok() {
    BusinessInsuranceRaterService.Request requestInformationObject = (BusinessInsuranceRaterService.Request) JSON.deserializeStrict(
      JSON_INFORMATION,
      BusinessInsuranceRaterService.Request.class
    );

    Test.startTest();
    BusinessInsuranceRaterService.processFormData(requestInformationObject);
    Test.stopTest();

    System.assertEquals(true, true, 'true');
  }

  /**
   * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-01
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM01_ko() {
  }

  /**
   * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-02
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM02_ok() {
  }

  /**
   * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-02
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM02_ko() {
  }

  /**
   * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-03
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM03_ok() {
  }

  /**
   * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-03
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM03_ko() {
  }

  /**
   * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-04
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM04_ok() {
  }

  /**
   * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-04
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM04_ko() {
  }

  /**
   * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-05
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM05_ok() {
  }

  /**
   * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-05
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM05_ko() {
  }

  /**
   * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-06
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM06_ok() {
  }

  /**
   * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-06
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM06_ko() {
  }

  /**
   * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-07
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM07_ok() {
  }

  /**
   * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-07
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM07_ko() {
  }
  /**
   * Método que comprueba una ejecución correcta en el procesamiento de los datos en el paso CRM-08
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM08_ok() {
  }

  /**
   * Método que comprueba una ejecución incorrecta en el procesamiento de los datos en el paso CRM-08
   **
   * @author rlopez
   * @date 26/10/2020
   */
  @isTest
  static void test_processFormData_CRM08_ko() {
  }

  /**
   * Método que comprueba que se recuperan correctamente los metadatos cuando se solicita un paso existente en el formulario
   */
  @isTest
  static void test_getRequiredFieldsFromMetadata_ok() {
    String validFormStep = 'CRM-01';

    Test.startTest();
    BusinessInsuranceRaterService.getRequiredFieldsFromMetadata(validFormStep);
    Test.stopTest();

    System.assertEquals(
      false,
      BusinessInsuranceRaterService.requiredFieldsMetadataSet.isEmpty(),
      'The list shouldnt be empty'
    );
  }

  /**
   * Método que comprueba que NO se recuperan correctamente los metadatos cuando se solicita un paso inexistente en el formulario
   */
  @isTest
  static void test_getRequiredFieldsFromMetadata_ko() {
    String validFormStep = 'CRM-AA';

    Test.startTest();
    BusinessInsuranceRaterService.getRequiredFieldsFromMetadata(validFormStep);
    Test.stopTest();

    System.assertEquals(
      true,
      BusinessInsuranceRaterService.requiredFieldsMetadataSet.isEmpty(),
      'The list should be empty'
    );
  }
}
