@isTest
private class ClaimUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;

        List<Policy__c> policies = TestDataFactory.generatePoliciesForEachAccount(accounts, 1);
        for(Policy__c p: policies) {
            p.Scope__c = 'Z';
        }
        insert policies;
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada siniestro (claim)
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

        // Preparamos los siniestros (claim) sin indicar el scope
        List<Claim__c> claims = new List<Claim__c>();
        for( Integer i=0,j=policies.size();i<j;i++ ) {
            claims.add(new Claim__c(
                Name= String.valueOf(i + 1).leftPad(9, '0'),
                Policy__c= policies[i].Id
            ));
        }
        
        Test.startTest();
        insert claims;
        Test.stopTest();

        List<Claim__c> claimsUpdated = [SELECT Scope__c FROM Claim__c WHERE Scope__c != null];
        System.assertEquals(10, claimsUpdated.size(), 'No se han generado todas los siniestros con el Ambito correctamente');

        //Para cobertura beforeDelete/afterDelete
        delete claims;
    }
}
