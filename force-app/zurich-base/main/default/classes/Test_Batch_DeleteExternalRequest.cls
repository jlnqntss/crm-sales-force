/**
 * Clases de test para Batch_DeleteExternalRequest
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest
private class Test_Batch_DeleteExternalRequest {
  private static final Integer NUM_OF_REQ = 10;

  /**
   * Create test data
   **
   * @author nbizkarra
   * @date 27/04/2020
   */
  @TestSetup
  static void test_CreateData() {
    //create requests with createdDate 200 days before today
    Datetime fechaHora = System.today() - 200;

    List<ExternalRequest__c> requests = new List<ExternalRequest__c>();
    for (Integer i = 1; i <= NUM_OF_REQ; i++) {
      requests.add(
        new ExternalRequest__c(
          Origin__c = 'test',
          Country__c = 'test',
          Entity__c = 'test',
          Processed__c = true,
          ProcessedDate__c = fechaHora
        )
      );
    }

    insert requests;
  }

  /** 
    * Este método de test llama al Batch con query personalizada, para borrar los requests cuyo processed date mayor que 600 dias.
    No se borra ningún registro.
    **
    * @author nbizkarra
    * @date 27/04/2020
    */

  @isTest
  static void test_NoEliminarRequests() {
    Integer numReq = [SELECT COUNT() FROM ExternalRequest__c];
    System.assertEquals(NUM_OF_REQ, numReq);

    String query = 'SELECT Id from ExternalRequest__c where ProcessedDate__c < LAST_N_DAYS:600';

    Test.startTest();
    Id BatchInstanceId = database.executeBatch(
      new Batch_DeleteExternalRequest(query),
      200
    );
    Test.stopTest();

    numReq = [SELECT COUNT() FROM ExternalRequest__c];
    System.assertEquals(NUM_OF_REQ, numReq);
  }

  /**
   * Este método de test  llama al Batch y elimina todos los registros existentes de 'Error_Log__c' .
   * *
   * @author nbizkarra
   * @date 27/04/2020
   */

  @isTest
  static void test_EliminarRequests() {
    Integer numReq = [SELECT COUNT() FROM ExternalRequest__c];
    System.assertEquals(NUM_OF_REQ, numReq);

    String query = 'SELECT Id from ExternalRequest__c';

    Test.startTest();
    Batch_DeleteExternalRequest b = new Batch_DeleteExternalRequest(); // for coverage
    b = new Batch_DeleteExternalRequest(query);
    Id BatchInstanceId = database.executeBatch( b, 200 );
    Test.stopTest();

    numReq = [SELECT COUNT() FROM ExternalRequest__c];
    System.assertEquals(0, numReq);
  }

  
  /**
   * For testing Schedule
   */
  // @isTest
  // static void testBatch_schedule() {
  //   Batch_DeleteExternalRequest m = new Batch_DeleteExternalRequest();
  //   String sch = '20 30 8 10 2 ?';

  //   Test.startTest();
  //   String jobID = system.schedule('Delete External Request', sch, m);
  //   Test.stopTest();
  //   System.Debug('jobID: ' + jobID);
  // }
}