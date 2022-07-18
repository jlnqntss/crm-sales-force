/**
 * Clases de test para ContactUtil
 **
 * @author nbizkarra
 * @date 03/04/2020
 **/
@isTest
public class Test_ContactUtil
{
    @testSetup
    static void makeData()
    {}

    @isTest
    static void test_adaptCustomerNum()
    {
        String CustomerNum = '123456';
        String LegalEntity = Label.GeneralInsurance;
        String LegalEntity2 = Label.LifeInsurance;
        String LegalEntity3 = 'other';
        Test.startTest();
        String result1 = ContactUtil.adaptCustomerNum(CustomerNum, LegalEntity);
        String result2 = ContactUtil.adaptCustomerNum(CustomerNum, LegalEntity2);

        System.assertEquals(
            'GI-123456',
            result1,
            'Test_ContactUtil: No se ha creado correctamente el customer num'
            );
        System.assertEquals(
            'LIFE-123456',
            result2,
            'Test_ContactUtil: No se ha creado correctamente el customer num'
            );
        try
        {
            String result3 = ContactUtil.adaptCustomerNum(CustomerNum, LegalEntity3);
        }
        catch (Exception e)
        {
            System.assert (
                e.getMessage().contains('Wrong name'),
                'Test_ContactUtil: No se ha creado correctamente el customer num'
                );
        }
        Test.stopTest();
    }

    /**
     * @description This method updates the phone of a lead that exists in Salesforce with se same customer number
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_LeadUpdate()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '7897');
        insert newMaster;

        Contact ExistingLead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            sourceCountry__c = 'Spain',
            AccountId= newMaster.Id
            );
        insert ExistingLead;

        SET<String> keys = new Set<String>();
        keys.add(ExistingLead.CustomerNum__c);

        Map<String, Contact> mapContacts = SystemUtil.ContactsSelector(keys);
        System.assertEquals( 1, mapContacts.size() );
        System.assertEquals( ExistingLead.Email, mapContacts.get(ExistingLead.CustomerNum__c).Email );

        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();

        Contact lead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get(
            ExistingLead.CustomerNum__c
            );
        System.assertEquals( 1, ExternalRequestUtil.contactsToUpdate.size() );
        System.assert (updatedLead.MobilePhone != ExistingLead.MobilePhone);
        Test.stopTest();
    }

    /**
     * @description This method updates the phone of a lead that exists in Salesforce with se same customer number
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_CustomerUpdate()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '7897');
        insert newMaster;

        Contact ExistingLead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            sourceCountry__c = 'Spain',
            AccountId= newMaster.Id
            );
        insert ExistingLead;

        SET<String> keys = new Set<String>();

        keys.add(ExistingLead.CustomerNum__c);

        Map<String, Contact> mapContacts = SystemUtil.ContactsSelector(keys);
        System.assertEquals( 1, mapContacts.size() );
        System.assertEquals(ExistingLead.Email, mapContacts.get(ExistingLead.CustomerNum__c).Email );

        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();

        Contact customer = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Customer,
            sourceCountry__c = 'Spain',
            MasterPolicyNum__c = '123456'
            );

        ExternalRequestUtil.emptyStaticVariables();

        ContactUtil.upsertContact(customer, null);

        Contact updatedCustomer = ExternalRequestUtil.contactsToUpdate.get(
            ExistingLead.CustomerNum__c
            );
        System.assertEquals( 1, ExternalRequestUtil.contactsToUpdate.size() );
        System.assert (updatedCustomer.MobilePhone != ExistingLead.MobilePhone);
        Test.stopTest();
    }

    /**
     * @description MC1 This method updates the phone of a lead that exists in Salesforce with the same matchcode (email+birthdate)
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_LeadUpdateMatchcode()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '7897');
        insert newMaster;

        Contact ExistingLead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-2222',
            LegalEntity__c = Label.LifeInsurance,
            sourceCountry__c = 'Spain',
            AccountId= newMaster.id
            );
        insert ExistingLead;

        SET<String> keys = new Set<String>();
        SET<String> mobiles = new Set<String>();
        Map<String, Contact> mapContactsMatchCodeCountry = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCodeLE = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(ExistingLead.Email);
        SystemUtil.contactsSelectorMatchCode(keys, mobiles, mapContactsMatchCodeCountry, mapContactsMatchCodeLE, mapContactsMatchCode, null);

        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCodeCountry;

        ContactUtil.upsertContact(lead, null);
        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get(
            ExistingLead.CustomerNum__c
            );
        System.assert (updatedLead.MobilePhone != ExistingLead.MobilePhone);
        Test.stopTest();
    }

    /**
     * @description This method tries to insert a lead but a customer with the same matchcode (email+birthdate) is found in Salesforce,
     *              so the customer is not updated (mobile phone is not updated)
     * @author nbizkarra
     *  @date 05/05/2020
     **/
    @isTest
    static void test_LeadCustomerExistsMatchcode()
    {
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '2222',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-2222',
            Status__c = Label.Customer,
            LegalEntity__c = Label.LifeInsurance,
            sourceCountry__c = 'Spain',
            AccountId= newMaster.Id
            );
        insert customer;

