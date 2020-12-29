@isTest
private class OpportunityUtilTest
{
    @TestSetup
    static void makeData()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'BusinessCustomer', 10);
        insert accounts;
    }

    /**
     * Test que comprueba la generación del ámbito correspondiente para cada oferta
     *
     * @author adelgado
     * @date 09/12/2020
     */
    @isTest
    static void test_generateScope()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 2);

        for(Integer i = 0; i < optys.size(); i++)
        {
            optys[i].InfoQuoteNumber__c = String.valueOf(i);
        }

        Test.startTest();
        insert optys;
        Test.stopTest();

        List<Scope__c> scopes = [SELECT Id, Name FROM Scope__c WHERE AccountId__c IN : accounts];
        List<Opportunity> optysUpdated = [SELECT Scope__c, ScopeId__c FROM Opportunity];

        // FIXME: System.assertEquals(10, scopes.size(), 'No se han generado todos los ámbitos necesarios');

        for(Opportunity opty : optysUpdated)
        {
            // FIXME: System.assert (String.isNotBlank(opty.Scope__c), 'No se ha informado la picklist de scope');
            // FIXME: System.assert (opty.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }
}
