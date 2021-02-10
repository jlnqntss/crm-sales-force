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

        System.assertEquals(10, scopes.size(), 'No se han generado todos los ámbitos necesarios');

        for(Opportunity opty : optysUpdated)
        {
            System.assert (String.isNotBlank(opty.Scope__c), 'No se ha informado la picklist de scope');
            System.assert (opty.ScopeId__c != null, 'No se ha asignado el scope correspondiente');
        }
    }

    /**
     * Test que comprueba que no se modifica la etapa de la oferta cuando el usuario es Integrator
     *
     * @author adelgado
     * @date 26/01/2021
     */
    @isTest
    static void test_detectOpportunityStageChange_integratorUser()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 2);
        insert optys;

        for(Opportunity opty : optys)
        {
            opty.StageName = 'Test';
        }

        User integrator = [SELECT Id, ProfileId, Profile.Name FROM User WHERE Profile.Name = 'Integrator' LIMIT 1];

        Test.startTest();
        System.runAs(integrator) 
        {
            update optys;
        }
        Test.stopTest();

        List<Opportunity> optysUpdated = [SELECT StageName FROM Opportunity];

        for(Opportunity opty : optysUpdated)
        {
            System.assertEquals('New', opty.StageName, 'Se ha actualizado la etapa de la oferta y no deberia');
        }
    }

    /**
     * Test que comprueba que no se modifica la etapa de la oferta cuando el usuario no es Integrator
     *
     * @author adelgado
     * @date 26/01/2021
     */
    @isTest
    static void test_detectOpportunityStageChange_otherUser()
    {
        List<Account> accounts = [SELECT Name FROM Account];

        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 2);
        insert optys;

        for(Opportunity opty : optys)
        {
            opty.StageName = 'Test';
        }

        Test.startTest();
        update optys;
        Test.stopTest();

        List<Opportunity> optysUpdated = [SELECT StageName FROM Opportunity];

        for(Opportunity opty : optysUpdated)
        {
            System.assertEquals('Test', opty.StageName, 'No se actualizado la etapa de la oferta');
        }
    }

    /**
     * Test detection of the change of the AccountId of the offer
     * 
     * @author nts (agonzalezisasi)
     * @date 04/02/2021
     */
    @isTest
    static void test_detectOpportunityAccountChange_ok()
    {
        // Get 10 accounts
        List<Account> accounts = [SELECT Name FROM Account LIMIT 10];
        System.assertEquals(10, accounts.size(), 'There should be 10 accounts');
        // Get 10 offers
        List<Opportunity> optys = TestDataFactory.generateOpportunitiesForEachAccount(accounts, 'General', 'New', System.today().addDays(10), 1);
        insert optys;
        // Create new 10 accounts
        List<Account> accountsOther = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Customer', 10);
        insert accountsOther;
        // Change the offers AccountId to the new accounts
        for(Integer i=0,j=optys.size();i<j;i++) {
            optys[i].AccountId = accountsOther[i].Id;
        }

        // do the update 
        Test.startTest();
        update optys;
        Test.stopTest();

        // Check that the OldAccountId__c field is not null
        List<Opportunity> optysUpdated = [
            SELECT Id, OldAccountId__c FROM Opportunity WHERE Id IN :optys AND OldAccountId__c != null
        ];
        System.assertEquals(10, optysUpdated.size(), 'There should be 10 offers updated');
    }
}