        SET<String> keys = new Set<String>();
        SET<String> mobiles = new Set<String>();
        Map<String, Contact> mapContactsMatchCodeCountry = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCodeLE = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(customer.Email);
        SystemUtil.contactsSelectorMatchCode(keys, mobiles, mapContactsMatchCodeCountry, mapContactsMatchCodeLE, mapContactsMatchCode, null);

        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCodeCountry;
        ExternalRequestUtil.mapContactsEmailBirthDateLE = mapContactsMatchCodeLE;

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get(
            customer.CustomerNum__c
            );
        //The lead has not been updated
        System.assert (updatedLead == null);
        Test.stopTest();
    }

    /**
     * @description This method tries to insert a new lead whose customer number and matchcode doesn't exist in Salesforce but a customer/lead
     *              in the opposite legal entity exists with the same matchcode, so the lead is asociated to the existing master and given new customer number
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_LeadCustomerExistsMatchcodeOppositeLE()
    {
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '2222',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'GI-2222',
            Status__c = Label.Customer,
            LegalEntity__c = Label.GeneralInsurance,
            sourceCountry__c = 'Spain'
            );
        customer.AccountId = newMaster.id;
        insert customer;

        SET<String> keys = new Set<String>();
        keys.add(customer.Email);
        SET<String> mobiles = new Set<String>();
        Map<String, Contact> mapContactsMatchCodeLECountry = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCodeLE = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        SystemUtil.contactsSelectorMatchCode(
            keys, mobiles, mapContactsMatchCodeLECountry, mapContactsMatchCodeLE, mapContactsMatchCode, null
            );

        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCodeLECountry;
        ExternalRequestUtil.mapContactsEmailBirthDateLE = mapContactsMatchCodeLE;
        ExternalRequestUtil.mapContactsEmailBirthDate = mapContactsMatchCode;

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get('LIFE-7897');
        System.assert (updatedLead != null);
        System.assertEquals(customer.AccountId, updatedLead.AccountId);

        Test.stopTest();
    }

    /**
     * @description This method inserts a new lead whose customer number and matchcode don't exist in Salesforce LIFE-7897
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_LeadDoesntExist()
    {
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get('LIFE-7897');
        Account createdMaster = ExternalRequestUtil.mastersToUpdate.get('7897');
        System.assert (updatedLead != null);
        System.assert (createdMaster != null);

        Test.stopTest();
    }

    @isTest
    static void test_generateHashContactId()
    {
        Test.startTest();

        //inserciones de contacto qye ya incluyen generateHashContactId()
        Contact leadLife = new Contact(
            Email = 'test@test.com',
            LastName = 'Contact 1',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = '1234568',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead
            );
        Contact customerGI = new Contact(
            Email = 'test@test.com',
            LastName = 'Contact 2',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = '456789',
            LegalEntity__c = Label.GeneralInsurance,
            Status__c = Label.Customer
            );
        List<Contact> contacts = new List<Contact>();
        contacts.add(leadLife);
        contacts.add(customerGI);

        insert contacts;

        Contact customerGI2 = new Contact(
            Email = 'test@test.com',
            LastName = 'Contact 3',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = '896548',
            LegalEntity__c = Label.GeneralInsurance,
            Status__c = Label.Customer
            );

        insert customerGI2;

        Test.stopTest();

        List<Contact> cListNotNull = [
            SELECT Id
            FROM Contact
            WHERE HashedId__c != NULL
        ];

        System.assertEquals( 3, cListNotNull.size() );
    }

    @isTest
    static void test_updateQuoteStep4and5()
    {
        Contact c = new Contact(
            Email = 'edu@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance
            );
        insert c;

        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        insert newMaster;
        Order quote = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '3123',
            QuoteEntry__c = '89898787',
            Status = 'Sync',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI),
            QbLastPage__c = 'elige tu protección',
            After_Processing_Check__c = true
            );

        quote.AccountId = newMaster.id;
        quote.ContactId__c = c.id;
        insert quote;

        Test.startTest();
        quote = [
            SELECT id, Step__c, QbLastPage__c
            FROM Order
            WHERE QuoteEntry__c = '89898787'
        ];
        System.assertEquals('Step4', quote.Step__c);
        System.assertEquals('elige tu protección', quote.QbLastPage__c);

        c.MailingStreet = 'test';

        update c;

        quote = [SELECT id, Step__c FROM Order WHERE QuoteEntry__c = '89898787'];
        System.assertEquals('Step5', quote.Step__c);

        Test.stopTest();
    }

    /**
     * Test: delete de contact for coverage
     *
     * @author nts (agonzalezisasi)
     * @date 04/11/2020
     */
    @isTest
    static void test_updateAnddeleteContact()
    {
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '2222',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'GI-2222',
            Status__c = Label.Customer,
            LegalEntity__c = Label.GeneralInsurance,
            sourceCountry__c = 'Spain'
            );
        customer.AccountId = newMaster.id;
        insert customer;

        test.startTest();

        customer.MobilePhone = '2222';
        update customer;

        delete customer;
        List<Contact> contacts = [SELECT Id FROM Contact WHERE Id = :customer.Id];
        System.assertEquals( true, contacts.isEmpty() );

        test.stopTest();
    }

    /**
     * Test: Upsert contact when subscriber exists
     *
     * @author nts (nbizkarra)
     * @date 18/11/2020
     */
    @isTest
    static void test_UpsertContactSubscriber()
    {
        Account newMaster = new Account(
            Name = 'test',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = 'test@test.com',
            LastName = 'Test',
            IsSubscriber__c  = true,
            Status__c = Label.Lead,
            LegalEntity__c = Label.LifeInsurance,
            sourceCountry__c = 'Spain',
            AccountId= newMaster.Id
            );
        insert customer;

        SET<String> keys = new Set<String>();
        SET<String> mobiles = new Set<String>();
        Map<String, Contact> mapContactsMatchCodeCountry = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCodeLE = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        Map<String, List<Contact> > mapSubscribers = new Map<String, List<Contact> >();
        keys.add(customer.Email);
        SystemUtil.contactsSelectorMatchCode(keys, mobiles,
                                             mapContactsMatchCodeCountry, mapContactsMatchCodeLE, mapContactsMatchCode,
                                             mapSubscribers
                                             );
        // mapSubscribers = SystemUtil.contactsSelectorSubscribers(keys);

        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = 'test@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCodeCountry;
        ExternalRequestUtil.mapContactsEmailBirthDateLE = mapContactsMatchCodeLE;
        ExternalRequestUtil.mapSubscribers = mapSubscribers;

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get(
            lead.CustomerNum__c
            );
        //A subscriber has been found (same country, partner and LE)
        System.assert (updatedLead.id != null);
        Test.stopTest();
    }

    /**
     * Test: Upsert contact when subscriber exists from the opposite legal entity
     *
     * @author nts (nbizkarra)
     * @date 18/11/2020
     */
    @isTest
    static void test_UpsertContact_MasterSubscriber()
    {
        Account newMaster = new Account(
            Name = 'test',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = 'test@test.com',
            LastName = 'Test',
            IsSubscriber__c  = true,
            Status__c = Label.Lead,
            LegalEntity__c = Label.GeneralInsurance,
            sourceCountry__c = 'Spain',
            AccountId= newMaster.Id
            );
        insert customer;

        SET<String> keys = new Set<String>();
        SET<String> mobiles = new Set<String>();
        Map<String, Contact> mapContactsMatchCodeCountry = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCodeLE = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        Map<String, List<Contact> > mapSubscribers = new Map<String, List<Contact> >();
        keys.add(customer.Email);
        SystemUtil.contactsSelectorMatchCode(keys, mobiles,
                                             mapContactsMatchCodeCountry, mapContactsMatchCodeLE, mapContactsMatchCode,
                                             mapSubscribers
                                             );
        // mapSubscribers = SystemUtil.contactsSelectorSubscribers(keys);

        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = 'test@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Customer,
            sourceCountry__c = 'Spain',
            MasterPolicyNum__c = '123234'
            );

        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCodeCountry;
        ExternalRequestUtil.mapContactsEmailBirthDateLE = mapContactsMatchCodeLE;
        ExternalRequestUtil.mapSubscribers = mapSubscribers;

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get(
            lead.CustomerNum__c
            );
        //the lead has been related to the existing subsriber
        System.assert (updatedLead.AccountId != null);
        Test.stopTest();
    }

    /**
     * Test para el método de creación de matchcode
     *
     * @author nts (nbizkarra)
     * @date 10/03/2021
     */
    @isTest
    static void test_createMatchcode()
    {
        String matchcode;
        Contact contacto = new Contact(
            Email = 'test@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            sourceCountry__c = 'Spain'
            );

        //Matchcode: email+birthdate
        matchcode = ContactUtil.createMatchcode( contacto );
        System.assertEquals(contacto.Email + contacto.Birthdate, matchcode);

        //Matchcode: mobilephone+birthdate
        contacto.Email = null; 
        matchcode = ContactUtil.createMatchcode( contacto );
        System.assertEquals(contacto.sourceCountry__c +contacto.MobilePhone + contacto.Birthdate, matchcode);

        //Matchcode: email+mobilephone
        contacto.Email = 'test@test.com';
        contacto.Birthdate = null;
        matchcode = ContactUtil.createMatchcode( contacto );
        System.assertEquals( contacto.Email + contacto.sourceCountry__c +contacto.MobilePhone , matchcode);

        //Matchcode: email
        contacto.MobilePhone = null;
        matchcode = ContactUtil.createMatchcode( contacto );
        System.assertEquals( contacto.Email  , matchcode);

        //Matchcode: phone
        contacto.MobilePhone = '456456456';
        contacto.Email = null;
        matchcode = ContactUtil.createMatchcode( contacto );
        System.assertEquals( contacto.sourceCountry__c + contacto.MobilePhone  , matchcode);
        
    }
}