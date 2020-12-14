@isTest
private with sharing class ProductsSelectorTest
{
    @TestSetup
    public static void createScenario()
    {
        List<Product2> products = TestDataFactory.generateProducts(10);
        insert products;
    }

    @isTest
    static void test_selectByCommercialPCAndTechnicalPC_matchedRecords()
    {
        List<Product2> existingProducts = [SELECT Id, CommercialCode__c, TechnicalCode__c FROM Product2];
        System.assertEquals(false, existingProducts.isEmpty(), 'List should NOT be empty');

        Set<String> commercialCodes = new Set<String> {existingProducts.get(0).CommercialCode__c};
        Set<String> technicalCodes = new Set<String> {existingProducts.get(0).TechnicalCode__c};

        Test.startTest();
        List<Product2> matchedRecords = new ProductsSelector(
            new Set<String> {'Id', 'CommercialCode__c', 'TechnicalCode__c'}
            ).selectByCommercialPCAndTechnicalPC(commercialCodes, technicalCodes);
        Test.stopTest();

        System.assertEquals(false, matchedRecords.isEmpty(), 'List should NOT be empty');
        for (Product2 product: matchedRecords)
        {
            System.assertEquals(true, commercialCodes.contains(product.CommercialCode__c), 'Set should contain comercial code');
            System.assertEquals(true, technicalCodes.contains(product.TechnicalCode__c), 'Set should contain technical code');
        }
    }

    @isTest
    static void test_selectByCommercialPCAndTechnicalPC_emptySets_matchedRecords()
    {
        Set<String> commercialCodes = new Set<String>();
        Set<String> technicalCodes = new Set<String>();

        Test.startTest();
        List<Product2> matchedRecords = new ProductsSelector().selectByCommercialPCAndTechnicalPC(commercialCodes, technicalCodes);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByCommercialPCAndTechnicalPC_nullSets_matchedRecords()
    {
        Test.startTest();
        List<Product2> matchedRecords = new ProductsSelector().selectByCommercialPCAndTechnicalPC(null, null);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }

    @isTest
    static void test_selectByCommercialPCAndTechnicalPC_invalidFields_matchedRecords()
    {
        Set<String> commercialCodes = new Set<String>();
        Set<String> technicalCodes = new Set<String>();

        Test.startTest();
        List<Product2> matchedRecords = new ProductsSelector(new Set<String> {'invalidField'}).selectByCommercialPCAndTechnicalPC(commercialCodes, technicalCodes);
        Test.stopTest();

        System.assertEquals(true, matchedRecords.isEmpty(), 'List should be empty');
    }
}