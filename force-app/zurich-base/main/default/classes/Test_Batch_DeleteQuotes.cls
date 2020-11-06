/**
 * Clases de test para Batch_DeleteQuotes
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest
private class Test_Batch_DeleteQuotes {
  /**
   * Create test data
   **
   * @author nbizkarra
   * @date 27/04/2020
   */
  @TestSetup
  static void test_CreateData() {
    // Instantiate the Pricebook2 record first, setting the Id
    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    Product2 newProduct = new Product2(
      ProductID__c = 'Samsung Galaxy',
      Name = 'Samsung Galaxy',
      Family = 'Smartphone',
      Brand__c = 'Samsung',
      IsActive = true
    );
    insert newProduct;
    PricebookEntry pricebookEntry = new PricebookEntry(
      UnitPrice = 0,
      ProductID__c = 'Samsung Galaxy',
      Pricebook2Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    pricebookEntry.Product2Id = newProduct.id;
    insert pricebookEntry;

    Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
    Account MasterRef = new Account(CustomerNum__c = '3123');
    insert newMaster;

    Order quote = new Order(
      EffectiveDate = Date.valueOf('1990-01-02'),
      CustomerNum__c = '3123',
      QuoteEntry__c = '10000',
      Status = 'Sync',
      LegalEntity__c = Label.GeneralInsurance,
      RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI)
    );
    quote.Account = MasterRef;
    quote.Pricebook2Id = Test.getStandardPricebookId();
    insert quote;

    OrderItem item = new OrderItem(
      itemId__c = '7777',
      ItemAge__c = 2,
      Category__c = 'Smartphone',
      Brand__c = 'Samsung',
      itemModel__c = 'Samsung Galaxy'
    );
    item.OrderId = quote.id;
    item.Active__c = true;
    item.UnitPrice = 0;
    item.Quantity = 1;
    item.PricebookEntryId = pricebookEntry.id;
    insert item;

    Cover__c cover = new Cover__c(
      CoverId__c = '1',
      ParentCoverId__c = null,
      Name = 'Robo',
      Description__c = 'Cobertura por robo',
      SumInsured__c = 1000,
      LegalEntity__c = Label.GeneralInsurance
    );
    cover.PolicyProduct__c = item.id;
    insert cover;

    Cover__c subCover = new Cover__c(
      CoverId__c = '2',
      ParentCoverId__c = cover.id,
      Name = 'Robo',
      Description__c = 'Cobertura por robo',
      SumInsured__c = 1000,
      LegalEntity__c = Label.GeneralInsurance
    );
    subCover.ParentCover__c = cover.id;
    insert subCover;

    Case claim = new Case(
      ClaimNumber__c = '797',
      PolicyNum__c = '10000',
      CustomerNum__c = '3123',
      LegalEntity__c = Label.GeneralInsurance,
      DateReg__c = Date.valueOf('2020-01-02'),
      RecordTypeId = SystemUtil.getClaimRecordType()
    );
    claim.Policy__c = quote.id;
    insert claim;
  }

  /** 
    * El campo 'lastmodified' de los registros de Quote
    no son más antiguos que 7 días, no se elimina ningún regitro.
    **
    * @author nbizkarra
    * @date 27/04/2020
    */

  @isTest
  static void test_NoEliminarQuote() {
    Integer numQuotes = [SELECT COUNT() FROM Order];

    System.assertEquals(1, numQuotes);

    String query = 'SELECT Id FROM Error_Log__c WHERE LastModifiedDate < LAST_N_DAYS:7';
    Test.startTest();
    Id BatchInstanceId = database.executeBatch(
      new Batch_DeleteQuotes(query),
      200
    );
    Test.stopTest();

    numQuotes = [SELECT COUNT() FROM Order];

    System.assertEquals(1, numQuotes);
  }

  /**
    * Este método de test llama al Batch a través de una query personalizada que no tiene en cuenta LastModifyDate
    y elimina todos los registros existentes de quote.
    * *
    * @author nbizkarra
    * @date 27/04/2020
    */

  @isTest
  static void test_EliminarQuote() {
    Integer numQuotes = [SELECT COUNT() FROM Order];
    Integer numCases = [SELECT COUNT() FROM Case];
    Integer numCovers = [SELECT COUNT() FROM Cover__c];
    System.assertEquals(1, numQuotes);
    System.assertEquals(1, numCases);
    System.assertEquals(2, numCovers);

    String query = 'SELECT Id, (Select id from Casos__r), (Select itemId__c from OrderItems) from Order';

    Test.startTest();
    Batch_DeleteQuotes b = new Batch_DeleteQuotes(); // for coverage
    b = new Batch_DeleteQuotes(query);
    Id BatchInstanceId = database.executeBatch(b, 200);
    Test.stopTest();

    numQuotes = [SELECT COUNT() FROM Order];
    numCases = [SELECT COUNT() FROM Case];
    numCovers = [SELECT COUNT() FROM Cover__c];
    System.assertEquals(0, numQuotes);
    System.assertEquals(0, numCases);
    System.assertEquals(0, numCovers);
  }

  /**
   * For testing Schedule
   */
  @isTest
  static void testBatch_schedule() {
    Batch_DeleteQuotes m = new Batch_DeleteQuotes();
    String sch = '20 30 8 10 2 ?';

    Test.startTest();
    String jobID = system.schedule('Response External Request', sch, m);
    Test.stopTest();
    System.Debug('jobID: ' + jobID);
  }
}