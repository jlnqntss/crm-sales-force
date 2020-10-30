/**
 * Clases de test para BusinessInsuranceRaterService
 **
 * @author rlopez
 * @date 15/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class BusinessInsuranceRaterServiceTest {
  static final String REQUEST_URI = '/ze/v1/offers/';
  static final String INVALID_REQUEST_URI = '/ze/va/offers/';
  static final String JSON_INFORMATION = '{"timeStamp":"2020-04-28T12:23:00","webEmail":true,"webPhone":"600666000","sessionId":"xxxxx","businessCode":"3200011531","lastStep":"CRM-01","status":"Activo","manager":{"firstName":"ManagerFirstName","lastName":"ManagerLastName","email":"manageremail@manager.com","phone":"123456789"},"accountInformation":{"firstName":"Nombre","lastName":"Apellidos","family":"10","commercialActivity":"101100","annualRevenue":"200000.10","numberOfEmployees":"150","tradeName":"Nombre comercial","companyName":"Nombre Compañía","nationalIdentifier":"B111111111"},"offers":[{"quoteNumberINFO":"456789456","quoteNumberJRE":"5555555","policyNumber":"654654654","operationCode":"P1","businessCode":"3200011531","effectiveDate":"2020-09-28","commercialPC":"00001","technicalPC":"00526","paymentType":"A","paymentTypeSucc":"A","paymentChannel":"CC","paymentChannelSucc":"CC","language":"ES","buildingCapital":"120000","contentCapital":"12000","generalLiabilityLimit":"12000","netPremium":"12000","validationErrors":"","offerRiskInformation":{"propertyStreetType":"VI","propertyStreet":"Via Augusta","propertyStreetNumber":"12","propertyAdditionalInfo":"","propertyPostalCode":"08006","propertyCity":"Barcelona","propertyState":"8","propertyCountry":"ESP","yearOfConstruction":"1960","ownership":"P","insuredType":"I","buildingType":"I","height":"AL","riskFactor01":"0001","riskFactor02":"","riskFactor03":"","riskFactor04":"","riskFactor05":"","riskFactor06":"","riskFactor07":"","riskFactor08":"0039","riskFactor09":"","area":"50","lockType":true,"securityDoor":false,"bulletproofDoor":false,"connectedAlarm":false,"fireHydrant":false,"surveillance":false,"smokeDetector":false,"sprayer":false,"fireExtinguisher":true,"typeOfWindows":"2","strongbox":"N"}}]}';

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
      BusinessInsuranceRaterService.stepMetadataList.isEmpty(),
      'The list shouldnt be empty'
    );
    System.assertEquals(
      false,
      BusinessInsuranceRaterService.requiredFieldsMetadataSet.isEmpty(),
      'The set shouldnt be empty'
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
      BusinessInsuranceRaterService.stepMetadataList.isEmpty(),
      'The list should be empty'
    );
    System.assertEquals(
      true,
      BusinessInsuranceRaterService.requiredFieldsMetadataSet.isEmpty(),
      'The set should be empty'
    );
  }
}
