@isTest
private class AssetUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        for(Policy__c p: policies) {
            p.Scope__c = 'ZE';
        }
        insert policies;
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada siniestro (Asset)
     *
     * @author nts (agonzalezisasi)
     * @date 18/02/2021
     */
    @isTest
    static void test_generateScope()
    {
        // Recuperamos las polizas
        List<Policy__c> policies = [SELECT Id, Scope__c FROM Policy__c WHERE Scope__c != null];
        System.assertEquals(10, policies.size(), 'Deberia haber 10 polizas con scope');

        // Preparamos los siniestros (Asset) sin indicar el scope
        List<Asset> assets = new List<Asset>();
        for( Integer i=0,j=policies.size();i<j;i++ ) {
            assets.add(new Asset(
                Name= String.valueOf(i + 1).leftPad(9, '0'),
                PolicyId__c= policies[i].Id,
                Scope__c= null
            ));
        }
        
        Test.startTest();
        insert assets;
        Test.stopTest();

        List<Asset> assetsUpdated = [SELECT Scope__c FROM Asset WHERE Scope__c != null];
        System.assertEquals(10, assetsUpdated.size(), 'No se han generado todas los Assets con el Ambito correctamente');

        //Para cobertura beforeDelete/afterDelete
        delete assets;
    }
}
