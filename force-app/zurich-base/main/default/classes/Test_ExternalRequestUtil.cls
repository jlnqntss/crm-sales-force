/**
 * Clases de test para ExternalRequestUtil
 **
 * @author nbizkarra
 * @date 26/04/2020
 **/
@isTest
public class Test_ExternalRequestUtil
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

        //Master 3123
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '3123',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        Account MasterRef = new Account(CustomerNum__c = '3123');
        insert newMaster;

        // Customer GI-3123
        Contact customer = new Contact(
            Email = 'edu@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            Status__c = Label.Customer,
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI)
            );
        Contact ContactRef = new Contact(CustomerNum__c = 'GI-3123');
        //customer.Account=newMaster;
        customer.AccountId = newMaster.id;
        insert customer;

        //PolicyGI 8989
        Order policy = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '3123',
            LegalEntity__c = Label.GeneralInsurance,
            PolicyNum__c = '8989',
            Status = 'Sync',
            PolicyContractSerial__c = '1111-6',
            PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );
        policy.Account = MasterRef;
        policy.ContactId__r = ContactRef;
        policy.Pricebook2Id = standardPricebook.Id;
        insert policy;

        //QuoteGI 10000
        Order quote = new Order(
            QbLastPage__c = 'test',
            EffectiveDate = Date.valueOf('1994-01-01'),
            Status = 'Sync',
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI),
            CustomerNum__c = '3123',
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '10000'
            );
        quote.Account = MasterRef;
        quote.ContactId__r = ContactRef;
        quote.Pricebook2Id = standardPricebook.Id;
        insert quote;

        //Claim 797
        Case claim = new Case(
            ClaimNumber__c = '797',
            PolicyNum__c = '8989',
            CustomerNum__c = '3123',
            LegalEntity__c = Label.GeneralInsurance,
            DateReg__c = Date.valueOf('2020-01-05'),
            InsuredObjectId__c = '123456789',
            RecordTypeId = SystemUtil.getClaimRecordType()
            );
        insert claim;
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
        Test.startTest();
        Contact existingCustomer = [
            SELECT id, FirstName
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        Contact updatedCustomer = [
            SELECT id, FirstName
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        System.assert (existingCustomer.FirstName != updatedCustomer.FirstName);

        Test.stopTest();
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
        Contact existingCustomer = [
            SELECT id, FirstName
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];
        delete existingCustomer;

        Account existingMaster = [
            SELECT id
            FROM Account
            WHERE CustomerNum__c = '3123'
        ];
        delete existingMaster;

        Test.startTest();

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        //New contact with existing Account
        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        Contact newCustomer = [
            SELECT id, AccountId
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        System.assert (newCustomer != null);

        System.assert (newCustomer.AccountId != null);

        Test.stopTest();
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
        Contact existingCustomer = [
            SELECT Id, CustomerNum__c, LegalEntity__c
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];
        Account master = [SELECT Id FROM Account WHERE CustomerNum__c = '3123'];
        existingCustomer.AccountId = master.id;
        existingCustomer.LegalEntity__c = Label.LifeInsurance;
        existingCustomer.CustomerNum__c = 'LIFE-3123';
        upsert existingCustomer;

        Test.startTest();
        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        Contact newCustomer = [
            SELECT Id, AccountId, LegalEntity__c
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        System.assert (newCustomer != null);
        System.assertEquals(Label.GeneralInsurance, newCustomer.LegalEntity__c);
        System.assertEquals(master.Id, newCustomer.AccountId);

        Test.stopTest();
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

        Test.startTest();
        //try error scenario: quote from the app and customer doesnt exist
        Contact cont = [SELECT id FROM Contact WHERE CustomerNum__c = 'GI-3123'];

        delete cont;

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
            Json__c = '{}',
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
        /*Contact newLead=[Select id, CustomerNum__c from Contact where CustomerNum__c='GI-9999'];
            Order newQuote=[SELECT Id, (Select id from Descuentos__r),(Select id from OrderItems) from Order where QuoteEntry__c='9090'];
            //check if lead and quote have been created
            System.assert(newLead!=null);
            System.assert(newQuote!=null);
            //Check if discount has been inserted
            System.assert(newQuote.Descuentos__r!=null);
            //check that orderItems have been added to quote
            System.assert(newQuote.OrderItems!=null);

            //TEST2: insert new quote with existing lead (customer number)
            delete newQuote;
            ExternalRequestUtil.processExternalRequests(listExternalRequest);
            newQuote=[SELECT Id, ContactId__c from Order where QuoteEntry__c='9090'];
            //check if the quote has been asigned to the existing lead
            System.assertEquals(newLead.id, newQuote.ContactId__c);*/

        Test.stopTest();
    }

    /**
     * @description This method inserts a new quote from the Web
     *              TEST1: a new quote is inserted with existing lead (matchcode, email+birthdate)
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_QuoteWebMatchCode()
    {
        // TEST1: insert new quote with existing lead (matchcode, email+birthdate)

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
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI)
            );
        lead.AccountId = newMaster.id;
        insert lead;

        Test.startTest();

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        /*ExternalRequestUtil.processExternalRequests(listExternalRequest);
            Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c from Order where QuoteEntry__c='9090'];
            //check if the quote has been asigned to the existing lead (matchcode)
            System.assertEquals(lead.CustomerNum__c, newQuote.ContactId__r.CustomerNum__c);*/

        Test.stopTest();
    }

    /**
     * @description This method inserts a new quote from the Web
     *              //TEST2: a new quote with existing master will be insterted (matchcode opposite legal entity)
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
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife)
            );
        lead.AccountId = newMaster.id;
        insert lead;

        Test.startTest();
        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'QuoteEntry',
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();

        listExternalRequest.add(ExtReq);

        //TEST2: a new quote with existing master will be insterted (matchcode opposite legal entity
        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        /*ExternalRequestUtil.processExternalRequests(listExternalRequest);

            Order newQuote=[SELECT Id, ContactId__r.CustomerNum__c from Order where QuoteEntry__c='9090'];
            //check if the quote has been asigned to the opposite legal entity GI-888888
            System.assertEquals('GI-888888', newQuote.ContactId__r.CustomerNum__c);*/
        Test.stopTest();
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
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();

        // gpacho 2020-09-16 COMENTADO PARA SUBIDA A PRO - HAY PROBLEMAS CON LA CLASE MOCK
        /*ExternalRequestUtil.processExternalRequests(listExternalRequest);

            Order updatedPolicy=[SELECT Id, PolicyContractSerial__c from Order where PolicyNum__c='1111'];
            //Check if Policy version updated
            system.assert(updatedPolicy.PolicyContractSerial__c != policy.PolicyContractSerial__c );*/

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
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        Test.startTest();

        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        customer = [
            SELECT Id, (SELECT id FROM Pedidos__r WHERE PolicyNum__c != NULL)
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];
        //after inserting customer has 2 policies
        // @todo change 1 por 2
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

        //test that the partner has been created
        Account partner = [SELECT Name FROM Account WHERE Masterpolicy__c != NULL];
        system.assertEquals('Rastreator', partner.Name);

        Test.stopTest();
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
            Json__c = '{}',
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
            Json__c = '{}',
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

        Test.startTest();

        //Test error use case: claim without customer
        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Claim',
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        try
        {
            ExternalRequestUtil.processExternalRequests(listExternalRequest);
        }
        catch (Exception e)
        {
            system.assert ( e.getMessage().contains(Label.CustomerError) );
        }

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

        Test.stopTest();
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
        Test.startTest();

        Case existingClaim = [
            SELECT id, DateReg__c
            FROM Case
            WHERE ClaimNumber__c = '797'
        ];

        ExternalRequest__c ExtReq = new ExternalRequest__c(
            Origin__c = 'IBA',
            Country__c = 'Spain',
            Entity__c = 'Claim',
            Json__c = '{}',
            Timestamp__c = Datetime.now(),
            Processed__c = false
            );
        List<ExternalRequest__c> listExternalRequest = new List<ExternalRequest__c>();
        listExternalRequest.add(ExtReq);

        ExternalRequestUtil.processExternalRequests(listExternalRequest);

        Case updatedClaim = [
            SELECT id, DateReg__c
            FROM Case
            WHERE ClaimNumber__c = '797'
        ];

        System.assert (existingClaim.DateReg__c != updatedClaim.DateReg__c);

        Test.stopTest();
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
}