/**
 * Clases de test para Batch_PostProcessing
 **
 * @author nbizkarra
 * @date 18/06/2020
 */

@isTest
private with sharing class Test_Batch_PostProcessing
{
    private static final String PRODUCT_NAME = 'Samsung Galaxy';
    /**
     * Create test data: an order with a new timestamp and orderItem, discount and cover with old timestamp
     **
     * @author nbizkarra
     * @date 18/06/2020
     */
    @TestSetup
    private static void test_CreateData()
    {
        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        update standardPricebook;

        Product2 newProduct = new Product2(
            ProductID__c = PRODUCT_NAME,
            Name = PRODUCT_NAME,
            Family = 'Smartphone',
            Brand__c = 'Samsung',
            IsActive = true
            );
        insert newProduct;
        PricebookEntry pricebookEntry = new PricebookEntry(
            UnitPrice = 0,
            ProductID__c = PRODUCT_NAME,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        pricebookEntry.Product2Id = newProduct.id;
        insert pricebookEntry;

        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        Account masterRef = new Account(CustomerNum__c = '3123');
        insert newMaster;

        Datetime newTimestamp = Datetime.newInstance(2020, 12, 1, 12, 30, 2);

        Order quote = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '3123',
            Status = 'Sync',
            PolicyNum__c = '12345',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI),
            After_Processing_Check__c = true,
            Processing_Timestamp__c = newTimestamp
            );

        quote.Account = MasterRef;
        quote.Pricebook2Id = Test.getStandardPricebookId();
        insert quote;

        Datetime oldTimestamp = Datetime.newInstance(2008, 12, 1, 12, 30, 2);

        OrderItem item = new OrderItem(
            itemId__c = '7777',
            ItemAge__c = 2,
            Category__c = 'Smartphone',
            Brand__c = 'Samsung',
            itemModel__c = 'Samsung Galaxy',
            Processing_Timestamp__c = oldTimestamp
            );
        item.OrderId = quote.id;
        item.Active__c = true;
        item.UnitPrice = 0;
        item.Quantity = 1;
        item.PricebookEntryId = pricebookEntry.id;
        insert item;

        Discount__c disc = new Discount__c(
            Name = 'Primavera 2020',
            DiscountPct__c = 50,
            DiscountId__c = '1111',
            Processing_Timestamp__c = oldTimestamp
            );
        disc.Policy__c = quote.id;
        insert disc;

        Cover__c cover = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            LegalEntity__c = Label.GeneralInsurance,
            Processing_Timestamp__c = oldTimestamp
            );

        cover.PolicyProduct__c = item.id;
        insert cover;
    }

    /**
     * This batch will delete the orderitem, discount and cover because they have an older timestamp than the order
     **
     * @author nbizkarra
     * @date 18/06/2020
     */
    @isTest
    private static void test_DeleteOutdatedData()
    {
        Order policy = [
            SELECT After_Processing_Check__c
            FROM Order
            WHERE PolicyNum__c = '12345'
        ];
        Integer numOrderItem = [SELECT COUNT() FROM OrderItem];
        Integer numDiscount = [SELECT COUNT() FROM Discount__c];
        Integer numCover = [SELECT COUNT() FROM Cover__c];

        System.assertEquals(true, policy.After_Processing_Check__c);
        System.assertEquals(1, numOrderItem);
        System.assertEquals(1, numDiscount);
        System.assertEquals(1, numCover);

        Test.startTest();
        Batch_PostProcessing b = new Batch_PostProcessing('select'); // for coverage
        b = new Batch_PostProcessing();
        database.executeBatch(b, 200);
        Test.stopTest();

        policy = [
            SELECT After_Processing_Check__c
            FROM Order
            WHERE PolicyNum__c = '12345'
        ];
        numOrderItem = [SELECT COUNT() FROM OrderItem];
        numDiscount = [SELECT COUNT() FROM Discount__c];
        numCover = [SELECT COUNT() FROM Cover__c];

        System.assertEquals(false, policy.After_Processing_Check__c);
        System.assertEquals(0, numOrderItem);
        System.assertEquals(0, numDiscount);
        System.assertEquals(0, numCover);
    }

    /**
     * For testing Schedule
     */
    @isTest
    private static void testBatch_schedule()
    {
        Batch_PostProcessing m = new Batch_PostProcessing();
        String sch = '20 30 8 10 2 ?';

        Test.startTest();
        system.schedule('Post Processing batch', sch, m);
        Test.stopTest();
    }

    /**
     * Test que comprueba si se obtienen correctamente los order items a borrar
     **
     * @author aberuete
     * @date 21/04/2023
     */
    @isTest
    private static void testGetItemsToDelete()
    {
        Batch_PostProcessing batch = new Batch_PostProcessing();

        List<OrderItem> itemsToDelete = new List<OrderItem>();
        Order quote = [Select id,(Select id from OrderItems) from Order limit 1];
        System.assertNotEquals(0, quote.OrderItems.size(), 'Debería tener alguna order item relacionada');

        Test.startTest();
        itemsToDelete = batch.getItemsToDelete (quote, itemsToDelete);
        Test.stopTest();

        System.assertEquals(1, itemsToDelete.size(), 'Debería devolver un orderitem para borrar');
    }

    /**
     * Test que comprueba si se obtienen correctamente los descuentos a borrar
     **
     * @author aberuete
     * @date 21/04/2023
     */
    @isTest
    private static void testGetDiscountsToDelete()
    {
        Batch_PostProcessing batch = new Batch_PostProcessing();

        List<Discount__c> discountsToDelete = new List<Discount__c>();
        Order quote = [Select id,(Select id from Descuentos__r) from Order limit 1];
        System.assertNotEquals(0, quote.Descuentos__r.size(), 'Debería tener algun descuento relacionado');

        Test.startTest();
        discountsToDelete = batch.getDiscountsToDelete (quote, discountsToDelete);
        Test.stopTest();

        System.assertEquals(1, discountsToDelete.size(), 'Debería devolver un descuento para borrar');
    }
}