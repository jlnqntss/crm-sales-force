@isTest
private without sharing class OrdersSelectorTest {

    @TestSetup
    public static void createScenario()
    {
        Account newMaster = new Account(Name = 'test', CustomerNum__c = '3123');
        insert newMaster;

        Contact customer = new Contact(
            Email = 'edu@test.com',
            MobilePhone = '675887723',
            DNI__c = '05289654W',
            Birthdate = Date.valueOf('1990-01-01'),
            FirstName = 'Edu',
            LastName = 'Sanchez',
            CustomerNum__c = 'GI-3123',
            LegalEntity__c = Label.GeneralInsurance,
            RecordTypeId = SystemUtil.getContactRecordTypeIdByName(Label.CustomerGI),
            AccountId = newMaster.Id
            );
        insert customer;

        //Generar 10 orders para que las querys devuelvan un listado
        List<Order> orders = TestDataFactory.generateOrdersKlinc(newMaster.Id, customer.Id, customer.CustomerNum__c, Label.PolicyGI, 10);
        insert orders;
    }

    @IsTest
    static void test_selectByDNI_ok()
    {
        // Comprobaciones iniciales
        List<Order> orders = [SELECT Id FROM Order];
        System.assertEquals(false, orders.isEmpty(), 'Orders list should NOT be empty');

        Test.startTest();
        List<Order> matchedRecords = new OrdersSelector().selectByDNI('05289654W'); //El DNI es el del TestSetup
        Test.stopTest();

        //El tamaño de la lista depende de lo generado en el TestSetup
        System.assertEquals(10, matchedRecords.size(), 'List should NOT be empty');
    }

    @IsTest
    static void test_selectByDNI_ko()
    {
        // Comprobaciones iniciales
        List<Order> orders = [SELECT Id FROM Order];
        System.assertEquals(false, orders.isEmpty(), 'Orders list should NOT be empty');

        Test.startTest();
        OrdersSelector ordersSelector = new OrdersSelector();
        ordersSelector.setFields(new List<Schema.SobjectField>{Order.Id});
        List<Order> matchedRecords = ordersSelector.selectByDNI('noExisteEsteDNI'); //El DNI NO es el del TestSetup
        Test.stopTest();

        //El tamaño de la lista depende de lo generado en el TestSetup
        System.assertEquals(0, matchedRecords.size(), 'List should be empty');
    }

    @IsTest
    static void test_selectByEmail_ok()
    {
        // Comprobaciones iniciales
        List<Order> orders = [SELECT Id FROM Order];
        System.assertEquals(false, orders.isEmpty(), 'Orders list should NOT be empty');

        Test.startTest();
        List<Order> matchedRecords = new OrdersSelector().selectByEmail('edu@test.com'); //El Email es el del TestSetup
        Test.stopTest();

        //El tamaño de la lista depende de lo generado en el TestSetup
        System.assertEquals(10, matchedRecords.size(), 'List should NOT be empty');
    }

    @IsTest
    static void test_selectByEmail_ko()
    {
        // Comprobaciones iniciales
        List<Order> orders = [SELECT Id FROM Order];
        System.assertEquals(false, orders.isEmpty(), 'Orders list should NOT be empty');

        Test.startTest();
        OrdersSelector ordersSelector = new OrdersSelector();
        ordersSelector.setFields(new List<Schema.SobjectField>{Order.Id});
        List<Order> matchedRecords = ordersSelector.selectByEmail('no@existe.com'); //El Email NO es el del TestSetup
        Test.stopTest();

        //El tamaño de la lista depende de lo generado en el TestSetup
        System.assertEquals(0, matchedRecords.size(), 'List should be empty');
    }

    @IsTest
    static void test_selectByMobilePhone_ok()
    {
        // Comprobaciones iniciales
        List<Order> orders = [SELECT Id FROM Order];
        System.assertEquals(false, orders.isEmpty(), 'Orders list should NOT be empty');

        Test.startTest();
        List<Order> matchedRecords = new OrdersSelector().selectByMobilePhone('675887723'); //El MobilePhone es el del TestSetup
        Test.stopTest();

        //El tamaño de la lista depende de lo generado en el TestSetup
        System.assertEquals(10, matchedRecords.size(), 'List should NOT be empty');
    }

    @IsTest
    static void test_selectByMobilePhone_ko()
    {
        // Comprobaciones iniciales
        List<Order> orders = [SELECT Id FROM Order];
        System.assertEquals(false, orders.isEmpty(), 'Orders list should NOT be empty');

        Test.startTest();
        OrdersSelector ordersSelector = new OrdersSelector();
        ordersSelector.setFields(new List<Schema.SobjectField>{Order.Id});
        List<Order> matchedRecords = ordersSelector.selectByMobilePhone('666778899'); //El MobilePhone NO es el del TestSetup
        Test.stopTest();

        //El tamaño de la lista depende de lo generado en el TestSetup
        System.assertEquals(0, matchedRecords.size(), 'List should be empty');
    }


}
