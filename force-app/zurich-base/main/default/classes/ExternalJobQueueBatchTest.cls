@isTest
private class ExternalJobQueueBatchTest {
  @TestSetup
  static void makeData() {
    List<ExternalRequest__c> externalRequestList = new List<ExternalRequest__c>();

    for (
      Map<String, Object> custJson : TestDataFactory.getINFOCustomerJson(
        200,
        'F'
      )
    ) {
      externalRequestList.add(
        new ExternalRequest__c(
          Origin__c = 'INFO',
          Entity__c = 'CUSTOMER',
          Action__c = 'UPSERT',
          Payload__c = JSON.serialize(custJson),
          ContentFormat__c = 'JSON'
        )
      );
    }

    insert externalRequestList;
  }

  /**
   * Método test que válida la correcta ejecución de las external request cuyo origen sea INFO
   * Lógica correspondiente a INFO se valida en la clase INFOHandlerTest
   **
   * @author adelgado
   * @date 15/10/2020
   */
  @isTest
  static void test_execute_INFO() {
    Test.startTest();
    ExternalJobQueueBatch ejqb = new ExternalJobQueueBatch('INFO');
    Id batchId = Database.executeBatch(ejqb);
    Test.stopTest();

    List<ExternalRequest__c> erProcessed = [
      SELECT Id
      FROM ExternalRequest__c
      WHERE ProcessResult__c != NULL
    ];

    System.assertEquals(
      200,
      erProcessed.size(),
      'No se han procesado todas las external request'
    );
  }
}
