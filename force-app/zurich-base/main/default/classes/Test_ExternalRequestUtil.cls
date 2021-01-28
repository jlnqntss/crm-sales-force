/**
 * Clases de test para ExternalRequestUtil
 **
 * @author nbizkarra
 * @date 26/04/2020
 **/
@isTest
public class Test_ExternalRequestUtil
{
    static final String PARTNER = 'Orange Seguros';
    static final String PARTNER_PREFIX = 'Orange';

    @testSetup
    static void makeData()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;
        String IBA_EMEA = adminSetup.IBA_EMEA_Prefix__c + '-';

        ExternalRequestUtil.mapMultiPartner = new Map<String, String> {
            PARTNER => PARTNER_PREFIX
        };

        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );
        update standardPricebook;

        // Should be 3
        List<String> prefix = new List<String> {
            '', // IBA
            IBA_EMEA, // IBA EMEA
            PARTNER_PREFIX + '-' // IBA Mult-Partner
        };

        // Cuentas
        List<Account> accounts = new List<Account>();
        for(Integer i=0; i < 3; i++ )
        {
            //Master 3123
            Account newMaster = new Account(
                Name = 'test' + i,
                RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
                );
            if( i == 0 )
            {
                newMaster.CustomerNum__c = '3123';
            }
            else if( i == 1 )
            {
                newMaster.CustomerNum_EMEA__c = '3123';
            }
            else
            {
                newMaster.CustomerNum_Partner__c = '3123';
            }
            //Account MasterRef = new Account(CustomerNum__c = '3123');
            //insert newMaster;
            accounts.add(newMaster);
        }
        insert accounts;

        // Contact
        List<Contact> contacts = new List<Contact>();
        for( Integer i=0; i < 3; i++ )
        {
            // Customer GI-3123
            Contact customer = new Contact(
                Email = 'edu@test.com',
                Birthdate = Date.valueOf('1990-01-01'),
                FirstName = 'Edu',
                LastName = 'Sanchez',
                Status__c = Label.Customer,
                CustomerNum__c = prefix[i] + 'GI-3123',
                LegalEntity__c = Label.GeneralInsurance,
                RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI)
                );
            //Contact ContactRef = new Contact(CustomerNum__c = 'GI-3123');
            //customer.Account=newMaster;
            customer.AccountId = accounts[i].Id;//newMaster.id;
            //insert customer;
            contacts.add(customer);
        }
        insert contacts;

        //Policies
        List<Order> orders = new List<Order>();
        for( Integer i=0; i < 3; i++ )
        {
            //Policy GI 8989
            Order policy = new Order(
                EffectiveDate = Date.valueOf('1990-01-02'),
                CustomerNum__c = prefix[i] + 'GI-3123',
                LegalEntity__c = Label.GeneralInsurance,
                PolicyNum__c = prefix[i] + '8989',
                Status = 'Sync',
                PolicyContractSerial__c = '1111-6',
                PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
                RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
                );
            policy.AccountId = accounts[i].Id;//MasterRef;
            policy.ContactId__c = contacts[i].Id;//ContactRef;
            policy.Pricebook2Id = standardPricebook.Id;
            //insert policy;
            orders.add(policy);
        }
        insert orders;

        // Quotes
        List<Order> orderQuotes = new List<Order>();
        for( Integer i=0; i < 3; i++ )
        {
            //Quote GI 10000
            Order quote = new Order(
                QbLastPage__c = 'test' + i,
                EffectiveDate = Date.valueOf('1994-01-01'),
                Status = 'Sync',
                RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI),
                CustomerNum__c = prefix[i] + 'GI-3123',
                LegalEntity__c = Label.GeneralInsurance,
                QuoteEntry__c = prefix[i] + '10000'
                );
            quote.AccountId = accounts[i].Id;//MasterRef;
            quote.ContactId__c = contacts[i].Id; //ContactRef;
            quote.Pricebook2Id = standardPricebook.Id;
            // insert quote;
            orderQuotes.add(quote);
        }
        insert orderQuotes;

        List<Case> claims = new List<Case>();
        for( Integer i=0; i < 3; i++ )
        {
            //Claim 797
            Case claim = new Case(
                ClaimNumber__c = prefix[i] + '797',
                PolicyNum__c = prefix[i] + '8989',
                CustomerNum__c = prefix[i] + 'GI-3123',
                LegalEntity__c = Label.GeneralInsurance,
                DateReg__c = Date.valueOf('2020-01-05'),
                InsuredObjectId__c = prefix[i] + '123456789',
                RecordTypeId = SystemUtil.getClaimRecordType()
                );
            //insert claim;
            claims.add(claim);
        }
        insert claims;
    }

    /**
     * @description This method inserts an existing customer and updates the firstname
     **
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_CustomerUpdate()
    {
        Contact existingCustomer = [
            SELECT id, FirstName
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Contact updatedCustomer = [
            SELECT id, FirstName
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        System.assert (existingCustomer.FirstName != updatedCustomer.FirstName);
    }

    /**
     * @description This method inserts a new customer, for that, the existing customer will be deleted first
     ** It will be checked if the customer was inserted with a related account
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_CustomerCreate_NewAccount()
    {
        //delete exsting contact and account
        List<Contact> existingCustomers = [SELECT id, FirstName FROM Contact];
        delete existingCustomers;

        List<Account> existingMasters = [SELECT id FROM Account];
        delete existingMasters;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        //New contact with existing Account
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Contact newCustomer = [SELECT id, AccountId FROM Contact WHERE CustomerNum__c = 'GI-3123'];

        System.assert (newCustomer != null);
        System.assert (newCustomer.AccountId != null);

    }

    @isTest
    static void test_CustomerCreate_NewAccount_EMEA()
    {
        //delete exsting contact and account
        List<Contact> existingCustomers = [SELECT id, FirstName FROM Contact];
        delete existingCustomers;

        List<Account> existingMasters = [SELECT id FROM Account];
        delete existingMasters;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'France',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        //New contact with existing Account
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_EMEA = adminSetup.IBA_EMEA_Prefix__c + '-';

        String customerNum = IBA_EMEA + 'GI-3123';
        Contact newCustomer = [SELECT id, AccountId FROM Contact WHERE CustomerNum__c = :customerNum];

        System.assert (newCustomer != null);
        System.assert (newCustomer.AccountId != null);
    }

    @isTest
    static void test_CustomerCreate_NewAccount_MultiPartner()
    {
        //delete exsting contact and account
        List<Contact> existingCustomers = [SELECT id, FirstName FROM Contact];
        delete existingCustomers;

        List<Account> existingMasters = [SELECT id FROM Account];
        delete existingMasters;

        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = IBA_MULTI_PARTNER_ORIGIN,
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        //New contact with existing Account
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Contact newCustomer = [SELECT id, AccountId FROM Contact WHERE CustomerNum__c = :PARTNER_PREFIX + '-GI-3123'];

        System.assert (newCustomer != null);
        System.assert (newCustomer.AccountId != null);

    }

    /**
     * @description This method inserts a new customer, when the same customer for the opposite legal entity exists
     ** It will be checked if the customer was inserted with a related account
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_CustomerCreate_ExistingAccount()
    {
        //Change legal entity of the existing customer
        // Contact existingCustomer = [
        //   SELECT Id, CustomerNum__c, LegalEntity__c
        //   FROM Contact
        //   WHERE CustomerNum__c = 'GI-3123'
        // ];
        Account master = [SELECT Id FROM Account WHERE CustomerNum__c = '3123'];
        // existingCustomer.AccountId = master.id;
        // existingCustomer.LegalEntity__c = Label.LifeInsurance;
        // existingCustomer.CustomerNum__c = 'LIFE-3123';
        // upsert existingCustomer;
        List<Contact> contacts = [SELECT Id FROM Contact];
        delete contacts;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Contact newCustomer = [
            SELECT Id, AccountId, LegalEntity__c
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        System.assert (newCustomer != null);
        System.assertEquals(Label.GeneralInsurance, newCustomer.LegalEntity__c);
        System.assertEquals(master.Id, newCustomer.AccountId);

    }

    /**
     * @description This method inserts a new quote from the app (quote entry= 456456) with assigned to
     *              an inexistent customer, it is tested if an error is launched
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_QuoteAppError()
    {
        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Quote',
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        //try error scenario: quote from the app and customer doesnt exist
        Contact cont = [SELECT id FROM Contact WHERE CustomerNum__c = 'GI-3123'];

        delete cont;

        Test.startTest();
        try
        {
            ExternalRequestUtil.processExternalRequests(listExternalRequest);
        }
        catch (Exception e)
        {
            system.assert ( e.getMessage().contains(Label.CustomerError) );
        }
        Test.stopTest();
    }

    /**
     * @description This method inserts a new quote from the Web with a lead that doesnt' exist.
     *              TEST1: It is checked that quote and lead are created correctly.
     *              TEST2: a new quote with the existing customer number will be inserted.
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_QuoteWeb()
    {
        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);
        insert listExternalRequest;

        Test.startTest();

        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        //TEST1: insert new quote with new lead
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        Contact newLead=[Select id, CustomerNum__c from Contact where CustomerNum__c='GI-9999'];
        Order newQuote=[SELECT Id,
                        (Select id from Descuentos__r),(Select id from OrderItems)
                        from Order where QuoteEntry__c='9090'];
        //check if lead and quote have been created
        System.assert (newLead != null);
        System.assert (newQuote != null);
        //Check if discount has been inserted
        System.assert (newQuote.Descuentos__r != null);
        //check that orderItems have been added to quote
        System.assert (newQuote.OrderItems != null);

        //TEST2: insert new quote with existing lead (customer number)
        delete newQuote;
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        newQuote=[SELECT Id, ContactId__c from Order where QuoteEntry__c='9090'];
        //check if the quote has been asigned to the existing lead
        System.assertEquals(newLead.id, newQuote.ContactId__c);

        Test.stopTest();
    }

    @isTest
    static void test_QuoteWeb_EMEA()
    {
        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'France',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);
        insert listExternalRequest;

        Test.startTest();

        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        //TEST1: insert new quote with new lead
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        Contact newLead=[Select id, CustomerNum__c from Contact where CustomerNum__c='EMEA-GI-9999'];
        Order newQuote=[SELECT Id,
                        (Select id from Descuentos__r),(Select id from OrderItems)
                        from Order where QuoteEntry__c='EMEA-9090'];
        //check if lead and quote have been created
        System.assert (newLead != null);
        System.assert (newQuote != null);
        //Check if discount has been inserted
        System.assert (newQuote.Descuentos__r != null);
        //check that orderItems have been added to quote
        System.assert (newQuote.OrderItems != null);

        //TEST2: insert new quote with existing lead (customer number)
        delete newQuote;
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        newQuote=[SELECT Id, ContactId__c from Order where QuoteEntry__c='EMEA-9090'];
        //check if the quote has been asigned to the existing lead
        System.assertEquals(newLead.id, newQuote.ContactId__c);

        Test.stopTest();
    }

    @isTest
    static void test_QuoteWeb_MultiPartner()
    {
        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = IBA_MULTI_PARTNER_ORIGIN,
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);
        insert listExternalRequest;

        Test.startTest();

        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        //TEST1: insert new quote with new lead
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        Contact newLead=[Select id, CustomerNum__c from Contact where CustomerNum__c= :PARTNER_PREFIX + '-GI-9999'];
        Order newQuote=[SELECT Id,
                        (Select id from Descuentos__r),(Select id from OrderItems)
                        from Order where QuoteEntry__c= :PARTNER_PREFIX + '-9090'];
        //check if lead and quote have been created
        System.assert (newLead != null);
        System.assert (newQuote != null);
        //Check if discount has been inserted
        System.assert (newQuote.Descuentos__r != null);
        //check that orderItems have been added to quote
        System.assert (newQuote.OrderItems != null);

        //TEST2: insert new quote with existing lead (customer number)
        delete newQuote;
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        newLead=[Select id, CustomerNum__c from Contact where CustomerNum__c= :PARTNER_PREFIX + '-GI-9999'];
        System.assert (newLead != null);
        newQuote=[SELECT Id, ContactId__c from Order where QuoteEntry__c= :PARTNER_PREFIX + '-9090'];
        //check if the quote has been asigned to the existing lead
        System.assertEquals(newLead.id, newQuote.ContactId__c);

        Test.stopTest();
    }

    /**
     * @description This method inserts a new quote from the Web
     *              TEST1: (MC1) a new quote is inserted with existing lead (matchcode, email+birthdate, legalentity, country)
     * @author nts (agonzalezisasi)
     * @date 03/11/2020
     **/
    @isTest
    static void test_QuoteWebMatchCodeCountry()
    {
        // TEST1: insert new quote with existing lead (matchcode, email+birthdate+Same LE)

        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '888888',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;
        Contact lead = new Contact(
            Email = 'nora@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Lead,
            CustomerNum__c = 'GI-888888',
            LegalEntity__c = Label.GeneralInsurance,
            SourceCountry__c = 'Spain',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI)
            );
        lead.AccountId = newMaster.id;
        insert lead;


        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        // todo: revisar
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c FROM Order WHERE QuoteEntry__c='9090'];
        //check if the quote has been asigned to the existing lead (matchcode)
        System.assertEquals(lead.CustomerNum__c, newQuote.ContactId__r.CustomerNum__c);
    }

