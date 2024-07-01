/**
 * Clase de test para la clase Job_WorkRouter
 * @author aberuete
 * @date 01/07/2024
 */
@isTest
private with sharing class Job_WorkRouterTest 
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
     * Test del método que comprueba que la clase programable calcula y actualiza la asignación de los casos sin gestor preferente.
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_UpdateCasesToAssignOwner()
    {
        Test.startTest();
        new Job_WorkRouter().execute(null);
        Test.stopTest();

        List<User> userAgentActiveAfterUpdate = [Select id from User where Lastname = 'Integrator work router'];
        List<Case> casesWithoutBestAgent = [Select id,OwnerId from Case where WithoutBestAgent__c = true];
        Assert.isTrue (casesWithoutBestAgent.size() == 1, 'El número de casos sin gestor preferente es incorrecto');
        Assert.isTrue (casesWithoutBestAgent[0].OwnerId != userAgentActiveAfterUpdate[0].id, 'El caso debería haber actualizado de owner');
    }
}