/**
 * Clases de test para AccountUtil
 **
 * @author nbizkarra
 * @date 26/04/2020
 */
@isTest(SeeAllData = false)
public class Test_AccountUtil
{
    @testSetup
    static void makeData()
    {}

    @IsTest
    static void test_associatePartner()
    {
        Contact customer = new Contact(
            DNI__c = '443485723A',
            Email = 'edu@test.com',
            MobilePhone = '456456456',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = '3123',
            LegalEntity__c = 'GI',
            MasterPolicyNum__c = '3344',
            MasterPolicyDesc__c = 'Nestle'
            );

        Map<String, Account> mapPartners = new Map<String, Account>();
        SET<String> keys = new Set<String>();

        mapPartners = SystemUtil.PartnerSelector(keys);

        Account newPartner = new Account(
            Name = customer.MasterPolicyDesc__c,
            Masterpolicy__c = customer.MasterPolicyNum__c,
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName('Partner')
            );
        insert (newPartner);

        Map<String, Account> mapPartnersWithPartner = new Map<String, Account>();
        keys.add(newPartner.Masterpolicy__c);
        mapPartnersWithPartner = SystemUtil.PartnerSelector(keys);

        Map<String, Contact> contactsToUpdateWithPartner = new Map<String, Contact>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();

        Test.startTest();
        //Partner no existe
        AccountUtil.associatePartner(
            customer,
            mapPartners,
            contactsToUpdateWithPartner,
            partnersToUpdateList,
            recordOwner
            );
        System.assert (
            !partnersToUpdateList.isEmpty(),
            'AssociatePartner: El partner no ha sido creado'
            );
        //Partner existe
        AccountUtil.associatePartner(
            customer,
            mapPartnersWithPartner,
            contactsToUpdateWithPartner,
            partnersToUpdateList,
            recordOwner
            );
        System.assert (
            !customer.MasterPolicy__c.equals(null),
            'AssociatePartner:El partner existente no ha sido asociado al cliente'
            );

        Test.stopTest();
    }

    @IsTest
    static void test_associatePartnerToOrder()
    {
        Order policy = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '3123',
            PolicyNum__c = '1111',
            PolicyContractSerial__c = '1111-6',
            UpdateReason__c = '',
            PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
            LegalEntity__c = 'GI',
            MasterPolicyNum__c = '3344',
            MasterPolicyDescr__c = 'Nestle'
            );

        Map<String, Account> mapPartners = new Map<String, Account>();
        SET<String> keys = new Set<String>();
        mapPartners = SystemUtil.PartnerSelector(keys);

        Account newPartner = new Account(
            Name = policy.MasterPolicyDescr__c,
            Masterpolicy__c = policy.MasterPolicyNum__c,
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName('Partner')
            );
        insert (newPartner);

        Map<String, Account> mapPartnersWithPartner = new Map<String, Account>();
        keys.add(newPartner.Masterpolicy__c);
        mapPartnersWithPartner = SystemUtil.PartnerSelector(keys);

        Map<String, Order> ordersToUpdateWithPartner = new Map<String, Order>();
        Map<String, Account> partnersToUpdateList = new Map<String, Account>();
        User recordOwner = SystemUtil.RecordOwnerSelector();

        Test.startTest();
        //Partner no existe
        AccountUtil.associatePartnerToOrder(
            policy,
            mapPartners,
            ordersToUpdateWithPartner,
            partnersToUpdateList,
            recordOwner
            );
        System.assert (
            !partnersToUpdateList.isEmpty(),
            'associatePartnerToOrder: El partner no ha sido creado'
            );
        //Partner existe
        AccountUtil.associatePartnerToOrder(
            policy,
            mapPartnersWithPartner,
            ordersToUpdateWithPartner,
            partnersToUpdateList,
            recordOwner
            );
        System.assert (
            !policy.MasterPolicy__c.equals(null),
            'associatePartnerToOrder: El partner existente no ha sido asociado a la poliza'
            );

        Test.stopTest();
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cuenta de INFO
     *
     * @author adelgado
     * @date 09/12/2020
     */
    @isTest
    static void test_generateScope()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 20);

        for(Integer i = 0; i < accounts.size(); i++)
        {
            accounts[i].INFOCustomerNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert accounts;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];

        System.assertEquals(20, scopes.size(), 'No se han generado todos los ámbitos necesarios');

    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cuentas cargadas desde CSV
     * @date 30/7/2021
     */
    @isTest
    static void test_generateScope_Telemarketing()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Lead', 20);

        for(Integer i = 0; i < accounts.size(); i++)
        {
            accounts[i].LeadBusinessCode__c = '3200012491'; //Scope Setting
            accounts[i].LeadSource__c = 'Telemarketing';
        }

        Test.startTest();
        insert accounts;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];

        System.assertEquals(20, scopes.size(), 'No se han generado todos los ámbitos necesarios');
    }
}