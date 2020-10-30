@isTest
private class ExternalRequestsSelectorTest
{
    @TestSetup
    static void makeData()
    {
        List<ExternalRequest__c> externalRequestList = TestDataFactory.generateExternalRequest('INFO', 'NATURAL_ACCOUNT', 10);
        insert externalRequestList;
    }

    /**
     * Test origen nulo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByOrigin_null()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectByOrigin(null);
        Test.stopTest();

        System.assertEquals(true, selectedExtReq.isEmpty(), 'Se han obtenido external request erróneas');
    }

    /**
     * Test origen correcto
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByOrigin_ok()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).selectByOrigin(new Set<String> {'INFO'});
        Test.stopTest();

        System.assertEquals(10, selectedExtReq.size(), 'No se han obtenido external request');
    }

    /**
     * Test origen correcto con límite  de registros
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByOrigin_ok_limit()
    {
        Test.startTest();
        List<ExternalRequest__c> selectedExtReq = new ExternalRequestsSelector(new List<Schema.SObjectField> {ExternalRequest__c.Origin__c}).setLimit(1).selectByOrigin(new Set<String> {'INFO'});
        Test.stopTest();

        System.assertEquals(1, selectedExtReq.size(), 'No se han obtenido external request');
    }
}