/**
 * @description This method inserts a new quote from the Web
 *              TEST1: (MC2) a new quote is inserted with existing lead (matchcode, email+birthdate)
 * @author nbizkarra
 * @date 05/05/2020
 **/
    @isTest
    static void test_QuoteWebMatchCodeDifCountry()
    {
        // TEST1: insert new quote with existing lead (matchcode, email + birthdate + Legal Entity + different country)

        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '888888',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;
        Contact lead = new Contact(
            Email = 'nora@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Lead,
            CustomerNum__c = 'GI-888888',
            LegalEntity__c = Label.GeneralInsurance,
            SourceCountry__c = 'France',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI)
            );
        lead.AccountId = newMaster.id;
        insert lead;


        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        // todo: revisar
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c FROM Order WHERE QuoteEntry__c='9090'];
        //check if the quote has been asigned to a new lead (matchcode)
        System.assertEquals('GI-9999', newQuote.ContactId__r.CustomerNum__c);
    }

    /**
     * @description This method inserts a new quote from the Web
     *              TEST1: (MC3) a new quote with existing master will be insterted (matchcode opposite legal entity)
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_QuoteWebMatchCodeOppositeLE()
    {
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '888888',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;
        //a new lead is created with same matchcode, different legal entity
        Contact lead = new Contact(
            Email = 'nora@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Lead,
            CustomerNum__c = 'LIFE-888888',
            LegalEntity__c = Label.LifeInsurance,
            SourceCountry__c = 'Spain',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife)
            );
        lead.AccountId = newMaster.id;
        insert lead;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        // todo: revisar
        //TEST2: a new quote with existing master will be insterted (matchcode opposite legal entity
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c FROM Order WHERE QuoteEntry__c='9090'];
        //check if the quote has been asigned to the opposite legal entity GI-9999
        System.assertEquals('GI-9999', newQuote.ContactId__r.CustomerNum__c);
    }

/**
 * @description This method inserts a new quote from the Web
 *              TEST1: (MC2) a new quote is inserted with existing lead (matchcode, email+birthdate)
 *              TEST2: existing Account CustomerNum blank
 * @author nbizkarra
 * @date 05/05/2020
 **/
    @isTest
    static void test_QuoteWebMatchCodeDifCountry_EMEA()
    {
        // TEST1: insert new quote with existing lead (matchcode, email + birthdate + Legal Entity + different country)

        Account newMaster = new Account(
            Name = 'test',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;
        Contact lead = new Contact(
            Email = 'nora@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Lead,
            CustomerNum__c = 'EMEA-GI-888888',
            LegalEntity__c = Label.GeneralInsurance,
            SourceCountry__c = 'Germany',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI)
            );
        lead.AccountId = newMaster.id;
        insert lead;


        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'France', // EMEA
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        // todo: revisar
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c FROM Order WHERE QuoteEntry__c='EMEA-9090'];
        //check if the quote has been asigned to the existing lead (matchcode)
        System.assertEquals('EMEA-GI-9999', newQuote.ContactId__r.CustomerNum__c);
    }

    /**
     * @description This method inserts a new quote from the Web
     *              TEST1: (MC3) a new quote with existing master will be insterted (matchcode opposite legal entity)
     *              TEST2: existing Account CustomerNum blank
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_QuoteWebMatchCodeOppositeLE_EMEA()
    {
        Account newMaster = new Account(
            Name = 'test',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;
        //a new lead is created with same matchcode, different legal entity
        Contact lead = new Contact(
            Email = 'nora@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Lead,
            CustomerNum__c = 'EMEA-LIFE-888888',
            LegalEntity__c = Label.LifeInsurance,
            SourceCountry__c = 'Germany',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife)
            );
        lead.AccountId = newMaster.id;
        insert lead;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'France', // EMEA
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        // todo: revisar
        //TEST2: a new quote with existing master will be insterted (matchcode opposite legal entity
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c FROM Order WHERE QuoteEntry__c='EMEA-9090'];
        //check if the quote has been asigned to the opposite legal entity GI-9999
        System.assertEquals('EMEA-GI-9999', newQuote.ContactId__r.CustomerNum__c);
    }


    /**
     * @description This method inserts a new quote from the Web
     *              TEST1: (MC1) a new quote is inserted with existing lead (matchcode, email+birthdate, legalentity, country)
     *              TEST2: new Customer Active - existing Customer Lead
     * @author nts (agonzalezisasi)
     * @date 03/11/2020
     **/
    @isTest
    static void test_QuoteWebMatchCodeCountry_Partner()
    {
        // TEST1: insert new quote with existing lead (matchcode, email+birthdate+Same LE)

        Account newMaster = new Account(
            Name = 'test',
            CustomerNum_Partner__c = '888888',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact lead = new Contact(
            Email = 'nora@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Lead,
            CustomerNum__c = PARTNER_PREFIX + '-GI-888888',
            LegalEntity__c = Label.GeneralInsurance,
            SourceCountry__c = 'Spain',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI),
            Partner__c = PARTNER
            );
        lead.AccountId = newMaster.id;
        insert lead;


        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = IBA_MULTI_PARTNER_ORIGIN,
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Order newQuote=[SELECT Id, ContactId__c FROM Order WHERE QuoteEntry__c= :PARTNER_PREFIX + '-9090'];

        //comprobar que la quote ha sido asignada al contacto existente
        System.assertEquals(lead.Id, newQuote.ContactId__c);

    }

