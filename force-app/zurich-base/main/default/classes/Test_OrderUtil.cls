/**
 * Clases de test para OrderUtil
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest(SeeAllData=false)
public with sharing class Test_OrderUtil
{
    static final String EMAIL_TEST = 'edu@test.com';
    static final String BIRTHDAY_DATE_TEST = '1990-01-01';
    static final String BIRTHDAY_DATE_TEST2 = '1994-01-01';
    static final String BIRTHDAY_DATE_TEST3 = '1990-01-02';
    static final String BIRTHDAY_DATE_TEST4 = '2020-05-02';
    static final String CUSTOMER_NUM_TEST1 = 'GI-3123';
    static final String CUSTOMER_NUM_TEST2 = 'GI-6666';
    static final String ITEM_MODEL_TEST = 'Samsung Galaxy';
    static final String DESCRIPTION_TEST = 'Cobertura por robo';
    static final String NAME_PRODUCT_TEST = 'Test Product';

    @testSetup
    static void makeData()
    {
        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        update standardPricebook;

        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        insert newMaster;

        Contact customer = new Contact(
            Email = EMAIL_TEST,
            Birthdate = Date.valueOf(BIRTHDAY_DATE_TEST),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = CUSTOMER_NUM_TEST1,
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            AccountId = newMaster.Id
            );
        insert customer;
    }

    /**
     * @description This method inserts a new quote from the app (quote entry= 456456) and checks if the quote is created
     * @date 05/05/2020
     */
    @IsTest
    static void test_QuoteApp()
    {
        Order quote = new Order(
            QbLastPage__c = null,
            EffectiveDate = null, 
            CustomerNum__c = CUSTOMER_NUM_TEST2,
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain',
            MasterPolicyNum__c = '666' // for coverage
            );

        Contact contact = new Contact(
            Email = EMAIL_TEST,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE_TEST),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = CUSTOMER_NUM_TEST2,
            LegalEntity__c = Label.GeneralInsurance,
            MasterPolicyNum__c = '',
            MasterPolicyDesc__c = '',
            SourceCountry__c = 'Spain'
            );

        Test.startTest();

        // Initialize all the lists and parameters used in util classes
        ExternalRequestUtil.emptyStaticVariables();

        OrderUtil.upsertQuote(contact, quote);

        //Check if the quote has been created
        //Order createdQuote = ExternalRequestUtil.ordersToUpdateList.get(quote.QuoteEntry__c);
        Order createdQuote = ExternalRequestUtil.quotesToUpdateList.get(quote.QuoteEntry__c);
        System.assert (createdQuote != null);

        Test.stopTest();
    }

    /**
     * @description This method inserts a new quote from the app (quote entry= 456456) and checks if the quote is created and associated to existing master
     * @date 03/11/2020
     */
    @IsTest
    static void test_QuoteAppExistingMaster()
    {
        List<Contact> c = [SELECT Id, AccountId FROM Contact WHERE CustomerNum__c =: CUSTOMER_NUM_TEST1];
        System.assertEquals( 1, c.size() );

        Order quote = new Order(
            QbLastPage__c = null,
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST2),
            CustomerNum__c = CUSTOMER_NUM_TEST1,
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain',
            ContactId__c = c[0].Id,
            Status = 'Sync',
            AccountId = c[0].AccountId
            );
        insert quote;

        Test.startTest();

        // Initialize all the lists and parameters used in util classes
        ExternalRequestUtil.emptyStaticVariables();
        Externalrequestutil.mapContacts = SystemUtil.contactsSelector(new Set<String> {CUSTOMER_NUM_TEST1});
        Externalrequestutil.mapQuotes = SystemUtil.QuoteSelector(new Set<String> {'456456'});

        Order quote2 = new Order(
            QbLastPage__c = Label.Q_LastStep_v2,
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST2),
            CustomerNum__c = CUSTOMER_NUM_TEST2,
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain'
            );

        Contact contact = new Contact(
            Email = EMAIL_TEST,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE_TEST),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = CUSTOMER_NUM_TEST2,
            LegalEntity__c = Label.GeneralInsurance,
            MasterPolicyNum__c = '',
            MasterPolicyDesc__c = '',
            SourceCountry__c = 'Spain'
            );

        OrderUtil.upsertQuote(contact, quote2);

        //Check if the quote has been created
        //Order createdQuote = ExternalRequestUtil.ordersToUpdateList.get(quote.QuoteEntry__c);
        Order createdQuote = ExternalRequestUtil.quotesToUpdateList.get(quote.QuoteEntry__c);
        System.assert (createdQuote != null);

        Test.stopTest();
    }

    /**
     * @description This method inserts a new active policy and checks if the number of policies is updated in the contact
     * @date 05/05/2020
     */
    @IsTest
    static void test_SummaryTotalPolicies()
    {
        Contact c = [
            SELECT id, NumPolicies__c
            FROM Contact
            WHERE CustomerNum__c =: CUSTOMER_NUM_TEST1
        ];

        Account masterRef = new Account(CustomerNum__c = '3123');
        Order policy = new Order(
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST3),
            CustomerNum__c = '3123',
            PolicyNum__c = '8989',
            Status = 'Sync',
            PolicyContractStartDate__c = Date.valueOf(BIRTHDAY_DATE_TEST4),
            LegalEntity__c = Label.GeneralInsurance,
            PolicyStatus__c = Label.PolicyStatusActive,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );
        policy.Account = masterRef;
        policy.ContactId__c = c.id;
        insert policy;

        Test.startTest();

        c = [
            SELECT id, NumPolicies__c
            FROM Contact
            WHERE CustomerNum__c =: CUSTOMER_NUM_TEST1
        ];
        System.assert (
            c.NumPolicies__c == 1,
            'Test_OrderUtil: Error al crear rollup summary total policies'
            );

        Test.stopTest();
    }

    /**
     * @description This method inserts a new quote and checks if the last quote field is updated in the contact
     * @date 05/05/2020
     **/
    @IsTest
    static void test_updateLastQuoteOnContact()
    {
        Contact c = [
            SELECT id, LastQuote__c
            FROM Contact
            WHERE CustomerNum__c =:CUSTOMER_NUM_TEST1
        ];

        Account masterRef = new Account(CustomerNum__c = '3123');
        Order quote = new Order(
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST3),
            CustomerNum__c = '3123',
            QuoteEntry__c = '89898787',
            Status = 'Sync',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI),
            After_Processing_Check__c = true
            );
        quote.Account = masterRef;
        quote.ContactId__c = c.id;
        insert quote;

        Test.startTest();

        c = [SELECT id, LastQuote__c FROM Contact WHERE CustomerNum__c =:CUSTOMER_NUM_TEST1];
        System.assertEquals(true, c.LastQuote__c != null);

        Test.stopTest();
    }

    /**
     * Test: insert, update, delete for coverage
     *
     * @author nts (agonzalezisasi)
     * @date 03/11/2020
     */
    @isTest
    static void test_insertUpdateDelete()
    {
        List<Contact> c = [SELECT Id, AccountId FROM Contact WHERE CustomerNum__c =:CUSTOMER_NUM_TEST1];
        System.assertEquals( 1, c.size() );

        Order quote = new Order(
            QbLastPage__c = null,
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST2),
            CustomerNum__c = CUSTOMER_NUM_TEST1,
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain',
            ContactId__c = c[0].Id,
            Status = 'Sync',
            AccountId = c[0].AccountId
            );

        test.startTest();
        insert quote;

        quote.EffectiveDate = Date.today();
        update quote;

        delete quote;
        List<Order> orders = [SELECT Id FROM Order WHERE Id = :quote.Id];
        System.assertEquals( true, orders.isEmpty() );

        test.stopTest();
    }

    /**
     * Test: quote LifeInsurance
     *
     * @author nts (agonzalezisasi)
     * @date 04/11/2020
     */
    @IsTest
    static void test_QuoteAppLifeInsurance()
    {
        Order quote = new Order(
            QbLastPage__c = null,
            EffectiveDate = null, // Date.valueOf('1994-01-01'), for coverage
            CustomerNum__c = CUSTOMER_NUM_TEST2,
            LegalEntity__c = Label.LifeInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain',
            MasterPolicyNum__c = '666' // for coverage
            );

        Contact contact = new Contact(
            Email = EMAIL_TEST,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE_TEST),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = CUSTOMER_NUM_TEST2,
            LegalEntity__c = Label.LifeInsurance,
            MasterPolicyNum__c = '',
            MasterPolicyDesc__c = '',
            SourceCountry__c = 'Spain'
            );

        OrderItem item = new OrderItem(
            ItemAge__c = 2,
            Category__c = 'Smartphone',
            Brand__c = 'Samsung',
            itemModel__c = ITEM_MODEL_TEST
            );

        Cover__c cover = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            Description__c = DESCRIPTION_TEST,
            SumInsured__c = 1000,
            SourceCountry__c = 'Spain',
            PolicyProduct__r = new OrderItem(itemId__c = '77777')
            );

        // Initialize all the lists and parameters used in util classes
        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.listOrderItems.add(item);
        ExternalRequestUtil.listCovers.add(cover);

        Test.startTest();

        ExternalRequestUtil.listOrderItems.add(item); // to get exception
        try
        {
            OrderUtil.upsertQuote(contact, quote);
        }
        catch( Exception e)
        {
            System.assertEquals( true, e.getMessage().contains(Label.LifeObjectIdNull) );
        }
        ExternalRequestUtil.listOrderItems.remove(1);
        OrderUtil.upsertQuote(contact, quote);


        //Check if the quote has been created
        //Order createdQuote = ExternalRequestUtil.ordersToUpdateList.get(quote.QuoteEntry__c);
        Order createdQuote = ExternalRequestUtil.quotesToUpdateList.get(quote.QuoteEntry__c);
        System.assert (createdQuote != null);

        Test.stopTest();
    }

    /**
     * Test: Insert new policy and mark existing quotes with same product as converted
     *
     * @author nts (nbizkarra)
     * @date 19/11/2020
     */
    @IsTest
    static void test_NewPolicyExistingProds()
    {
        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );

        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        update standardPricebook;

        // Create the Product
        Product2 testProduct = new Product2(
            Name = NAME_PRODUCT_TEST,
            IsActive = true,
            ProductID__c = NAME_PRODUCT_TEST
            );
        insert testProduct;

        // Create the PricebookEntry
        PricebookEntry testPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
            );

        insert testPbe;

        Order quote = new Order(
            QbLastPage__c = null,
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST2),
            CustomerNum__c = CUSTOMER_NUM_TEST1,
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain',
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName('QuoteGI'),
            QuoteStatus__c = 'New',
            Status = 'Sync'
            );

        Account masterRef = new Account(CustomerNum__c = '3123');
        Contact contactRef = new Contact(CustomerNum__c = CUSTOMER_NUM_TEST1);

        quote.Pricebook2Id = standardPricebook.Id;
        quote.Account = masterRef;
        quote.ContactId__r = contactRef;
        insert (quote);

        Order quoteRef = new Order(QuoteEntry__c = '456456');
        //Order Item with product "Test Product"
        OrderItem oi = new OrderItem(
            ItemAge__c = 2,
            itemId__c = '3333',
            UnitPrice = 0,
            Quantity = 1
            );
        oi.Order = quoteRef;
        oi.PricebookEntryId = testPbe.Id;
        insert (oi);

        // -------- Data to process

        Order policy = new Order(
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST3),
            CustomerNum__c = CUSTOMER_NUM_TEST1,
            PolicyNum__c = '8989',
            Status = 'Sync',
            PolicyContractStartDate__c = Date.valueOf(BIRTHDAY_DATE_TEST4),
            LegalEntity__c = Label.GeneralInsurance,
            PolicyStatus__c = Label.PolicyStatusActive,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );

        // Initialize all the lists and parameters used in util classes
        ExternalRequestUtil.emptyStaticVariables();
        Externalrequestutil.mapContacts = SystemUtil.contactsSelector(new Set<String> {CUSTOMER_NUM_TEST1});
        Externalrequestutil.mapPolicies = SystemUtil.policySelector( new Set<String> {'8989'} );
        Externalrequestutil.mapProducts = SystemUtil.productsSelector( new Set<String> {NAME_PRODUCT_TEST} );
        Externalrequestutil.mapQuoteSameProd = SystemUtil.getQuoteSameProduct(new Set<String> {CUSTOMER_NUM_TEST1}, new Set<String> {NAME_PRODUCT_TEST} );

        Test.startTest();

        OrderUtil.upsertPolicy(policy);

        //Check if the quote with same product has been covnerted
        Order convertedQuote = ExternalRequestUtil.quotesToUpdateList.get(quote.QuoteEntry__c);
        System.assert (convertedQuote.QuoteStatus__c == Label.Converted);

        Test.stopTest();
    }

    /** nts (nbizkarra)
     * @description Insert a new policy and check that is has been associated to the owner of the task
     * @date 07/01/2021
     */
    @IsTest
    static void test_relateCallToPolicy()
    {
        Contact cont = [SELECT ID FROM CONTACT WHERE CustomerNum__c =:CUSTOMER_NUM_TEST1];
        Id recordTypeId= Schema.SObjectType.Task.getRecordTypeInfosByDeveloperName().get(Label.Interaction).getRecordTypeId();

        //Create new task associated  to existing customer
        Task task = new Task(
            Klinc_CallResult__c = Label.Valid,
            CustomerInterest__c = Label.Interested,
            RecordTypeId = recordTypeId,
            WhoId = cont.id
            );

        //New policy to process
        Order newpolicy = new Order(
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST3),
            CustomerNum__c = CUSTOMER_NUM_TEST1,
            PolicyNum__c = '8989',
            Status = 'Sync',
            PolicyContractStartDate__c = Date.valueOf(BIRTHDAY_DATE_TEST4),
            LegalEntity__c = Label.GeneralInsurance,
            PolicyStatus__c = Label.PolicyStatusActive,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );

        // Initialize all the lists and parameters used in util classes
        ExternalRequestUtil.emptyStaticVariables();
        Externalrequestutil.mapContacts = SystemUtil.contactsSelector(new Set<String> {CUSTOMER_NUM_TEST1});
        Externalrequestutil.mapPolicies = SystemUtil.policySelector( new Set<String> {'8989'} );

        Test.startTest();

        OrderUtil.upsertPolicy(newpolicy);

        Order policy = ExternalRequestUtil.ordersToUpdateList.get(newpolicy.PolicyNum__c);
        //Check if policy has been related to the task
        System.assertEquals(policy.id, task.WhatId);

        Test.stopTest();
    }

     /**
     * Test que comprueba que se borran correctamente los casos asociadas las orders a borrar
     *
     * @author aberuete
     * @date 19/04/2023
     */
    @IsTest
    static void test_deleteCasesRelatedWithOrder()
    {
        Account accountToOrder = [Select id from Account limit 1];

        Order quote = new Order(
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST3),
            CustomerNum__c = '3123',
            QuoteEntry__c = '10000',
            Status = 'Sync',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI)
            );
        quote.AccountId = accountToOrder.Id;
        insert quote;

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

        //Verificar que hay dos casos relacionados a la orden
        System.assertEquals(1, [SELECT COUNT() FROM Case WHERE Policy__c = :quote.Id]);

        //Llamar al método que borra los casos relacionados a la orden y actualiza el estado de la orden
        List<Order> quotesToDelete = [SELECT Id, (Select id from Casos__r) from Order];

        Test.startTest();
        OrderUtil.deleteCasesRelatedWithOrder(quotesToDelete);
        Test.stopTest();

        //Verificar que los casos se han borrado correctamente
        System.assertEquals(0, [SELECT COUNT() FROM Case WHERE Policy__c = :quote.Id], 'El caso se debería de haber borrado');
    }

    /**
     * Test que comprueba que se borran correctamente las covers y subcovers asociadas a los order items de las orders a borrar
     *
     * @author aberuete
     * @date 19/04/2023
     */
    @IsTest
    static void test_deleteConversAndSubcoversRelatedWithOrdersItem()
    {
        Account accountToOrder = [Select id from Account limit 1];

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        update standardPricebook;

        Product2 newProduct = new Product2(
            ProductID__c = ITEM_MODEL_TEST,
            Name = ITEM_MODEL_TEST,
            Family = 'Smartphone',
            Brand__c = 'Samsung',
            IsActive = true
            );
        insert newProduct;

        PricebookEntry pricebookEntry = new PricebookEntry(
            UnitPrice = 0,
            ProductID__c = ITEM_MODEL_TEST,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        pricebookEntry.Product2Id = newProduct.id;
        insert pricebookEntry;

        Order quote = new Order(
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST3),
            CustomerNum__c = '3123',
            QuoteEntry__c = '10000',
            Status = 'Sync',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI)
            );
        quote.AccountId = accountToOrder.Id;
        quote.Pricebook2Id = Test.getStandardPricebookId();
        insert quote;

        OrderItem item = new OrderItem(
            itemId__c = '7777',
            ItemAge__c = 2,
            Category__c = 'Smartphone',
            Brand__c = 'Samsung',
            itemModel__c = ITEM_MODEL_TEST
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
            Description__c = DESCRIPTION_TEST,
            SumInsured__c = 1000,
            LegalEntity__c = Label.GeneralInsurance
            );
        cover.PolicyProduct__c = item.id;
        insert cover;

        Cover__c subCover = new Cover__c(
            CoverId__c = '2',
            ParentCoverId__c = cover.id,
            Name = 'Robo',
            Description__c = DESCRIPTION_TEST,
            SumInsured__c = 1000,
            LegalEntity__c = Label.GeneralInsurance
            );
        subCover.ParentCover__c = cover.id;
        insert subCover;

        List<Order> quotesToDelete = [SELECT Id,(Select itemId__c from OrderItems) from Order];

        Test.startTest();
        OrderUtil.deleteConversAndSubcoversRelatedWithOrdersItem(quotesToDelete);
        Test.stopTest();

        //Verificar que las covers se han borrado correctamente
        System.assertEquals(0, [SELECT COUNT() FROM Cover__c WHERE PolicyProduct__c = :item.Id], 'Las covers se deberían de haber borrado');
    }

    /**
     * Test que comprueba que se actualiza correctamente el número de pólizas que tiene el contacto
     *
     * @author aberuete
     * @date 19/04/2023
     */
    @IsTest
    static void test_updateSummaryPolocies()
    {
        Account accountToOrder = [Select id from Account limit 1];
        Contact contactToOrder = [Select id,NumPolicies__c from Contact limit 1];

        Order quote1 = new Order(
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST3),
            CustomerNum__c = '3123',
            QuoteEntry__c = '10000',
            Status = 'Sync',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI),
            PolicyNum__c = 'Orange-3123',
            PolicyStatus__c = 'Activo'
            );
        quote1.AccountId = accountToOrder.Id;
        quote1.ContactId__c = contactToOrder.id;
        insert quote1;

        Order quote2 = new Order(
            EffectiveDate = Date.valueOf('1991-01-02'),
            CustomerNum__c = '3122',
            Status = 'Sync',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI),
            PolicyNum__c = 'Orange-3122',
            PolicyStatus__c = 'Activo'
            );
        quote2.AccountId = accountToOrder.Id;
        quote2.ContactId__c = contactToOrder.id;
        insert quote2;

        Set<Id> idSet = new Set<Id>{contactToOrder.id};

        Test.startTest();
        OrderUtil.updateSummaryPolicies(idSet);
        Test.stopTest();

        Contact contactAfter = [Select id,NumPolicies__c from Contact where id =:contactToOrder.id limit 1];

        //Verificar que el número de pólizas se ha actualizado correctamente
        System.assertEquals(2, contactAfter.NumPolicies__c , 'El contacto debería tener dos pólizas asociadas');
    }

     /**
     * Test que comprueba que se actualiza correctamente la última quote asociada al contacto
     *
     * @author aberuete
     * @date 19/04/2023
     */
    @IsTest
    static void test_updateContacts()
    {
        Map<Id, Order> mapQuotes = new  Map<Id, Order> ();
        Account accountToOrder = [Select id from Account limit 1];
        Contact contactToOrder = [Select id,LastQuote__c from Contact limit 1];

        Order quote = new Order(
            EffectiveDate = Date.valueOf(BIRTHDAY_DATE_TEST3),
            CustomerNum__c = '3123',
            QuoteEntry__c = '10000',
            Status = 'Sync',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI),
            PolicyNum__c = 'Orange-3123',
            PolicyStatus__c = 'Activo'
            );
        quote.AccountId = accountToOrder.Id;
        quote.ContactId__c = contactToOrder.id;
        insert quote;

        mapQuotes.put(quote.ContactId__c, quote);

        Test.startTest();
        OrderUtil.updateContacts(mapQuotes);
        Test.stopTest();

        Contact contactAfter = [Select id,LastQuote__c from Contact where id =:contactToOrder.id limit 1];

        //Verificar que el contacto tiene enlazada la order como lastquote
        System.assertEquals(quote.id, contactAfter.LastQuote__c , 'El contacto debería tener a la order como lastquote');
    }
}