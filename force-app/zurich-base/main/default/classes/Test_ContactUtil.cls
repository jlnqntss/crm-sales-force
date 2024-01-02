/**
 * Clases de test para ContactUtil
 **
 * @author nbizkarra
 * @date 03/04/2020
 **/
@isTest
private with sharing class Test_ContactUtil
{
    static final String ERROR_MESSAGE_CUSTOMER_NUM = 'Test_ContactUtil: No se ha creado correctamente el customer num';
    static final String EMAIL_CONTACT = 'nora@test.com' ;
    static final String EMAIL_CONTACT_TEST = 'test@test.com';
    static final String BIRTHDAY_DATE = '1990-01-01' ;
    static final String CUSTOMER_NUM = 'LIFE-7897';

    @testSetup
    private static void makeData()
    {}

    @isTest
    private static void test_adaptCustomerNum()
    {
        String customerNum = '123456';
        String legalEntity = Label.GeneralInsurance;
        String legalEntity2 = Label.LifeInsurance;
        String legalEntity3 = 'other';
        Test.startTest();
        String result1 = ContactUtil.adaptCustomerNum(customerNum, legalEntity);
        String result2 = ContactUtil.adaptCustomerNum(customerNum, legalEntity2);
        String result3;

        System.assertEquals(
            'GI-123456',
            result1,
            ERROR_MESSAGE_CUSTOMER_NUM
            );
        System.assertEquals(
            'LIFE-123456',
            result2,
            ERROR_MESSAGE_CUSTOMER_NUM
            );
        try
        {
            result3 = ContactUtil.adaptCustomerNum(customerNum, legalEntity3);
        }
        catch (Exception e)
        {
            System.assert (
                e.getMessage().contains('Wrong name'),
                ERROR_MESSAGE_CUSTOMER_NUM
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
    private static void test_LeadUpdate()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '7897');
        insert newMaster;

        Contact existingLead = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            sourceCountry__c = 'Spain',
            AccountId= newMaster.Id
            );
        insert existingLead;

        SET<String> keys = new Set<String>();
        keys.add(existingLead.CustomerNum__c);

        Map<String, Contact> mapContacts = SystemUtil.ContactsSelector(keys);
        System.assertEquals( 1, mapContacts.size() );
        System.assertEquals( existingLead.Email, mapContacts.get(existingLead.CustomerNum__c).Email );

        Pricebook2 pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update pricebook;

        Test.startTest();

        Contact lead = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
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
    private static void test_CustomerUpdate()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '7897');
        insert newMaster;

        Contact existingLead = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            sourceCountry__c = 'Spain',
            AccountId= newMaster.Id
            );
        insert existingLead;

        SET<String> keys = new Set<String>();

        keys.add(existingLead.CustomerNum__c);

        Map<String, Contact> mapContacts = SystemUtil.ContactsSelector(keys);
        System.assertEquals( 1, mapContacts.size() );
        System.assertEquals(existingLead.Email, mapContacts.get(existingLead.CustomerNum__c).Email );

        Pricebook2 pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update pricebook;

        Test.startTest();

        Contact customer = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Customer,
            sourceCountry__c = 'Spain',
            MasterPolicyNum__c = '123456'
            );

        ExternalRequestUtil.emptyStaticVariables();

        ContactUtil.upsertContact(customer, null);

        Contact updatedCustomer = ExternalRequestUtil.contactsToUpdate.get(
            existingLead.CustomerNum__c
            );
        System.assertEquals( 1, ExternalRequestUtil.contactsToUpdate.size() );
        System.assert (updatedCustomer.MobilePhone != existingLead.MobilePhone);
        Test.stopTest();
    }

    /**
     * @description MC1 This method updates the phone of a lead that exists in Salesforce with the same matchcode (email+birthdate)
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    private static void test_LeadUpdateMatchcode()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '7897');
        insert newMaster;

        Contact existingLead = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = 'LIFE-2222',
            LegalEntity__c = Label.LifeInsurance,
            sourceCountry__c = 'Spain',
            AccountId= newMaster.id
            );
        insert existingLead;

        SET<String> keys = new Set<String>();
        SET<String> mobiles = new Set<String>();
        Map<String, Contact> mapContactsMatchCodeCountry = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCodeLE = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(existingLead.Email);
        SystemUtil.contactsSelectorMatchCode(keys, mobiles, mapContactsMatchCodeCountry, mapContactsMatchCodeLE, mapContactsMatchCode, null);

        Pricebook2 pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCodeCountry;

        ContactUtil.upsertContact(lead, null);
        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get(
            existingLead.CustomerNum__c
            );
        System.assert (updatedLead.MobilePhone != existingLead.MobilePhone);
        Test.stopTest();
    }

    /**
     * @description This method tries to insert a lead but a customer with the same matchcode (email+birthdate) is found in Salesforce,
     *              so the customer is not updated (mobile phone is not updated)
     * @author nbizkarra
     *  @date 05/05/2020
     **/
    @isTest
    private static void test_LeadCustomerExistsMatchcode()
    {
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '2222',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '11111',
            LastName = 'unknown',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
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

        Pricebook2 pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
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
    private static void test_LeadCustomerExistsMatchcodeOppositeLE()
    {
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '2222',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '11111',
            LastName = 'unknown',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
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

        Pricebook2 pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCodeLECountry;
        ExternalRequestUtil.mapContactsEmailBirthDateLE = mapContactsMatchCodeLE;
        ExternalRequestUtil.mapContactsEmailBirthDate = mapContactsMatchCode;

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get(CUSTOMER_NUM);
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
    private static void test_LeadDoesntExist()
    {
        Pricebook2 pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'Spain'
            );

        ExternalRequestUtil.emptyStaticVariables();

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get(CUSTOMER_NUM);
        Account createdMaster = ExternalRequestUtil.mastersToUpdate.get('7897');
        System.assert (updatedLead != null);
        System.assert (createdMaster != null);

        Test.stopTest();
    }

    @isTest
    private static void test_generateHashContactId()
    {
        Test.startTest();

        //inserciones de contacto qye ya incluyen generateHashContactId()
        Contact leadLife = new Contact(
            Email = EMAIL_CONTACT_TEST,
            LastName = 'Contact 1',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = '1234568',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead
            );
        Contact customerGI = new Contact(
            Email = EMAIL_CONTACT_TEST,
            LastName = 'Contact 2',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = '456789',
            LegalEntity__c = Label.GeneralInsurance,
            Status__c = Label.Customer
            );
        List<Contact> contacts = new List<Contact>();
        contacts.add(leadLife);
        contacts.add(customerGI);

        insert contacts;

        Contact customerGI2 = new Contact(
            Email = EMAIL_CONTACT_TEST,
            LastName = 'Contact 3',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
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
    private static void test_updateQuoteStep4and5()
    {
        Contact c = new Contact(
            Email = 'edu@test.com',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
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
    private static void test_updateAnddeleteContact()
    {
        Account newMaster = new Account(
            Name = 'test',
            CustomerNum__c = '2222',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = EMAIL_CONTACT,
            MobilePhone = '11111',
            LastName = 'unknown',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
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
    private static void test_UpsertContactSubscriber()
    {
        Account newMaster = new Account(
            Name = 'test',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = EMAIL_CONTACT_TEST,
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

        Pricebook2 pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = EMAIL_CONTACT_TEST,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
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
    private static void test_UpsertContact_MasterSubscriber()
    {
        Account newMaster = new Account(
            Name = 'test',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Master)
            );
        insert newMaster;

        Contact customer = new Contact(
            Email = EMAIL_CONTACT_TEST,
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

        Pricebook2 pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update pricebook;

        Test.startTest();
        Contact lead = new Contact(
            Email = EMAIL_CONTACT_TEST,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
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
    private static void test_createMatchcode()
    {
        String matchcode;
        Contact contacto = new Contact(
            Email = EMAIL_CONTACT_TEST,
            MobilePhone = '456456456',
            Birthdate = Date.valueOf(BIRTHDAY_DATE),
            CustomerNum__c = CUSTOMER_NUM,
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
        contacto.Email = EMAIL_CONTACT_TEST;
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

    /**
     * Método que testea el método generateAccountIdSet
     * @author jjuaristi@seidor.es
     * @date 16/11/2022
     */
    @IsTest
    private static void test_generateAccountIdSet_OK ()
    {
        List<Account> accounts = TestDataFactory.generateAccounts('001', 'PartnerOCS', 10);
        insert accounts;
        List<Contact> contacts = TestDataFactory.generateContactsFromAccounts(accounts, 'AgentMediator', 1);
        insert contacts;
        
        List<Contact> contactsToCheck = [SELECT Id, AccountId FROM Contact WHERE AccountId != '' LIMIT 5];

        Test.startTest();
        Set<Id> accountIds = ContactUtil.generateAccountIdSet(contactsToCheck);
        Test.stopTest();

        List<Id> idList = new List<Id>();
        for(contact currentContact : contactsToCheck )
        {
            idList.add(currentContact.AccountId);
        }
        System.assertEquals( true  , accountIds.containsAll(idList));
    }

    
    /**
     * Método que comprueba que se obtiene correctamente el id de las cuentas asociadas a los contactos
     * @author aberuete
     * @date 17/04/2023
     */
    @IsTest
    private static void test_getAccountIdsFromContact ()
    {
        List<Account> accountsToInsert = TestDataFactory.generateAccounts(null, 'Intermediary', 2);
        insert accountsToInsert;

        List<Contact> contactsToInsert = TestDataFactory.generateContactsFromAccounts(accountsToInsert, 'AgentMediator', 1);
        insert contactsToInsert;

        Set<Id> idSet = new Set<Id>();
        List<Contact> newList = new  List<Contact> ();
        newList.add (contactsToInsert[0]);

        Map<Id, Contact> oldMap = new Map<Id,Contact>();
        oldMap.put(contactsToInsert[1].id,contactsToInsert[1]);

        Test.startTest();
        idSet = ContactUtil.getAccountIdsFromContact(newList, oldMap, idSet);
        Test.stopTest();

        System.assertEquals(true, idSet.contains(contactsToInsert[0].AccountId), 'La cuenta asociada al primer contacto debería estar en el conjunto devuelto');
        System.assertEquals(true, idSet.contains(contactsToInsert[1].AccountId), 'La cuenta asociada al segundo contacto debería estar en el conjunto devuelto');
    }

    /**
     * Método que comprueba que se actualizan correctamente las quotes asociadas a los contactos
     * @author aberuete
     * @date 17/04/2023
     */
    @IsTest
    private static void test_updateQuotes ()
    {
        List<Account> account = TestDataFactory.generateAccounts(null, 'Intermediary', 1);
        insert account;

        List<Contact> contactList = new List<Contact> ();
        List<Order> quoteList = new List<Order> ();
        Map<ID, Contact> mapContactos = new Map<Id, Contact>();
        Map<Id, Contact> oldMap = new Map<Id,Contact>();
        Map<ID, Order> mapQuotes = new Map<ID, Order>();

        for (Integer i=0;i<2;i++)
        {
            contactList.add(new Contact(LastName = 'contacto prueba'+i,MailingStreet = '123 Main St'));
            quoteList.add (new Order(QbLastPage__c = 'Elige tu protección', Step__c = 'Step4', AccountId = account[0].Id, Status = 'Sync',EffectiveDate = Date.valueOf('1994-01-01'),ContactId__c = contactList[i].id));
        }
        contactList[0].CreditCard__c = '1234567812';
        insert contactList;
        insert quoteList;

        contactList[0].LastQuote__c = quoteList[0].id ;
        contactList[1].LastQuote__c = quoteList[1].id ;
        update contactList;

        for (Integer i=0;i<2;i++)
        {
            mapContactos.put(contactList[i].Id, contactList[i]);
            oldMap.put(contactList[i].Id, new Contact(Id = contactList[i].Id, MailingStreet = '456 Oak St', CreditCard__c = '1234567812'));
            mapQuotes.put(quoteList[i].Id, quoteList[i]);
        }

        Test.startTest();
        ContactUtil.updateQuotes (mapContactos, mapQuotes,oldMap);
        Test.stopTest();

        Order quoteActualizadoTo5 = [SELECT id,Step__c FROM Order WHERE Id = :quoteList[0].Id];
        Order quoteActualizadoTo6 = [SELECT id,Step__c FROM Order WHERE Id = :quoteList[1].Id];
        System.assertEquals('Step5', quoteActualizadoTo5.Step__c, 'El Step__c de la Quote no se actualizó correctamente a 5');
        System.assertEquals('Step6', quoteActualizadoTo6.Step__c, 'El Step__c de la Quote no se actualizó correctamente a 6 ');
    }
}