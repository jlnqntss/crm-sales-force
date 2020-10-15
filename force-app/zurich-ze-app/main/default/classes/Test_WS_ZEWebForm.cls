/**
 * Clases de test para WS_ZEWebForm
 **
 * @author rlopez
 * @date 14/10/2020
 */
@isTest(SeeAllData=false)
public with sharing class Test_WS_ZEWebForm {
  static final String REQUEST_URI = 'https://zurich-es--devc.my.salesforce.com/services/apexrest/v1/ze/webform/';
  /**
   * Método que comprueba una ejecución correcta de doPost
   **
   * @author rlopez
   * @date 14/10/2020
   */
  @isTest
  static void test_doPost_processInformation_ok() {
    RestRequest request = new RestRequest();

    request.requestUri = REQUEST_URI;
    request.httpMethod = 'POST';
    request.addHeader('Content-Type', 'application/json');
    request.requestBody = Blob.valueOf('{}');
    RestContext.request = request;

    String responseId = WS_ZEWebForm.doPost();

    System.assertEquals('OK', responseId, 'El Id debería coincidir');
  }
}
