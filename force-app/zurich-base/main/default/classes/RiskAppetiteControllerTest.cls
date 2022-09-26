@IsTest
public with sharing class RiskAppetiteControllerTest {

    @TestSetup
    static void makeData()
    {
        String SicCode = '1100';
        MaestroApetito__c maestro1 = new MaestroApetito__c();
        maestro1.SIC__c = SicCode;
        maestro1.CodigoProducto__c = '0001';
        maestro1.CodigoActividad__c = '0010';
        maestro1.ApetitoRiesgo__c = 'Preferente';
        insert maestro1;
        MaestroApetito__c maestro2 = new MaestroApetito__c();
        maestro2.SIC__c = SicCode;
        maestro2.CodigoProducto__c = '0002';
        maestro2.CodigoActividad__c = '0020';
        maestro2.ApetitoRiesgo__c = 'No preferente';
        insert maestro2;

        MaestroApetito__c maestro3 = new MaestroApetito__c();
        maestro3.SIC__c = SicCode;
        maestro3.CodigoProducto__c = '0001';
        maestro3.CodigoActividad__c = '0020';
        maestro3.ApetitoRiesgo__c = 'Fuera de apetito';
        insert maestro3;
    }
    
    @IsTest
    static void test_getAvailableSICs_OK()
    {
        test.startTest();
        List<String> labels = RiskAppetiteController.getAvailableSICs();
        test.stopTest();

        system.assertEquals(1, labels.size());
    }

    @IsTest
    static void test_getProductsForSIC_OK()
    {
        test.startTest();
        List<RiskAppetiteController.Product> products = RiskAppetiteController.getProductsForSIC('1100');
        test.stopTest();

        system.assertEquals(2, products.size());
    }

    @IsTest
    static void test_getCommercialActivitiesForProducts_OK()
    {
        test.startTest();
        List<RiskAppetiteController.CommercialActivity> activities = RiskAppetiteController.getCommercialActivitiesForProducts('1100', '0001');
        test.stopTest();

        system.assertEquals(2, activities.size());
    }

    @IsTest
    static void test_getTechPoliciesForActivities_OK()
    {
        test.startTest();
        List<MaestroApetito__c> masters = RiskAppetiteController.getTechPoliciesForActivities('1100', '0001', '0020');
        test.stopTest();

        system.assertEquals(1, masters.size());
    }

    @IsTest
    static void test_getFields_OK()
    {
        String productCode = '00516';
        String fieldSet = 'ramo' + productCode;
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get('MaestroApetito__c');
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSet);
        List<Schema.FieldSetMember> fieldList = fieldSetObj.getFields(); 

        test.startTest();
        List<RiskAppetiteController.Field> fields = RiskAppetiteController.getFields(productCode);
        test.stopTest();

        system.assertEquals(fieldList.size(), fields.size());
    }

    @IsTest
    static void test_getOtherProducts_OK()
    {
        List<OtherProduct__mdt> originalProducts = OtherProduct__mdt.getAll().values();

        test.startTest();
        List<OtherProduct__mdt> products = RiskAppetiteController.getOtherProducts();
        test.stopTest();

        system.assertEquals(originalProducts.size(), products.size());
    }
}