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
        Contact ExistingLead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            sourceCountry__c = 'Spain'
            );
        insert ExistingLead;

        Map<String, Contact> mapContacts = new Map<String, Contact>();
        SET<String> keys = new Set<String>();
        keys.add(ExistingLead.CustomerNum__c);
        mapContacts = SystemUtil.ContactsSelector(keys);
        System.assertEquals( 1, mapContacts.size() );
        System.assertEquals(
            ExistingLead.Email,
            mapContacts.get(ExistingLead.CustomerNum__c).Email
            );
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(ExistingLead.Email);
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();

        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;
        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Origin__c = 'IBA'
            );
        insert actualRequest;

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
        recordsToProcess.put(actualRequest.Id, lead);

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdate;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

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
    static void test_LeadUpdate_EMEA()
    {
        Contact ExistingLead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'EMEA-LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            sourceCountry__c = 'France'
            );
        insert ExistingLead;

        Map<String, Contact> mapContacts = new Map<String, Contact>();
        SET<String> keys = new Set<String>();
        keys.add(ExistingLead.CustomerNum__c);
        mapContacts = SystemUtil.ContactsSelector(keys);
        System.assertEquals( 1, mapContacts.size() );
        System.assertEquals(
            ExistingLead.Email,
            mapContacts.get(ExistingLead.CustomerNum__c).Email
            );
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(ExistingLead.Email);
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();

        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;
        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'France',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Origin__c = 'IBA EMEA'
            );
        insert actualRequest;

        Test.startTest();

        Contact lead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'EMEA-LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = Label.Lead,
            sourceCountry__c = 'France'
            );
        recordsToProcess.put(actualRequest.Id, lead);

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdate;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

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
        Contact ExistingLead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            sourceCountry__c = 'Spain'
            );
        insert ExistingLead;

        Map<String, Contact> mapContacts = new Map<String, Contact>();
        SET<String> keys = new Set<String>();
        keys.add(ExistingLead.CustomerNum__c);
        mapContacts = SystemUtil.ContactsSelector(keys);
        System.assertEquals( 1, mapContacts.size() );
        System.assertEquals(
            ExistingLead.Email,
            mapContacts.get(ExistingLead.CustomerNum__c).Email
            );
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(ExistingLead.Email);
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();

        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;
        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Origin__c = 'IBA'
            );
        insert actualRequest;

        Test.startTest();

        Contact customer = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = 'Activo',
            sourceCountry__c = 'Spain',
            MasterPolicyNum__c = '123456'
            );
        recordsToProcess.put(actualRequest.Id, customer);

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdate;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

        ContactUtil.upsertContact(customer, null);

        Contact updatedCustomer = ExternalRequestUtil.contactsToUpdate.get(
            ExistingLead.CustomerNum__c
            );
        System.assertEquals( 1, ExternalRequestUtil.contactsToUpdate.size() );
        System.assert (updatedCustomer.MobilePhone != ExistingLead.MobilePhone);
        Test.stopTest();
    }

    /**
     * @description This method updates the phone of a lead that exists in Salesforce with se same customer number
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_CustomerUpdate_EMEA()
    {
        Contact ExistingLead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'EMEA-LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadLife),
            sourceCountry__c = 'France'
            );
        insert ExistingLead;

        Map<String, Contact> mapContacts = new Map<String, Contact>();
        SET<String> keys = new Set<String>();
        keys.add(ExistingLead.CustomerNum__c);
        mapContacts = SystemUtil.ContactsSelector(keys);
        System.assertEquals( 1, mapContacts.size() );
        System.assertEquals(
            ExistingLead.Email,
            mapContacts.get(ExistingLead.CustomerNum__c).Email
            );
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(ExistingLead.Email);
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();

        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;
        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'France',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Origin__c = 'IBA EMEA'
            );
        insert actualRequest;

        Test.startTest();

        Contact customer = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'EMEA-LIFE-7897',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = 'Activo',
            sourceCountry__c = 'France'
            );
        recordsToProcess.put(actualRequest.Id, customer);

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdate;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

        ContactUtil.upsertContact(customer, null);

        Contact updatedCustomer = ExternalRequestUtil.contactsToUpdate.get(
            ExistingLead.CustomerNum__c
            );
        System.assertEquals( 1, ExternalRequestUtil.contactsToUpdate.size() );
        System.assert (updatedCustomer.MobilePhone != ExistingLead.MobilePhone);
        Test.stopTest();
    }

    /**
     * @description This method updates the phone of a lead that exists in Salesforce with se same matchcode (email+birthdate)
     * @author nbizkarra
     * @date 05/05/2020
     **/
    @isTest
    static void test_LeadUpdateMatchcode()
    {
        Contact ExistingLead = new Contact(
            Email = 'nora@test.com',
            MobilePhone = '11111',
            Status__c = Label.Lead,
            LastName = 'unknown',
            Birthdate = Date.valueOf('1990-01-01'),
            CustomerNum__c = 'LIFE-2222',
            LegalEntity__c = Label.LifeInsurance,
            sourceCountry__c = 'Spain'
            );
        insert ExistingLead;

        Map<String, Contact> mapContacts = new Map<String, Contact>();
        SET<String> keys = new Set<String>();
        keys.add(ExistingLead.CustomerNum__c);
        mapContacts = SystemUtil.ContactsSelector(keys);
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(ExistingLead.Email);
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDateLECountry(
            keys
            );
        Map<String, Account> mapPartners = new Map<String, Account>();
        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;
        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Origin__c = 'IBA'
            );
        insert actualRequest;

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
        recordsToProcess.put(actualRequest.Id, lead);

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdate;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mapContactsEmailBirthDateLE = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

        ContactUtil.upsertContact(lead, null);

        System.debug(
            'ExternalRequestUtil.contactsToUpdate >>> ' +
            ExternalRequestUtil.contactsToUpdate
            );
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
            sourceCountry__c = 'Spain'
            );
        customer.AccountId = newMaster.id;
        insert customer;

        Map<String, Contact> mapContacts = new Map<String, Contact>();
        SET<String> keys = new Set<String>();
        keys.add(customer.CustomerNum__c);
        mapContacts = SystemUtil.ContactsSelector(keys);
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(customer.Email);
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();
        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;
        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Origin__c = 'IBA'
            );
        insert actualRequest;

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
        recordsToProcess.put(actualRequest.Id, lead);

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdate;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

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

        Map<String, Contact> mapContacts = new Map<String, Contact>();
        SET<String> keys = new Set<String>();
        keys.add(customer.CustomerNum__c);
        mapContacts = SystemUtil.ContactsSelector(keys);
        Map<String, Contact> mapContactsMatchCodeLECountry = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCodeLE = new Map<String, Contact>();
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        keys.add(customer.Email);
        mapContactsMatchCodeLECountry = SystemUtil.ContactsSelectorEmailBirthDateLECountry(
            keys
            );
        mapContactsMatchCodeLE = SystemUtil.ContactsSelectorEmailBirthDateLE(keys);
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();

        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;
        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Origin__c = 'IBA'
            );
        insert actualRequest;

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
        recordsToProcess.put(actualRequest.Id, lead);

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdate;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCodeLECountry;
        ExternalRequestUtil.mapContactsEmailBirthDateLE = mapContactsMatchCodeLE;
        ExternalRequestUtil.mapContactsEmailBirthDate = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get('LIFE-7897');
        System.debug('contactsToUpdate >>> ' + contactsToUpdate);
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
        Map<String, Contact> mapContacts = new Map<String, Contact>();
        SET<String> keys = new Set<String>();

        mapContacts = SystemUtil.ContactsSelector(keys);
        Map<String, Contact> mapContactsMatchCode = new Map<String, Contact>();
        mapContactsMatchCode = SystemUtil.ContactsSelectorEmailBirthDate(keys);
        Map<String, Account> mapPartners = new Map<String, Account>();
        mapPartners = SystemUtil.PartnerSelector(keys);
        Map<String, Account> mastersToUpdateList = new Map<String, Account>();
        Map<String, Contact> contactsToUpdate = new Map<String, Contact>();
        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;
        Map<String, Object> recordsToProcess = new Map<String, Object>();
        ExternalRequest__c actualRequest = new ExternalRequest__c(
            Country__c = 'Spain',
            Entity__c = 'Customer',
            Json__c = '[{}]',
            Origin__c = 'IBA'
            );
        insert actualRequest;

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
        recordsToProcess.put(actualRequest.Id, lead);

        ExternalRequestUtil.actualRequest = actualRequest;
        ExternalRequestUtil.recordsToProcess = recordsToProcess;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.contactsToUpdate = contactsToUpdate;
        ExternalRequestUtil.mapContactsEmailBirthDateLECountry = mapContactsMatchCode;
        ExternalRequestUtil.mastersToUpdate = mastersToUpdateList;
        ExternalRequestUtil.mapPartners = mapPartners;
        ExternalRequestUtil.contactsToUpdateWithPartner = contactsToUpdateWithPartner;
        ExternalRequestUtil.partnersToUpdateList = partnersToUpdateList;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

        ContactUtil.upsertContact(lead, null);

        Contact updatedLead = ExternalRequestUtil.contactsToUpdate.get('LIFE-7897');
        Account createdMaster = mastersToUpdateList.get('7897');
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

    /*
       @isTest
       static void test_ContactTrigger()
       {

          Contact contact = new Contact( DNI__c='443485723A',Email='edu@test.com',Birthdate=Date.valueOf('1990-01-01'),FirstName='Edu',MobilePhone='1111',
          LastName='Sanchez', CustomerNum__c='3123',LegalEntity__c='GI',MasterPolicyNum__c='3344',MasterPolicyDesc__c='Nestle');

          contact.CustomerNum__c=ContactUtil.adaptCustomerNum(contact.CustomerNum__c, contact.LegalEntity__c);

          Account newMaster= new Account(Name=contact.FirstName+' '+contact.LastName,CustomerNum__c='3123',
                                          RecordTypeId=SystemUtil.getAccountRecordTypeIdByName('Master'));

          insert(newMaster);
          contact.AccountId=newMaster.Id;
          insert(contact);

          Contact contact2 = new Contact( DNI__c='443485723A',Email='edu@test.com',Birthdate=Date.valueOf('1990-01-01'),FirstName='Edu',MobilePhone='1111',
          LastName='Sanchez', CustomerNum__c='3123',LegalEntity__c='Life',MasterPolicyNum__c='3344',MasterPolicyDesc__c='Nestle');

          contact2.CustomerNum__c=ContactUtil.adaptCustomerNum(contact2.CustomerNum__c, contact2.LegalEntity__c);
          contact2.AccountId=newMaster.Id;
          insert(contact2);

          contact2.DNI__c='1111B';
          contact2.Email='test@gmail.com';
          contact2.Birthdate=Date.valueOf('1990-01-02');
          contact2.FirstName='Bob';
          contact2.LastName='Dylan';

          upsert(contact2);

          Test.startTest();
          Contact updatedContact=[SELECT id, DNI__C, Email, MobilePhone, Birthdate, FirstName, LastName  FROM Contact where CustomerNum__c='GI-3123'];

          System.assertEquals(contact2.DNI__c, updatedContact.DNI__c, 'TEST trigger: no se ha actualizado el DNI del contacto');
          System.assertEquals(contact2.Email, updatedContact.Email, 'TEST trigger: no se ha actualizado el Email del contacto');
          System.assertEquals(contact2.Birthdate, updatedContact.Birthdate, 'TEST trigger: no se ha actualizado el Birthdate del contacto');
          System.assertEquals(contact2.FirstName, updatedContact.FirstName, 'TEST trigger: no se ha actualizado el FirstName del contacto');
          System.assertEquals(contact2.LastName, updatedContact.LastName, 'TEST trigger: no se ha actualizado el LastName del contacto');

          Test.stopTest();
       }

     */
}