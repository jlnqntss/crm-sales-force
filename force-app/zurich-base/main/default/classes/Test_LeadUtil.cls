/**
 * Clases de test para LeadUtil
 **
 * @author nbizkarra
 * @date 17/11/2020
 **/
@isTest
private with sharing class Test_LeadUtil
{
    static final String EMAIL_CONTACTOS_TEST = 'testexisting@test.com';
    static final String CUSTOMER_NUM_TEST = 'Life-3123';

    @testSetup
    private static void makeData()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        insert newMaster;

        Contact customerGI = new Contact(
            Email = EMAIL_CONTACTOS_TEST,
            LastName = 'Test',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            Status__c = 'Activo',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            SourceCountry__c = 'Spain',
            AccountId = newMaster.Id
            );

        insert customerGI;

        Contact customerLife = new Contact(
            Email = EMAIL_CONTACTOS_TEST,
            LastName = 'Test',
            CustomerNum__c = CUSTOMER_NUM_TEST,
            LegalEntity__c = Label.LifeInsurance,
            Status__c = 'Activo',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerLife),
            SourceCountry__c = 'Spain',
            AccountId = newMaster.Id
            );

        insert customerLife;

        Contact lead = new Contact(
            Email = 'edutest@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Test',
            CustomerNum__c = 'GI-3125',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI),
            IsSubscriber__c = true,
            HasOptedOutOfEmail = false
            );
        insert lead;

        Contact lead2 = new Contact(
            Email = 'edu2test@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu2',
            LastName = 'Test2',
            CustomerNum__c = 'GI-1112',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI),
            IsSubscriber__c = true,
            HasOptedOutOfEmail = true 
            );
        insert lead2;
    }


    /**
     * @description This method creates a new subscriber whose email doesn't exist in SF
     * @author nbizkarra
     * @date 17/11/2020
     **/
    @isTest
    private static void test_NewSubscriber()
    {

        List<Lead> subscribers = new List<Lead>();

        Lead subscriber = new Lead (
            Email = 'test@test.com',
            LastName = 'Test',
            CheckGI__c = true,
            CheckLife__c = true,
            Country = 'Spain',
            LeadSource = 'Klinc'
            );

        subscribers.add(subscriber);

        Test.startTest();

        LeadUtil.NewSubscribers(subscribers);
        //Check that 2 contacts (life and GI) are created in SF
        System.assertEquals( 2, LeadUtil.contactsToCreate.size() );

        Test.stopTest();
    }

    /**
     * @description This method creates a new subscriber and updates existing contact
     * @author nbizkarra
     * @date 17/11/2020
     **/
    @isTest
    private static void test_ExistingSubscriber()
    {

        List<Lead> subscribers = new List<Lead>();

        Lead subscriber = new Lead (
            Email = EMAIL_CONTACTOS_TEST,
            LastName = 'Test',
            CheckGI__c = true,
            CheckLife__c = true,
            Country = 'Spain',
            LeadSource = 'Klinc'
            );

        subscribers.add(subscriber);

        Test.startTest();

        LeadUtil.NewSubscribers(subscribers);
        //Check that 2 contacts (life and GI) are updated in SF
        List<Contact> c=LeadUtil.mapContacts.values().get(0);
        System.assertEquals(EMAIL_CONTACTOS_TEST, c.get(0).Email);
        System.assertEquals( 2, LeadUtil.contactsToUpdate.size() );

        Test.stopTest();
    }

    /**
     * @description This method creates a new subscriber and relates to the existing account
     * @author nbizkarra
     * @date 17/11/2020
     **/
    @isTest
    private static void test_ExistingMaster1()
    {

        List<Lead> subscribers = new List<Lead>();

        Lead subscriber = new Lead (
            Email = EMAIL_CONTACTOS_TEST,
            LastName = 'Test',
            CheckGI__c = true,
            CheckLife__c = true,
            Country = 'France',
            LeadSource = 'Klinc'
            );

        subscribers.add(subscriber);

        Test.startTest();

        LeadUtil.NewSubscribers(subscribers);
        //Check that 2 contacts (life and GI) are created in SF
        System.assertEquals( 2, LeadUtil.contactsToCreate.size() );

        Test.stopTest();
    }

    /**
     * @description This method creates a new subscriber and relates to one of the 2 existing account
     * @author nbizkarra
     * @date 17/11/2020
     **/
    @isTest
    private static void test_ExistingMaster2()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '1111');
        insert newMaster;

        Contact customerGI = new Contact(
            Email = EMAIL_CONTACTOS_TEST,
            LastName = 'Test',
            CustomerNum__c = 'GI-1111',
            LegalEntity__c = Label.GeneralInsurance,
            Status__c = 'Lead',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.LeadGI),
            SourceCountry__c = 'Spain',
            AccountId = newMaster.Id
            );

        insert customerGI;

        List<Lead> subscribers = new List<Lead>();

        Lead subscriber = new Lead (
            Email = EMAIL_CONTACTOS_TEST,
            LastName = 'Test',
            CheckGI__c = true,
            CheckLife__c = true,
            Country = 'France',
            LeadSource = 'Klinc'
            );

        subscribers.add(subscriber);

        Test.startTest();

        LeadUtil.NewSubscribers(subscribers);
        //Check that 2 contacts (life and GI) are created in SF
        System.assertEquals( 2, LeadUtil.contactsToCreate.size() );

        //Check that the created contacts are related to the master whose contact is a customer
        SET<String> customerNum = new SET<String>();
        customerNum.add(CUSTOMER_NUM_TEST);
        Map<String, Contact> mapContact = SystemUtil.contactsSelector(customerNum);
        Contact contact = mapContact.get(CUSTOMER_NUM_TEST);

        System.assertEquals(contact.AccountId, LeadUtil.contactsToCreate.get(0).AccountId);
        System.assertEquals(contact.AccountId, LeadUtil.contactsToCreate.get(1).AccountId);

        Test.stopTest();
    }

     /**
     * @description Comprueba si se elimina correctamente un contacto que es suscriptor y se ha desuscrito
     * @author aberuete
     * @date 03/04/2023
     **/
    @isTest
    private static void test_deleteContact()
    {
        List<Contact> leadsToDeleteBefore = [Select id,IsSubscriber__c,HasOptedOutOfEmail from Contact where recordtype.developerName =: Label.LeadGI and IsSubscriber__c = true and HasOptedOutOfEmail = true ];
        
        Test.startTest(); 
        LeadUtil.deleteOrUpdateContacs(leadsToDeleteBefore);
        Test.stopTest(); 

        List<Contact> leadsToDeleteAfter = [Select id,IsSubscriber__c,HasOptedOutOfEmail from Contact where recordtype.developerName =: Label.LeadGI and IsSubscriber__c = true and HasOptedOutOfEmail = true ];

        System.assertEquals (1,leadsToDeleteBefore.size(),'El número de contactos debe ser 1');
        System.assertEquals (0,leadsToDeleteAfter.size(),'El contacto se debe haber borrado');
    }

    /**
     * @description Comprueba si se actualizan los valores a nulo si  un contacto que es suscriptor y  no se ha desuscrito
     * @author aberuete
     * @date 03/04/2023
     **/
    @isTest
    private static void test_updateContact()
    {
        List<Contact> leadsToUpdateBefore = [Select id,IsSubscriber__c,HasOptedOutOfEmail,Balance__c,Birthdate,CNO__c,CreditCard__c,CustomerID__c,CustomerNum__c,DNI__c,EmailHash__c,Gender__c,Job__c,JobPosition__c,
        MailingCity,MailingCountry,MailingPostalCode,MailingState,MailingStreet,MasterPolicy__c,MasterPolicyDesc__c,MasterPolicyNum__c,MobilePhone,MonthExpiryDate__c,Nationality__c,YearExpiryDate__c,Abandoned_Lead__c
         from Contact where recordtype.developerName =: Label.LeadGI and IsSubscriber__c = true and HasOptedOutOfEmail = false ];
        
        Test.startTest(); 
        LeadUtil.deleteOrUpdateContacs(leadsToUpdateBefore);
        Test.stopTest(); 

        List<Contact> leadsToUpdateAfter = [Select id,IsSubscriber__c,HasOptedOutOfEmail,Balance__c,Birthdate,CNO__c,CreditCard__c,CustomerID__c,CustomerNum__c,DNI__c,EmailHash__c,Gender__c,Job__c,JobPosition__c,
        MailingCity,MailingCountry,MailingPostalCode,MailingState,MailingStreet,MasterPolicy__c,MasterPolicyDesc__c,MasterPolicyNum__c,MobilePhone,MonthExpiryDate__c,Nationality__c,YearExpiryDate__c,Abandoned_Lead__c
         from Contact where recordtype.developerName =: Label.LeadGI and IsSubscriber__c = true and HasOptedOutOfEmail = false ];

        System.assertEquals (null,leadsToUpdateAfter[0].Birthdate,'El valor del campo cumpleaños debe ser nulo');
    }

}