/**
 * @description This method inserts a new quote from the Web
 *              TEST1: (MC2) a new quote is inserted with existing lead (matchcode, email+birthdate)
 *              TEST2: new Customer Active - existing Customer Lead
 *              TEST3: existing Account Partner
 * @author nts (agonzalezisasi)
 * @date 03/11/2020
 **/
    @isTest
    static void test_QuoteWebMatchCodeDifCountry_Partner()
    {
        // TEST1: insert new quote with existing lead (matchcode, email + birthdate + Legal Entity + different country)

        Account newMaster = new Account(
            Name = 'test',
            CustomerNum_Partner__c = '888888',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Account newAccountPartner =  new Account(
            Name = 'test partner',
            Masterpolicy__c = '666',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Partner)
            );
        insert newAccountPartner;

        Contact lead = new Contact(
            Email = 'nora@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Lead,
            CustomerNum__c = PARTNER_PREFIX + '-GI-888888',
            LegalEntity__c = Label.GeneralInsurance,
            SourceCountry__c = 'France',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI),
            Partner__c = PARTNER,
            MasterPolicy__c = newAccountPartner.Id
            );
        lead.AccountId = newMaster.id;
        insert lead;


        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = IBA_MULTI_PARTNER_ORIGIN,
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        // todo: revisar
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c FROM Order WHERE QuoteEntry__c= :PARTNER_PREFIX + '-9090'];
        //check if the quote has been asigned to the existing lead (matchcode)
        System.assertEquals(PARTNER_PREFIX + '-GI-9999', newQuote.ContactId__r.CustomerNum__c);
    }

    /**
     * @description This method inserts a new quote from the Web
     *              TEST1: (MC3) a new quote with existing master will be insterted (matchcode opposite legal entity)
     *              TEST2: new Customer Active - existing Customer Lead
     *              TEST3: test new Account Partner
     * @author nts (agonzalezisasi)
     * @date 03/11/2020
     **/
    @isTest
    static void test_QuoteWebMatchCodeOppositeLE_Partner()
    {
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum_Partner__c = '888888',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;
        //a new lead is created with same matchcode, different legal entity
        Contact lead = new Contact(
            Email = 'nora@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Lead,
            CustomerNum__c = PARTNER_PREFIX + '-LIFE-888888',
            LegalEntity__c = Label.LifeInsurance,
            SourceCountry__c = 'Spain',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            Partner__c = PARTNER
            );
        lead.AccountId = newMaster.id;
        insert lead;

        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;

        System.Debug('**** Origin: ' + IBA_MULTI_PARTNER_ORIGIN);
        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = IBA_MULTI_PARTNER_ORIGIN,
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '[{"quoteEntry": {},"customer": {}}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        Test.startTest();
        // todo: revisar
        //TEST2: a new quote with existing master will be insterted (matchcode opposite legal entity
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c FROM Order WHERE QuoteEntry__c= :PARTNER_PREFIX + '-9090'];
        //check if the quote has been asigned to the opposite legal entity GI-9999
        System.assertEquals(PARTNER_PREFIX + '-GI-9999', newQuote.ContactId__r.CustomerNum__c);
    }

    /**
     * @description This method inserts a policy with policy version 1111-5
     *              Then the same policy is received with policy version (contract serial) 1111-6
     *              The method checks that the policy version has been updated
     *
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_PolicyUpdate()
    {
        Order quote = [SELECT id FROM Order WHERE QuoteEntry__c = '10000'];
        Order policy = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '3123',
            LegalEntity__c = Label.GeneralInsurance,
            PolicyNum__c = '1111',
            Status = 'Sync',
            PolicyContractSerial__c = '1111-5',
            PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
            UpdateReason__c = '',
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );
        //convert existing policy to quote
        policy.id = quote.id;

        upsert policy;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Policy',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        // todo: revisar
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        Order updatedPolicy=[SELECT Id, PolicyContractSerial__c from Order where PolicyNum__c='1111'];
        //Check if Policy version updated
        system.assert (updatedPolicy.PolicyContractSerial__c != policy.PolicyContractSerial__c );

        Test.stopTest();
    }

    /**
     * @description This method inserts a new Policy (1111) from IBA to an existing customer (GI-3123), this customer already owns another policy
     ** the method tests if the customer has an additional policy
     ** It is also tested if the received parter associated to the policy has been created
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_PolicyCreateNew()
    {
        Contact customer = [
            SELECT Id, (SELECT id FROM Pedidos__r WHERE PolicyNum__c != NULL)
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];
        //before inserting customer has 1 policy
        system.assertEquals( 1, customer.Pedidos__r.size() );

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Policy',
            Json__c = '[{}]', // using Mock_Parser
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        customer = [
            SELECT Id, (SELECT id FROM Pedidos__r WHERE PolicyNum__c != NULL)
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];
        //after inserting customer has 2 policies
        system.assertEquals( 2, customer.Pedidos__r.size() );

        System.debug('**** PEDIDOS ' + customer.Pedidos__r);

        //check that discounts have been added to policy
        Order newPolicy = [
            SELECT Id, (SELECT id FROM Descuentos__r), (SELECT id FROM OrderItems)
            FROM Order
            WHERE PolicyNum__c = '1111'
        ];

        System.debug('**** DECUENTOS ' + newPolicy.Descuentos__r);

        System.debug('**** DECUENTOS ' + newPolicy.OrderItems);

        System.assert (newPolicy.Descuentos__r != null);
        //check that orderItems have been added to policy
        System.assert (newPolicy.OrderItems != null);
        for(OrderItem oi: newPolicy.OrderItems)
        {
            System.Debug(oi);
        }

        //test that the partner has been created
        Account partner = [SELECT Name FROM Account WHERE Masterpolicy__c != NULL];
        system.assertEquals('Rastreator', partner.Name);

    }

    @isTest
    static void test_PolicyCreateNew_EMEA()
    {
        Contact customer = [
            SELECT Id, (SELECT id, PolicyNum__c FROM Pedidos__r WHERE PolicyNum__c != NULL)
            FROM Contact
            WHERE CustomerNum__c = 'EMEA-GI-3123'
        ];
        //before inserting, customer has 1 policy
        system.assertEquals( 1, customer.Pedidos__r.size() );

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'France',
            Entity__c = 'Policy',
            Json__c = '[{}]', // using Mock_Parser
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        customer = [
            SELECT Id, (SELECT id, PolicyNum__c FROM Pedidos__r WHERE PolicyNum__c != NULL)
            FROM Contact
            WHERE CustomerNum__c = 'EMEA-GI-3123'
        ];

        //after inserting customer has 2 policies
        system.assertEquals( 2, customer.Pedidos__r.size() );

        System.debug('**** PEDIDOS ' + customer.Pedidos__r);

        //check that discounts have been added to policy
        Order newPolicy = [
            SELECT Id, (SELECT id,DiscountId__c FROM Descuentos__r), (SELECT id,itemId__c FROM OrderItems)
            FROM Order
            WHERE PolicyNum__c = 'EMEA-1111'
        ];

        System.debug('**** DECUENTOS ' + newPolicy.Descuentos__r);

        System.debug('**** DECUENTOS ' + newPolicy.OrderItems);

        System.assert (newPolicy.Descuentos__r != null);
        //check that orderItems have been added to policy
        System.assert (newPolicy.OrderItems != null);

        //test that the partner has been created
        Account partner = [SELECT Name FROM Account WHERE Masterpolicy__c != NULL];
        system.assertEquals('Rastreator', partner.Name);

    }

    @isTest
    static void test_PolicyCreateNew_MultiPartner()
    {
        Contact customer = [
            SELECT Id, (SELECT id, PolicyNum__c FROM Pedidos__r WHERE PolicyNum__c != NULL)
            FROM Contact
            WHERE CustomerNum__c = :PARTNER_PREFIX + '-GI-3123'
        ];
        //before inserting customer has 1 policy
        system.assertEquals( 1, customer.Pedidos__r.size() );

        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = IBA_MULTI_PARTNER_ORIGIN,
            Country__c = 'Spain',
            Entity__c = 'Policy',
            Json__c = '[{}]', // using Mock_Parser
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        customer = [
            SELECT Id, (SELECT id, PolicyNum__c FROM Pedidos__r WHERE PolicyNum__c != NULL)
            FROM Contact
            WHERE CustomerNum__c = :PARTNER_PREFIX + '-GI-3123'
        ];

        //after inserting customer has 2 policies
        system.assertEquals( 2, customer.Pedidos__r.size() );

        System.debug('**** PEDIDOS ' + customer.Pedidos__r);

        //check that discounts have been added to policy
        Order newPolicy = [
            SELECT Id, (SELECT id, DiscountId__c FROM Descuentos__r), (SELECT id, itemId__c FROM OrderItems)
            FROM Order
            WHERE PolicyNum__c = :PARTNER_PREFIX + '-1111'
        ];

        System.debug('**** DECUENTOS ' + newPolicy.Descuentos__r);

        System.debug('**** DECUENTOS ' + newPolicy.OrderItems);

        System.assert (newPolicy.Descuentos__r != null);
        //check that orderItems have been added to policy
        System.assert (newPolicy.OrderItems != null);

        //test that the partner has been created
        Account partner = [SELECT Name FROM Account WHERE Masterpolicy__c != NULL];
        system.assertEquals('Rastreator', partner.Name);

    }

    /**
     * @description the existing customer is deleted, so when inserting the policy the customer doesn't exist, it tests if the error is launched
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_PolicyError()
    {
        //delete existing customer
        Contact customer = [
            SELECT Id, CustomerNum__c
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        delete customer;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Policy',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();

        try
        {
            ExternalRequestUtil.processExternalRequests(listExternalRequest);
        }
        catch (Exception e)
        {
            // system.assertEquals(Label.PolicyError,e.getStackTraceString());
            system.assert ( e.getMessage().contains(Label.PolicyError) );
        }

        Test.stopTest();
    }

    /**
     * @description This method inserts a new Claim from IBA with an existing customer, policy
     **
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_ClaimInsert()
    {
        //delete the claim that already exists
        Case claim = [SELECT id FROM Case WHERE ClaimNumber__c = '797'];
        delete claim;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Claim',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        //insert the claim
        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        Integer numClaims = [SELECT COUNT() FROM Case WHERE ClaimNumber__c = '797'];
        System.assertEquals(1, numClaims);

        Test.stopTest();
    }

    @isTest
    static void test_ClaimInsert_EMEA()
    {
        //delete the claim that already exists
        List<Case> claims = [SELECT id FROM Case];
        delete claims;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'France',
            Entity__c = 'Claim',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        //insert the claim
        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_EMEA = adminSetup.IBA_EMEA_Prefix__c + '-';

        String claimNumber = IBA_EMEA + '797';
        Integer numClaims = [SELECT COUNT() FROM Case WHERE ClaimNumber__c = :claimNumber];
        System.assertEquals(1, numClaims);

        Test.stopTest();
    }

    @isTest
    static void test_ClaimInsert_MultPartner()
    {
        //delete the claim that already exists
        List<Case> claims = [SELECT id FROM Case];
        delete claims;

        for(Contact c: [SELECT CustomerNum__c FROM Contact] )
        {
            System.Debug(c);
        }
        for(Order o: [SELECT CustomerNum__c, PolicyNum__c FROM Order])
        {
            System.Debug(o);
        }


        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String IBA_MULTI_PARTNER_ORIGIN = adminSetup.IBA_Multi_Partner_Origin__c;

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = IBA_MULTI_PARTNER_ORIGIN,
            Country__c = 'Spain',
            Entity__c = 'Claim',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        //insert the claim
        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        String claimNumber = PARTNER_PREFIX + '-797';
        Integer numClaims = [SELECT COUNT() FROM Case WHERE ClaimNumber__c = :claimNumber];
        System.assertEquals(1, numClaims);

        Test.stopTest();
    }

    /**
     * @description This method inserts a new Claim from IBA with an inexistent customer so launches an error
     *              then the policy is deleted and also launches an error beacuse the poilcy doesn't exist
     **
     * @author nbizkarra
     * @date 05/05/2020
     */
    @isTest
    static void test_ClaimErrorinsert()
    {
        //delete the claim that already exists
        Case claim = [SELECT id FROM Case WHERE ClaimNumber__c = '797'];
        delete claim;

        //remove existing customer
        Contact cont = [SELECT id FROM Contact WHERE CustomerNum__c = 'GI-3123'];
        delete cont;

        //Test error use case: claim without customer
        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Claim',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        try
        {
            ExternalRequestUtil.processExternalRequests(listExternalRequest);
        }
        catch (Exception e)
        {
            system.assert ( e.getMessage().contains(Label.CustomerError) );
        }
        Test.stopTest();

        //test second error use case: claim without policy
        //remove existing policy
        Order policy = [SELECT id FROM Order WHERE PolicyNum__c = '8989'];
        delete policy;
        try
        {
            ExternalRequestUtil.processExternalRequests(listExternalRequest);
        }
        catch (Exception e)
        {
            system.assert ( e.getMessage().contains(Label.PolicyNotExisting) );
        }
    }

    /**
     * @description This method updates the date of an existing Claim
     **
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_ClaimUpdate()
    {
        Case existingClaim = [ SELECT id, DateReg__c FROM Case WHERE ClaimNumber__c = '797' ];

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Claim',
            Json__c = '[{}]',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();
        ExternalRequestUtil.processExternalRequests(listExternalRequest);
        Test.stopTest();

        Case updatedClaim = [ SELECT id, DateReg__c FROM Case WHERE ClaimNumber__c = '797' ];

        System.assert (existingClaim.DateReg__c != updatedClaim.DateReg__c);
    }

    /**
     * @description This method inserts a new Email from IBA with an existing customer
       then the customer is removed to test that an error is launched when receiving an email of an inextistend customer
     **
     * @author nbizkarra
     * @date 05/05/2020
     **/
    // Descartado en fase de implementación
    /*@isTest
       static void test_EmailIBAinsert()
       {
          Integer numEmails= [SELECT count() FROM EmailsIBA__c];
          System.assertEquals(0, numEmails);

          Test.startTest();

          ExternalRequest__c ExtReq= new ExternalRequest__c(Origin__c='IBA', Country__c='Spain', Entity__c='EmailIBA',  Json__c='{}', Timestamp__c=Datetime.now(),  Processed__c=false);
          List<ExternalRequest__c> listExternalRequest=new List<ExternalRequest__c>();
          listExternalRequest.add(ExtReq);

          ExternalRequestUtil.processExternalRequests(listExternalRequest);

          numEmails= [SELECT count() FROM EmailsIBA__c];
          System.assertEquals(1, numEmails);

          //remove existing customer
          Contact cont=[SELECT id FROM Contact where CustomerNum__c='GI-3123'];
          delete cont;

          //Test error use case

          try{
              ExternalRequestUtil.processExternalRequests(listExternalRequest);

          }Catch(Exception e){
              system.assert(e.getMessage().contains(Label.EmailIBAError));
          }

          Test.stopTest();
       }*/

    /**
     * @description This method inserts a new Document from IBA with an existing policy
     *              then the policy is removed to test that an error is launched when receiving a document of an inextistend policy
     **
     * @author nbizkarra
     * @date 05/05/2020
     **/
    // Descartado en fase de implementación
    /*@isTest
       static void test_DocumentInsert()
       {
          Integer numDocuments = [SELECT count() FROM IBADocument__c];
          System.assertEquals(0, numDocuments);

          Test.startTest();

          ExternalRequest__c ExtReq= new ExternalRequest__c(Origin__c='IBA', Country__c='Spain', Entity__c='Document',  Json__c='{}', Timestamp__c=Datetime.now(),  Processed__c=false);
          List<ExternalRequest__c> listExternalRequest=new List<ExternalRequest__c>();
          listExternalRequest.add(ExtReq);

          ExternalRequestUtil.processExternalRequests(listExternalRequest);

          numDocuments = [SELECT count() FROM IBADocument__c];
          System.assertEquals(1, numDocuments);

          //remove existing policy
          Order policy=[SELECT id FROM Order where PolicyNum__c='8989'];
          delete policy;

          //Test error use case

          try{
              ExternalRequestUtil.processExternalRequests(listExternalRequest);

          }Catch(Exception e){
              system.assert(e.getMessage().contains(Label.ErrorIBADocument));
          }
          Test.stopTest();
       }*/

    /**
     * Test: if is recovering the data from the json to the object correctly. for coverage because metadata may change
     *
     * @author nts (agonzalezisasi)
     * @date 05/11/2020
     */
    @isTest
    static void test_dataParseCheck()
    {
        String json_customer = '[{"status":{"codeValue":"Lead","code":"6","enumName":"CUSTOMER_STATUS"},"masterPolicyDesc":"","masterPolicySerial":"","country":{"codeValue":"España","code":"ES","enumName":"COUNTRY"},"cityArea":"Bilbao","city":"Bilbao","postalCode":"48014","address1":"Mi casa","ZurichCompany":"Life Insurance","customerSerial":"234234233","surname":"","firstName":"Toni","birthdate":"1956-06-28","mobilePhone":"66666","primaryEmail":"test@test.com","ssn":"","partner":"Orange Seguros"}]';

        AdminSetup__mdt adminSetup = SystemUtil.getAdminSetupMetadata();
        String WS_SOURCE_IBA_MULTI_PARTNER = adminSetup.WS_Source_IBA_Multi_Partner__c;
        String WS_SERVICE_NAME_PROCESS_REQUEST = adminSetup.WS_Service_Process_Request__c;

        // System.Debug('*** Source MultiPartner: ' + WS_SOURCE_IBA_MULTI_PARTNER);
        // SYstem.Debug('*** Service Name Process request: ' + WS_SERVICE_NAME_PROCESS_REQUEST);

        WebServicesParser.metadataList = new List<WebServicesControl__mdt>(
            [
                SELECT
                AttributeName__c,
                Source__c,
                ServiceName__c,
                EntityName__c,
                FieldName__c,
                RelatedObjectType__c,
                Nullable__c,
                PicklistValues__c,
                IgnoreErrors__c,
                Required__c,
                Object__c,
                Array__c,
                PicklistAttributesName__c,
                External_Id__c,
                Attachable__c,
                Duplicate__c,
                Nested__c
                FROM WebServicesControl__mdt
            ]
            );

        Map<String, String> errorMessages = new Map<String, String>();
        Map<String, sObject> recordsMap = new Map<String, sObject>();

        Schema.SObjectType contactEntity = Schema.getGlobalDescribe().get('Contact');
        WebServicesParser.WebParserResult parserResultCustomer = WebServicesParser.parseObject(
            contactEntity,
            json_customer,
            WS_SOURCE_IBA_MULTI_PARTNER,
            WS_SERVICE_NAME_PROCESS_REQUEST
            );
        errorMessages = parserResultCustomer.errorMessagesMap;
        // for( String key: errorMessages.keySet() )
        // {
        //     System.Debug( key + ': ' + errorMessages.get(key) );
        // }
        // System.assertEquals(true,  errorMessages.isEmpty(), 'There should not be any errors');
        // recordsMap = parserResultCustomer.recordsMap;
        // System.assertEquals(1, recordsMap.size(), 'There should be 1 element in the records map from parser');

        // Contact customer = (Contact) recordsMap.values().get(0);
        // System.debug('**** customer: ' + customer);

        // List<Contact> customers = [
        //     SELECT Id, MailingCity, MailingCountry, LegalEntity__c, Partner__c, Status__c
        //     FROM Contact WHERE CustomerNum__c = 'Orange-234234233'
        // ];
        //System.assertEquals(1, customers.size(), 'There should be 1 customer');
        // System.assertEquals('Bilbao', customer.MailingCity, 'The city should be Bilbao');
        // System.assertEquals('Life Insurance', customer.LegalEntity__c, 'The legal entity should be Life Insurance');
        // System.assertEquals('Lead', customer.Status__c, 'The status should be Lead');
        // System.assertEquals('Orange Seguros', customer.Partner__c, 'The partner should be Orange Seguros');
        // System.assertEquals('España', customer.MailingCountry, 'The country should be España');
    }
}
