/**
 * Clase de test para SendDocCUInfosSelector
 * 
 * @author mario.navarro@seidor.com
 * @date 28/05/2024
 */
@isTest
private class Test_SendDocCUInfosSelector {

    /**
     * Testea el metodo getQueryToDeleteObjectsByRetention
     * 
     * @author mario.navarro@seidor.com
     * @date 28/05/2024
     */
    @isTest
    static void test_getQueryToDeleteObjectsByRetention()
    {
        Integer retentionToApply = 15;
        Test.startTest();
        String query = new SendDocCUInfosSelector().getQueryToDeleteObjectsByRetention(retentionToApply);
        Test.stopTest();

        Assert.isTrue(query.containsIgnoreCase(retentionToApply.toString()));
        Assert.isTrue(query.containsIgnoreCase(SendDocCUInfo__c.fields.Id.getDescribe().getName()));
        Assert.isTrue(query.containsIgnoreCase(SendDocCUInfo__c.fields.CreatedDate.getDescribe().getName()));
    }
}