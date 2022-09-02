@IsTest
public with sharing class RiskAppetiteControllerTest {
    
    @IsTest
    static void test_getAvailableSICs()
    {
        MaestroApetito__c maestro1 = new MaestroApetito__c();
        maestro1.SIC__c = '1100';
        insert maestro1;
        MaestroApetito__c maestro2 = new MaestroApetito__c();
        maestro2.SIC__c = '1100';
        insert maestro2;

        test.startTest();
        List<String> labels = RiskAppetiteController.getAvailableSICs();
        test.stopTest();

        system.assertEquals(1, labels.size());
    }
}