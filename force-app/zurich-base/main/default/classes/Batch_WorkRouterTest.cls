/**
 * Clase de test para la clase Batch_WorkRouter
 * @author aberuete
 * @date 01/07/2024
 */
@isTest
private with sharing class Batch_WorkRouterTest 
{
    static final string PROFILE_INTEGRATOR = 'Integrator';
    static final string PROFILE_USP_USER = 'USP User';

    @TestSetup
    private static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 1);
        insert accounts;

        List<Profile> profileIntegrator= [SELECT Id FROM Profile WHERE Name =: PROFILE_INTEGRATOR];
        List<User> userIntegrator= TestDataFactory.generateUsersByProfile(profileIntegrator[0].Id, 1);
        userIntegrator[0].Lastname = 'Integrator work router';
        insert userIntegrator;

        List<Profile> profileUsp= [SELECT Id FROM Profile WHERE Name =: PROFILE_USP_USER];
        List<User> userUsp = TestDataFactory.generateUsersByProfile(profileUsp[0].Id, 1);
        userUsp[0].Lastname = 'Work router';
        userUsp[0].ActiveAgent__c = true;
        userUsp[0].Capacity__c = 10;
        userUsp[0].AssignedCases__c = 0;
        insert userUsp;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 1);
        cases[0].WithoutBestAgent__c = true;
        cases[0].OwnerId = userIntegrator[0].id;
        insert cases;
    }

    /**
     * Test del método que comprueba que el batch calcula y actualiza la asignación de los casos sin gestor preferente.
     * La llamada de este método se hace sin utilizar una query.
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_UpdateCasesToAssignOwnerWithoutQuery()
    {
        Test.startTest();
        database.executeBatch(new Batch_WorkRouter(), 200);
        Test.stopTest();

        List<User> userAgentActiveAfterUpdate = [Select id from User where Lastname = 'Integrator work router'];
        List<Case> casesWithoutBestAgent = [Select id,OwnerId from Case where WithoutBestAgent__c = true];
        Assert.isTrue (casesWithoutBestAgent.size()==1, 'El número de casos sin gestor preferente es incorrecto');
        Assert.isTrue (casesWithoutBestAgent[0].OwnerId != userAgentActiveAfterUpdate[0].id, 'El caso debería haber actualizado de owner');
    }

    /**
     * Test del método que comprueba que el batch calcula y actualiza la asignación de los casos sin gestor preferente.
     * La llamada de este método se hace utilizando una query.
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_UpdateCasesToAssignOwnerWithQuery()
    {
        Test.startTest();
        database.executeBatch(new Batch_WorkRouter(new CasesSelector().getCasesWithoutBestAgent()), 200);
        Test.stopTest();

        List<User> userAgentActiveAfterUpdate = [Select id from User where Lastname = 'Integrator work router'];
        List<Case> casesWithoutBestAgent = [Select id,OwnerId from Case where WithoutBestAgent__c = true];
        Assert.isTrue (casesWithoutBestAgent.size()==1, 'El número de casos sin gestor preferente es incorrecto');
        Assert.isTrue (casesWithoutBestAgent[0].OwnerId != userAgentActiveAfterUpdate[0].id, 'El caso debería de haber actualizado de owner');
    }
}