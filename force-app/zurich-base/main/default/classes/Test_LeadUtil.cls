/**
 * Clases de test para LeadUtil
 **
 * @author nbizkarra
 * @date 17/11/2020
 **/
@isTest
public class Test_LeadUtil
{
    @testSetup
    static void makeData()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        insert newMaster;

        Contact customerGI = new Contact(
            Email = 'testexisting@test.com',
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
            Email = 'testexisting@test.com',
            LastName = 'Test',
            CustomerNum__c = 'Life-3123',
            LegalEntity__c = Label.LifeInsurance,
            Status__c = 'Activo',
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerLife),
            SourceCountry__c = 'Spain',
            AccountId = newMaster.Id
            );

        insert customerLife;
    }


    /**
     * @description This method creates a new subscriber whose email doesn't exist in SF
     * @author nbizkarra
     * @date 17/11/2020
     **/
    @isTest
    static void test_NewSubscriber()
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
    static void test_ExistingSubscriber()
    {

        List<Lead> subscribers = new List<Lead>();

        Lead subscriber = new Lead (
            Email = 'testexisting@test.com',
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
        System.assertEquals('testexisting@test.com', c.get(0).Email);
        System.assertEquals( 2, LeadUtil.contactsToUpdate.size() );

        Test.stopTest();
    }

    /**
     * @description This method creates a new subscriber and relates to the existing account
     * @author nbizkarra
     * @date 17/11/2020
     **/
    @isTest
    static void test_ExistingMaster1()
    {

        List<Lead> subscribers = new List<Lead>();

        Lead subscriber = new Lead (
            Email = 'testexisting@test.com',
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
    static void test_ExistingMaster2()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '1111');
        insert newMaster;

        Contact customerGI = new Contact(
            Email = 'testexisting@test.com',
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
            Email = 'testexisting@test.com',
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
        customerNum.add('Life-3123');
        Map<String, Contact> mapContact = SystemUtil.contactsSelector(customerNum);
        Contact contact = mapContact.get('Life-3123');

        System.assertEquals(contact.AccountId, LeadUtil.contactsToCreate.get(0).AccountId);
        System.assertEquals(contact.AccountId, LeadUtil.contactsToCreate.get(1).AccountId);

        Test.stopTest();
    }
}