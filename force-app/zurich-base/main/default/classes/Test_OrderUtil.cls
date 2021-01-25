/**
 * Clases de test para OrderUtil
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest(SeeAllData=false)
public with sharing class Test_OrderUtil
{
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
            Email = 'edu@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
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
            EffectiveDate = null, // Date.valueOf('1994-01-01'), for coverage
            CustomerNum__c = 'GI-6666',
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain',
            MasterPolicyNum__c = '666' // for coverage
            );

        Contact contact = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-6666',
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
        List<Contact> c = [SELECT Id, AccountId FROM Contact WHERE CustomerNum__c = 'GI-3123'];
        System.assertEquals( 1, c.size() );

        Order quote = new Order(
            QbLastPage__c = null,
            EffectiveDate = Date.valueOf('1994-01-01'),
            CustomerNum__c = 'GI-3123',
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
        Externalrequestutil.mapContacts = SystemUtil.contactsSelector(new Set<String> {'GI-3123'});
        Externalrequestutil.mapQuotes = SystemUtil.QuoteSelector(new Set<String> {'456456'});

        Order quote2 = new Order(
            QbLastPage__c = Label.Q_LastStep_v2,
            EffectiveDate = Date.valueOf('1994-01-01'),
            CustomerNum__c = 'GI-6666',
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain'
            );

        Contact contact = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-6666',
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
            WHERE CustomerNum__c = 'GI-3123'
        ];

        Account MasterRef = new Account(CustomerNum__c = '3123');
        Order policy = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '3123',
            PolicyNum__c = '8989',
            Status = 'Sync',
            PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
            LegalEntity__c = Label.GeneralInsurance,
            PolicyStatus__c = Label.PolicyStatusActive,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );
        policy.Account = MasterRef;
        policy.ContactId__c = c.id;
        insert policy;

        Test.startTest();

        c = [
            SELECT id, NumPolicies__c
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
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
            WHERE CustomerNum__c = 'GI-3123'
        ];

        Account MasterRef = new Account(CustomerNum__c = '3123');
        Order quote = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '3123',
            QuoteEntry__c = '89898787',
            Status = 'Sync',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI),
            After_Processing_Check__c = true
            );
        quote.Account = MasterRef;
        quote.ContactId__c = c.id;
        insert quote;

        Test.startTest();

        c = [SELECT id, LastQuote__c FROM Contact WHERE CustomerNum__c = 'GI-3123'];
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
        List<Contact> c = [SELECT Id, AccountId FROM Contact WHERE CustomerNum__c = 'GI-3123'];
        System.assertEquals( 1, c.size() );

        Order quote = new Order(
            QbLastPage__c = null,
            EffectiveDate = Date.valueOf('1994-01-01'),
            CustomerNum__c = 'GI-3123',
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
            CustomerNum__c = 'GI-6666',
            LegalEntity__c = Label.LifeInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain',
            MasterPolicyNum__c = '666' // for coverage
            );

        Contact contact = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-6666',
            LegalEntity__c = Label.LifeInsurance,
            MasterPolicyNum__c = '',
            MasterPolicyDesc__c = '',
            SourceCountry__c = 'Spain'
            );

        OrderItem item = new OrderItem(
            ItemAge__c = 2,
            Category__c = 'Smartphone',
            Brand__c = 'Samsung',
            itemModel__c = 'Samsung Galaxy'
            );

        Cover__c cover = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            Description__c = 'Cobertura por robo',
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
            Name = 'Test Product',
            IsActive = true,
            ProductID__c = 'Test Product'
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
            EffectiveDate = Date.valueOf('1994-01-01'),
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '456456',
            SourceCountry__c = 'Spain',
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName('QuoteGI'),
            QuoteStatus__c = 'New',
            Status = 'Sync'
            );

        Account masterRef = new Account(CustomerNum__c = '3123');
        Contact contactRef = new Contact(CustomerNum__c = 'GI-3123');

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
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = 'GI-3123',
            PolicyNum__c = '8989',
            Status = 'Sync',
            PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
            LegalEntity__c = Label.GeneralInsurance,
            PolicyStatus__c = Label.PolicyStatusActive,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );

        // Initialize all the lists and parameters used in util classes
        ExternalRequestUtil.emptyStaticVariables();
        Externalrequestutil.mapContacts = SystemUtil.contactsSelector(new Set<String> {'GI-3123'});
        Externalrequestutil.mapPolicies = SystemUtil.policySelector( new Set<String> {'8989'} );
        Externalrequestutil.mapProducts = SystemUtil.productsSelector( new Set<String> {'Test Product'} );
        Externalrequestutil.mapQuoteSameProd = SystemUtil.getQuoteSameProduct(new Set<String> {'GI-3123'}, new Set<String> {'Test Product'} );

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
        Contact cont = [SELECT ID FROM CONTACT WHERE CustomerNum__c = 'GI-3123'];
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
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = 'GI-3123',
            PolicyNum__c = '8989',
            Status = 'Sync',
            PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
            LegalEntity__c = Label.GeneralInsurance,
            PolicyStatus__c = Label.PolicyStatusActive,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );

        // Initialize all the lists and parameters used in util classes
        ExternalRequestUtil.emptyStaticVariables();
        Externalrequestutil.mapContacts = SystemUtil.contactsSelector(new Set<String> {'GI-3123'});
        Externalrequestutil.mapPolicies = SystemUtil.policySelector( new Set<String> {'8989'} );

        Test.startTest();

        OrderUtil.upsertPolicy(newpolicy);

        Order policy = ExternalRequestUtil.ordersToUpdateList.get(newpolicy.PolicyNum__c);
        //Check if policy has been related to the task
        System.assertEquals(policy.id, task.WhatId);

        Test.stopTest();
    }
}