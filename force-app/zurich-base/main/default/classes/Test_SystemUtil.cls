/**
 * Clases de test para SystemUtil
 **
 * @author nts
 * @date 24/02/2020
 */
@isTest(SeeAllData=false)
public class Test_SystemUtil
{
    @testSetup
    static void makeData()
    {
        // Instantiate the Pricebook2 record first, setting the Id
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
            );

        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        update standardPricebook;

        // Create the Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
            ProductID__c = 'Test Product'
            );
        insert testProduct;

        // Create the PricebookEntry
        PricebookEntry testPbe = new PricebookEntry(
            Pricebook2Id = standardPricebook.Id,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
            );

        insert testPbe;

        Account master = new Account(CustomerNum__c = '4747', Name = 'Test');
        insert (master);

        Account masterRef = new Account(CustomerNum__c = '4747');

        Contact customer = new Contact(
            DNI__c = '44348579Ñ',
            Email = 'andrea11@test.com',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'test',
            LastName = 'Gomez',
            CustomerNum__c = '454545',
            LegalEntity__c = Label.GeneralInsurance
            );
        customer.Account = masterRef;
        insert (customer);

        Contact contactRef = new Contact(CustomerNum__c = '454545');

        Order quote = new Order(
            EffectiveDate = Date.valueOf('1994-01-01'),
            CustomerNum__c = '4747',
            LegalEntity__c = Label.LifeInsurance,
            QuoteEntry__c = '333333',
            Status = 'Sync'
            );

        String legalEntityName;
        if ( quote.LegalEntity__c.equals(Label.GeneralInsurance) )
        {
            legalEntityName = 'GI';
        }
        else
        {
            legalEntityName = 'Life';
        }
        quote.RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(
            'Quote' + legalEntityName
            );
        quote.Pricebook2Id = standardPricebook.Id;
        quote.Account = masterRef;
        quote.ContactId__r = contactRef;
        insert (quote);


        Order quoteRef = new Order(QuoteEntry__c = '333333');

        OrderItem oi = new OrderItem(
            ItemAge__c = 2,
            itemId__c = '111111',
            UnitPrice = 0,
            Quantity = 1
            );
        oi.Order = quoteRef;
        oi.PricebookEntryId = testPbe.Id;

        insert (oi);

    }

    @IsTest
    static void test_getSettings()
    {
        Test.startTest();
        ErrorManagementSetting__mdt setupErrors = SystemUtil.getErrorLogSettingsMetadata();
        System.assert (
            setupErrors != null,
            'Test_SystemUtil: No se ha recuperado correctamente ErrorManagementSetting__mdt para ErrorLogUtil'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_maskEmail()
    {
        String emailToMask = 'test@example.com';
        String code = '00001';
        Test.startTest();
        String maskedEmail = SystemUtil.maskEmail(emailToMask, code);
        System.assertEquals(
            'test@00001-mng.dev',
            maskedEmail,
            'No se ha enmascarado correctamente el email'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_isValidDate()
    {
        Test.startTest();
        String validDate = '2012-01-12';
        System.assert (
            SystemUtil.isValidDate(validDate),
            'No ha detectado correctamente una fecha válida'
            );
        String invalidDate = '23-13-1999';
        System.assert (
            !SystemUtil.isValidDate(invalidDate),
            'No ha detectado correctamente una fecha invalida'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getExternalRequest()
    {
        Test.startTest();
        System.assert (
            String.isNotBlank( Systemutil.getExternalRequests() ),
            'No se ha podido recuperar la query de external request'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getProcessedExternalRequests()
    {
        Test.startTest();
        System.assert (
            String.isNotBlank( Systemutil.getProcessedExternalRequests() ),
            'No se ha podido recuperar la query de processed external request'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getOldExternalRequests()
    {
        Test.startTest();
        System.assert (
            String.isNotBlank( Systemutil.getOldExternalRequests() ),
            'No se ha podido recuperar la query de old external request'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getErrorLogs()
    {
        Test.startTest();
        System.assert (
            String.isNotBlank( Systemutil.getErrorLogs() ),
            'No se ha podido recuperar la query de error logs'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getQuotesToDelete()
    {
        Test.startTest();
        System.assert (
            String.isNotBlank( Systemutil.getQuotesToDelete() ),
            'No se ha podido recuperar la query de quotes para borrar'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getLeadsToDelete()
    {
        Test.startTest();
        System.assert (
            String.isNotBlank( Systemutil.getLeadsToDelete() ),
            'No se ha podido recuperar la query de leads para borrar'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getMastersToDelete()
    {
        Test.startTest();
        System.assert (
            String.isNotBlank( Systemutil.getMastersToDelete() ),
            'No se ha podido recuperar la query de masters para borrar'
            );
        Test.stopTest();
    }
    @IsTest
    static void test_getContactRecordTypeIdByName()
    {
        Test.startTest();
        String id = SystemUtil.getContactRecordTypeIdByName(Label.CustomerLife);

        System.assert (
            String.isNotBlank(id),
            'No se ha podido recuperar el record type id de contacto'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getAccountRecordTypeIdByName()
    {
        Test.startTest();
        String id = SystemUtil.getAccountRecordTypeIdByName(Label.Master);

        System.assert (
            String.isNotBlank(id),
            'No se ha podido recuperar el record type id de cuenta'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getOrderRecordTypeIdByName()
    {
        Test.startTest();
        String id = SystemUtil.getOrderRecordTypeIdByName(Label.QuoteGI);

        System.assert (
            String.isNotBlank(id),
            'No se ha podido recuperar el record type id de order'
            );
        Test.stopTest();
    }

    static void test_getClaimRecordTypeIdByName()
    {
        Test.startTest();
        String id = SystemUtil.getClaimRecordType();

        System.assert (
            String.isNotBlank(id),
            'No se ha podido recuperar el record type id de claim'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_PartnerSelector()
    {
        Account partner = new Account(
            Name = 'test',
            Masterpolicy__c = '121',
            RecordTypeId = SystemUtil.getAccountRecordTypeIdByName(Label.Partner)
            );
        insert (partner);
        Map<String, Account> mapa = new Map<String, Account>();

        SET<String> keys = new Set<String>();
        keys.add(partner.Masterpolicy__c);

        Test.startTest();
        mapa = SystemUtil.PartnerSelector(keys);
        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los partners'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_ContactsSelector()
    {
        Map<String, Contact> mapa = new Map<String, Contact>();
        SET<String> keys = new Set<String>();
        keys.add('454545');

        Test.startTest();
        mapa = SystemUtil.ContactsSelector(keys);

        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los contactos'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_ContactsSelectorEmail()
    {
        Map<String, List<Contact> > mapa = new Map<String, List<Contact> >();
        SET<String> keys = new Set<String>();
        keys.add('andrea11@test.com');

        Test.startTest();
        mapa = SystemUtil.contactsSelectorEmail(keys);

        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los contactos'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_contactsSelectorSubscribers()
    {
        Contact subscriber = new Contact (
            Email = 'testexisting@test.com',
            LastName = 'Test',
            IsSubscriber__c  = true
            );

        insert subscriber;

        Map<String, List<Contact> > mapa = new Map<String, List<Contact> >();
        SET<String> keys = new Set<String>();
        keys.add('testexisting@test.com');

        SET<String> mobiles = new Set<String>();

        Test.startTest();
        SystemUtil.contactsSelectorMatchCode(keys, mobiles, null, null, null, mapa);
        // mapa = SystemUtil.contactsSelectorSubscribers(keys);

        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los contactos'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getQuoteSameProduct()
    {

        Map<String, List<Order> > mapa = new Map<String, List<Order> >();
        SET<String> customerNum = new Set<String>();
        customerNum.add('454545');
        SET<String> products = new Set<String>();
        products.add('Test Product');

        Test.startTest();
        mapa = SystemUtil.getQuoteSameProduct( customerNum,  products);

        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar las quotes'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getSubscribers()
    {
        Test.startTest();
        System.assert (
            String.isNotBlank( Systemutil.getSubscribers() ),
            'No se ha podido recuperar la query de error logs'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_ContactsSelectorEmailBirthDate()
    {
        Map<String, Contact> mapa1 = new Map<String, Contact>();
        Map<String, Contact> mapa2 = new Map<String, Contact>();
        Map<String, Contact> mapa3 = new Map<String, Contact>();

        SET<String> keys = new Set<String>();
        keys.add('andrea11@test.com');

        SET<String> mobiles = new Set<String>();

        Test.startTest();
        SystemUtil.contactsSelectorMatchCode(keys, mobiles, mapa1, mapa2, mapa3, null);

        System.assert (
            !mapa1.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los contactos con email y fecha de nacimiento'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_PolicySelector()
    {
        Account master = new Account(CustomerNum__c = '454545', Name = 'Test');
        insert (master);
        Account masterRef = new Account(CustomerNum__c = '454545');
        Order policy = new Order(
            EffectiveDate = Date.valueOf('1990-01-02'),
            CustomerNum__c = '454545',
            PolicyNum__c = '1010',
            PolicyContractSerial__c = '1010-5',
            PolicyContractStartDate__c = Date.valueOf('1990-02-02'),
            LegalEntity__c = Label.GeneralInsurance,
            QuoteEntry__c = '',
            MasterPolicyNum__c = '22',
            MasterPolicyDescr__c = 'Rastreator2',
            Status = 'Sync'
            );
        policy.Account = masterRef;
        String legalEntityName;
        if ( policy.LegalEntity__c.equals(Label.GeneralInsurance) )
        {
            legalEntityName = 'GI';
        }
        else
        {
            legalEntityName = 'Life';
        }
        policy.RecordTypeId = SystemUtil.getOrderRecordTypeIdByName(
            'Policy' + legalEntityName
            );
        insert (policy);
        Map<String, Order> mapa = new Map<String, Order>();

        SET<String> keys = new Set<String>();
        keys.add(policy.PolicyNum__c);

        Test.startTest();
        mapa = SystemUtil.PolicySelector(keys);
        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar las polizas'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_QuoteSelector()
    {
        Map<String, Order> mapa = new Map<String, Order>();
        SET<String> keys = new Set<String>();
        keys.add('333333');

        Test.startTest();
        mapa = SystemUtil.QuoteSelector(keys);
        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los quotes'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_OrderItemSelector()
    {
        Order quoteRef = new Order(QuoteEntry__c = '333333');
        PricebookEntry testPbe = [
            SELECT Id, Pricebook2.IsStandard
            FROM PricebookEntry
        ];

        OrderItem oi = new OrderItem(
            ItemAge__c = 2,
            itemId__c = '646464',
            UnitPrice = 0,
            Quantity = 1
            );
        oi.Order = quoteRef;
        oi.PricebookEntryId = testPbe.Id;

        insert (oi);
        Map<String, OrderItem> mapa = new Map<String, OrderItem>();

        SET<String> keys = new Set<String>();
        keys.add(oi.itemId__c);
        Test.startTest();
        mapa = SystemUtil.OrderItemSelector(keys);
        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los order items'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_ProductsSelector()
    {
        Map<String, PricebookEntry> mapa = new Map<String, PricebookEntry>();
        SET<String> keys = new Set<String>();
        keys.add('Test Product');

        Test.startTest();
        mapa = SystemUtil.ProductsSelector(keys);
        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los productos'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_getStandardPricebook()
    {
        Pricebook2 pb = new Pricebook2();

        Test.startTest();
        pb = SystemUtil.getStandardPricebook();
        System.assert (
            pb != null,
            'Test_SystemUtil: No se han podido recuperar el standard pricebook'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_CoversSelector()
    {
        Map<String, Cover__c> mapa = new Map<String, Cover__c>();
        Cover__c cover = new Cover__c(
            CoverId__c = '1',
            ParentCoverId__c = null,
            Name = 'Robo',
            Description__c = 'Cobertura por robo',
            SumInsured__c = 1000,
            LegalEntity__c = Label.LifeInsurance
            );
        insert cover;

        SET<String> keys = new Set<String>();
        keys.add(cover.CoverId__c);

        Test.startTest();
        mapa = SystemUtil.CoversSelector(keys);
        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los covers'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_ClaimsSelector()
    {
        Case claim = new Case(
            ClaimNumber__c = '797',
            PolicyNum__c = '8989',
            CustomerNum__c = '3123',
            LegalEntity__c = Label.GeneralInsurance,
            DateReg__c = Date.valueOf('2020-01-02'),
            InsuredObjectId__c = '123456789',
            RecordTypeId = SystemUtil.getClaimRecordType()
            );
        insert claim;
        Map<String, Case> mapa = new Map<String, Case>();

        SET<String> keys = new Set<String>();
        keys.add(claim.ClaimNumber__c);

        Test.startTest();
        mapa = SystemUtil.ClaimsSelector(keys);
        System.assert (
            !mapa.isEmpty(),
            'Test_SystemUtil: No se han podido recuperar los siniestros'
            );
        Test.stopTest();
    }

    @IsTest
    static void test_createJSON()
    {
        String json;
        ID identifier = 'a085E00000ARPh3QAH';

        Test.startTest();
        json = SystemUtil.createJSON(
            identifier,
            'errorCode',
            'errorDescription',
            Datetime.now(),
            'Origin',
            'Country',
            'Entity',
            Datetime.now(),
            'Json'
            );
        System.assert (
            !String.isBlank(json),
            'Test_SystemUtil: No se han podido crear el json'
            );
        Test.stopTest();
    }
}