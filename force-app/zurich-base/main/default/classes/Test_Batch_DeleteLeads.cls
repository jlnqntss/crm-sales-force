/**
 * Clases de test para Batch_DeleteLeads
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest
private class Test_Batch_DeleteLeads {
  /**
   * Create test data
   **
   * @author nbizkarra
   * @date 27/04/2020
   */
  @TestSetup
  static void test_CreateData() {
    Contact lead = new Contact(
      Email = 'edu@test.com',
      Birthdate = Date.valueOf('1990-01-01'),
      FirstName = 'Edu',
      LastName = 'Sanchez',
      CustomerNum__c = 'GI-3123',
      LegalEntity__c = Label.GeneralInsurance,
      RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI)
    );
    insert lead;
  }

  /** 
    * El campo 'lastmodified' de los registros de lead
    no son más antiguos que 7 días, no se elimina ningún regitro.
    **
    * @author nbizkarra
    * @date 27/04/2020
    */

  @isTest
  static void test_NoEliminarLead() {
    Integer numContact = [SELECT COUNT() FROM Contact];
    System.assertEquals(1, numContact);

    String query = 'SELECT Id FROM Error_Log__c WHERE LastModifiedDate < LAST_N_DAYS:7';
    Test.startTest();
    Id BatchInstanceId = database.executeBatch(
      new Batch_DeleteLeads(query),
      200
    );
    Test.stopTest();

    numContact = [SELECT COUNT() FROM Contact];

    System.assertEquals(1, numContact);
  }

  /**
    * Este método de test llama al Batch a través de una query personalizada.
    y elimina todos los registros existentes de lead.
    * *
    * @author nbizkarra
    * @date 27/04/2020
    */

  @isTest
  static void test_EliminarLead() {
    Integer numContact = [SELECT COUNT() FROM Contact];
    System.assertEquals(1, numContact);

    String query = 'SELECT Id FROM Contact  ';

    Test.startTest();
    Id BatchInstanceId = database.executeBatch(
      new Batch_DeleteLeads(query),
      200
    );
    Test.stopTest();

    numContact = [SELECT COUNT() FROM Contact];
    System.assertEquals(0, numContact);
  }
}
