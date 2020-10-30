@isTest
private class AsyncApexJobsSelectorTest
{
    /**
     * Test id clase nulo
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByClassName_null()
    {
        Test.startTest();
        List<AsyncApexJob> selectedMetadata = new AsyncApexJobsSelector(new List<Schema.SObjectField> {AsyncApexJob.Id}).selectByClassName(null);
        Test.stopTest();

        System.assertEquals(true, selectedMetadata.isEmpty(), 'Se han obtenido trabajos de apex erróneos');
    }

    /**
     * Test id clase correcto
     *
     * @author adelgado
     * @date 29/10/2020
     */
    @isTest
    static void test_selectByClassName_ok()
    {
        Test.startTest();
        List<AsyncApexJob> selectedMetadata = new AsyncApexJobsSelector(new List<Schema.SObjectField> {AsyncApexJob.Id}).selectByClassName(new Set<String> {'ExternalJobQueueBatch'});
        Test.stopTest();

        System.assertEquals(true, selectedMetadata.isEmpty(), 'Se han obtenido trabajos de apex erróneos');
    }
}