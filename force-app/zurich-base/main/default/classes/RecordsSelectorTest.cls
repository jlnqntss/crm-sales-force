@isTest
private class RecordsSelectorTest
{
    @TestSetup
    static void makeData()
    {
        List<Policy__c> policiesToInstert = new List<Policy__c>();

        for(Integer i = 0; i < 10; i++)
        {
            policiesToInstert.add
            (
                new Policy__c
                (
                    InfoPolicyNumber__c = 'Policy' + i
                )
            );
        }
        insert policiesToInstert;
    }

    /**
     * Test origen nulo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByExternalId_null()
    {
        Test.startTest();
        List<sObject> selectedsObjects = new RecordsSelector( Schema.getGlobalDescribe().get('Policy__c') ).selectByExternalId(null, null);
        Test.stopTest();

        System.assertEquals(true, selectedsObjects.isEmpty(), 'Se han obtenido registros erróneos');
    }

    /**
     * Test origen correcto
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByExternalId_ok()
    {
        Set<Object> externalIdValues = new Set<Object>();

        for(Integer i = 0; i < 10; i++)
        {
            externalIdValues.add('Policy' + i);
        }

        Test.startTest();
        List<sObject> selectedsObjects = new RecordsSelector
                                         (
            Schema.getGlobalDescribe().get('Policy__c'),
            new List<Schema.SObjectField> {Policy__c.Name}
                                         ).selectByExternalId(Policy__c.InfoPolicyNumber__c, externalIdValues);
        Test.stopTest();

        System.assertEquals(10, selectedsObjects.size(), 'No se han obtenido registros');
    }

    /**
     * Test origen correcto con límite de registros
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByExternalId_ok_limit()
    {
        Set<Object> externalIdValues = new Set<Object>();

        for(Integer i = 0; i < 10; i++)
        {
            externalIdValues.add('Policy' + i);
        }

        Test.startTest();
        List<sObject> selectedsObjects = new RecordsSelector
                                         (
            Schema.getGlobalDescribe().get('Policy__c'),
            new List<Schema.SObjectField> {Policy__c.Name}
                                         ).setLimit(1).selectByExternalId(Policy__c.InfoPolicyNumber__c, externalIdValues);
        Test.stopTest();

        System.assertEquals(1, selectedsObjects.size(), 'No se han obtenido registros');
    }

}