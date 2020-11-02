@isTest
private class ExternalIdFieldsSelectorTest
{
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
        List<ExternalIdField__mdt> selectedMetadata = new ExternalIdFieldsSelector(new List<Schema.SObjectField> {ExternalIdField__mdt.Origin__c}).selectByOrigin(null);
        Test.stopTest();

        System.assertEquals(true, selectedMetadata.isEmpty(), 'Se han obtenido metadatos erróneos');
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
        List<ExternalIdField__mdt> selectedMetadata = new ExternalIdFieldsSelector(new List<Schema.SObjectField> {ExternalIdField__mdt.Origin__c}).selectByOrigin(new Set<String> {'INFO'});
        Test.stopTest();

        System.assertEquals(false, selectedMetadata.isEmpty(), 'No se han obtenido metadatos');
    }
}