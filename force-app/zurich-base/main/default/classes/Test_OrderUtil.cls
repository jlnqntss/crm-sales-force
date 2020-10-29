/**
 * Clases de test para OrderUtil
 **
 * @author nbizkarra
 * @date 27/04/2020
 */
@isTest(SeeAllData = false)
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
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI)
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
            EffectiveDate = Date.valueOf('1994-01-01'),
            CustomerNum__c = '3123',
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
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            MasterPolicyNum__c = '',
            MasterPolicyDesc__c = '',
            SourceCountry__c = 'Spain'
            );

        Map<String, Order> mapQuotes = new Map<String, Order>();
        SET<String> keys = new Set<String>();

        mapQuotes = SystemUtil.QuoteSelector(keys);
        Map<String, Order> ordersToUpdateList = new Map<String, Order>();
        Map<String, Contact> mapContacts = new Map<String, Contact>();
        keys.add('GI-3123');
        mapContacts = SystemUtil.ContactsSelector(keys);
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add('edu@test.com');
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();
        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdateList = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Map<String, Order> ordersToUpdateWithPartner = new Map<String, Order>();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{}]',
            Origin__c = 'IBA'
            );
        insert actualRequest;

        recordsToProcess.put(actualRequest.Id, contact);

        Test.startTest();

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapQuotes = mapQuotes;
        ExternalRequestUtil.ordersToUpdateList = ordersToUpdateList;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdateList;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.ordersToUpdateWithPartner = ordersToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.Pricebook = Pricebook;
        ExternalRequestUtil.recordOwner = recordOwner;

        OrderUtil.upsertQuote(contact, quote);

        //Check if the quote has been created
        //Order createdQuote = ExternalRequestUtil.ordersToUpdateList.get(quote.QuoteEntry__c);
        Order createdQuote = ExternalRequestUtil.quotesToUpdateList.get(
            quote.QuoteEntry__c
            );
        System.assert (createdQuote != null);

        Test.stopTest();
    }

    /**
     * @description This method inserts a new quote from the app (quote entry= 456456) and checks if the quote is created and associated to existing master
     * @date 05/05/2020
     */
    @IsTest
    static void test_QuoteAppExistingMaster()
    {
        Account master = [SELECT id FROM Account WHERE CustomerNum__c = '3123'];

        Contact customerOppositeLE = new Contact(
            Email = 'edu@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Customer,
            CustomerNum__c = 'LIFE-3123',
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(
                Label.CustomerLife
                ),
            SourceCountry__c = 'Spain'
            );
        customerOppositeLE.AccountId = master.id;
        insert customerOppositeLE;

        SET<String> keys = new Set<String>();
        Map<String, Order> mapQuotes = new Map<String, Order>();
        mapQuotes = SystemUtil.QuoteSelector(keys);
        Map<String, Order> ordersToUpdateList = new Map<String, Order>();
        Map<String, Contact> mapContacts = new Map<String, Contact>();
        keys.add('GI-3123');
        keys.add(customerOppositeLE.CustomerNum__c);
        mapContacts = SystemUtil.ContactsSelector(keys);
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add('edu@test.com');
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();
        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdateList = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Map<String, Order> ordersToUpdateWithPartner = new Map<String, Order>();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{}]',
            Origin__c = 'IBA'
            );
        insert actualRequest;

        Order quote = new Order(
            QbLastPage__c = null,
            EffectiveDate = Date.valueOf('1994-01-01'),
            CustomerNum__c = '3123',
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
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            MasterPolicyNum__c = '',
            MasterPolicyDesc__c = '',
            SourceCountry__c = 'Spain'
            );

        recordsToProcess.put(actualRequest.Id, contact);

        Test.startTest();

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapQuotes = mapQuotes;
        ExternalRequestUtil.ordersToUpdateList = ordersToUpdateList;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdateList;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.ordersToUpdateWithPartner = ordersToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.Pricebook = Pricebook;
        ExternalRequestUtil.recordOwner = recordOwner;

        OrderUtil.upsertQuote(contact, quote);

        //Check if the quote has been created
        //Order createdQuote = ExternalRequestUtil.ordersToUpdateList.get(quote.QuoteEntry__c);
        Order createdQuote = ExternalRequestUtil.quotesToUpdateList.get(
            quote.QuoteEntry__c
            );

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
}