@isTest
public class Test_OrderItemUtil
{
    @isTest
    static void test_createOrderItem()
    {
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

        OrderItem item2 = new OrderItem(
            itemId__c = '66666',
            ItemAge__c = 2,
            Category__c = 'Smartphone',
            Brand__c = 'Samsung'
            );
        item2.OrderId = quote.id;
        item2.Active__c = true;
        item2.UnitPrice = 0;
        item2.Quantity = 1;
        item2.PricebookEntryId = pricebookEntry.id;
        insert item2;

        Test.startTest();

        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        List<Cover__c> listCovers = new List<Cover__c>();
        Cover__c cover = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            Description__c = 'Cobertura por robo',
            SumInsured__c = 1000,
            SourceCountry__c = 'Spain',
            PolicyProduct__r = new OrderItem(itemId__c = '7777')
            );
        Cover__c subcover = new Cover__c(
            CoverId__c = '2',
            ParentCoverId__c = '1',
            Name = 'Sub-Robo',
            Description__c = 'SubCobertura por robo',
            SumInsured__c = 150,
            SourceCountry__c = 'Spain',
            PolicyProduct__r = new OrderItem(itemId__c = '7777')
            );
        Cover__c cover2 = new Cover__c(
            CoverId__c = '3',
            ParentCoverId__c = null,
            Name = 'Perdida',
            Description__c = 'Cobertura por perdida',
            SumInsured__c = 1000,
            SourceCountry__c = 'Spain',
            PolicyProduct__r = new OrderItem(itemId__c = '7777')
            );
        Cover__c subcover2 = new Cover__c(
            CoverId__c = '4',
            ParentCoverId__c = '3',
            Name = 'Sub-Perdida',
            Description__c = 'SubCobertura por perdida',
            SumInsured__c = 150,
            SourceCountry__c = 'Spain',
            PolicyProduct__r = new OrderItem(itemId__c = '7777')
            );
        listCovers.add(cover);
        listCovers.add(subcover);
        listCovers.add(cover2);
        listCovers.add(subcover2);

        List<Orderitem> listOrderItems = new List<Orderitem> { item };
        listOrderItems.add(item2);
        // Map<String, PricebookEntry> mapProducts = new Map<String, PricebookEntry>();
        //mapProducts.get(item.itemModel__c, pricebookEntry);

        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.listOrderItems = listOrderItems;
        // ExternalRequestUtil.mapProducts = mapProducts;
        ExternalRequestUtil.listCovers = listCovers;

        OrderItemUtil.createOrderItem(
            quote,
            ExternalRequestUtil.listOrderItems,
            ExternalRequestUtil.mapOrderItem,
            ExternalRequestUtil.mapProducts,
            ExternalRequestUtil.productsToInsert,
            ExternalRequestUtil.pricebookEntryToInsert,
            ExternalRequestUtil.Pricebook,
            ExternalRequestUtil.orderItemsToInsert,
            ExternalRequestUtil.listCovers,
            ExternalRequestUtil.subCoversToInsertQuote,
            ExternalRequestUtil.mapCovers,
            ExternalRequestUtil.updateCover,
            ExternalRequestUtil.recordOwner
            );

        Test.stopTest();
    }

    /**
     * Test: deactivateOldProduct
     *
     * @author nts (agonzalezisasi)
     * @date 04/11/2020
     */
    @isTest
    static void test_deactivateOldProduct()
    {
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

        // get the quote and the order items associated
        List<Order> policies = [SELECT Id, (SELECT Id, ItemId__c FROM OrderItems) FROM Order WHERE Id = :quote.Id];
        System.assertEquals(1, policies.size(), 'There should be 1 cuote');
        System.assertEquals(1, policies[0].OrderItems.size(), 'There should have 1 orderitem');

        List<OrderItem> orderitems = new List<OrderItem>(); // received items empty
        orderitems.add( new OrderItem(ItemId__c='test empty') );
        Map<String, OrderItem> orederItemsToInsert = new Map<String, OrderItem>(); // return

        test.startTest();
        OrderItemUtil.deactivateOldProduct(policies[0], orderitems, orederItemsToInsert);
        test.stopTest();

        System.assertEquals( 1, orederItemsToInsert.size() );
    }
}