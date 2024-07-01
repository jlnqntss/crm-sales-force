/**
 * Clase de test para la lógica de la clase programada Job_WorkRouter y el batch Batch_WorkRouter
 * @author aberuete
 * @date 01/07/2024
 */
@isTest
private with sharing class WorkRouterTest 
{
    static final string PROFILE_USP_USER = 'USP User';
    static final string MESSAGE_NUMBER_OF_ASSIGNED_CASES_INCORRECT = 'El número de casos asignados del agente no es correcto';

    @TestSetup
    private static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 1);
        insert accounts;

        List<Profile> profileUsp= [SELECT Id FROM Profile WHERE Name =: PROFILE_USP_USER];
        List<User> userUsp = TestDataFactory.generateUsersByProfile(profileUsp[0].Id, 2);
        userUsp[0].Lastname = 'Work router';
        userUsp[1].Lastname = 'Work router 2';
        userUsp[0].ActiveAgent__c = true;
        userUsp[1].ActiveAgent__c = true;
        userUsp[0].Capacity__c = 10;
        insert userUsp;

        List<Case> cases = TestDataFactory.generateCasesForEachAccount(accounts, 5);
        cases[0].OwnerId = userUsp[0].Id;
        for (Case caseToCreate :cases)
        {
            caseToCreate.WithoutBestAgent__c = true;
        }
        insert cases;
    }

    /**
     * Test del método que calcula y actualiza el número de casos 
     * asignados para los usuarios que son gestores activos (ActiveAgent__c a true) 
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_updateNumberOfCaseByUserWithAssignedCases()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().getNumberOfAssignedCasesGroupById();

        Test.startTest();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        Test.stopTest();

        List<User> userAgentActiveAfterUpdate = [Select id,AssignedCases__c from User where Lastname = 'Work router'];
        Assert.areEqual(1,userAgentActiveAfterUpdate[0].AssignedCases__c, 'El número de casos asignados del agente tras la actualización no es correcto');
    }

    /**
     * Test del método que calcula y actualiza el número de casos asignados para los usuarios 
     * que son gestores activos (ActiveAgent__c a true) y no tienen casos asignados.Es decir, actualiza el número a 0.
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_updateNumberOfCaseByUserWithNoAssignedCases()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().getNumberOfAssignedCasesGroupById();

        Test.startTest();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        Test.stopTest();

        List<User> userAgentActiveAfterUpdate = [Select id,AssignedCases__c from User where Lastname = 'Work router 2'];
        Assert.areEqual(0,userAgentActiveAfterUpdate[0].AssignedCases__c, 'El número de casos asignados del agente tras la actualización no es correcto');
    }

    /**
     * Test del método que calcula el número de casos totales que pueden gestionar los usuarios 
     * si todos tienen una capacidad asignada
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_calculateSumOfCapacitiesLeft ()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().getNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        List<User> userAgentActiveAfterUpdate = [Select id,AssignedCases__c,Capacity__c from User where Lastname = 'Work router'];
        Assert.areEqual(1,userAgentActiveAfterUpdate[0].AssignedCases__c, MESSAGE_NUMBER_OF_ASSIGNED_CASES_INCORRECT);
        Assert.areEqual(10,userAgentActiveAfterUpdate[0].Capacity__c, 'La capacidad del agente no es correcta');

        Test.startTest();
        Integer capacityLeft = new WorkRouter().calculateSumOfCapacitiesLeft (userAgentActiveAfterUpdate);
        Test.stopTest();
        Assert.areEqual(9,capacityLeft, 'La capacidad restante del agente no es correcta');
    }

    /**
     * Test del método que calcula la distribución equitativa
     * de los casos sin gestor preferente (WithoutBestAgent__c sea verdadero)
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_calculateDistributionOfCases()
    {
        List<User> usersWithAgentActive = new List<User>();
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().getNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);

        User user0 = [Select id,AssignedCases__c,Capacity__c from User where Lastname = 'Work router'];
        Assert.areEqual(1,user0.AssignedCases__c, MESSAGE_NUMBER_OF_ASSIGNED_CASES_INCORRECT);   

        User user1 = [Select id,AssignedCases__c,Capacity__c from User where Lastname = 'Work router 2'];
        Assert.areEqual(0,user1.AssignedCases__c, MESSAGE_NUMBER_OF_ASSIGNED_CASES_INCORRECT);  

        usersWithAgentActive.add(user0);
        usersWithAgentActive.add(user1);

        List<Case> casesToAssignOwner = [Select id,OwnerId from case where WithoutBestAgent__c = true and owner.profile.name !=: PROFILE_USP_USER];
        Assert.areEqual(4, casesToAssignOwner.size(),'El número de casos a asignar no es correcto');
    
        Test.startTest();
        List<Case> casesToUpdate = new WorkRouter().calculateDistributionOfCases (casesToAssignOwner, true, 0, usersWithAgentActive );
        Test.stopTest();

        Map<Id,List<Case>> mapOwnerByCases = new Map<Id,List<Case>>();

        for (Case caseToUpdate: casesToUpdate)
        {
            if (mapOwnerByCases.containsKey(caseToUpdate.OwnerId))
            {
                mapOwnerByCases.get(caseToUpdate.OwnerId).add(caseToUpdate);
            }
            else
            {
                mapOwnerByCases.put(caseToUpdate.OwnerId,new List<Case>{caseToUpdate});  
            }
        }

        Assert.areEqual(2,mapOwnerByCases.get(user0.id).size(), 'El número de casos asignados del agente 0 no es correcto');   
        Assert.areEqual(2,mapOwnerByCases.get(user1.id).size(), 'El número de casos asignados del agente 1 no es correcto');  
    }

    /**
     * Test del método que comprueba la actualización de los casos
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_updateCases()
    {
        User user0 = [Select id,AssignedCases__c,Capacity__c from User where Lastname = 'Work router'];
        List<Case> casesToAssignOwner = [Select id,OwnerId from case where WithoutBestAgent__c = true and owner.profile.name !=: PROFILE_USP_USER];
        casesToAssignOwner[0].OwnerId = user0.id;
        
        Test.startTest();
        new WorkRouter().updateCases(casesToAssignOwner);
        Test.stopTest();

        List<Case> casesAfterUpdate = [Select id,OwnerId from case where id =:casesToAssignOwner[0].id];

        Assert.areEqual (user0.id, casesAfterUpdate[0].OwnerId, 'El caso no se ha actualizado correctamente');
    }

    /**
     * Test del método que comprueba que si existe un error al actualizar los casos, se genera un error. 
     * El error que da es porque no permite actualizar los usuarios y los casos a la vez en el test. 
     * @author aberuete
     * @date 01/07/2024
     */
    @isTest
    private static void test_generateErrorUpdatingCase()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().getNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);

        User user0 = [Select id,AssignedCases__c,Capacity__c from User where Lastname = 'Work router'];
        Assert.areEqual(1,user0.AssignedCases__c, MESSAGE_NUMBER_OF_ASSIGNED_CASES_INCORRECT);   

        User user1 = [Select id,AssignedCases__c,Capacity__c from User where Lastname = 'Work router 2'];
        Assert.areEqual(0,user1.AssignedCases__c, MESSAGE_NUMBER_OF_ASSIGNED_CASES_INCORRECT);

        List<Case> casesToAssignOwner = [Select id,OwnerId from case where WithoutBestAgent__c = true and owner.profile.name !=: PROFILE_USP_USER];
        Assert.areEqual(4, casesToAssignOwner.size(),'El número de casos a asignar no es correcto');

        Test.startTest();
        new WorkRouter().assignCasesWithoutBestAgentToActiveAgent((List<Case>)casesToAssignOwner);
        Test.stopTest();

        List<Error_Log__c> errorRecords = [SELECT Id FROM Error_Log__c];
        Assert.isTrue(errorRecords.size()>0, 'Deberia de haber algun error');
    }
}