@IsTest
public with sharing class RiskAppetiteMasterSelectorTest {
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
    static void test_findAllMasters_OK()
    {
        
        test.startTest();
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findAllMasters();
        test.stopTest();

        system.assertEquals(3, records.size());
    }

    @IsTest
    static void test_findProductsBySicCode_OK()
    {
        
        test.startTest();
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findProductsBySicCode('1100');
        test.stopTest();

        system.assertEquals(3, records.size());
    }

    @IsTest
    static void test_findCommercialActivitiesByProductCode_OK()
    {
        
        test.startTest();
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findCommercialActivitiesByProductCode('1100', '0001');
        test.stopTest();

        system.assertEquals(2, records.size());
    }

    @IsTest
    static void test_findTechPolicyByCommercialActivity_OK()
    {
        
        test.startTest();
        List<MaestroApetito__c> records = new RiskAppetiteMasterSelector().findTechPolicyByCommercialActivity('1100', '0001', '0020');
        test.stopTest();

        system.assertEquals(1, records.size());
    }
}
