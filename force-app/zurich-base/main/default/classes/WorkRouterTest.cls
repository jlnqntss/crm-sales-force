/**
 * Clase de test para la lógica de la clase programada Job_WorkRouter y el batch Batch_WorkRouter
 * @author aberuete
 * @date 01/07/2024
 */
@isTest
private with sharing class WorkRouterTest
{
    private static final string PROFILE_USP_USER = 'USP User';
    private static final string MESSAGE_NUMBER_OF_ASSIGNED_CASES_INCORRECT = 'El número de casos asignados del agente no es correcto';
    private static final string NO_DAMAGES_QUEUE_NAME = 'Email_USP_Daños_RC';
    private static final string NB_DAMAGES_RC_ROUTING_TEAM_NAME = 'NB Damages RC';

    @TestSetup
    private static void createScenario()
    {
        List<Account> accounts = TestDataFactory.generateAccounts(Label.GeneralInsurance, 'Intermediary', 1);
        insert accounts;

        List<Profile> profileUsp= [SELECT Id FROM Profile WHERE Name =: PROFILE_USP_USER];
        List<Group> lDamagesQueue = [SELECT Id, Name FROM Group WHERE Name =: NO_DAMAGES_QUEUE_NAME];
        List<User> userUsp = TestDataFactory.generateUsersByProfile(profileUsp[0].Id, 2);
        userUsp[0].Lastname = 'Work router';
        userUsp[1].Lastname = 'Work router 2';
        userUsp[0].ActiveAgent__c = true;
        userUsp[1].ActiveAgent__c = true;
        userUsp[0].Capacity__c = 10;
        userUsp[0].RoutingTeam__c = NB_DAMAGES_RC_ROUTING_TEAM_NAME;
        userUsp[1].RoutingTeam__c = NB_DAMAGES_RC_ROUTING_TEAM_NAME;
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
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();

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
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();

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
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
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
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
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

        Map<Id,List<Case> > mapOwnerByCases = new Map<Id,List<Case> >();

        for (Case caseToUpdate: casesToUpdate)
        {
            if ( mapOwnerByCases.containsKey(caseToUpdate.OwnerId) )
            {
                mapOwnerByCases.get(caseToUpdate.OwnerId).add(caseToUpdate);
            }
            else
            {
                mapOwnerByCases.put(caseToUpdate.OwnerId,new List<Case> {caseToUpdate});
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

        List<Case> casesAfterUpdate = [Select id,OwnerId from case where id =: casesToAssignOwner[0].id];

        Assert.areEqual (user0.id, casesAfterUpdate[0].OwnerId, 'El caso no se ha actualizado correctamente');
    }

    /**
     * Método que organiza la lista de usuarios y de casos por equipos haciendo uso del wrapper RoutingTeamWrapper y
     * posteriormente llama al método de disrtribución de casos
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_assignCasesAndAgentsByRoutingTeam()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        List<Case> casesToAssignOwner = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE WithoutBestAgent__c = true];
        Test.startTest();
        new WorkRouter().assignCasesAndAgentsByRoutingTeam(casesToAssignOwner);
        Test.stopTest();

        List<User> userAgentActiveAfterUpdate = [Select id,AssignedCases__c from User where Lastname = 'Work router'];
        Assert.areEqual(1,userAgentActiveAfterUpdate[0].AssignedCases__c, 'El número de casos asignados del agente tras la actualización no es correcto');
    }

    /**
     * Método que organiza la lista de usuarios y de casos por equipos haciendo uso del wrapper RoutingTeamWrapper y
     * posteriormente llama al método de disrtribución de casos
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_assignCasesAndAgentsByRoutingTeamException()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        Exception expectedError;
        Test.startTest();
        try
        {
            new WorkRouter().assignCasesAndAgentsByRoutingTeam(null);
        }
        catch(Exception error)
        {
            expectedError = error;
        }
        Test.stopTest();

        Assert.isNotNull(expectedError, 'No se ha lanzado ninguna excepción');
    }

    /**
     * Método que gestiona la lista de casos por equipos haciendo uso del wrapper
     * RoutingTeamManager
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_allocateAssignCasesByRoutingTeam()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        List<Case> casesToAssignOwner = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE WithoutBestAgent__c = true];
        Map<String, WorkRouter.RoutingTeamWrapper> mRoutingTeamWrapper = new  Map<String, WorkRouter.RoutingTeamWrapper>();
        Test.startTest();
        new WorkRouter().allocateAssignCasesByRoutingTeam(casesToAssignOwner, mRoutingTeamWrapper);
        Test.stopTest();
        Assert.isTrue(!mRoutingTeamWrapper.get(NB_DAMAGES_RC_ROUTING_TEAM_NAME).lCasesToAssign.isEmpty(), 'El mapa no se ha generado correctamente');
    }

    /**
     * Método que gestiona la lista de casos por equipos haciendo uso del wrapper
     * RoutingTeamManager
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_allocateAssignCasesByRoutingTeamException()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        List<Case> casesToAssignOwner = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE WithoutBestAgent__c = true];
        Map<String, WorkRouter.RoutingTeamWrapper> mRoutingTeamWrapper = new  Map<String, WorkRouter.RoutingTeamWrapper>();
        Exception expectedError;
        Test.startTest();
        try
        {
            new WorkRouter().allocateAssignCasesByRoutingTeam(null, mRoutingTeamWrapper);
        }
        catch(Exception error)
        {
            expectedError = error;
        }
        Test.stopTest();

        Assert.isNotNull(expectedError, 'No se ha lanzado ninguna excepción');
    }

    /**
     * Test del método que gestiona la lista de usuarios por equipos haciendo uso del wrapper
     * RoutingTeamManager
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_allocateActiveAgentsByRoutingTeam()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        List<Case> casesToAssignOwner = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE WithoutBestAgent__c = true];
        Map<String, WorkRouter.RoutingTeamWrapper> mRoutingTeamWrapper = new  Map<String, WorkRouter.RoutingTeamWrapper>();
        new WorkRouter().allocateAssignCasesByRoutingTeam(casesToAssignOwner, mRoutingTeamWrapper);
        List<User> lUserAgentActive = [SELECT Id, AssignedCases__c, Capacity__c, RoutingTeam__c FROM User WHERE Lastname = 'Work router'];
        Test.startTest();
        new WorkRouter().allocateActiveAgentsByRoutingTeam(lUserAgentActive, mRoutingTeamWrapper);
        Test.stopTest();
        Assert.isTrue(!mRoutingTeamWrapper.get(NB_DAMAGES_RC_ROUTING_TEAM_NAME).lUsersWithAgentActive.isEmpty(), 'El mapa no se ha generado correctamente');
    }

    /**
     * Test del método que gestiona la lista de usuarios por equipos haciendo uso del wrapper
     * RoutingTeamManager
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_allocateActiveAgentsByRoutingTeamException()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        List<Case> casesToAssignOwner = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE WithoutBestAgent__c = true];
        Map<String, WorkRouter.RoutingTeamWrapper> mRoutingTeamWrapper = new  Map<String, WorkRouter.RoutingTeamWrapper>();
        Exception expectedError;
        Test.startTest();
        try
        {
            new WorkRouter().allocateActiveAgentsByRoutingTeam(null, mRoutingTeamWrapper);
        }
        catch(Exception error)
        {
            expectedError = error;
        }
        Test.stopTest();

        Assert.isNotNull(expectedError, 'No se ha lanzado ninguna excepción');
    }

    /**
     * Devuelve el número de usuarios con capacidad infinita
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_getNumberOfUsersActiveWithInfiniteCapacity()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        List<Case> casesToAssignOwner = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE WithoutBestAgent__c = true];
        Map<String, WorkRouter.RoutingTeamWrapper> mRoutingTeamWrapper = new  Map<String, WorkRouter.RoutingTeamWrapper>();
        new WorkRouter().allocateAssignCasesByRoutingTeam(casesToAssignOwner, mRoutingTeamWrapper);
        List<User> lUserAgentActive = [SELECT Id, AssignedCases__c, Capacity__c, RoutingTeam__c FROM User WHERE Lastname = 'Work router 2'];
        Test.startTest();
        Integer numberOfUsersWithInfiniteCapacity = new WorkRouter().getNumberOfUsersActiveWithInfiniteCapacity(lUserAgentActive);
        Test.stopTest();
        Assert.areEqual(1, numberOfUsersWithInfiniteCapacity, 'número de usuarios con capacidad infinita incorrecto');
    }

    /**
     * Devuelve el número de usuarios con capacidad infinita
     * @author fjbelmonte
     * @date: 24/10/2024
     */
    @isTest
    private static void test_getNumberOfUsersActiveWithInfiniteCapacityException()
    {
        List<AggregateResult> ownerIdsByNumberOfCases = new CasesSelector().selectNumberOfAssignedCasesGroupById();
        new WorkRouter().updateNumberOfCaseByUser(ownerIdsByNumberOfCases);
        List<Case> casesToAssignOwner = [SELECT Id, OwnerId, Owner.Name FROM Case WHERE WithoutBestAgent__c = true];
        Map<String, WorkRouter.RoutingTeamWrapper> mRoutingTeamWrapper = new  Map<String, WorkRouter.RoutingTeamWrapper>();
        Exception expectedError;
        Test.startTest();
        try
        {
            Integer numberOfUsersWithInfiniteCapacity = new WorkRouter().getNumberOfUsersActiveWithInfiniteCapacity(null);
        }
        catch(Exception error)
        {
            expectedError = error;
        }
        Test.stopTest();

        Assert.isNotNull(expectedError, 'No se ha lanzado ninguna excepción');
    }
}