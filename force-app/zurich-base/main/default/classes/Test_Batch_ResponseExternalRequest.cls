/**
 * Clases de test para Batch_ResponseExternalRequest
 **
 * @author nbizkarra
 * @date 05/04/2020
 */
@isTest
public class Test_Batch_ResponseExternalRequest {
  @isTest
  static void testBatch() {
    ExternalRequest__c er = new ExternalRequest__c(
      Timestamp__c = DateTime.now(),
      Origin__c = 'IBA',
      Country__c = 'Spain',
      Entity__c = 'test',
      Error_Log__c = '',
      Json__c = '{Test}',
      Processed__c = true,
      Sent__c = false,
      Retry__c = 0
    );

    insert er;

    Test.startTest();
    Id BatchInstanceId = Database.executeBatch(
      new Batch_ResponseExternalRequest(),
      10
    );
    Test.stopTest();

    er = [SELECT id, Sent__c FROM ExternalRequest__c];
    System.assertEquals(true, er.Sent__c);
  }
}
