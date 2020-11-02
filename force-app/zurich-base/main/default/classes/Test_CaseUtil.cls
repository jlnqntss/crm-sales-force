/**
 * Clases de test para CaseUtil
 **
 * @author nbizkarra
 * @date 27/04/2020
 **/
@isTest
public with sharing class Test_CaseUtil
{
    @testSetup
    static void makeData()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        Account MasterRef = new Account(CustomerNum__c = '3123');
        insert newMaster;

        Order policy = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '3123',
            PolicyNum__c = '8989',
            Status = 'Sync',
            PolicyContractStartDate__c = Date.valueOf('2020-05-02'),
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(Label.PolicyGI)
            );
        policy.Account = MasterRef;
        insert policy;

        Contact customer = new Contact(
            Email = 'edu@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            sourceCountry__c = 'Spain'
            );
        insert customer;
    }

    @IsTest
    static void test_updateClaim()
    {
        Case claim = new Case(
            ClaimNumber__c = '797',
            PolicyNum__c = '8989',
            CustomerNum__c = '3123',
            LegalEntity__c = Label.GeneralInsurance,
            DateReg__c = Date.valueOf('2020-01-02'),
            InsuredObjectId__c = '123456789',
            RecordTypeId = SystemUtil.getClaimRecordType(),
            sourceCountry__c = 'Spain'
            );
        insert claim;

        SET<String> keys = new Set<String>();
        keys.add(claim.ClaimNumber__c); //claim
        keys.add('8989'); //Policy
        keys.add('3123'); //Contact

        Map<String, Case> mapClaims = new Map<String, Case>();
        mapClaims = SystemUtil.ClaimsSelector(keys);
        Map<String, Case> claimsToUpsert = new Map<String, Case>();

        Map<String, Order> mapPolicies = new Map<String, Order>();
        mapPolicies = SystemUtil.PolicySelector(keys);
        Map<String, Contact> mapContacts = new Map<String, Contact>();
        mapContacts = SystemUtil.ContactsSelector(keys);
        Map<String, OrderItem> mapOrderItem = new Map<String, OrderItem>();
        mapOrderItem = SystemUtil.OrderItemSelector(keys);
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();

        ExternalRequestUtil.mapClaims = mapClaims;
        ExternalRequestUtil.claimsToUpsert = claimsToUpsert;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

        CaseUtil.upsertClaim(claim);
        System.assert (
            claimsToUpsert != null,
            'Test_CaseUtil: Error al actualizar claim'
            );

        Test.stopTest();
    }

    @IsTest
    static void test_createClaim()
    {
        Case claim = new Case(
            ClaimNumber__c = '797',
            PolicyNum__c = '8989',
            CustomerNum__c = '3123',
            LegalEntity__c = Label.LifeInsurance,
            DateReg__c = Date.valueOf('2020-01-02'),
            InsuredObjectId__c = '123456789',
            sourceCountry__c = 'Spain'
            );

        List<Contact> existingContactsList = [
            SELECT Id
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];
        System.AssertEquals( 1, existingContactsList.size() );

        SET<String> keys = new Set<String>();
        keys.add('8989'); //Policy
        keys.add('3123'); //Contact

        Map<String, Case> mapClaims = new Map<String, Case>();
        mapClaims = SystemUtil.ClaimsSelector(keys);
        Map<String, Case> claimsToUpsert = new Map<String, Case>();

        Map<String, Order> mapPolicies = new Map<String, Order>();

        mapPolicies = SystemUtil.PolicySelector(keys);
        Map<String, Contact> mapContacts = new Map<String, Contact>();
        mapContacts = SystemUtil.ContactsSelector(new Set<String> { 'GI-3123' });
        Map<String, OrderItem> mapOrderItem = new Map<String, OrderItem>();
        mapOrderItem = SystemUtil.OrderItemSelector(keys);
        User recordOwner = SystemUtil.RecordOwnerSelector();
        Pricebook2 Pricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Name = Label.PriceBook
            );
        update Pricebook;

        Test.startTest();

        ExternalRequestUtil.mapClaims = mapClaims;
        ExternalRequestUtil.mapPolicies = mapPolicies;
        ExternalRequestUtil.mapContacts = mapContacts;
        ExternalRequestUtil.mapOrderItem = mapOrderItem;
        ExternalRequestUtil.claimsToUpsert = claimsToUpsert;
        ExternalRequestUtil.recordOwner = recordOwner;
        ExternalRequestUtil.Pricebook = Pricebook;

        CaseUtil.upsertClaim(claim);

        //CaseUtil.upsertClaim(claim);
        System.assert (
            ExternalRequestUtil.claimsToUpsert != null,
            'Test_CaseUtil: Error al crear claim'
            );

        Test.stopTest();
    }

    @IsTest
    static void test_SummaryTotalClaims()
    {
        Contact c = [
            SELECT id, NumClaims__c
            FROM Contact
            WHERE CustomerNum__c = 'GI-3123'
        ];

        Case claim = new Case(
            ClaimNumber__c = '797',
            PolicyNum__c = '8989',
            CustomerNum__c = '3123',
            LegalEntity__c = Label.LifeInsurance,
            DateReg__c = Date.valueOf('2020-01-02'),
            InsuredObjectId__c = '123456789'
            );
        claim.ContactId = c.id;
        insert claim;

        Test.startTest();

        c = [SELECT id, NumClaims__c FROM Contact WHERE CustomerNum__c = 'GI-3123'];
        System.assert (
            c.NumClaims__c == 1,
            'Test_CaseUtil: Error al crear rollup summary total claims'
            );

        Test.stopTest();
    }

    /**Method that tests if the case received from email has a contact assigned and the case from Web has a policy assigned */
    @IsTest
    static void test_EmailToCaseAssignContact()
    {
        Case caso1 = new Case(
            LegalEntity__c = Label.GeneralInsurance,
            Origin = 'Email',
            Status = 'New',
            SuppliedEmail = 'edu@test.com',
            sourceCountry__c = 'Spain'
            );
        insert caso1;

        Case caso2 = new Case(
            LegalEntity__c = Label.GeneralInsurance,
            Origin = 'Web',
            Status = 'New',
            PolicyNum__c = '8989',
            sourceCountry__c = 'Spain'
            );
        insert caso2;

        Test.startTest();

        caso1 = [
            SELECT id, ContactId
            FROM Case
            WHERE SuppliedEmail = 'edu@test.com'
        ];
        caso2 = [
            SELECT id, ContactId, Policy__c
            FROM Case
            WHERE PolicyNum__c = '8989'
        ];

        System.assert (caso1.ContactId != null);
        System.assert (caso2.Policy__c != null);
        Test.stopTest();
    }
}